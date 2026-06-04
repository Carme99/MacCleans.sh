# Developer Guide

Interested in contributing to MacCleans? This guide covers everything you need to know.

## Project Structure

```
MacCleans.sh/
├── clean-mac-space.sh      # Main script (entry point installed as `Mac-Clean`)
├── installer.sh            # Curl-based installer
├── maccleans.conf.example  # Annotated sample config file
├── completions/            # Shell completions (bash, zsh, fish)
├── docs/                   # User + developer documentation
├── .github/
│   ├── workflows/          # GitHub Actions (shellcheck, claude-review, release)
│   ├── ISSUE_TEMPLATE/     # Bug + feature request templates
│   └── pull_request_template.md
├── CHANGELOG.md            # Release history
├── CONTRIBUTING.md         # How to contribute + release process
├── CLAUDE.md               # AI-agent context (this file's sibling)
├── LICENSE                 # MIT
└── README.md
```

There is intentionally **no `tests/` directory and no `npm test`** — MacCleans is a single Bash script (plus an installer and completions), tested manually and via ShellCheck on PRs. Adding a test framework is intentionally out of scope; see the "Testing" section below.

## Script Architecture

`clean-mac-space.sh` is a single-file Bash script (~3,200 lines). It's organized into these top-level sections:

1. **Shebang + strict mode** (`set -euo pipefail`, lines 1-9)
2. **Constants + version** (lines 11-30)
3. **Help / option documentation** (the `# Options:` block, lines 33-72)
4. **Configuration loading** — `load_config_file()`, `validate_config()`, `parse_arguments()` (lines ~155-475)
5. **Cleanup-on-signal handlers** — `cleanup_on_interrupt`, `cleanup_on_exit` (lines ~477-525)
6. **Locking** — `acquire_lock` (lines ~534-575)
7. **Destructive helper** — `safe_clear_directory` (lines ~580-625)
8. **iCloud safety helpers** — `check_icloud_sync_status`, `check_icloud_backup_enabled` (lines ~627-735)
9. **Logging helpers** — `log`, `log_verbose`, `log_plain`, `log_always`, `log_warning`, `log_error`, `log_success`, `log_category`, `log_section` (lines ~750-810)
10. **Disk / size helpers** — `safe_du`, `size_to_bytes`, `bytes_to_human`, `check_disk_space`, `check_minimum_disk_space` (lines ~846-925)
11. **Health checks** — `perform_health_checks` (line 1031)
12. **Profile loader** — `load_profile` (line 1071)
13. **Category cleanup sections** — 29 top-level procedural blocks, numbered #1 through #29 continuously (the F-2 numbering gap that was noted in the v5.2.0 review was fixed in v5.4.0; the root-cause refactor into a `CATEGORY_REGISTRY` + `run_category` dispatcher is still F-5)
14. **JSON output** (the trailing `# Deliver results as JSON` block)

## Adding a New Category

To add a new cleanup category (e.g. `newcategory`):

### 1. Add the skip flag and CLI option

In the option block at the top of the script (around line 46-72), add:

```bash
#   --skip-newcategory    Skip NewCategory cleanup
```

In `parse_arguments()` (line 258), add a case for the new flag:

```bash
--skip-newcategory)
    SKIP_NEWCATEGORY=true
    shift
    ;;
```

### 2. Add the variable

In the default-variables block, add:

```bash
SKIP_NEWCATEGORY=false
```

### 3. Add configuration-file support

In `load_config_file()` (line 191), add:

```bash
SKIP_NEWCATEGORY) SKIP_NEWCATEGORY="$value" ;;
```

In `validate_config()` (line 160), add `SKIP_NEWCATEGORY` to the allowed-keys list so unknown-key warnings don't fire.

### 4. Add the cleanup section

Add a new numbered section at the end of the category block list (currently 29 categories, ~line 3050-ish). Use an existing similar category as a template. Required pattern:

