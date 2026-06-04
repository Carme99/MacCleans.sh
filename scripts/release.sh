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

# --- Preflight -------------------------------------------------------------

[[ $# -ge 1 ]] || die "usage: scripts/release.sh X.Y.Z [--dry-run]"
VERSION="$1"; shift || true
DRY_RUN=false
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true

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

# Working tree must be clean (or have a pre-approved dirty state)
if ! git diff --quiet HEAD 2>/dev/null; then
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

CLEAN_FILE="clean-mac-space.sh"
[[ -f "$CLEAN_FILE" ]] || die "$CLEAN_FILE not found"

OLD_VERSION=$(grep -E '^VERSION=' "$CLEAN_FILE" | head -1 | sed -E 's/^VERSION="([^"]+)"$/\1/')
[[ -n "$OLD_VERSION" ]] || die "could not find VERSION in $CLEAN_FILE"
echo "  $CLEAN_FILE: VERSION $OLD_VERSION -> $VERSION"

if ! $DRY_RUN; then
    sed -i.bak -E "s|^VERSION=\"$OLD_VERSION\"|VERSION=\"$VERSION\"|" "$CLEAN_FILE"
    rm -f "$CLEAN_FILE.bak"
fi

# --- Step 2: regenerate EXPECTED_HASH in installer.sh ---------------------

INSTALLER="installer.sh"
[[ -f "$INSTALLER" ]] || die "$INSTALLER not found"

OLD_HASH=$(grep -E '^EXPECTED_HASH=' "$INSTALLER" | head -1 | sed -E 's/^EXPECTED_HASH="([0-9a-f]+)"$/\1/')
[[ -n "$OLD_HASH" ]] || die "could not find EXPECTED_HASH in $INSTALLER"

NEW_HASH=$(shasum -a 256 "$CLEAN_FILE" | awk '{print $1}')
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

# --version sanity (verifies the script actually runs)
if [[ -x "$CLEAN_FILE" ]]; then
    echo "  $CLEAN_FILE --version (sanity)..."
    REPORTED=$(bash "$CLEAN_FILE" --version 2>&1 | head -1 || true)
    echo "    -> $REPORTED"
    if ! echo "$REPORTED" | grep -q "$VERSION"; then
        die "VERSION=$VERSION in $CLEAN_FILE but --version reports '$REPORTED' — something is wrong"
    fi
else
    echo "  (skipping --version sanity: $CLEAN_FILE is not executable)"
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
CHANGELOG="CHANGELOG.md"
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
