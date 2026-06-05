# Changelog

All notable changes to MacCleans.sh are documented in this file.

## [Unreleased]

### Security

- **Three-pass security audit + 3 audit tests** — script-wide review of `$USER_HOME` usage, `find -delete` symlink-safety, and sudo path resolution. Found and fixed 3 real bugs (below). The audit patterns are now codified as 3 CI tests in `tests/run-tests.sh` so future regressions get caught at PR time.
- **Fixed: `CONFIG_FILES` (script entry points) used literal `$HOME`** — under `sudo Mac-Clean` on default macOS sudoers, `$HOME` resolves to `/var/root`, which meant the script silently missed the user's `~/.maccleans.conf` and `~/.config/maccleans/config`. The config-file load would then use no config, and the user wouldn't see the warning. Moved the array to after the `USER_HOME` derivation and switched to `$USER_HOME`.
- **Fixed: `LOCKDIR="$HOME/.macclean/lock"`** — the per-invocation lock went to `/var/root/.macclean/lock` under sudo, while a non-sudo invocation would create a separate lock in the user's real home. Two separate locks = no actual concurrency protection. Reassigned `LOCKDIR` after `USER_HOME` derivation to use `$USER_HOME/.macclean/lock`.
- **Fixed: `check_icloud_backup_enabled` used `$HOME`** — the iOS backup detection logic looked for `~/Library/Logs/MobileBackup/Backup.log`, which under sudo would silently miss the user's real backup log. This affected the safety check that warns before deleting iOS device backups (category #21). Switched to `$USER_HOME`.

### Internal

- `tests/run-tests.sh`: 14 → 17 tests. The 3 new tests are:
  - `test_no_literal_home_in_user_paths` — fails if any future PR adds `"$HOME/..."` to the script
  - `test_find_delete_has_type_or_symlink_guard` — fails if any future `find ... -delete` lacks a type filter or `[ ! -L ]` guard
  - `test_user_home_derivation_uses_sudo_user` — verifies the sudo/non-sudo derivation block in the script has the right shape (uses `$SUDO_USER` + `getent` with a `$HOME` fallback)
- `docs/explanation/security-model.md`: documents the `$USER_HOME` and `find -delete` symlink-safety conventions so the next contributor knows the rules without having to re-derive them.

## [5.6.0] - 2026-06-05

### Added

