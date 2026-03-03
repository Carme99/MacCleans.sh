[![Version](https://img.shields.io/badge/Version-4.1.2-blue.svg)](CHANGELOG.md)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![macOS](https://img.shields.io/badge/macOS-10.15+-blue.svg)](https://www.apple.com/macos/)
[![Tested](https://img.shields.io/badge/Tested%20on-26.4-green.svg)]()
[![Shell](https://img.shields.io/badge/Shell-Bash-black.svg)](https://www.gnu.org/software/bash/)
[![Maintenance](https://img.shields.io/badge/Maintained%3F-yes-green.svg)](https://github.com/Carme99/MacCleans.sh/graphs/commit-activity)

[![Stars](https://img.shields.io/github/stars/Carme99/MacCleans.sh?style=social)](https://github.com/Carme99/MacCleans.sh/stargazers)
[![Forks](https://img.shields.io/github/forks/Carme99/MacCleans.sh?style=social)](https://github.com/Carme99/MacCleans.sh/network/members)
[![Issues](https://img.shields.io/github/issues/Carme99/MacCleans.sh)](https://github.com/Carme99/MacCleans.sh/issues)
[![Last Commit](https://img.shields.io/github/last-commit/Carme99/MacCleans.sh)](https://github.com/Carme99/MacCleans.sh/commits/main)
[![Code Size](https://img.shields.io/github/languages/code-size/Carme99/MacCleans.sh)](https://github.com/Carme99/MacCleans.sh)

[![AI Assisted](https://img.shields.io/badge/AI%20Assisted-Claude-blueviolet.svg)](https://claude.ai)
[![AI Assisted](https://img.shields.io/badge/AI%20Assisted-MiniMax%20M2.5-cyan.svg)](https://minimax.ai)

---

# Mac Space Cleanup Script

> A comprehensive macOS disk cleanup utility that safely frees up disk space by removing cache files, temporary files, and other safe-to-delete items.

## Quick Links

[Installation](#installation) · [Usage](#usage) · [Features](#features) · [Categories](#what-gets-cleaned-23-categories) · [Commands](#quick-reference) · [Safety](#safety-guarantees) · [Automation](#automation) · [Troubleshooting](#troubleshooting)

---

## Quick Start

```bash
# Install
curl -fsSL https://raw.githubusercontent.com/Carme99/MacCleans.sh/main/installer.sh | bash

# Preview what would be cleaned
sudo Mac-Clean --dry-run

# Clean everything (non-interactive)
sudo Mac-Clean --yes
```

---

## What's New in v4.1.2

### Security Improvements

- **Atomic Lock File**: Prevents race conditions when running multiple instances
- **iCloud Sync Validation**: Blocks cleanup if files are pending upload/download
- **Symlink Protection**: All deletions now use hardened `safe_clear_directory()` helper
- **Safe Deletion**: Replaced risky glob patterns with `find -delete` operations

### Code Quality

- **Dynamic Help**: `--help` now extracts content automatically
- **Performance**: iCloud checks now cached for faster execution
- **Bug Fixes**: Fixed interactive menu cursor, error handling improvements

For full changelog, see [CHANGELOG.md](CHANGELOG.md).

### Installation

```bash
# Install (recommended)
curl -fsSL https://raw.githubusercontent.com/Carme99/MacCleans.sh/main/installer.sh | sudo bash
```

This will install `Mac-Clean` to `/usr/local/bin/` and create a symlink for `mac-clean`.

---

## What's New in v4.0

### Major Features

- **Photos Library Multi-Library Support** - Clean specific libraries (`--photos-library "Photos Library"`) or all libraries (`--photos-library all`)
- **Enhanced iCloud Integration** - iCloud Photos, Drive, and Mail cache cleanup with smart detection
- **macOS Compatibility Fix** - Fixed POSIX compatibility for macOS Bash 3.2 (replaced `mapfile` with POSIX loops)
- **Dry-Run Improvements** - Photos app check now logs warning in dry-run without blocking space calculation

### Security & Stability

- **Eval Vulnerability Fix** - Replaced unsafe `eval` with safer alternatives
- **Symlink Attack Prevention** - Fixed trash deletion to prevent following malicious symlinks
- **Signal Handling** - Graceful interruption handling (Ctrl+C)

### Breaking Changes

- Renamed `--skip-icloud-photos` → `--skip-photos-library`
- Added `--photos-library "name"` flag for library selection

### Full Changelog

[View complete changelog →](CHANGELOG.md)

---

## Why MacCleans?

| Feature | MacCleans | CleanMyMac | CCleaner |
|---------|-----------|------------|----------|
| Open Source | ✅ | ❌ | ❌ |
| Free | ✅ | ❌ | ❌ |
| CLI / Scriptable | ✅ | ❌ | Partial |
| macOS Native | ✅ | ❌ | Partial |
| No Subscription | ✅ | ❌ | ❌ |
| Privacy-First | ✅ | ❌ | ❌ |

---

## Features

- **Safe by Design** - Only removes cache/temp files, never touches user data, documents, or settings
- **Opt-Out Approach** - 29 cleanup categories enabled by default with `--skip-*` flags
- **Interactive Mode** - Choose exactly what to clean with a menu
- **Configuration Profiles** - Quick presets: conservative, developer, aggressive, minimal
- **Preview Mode** - `--dry-run` to see what would be deleted
- **Detailed Reporting** - Byte-accurate space tracking per category
- **Configuration Files** - Save settings in `~/.maccleans.conf`
- **Colored Output** - Visual feedback with color-coded messages
- **System Health Checks** - Monitors Time Machine, system load

---

## Quick Reference

### Common Commands

| Use Case | Command |
|----------|---------|
| Preview what would be cleaned | `sudo ~/Scripts/clean-mac-space.sh --dry-run` |
| Clean everything (no prompts) | `sudo ~/Scripts/clean-mac-space.sh --yes` |
| Interactive mode | `sudo ~/Scripts/clean-mac-space.sh --interactive` |
| Use preset profile | `sudo ~/Scripts/clean-mac-space.sh --profile developer` |
| Skip specific category | `sudo ~/Scripts/clean-mac-space.sh --skip-xcode` |
| Only run if disk > 80% | `sudo ~/Scripts/clean-mac-space.sh --threshold 80` |

### Profiles

| Profile | Description |
|---------|-------------|
| `conservative` | Skip XCode, npm, pip, browsers, Docker, Simulator, iOS backups, CocoaPods, Gradle, Go, Bun, pnpm |
| `developer` | Skip XCode, iOS backups only |
| `aggressive` | Clean everything |
| `minimal` | Skip all development tool caches + application caches |

### Danger Zone (Requires `--force`)

These operations require `--force` to skip warnings:
- XCode Derived Data (5-50GB+)
- iOS Device Backups
- Full Docker cleanup
- **iCloud Drive Offline Files** (bypasses sync, data loss risk)

---

## What Gets Cleaned (23 Categories)

### Core System

| # | Category | Typical Size | Risk |
|---|----------|--------------|------|
| 1 | Time Machine Local Snapshots | 10-100GB | 🟢 Low |
| 2 | Homebrew Cache | 1-5GB | 🟢 Low |
| 3 | Application Caches (Spotify, Claude, etc.) | 500MB-2GB | 🟢 Low |
| 4 | System Caches (>30 days old) | 100MB-1GB | 🟢 Low |
| 5 | Old Log Files (>7 days) | 50-500MB | 🟢 Low |
| 6 | System Temporary Files | 100MB-1GB | 🟢 Low |

### Development

| # | Category | Typical Size | Risk |
|---|----------|--------------|------|
| 7 | Browser Caches (Chrome, Firefox, Edge) | 1-5GB | 🟢 Low |
| 8 | XCode Derived Data | 5-50GB+ | 🔴 High |
| 9 | npm/Yarn Cache | 500MB-5GB | 🟢 Low |
| 10 | Python pip Cache | 100MB-2GB | 🟢 Low |

### Maintenance

| # | Category | Typical Size | Risk |
|---|----------|--------------|------|
| 11 | Trash Bin | Variable | 🟢 Low |
| 12 | Docker Cache | Variable | 🟡 Medium |
| 13 | iOS Simulator Data | Variable | 🟢 Low |
| 14 | Mail App Cache | 100MB-1GB | 🟢 Low |
| 15 | Siri TTS Cache | 100-500MB | 🟢 Low |
| 16 | iCloud Mail Cache | Variable | 🟢 Low |
| 17 | **Photos Library Cache** | Variable | 🟢 Low |
| 18 | iCloud Drive Offline Files | Variable | 🔴 High (requires --force) |
| 19 | QuickLook Thumbnails | 100MB-1GB | 🟢 Low |
| 20 | Diagnostic Reports (>30 days) | 100MB-1GB | 🟢 Low |
| 21 | iOS Device Backups | 5-50GB+ | 🔴 High |
| 22 | iOS/iPadOS Update Files (.ipsw) | 3-7GB each | 🟢 Low |
| 23 | .DS_Store Files | 100MB-2GB | 🟢 Low |

---

## Installation

See [INSTALL.md](INSTALL.md) for detailed installation instructions.

### Quick Install Methods

```bash
# Method 1: Installer script (recommended)
curl -fsSL https://raw.githubusercontent.com/Carme99/MacCleans.sh/main/installer.sh | bash

# Method 2: Manual install
curl -sSL https://raw.githubusercontent.com/Carme99/MacCleans.sh/main/clean-mac-space.sh -o /usr/local/bin/Mac-Clean
chmod +x /usr/local/bin/Mac-Clean

# Method 3: Git clone
git clone https://github.com/Carme99/MacCleans.sh ~/MacCleans.sh

# Method 4: Homebrew (if available)
brew install carme99/maccleans/maccleans
```

### Setup Configuration (Optional)

```bash
# Create config file
mkdir -p ~/.config/maccleans
cp maccleans.conf.example ~/.config/maccleans/config

# Edit to your preferences
nano ~/.config/maccleans/config
```

---

## Usage

### Basic Commands

```bash
# Preview what will be cleaned (recommended first run)
sudo ~/Scripts/clean-mac-space.sh --dry-run

# Interactive mode - select categories
sudo ~/Scripts/clean-mac-space.sh --interactive

# Full cleanup with confirmation
sudo ~/Scripts/clean-mac-space.sh

# Non-interactive (no prompts)
sudo ~/Scripts/clean-mac-space.sh --yes

# Fully unattended (skip ALL warnings including XCode)
sudo ~/Scripts/clean-mac-space.sh --force
```

### Advanced Usage

```bash
# Use a preset profile
sudo ~/Scripts/clean-mac-space.sh --profile developer
sudo ~/Scripts/clean-mac-space.sh --profile aggressive

# Skip specific categories
sudo ~/Scripts/clean-mac-space.sh --skip-xcode --skip-ios-backups

# Target specific Photos library
sudo ~/Scripts/clean-mac-space.sh --photos-library "Photos Library"

# Clean all Photos libraries
sudo ~/Scripts/clean-mac-space.sh --photos-library all

# Only run if disk usage is above threshold
sudo ~/Scripts/clean-mac-space.sh --threshold 85

# Quiet mode (minimal output)
sudo ~/Scripts/clean-mac-space.sh --quiet

# Use custom config file
sudo ~/Scripts/clean-mac-space.sh --config /path/to/config
```

---

## Command Reference

### Core Options

| Flag | Alias | Description | Default |
|------|-------|-------------|---------|
| `--dry-run` | `-n` | Preview only, no deletions | `false` |
| `--yes` | `-y` | Skip confirmation prompts | `false` |
| `--force` | `-f` | Skip ALL warnings (dangerous!) | `false` |
| `--quiet` | `-q` | Minimal output | `false` |
| `--no-color` | - | Disable colored output | `false` |
| `--version` | `-v` | Show version | - |
| `--help` | `-h` | Show help | - |

### Cleanup Selection

| Flag | Description |
|------|-------------|
| `--profile NAME` | Use preset: conservative, developer, aggressive, minimal |
| `--interactive` | Interactive category selection |
| `--threshold N` | Only run if disk usage > N% |
| `--skip-*` | Skip specific category (see below) |

### Skip Flags (23 categories)

| Flag | Skips |
|------|-------|
| `--skip-snapshots` | Time Machine snapshots |
| `--skip-homebrew` | Homebrew cache |
| `--skip-spotify` | Spotify cache |
| `--skip-claude` | Claude Desktop cache |
| `--skip-xcode` | XCode Derived Data |
| `--skip-browsers` | Browser caches |
| `--skip-npm` | npm/Yarn cache |
| `--skip-pip` | Python pip cache |
| `--skip-trash` | Trash bin |
| `--skip-dsstore` | .DS_Store files |
| `--skip-docker` | Docker cache |
| `--skip-simulator` | iOS Simulator data |
| `--skip-mail` | Mail app cache |
| `--skip-siri-tts` | Siri TTS cache |
| `--skip-icloud-mail` | iCloud Mail cache |
| `--skip-photos-library` | Photos Library cache |
| `--skip-icloud-drive` | iCloud Drive offline files |
| `--skip-quicklook` | QuickLook thumbnails |
| `--skip-diagnostics` | Diagnostic reports |
| `--skip-ios-backups` | iOS device backups |
| `--skip-ios-updates` | iOS update files |

### Photos Library Options

| Flag | Description |
|------|-------------|
| `--photos-library "name"` | Target specific library |
| `--photos-library all` | Clean all libraries |

---

## Configuration Files

The script checks these locations in order:

1. `~/.maccleans.conf`
2. `~/.config/maccleans/config`
3. `${XDG_CONFIG_HOME}/maccleans/config`

### Example Configuration

```bash
# ~/.maccleans.conf

# Run options
DRY_RUN=false
AUTO_YES=false
FORCE=false
QUIET=false
THRESHOLD=0

# Skip specific categories
SKIP_SNAPSHOTS=false
SKIP_XCODE=false
SKIP_IOS_BACKUPS=true
SKIP_DOCKER=false
```

---

## Safety Guarantees

- **Never touches**: User documents, photos, music, downloads, applications
- **Only removes**: Cache files, temporary files, build artifacts, logs
- **Opt-out by category**: Every cleanup category can be skipped individually
- **Preview first**: Always run `--dry-run` to see what would be deleted
- **Detailed logging**: Shows exactly what was cleaned and how much space was freed

### What Could Go Wrong?

1. **XCode Derived Data** - May slow down first build after cleanup (rebuilds automatically)
2. **iOS Backups** - Should have alternative backup before deleting
3. **Photos Library** - Thumbnails will regenerate on demand (photos safe in iCloud)

---

## What MacCleans Does NOT Touch

MacCleans is designed to only delete safe, regenerable files. It will **never** delete:

| Category | Examples | Why Safe |
|----------|----------|----------|
| **User Documents** | ~/Documents/* | Your actual files |
| **Photos & Media** | ~/Pictures/*, ~/Music/* | Personal media |
| **Downloads** | ~/Downloads/* | User downloads |
| **Applications** | /Applications/* | Installed apps |
| **App Settings** | ~/Library/Preferences/* | User preferences |
| **Browser Data** | History, bookmarks, passwords | Never touched |
| **Email** | Mail messages, attachments | Never touched |
| **iCloud Data** | Files synced to iCloud | Only local cache |

**What IS cleaned:**
- Cache files (~/Library/Caches)
- Temporary files (/tmp, /var/tmp)
- Build artifacts (XCode Derived Data)
- System logs (old logs only)
- Thumbnail caches (regenerate on demand)

---

## Automation

### Cron (Daily at 2 AM)

```bash
# Edit crontab
crontab -e

# Add this line:
0 2 * * * /Users/jacklee/Scripts/clean-mac-space.sh --yes --threshold 80 --quiet
```

### LaunchDaemon (macOS native)

See [INSTALL.md](INSTALL.md) for detailed launchd setup.

---

## Troubleshooting

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for common issues.

### Common Issues

| Issue | Solution |
|-------|----------|
| "Permission denied" | Run with `sudo` |
| "Command not found" | Ensure script is executable: `chmod +x clean-mac-space.sh` |
| "No space freed" | Try `--dry-run` first to see what's available |
| "Photos app running" | Close Photos app or run in dry-run mode |

---

## Documentation

| Guide | Description |
|-------|-------------|
| [INSTALL.md](INSTALL.md) | Detailed installation instructions |
| [QUICKSTART.md](QUICKSTART.md) | 5-minute getting started guide |
| [ADVANCED.md](ADVANCED.md) | Advanced usage and automation |
| [FAQ.md](FAQ.md) | Frequently asked questions |
| [TROUBLESHOOTING.md](TROUBLESHOOTING.md) | Common issues and solutions |
| [CONTRIBUTING.md](CONTRIBUTING.md) | How to contribute |
| [SECURITY.md](SECURITY.md) | Security policy |

### Additional Guides

- [Understanding macOS Caches](docs/guides/understanding-macos-caches.md)
- [XCode Derived Data Guide](docs/guides/xcode-derived-data-guide.md)
- [Docker Cache Guide](docs/guides/docker-cache-guide.md)
- [Automating macOS Maintenance](docs/guides/automating-macos-maintenance.md)

---

## Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Development Setup

```bash
# Clone the repo
git clone https://github.com/Carme99/MacCleans.sh.git
cd MacCleans.sh

# Run tests
bash -n clean-mac-space.sh  # Syntax check

# Run with debug
bash -x clean-mac-space.sh --dry-run
```

---

## License

MIT License - See [LICENSE](LICENSE) for details.

---

## Acknowledgments

This project is developed with AI assistance from [Claude](https://claude.ai) and [MiniMax M2.5](https://minimax.ai). AI helps accelerate development while maintaining quality and security standards. All code is reviewed by the maintainer before merging.

- Inspired by various macOS cleanup utilities
- Special thanks to [mac-cleanup](https://github.com/mac-cleanup/mac-cleanup-sh) for inspiration on several cleanup categories (MIT License)
- Thanks to all [contributors](https://github.com/Carme99/MacCleans.sh/graphs/contributors)

---

<p align="center">
  <strong>Star us on GitHub!</strong><br>
  <a href="https://github.com/Carme99/MacCleans.sh">
    <img src="https://img.shields.io/github/stars/Carme99/MacCleans.sh?style=social" alt="Stars">
  </a>
</p>