```bash
###############################################################################
# 30. NewCategory
###############################################################################
if [ "$SKIP_NEWCATEGORY" = false ]; then
    log_plain "================================================"
    log "30. NewCategory"
    log_plain "================================================"

    NEWCATEGORY_PATH="$USER_HOME/Library/Caches/com.example.newcategory"

    if [ -L "$NEWCATEGORY_PATH" ]; then
        log_warning "Skipping symlink: $NEWCATEGORY_PATH"
    elif [ -d "$NEWCATEGORY_PATH" ]; then
        # measure size, log_warning if 0
        NEWCATEGORY_SIZE=$(safe_du "$NEWCATEGORY_PATH" 2>/dev/null)
        log "NewCategory: $NEWCATEGORY_SIZE"

        if [ "$NEWCATEGORY_SIZE" != "0B" ]; then
            PROCESSED_CATEGORIES+=("NewCategory")
            if [ "$DRY_RUN" = true ]; then
                log "Would clean NewCategory: $NEWCATEGORY_SIZE"
                TOTAL_BYTES_FREED=$((TOTAL_BYTES_FREED + $(size_to_bytes "$NEWCATEGORY_SIZE")))
            else
                if safe_clear_directory "$NEWCATEGORY_PATH"; then
                    log_success "NewCategory cleared"
                    TOTAL_BYTES_FREED=$((TOTAL_BYTES_FREED + $(size_to_bytes "$NEWCATEGORY_SIZE")))
                else
                    log_warning "Some files in NewCategory could not be removed"
                fi
            fi
        else
            log "NewCategory is empty"
        fi
    else
        log "NewCategory not found"
    fi
    log_plain ""
else
    SKIPPED_CATEGORIES+=("NewCategory")
fi
```

Conventions:
- Use `safe_clear_directory` for the destructive step — it handles `[ -L ]` checks and `find -type f` predicates
- Use `safe_du` for size measurement (returns human-readable string, pair with `size_to_bytes` for arithmetic)
- Append to `PROCESSED_CATEGORIES` (success) or `SKIPPED_CATEGORIES` (skipped/failed), used for the final summary + `--json` output
- Match the existing numbering — if you add this as the new #30, the gap at #23 still needs separate fixing (see "Known issues" below)

### 5. Update documentation

- Add an entry to `docs/all-categories.md` (keep the alphabetical-ish ordering)
- Add the flag to the `--skip-X` list in `docs/command-reference.md` (around line 171)
- Add `SKIP_NEWCATEGORY` to the Skip Options table in `docs/configuration.md`
- If it should be skippable via a profile, add it to the relevant profile case in `load_profile()` (line 1071) and update `docs/profiles.md`

### 6. Add to the example config

Append the new `SKIP_NEWCATEGORY=false` line to `maccleans.conf.example` at the repo root, in a sensible alphabetical/grouped position.

## Code Style

### Formatting

- 4-space indentation (no tabs)
- ~100 character line length where practical
- Blank lines between top-level functions
- `local` for all function-local variables

### Naming

- Functions: `snake_case` (e.g. `safe_clear_directory`, `load_config_file`)
- Local variables: `snake_case` (e.g. `user_home`, `recent_backup`)
- Global variables: `UPPER_SNAKE_CASE` (e.g. `SKIP_XCODE`, `USER_HOME`, `PROCESSED_CATEGORIES`)
- Array appends: `ARR+=("item")` (always quoted)
- Command substitution: `$(cmd)` not backticks

### Safety conventions

These are the rules the script lives by — please don't relax them:

- `set -euo pipefail` at the top of every script, no exceptions
- All destructive operations go through `safe_clear_directory`, which:
  - Refuses to follow symlinks at the root
  - Uses `find -type f` / `-type d` predicates that don't follow in-tree symlinks
- Per-folder `[ -L "$folder" ]` checks before any `find -delete` on user data
- All variable expansions are double-quoted (the optional `quote-safe-variables` ShellCheck rule, currently disabled in CI but enforced in code review)
- Sudo is only used where required, and drops privileges via `sudo -u "$ACTUAL_USER"` when running as root (see the brew cleanup and the iCloud backup check for the pattern)
- Per-operation `--force-X` flags for dangerous operations (Xcode, Trash, iCloud Drive, iOS Backups) — `--force` alone does not bypass them

