#!/usr/bin/env bash
# run-tests.sh — smoke tests for the pure helpers in clean-mac-space.sh.
#
# Why not bats? An earlier draft of this PR used bats-core 1.13.0, but
# the version installed via Homebrew was returning 0 tests when run
# from the project's `tests/` directory (subshell path-resolution issue
# in bats-gather-tests that I couldn't pin down in a reasonable time
# budget). A plain bash runner is portable, has no external
# dependency, runs identically on macOS bundled bash 3.2.57 and
# modern Linux bash, and the user explicitly asked for a "starter
# set of ~10 tests" — not a framework migration.
#
# Each test is a shell function. The runner sources clean-mac-space.sh
# in TEST_MODE=1 (which skips the top-level _init_skip_defaults and
# parse_arguments calls), invokes each test function, and reports
# pass/fail with a TAP-style summary. Returns 0 if all pass, 1
# otherwise.

set -uo pipefail

# Resolve repo root regardless of where the script is invoked from.
TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$TESTS_DIR/.." && pwd)"

export TEST_MODE=1
# Source the script with `set +u` first — the script's own `set -u`
# combined with the `local value="${!_skip_var}"` indirection in
# validate_config (line ~281) fires an "unbound variable" error for
# any SKIP_X var that hasn't been populated yet. We don't call
# validate_config from these tests, but sourcing the script defines
# the function, and `set -u` in the source-guard timing window can
# trip on a stray read. After sourcing, restore our own -u.
set +u
# shellcheck source=/dev/null
source "$REPO_ROOT/clean-mac-space.sh"
set -u

# --- Tiny assertion framework ----------------------------------------------

PASS=0
FAIL=0
FAILED_TESTS=()

# assert <description> <test-command...>
# Runs the test command in a subshell. Exit 0 = pass, non-zero = fail.
assert() {
    local desc="$1"
    shift
    if "$@" >/dev/null 2>&1; then
        (( PASS++ )) || true
        printf "ok %d - %s\n" "$(( PASS + FAIL ))" "$desc"
    else
        (( FAIL++ )) || true
        FAILED_TESTS+=("$desc")
        printf "not ok %d - %s\n" "$(( PASS + FAIL ))" "$desc"
    fi
}

# assert_eq <description> <expected> <actual>
assert_eq() {
    local desc="$1" expected="$2" actual="$3"
    if [ "$expected" = "$actual" ]; then
        (( PASS++ )) || true
        printf "ok %d - %s\n" "$(( PASS + FAIL ))" "$desc"
    else
        (( FAIL++ )) || true
        FAILED_TESTS+=("$desc (expected '$expected', got '$actual')")
        printf "not ok %d - %s\n" "$(( PASS + FAIL ))" "$desc"
    fi
}

# --- Tests -----------------------------------------------------------------

