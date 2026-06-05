#!/usr/bin/env bash
# scripts/release.sh — pre-tag release prep for MacCleans.sh
#
# Bundles the three manual steps that v5.2.0 forgot to do together, so the
# next release can't repeat that drift:
#   1. Bump VERSION in clean-mac-space.sh
#   2. Regenerate EXPECTED_HASH in installer.sh
#   3. Run syntax + shellcheck + dry-run sanity checks
# Then stage the changes and prompt for the commit.
#
# Does NOT push, tag, or release — that's the release workflow's job
# (push the tag and .github/workflows/release.yml handles the rest).
#
# Usage: scripts/release.sh X.Y.Z [--dry-run]

set -euo pipefail

# --- Helpers ---------------------------------------------------------------

die() { echo "ERROR: $*" >&2; exit 1; }

# Run a shellcheck invocation. On macOS BSD shellcheck works fine;
# on Linux the homebrew path is /usr/bin/shellcheck.
shellcheck_run() {
    if command -v shellcheck >/dev/null 2>&1; then
        shellcheck -f gcc -S warning "$@"
    else
        echo "  (shellcheck not installed locally; skipping)" >&2
    fi
}

# Compute a SHA-256 of a file. shasum is the macOS default; sha256sum
# is what most Linux distros ship. Try shasum first, then sha256sum.
sha256_file() {
    if command -v shasum >/dev/null 2>&1; then
        shasum -a 256 "$1" | awk '{print $1}'
    elif command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$1" | awk '{print $1}'
    else
        die "neither shasum nor sha256sum is available; cannot compute SHA-256"
    fi
}

# --- Preflight -------------------------------------------------------------

