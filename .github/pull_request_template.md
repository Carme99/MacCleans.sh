## What kind of change is this?

Pick the conventional-commit type that matches (this drives the version bump):

- [ ] `feat:` — new feature (→ minor version, e.g. `5.5.2` → `5.6.0`)
- [ ] `fix:` — bug fix (→ patch version, e.g. `5.5.2` → `5.5.3`)
- [ ] `refactor:` — code change with no behavior change (→ no version bump)
- [ ] `perf:` — performance improvement with no behavior change (→ no version bump)
- [ ] `docs:` — documentation only (→ no version bump)
- [ ] `test:` — adding or fixing tests (→ no version bump)
- [ ] `chore:` / `build:` / `ci:` — tooling, deps, CI config (→ no version bump)

> Not sure which one? See [CONTRIBUTING.md § Commit Messages](../CONTRIBUTING.md#commit-messages) for the full table.

## Description

<!-- One or two sentences on WHAT and WHY. Link any related issue with `Closes #N` or `Fixes #N`. -->

## Self-review checklist

- [ ] `bash tests/run-tests.sh` passes locally
- [ ] `shellcheck -S warning clean-mac-space.sh` is clean (or new findings explained in PR)
- [ ] `bash -n clean-mac-space.sh` passes (no syntax errors)
- [ ] If user-visible: I added a `## [Unreleased]` entry to `CHANGELOG.md` describing the change
- [ ] If this changes CLI behavior, JSON shape, or skip flags: I updated `docs/reference/commands.md`
- [ ] No new `*.bak` / `*.swp` / editor backup files in the diff

## Release follow-up (maintainer)

> This section is a reminder for the maintainer — not a blocker for merging.

- [ ] This PR changes user-visible behavior → schedule a release (run `scripts/release.sh X.Y.Z`) **before opening the next PR**
- [ ] This PR is `refactor:` / `docs:` / `chore:` etc. → no release needed
- [ ] I have **not** already run `scripts/release.sh` for this change (the release commit goes on a separate, clean PR)