test_validate_boolean_accepts_true_false() {
    validate_boolean "true"  && validate_boolean "false"
}
test_validate_boolean_rejects_others() {
    ! validate_boolean "TRUE" && ! validate_boolean "0" \
        && ! validate_boolean "" && ! validate_boolean "yes"
}
test_validate_numeric_in_range() {
    validate_numeric "0" 0 100 && validate_numeric "100" 0 100 \
        && validate_numeric "50" 0 100
}
test_validate_numeric_rejects_out_of_range() {
    ! validate_numeric "-1" 0 100 && ! validate_numeric "101" 0 100 \
        && ! validate_numeric "50.5" 0 100 && ! validate_numeric "abc" 0 100 \
        && ! validate_numeric "" 0 100
}
test_photos_name_accepts_plain() {
    validate_photos_library_name "Photos Library.photoslibrary" \
        && validate_photos_library_name "all" \
        && validate_photos_library_name "Vacation 2024"
}
test_photos_name_rejects_paths() {
    # "~/Library" is intentionally a LITERAL 9-char string here — the
    # validator must see ~ (no expansion) and reject it as a path.
    # Pass the tilde via an unquoted variable so shellcheck SC2088
    # doesn't fire (the literal "~/..." in double quotes is exactly
    # the pattern SC2088 warns about; the actual intent is the tilde
    # staying literal, which the unquoted var preserves).
    local tilde_path=\~/Library
    ! validate_photos_library_name "/etc/passwd" \
        && ! validate_photos_library_name "../etc" \
        && ! validate_photos_library_name 'Photos\Evil' \
        && ! validate_photos_library_name "$tilde_path"
}
test_photos_name_rejects_traversal_and_control() {
    ! validate_photos_library_name ".." \
        && ! validate_photos_library_name "foo..bar" \
        && ! validate_photos_library_name $'foo\nbar'
}
test_size_to_bytes_known_units() {
    [ "$(size_to_bytes "1B")"  = "1" ] \
        && [ "$(size_to_bytes "1KB")" = "1024" ] \
        && [ "$(size_to_bytes "1MB")" = "1048576" ] \
        && [ "$(size_to_bytes "1GB")" = "1073741824" ] \
        && [ "$(size_to_bytes "2.5GB")" = "2684354560" ] \
        && [ "$(size_to_bytes "100")" = "100" ]
}
test_size_to_bytes_case_insensitive() {
    [ "$(size_to_bytes "1k")"  = "$(size_to_bytes "1K")"  ] \
        && [ "$(size_to_bytes "1kb")" = "$(size_to_bytes "1KB")" ] \
        && [ "$(size_to_bytes "1mb")" = "$(size_to_bytes "1MB")" ]
}
test_registry_get_skip_var() {
    [ "$(registry_get_skip_var '1|Time Machine Local Snapshots|SKIP_SNAPSHOTS')" = "SKIP_SNAPSHOTS" ] \
        && [ "$(registry_get_skip_var '2|Homebrew Cache|SKIP_HOMEBREW')" = "SKIP_HOMEBREW" ] \
        && [ "$(registry_get_skip_var '3a|Spotify Cache|SKIP_SPOTIFY')" = "SKIP_SPOTIFY" ] \
        && [ "$(registry_get_skip_var '3|Application Cache Files|')" = "" ]
}
test_registry_get_display() {
    [ "$(registry_get_display '1|Time Machine Local Snapshots|SKIP_SNAPSHOTS')" = "Time Machine Local Snapshots" ] \
        && [ "$(registry_get_display '3a|Spotify Cache|SKIP_SPOTIFY')" = "Spotify Cache" ] \
        && [ "$(registry_get_display '7|Browser Caches (Chrome, Firefox, Edge)|SKIP_BROWSERS')" = "Browser Caches (Chrome, Firefox, Edge)" ] \
        && [ "$(registry_get_display '3|Application Cache Files|')" = "Application Cache Files" ]
}
test_init_skip_defaults_sets_every_skip_to_false() {
    local rc=0 entry skip_var
    for entry in "${CATEGORY_REGISTRY[@]}"; do
        skip_var=$(registry_get_skip_var "$entry")
        [ -n "$skip_var" ] || continue
        unset "$skip_var"
    done
    _init_skip_defaults
    for entry in "${CATEGORY_REGISTRY[@]}"; do
        skip_var=$(registry_get_skip_var "$entry")
        [ -n "$skip_var" ] || continue
        if [ "${!skip_var}" != "false" ]; then
            echo "$skip_var is '${!skip_var}', expected 'false'" >&2
            rc=1
        fi
    done
    return $rc
}
test_registry_has_at_least_34_entries() {
    # Lower bound, not equality: the registry grows in feature PRs
    # (v5.6.0 added 29-31, v5.8.0 added 34), and an exact-count assert
    # makes every category PR collide on this line. Category PRs add
    # no count assertion of their own; presence is enforced by the
    # dynamic registry-walk tests below.
    [ "${#CATEGORY_REGISTRY[@]}" -ge 34 ]
}
test_registry_has_new_categories() {
    # Verify the v5.6.0 3 new entries (29, 30, 31) and the v5.8.0
    # entry (34 Xcode Archives) exist with the right skip_var wiring.
    local entry found_bt found_cr found_uc found_xa
    found_bt=0
    found_cr=0
    found_uc=0
    found_xa=0
    for entry in "${CATEGORY_REGISTRY[@]}"; do
        case "$(registry_get_skip_var "$entry")" in
            SKIP_BROWSER_TOOLS)    found_bt=1 ;;
            SKIP_CRASH_REPORTS)    found_cr=1 ;;
            SKIP_USER_TOOL_CACHES) found_uc=1 ;;
            SKIP_XCODE_ARCHIVES)   found_xa=1 ;;
        esac
    done
    [ "$found_bt" -eq 1 ] && [ "$found_cr" -eq 1 ] && [ "$found_uc" -eq 1 ] && [ "$found_xa" -eq 1 ]
}