# X.Y.Z is required for the actual prep mode (--dry-run or no flag),
# OPTIONAL for --check mode (the CI workflow calls
# `scripts/release.sh --check` with no version arg, and the check
# uses SCRIPT_VERSION as the fallback for the remediation hint).
# Pre-scan the args so --check / --dry-run can appear before OR
# after the X.Y.Z (humans sometimes write either order).
CHECK_ONLY=false
DRY_RUN=false
HAS_CHECK=false
HAS_DRY_RUN=false
VERSION_ARG=""
for arg in "$@"; do
    if [[ "$arg" == "--check" ]]; then
        HAS_CHECK=true
    elif [[ "$arg" == "--dry-run" ]]; then
        HAS_DRY_RUN=true
    elif [[ "$arg" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        VERSION_ARG="$arg"
    fi
done
[[ -n "$VERSION_ARG" && "$#" -gt 2 ]] && \
    die "usage: scripts/release.sh X.Y.Z [--dry-run|--check]"

if $HAS_CHECK; then
    CHECK_ONLY=true
    VERSION="$VERSION_ARG"  # may be empty; validated lazily
else
    DRY_RUN=$HAS_DRY_RUN
    [[ -n "$VERSION_ARG" ]] || \
        die "usage: scripts/release.sh X.Y.Z [--dry-run|--check]"
    VERSION="$VERSION_ARG"
    # Reject obviously bad versions in prep mode (in --check mode
    # we don't validate this; the check uses SCRIPT_VERSION as the
    # fallback hint if VERSION is empty or non-semver).
    [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || \
        die "version '$VERSION' is not X.Y.Z format (e.g. 5.4.0)"
fi

# Resolve the four files that the rest of the script (and the
# --check mode below) reference. Doing this here so the --check
# block doesn't have to duplicate the lookup logic.
CLEAN_FILE="clean-mac-space.sh"
[[ -f "$CLEAN_FILE" ]] || die "$CLEAN_FILE not found"

INSTALLER="installer.sh"
[[ -f "$INSTALLER" ]] || die "$INSTALLER not found"

OLD_HASH=$(grep -E '^EXPECTED_HASH=' "$INSTALLER" | head -1 | sed -E 's/^EXPECTED_HASH="([0-9a-f]+)"$/\1/')
[[ -n "$OLD_HASH" ]] || die "could not find EXPECTED_HASH in $INSTALLER"

CHANGELOG="CHANGELOG.md"

# --- --check mode (CI gate) -----------------------------------------------
# Verify the repo's release state is consistent without making any
# changes. Used by .github/workflows/release-check.yml to fail PRs
# that would create drift. Exits 0 on clean, 1 on drift. Does NOT
# require a clean working tree or a specific branch — the check is
# read-only so it can run in any context (including dirty worktrees
# during a release prep, where the script is explicitly run from main).
#
# The X.Y.Z argument is OPTIONAL in --check mode. If not given (or
# not a valid semver), the check uses SCRIPT_VERSION (or LATEST_TAG
# as a fallback) for the remediation hint, so the CI workflow can
# just call `bash scripts/release.sh --check` with no dummy arg.
if $CHECK_ONLY; then
    ERRORS=0
    SCRIPT_VERSION=$(grep -E '^VERSION=' "$CLEAN_FILE" 2>/dev/null | head -1 | sed -E 's/^VERSION="([^"]+)"$/\1/')

    # Determine the "expected" version for remediation hints. Prefer
    # the X.Y.Z arg if given + valid; otherwise SCRIPT_VERSION;
    # otherwise LATEST_TAG; otherwise the literal "X.Y.Z".
    EXPECTED_VERSION="$VERSION"
    if [[ ! "$EXPECTED_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        if [[ "$SCRIPT_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            EXPECTED_VERSION="$SCRIPT_VERSION"
        elif LATEST_TAG=$(git describe --tags --abbrev=0 2>/dev/null); then
            EXPECTED_VERSION="${LATEST_TAG#v}"
        else
            EXPECTED_VERSION="X.Y.Z"
        fi
    fi

    # Check 1: EXPECTED_HASH in installer.sh matches the actual hash
    # of clean-mac-space.sh. Only fail if the file is UNCHANGED since
    # the last version bump. If the file has been modified since the
    # last version bump (a release is in progress), warn only — the
    # EXPECTED_HASH will be regenerated by the release prep.
    ACTUAL_HASH=$(sha256_file "$CLEAN_FILE" 2>/dev/null) || {
        echo "  FAIL: cannot read $CLEAN_FILE to compute hash" >&2
        ERRORS=$((ERRORS + 1))
        ACTUAL_HASH=""
    }
    if [[ -n "$ACTUAL_HASH" && "$ACTUAL_HASH" != "$OLD_HASH" ]]; then
        # Hash mismatch. Distinguish in-progress (file modified
        # since last VERSION bump) from real drift.
        LAST_VER_BUMP=$(git log -1 -G '^VERSION=' --format='%H' -- "$CLEAN_FILE" 2>/dev/null || true)
        IN_PROGRESS=false
        if [[ -n "$LAST_VER_BUMP" ]]; then
            TMPFILE=$(mktemp)
            if git show "$LAST_VER_BUMP:$CLEAN_FILE" > "$TMPFILE" 2>/dev/null; then
                HASH_AT_LAST_VER=$(sha256_file "$TMPFILE")
                if [[ -n "$HASH_AT_LAST_VER" && "$HASH_AT_LAST_VER" != "$ACTUAL_HASH" ]]; then
                    IN_PROGRESS=true
                fi
            fi
            rm -f "$TMPFILE"
        fi
        if $IN_PROGRESS; then
            echo "  WARN: EXPECTED_HASH in $INSTALLER is stale, but $CLEAN_FILE has been modified since the last VERSION bump (commit $LAST_VER_BUMP)" >&2
            echo "    (this is expected for a pre-release-prep PR; the hash will be regenerated by 'scripts/release.sh $EXPECTED_VERSION')" >&2
            # not an error
        else
            echo "  FAIL: EXPECTED_HASH in $INSTALLER is stale" >&2
            echo "    recorded: $OLD_HASH" >&2
            echo "    actual:   $ACTUAL_HASH" >&2
            echo "    fix: run 'scripts/release.sh $EXPECTED_VERSION' (without --check) to regenerate" >&2
            ERRORS=$((ERRORS + 1))
        fi
    elif [[ -n "$ACTUAL_HASH" ]]; then
        echo "  OK: EXPECTED_HASH in $INSTALLER matches $CLEAN_FILE ($ACTUAL_HASH)"
    fi

    # Check 2: VERSION in clean-mac-space.sh is a valid semver.
    if [[ -z "$SCRIPT_VERSION" ]]; then
        echo "  FAIL: could not find VERSION in $CLEAN_FILE" >&2
        ERRORS=$((ERRORS + 1))
    elif ! [[ "$SCRIPT_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "  FAIL: VERSION='$SCRIPT_VERSION' is not X.Y.Z format" >&2
        ERRORS=$((ERRORS + 1))
    else
        echo "  OK: VERSION='$SCRIPT_VERSION' is valid semver"
    fi

    # Check 3: CHANGELOG.md has at least one versioned section. We
    # don't require either [Unreleased] or a specific version — both
    # states are valid for a stable repo. We just verify the file
    # is parseable and has at least one versioned section.
    if [[ -f "$CHANGELOG" ]]; then
        VERSIONED_SECTIONS=$(grep -cE '^## \[[0-9]+\.[0-9]+\.[0-9]+\]' "$CHANGELOG" 2>/dev/null || echo 0)
        if [[ "$VERSIONED_SECTIONS" -lt 1 ]]; then
            echo "  FAIL: $CHANGELOG has no versioned sections (looking for '## [X.Y.Z]')" >&2
            ERRORS=$((ERRORS + 1))
        else
            echo "  OK: $CHANGELOG has $VERSIONED_SECTIONS versioned section(s)"
        fi
    else
        echo "  WARN: $CHANGELOG not found (skipping changelog check)"
    fi

    # Check 4: VERSION in clean-mac-space.sh matches the latest
    # git tag. This is informational only — a "no" answer is normal
    # when a release prep is in progress.
    if LATEST_TAG=$(git describe --tags --abbrev=0 2>/dev/null); then
        LATEST_TAG="${LATEST_TAG#v}"
        if [[ -n "$SCRIPT_VERSION" && "$LATEST_TAG" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            if [[ "$SCRIPT_VERSION" == "$LATEST_TAG" ]]; then
                echo "  WARN: VERSION='$SCRIPT_VERSION' matches latest tag v$LATEST_TAG. (This is fine if you haven't started the next release yet.)"
            fi
        fi
    fi

    echo ""
    if [[ $ERRORS -gt 0 ]]; then
        echo "release state check FAILED: $ERRORS error(s)" >&2
        exit 1
    fi
    echo "release state check OK"
    exit 0
fi

# Reject obviously bad versions
[[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || \
    die "version '$VERSION' is not X.Y.Z format (e.g. 5.4.0)"

# Must be run from the repo root
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || \
    die "must be run from inside a git checkout"
cd "$REPO_ROOT"

# Branch check
BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [[ "$BRANCH" != "main" && "$BRANCH" != "master" ]]; then
    die "current branch is '$BRANCH' — release prep must run from main (or master)"
fi

# Working tree must be clean (or have a pre-approved dirty state).
# `git status --porcelain` catches both modified and untracked files;
# `git diff --quiet HEAD` would miss untracked files.
if [[ -n "$(git status --porcelain)" ]]; then
    die "working tree has uncommitted changes; commit or stash first"
fi

# Make sure we're up to date with origin
if git fetch --quiet origin "$BRANCH" 2>/dev/null; then
    if [[ "$(git rev-parse HEAD)" != "$(git rev-parse "origin/$BRANCH")" ]]; then
        die "local $BRANCH is not in sync with origin/$BRANCH; pull first"
    fi
fi

echo "Preparing release $VERSION on $BRANCH..."
$DRY_RUN && echo "(dry-run mode — no files will be written)"

# --- Step 1: bump VERSION -------------------------------------------------
# (CLEAN_FILE was already defined above; we just need the current
# VERSION string to know what to bump from.)

OLD_VERSION=$(grep -E '^VERSION=' "$CLEAN_FILE" | head -1 | sed -E 's/^VERSION="([^"]+)"$/\1/')
[[ -n "$OLD_VERSION" ]] || die "could not find VERSION in $CLEAN_FILE"
echo "  $CLEAN_FILE: VERSION $OLD_VERSION -> $VERSION"

if ! $DRY_RUN; then
    sed -i.bak -E "s|^VERSION=\"$OLD_VERSION\"|VERSION=\"$VERSION\"|" "$CLEAN_FILE"
    rm -f "$CLEAN_FILE.bak"
fi

# --- Step 2: regenerate EXPECTED_HASH in installer.sh ---------------------
# (INSTALLER + OLD_HASH already defined above.)

NEW_HASH=$(sha256_file "$CLEAN_FILE")
echo "  $INSTALLER: EXPECTED_HASH $OLD_HASH -> $NEW_HASH"

if [[ "$NEW_HASH" == "$OLD_HASH" ]]; then
    echo "  (note: hash unchanged from the previous release — that's fine if no script changes were made)"
fi

if ! $DRY_RUN; then
    sed -i.bak -E "s|^EXPECTED_HASH=\"$OLD_HASH\"|EXPECTED_HASH=\"$NEW_HASH\"|" "$INSTALLER"
    rm -f "$INSTALLER.bak"
fi

# --- Step 3: sanity checks ------------------------------------------------

echo ""
echo "Running sanity checks..."

# bash -n
echo "  bash -n $CLEAN_FILE..."
bash -n "$CLEAN_FILE" || die "bash -n $CLEAN_FILE failed"
echo "  bash -n $INSTALLER..."
bash -n "$INSTALLER" || die "bash -n $INSTALLER failed"

# Linter at the same severity the CI uses (CI runs `shellcheck -S warning`).
# The actual invocation is the shellcheck_run helper below.
echo "  shellcheck -S warning (default + warning)..."
shellcheck_run "$CLEAN_FILE" "$INSTALLER"

# --version sanity (verifies the script actually runs).
# We always invoke via `bash` (not by executing $CLEAN_FILE directly),
# so the executable bit is irrelevant; just run it.
echo "  $CLEAN_FILE --version (sanity)..."
REPORTED=$(bash "$CLEAN_FILE" --version 2>&1 | head -1 || true)
echo "    -> $REPORTED"
if ! echo "$REPORTED" | grep -q "$VERSION"; then
    die "VERSION=$VERSION in $CLEAN_FILE but --version reports '$REPORTED' — something is wrong"
fi

# --- Step 4: stage + (optionally) commit ----------------------------------

echo ""
if $DRY_RUN; then
    echo "Dry run complete. No files changed."
    echo "Re-run without --dry-run to apply the bump + commit."
    exit 0
fi

git add "$CLEAN_FILE" "$INSTALLER"

# Update CHANGELOG if there's a [Unreleased] section, otherwise warn
# (CHANGELOG was already defined above.)
if [[ -f "$CHANGELOG" ]] && grep -q "## \[Unreleased\]" "$CHANGELOG"; then
    echo "Found [Unreleased] section in $CHANGELOG — leaving for you to fold into [$VERSION] before tagging."
else
    echo "No [Unreleased] section in $CHANGELOG — please add a [$VERSION] entry before tagging."
fi

echo ""
echo "Changes staged. Diff summary:"
git diff --cached --stat

echo ""
echo "Next steps:"
echo "  1. Review the diff above"
echo "  2. Add a [$VERSION] entry to CHANGELOG.md (or fold [Unreleased] into it)"
echo "  3. git commit -m 'chore: bump version to v$VERSION'"
echo "  4. git tag v$VERSION && git push --tags"
echo "     (the .github/workflows/release.yml will update the homebrew tap + create the GitHub release)"
