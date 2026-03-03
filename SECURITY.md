[![Security](https://img.shields.io/badge/Security-Policy-red.svg)]()
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Tested](https://img.shields.io/badge/Tested%20on-26.4-green.svg)]()

# Security

## Found Something Dodgy?

If you spot a security issue, just [open an issue](https://github.com/Carme99/MacCleans.sh/issues) or message me directly. No formal process here - this is a solo project, not a Fortune 500 company.

## What This Script Does (and Doesn't Do)

Since this script runs with `sudo`, it's fair to ask what it's actually doing. Here's the deal:

**It does**:
- Delete cache files, temp files, and system metadata
- That's literally it

**It does NOT**:
- Phone home or transmit any data
- Install anything
- Modify system configs or user accounts
- Touch your actual files, documents, or app settings
- Do anything sneaky - it's all open source, read it yourself

## Running Safely

- **Read the script first** - it's one file, not rocket science
- **Use `--dry-run`** - preview everything before it deletes
- **Download from here** - don't grab it from random places
- **Check the source** - ShellCheck CI runs on every PR

## How It Stays Safe

- `set -euo pipefail` - script dies on any error rather than ploughing on
- All variables quoted - no command injection funny business
- Operations scoped to known cache/temp directories only
- Validates user context before doing anything
- **Atomic locking** - Uses `mkdir` for race-free concurrent execution protection
- **iCloud sync validation** - Checks for pending uploads before iCloud Drive cleanup
- **Symlink protection** - All deletions use hardened helpers with symlink guards
- **Safe deletion** - Uses `find -delete` instead of glob expansion to prevent injection

This is a free tool built for fun. It does what other apps charge money for, but without the dodgy data collection. You're welcome.

## Auditing the Script

Since this runs with sudo, you should verify it yourself:

1. **Read the source**: `cat clean-mac-space.sh`
2. **Check for issues**: `shellcheck clean-mac-space.sh`
3. **Verify no network calls**: `grep -E 'curl|wget' clean-mac-space.sh` (only downloads, never uploads)
4. **Check git history**: `git log --oneline` to see recent changes

## Reporting Vulnerabilities

If you find a security issue:
1. Don't open a public issue
2. Email the maintainer directly (or message on GitHub)
3. Provide details but don't disclose publicly until fixed

We aim to respond within 48 hours and push a fix ASAP.

---

<!-- Security isn't just a feature, it's a lifestyle. Like wearing a seatbelt... for your terminal. -->