# --- Security audit tests (added 2026-06-05) -------------------------------
#
# These tests codify the three rules from the security audit pass:
#   1. No section body or infrastructure code uses literal "$HOME/" for user
#      paths — must use $USER_HOME (set from $SUDO_USER's passwd entry) so
#      the user's actual home is targeted under `sudo`.
#   2. Every `find ... -delete` is either guarded by `-type f`/`-type d` (which
#      inherently exclude symlinks) or wrapped in a `[ ! -L ]` parent check.
#      Both are safe; the rule is "at least one of the two must be present."
#   3. The script's source-guard + sudo check + USER_HOME derivation live in
#      the right order: source guard returns when sourced, sudo check exits
#      when not root, USER_HOME is derived before any code that uses it.
#
# A regression on any of these would silently break the script under sudo
# (e.g., a future PR adding a section body with `"$HOME/foo"` would miss
# the user's real home when run with `sudo Mac-Clean`). These tests catch
# that at CI time.

# Path to the script (we read it directly for static checks).
SCRIPT_PATH="$REPO_ROOT/clean-mac-space.sh"

test_no_literal_home_in_user_paths() {
    # No `"\$HOME/` (literal $HOME with trailing slash, indicating a user
    # path) anywhere in the script. The legitimate fallback
    # `USER_HOME="$HOME"` (no slash) at the end of the sudo/non-sudo
    # block is fine; we look for `"\$HOME/` specifically.
    local hits
    hits=$(/usr/bin/grep -nF '"\$HOME/' "$SCRIPT_PATH" || true)
    if [ -n "$hits" ]; then
        echo "Found literal '\$HOME/' (user-path uses of \$HOME instead of \$USER_HOME):" >&2
        echo "$hits" >&2
        return 1
    fi
    return 0
}

