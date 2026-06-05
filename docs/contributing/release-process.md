# Release Process

This project uses **manual releases** triggered by a version tag push. `scripts/release.sh` handles the version-bumping ceremony; `.github/workflows/release.yml` handles the homebrew-tap + GitHub release updates on the push.

## The golden rule

> **Every PR that ships user-visible behavior is followed by a release before the next PR is opened.**

This isn't enforced by automation (yet) — it lives in the PR template's "Release follow-up" section as a reminder. If a PR is `refactor:`, `docs:`, `chore:`, or similar, no release is needed.

## The four version files

A version bump touches exactly four files, all in the same commit:

| File | What changes |
|---|---|
| `clean-mac-space.sh` | `VERSION="X.Y.Z"` (line 7) |
| `installer.sh` | `EXPECTED_HASH="<sha256 of clean-mac-space.sh>"` — **regenerated** by `scripts/release.sh` |
| `CHANGELOG.md` | Move the `[Unreleased]` entry into a new `## [X.Y.Z] - YYYY-MM-DD` section |
| `README.md` (and `docs/README.md` if it exists) | The version badge |

`scripts/release.sh` handles the first two automatically. The other two are manual.

## The release checklist

1. **All PRs for this release are merged on `main`**, with their `[Unreleased]` entries in `CHANGELOG.md`.
2. **Worktree is clean and on `main`**:
   ```bash
   git checkout main
   git pull --rebase
   git status   # should be clean
   ```
3. **Run the release helper** from a `main` checkout (the script refuses to run on any other branch):
   ```bash
   bash scripts/release.sh 5.5.3
   ```
   What this does:
   - Bumps `VERSION=` in `clean-mac-space.sh` to `5.5.3`
   - Regenerates `EXPECTED_HASH` in `installer.sh` from the new script content (this is the part v5.2.0 forgot to do — bundling it into the same command prevents that drift)
   - Runs `bash -n` and `shellcheck -S warning` to catch syntax regressions
   - **Stages** both files but does **not** commit
4. **Edit `CHANGELOG.md` manually**: rename the `[Unreleased]` section to `## [5.5.3] - YYYY-MM-DD` and add a fresh empty `## [Unreleased]` above it for the next cycle.
5. **Edit the version badge** in `README.md` (and `docs/README.md` if it has one). One-line edit each.
6. **Commit the release prep as a single chore commit**:
   ```bash
   git commit -m "chore: bump version to v5.5.3"
   ```
7. **Tag and push** (push both the `main` refspec and the tag in one command — `git push origin <tag>` only uploads the tag ref, the underlying release commit and the new `main` tip need an explicit push too):
   ```bash
   git tag v5.5.3
   git push origin main v5.5.3
   ```
   The tag push is what fires `.github/workflows/release.yml`.
8. **Watch the [Actions tab](https://github.com/Carme99/MacCleans.sh/actions)** for the `Release` workflow to finish (~30 seconds). On success, the homebrew tap formula (`carme99/homebrew-tap/mac-cleans.rb`) is updated and a GitHub release is created.

If the workflow fails, fix the underlying issue and either delete the tag locally + on origin and re-push, or use the **Run workflow** button on the Actions tab to re-run it manually.

## Version numbering

We follow [Semantic Versioning](https://semver.org/):

- **MAJOR** (`X.0.0`) — breaking change to a user-facing flag, JSON shape, or config-file format
- **MINOR** (`x.X.0`) — new feature, new category, new flag (backward compatible)
- **PATCH** (`x.x.X`) — bug fix, doc fix that ships in a release, or a grouping of small changes

The PR template's "What kind of change is this?" section encodes this. A single `feat:` PR → minor. A `fix:` PR → patch. A `refactor:` PR → no version bump (fold it into the next `feat:` or `fix:` if you want a release to mention it).

## Worked example (v5.5.2 → v5.5.3, hypothetical)

Say PR #83 is a `fix:` for a Photos Library edge case:

1. PR #83 is reviewed, merged, CI is green, `CHANGELOG.md` has a new `## [Unreleased]` entry
2. (Optional, but recommended: open a "release prep" PR that just moves the `[Unreleased]` entry into a new `## [5.5.3] - 2026-06-06` section — keeps the release commit itself a clean diff against the v5.5.2 tag)
3. Locally on `main`:
   ```bash
   bash scripts/release.sh 5.5.3
   git add CHANGELOG.md README.md docs/README.md   # the files you edited in step 2
   git commit -m "chore: bump version to v5.5.3"
   git tag v5.5.3
   git push origin main v5.5.3
   ```
4. Watch Actions. 30 seconds later, `brew upgrade mac-cleans` picks up v5.5.3.

## What this is **not**

- **Not release-please.** We considered it — it would auto-generate the PR and tag — but at the current release volume (~3/month) the overhead doesn't pay off. Revisit if the project ever ships ≥1 release/week.
- **Not a pre-commit hook.** CI shellcheck covers the same ground for a one-maintainer project, and a pre-commit hook would just be a slower version of the same check.
- **Not auto-bumped on merge.** The release commit is a deliberate, separate action. Don't try to wire it up to "merge to main = release" — the manual gate is the whole point.

## When something goes wrong

| Symptom | Likely cause | Fix |
|---|---|---|
| `scripts/release.sh` refuses to run | Not on `main` | `git checkout main` |
| Workflow fails with "couldn't compute sha256" | Tarball URL changed or GITHUB_REF_NAME is wrong | Check the [release workflow debugging notes](https://github.com/Carme99/MacCleans.sh/blob/main/.github/workflows/release.yml) |
| Homebrew tap formula is wrong after release | Token (`HOMEBREW_TAP_TOKEN`) lost or rotated | See [CONTRIBUTING.md § One-time setup for the maintainer](../CONTRIBUTING.md#one-time-setup-for-the-maintainer) |
| Want to undo a release | Tag was pushed but the tap/release is bad | Delete tag locally + on origin, fix the issue, re-tag. `git push origin :refs/tags/v5.5.3` to delete remotely. |
