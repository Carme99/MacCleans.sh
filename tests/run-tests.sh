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
test_registry_has_33_entries() {
    # 28 numbered sections (1-28) + 2 sub-numbered (3a Spotify, 3b Claude)
    # + 3 new (29 Browser Testing Tool Caches, 30 Crash Reports,
    # 31 User Tool Caches) = 33 array entries. Adding a new category =
    # edit this count, add a line to CATEGORY_REGISTRY, and write one
    # section body.
    [ "${#CATEGORY_REGISTRY[@]}" -eq 33 ]
}
test_registry_has_new_categories() {
    # Verify the 3 new entries exist with the right skip_var wiring.
    local entry found_bt found_cr found_uc
    found_bt=0
    found_cr=0
    found_uc=0
    for entry in "${CATEGORY_REGISTRY[@]}"; do
        case "$(registry_get_skip_var "$entry")" in
            SKIP_BROWSER_TOOLS)   found_bt=1 ;;
            SKIP_CRASH_REPORTS)   found_cr=1 ;;
            SKIP_USER_TOOL_CACHES) found_uc=1 ;;
        esac
    done
    [ "$found_bt" -eq 1 ] && [ "$found_cr" -eq 1 ] && [ "$found_uc" -eq 1 ]
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
    # `[ ! -L`.
    #
    # We use a python helper because bash + multi-line + alternation is
    # painful. The script is well under 4000 lines so the perf cost is
    # trivial.
    python3 - "$SCRIPT_PATH" <<'PY'
import re
import sys

script_path = sys.argv[1]
with open(script_path) as f:
    lines = f.readlines()

# Find every line that contains `find ... -delete` and isn't inside the
# `safe_clear_directory` helper body (which is allowed to have multiple
# forms by design).
violations = []
in_safe_clear = False
brace_depth = 0
for i, line in enumerate(lines):
    n = i + 1

    # Track whether we're inside safe_clear_directory's function body.
    # The function definition starts with `safe_clear_directory() {` and
    # ends at the matching closing `}`.
    if re.search(r'^safe_clear_directory\s*\(\s*\)\s*\{', line):
        in_safe_clear = True
        brace_depth = 1
        continue
    if in_safe_clear:
        brace_depth += line.count('{') - line.count('}')
        if brace_depth <= 0:
            in_safe_clear = False
        continue

    # Look for `find ... -delete` on this line.
    if not re.search(r'\bfind\b.+\-delete\b', line):
        continue

    # Skip comment lines. `find -delete` mentioned in a comment is
    # documentation, not a real call.
    stripped = line.lstrip()
    if stripped.startswith('#'):
        continue

    # Same-line type filter is enough.
    if re.search(r'-(?:type\s+[fd]|type\s+[fd]\b)', line):
        continue
    if '-type f' in line or '-type d' in line:
        continue

    # Otherwise, look at the 5 preceding lines for a `[ ! -L "$X" ]`
    # parent guard. The guard is a common idiom and may span an `if`
    # statement boundary.
    context = ''.join(lines[max(0, i-5):i+1])
    if re.search(r'\[\s*!\s*-L\s+"\$', context):
        continue

    # System-path finds (no `$VAR` interpolation) are out of scope for
    # this test — the system owns /private/var/tmp and /private/tmp.
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

test_user_home_derivation_uses_sudo_user() {
    # The script's USER_HOME derivation must (a) use $SUDO_USER's passwd
    # entry under sudo (via getent), and (b) fall back to $HOME when
    # SUDO_USER is unset. We verify both by reading the relevant
    # source block from the script.
    #
    # Specifically, the block at "Get and validate actual user" must
    # contain:
    #   1. `if [ -n "${SUDO_USER:-}" ]` (or equivalent) to detect sudo
    #   2. `getent passwd "$SUDO_USER"` (or passwd lookup) to find the
    #      home dir, since $HOME is unreliable under sudo
    #   3. A fallback to `USER_HOME="$HOME"` when SUDO_USER is empty
    #
    # The audit caught a real bug where the script used $HOME for
    # CONFIG_FILES / LOCKDIR / check_icloud_backup_enabled, missing
    # the user's actual home under sudo. This test makes the derivation
    # pattern the canonical place to look.
    local block
    block=$(/usr/bin/awk '/^# Get and validate actual user/,/^fi$/' "$SCRIPT_PATH")

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
assert "CATEGORY_REGISTRY has 33 entries (1-28 + 3a/3b + 29/30/31)"  test_registry_has_33_entries
assert "CATEGORY_REGISTRY has new SKIP_BROWSER_TOOLS/CRASH_REPORTS/USER_TOOL_CACHES" test_registry_has_new_categories
assert "No literal '\$HOME/' in user paths (security audit)"            test_no_literal_home_in_user_paths
assert "Every 'find ... -delete' has -type filter or [ ! -L ] guard"    test_find_delete_has_type_or_symlink_guard
assert "USER_HOME derivation uses SUDO_USER with getent fallback"        test_user_home_derivation_uses_sudo_user

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