test_find_delete_has_type_or_symlink_guard() {
    # Every line containing `find ... -delete` must also have either a
    # type filter (`-type f` or `-type d`) somewhere on the same line, OR
    # be preceded (within the immediately surrounding block) by a
    # `[ ! -L ]` parent guard. The check is structural: we look at the
    # find -delete line itself for `-type`, and at the prior 5 lines for
    # `[ ! -L ]`.
    #
    # We use a python helper because bash + multi-line + alternation is
    # painful. The script is well under 4000 lines so the perf cost is
    # trivial.
    #
    # Recognised safe patterns (any one of these is enough):
    #   - Same line: `find ... -type f ... -delete` or `-type d`
    #   - Within the prior 5 lines: `[ ! -L "$X" ]`, `[ ! -L $X ]`,
    #     `[ ! -L "${X}" ]`, etc. (any quoting style on the path arg)
    #   - Inside the `safe_clear_directory` function body (excluded —
    #     it has its own internal symlink check)
    #   - System-path finds (no `$VAR` interpolation) for paths the
    #     system owns: /private/var/tmp, /private/tmp
    python3 - "$SCRIPT_PATH" <<'PY'
import re
import sys

script_path = sys.argv[1]
with open(script_path) as f:
    lines = f.readlines()

violations = []
in_safe_clear = False
brace_depth = 0

# Symlink-guard regex. Accepts any of the common quoting styles for
# the path argument: "$X", "${X}", $X, or `${X}`. Tabs / multiple
# spaces between `[`, `!`, `-L` and the path are allowed.
SYM_GUARD_RE = re.compile(
    r'\[\s*!\s*-L\s+'            # [ ! -L
    r'(?:'                         # path arg, any of:
    r'"\$[\w]+"'                  #   "$X"
    r'|\$\{[\w]+\}'               #   ${X}
    r'|"\$?\{?[\w]+\}?"'          #   "$X" / "${X}" / "$X" / "X"
    r'|\$[\w]+'                   #   $X
    r')'
    r'\s*\]'                      # closing ]
)

# safe_clear_directory body detection. Whitespace between tokens is
# flexible to allow for refactoring.
def is_safe_clear_def(line):
    return bool(re.search(
        r'^safe_clear_directory\s*\(\s*\)\s*\{',
        line))

for i, line in enumerate(lines):
    n = i + 1

    if is_safe_clear_def(line):
        in_safe_clear = True
        brace_depth = 1
        continue
    if in_safe_clear:
        brace_depth += line.count('{') - line.count('}')
        if brace_depth <= 0:
            in_safe_clear = False
        continue

    if not re.search(r'\bfind\b.+\-delete\b', line):
        continue

    # Skip comment lines.
    stripped = line.lstrip()
    if stripped.startswith('#'):
        continue

    # Same-line type filter.
    if '-type f' in line or '-type d' in line:
        continue

    # Otherwise, look at the 5 preceding lines for a [ ! -L ] guard.
    context = ''.join(lines[max(0, i-5):i+1])
    if SYM_GUARD_RE.search(context):
        continue

    # System-path finds.
    if '/private/var/tmp' in line or '/private/tmp' in line:
        continue

    violations.append((n, line.rstrip()))

if violations:
    print('find -delete lines without type filter or [ ! -L ] guard:', file=sys.stderr)
    for n, line in violations:
        print(f'  {n}: {line}', file=sys.stderr)
    sys.exit(1)
PY
}

test_record_category_size_helper() {
    # Verifies the new `record_category_size` helper exists and stores
    # the per-category size info via indirect variable expansion
    # (DETAIL_BYTES_<name> / DETAIL_HUMAN_<name>). Used by the
    # --json output to embed estimated_bytes / estimated_human in the
    # "details" object. The previous implementation used a flat
    # string accumulator (CATEGORY_SIZES_JSON) which produced
    # duplicate keys in the output JSON when both a registry entry
    # and a size call existed for the same category — the
    # indirect-var approach lets the main loop merge the size info
    # into the per-category fragment, emitting each category exactly
    # once.
    if ! declare -f record_category_size >/dev/null 2>&1; then
        echo "record_category_size helper is not defined" >&2
        return 1
    fi
    # Use a unique name so we don't collide with the v5.6.0 sections
    # that also call record_category_size in some test setups.
    local TEST_NAME="RecordCategorySize Test Subject"
    local BYTES_VAR="DETAIL_BYTES_RecordCategorySize_Test_Subject"
    local HUMAN_VAR="DETAIL_HUMAN_RecordCategorySize_Test_Subject"
    # Clean up any leftover state from a previous test run
    unset "$BYTES_VAR" "$HUMAN_VAR"
    record_category_size "$TEST_NAME" 1024 "1.0K"
    # Verify the indirect vars got set
    local recorded_bytes="${!BYTES_VAR:-}"
    local recorded_human="${!HUMAN_VAR:-}"
    if [ "$recorded_bytes" != "1024" ]; then
        echo "record_category_size did not set DETAIL_BYTES_<name>=1024 (got '$recorded_bytes')" >&2
        return 1
    fi
    if [ "$recorded_human" != "1.0K" ]; then
        echo "record_category_size did not set DETAIL_HUMAN_<name>=1.0K (got '$recorded_human')" >&2
        return 1
    fi
    # Cleanup
    unset "$BYTES_VAR" "$HUMAN_VAR"
    return 0
}