- **3 new cleanup categories (#29, #30, #31)** — adds ~3.1GB of potential free space on a typical dev machine, with a clean safety story for each:
  - **#29 Browser Testing Tool Caches** (`--skip-browser-tools`) — `~/.cache/puppeteer` and `~/.cache/selenium`. Downloads browser binaries (full Chrome, headless Chrome, etc.) for headless testing. Safe to delete — re-downloaded on next test run. **Typical savings: 500MB-2GB.**
  - **#30 Crash Reports** (`--skip-crash-reports`) — `~/Library/Logs/CrashReporter` and `~/Library/Application Support/CrashReporter`. macOS writes per-app `.crash`/`.ips`/`.diag` dumps here when processes die. 7-day age threshold so recent crashes stay available for "report a bug" workflows. **Typical savings: 100MB-1GB.**
  - **#31 User Tool Caches** (`--skip-user-tool-caches`) — `~/.cache/{uv, giget, opencode, opencode-agent-skills, powershell, gh, starship}`. Modern CLI tool caches — packages, modules, API responses, all redownloaded on demand. **Typical savings: 500MB-2GB.** (uv's cache is conceptually similar to the existing pip category (#10) but lives in `~/.cache/uv` rather than pip's directory; we covered it here to keep this PR's scope small. Renaming/extending #10 is a candidate for a future cleanup PR.)
- **3 new `--skip-X` flags wired through the registry** — `--skip-browser-tools`, `--skip-crash-reports`, `--skip-user-tool-caches`. The typo check (e.g., `--skip-brower-tools`) catches the misspelling and exits with a clear error, because the auto-derivation looks up the registry.

### Internal

- CATEGORY_REGISTRY: 30 entries → **33 entries** (1-28 + 3a/3b + 29/30/31). The `test_registry_has_33_entries` and `test_registry_has_new_categories` smoke tests in `tests/run-tests.sh` enforce the count and the new skip-var wiring. Adding a future category = one new line in the registry + one section body, as before.
- 3 new section bodies follow the existing `if run_category "N|Name|SKIP_X"; then ... fi` pattern. Each one uses `safe_clear_directory` (browser tools + user tool caches) or the `find -mtime +X -delete` age-threshold pattern (crash reports) so symlink-safety and write-permission checks come for free.

## [5.5.2] - 2026-06-04

### Documentation

- **Diátaxis restructure + 7 mermaid diagrams** (PR #81) — `docs/` reorganized into 4 buckets (tutorials/ how-to/ reference/ explanation/) plus a `contributing/` subfolder. 4 new files (`docs/README.md` landing, `docs/tutorials/first-cleanup.md` walkthrough, `docs/reference/config-file.md` reference, `docs/contributing/adding-a-category.md` recipe). 1 file deleted (`docs/guides/automating-macos-maintenance.md`, content merged into `how-to/automate.md`). 7 new mermaid diagrams: full architecture sequence (`explanation/how-it-works.md`), config precedence flowchart (`how-to/configure.md`), diagnostic decision tree (`how-to/troubleshooting.md`), `--clean-system-tmp` vs `--skip-system-tmp` order-independent flow (`reference/commands.md`), `CATEGORY_REGISTRY` → 5 consumers sequence (`contributing/developer-guide.md`), top-level function call graph (`contributing/developer-guide.md`), trust boundary flowchart (`explanation/security-model.md`). Style guide applied across all docs: one H1, one-line purpose statement, "you" not "the user", tables for option specs, no marketing copy, no emoji in bodies, code-first examples, language-tagged code blocks. Cross-link audit: 0 broken. Net diff: +635/-815 (the doc tree actually shrunk).

### Bug Fixes

- **Interactive menu now shows row numbers** (PR #82) — the "Tip: Numbers 1-27" hint at the bottom of the picker was promising a feature the rows didn't deliver. The shortcut itself worked, but the user had no way to know which digit maps to which row without counting. Now each row shows ` %2d. ` before the display name, so the cursor's row and the digit to press line up exactly.
- **iOS Simulators no longer reports a false success** (PR #82) — when `xcrun simctl delete unavailable` failed, the script was logging both `⚠ Could not delete unavailable simulators` AND `✓ Unavailable iOS Simulators removed` in the same section. Direct contradiction. Restructured into a proper `if/then/else` so a real failure only emits the warning, the freed-bytes total stays accurate, and the summary can't say a category succeeded when it didn't.

### Internal

- Bumped `VERSION="5.5.2"` in `clean-mac-space.sh`.
- Regenerated `EXPECTED_HASH` in `installer.sh` for the new script bytes.
- All verification (`bash -n`, `shellcheck -S warning`) clean.

## [5.5.0] - 2026-06-04

### Refactor

- **F-5: registry-driven category cleanup (PR #78 + #79)** — extracted `CATEGORY_REGISTRY` (28 entries covering 1-28 with 3a/3b sub-sections for Spotify + Claude), `_init_skip_defaults` (initialises each `SKIP_X` var via `printf -v`), and `run_category` (emits the header banner and tracks `PROCESSED_CATEGORIES` / `SKIPPED_CATEGORIES`). All 28 section bodies refactored to the `if run_category "N|Name|SKIP_X"; then ... fi` pattern. Four consumers refactored to derive from the registry: `parse_arguments` (27 `--skip-X` cases → 1 generic case with auto-derive + registry-based typo check), `interactive_selection` (27-entry `categories` array → registry-derived; 54-case `toggle_category` → 5-line `printf -v`; `a`/`n` shortcuts now iterate `categories[@]` so new categories auto-pick them up), `validate_config` (27-line `for SKIP_X` loop → registry-derived), and the `SC2034` shellcheck disable widened to file scope (the `SKIP_X` vars are read via dynamic `${!var}` and `printf -v`, which shellcheck can't trace). Adding a new cleanup category is now one new line in `CATEGORY_REGISTRY` + one new section body — no edits to argument parsing, config validation, the interactive menu, or shellcheck suppression. Closes the last open item from the v5.2.0 review.
- **F-4: `get_free_disk_bytes()` shared helper (PR #77)** — the two disk-space check functions (the hard-gate `check_minimum_disk_space` and the soft-warn `is_disk_space_sufficient`) and the pre/post-cleanup byte measurement now share a single `df` invocation, so the parser, the column mapping, and the bytes-from-blocks math live in one place. The two check functions remain (they have different contracts: one exits on failure, one returns), but the underlying `df` read is the helper.

### Bug Fixes

- **`--help` extraction is robust** (PR #76) — the script now reads the help block between sentinel markers (`###...###`) instead of "everything up to the first non-comment line" (which broke on the blank line right after the shebang), and uses a two-step `#` strip that handles bare `#`, `#\tfoo`, and `#foo` in addition to `# foo`. `script --help` now always produces the expected text on every shell.
- **`X-25` `PHOTOS_LIBRARY_NAME` config validation** (PR #76) — `validate_photos_library_name()` is now a shared helper called from both the CLI flag and the config-file loader, instead of two divergent inline regex checks. Rejects path traversal, absolute paths, and shell metacharacters up front.
- **`-w` no longer overwritten by `SKIP_SYSTEM_TMP` after `--clean-system-tmp`** (PR #79 follow-up) — `--clean-system-tmp` is now a sticky `CLEAN_SYSTEM_TMP_REQUESTED` marker, so a later `--skip-system-tmp` on the same command line is ignored. The help text's "clean overrides skip" contract holds regardless of flag order.
- **iCloud Drive symlink-skip is no longer emitted as "processed"** (PR #79 follow-up) — the `[ -L CloudStorage ]` check is hoisted before `run_category`, so the symlink-swap defense is recorded as a skip, not a process-with-zero-freed.
- **iOS Backups `SKIPPED_CATEGORIES` no longer duplicated** (PR #79 follow-up) — the `--force` and `! --force` branches in section 21 no longer append to `SKIPPED_CATEGORIES` after `run_category` has already added the category to `PROCESSED_CATEGORIES`, so the end-of-run summary and JSON no longer show "iOS Device Backups" in both lists when the cleanup was gated.

### Documentation

- **Completion parity for 7 missing flags** (PR #76) — `--profile`, `--threshold`, `--update`, `--photos-library`, `--verbose`, `--quiet`, `--no-color` are now in the bash, zsh, and fish completions (was only `--skip-*` + `--force` everywhere).
- **Stale `5.3.0` references fixed in `docs/index.md` and `docs/command-reference.md`** (PR #76 follow-up) — the docs badge and JSON example were lagging one minor version behind.
- **`docs/developer-guide.md` "Known Issues" section now reflects reality** — the F-2/F-3 entries are marked ✅ fixed in v5.4.0, and F-4/F-5 are marked ✅ fixed in v5.5.0. Section counts updated to 28 (was a stale 29 in four places, fixed in PR #79).

### Internal

- Bumped `VERSION="5.5.0"` in `clean-mac-space.sh`.
- Regenerated `EXPECTED_HASH` in `installer.sh` for the new script bytes.
- All verification (`bash -n`, `shellcheck -S warning`) clean.

## [5.4.0] - 2026-06-04

### Internal

- **`scripts/release.sh` (new)** — pre-tag release prep helper that bundles the v5.2.0 release work that was forgotten: bump `VERSION` in `clean-mac-space.sh`, regenerate `EXPECTED_HASH` in `installer.sh`, run `bash -n` + `shellcheck -S warning` + `--version` sanity, stage both files, and prompt for the CHANGELOG entry. Has a `--dry-run` mode and refuses to run off `main`, with a dirty tree, or out of sync with `origin/main`. The hash-regen step being a separate manual command was the root cause of the v5.2.0 `EXPECTED_HASH` drift; bundling it into one command prevents that.
- **CI: `ludeeus/action-shellcheck` replaced with self-contained `apt-get install shellcheck`** — the third-party composite action had been producing 0-job failures on every run since 2026-04-11 (~30 consecutive failures on main, predating v5.2.0). The earlier pin-to-SHA was the right idea for supply-chain stability but is functionally a no-op for fix purposes — the brokenness is in `action.yaml`, not in the SHA reference. apt's shellcheck is the same upstream binary, just installed in a way that doesn't depend on a third-party download. The find filter uses the same shebang regex the action used, so it still correctly skips the zsh autoload file (`_mac-cleans`) and the fish completion. Also extends the `bash -n` step to cover `installer.sh` and `scripts/release.sh` (previously only `clean-mac-space.sh`).
- **`scripts/release.sh` review fixes** (from Sourcery + CodeRabbit on the v5.4 PR): reject extra CLI args; switch dirty-tree check to `git status --porcelain` so untracked files are caught; add a `sha256_file()` helper that falls back from `shasum` to `sha256sum` for Linux; drop the dead `[[ -x ]]` guard around the `--version` sanity check; fix the `CONTRIBUTING.md` example to use `X.Y.Z` (no `v` prefix).
- **Section comments renumbered 1–28** in `clean-mac-space.sh` (F-2) — was 1–22, 24–29 with no #23. Pure cosmetic.
- **`disk_usage.after` now `null` in dry-run JSON** (F-3) — was `0`, which falsely implied the disk was empty. Real runs still emit the measured post-clean value.
- **Completion parity for `--skip-system-tmp` / `--clean-system-tmp`** — zsh completion now lists both flags, fish completion now lists both AND registers the `Mac-Clean` alias via `complete -c Mac-Clean -w mac-cleans` (bash and zsh were already covered).
- **`.github/ISSUE_TEMPLATE/config.yml` (new)** — disables the blank-issue option in the New Issue chooser and points users to Discussions / README first.
- **`.gitignore` extended** — `.worktrees/`, `.mavis/`, `.opencode/`, `CLAUDE.md` (worktree + AI session infrastructure; per-developer, not project-level).
- **`CONTRIBUTING.md`** — release checklist now references `scripts/release.sh` as the pre-tag step.

## [5.3.0] - 2026-06-03

### Documentation

- **`--profile developer` / `conservative` / `minimal` drift fixed** — all three profiles' skip lists in `docs/profiles.md` and `docs/getting-started.md` now match the actual `load_profile()` switches in the code. The developer profile also skips iOS Backups (in addition to Xcode), the conservative profile skips 8 categories, the minimal profile skips 11.
- **`--skip-system-tmp`, `--clean-system-tmp`, `SKIP_SYSTEM_TMP` documented** — added to the option block at the top of `clean-mac-space.sh`, to the `--skip-X` list in `docs/command-reference.md`, and to the Skip Options table in `docs/configuration.md`. (The flags shipped in v5.1.7 but were never written down.)
- **Docker category description** — `docs/all-categories.md` no longer claims Docker cleanup touches volumes; v5.1.7+ only prunes containers and images.
- **6 broken `docs/guides/` links fixed** — `xcode-derived-data`, `docker-cache`, `understanding-caches` references now point to the existing `-guide.md` suffixed files.
- **iCloud Drive and Claude cache paths** in `docs/all-categories.md` were already corrected in v5.2.0.
- **`docs/developer-guide.md` rewritten** — removed the phantom `tests/` directory and `npm test` references, replaced made-up function names (`print_skip`, `calculate_size`, etc.) with the real ones (`log_warning`, `safe_clear_directory`, etc.), and added a "Known Issues / Tech Debt" section listing the remaining P2 items from the v5.2.0 review.
- **`maccleans.conf.example` created at repo root** — annotated, complete sample covering every current config key, including the new `SKIP_SYSTEM_TMP`. Three doc references that pointed to this file (`docs/installation.md`, `docs/guides/automating-macos-maintenance.md`, `CONTRIBUTING.md`) now resolve.
- **Stale version strings** — `docs/index.md` badge, `docs/command-reference.md` JSON example, and `README.md` badge all bumped to 5.3.0.
- **`docs/installation.md`**: installer no longer falsely claims to install shell completions (it never did); added SHA-256 verification step to the install flow description.

### Bug Fixes

- **Duplicate `trap ... INT TERM` in `clean-mac-space.sh`** — the second `trap handle_interrupt INT TERM` was silently overriding the better `cleanup_on_interrupt` handler. Deleted the redundant trap and dead `handle_interrupt` function so Ctrl-C users now get the partial-cleanup summary as intended.
- **Bash 3.2 compatibility for shell completion** — `completions/mac-cleans.bash` was using `mapfile` (a bash 4+ builtin), which fails on macOS's bundled `bash 3.2.57`. Replaced with a `for option in "${options[@]}"` loop.
- **`VERSION` regression in v5.2.0** — the v5.2.0 release shipped with the internal `VERSION="5.1.7"` because a conflict-resolution step during the v5.2.0 cherry-pick dropped the version bump. This release corrects the script's `VERSION` to match the release tag. The Homebrew formula and the GitHub release were already correct.

### Security

- **Constant-time hash comparison in `installer.sh`** — replaced `[ "$sha256_hash" = "$EXPECTED_HASH" ]` with a length-check plus `cmp -s` on process substitutions, avoiding the early-exit timing side-channel. (Defense-in-depth — the expected hash is not a secret.)
- **Symlinked cache path defense** — the system-cache cleanup loop in `clean-mac-space.sh` now skips any `~/Library/Caches/$CACHE_DIR` path that resolves to a symlink, mirroring the pattern used in the diagnostic-reports section. `$CACHE_DIR` is hard-coded today, so this is a future-proofing change for when `SAFE_CACHES` becomes config-driven.

### Internal

- Bumped `VERSION="5.3.0"` in `clean-mac-space.sh`.
- All verification (`bash -n`, `shellcheck -S warning`) clean.

### Post-review polish

- `validate_config()` now also coerces/checks `SKIP_SYSTEM_TMP` (it was previously missing from the boolean validation loop, even though `SKIP_SYSTEM_TMP` was a recognised config key).
- `completions/mac-cleans.bash` now tab-completes `--skip-system-tmp` and `--clean-system-tmp` (the v5.3.0 release added the flags to the script but the bash completion array was not updated).
- `maccleans.conf.example` corrected: the XDG-style path is `~/.config/maccleans/config` (no hyphen), matching the loader. Also clarified that `--skip-xcode` is a presence-style flag and there is no `--skip-xcode=false` form.
- `installer.sh` hash check comment reframed — `cmp -s` is not constant-time, only the length check is.

## [5.1.7] - 2026-04-12

### Security Fixes

- **iCloud Drive TOCTOU mitigation** - Added re-verification before deletion to prevent time-of-check-time-of-use race conditions
- **Docker cleanup restricted** - Changed from `docker system prune -a` (removes ALL images) to `docker container prune` and `docker image prune` (only dangling containers/images)
- **Lock file moved from /tmp** - Lock directory changed to `$HOME/.macclean/lock` to prevent world-writable security issues
- **Homebrew sudo wrapper fixed** - Brew commands now conditionally use `sudo -u $ACTUAL_USER` only when running as root to prevent running as root

### Bug Fixes

- **Duplicate spinner function** - Removed duplicate spinner function definitions that were causing conflicts
- **Path traversal validation** - Improved validation for `--photos-library` option to reject dangerous characters and non-printable input
- **Symlink resolution** - Added robust symlink resolution for user home directory with relative path handling
- **Lock acquisition race condition** - Simplified lock acquisition to avoid TOCTOU; added stale-lock detection using PID-based checks
- **Unknown config keys** - Added warning message when unknown configuration keys are encountered in config file

### New Features

- **Per-operation force flags** - Added `--force-xcode`, `--force-trash`, `--force-icloud-drive`, `--force-ios-backups` flags for granular control
- **System temp cleanup opt-in** - System temp directory cleanup now opt-in via `--clean-system-tmp` flag or `SKIP_SYSTEM_TMP=false` config
- **Installer hash verification** - Optional SHA256 hash verification for installer when `EXPECTED_HASH` is set

### Technical

- **ShellCheck CI improvements** - Added SC1090/SC1091 excludes for sourced files and proper shell specification
- **Lock directory creation** - Parent directory is created automatically if missing
- **Config file FORCE_* support** - FORCE_XCODE, FORCE_TRASH, FORCE_ICLOUD_DRIVE, FORCE_IOS_BACKUPS now loadable from config file

## [5.1.6] - 2026-03-29

### Bug Fixes

- **safe_du() still failing with pipefail** - Fixed `safe_du()` function by adding `set +o pipefail` in addition to `set +e`. When `du` returns non-zero (e.g., "Operation not permitted" on `~/.Trash`), `pipefail` was causing silent script exit even after disabling `set -e`. Affects Trash Bin and any protected directories.

## [5.1.5] - 2026-03-29

### Bug Fixes

- **size_to_bytes() function broken on macOS** - Fixed GNU awk `/i` flag regex incompatibility. BSD awk (macOS) does not support case-insensitive regex flag. Changed to use `tolower()` function for POSIX compatibility. Affected 27+ categories: Homebrew, Spotify, Siri, Bun, Trash, npm, pip, Xcode, Gradle, Go, pnpm, and more.
- **du -sh fallback pattern broken** - Fixed `du` command pipeline logic where the `|| echo "0B"` fallback never triggered because `du` returns exit 0 even on permission errors (outputs to stderr only). Changed to explicit empty check: `SIZE=$(du -sh ... | awk '{print $1}'); [ -z "$SIZE" ] && SIZE="0B"`. Affected 22 categories.
- **safe_du() helper function for set -euo pipefail** - Created `safe_du()` wrapper function that uses `set +e` in a subshell to prevent exit when `du` returns non-zero. Returns "0B" on failure/empty. Replaces 24 instances of `du -sh ... | awk '{print $1}'` pattern with proper error handling.
- **size_to_bytes() regex missing P/E units** - Fixed regex pattern from `[kmgt]b?$` to `[kmgtpe]b?$` to include Petabyte (P) and Exabyte (E) units that the conversion code already supported.

## [5.1.4] - 2026-03-29

### Bug Fixes

- **System temporary files permission error** - Fixed script exiting when `find` returns "Operation not permitted" on `/private/var/tmp` and `/private/tmp` by adding `|| TMP_COUNT=0` fallback and value normalization
- **User diagnostic reports permission error** - Fixed script exiting when `find` returns "Operation not permitted" on user diagnostic reports directory by adding `|| USER_COUNT=0` fallback and value normalization
- **System diagnostic reports permission error** - Fixed script exiting when `find` returns "Operation not permitted" on system diagnostic reports directory by adding `|| SYS_COUNT=0` fallback and value normalization
- **DS_Store count permission error** - Fixed script exiting when `find` returns "Operation not permitted" on iCloud directories by adding `|| DSSTORE_COUNT=0` fallback and value normalization

## [5.1.2] - 2026-03-29

### Bug Fixes

- **iOS backup permission error** - Fixed script exiting silently when `find` returns "Operation not permitted" on the iOS backup directory by adding `|| IOS_BACKUP_COUNT=0` fallback and value normalization to prevent `set -e` from triggering on expected permission errors

## [5.1.1] - 2026-03-28

### Bug Fixes

- **Time Machine snapshot count error** - Fixed `[: 0\n0: integer expression expected]` error when no Time Machine snapshots exist by using explicit exit code check instead of `|| echo "0"` fallback

## [5.1] - 2026-03-21

### Bug Fixes

- **Photos Library size calculation** - Fixed size reporting to only measure cache subdirectories (Thumbnails, Previews, etc.) instead of entire library, resolving 38GB vs 7GB discrepancy
- **npm cache size formatting** - Fixed size display showing "211B" instead of "211M" by using consistent byte calculation

### Technical

- Version bumped: 5.0 → 5.1

## [5.0] - 2026-03-20

### New Features

- **Homebrew Tap** - Install via `brew tap Carme99/tap && brew install mac-cleans`
  - Official Homebrew tap for easy installation and updates
  - Shell completions included (bash, zsh, fish)
- **Progress Spinner** - Visual spinner during long-running operations
- **Improved Error Messages** - Better context and recovery suggestions on failures

### Technical

- Version bumped: 4.3.0 → 5.0
- Shell completions added: `completions/` directory with bash, zsh, fish support
- Spinner functions added: `start_spinner()` and `stop_spinner()`

## [4.3.0] - 2026-03-20

### Security & Safety Fixes

- **#17 — Trash emptying now requires confirmation or `--force`/`--yes`**
  Previously trash was silently emptied without any user acknowledgement. Interactive mode now prompts; `--yes` or `--force` auto-approves.
- **#20 — iOS backup deletion verifies iCloud backup exists first**
  Before deleting local device backups (already requiring `--force`), the tool now checks that an iCloud backup folder is present.
- **#21 — iCloud sync check enhanced with pending-upload detection**
  `check_icloud_sync_status()` now also detects files pending upload via Spotlight metadata (`mdfind com_apple_clouddocs_isUploading`) in addition to existing download and brctl checks.
- **#22 — Xcode cleanup no longer bypassed by `--yes`; requires `--force`**
  `--yes` now prompts for Xcode confirmation. Only `--force` auto-approves this expensive operation.
- **#24 — Lock file check applies in dry-run mode**
  Removed the dry-run early-return from `acquire_lock()` to prevent concurrent dry-run/real-run race conditions.
- **#25 — Photos library path checked for symlinks before cleanup**
  Added `[ ! -L "$LIB_PATH" ]` guard to prevent cleaning through symlinks to other volumes.
- **#26 — Deletion failures now tracked and reported in summary**
  Critical deletion errors are counted via `ERRORS_OCCURRED` and surfaced in the final summary instead of being silently swallowed.
- **#27 — Minimum free disk space pre-check added**
  Mac-Clean now verifies at least 200MB is free before starting any cleanup operations via `check_minimum_disk_space()`.
- **#28 — Interrupt handler reports partial progress**
  When the script is interrupted (Ctrl-C/SIGTERM), it now reports how many categories completed and bytes freed before exiting.
- **#29 — Gradle, Bun, pnpm cache cleanup uses safe_clear_directory()**
  Replaced `rm -rf` with the safe deletion helper, adding symlink protection and consistent error handling.
- **#30 — Installer verifies SHA256 checksum after download**
  The installer now downloads and validates a SHA256SUMS file before installing. Mismatches cause a hard failure.

### Closed as Duplicate

- **#18, #19** — Duplicate of #17 (Trash emptied without confirmation)

### Closed as By Design

- **#23** — Docker error on cleanup when Docker is not running is expected and handled gracefully

### Technical

- Version bumped: 4.2.0 → 4.3.0

## [4.2.0] - 2026-03-07

### New Features

- **JSON Output**: New `--json` / `-j` flag to output cleanup results in JSON format (useful for automation/monitoring)
  - Outputs version, timestamp, dry-run status, processed/skipped categories, disk usage before/after, and space freed
  - Perfect for CI/CD pipelines, monitoring scripts, and logging systems
  - JSON output suppresses all normal log messages for clean programmatic consumption

### Improvements

#### Code Quality & Security

- **Config Parsing**: Replaced fragile `xargs` with bash parameter expansion for more robust whitespace handling
  - Old: `key=$(echo "$key" | xargs)` - could fail on edge cases
  - New: Bash parameter expansion `${key#"${key%%[![:space:]]*}"}` - pure bash, more reliable
- **Consistent Safe Deletion**: Trash section now uses `safe_clear_directory()` function for consistent behavior
  - Aligns with other cleanup sections
  - Uses `find -delete` operations instead of risky glob patterns
  - Better symlink protection
- **Config File Updates**: Updated `config.example` to v4.2.0 with `JSON_OUTPUT=false` option added

### Security Restorations (Critical)

- **Lock File Prevention**: Restored `acquire_lock()` function to prevent multiple instances running simultaneously
  - Uses atomic mkdir-based locking
  - Prevents race conditions and potential corruption
- **Symlink Protection Restored**: Added `! -L` checks to all 15+ deletion sites
  - Prevents symlink attacks where malicious symlinks could redirect deletions
  - Uses `safe_clear_directory()` for all cache cleanups
- **iCloud Sync Check Restored**: Reintroduced `check_icloud_sync_status()` function
  - Checks for `.icloud` placeholder files before deletion
  - Uses `brctl` to detect active uploads/downloads
  - Prevents permanent data loss from iCloud
- **Age-Based tmp Deletion Restored**: System temp files now use `mtime +3` (3 days old)
  - Changed from blanket `rm -rf /private/tmp/*` to `find -mtime +3 -delete`
  - Prevents breaking running processes that have active temp files
- **Cleanup on Exit**: Restored `cleanup_on_exit()` function
  - Ensures lock files are properly released on script exit
  - Prevents stale locks from blocking future runs

### JSON Output Improvements

- **Fixed JSON Validity**: Resolved issues with unquoted booleans and strings
  - `dry_run` now outputs proper JSON boolean (`true`/`false`)
  - Category names are now properly escaped for JSON
- **Consolidated JSON**: Removed fragmented JSON implementations
  - Single JSON output at script end
  - Cleaner code structure

### Installer Improvements

- **curl|bash Safety**: Fixed auto-sudo escalation when running via `curl | bash`
  - Detects stdin execution and provides clear error message
  - Prevents unexpected behavior from re-execing from stdin

#### Documentation Restructure

- **Moved to docs/ folder**: 7 documentation files relocated to maintain cleaner repository root
  - `ADVANCED.md` → `docs/advanced.md`
  - `FAQ.md` → `docs/faq.md`
  - `INSTALL.md` → `docs/install.md`
  - `QUICKSTART.md` → `docs/quickstart.md`
  - `SECURITY.md` → `docs/security.md`
  - `TROUBLESHOOTING.md` → `docs/troubleshooting.md`
  - `COMPARISON.md` → `docs/comparison.md`
  - `maccleans.conf.example` → `docs/config.example`
- **README Rewrite**: Transformed from 530-line comprehensive manual to 174-line quick-start hub
  - Added ASCII art logo with lightning bolt branding
  - Added 2 terminal output examples (--dry-run and --json)
  - Condensed and scannable for new users
  - Links to detailed docs for in-depth information
- **Internal Links Updated**: All cross-document links updated to reflect new `docs/` folder structure
  - Updated `CONTRIBUTING.md` doc references
  - Fixed links in all 7 moved documentation files
  - Updated `docs/index.md` navigation hub
- **Testing Documentation**: Added JSON output testing instructions to `CONTRIBUTING.md`
  - Added "Test JSON Output" section with examples
  - Updated manual testing checklist to include JSON validation

#### README Visual Enhancements

- **ASCII Art Logo**: Added branded header with lightning bolt icon
  - Professional and instantly recognizable
  - Version number prominently displayed
- **Terminal Output Examples**: Added 2 practical code blocks
  - `--dry-run`: Shows discovery process, category scans, and space calculation
  - `--json`: Demonstrates programmatic output structure for automation
  - Builds user trust by showing exactly what they'll see
- **Better User Experience**: Transformed from boring text-heavy to visually engaging with personality

### Repository Structure

- **Root Files**: Simplified to essential files only
  - `README.md`, `CHANGELOG.md`, `CONTRIBUTING.md`, `LICENSE` kept at root
  - `clean-mac-space.sh`, `installer.sh` at root
  - All detailed docs in `docs/` folder

### Technical Details

- **Version Bump**: 4.1.2 → 4.2.0 (minor version for new functionality)
- **No Breaking Changes**: All existing CLI flags and behavior preserved
- **Backward Compatible**: Existing config files work without modification
- **Code Size**: README reduced by 67% while improving usability

### Community Impact

- **Better Onboarding**: New users can understand and use MacCleans in seconds
- **Improved Safety**: More robust code reduces edge case failures
- **Automation Ready**: JSON output enables programmatic usage
- **Easier Maintenance**: Cleaner repository structure reduces cognitive load

## [4.1.0] - 2026-02-23

### New Features

- **New Command Name**: Script now installs as `Mac-Clean` (with backward-compatible symlink as `mac-clean`)
- **Visual Feedback**: Added spinners, colored status indicators, and progress messages for better UX
- **brew update Integration**: New `--update` / `-u` flag to run `brew update` before cleanup

### New Cleanup Categories (5 additional)

- **CocoaPods Cache**: Clean `$HOME/Library/Caches/CocoaPods` using `pod cache clean --all`
- **Gradle Cache**: Clean `$HOME/.gradle/caches`
- **Go Module Cache**: Clean `$GOPATH/pkg/mod` using `go clean -modcache`
- **Bun Cache**: Clean `$HOME/.bun/install/cache`
- **pnpm Store**: Clean pnpm store using `pnpm store prune`

### Improvements

- **Time Machine Snapshots**: Now shows accurate count only. Removed estimated size calculation since macOS doesn't expose snapshot sizes (previously showed unreliable estimates)
- **Interactive Menu**: Updated to include all 29 cleanup categories in correct order
- **Documentation**: Added attribution to [mac-cleanup](https://github.com/mac-cleanup/mac-cleanup-sh) for inspiration on several cleanup categories

### Bug Fixes

- Fixed section numbering after adding new categories (now 29 total, .DS_Store is section 29)
- Installer script now creates proper symlinks for backward compatibility

## [4.0.0] - 2026-02-21

### Major Features

- **Photos Library Multi-Library Support**: New `--photos-library` flag to target specific libraries or clean all libraries
  - `--photos-library "Photos Library"` - Target specific library by name
  - `--photos-library all` - Clean all found libraries
  - Default: cleans first/default library only
- **Enhanced iCloud Integration**: Improved iCloud Photos, Drive, and Mail cache cleanup with smart detection

### Breaking Changes

- Renamed `--skip-icloud-photos` → `--skip-photos-library`
- Renamed variable `SKIP_ICLOUD_PHOTOS` → `SKIP_PHOTOS_LIBRARY`
- Updated category name: "iCloud Photos Cache" → "Photos Library Cache"
- **FORCE=true in config now propagates to AUTO_YES=true**: This means iOS device backups and iCloud Drive files will be deleted without requiring 'DELETE' confirmation when FORCE=true is set in config. Users who previously relied on config-based FORCE=true for unattended runs should add `SKIP_IOS_BACKUPS=true` and `SKIP_ICLOUD_DRIVE=true` to their config if they don't want these categories deleted.

### Bug Fixes (v4.0.x)

#### Critical Fixes
- **Disk Space Calculation**: Fixed broken calculation using `df -h` multiplied by 512. Now uses `df -k` for accurate kilobyte-based calculation
- **iCloud Drive Scope**: Fixed deletion targeting ALL cloud providers (OneDrive, Google Drive, Box). Now only targets iCloud Drive folders using glob filter `iCloud Drive*`

#### High Severity Fixes
- **iOS Backups Safety**: Added `--force` requirement for iOS backup deletion (like iCloud Drive). Prevents accidental data loss
- **iCloud Drive Safety**: Added `--force` requirement with prominent warnings about data loss risk
- **Photos iCloud Detection**: Fixed `$HOME` → `$USER_HOME` for CloudDocs path (correct when running under sudo)
- **Summary Double-Counting**: Fixed Photos Library and iCloud Drive appearing in both processed AND skipped lists

#### Medium/Low Fixes
- **POSIX Compatibility**: Fixed `mapfile` command not found error on macOS (Bash 3.2). Replaced with POSIX-compatible `while IFS= read` loop
- **Dry-Run Photos Check**: Photos app running check now logs warning in dry-run mode without blocking space calculation
- **Photos App Auto-Close**: When `--yes` flag is used, script now auto-closes Photos app for safe cleanup
- **Section Numbering**: Fixed incorrect section numbers after .DS_Store was moved to end
- **iCloud Drive Recovery Message**: Fixed incorrect claim that files are "recoverable via Recently Deleted". Files are permanently deleted; local-only files pending upload cannot be recovered
- **Photos Database Safety**: Changed from `pkill -9` (SIGKILL) to graceful shutdown with SIGTERM + 5-second polling loop to prevent SQLite database corruption
- **Path Traversal Protection**: Added validation for `--photos-library` flag to reject path traversal attempts (`/` or `..`)
- **Diagnostic Reports Symlink**: Added symlink check to find commands in Diagnostic Reports section
- **BSD Find Compatibility**: Removed invalid `\! -L` predicate from find commands (not valid in macOS BSD find). Added `|| true` guards to prevent set -e aborts
- **Photos Summary Fix**: Added missing else clause so skipped Photos Library shows in summary
- **Dead Code Removal**: Removed redundant condition in iCloud Drive folder matching
- **Interactive Menu Security**: Replaced `eval` with case statement to prevent potential code injection
- **Photos Library Targeted Cleanup**: Only clear known cache subdirectories (derivatives, renders, caches, proxies), skip cpl/ to preserve iCloud sync state
- **Trash Cleanup**: Removed redundant find command (second -type f -name '.*' was unnecessary)
- **Code Refactoring**: Extracted Photos quit logic to reusable function to eliminate duplication
- **Robustness Improvements**: Improved parsing reliability for df, diskutil, docker, and uptime commands. Added numeric validation to prevent arithmetic errors

### Security & Stability

- **Eval vulnerability fix**: Replaced unsafe `eval` with safer alternatives
- **Symlink attack prevention**: Fixed trash deletion to prevent following malicious symlinks
- **Signal handling**: Graceful interruption handling

### Documentation

- **Complete README overhaul**: Modernized with badges, quick reference cards, categories grid
- **Added**: Quick Reference section, Command Reference tables, Why MacCleans comparison
- **Updated**: All documentation to reference v4.0
- **Danger Zone**: Added iCloud Drive to list of operations requiring `--force`

### Dependencies

- No new dependencies added
- Compatible with macOS 10.15+ (Catalina and later)
- Tested on macOS 26.4
- Compatible with Bash 3.2+ (macOS default)

### Documentation

- **Documentation restructure**: Moved guides to `docs/guides/` folder with new index at `docs/index.md`
- **New COMPARISON.md**: Tool comparison guide added
- **AI transparency**: Added AI assistance badges and acknowledgment
- **Security enhancements**: Expanded security policy with audit instructions
- **macOS 26.4**: Added compatibility badge and testing confirmation

## [3.3.0] - 2026-02-21

### Bug Fixes

- **Trash directory deletion**: Fixed trash cleanup to also delete directories, not just files. On macOS Trash commonly contains folders, so previous implementation left content behind and reported incorrect freed-space.
- **FORCE config propagation**: Fixed FORCE=true in config file to propagate to AUTO_YES, ensuring unattended runs don't block on prompts.

### Added

- **iCloud Photos cache cleanup**: New category to clear locally cached iCloud Photos (frees space while keeping photos in iCloud)
- **iCloud Drive offline files**: New category to remove offline copies of iCloud Drive files (files will re-download on demand)
- New `--skip-icloud-photos` flag
- New `--skip-icloud-drive` flag
- Added iCloud Photos and iCloud Drive to interactive mode selection

## [3.2.1] - 2026-02-21

### Security Fixes

- **Eval vulnerability fix**: Replaced unsafe `eval echo ~$SUDO_USER` with safer `getent passwd` or `/Users/$SUDO_USER` fallback. This prevents potential code injection if SUDO_USER is set to a malicious value.
- **Symlink attack prevention**: Fixed trash bin deletion to use `find -type f -delete` instead of glob expansion, preventing potential symlink attacks that could follow links outside the trash directory.

### Added

- **New --force/-f flag**: Skips ALL confirmation prompts including dangerous operations like XCode cleanup. Useful for fully unattended automation. Implies --yes.
- **Signal handling**: Added SIGINT/SIGTERM trap for graceful interruption. Script now cleanly exits with proper message when interrupted (Ctrl+C).

### Improved

- **XCode cleanup**: Now respects --force flag to allow fully automated XCode cleanup without prompts.

## [3.2.0] - 2026-02-20

### Added

- iOS/iPadOS update file (.ipsw) detection and cleanup
- New `--skip-ios-updates` flag
- Conservative and minimal profiles updated to skip iOS updates by default

## [3.1.0] - 2026-02-08

### Added

**Comprehensive Documentation Suite**
- New `CONTRIBUTING.md` - Complete contribution guide with:
  - Testing guidelines and code style standards
  - Step-by-step instructions for adding cleanup categories
  - Pull request submission process
  - ShellCheck compliance requirements
- New `ADVANCED.md` - Advanced usage guide covering:
  - Multi-profile configurations
  - CI/CD integration (GitHub Actions, GitLab, Jenkins, CircleCI)
  - Monitoring and alerting (Slack, Prometheus, macOS notifications)
  - Custom cleanup categories
  - Enterprise deployment strategies
  - Performance optimization
- New `FAQ.md` - Comprehensive FAQ with 50+ questions covering:
  - General questions and safety concerns
  - Features and usage
  - Troubleshooting
  - Performance and results
  - Technical details
- New `TROUBLESHOOTING.md` - Detailed troubleshooting guide with:
  - Solutions to common errors
  - Permission issue fixes
  - Installation and execution problems
  - Configuration troubleshooting
  - Recovery and rollback procedures
  - Debug mode instructions

**Educational Guides (docs/)**
- `docs/understanding-macos-caches.md` - Deep dive into cache types, how they work, and when to clean them
- `docs/xcode-derived-data-guide.md` - Comprehensive guide for iOS/Mac developers on managing XCode caches with real-world examples
- `docs/docker-cache-guide.md` - Docker cache management best practices and cleanup strategies
- `docs/automating-macos-maintenance.md` - Complete automation guide with cron, LaunchD, and custom scripts
- `docs/index.md` - Navigation hub for all documentation

**Documentation Improvements**
- Updated main README with comprehensive documentation section
- Added quick reference table for common use cases
- New documentation badge in README header
- Cross-referenced navigation between all docs
- Shield badges throughout all documentation

**Safety Improvements**
- Removed `--volumes` flag from Docker cleanup to protect database data
- Removed destructive `xcrun simctl erase all` from Simulator cleanup
- Docker cleanup now only removes dangling images, stopped containers, and unused networks
- Simulator cleanup now only removes unavailable simulators

**Space Tracking**
- Added byte-accurate space tracking to System Cache section
- Added byte-accurate space tracking to Temp Files section
- Added byte-accurate space tracking to .DS_Store section
- Added estimated reclaimable space tracking to Docker section

**Project Infrastructure**
- New `SECURITY.md` - Security policy with responsible disclosure guidelines
- New `.github/ISSUE_TEMPLATE/bug_report.md` - Structured bug report template
- New `.github/ISSUE_TEMPLATE/feature_request.md` - Feature request template
- New `.github/pull_request_template.md` - PR template with checklist
- Added table of contents to README
- Streamlined README by removing duplicate FAQ/Troubleshooting sections

### Improved

- Better documentation discoverability from main README
- Comprehensive resources for users at all skill levels
- Clear guidance for contributors
- Real-world examples and use cases throughout
- More accurate space freed reporting in summary
- Safer default behavior for Docker and Simulator cleanup

## [3.0.0] - 2026-02-02

See main branch for v3.0.0 release notes.

## [2.5.0] - 2026-02-01

### Added

**Configuration File Support**
- Load persistent settings from configuration files
- Config file locations (checked in order):
  - `~/.maccleans.conf`
  - `~/.config/maccleans/config`
  - `${XDG_CONFIG_HOME}/maccleans/config`
- Command line arguments override config file settings
- Example configuration file (`maccleans.conf.example`)
- Support for all existing flags in config format

**Colored Output**
- Visual feedback with color-coded messages:
  - Green (✓) for success messages
  - Yellow (⚠) for warnings
  - Red (✗) for errors
  - Magenta for section headers
  - Cyan for highlighted values
  - Dimmed timestamps for better readability
- Automatically disabled when output is not a terminal
- Manual override with `--no-color` flag
- Enhanced log functions: `log_success()`, `log_warning()`, `log_error()`

**Documentation**
- New `INSTALL.md` - Comprehensive installation guide with:
  - Multiple installation methods (curl download, git clone)
  - Configuration file setup instructions
  - Automated cleanup setup (cron, launchd examples)
  - Troubleshooting section
- Updated README with:
  - Installation section linking to INSTALL.md
  - Configuration file documentation
  - New `--no-color` flag documentation
  - Updated feature list

**New Command-Line Options**
- `--no-color` - Disable colored output

### Improved

- Better user experience with visual feedback
- Reduced need for repetitive command-line flags
- Easier automation setup with config files
- More professional output formatting

### Details

- Config file parser supports comments and blank lines
- Safe config loading with validation
- Color support respects terminal capabilities
- All existing functionality preserved
- No breaking changes

---

## [2.0.0] - 2026-01-31

### Added

**New Cleanup Categories**
- **Browser Cache Cleanup** - Remove caches from Chrome, Firefox, and Microsoft Edge
- **XCode Derived Data** - Clean XCode build cache with interactive safety warning
- **npm/Yarn Cache** - Clear Node.js package manager caches  
- **Python pip Cache** - Remove Python package manager cache
- **Trash Bin Cleanup** - Safely empty user trash directory
- **.DS_Store File Cleanup** - Remove macOS system metadata files from user home directory

**New Command-Line Options**
- `--skip-xcode` - Skip XCode derived data cleanup
- `--skip-browsers` - Skip browser cache cleanup (Chrome, Firefox, Edge)
- `--skip-npm` - Skip npm/yarn cache cleanup
- `--skip-pip` - Skip Python pip cache cleanup
- `--skip-trash` - Skip emptying trash bin
- `--skip-dsstore` - Skip .DS_Store file cleanup

**Documentation**
- Updated README with new V2 features and categories
- Added detailed .DS_Store explanation (what they are, why to clean them, safety)
- Added version history and upgrade notes
- Expanded command options table

**Safety Features**
- Interactive confirmation for XCode cleanup (prevents unexpected rebuilds)
- .DS_Store scope limited to user home directory
- Full dry-run preview support for all new categories
- Proper error suppression on all operations

### Details

- Expanded from 6 to 12 cleanup categories
- Increased script size from 427 to 779 lines (+352 lines)
- All new categories enabled by default (opt-out approach via `--skip-*` flags)
- Proper space tracking for all new categories in final summary
- Existence checks before cleanup operations

### Potential Space Recovery

V2.0.0 can now recover significantly more space:

- **XCode Derived Data**: 5-50GB+ (developers)
- **Browser Caches**: 1-5GB
- **npm/Yarn Cache**: 500MB-5GB (developers)
- **pip Cache**: 100MB-2GB (Python developers)
- **Trash Bin**: Variable
- **Plus existing categories**: 1-10GB

**Total potential recovery with V2.0.0: 10-70GB+** depending on system usage

### Breaking Changes

None! V2.0.0 is fully backward compatible:
- All existing flags work identically
- Existing scripts and cron jobs continue to work
- Only additions, no removals

---

## [1.0.0] - 2024-01-15

### Features

**Cleanup Categories**
- Time Machine Local Snapshots - Old backup snapshots with safety checks
- Homebrew Cache - Package manager cache and unused dependencies
- Application Caches - Spotify and Claude Desktop safe caches
- System Cache Files - Old system service caches (30+ days)
- Old Log Files - Log files older than 7 days
- System Temporary Files - `/tmp` and `/var/tmp` directories

**Command-Line Options**
- `--dry-run, -n` - Preview without deleting
- `--yes, -y` - Skip confirmation
- `--quiet, -q` - Minimal output for automation
- `--threshold N` - Only run if disk usage above N%
- `--skip-snapshots` - Skip Time Machine cleanup
- `--skip-homebrew` - Skip Homebrew cleanup
- `--skip-spotify` - Skip Spotify cleanup
- `--skip-claude` - Skip Claude cleanup
- `--help, -h` - Show help

**Safety Features**
- Confirmation prompts in interactive mode
- Dry-run preview mode
- Time Machine safety (won't delete if backup is running)
- Selective skip options
- Non-destructive (only removes regenerable files)
- Age-based deletion (only old files)

**Space Recovery**
Typical recovery of 1-10GB from:
- Homebrew Cache: 500MB-2GB
- Old Logs: 100MB-1GB
- Application Caches: 100MB-2GB
- Temp Files: 100MB-500MB

---

## Upgrade Path: V1 to V2

### What's New

V2.0.0 adds significant new cleanup capabilities, especially for developers:

1. **Browser cleanup** - Chrome, Firefox, Edge caches
2. **XCode support** - XCode derived data with safety warnings
3. **Package manager caches** - npm, yarn, pip cleanup
4. **Trash management** - Trash bin emptying
5. **System metadata** - .DS_Store file cleanup

### Migration

No breaking changes - all existing configurations continue to work:

```bash
# Old command (V1) still works exactly the same
sudo ./clean-mac-space.sh --skip-homebrew

# New features are automatic but can be disabled
sudo ./clean-mac-space.sh --skip-xcode --skip-browsers
```

To preserve V1 behavior exactly (skip all new features):

```bash
sudo ./clean-mac-space.sh \
  --skip-xcode \
  --skip-browsers \
  --skip-npm \
  --skip-pip \
  --skip-trash \
  --skip-dsstore
```

---

## Future Considerations

Potential features for future releases:
- Language-specific caches (Rust, Go, Ruby, Gradle, Maven, Composer)
- Docker/container cleanup
- Additional browser support (Brave, Opera, Arc)
- Interactive mode with menu selection
- Detailed recovery statistics per category
- Progress indicators for long operations
- Notification support (macOS notifications when complete)