## Testing

There is no automated test framework. Before submitting a PR:

1. **ShellCheck on both scripts** — must pass clean at the default CI severity:
   ```bash
   shellcheck -f gcc clean-mac-space.sh installer.sh
   shellcheck -S warning clean-mac-space.sh installer.sh
   ```
2. **Bash syntax** — `bash -n clean-mac-space.sh && bash -n installer.sh`
3. **Manual dry run** — `sudo ./clean-mac-space.sh --dry-run --verbose` (or `--dry-run --json | jq` for machine-readable output)
4. **Targeted dry run** — exercise your new category with `--skip-everything-else --verbose` (or whatever skips narrow it down) to confirm the right files are about to be touched
5. **Real run with `--yes` on a non-critical machine** if the change affects anything beyond your own `/tmp` or your own caches

The CI on PRs runs ShellCheck automatically (see `.github/workflows/shellcheck.yml`) and the release workflow (`.github/workflows/release.yml`) handles tarball + SHA + tap on tag push.

## ShellCheck

The project is configured to pass `shellcheck` at default severity (error/warning/info) with `SC1090`/`SC1091` excluded (sourced files can't be checked statically). Optional rule groups (`-o quote-safe-variables`, `-o require-double-brackets`, `-o check-extra-masked-returns`, etc.) surface stylistic recommendations that aren't gating the build but are worth fixing in a follow-up PR.

The action pin is `ludeeus/action-shellcheck@master` (line 19 of `.github/workflows/shellcheck.yml`) — known P2 to pin to a SHA for supply-chain stability.

## Pull Request Guidelines

1. **Branch from `main`**, use a `fix/<name>` or `feat/<name>` prefix (the project's convention)
2. **Keep PRs focused** — one feature or fix per PR
3. **Run the verifications above locally** before pushing
4. **Update CHANGELOG.md** under an "Unreleased" section (or your version's section)
5. **Update all the docs** — the script's option block, `command-reference.md`, `all-categories.md`, `configuration.md`, `profiles.md` (whichever apply)
6. **PR template** (`.github/pull_request_template.md`) — tick the right boxes, link any closed issues

## Reporting Issues

Found a bug? Open an issue with:

- macOS version
- MacCleans version (`Mac-Clean --version`)
- Steps to reproduce
- Expected vs actual behavior
- Output with `--verbose` (and `--json` for machine-readable) if possible

## Known Issues / Tech Debt

These are open items from the v5.2.0 review that future contributors may want to tackle:

- **F-2**: ✅ fixed in v5.4.0 (PR #74). Sections now number 1-29 continuously.
- **F-3**: ✅ fixed in v5.4.0 (PR #74). `disk_usage.after` is now `null` in dry-run JSON.
- **F-4**: ✅ fixed in v5.5.0 (PR #77). Extracted `get_free_disk_bytes()` shared helper. The two disk-space check functions remain (they have different contracts — one exits, one returns) but now share a single `df` call. Pre/post-cleanup byte measurements also use the helper.
- **F-5**: 29 top-level procedural category blocks. Refactor into a registry.
- **P2 #26**: `ludeeus/action-shellcheck@master` should be pinned to a SHA.

## Getting Help

| Question | Where to Ask |
|----------|--------------|
| Bug report | [GitHub Issues](https://github.com/Carme99/MacCleans.sh/issues) |
| Feature request | [GitHub Discussions](https://github.com/Carme99/MacCleans.sh/discussions) |
| Contributing help | [GitHub Discussions](https://github.com/Carme99/MacCleans.sh/discussions) |

---

<p align="center">

[Back to Documentation](index.md) · [GitHub Repository](https://github.com/Carme99/MacCleans.sh) · [Issues](https://github.com/Carme99/MacCleans.sh/issues)

</p>