test_json_output_uses_details() {
    # Static check: the --json output block in clean-mac-space.sh
    # should include a "details" object (added in v5.7.0). Scoped
    # to the JSON emitter template (`cat <<EOF` block) so a comment
    # mentioning `"details":` elsewhere in the file doesn't false-
    # positive. We grep for the more specific pattern `"details":
    # $json_details` — that's the line that actually emits the
    # per-category details into the output.
    local json_template
    json_template=$(/usr/bin/awk '/^[[:space:]]*cat <<EOF$/,/^EOF$/' "$SCRIPT_PATH")
    if [ -z "$json_template" ]; then
        echo "could not extract JSON emitter block from $SCRIPT_PATH" >&2
        return 1
    fi
    if ! echo "$json_template" | /usr/bin/grep -qF '"details": $json_details'; then
        echo '--json output block does not include a "details": $json_details field' >&2
        echo '(the per-category details object is the v5.7.0 structured-output feature)' >&2
        return 1
    fi
    return 0
}

test_release_sh_check_mode() {
    # The release script should accept --check (added in v5.7.0) and
    # have a --check branch in the source. We grep the file rather
    # than running the script because --check requires git/CHANGELOG
    # state that's not portable across the test environment.
    if ! /usr/bin/grep -qF -- '--check' "$REPO_ROOT/scripts/release.sh"; then
        echo "scripts/release.sh does not mention --check flag" >&2
        return 1
    fi
    if ! /usr/bin/grep -qE 'CHECK_ONLY' "$REPO_ROOT/scripts/release.sh"; then
        echo "scripts/release.sh does not have a CHECK_ONLY branch" >&2
        return 1
    fi
    return 0
}

test_release_check_workflow_exists() {
    # The CI gate (.github/workflows/release-check.yml) should exist
    # so the --check mode actually runs on every PR.
    if [ ! -f "$REPO_ROOT/.github/workflows/release-check.yml" ]; then
        echo ".github/workflows/release-check.yml not found" >&2
        return 1
    fi
    if ! /usr/bin/grep -qF 'release.sh' "$REPO_ROOT/.github/workflows/release-check.yml"; then
        echo "release-check.yml does not reference release.sh" >&2
        return 1
    fi
    return 0
}

