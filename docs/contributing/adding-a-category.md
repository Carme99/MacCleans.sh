# Adding a New Cleanup Category

This is the recipe for shipping a new category in 5 steps. The F-5 refactor (PR #78 + #79) means most of the bookkeeping is now one line — see [reference/categories.md](../reference/categories.md) for what currently exists.

## Overview

Every category lives in `CATEGORY_REGISTRY` (a single bash array) and follows the format:

```text
"N|Display Name|SKIP_X"
```

Adding a category = one new line in the registry + one new section body. All four consumers (default init, `--skip-X` parsing, config validation, interactive menu) derive from the registry automatically.

## Step 1: Add the registry line

In `clean-mac-space.sh`, find the `CATEGORY_REGISTRY=(` block (around line 100). Add your new entry at the end:

```bash
CATEGORY_REGISTRY=(
    # ... existing entries ...
    "29|My New Category|SKIP_MY_NEW"  # ← new line
)
```

Pick the next number. Use the existing style for the display name. The `SKIP_X` var is what the user types `--skip-my-new` to set (uppercased, hyphens → underscores).

If your category must always run (e.g. "always clean trash", no opt-out), leave the skip var empty:

```bash
"29|My New Category|"
```

## Step 2: Add the CLI option

In the option block near the top of the script (the `###...###` sentinel-delimited help text block), add a line like:

```text
--skip-my-new    Skip My New Category cleanup
```

The format matters — `--skip-<lowercase-with-hyphens>` is auto-derived to `SKIP_<UPPERCASE_WITH_UNDERSCORES>` by `parse_arguments` and validated against the registry (typos get a clear error).

## Step 3: Add the section body

Find the end of the section block list (currently `28|.DS_Store Files|SKIP_DSSTORE` is the last). Below it, add a new section following the standard pattern:

```bash
###############################################################################
# 29. My New Category
###############################################################################
if run_category "29|My New Category|SKIP_MY_NEW"; then
    MY_NEW_BYTES=0
    MY_NEW_COUNT=0

    # Define your cleanup paths. Example:
    MY_NEW_DIRS=(
        "$USER_HOME/Library/Caches/MyApp"
    )

    for DIR in "${MY_NEW_DIRS[@]}"; do
        if [ -d "$DIR" ] && [ ! -L "$DIR" ]; then
            MY_NEW_SIZE=$(safe_du "$DIR")
            if [ -n "$MY_NEW_SIZE" ] && [ "$MY_NEW_SIZE" != "0B" ]; then
                log "My New Category: $MY_NEW_SIZE"
                MY_NEW_BYTES=$(size_to_bytes "$MY_NEW_SIZE")
                MY_NEW_TOTAL_BYTES=$((MY_NEW_TOTAL_BYTES + MY_NEW_BYTES))
                MY_NEW_COUNT=$((MY_NEW_COUNT + 1))

                if [ "$DRY_RUN" = false ]; then
                    safe_clear_directory "$DIR"
                fi
            fi
        fi
    done

    if [ "$MY_NEW_COUNT" -gt 0 ]; then
        log_success "My New Category deleted ($MY_NEW_COUNT files, $(bytes_to_human $MY_NEW_BYTES))"
    else
        log "No My New Category files found"
    fi
    log_plain ""
fi
```

Conventions:
- `if run_category "..."; then` opens the section. `run_category` handles the skip-flag check, prints the section header, and tracks processed/skipped.
- `safe_clear_directory` for any `find -delete` — refuses to follow symlinks at the root.
- `log` / `log_success` / `log_plain` for output. No `echo` directly.
- `log_plain ""` at the end gives a blank line between sections.
- `if [ -d "$DIR" ] && [ ! -L "$DIR" ]; then` is the standard symlink safety check.

## Step 4: Add the SKIP var initializer (if not handled automatically)

`_init_skip_defaults` walks the registry and sets every `SKIP_X` to `false`. So if your entry has a `SKIP_VAR`, the default is automatic.

If you need a different default (e.g. skip by default for safety), add an override after `_init_skip_defaults`:

```bash
# _init_skip_defaults sets SKIP_MY_NEW=false; we want true (opt-in)
SKIP_MY_NEW=true
```

(Mirror the existing `SKIP_SYSTEM_TMP=true` override — that's the pattern for "off by default".)

## Step 5: Update documentation

In `docs/reference/categories.md`, add a row to the summary table:

```markdown
| 29 | My New Category | Variable | Low | `--skip-my-new` |
```

In `docs/reference/config-file.md`, add `SKIP_MY_NEW` to the boolean flags table.

If your category needs a how-to guide (e.g. a "how to free X safely" walkthrough), add one under `docs/how-to/guides/`.

## Step 6: Add a test (if your category touches a non-trivial code path)

In `tests/run-tests.sh`, add a test for any new helper your section uses. Existing test categories: `validate_boolean`, `validate_numeric`, `validate_photos_library_name`, `size_to_bytes`, the two `registry_get_*` accessors, `_init_skip_defaults`, and `CATEGORY_REGISTRY` length.

If your category adds a new boolean flag, append a case to `validate_config`'s boolean-check list (the second `for` loop in `validate_config`).

## Step 7: Open a PR

That's it. The CI runs ShellCheck + the smoke tests; Sourcery will review; the contributor/owner merges.

For the full architecture, see [developer-guide.md](developer-guide.md).