test_completions_include_xcode_archives_skip_flag() {
    # v5.8.0 added --skip-xcode-archives for the new #34 category.
    # Without this test, a future refactor of the completion files
    # could quietly drop the new flag (the same bug class that
    # test_completions_include_v56_skip_flags covers for v5.6.0).
    if ! /usr/bin/grep -qF -e "--skip-xcode-archives" "$REPO_ROOT/completions/mac-cleans.bash"; then
        echo "completions/mac-cleans.bash missing --skip-xcode-archives" >&2
        return 1
    fi
    if ! /usr/bin/grep -qF -e "--skip-xcode-archives" "$REPO_ROOT/completions/_mac-cleans"; then
        echo "completions/_mac-cleans missing --skip-xcode-archives" >&2
        return 1
    fi
    if ! /usr/bin/grep -qF -e "-l skip-xcode-archives" "$REPO_ROOT/completions/mac-cleans.fish"; then
        echo "completions/mac-cleans.fish missing -l skip-xcode-archives" >&2
        return 1
    fi
    return 0
}
test_completions_include_v56_skip_flags() {
    # v5.6.0 added --skip-browser-tools, --skip-crash-reports, and
    # --skip-user-tool-caches but missed updating the bash/zsh/fish
    # completions. v5.7.0 added them. This test fails if any future
    # PR adds a new --skip-X flag and forgets the completions again.
    #
    # Note: bash and zsh use the literal --skip-foo token in their
    # options arrays; fish uses `-l skip-foo` (the long-form flag
    # pattern, no leading --). So we grep for "skip-foo" in all 3.
    local flag
    for flag in browser-tools crash-reports user-tool-caches; do
        # bash: literal --skip-foo in the options array
        if ! /usr/bin/grep -qF -e "--skip-$flag" "$REPO_ROOT/completions/mac-cleans.bash"; then
            echo "completions/mac-cleans.bash missing --skip-$flag" >&2
            return 1
        fi
        # zsh: literal --skip-foo in the options array
        if ! /usr/bin/grep -qF -e "--skip-$flag" "$REPO_ROOT/completions/_mac-cleans"; then
            echo "completions/_mac-cleans missing --skip-$flag" >&2
            return 1
        fi
        # fish: -l skip-foo (long-form flag, no leading --)
        if ! /usr/bin/grep -qF -e "-l skip-$flag" "$REPO_ROOT/completions/mac-cleans.fish"; then
            echo "completions/mac-cleans.fish missing -l skip-$flag" >&2
            return 1
        fi
    done
    return 0
}
test_config_loader_covers_every_registry_skip_x() {
    # load_config_file's case statement must have a SKIP_X arm for every
    # SKIP_X var declared in CATEGORY_REGISTRY. Otherwise a user's
    # `SKIP_NEW_CATEGORY=true` in ~/.maccleans.conf silently falls through
    # to the "Unknown config key" warning, the var stays at its default
    # `false`, and the category gets cleaned anyway.
    #
    # v5.6.0 (PR #84) added 3 categories — SKIP_BROWSER_TOOLS,
    # SKIP_CRASH_REPORTS, SKIP_USER_TOOL_CACHES — and updated the
    # registry, the --skip-X flags, the section bodies, and the
    # completions, but missed the load_config_file case statement AND
    # maccleans.conf.example. Caught by the v5.7.0 UX review.
    #
    # Constrain the extraction to the CATEGORY_REGISTRY=() block (between
    # the assignment opener and the closing paren). If the registry ever
    # moves, refactor the extractor first; this test should fail loud
    # rather than silently miss vars.
    local registry_block
    registry_block=$(/usr/bin/awk '
        /^CATEGORY_REGISTRY=\(/   { in_block=1; next }
        in_block && /^\)/         { in_block=0 }
        in_block                  { print }
    ' "$SCRIPT_PATH")
    if [ -z "$registry_block" ]; then
        echo "CATEGORY_REGISTRY=() block not found in $SCRIPT_PATH — test misconfigured" >&2
        return 1
    fi
    local registry_skip
    registry_skip=$(printf '%s\n' "$registry_block" | /usr/bin/grep -oE '\|SKIP_[A-Z_]+' | /usr/bin/sed -E 's/^\|//' | /usr/bin/sort -u)
    if [ -z "$registry_skip" ]; then
        echo "No SKIP_X vars found in CATEGORY_REGISTRY — test misconfigured" >&2
        return 1
    fi
    local missing=()
    local var
    while IFS= read -r var; do
        # Anchored match: a case arm starts with optional leading whitespace
        # then the var name followed by ')'. The FORCE_*/VERBOSE/etc. arms
        # are non-SKIP keys and are not checked here — only SKIP_X.
        if ! /usr/bin/grep -qE "^[[:space:]]+${var}\)" "$SCRIPT_PATH"; then
            missing+=("$var")
        fi
    done <<< "$registry_skip"
    if [ "${#missing[@]}" -gt 0 ]; then
        echo "load_config_file case statement is missing arms for: ${missing[*]}" >&2
        echo "Every SKIP_X var declared in CATEGORY_REGISTRY must have a case arm" >&2
        echo "in load_config_file (otherwise config-file settings are silently ignored)." >&2
        return 1
    fi
    return 0
}
test_interactive_menu_handles_all_digit_ranges() {
    # The menu tip says "Numbers 1-${#categories[@]} also work for quick
    # toggle". The case statement in interactive_selection's main loop
    # must handle the full range, not just 1-9 (with 10-13 special-cased).
    # PR #88 UX-1: prior version only handled 1-9 + 10-13, so typing
    # 14-30 was silently swallowed.
    #
    # The fix is a single `[1-9])` case that reads up to 1 more char
    # for 2-digit numbers and validates against the registered total.
    # This test asserts that the case pattern is `[1-9])` (not separate
    # `1)`, `2)`, ... `9)` cases) and that there's a numeric range check.
    if /usr/bin/grep -qE '^\s+[1-9]\)\s*$' "$SCRIPT_PATH"; then
        # Old style: per-digit cases. The fix removed these.
        echo "Interactive menu still has per-digit case arms (1)..9))." >&2
        echo "Should be a single [1-9]) case that handles 2-digit lookahead." >&2
        return 1
    fi
    if ! /usr/bin/grep -qE '^\s+\[1-9\]\)' "$SCRIPT_PATH"; then
        echo "Interactive menu is missing the [1-9]) case arm." >&2
        return 1
    fi
    if ! /usr/bin/grep -qE 'num[0-9]*=\"\$\{(first_key|key)\}\$\{next_key\}\"' "$SCRIPT_PATH"; then
        echo "Interactive menu digit handler does not form a 2-digit num." >&2
        return 1
    fi
    return 0
}
test_config_files_defined_before_load_config_file_call() {
    # The audit (PR #85) moved CONFIG_FILES to after USER_HOME derivation
    # so it could use $USER_HOME, but accidentally left the call at
    # its old position at the top of the script — the result was a
    # for-loop in load_config_file iterating an empty array, silently
    # loading no config. This test enforces the ordering.
    local config_files_line load_call_line
    config_files_line=$(/usr/bin/grep -nE '^CONFIG_FILES=\(' "$SCRIPT_PATH" | /usr/bin/head -1 | /usr/bin/cut -d: -f1 || echo 0)
    load_call_line=$(/usr/bin/grep -nE '^\s*load_config_file\s*$' "$SCRIPT_PATH" | /usr/bin/head -1 | /usr/bin/cut -d: -f1 || echo 0)
    if [ -z "$config_files_line" ] || [ "$config_files_line" = "0" ]; then
        echo "No CONFIG_FILES=( assignment found in script" >&2
        return 1
    fi
    if [ -z "$load_call_line" ] || [ "$load_call_line" = "0" ]; then
        echo "No load_config_file call site found in script" >&2
        return 1
    fi
    if [ "$config_files_line" -ge "$load_call_line" ]; then
        echo "CONFIG_FILES is at line $config_files_line but load_config_file is called at line $load_call_line" >&2
        echo "CONFIG_FILES must be defined before load_config_file is called" >&2
        return 1
    fi
    return 0
}
test_user_home_derivation_uses_sudo_user() {
    # The script's USER_HOME derivation must (a) use $SUDO_USER's passwd
    # entry under sudo (via getent), and (b) fall back to $HOME when
    # SUDO_USER is unset. We verify both by reading the relevant
    # source block from the script.
    #
    # The block is bounded by a stable marker comment
    # ("AUDIT_MARKER: end of sudo_user_derivation_block") so the test
    # doesn't depend on a closing `fi` line being at column 0 (which
    # would silently break if someone un-indented the inner `fi`).
    #
    # The audit caught a real bug where the script used $HOME for
    # CONFIG_FILES / LOCKDIR / check_icloud_backup_enabled, missing
    # the user's actual home under sudo. This test makes the derivation
    # pattern the canonical place to look.
    local block
    block=$(/usr/bin/awk '/^# Get and validate actual user/,/^# AUDIT_MARKER: end of sudo_user_derivation_block$/' "$SCRIPT_PATH")

    if ! echo "$block" | /usr/bin/grep -qF 'SUDO_USER'; then
        echo "USER_HOME derivation does not check SUDO_USER:" >&2
        echo "$block" >&2
        return 1
    fi
    if ! echo "$block" | /usr/bin/grep -qE 'getent passwd|/Users/\$SUDO_USER'; then
        echo "USER_HOME derivation does not look up SUDO_USER's home via getent or /Users fallback:" >&2
        echo "$block" >&2
        return 1
    fi
    if ! echo "$block" | /usr/bin/grep -qF 'USER_HOME="$HOME"'; then
        echo "USER_HOME derivation does not fall back to \$HOME when SUDO_USER is empty:" >&2
        echo "$block" >&2
        return 1
    fi
    return 0
}

# --- Run -------------------------------------------------------------------

echo "Running smoke tests for clean-mac-space.sh helpers..."
echo ""

assert "validate_boolean accepts true / false"                 test_validate_boolean_accepts_true_false
assert "validate_boolean rejects TRUE, 0, empty, yes"          test_validate_boolean_rejects_others
assert "validate_numeric accepts 0, 100, 50"                   test_validate_numeric_in_range
assert "validate_numeric rejects -1, 101, 50.5, abc, empty"    test_validate_numeric_rejects_out_of_range
assert "validate_photos_library_name accepts plain names"      test_photos_name_accepts_plain
assert "validate_photos_library_name rejects paths"            test_photos_name_rejects_paths
assert "validate_photos_library_name rejects .. and control"   test_photos_name_rejects_traversal_and_control
assert "size_to_bytes converts B/KB/MB/GB and bare ints"       test_size_to_bytes_known_units
assert "size_to_bytes is case-insensitive on unit"             test_size_to_bytes_case_insensitive
assert "registry_get_skip_var returns last field"              test_registry_get_skip_var
assert "registry_get_display returns middle field"             test_registry_get_display
assert "_init_skip_defaults sets every SKIP_X to false"        test_init_skip_defaults_sets_every_skip_to_false
assert "CATEGORY_REGISTRY has at least 34 entries (1-28 + 3a/3b + 29-31 + 34)"  test_registry_has_at_least_34_entries
assert "CATEGORY_REGISTRY has new SKIP_BROWSER_TOOLS/CRASH_REPORTS/USER_TOOL_CACHES/XCODE_ARCHIVES" test_registry_has_new_categories
assert "No literal '\$HOME/' in user paths (security audit)"            test_no_literal_home_in_user_paths
assert "Every 'find ... -delete' has -type filter or [ ! -L ] guard"    test_find_delete_has_type_or_symlink_guard
assert "USER_HOME derivation uses SUDO_USER with getent fallback"        test_user_home_derivation_uses_sudo_user
assert "CONFIG_FILES=() defined before load_config_file is called"      test_config_files_defined_before_load_config_file_call
assert "record_category_size helper builds the size JSON accumulator"   test_record_category_size_helper
assert '--json output block includes the "details" object'              test_json_output_uses_details
assert "scripts/release.sh supports --check mode"                       test_release_sh_check_mode
assert ".github/workflows/release-check.yml exists"                      test_release_check_workflow_exists
assert "Completions include the 3 v5.6.0 --skip-X flags"                 test_completions_include_v56_skip_flags
assert "Completions include the v5.8.0 --skip-xcode-archives flag"         test_completions_include_xcode_archives_skip_flag
assert "load_config_file case statement covers every registry SKIP_X"     test_config_loader_covers_every_registry_skip_x
assert "Interactive menu digit handler covers 1-N (no silent swallow)"    test_interactive_menu_handles_all_digit_ranges

TOTAL=$(( PASS + FAIL ))
echo ""
echo "1..${TOTAL}"
echo "# tests ${PASS} passed, ${FAIL} failed"
if [ "$FAIL" -gt 0 ]; then
    echo "# failed:" >&2
    for t in "${FAILED_TESTS[@]}"; do
        echo "#   $t" >&2
    done
    exit 1
fi
exit 0
