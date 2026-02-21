[![Version](https://img.shields.io/badge/Version-3.2.1-blue.svg)](CHANGELOG.md)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![macOS](https://img.shields.io/badge/macOS-10.15+-blue.svg)](https://www.apple.com/macos/)
[![Shell](https://img.shields.io/badge/Shell-Bash-black.svg)](https://www.gnu.org/software/bash/)
[![Maintenance](https://img.shields.io/badge/Maintained%3F-yes-green.svg)](https://github.com/Carme99/MacCleans.sh/graphs/commit-activity)
[![Documentation](https://img.shields.io/badge/Docs-Comprehensive-brightgreen.svg)](docs/)
[![Vibe Coded](https://img.shields.io/badge/Vibe%20Coded-with%20Claude-blueviolet.svg)](https://claude.ai)

# Mac Space Cleanup Script

A comprehensive macOS disk cleanup utility that safely frees up disk space by removing cache files, temporary files, and other safe-to-delete items.

## Table of Contents

- [What's New](#-whats-new-in-v321)
- [Features](#features)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [What Gets Cleaned](#what-gets-cleaned)
- [Usage](#usage)
- [All Available Flags](#all-available-flags)
- [Configuration Profiles](#configuration-profiles-explained)
- [Safety Guarantees](#safety-guarantees)
- [Typical Space Recovery](#typical-space-recovery)
- [Configuration Files](#configuration-files)
- [Real-World Example Run](#real-world-example-run)
- [Documentation](#documentation)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [Built With](#built-with)
- [License](#license)

## ✨ What's New in v3.2.1

### Security & Stability
- 🔒 **Security Fixes**: Patched eval vulnerability and symlink attack prevention in trash deletion
- 🛡️ **Signal Handling**: Script now handles interrupts gracefully

### New Features
- ⚡ **--force/-f Flag**: Skip ALL confirmation prompts for fully unattended automation

## ✨ What's New in v3.1.0

- 📚 **Comprehensive Documentation Suite**: Contributing guide, advanced usage, FAQ, troubleshooting, and educational guides
- 🛡️ **Docker Safety**: Removed dangerous `--volumes` flag from Docker cleanup to protect database data
- 📱 **Simulator Safety**: Removed destructive `erase all` command, now only removes unavailable simulators
- 📊 **Space Tracking**: Added byte-accurate tracking to System Cache, Temp Files, .DS_Store, and Docker sections
- 📝 **GitHub Templates**: Issue and PR templates for better contributor experience
- 🔒 **Security Policy**: Added SECURITY.md with responsible disclosure guidelines

</details>

## Features

- **Safe by Design**: Only removes cache and temp files, never touches user data, documents, or application settings
- **Opt-Out Approach**: New cleanup categories enabled by default with `--skip-*` flags
- **Interactive Mode**: Choose exactly what to clean with an interactive menu
- **Configuration Profiles**: Quick presets for different use cases
- **Preview Mode**: Use `--dry-run` to see what would be deleted before confirming
- **Detailed Reporting**: Shows exact space freed for each category with summary
- **Interactive Warnings**: Special alerts for risky operations like XCode cache deletion
- **Configuration File Support**: Save your preferred settings in `~/.maccleans.conf`
- **Colored Output**: Visual feedback with color-coded success, warnings, and errors
- **System Health Checks**: Monitors system load and running backups

## Installation

See [INSTALL.md](INSTALL.md) for detailed installation instructions including:
- Quick installation methods (curl download or git clone)
- Setting up configuration files
- Automated cleanup with cron or launchd

## Quick Start

```bash
# Preview what will be cleaned
sudo ./clean-mac-space.sh --dry-run

# Interactive mode - select what to clean
sudo ./clean-mac-space.sh --interactive

# Use a preset profile
sudo ./clean-mac-space.sh --profile developer

# Full cleanup with confirmation
sudo ./clean-mac-space.sh

# Automated cleanup (no prompts)
sudo ./clean-mac-space.sh --yes

# Fully unattended (skip all prompts including XCode warning)
sudo ./clean-mac-space.sh --force
```

## What Gets Cleaned

### Core Categories (Always Available)

1. **Time Machine Local Snapshots** - Old backup snapshots (with safety checks)
2. **Homebrew Cache** - Package manager cache and old downloads
3. **Application Caches** - Spotify, Claude Desktop, and system app caches
4. **System Caches** - GeoServices, helpd, parsecd, and compiler cache (>30 days old)
5. **Old Logs** - Log files older than 7 days
6. **Temporary Files** - System temp directories (`/tmp`, `/var/tmp`)

### Development Categories

7. **Browser Caches** - Chrome, Firefox, and Microsoft Edge caches (1-5GB)
8. **XCode Derived Data** - XCode build cache (5-50GB+ - **use caution!**)
9. **npm/Yarn Cache** - Node.js package manager caches (500MB-5GB)
10. **Python pip Cache** - Python package manager cache (100MB-2GB)
11. **Docker Cache** 🆕 - Docker images, containers, volumes (variable)
12. **iOS Simulator Data** 🆕 - Simulator caches and data (variable)

### Maintenance Categories

13. **Trash Bin** - Empties user trash directory (variable)
14. **.DS_Store Files** - macOS system metadata files (100MB-2GB)
15. **Mail App Cache** - Mail application caches (100MB-1GB)
16. **Siri TTS Cache** - Siri text-to-speech cache files
17. **iCloud Mail Cache** - iCloud Mail agent cache files
18. **QuickLook Thumbnails** - Regenerable thumbnail cache
19. **Diagnostic Reports** - System crash/diagnostic logs older than 30 days
20. **iOS Device Backups** - Local iTunes/Finder device backups ⚠️
21. **iOS/iPadOS Update Files** 🆕 - Stale `.ipsw` firmware files from iTunes (3–7 GB each!)

## Usage

### Basic Commands

```bash
# Preview what will be cleaned (dry-run mode)
sudo ./clean-mac-space.sh --dry-run

# Perform actual cleanup (will prompt for confirmation)
sudo ./clean-mac-space.sh

# Skip confirmation prompt
sudo ./clean-mac-space.sh --yes

# Check version
./clean-mac-space.sh --version
```

### Interactive Mode 🆕

Select exactly which categories to clean with an intuitive, keyboard-driven interface:

```bash
sudo ./clean-mac-space.sh --interactive
```

Interactive mode provides a menu where you can:
- **Navigate** with ↑↓ arrow keys
- **Toggle** categories with Space or Enter
- **Quick actions**: `a`=all, `n`=none, `d`=done, `q`=cancel
- **Number shortcuts**: 1-19 for instant toggle
- **Visual cursor** shows current selection
- **Real-time status** with color-coded checkmarks

**Real interactive menu (v3.2.0):**

```
Interactive Category Selection
================================================

Use ↑↓ arrow keys to navigate, Space/Enter to toggle
Press a=all, n=none, d=done, q=cancel

> [✓] Time Machine Snapshots
  [✓] Homebrew Cache
  [✓] Spotify Cache
  [✓] Claude Desktop Cache
  [✓] XCode Derived Data
  [✓] Browser Caches (Chrome, Firefox, Edge)
  [✓] npm/Yarn Cache
  [✓] Python pip Cache
  [✓] Trash Bin
  [ ] .DS_Store Files
  [✓] Docker Cache
  [✓] iOS Simulator Data
  [✓] Mail App Cache
  [✓] Siri TTS Cache
  [✓] iCloud Mail Cache
  [✓] QuickLook Thumbnails
  [✓] Diagnostic Reports (>30 days)
  [✓] iOS Device Backups (⚠️  requires confirmation)
  [✓] iOS/iPadOS Update Files (.ipsw)

Tip: Numbers 1-19 also work for quick toggle
```

### Configuration Profiles 🆕

Quick presets for common use cases:

```bash
# Conservative: Skip all development caches
sudo ./clean-mac-space.sh --profile conservative

# Developer: Skip only XCode (avoid long rebuilds)
sudo ./clean-mac-space.sh --profile developer

# Aggressive: Clean everything (maximum space recovery)
sudo ./clean-mac-space.sh --profile aggressive

# Minimal: Only safe system caches (quickest, safest)
sudo ./clean-mac-space.sh --profile minimal
```

### Advanced Options

```bash
# Skip specific categories
sudo ./clean-mac-space.sh --skip-xcode --skip-docker --skip-simulator

# Minimal output (useful for cron/automation)
sudo ./clean-mac-space.sh --quiet

# Only run if disk is above 80% full
sudo ./clean-mac-space.sh --threshold 80

# Disable colored output
sudo ./clean-mac-space.sh --no-color

# Combine options
sudo ./clean-mac-space.sh --dry-run --skip-browsers --skip-npm --profile developer
```

## All Available Flags

| Flag | Short | Description |
|------|-------|-------------|
| `--dry-run` | `-n` | Preview what would be cleaned without deleting |
| `--yes` | `-y` | Skip confirmation prompt and proceed |
| `--force` | `-f` | Skip ALL prompts (includes XCode warning) 🆕 |
| `--quiet` | `-q` | Minimal output (useful for cron) |
| `--no-color` | | Disable colored output |
| `--version` | `-v` | Display version information 🆕 |
| `--interactive` | `-i` | Interactive category selection mode 🆕 |
| `--profile NAME` | | Use preset profile (conservative, developer, aggressive, minimal) 🆕 |
| `--threshold N` | | Only run if disk usage is above N% |
| `--skip-snapshots` | | Skip Time Machine snapshot deletion |
| `--skip-homebrew` | | Skip Homebrew cache cleanup |
| `--skip-spotify` | | Skip Spotify cache cleanup |
| `--skip-claude` | | Skip Claude Desktop cache cleanup |
| `--skip-xcode` | | Skip XCode derived data cleanup |
| `--skip-browsers` | | Skip browser cache cleanup |
| `--skip-npm` | | Skip npm/yarn cache cleanup |
| `--skip-pip` | | Skip Python pip cache cleanup |
| `--skip-trash` | | Skip emptying trash bin |
| `--skip-dsstore` | | Skip .DS_Store file cleanup |
| `--skip-docker` | | Skip Docker cache cleanup |
| `--skip-simulator` | | Skip iOS Simulator data cleanup |
| `--skip-mail` | | Skip Mail app cache cleanup |
| `--skip-siri-tts` | | Skip Siri TTS cache cleanup |
| `--skip-icloud-mail` | | Skip iCloud Mail cache cleanup |
| `--skip-quicklook` | | Skip QuickLook thumbnails cleanup |
| `--skip-diagnostics` | | Skip diagnostic reports cleanup |
| `--skip-ios-backups` | | Skip iOS device backups cleanup |
| `--skip-ios-updates` | | Skip iOS/iPadOS update files (.ipsw) cleanup 🆕 |
| `--help` | `-h` | Show usage information |

## Configuration Profiles Explained

### Conservative Profile
**Use when**: You want to clean but keep development tools functional
**Skips**: XCode, npm, pip, browsers, Docker, iOS Simulator
**Best for**: Regular users, non-developers, cautious cleanup

```bash
sudo ./clean-mac-space.sh --profile conservative
```

### Developer Profile
**Use when**: You're a developer but want to avoid XCode rebuild times
**Skips**: Only XCode
**Best for**: Active developers who don't use XCode

```bash
sudo ./clean-mac-space.sh --profile developer
```

### Aggressive Profile
**Use when**: You need maximum space recovery
**Skips**: Nothing
**Best for**: Low disk space emergencies, periodic deep clean

```bash
sudo ./clean-mac-space.sh --profile aggressive
```

### Minimal Profile
**Use when**: Quick, safe cleanup without touching apps
**Skips**: All application caches, keeps only system cleanup
**Best for**: Daily/weekly automated runs

```bash
sudo ./clean-mac-space.sh --profile minimal
```

## Safety Guarantees

This script **NEVER** touches:
- Safari or browser history/sessions/bookmarks
- Application settings or configurations
- User documents or media files
- Active application data
- System critical files

All operations are scoped to safe cache and temporary directories.

### System Health Checks 🆕

The script now performs health checks before cleaning:
- **System Load**: Warns if system is under heavy load
- **Active Backups**: Detects running Time Machine backups
- **User Validation**: Ensures script is run correctly with sudo
- **Home Directory Verification**: Validates user home directory exists

## Typical Space Recovery

Depending on your usage, you can typically recover:

- **XCode Derived Data**: 5-50GB+ (if you develop with XCode)
- **Docker Cache**: 1-20GB+ (if you use Docker)
- **iOS/iPadOS Update Files**: 3-7GB per firmware file 🆕
- **Browser Caches**: 1-5GB
- **npm/Yarn Cache**: 500MB-5GB (if you develop with Node.js)
- **iOS Simulator Data**: 1-10GB+ (if you develop iOS apps)
- **pip Cache**: 100MB-2GB (if you code in Python)
- **Homebrew Cache**: 500MB-2GB
- **Mail Cache**: 100MB-1GB
- **Trash Bin**: Variable (whatever you've deleted)
- **Old Logs & Temps**: 100MB-1GB

**Total potential recovery: 15-100GB+** depending on your system usage.

## Configuration Files

You can save your preferred settings in a configuration file to avoid repeating command line flags. The script checks for config files in this order:

1. `~/.maccleans.conf` (recommended)
2. `~/.config/maccleans/config`
3. `${XDG_CONFIG_HOME}/maccleans/config`

### Example Configuration

Create `~/.maccleans.conf`:

```bash
# Conservative cleanup - skip development caches
SKIP_XCODE=true
SKIP_NPM=true
SKIP_PIP=true
SKIP_BROWSERS=true
SKIP_DOCKER=true
SKIP_SIMULATOR=true
```

Or for automated cron usage:

```bash
# Automated cleanup settings
QUIET=true
AUTO_YES=true
THRESHOLD=80
SKIP_XCODE=true
```

See `maccleans.conf.example` for a complete list of configurable options.

**Note**: Command line arguments always override config file settings.

## Real-World Example Run

The following is a real run using `--interactive` mode on a MacBook with a stale iPad firmware and accumulated caches. **23.46 GB freed in under 15 seconds.**

<details>
<summary>Full output (click to expand)</summary>

```
$ sudo ./clean-mac-space.sh --interactive

================================================
Mac Space Cleanup Script v3.2.0
================================================

[2026-02-20 14:34:47] Running as user: yourname
[2026-02-20 14:34:47] Home directory: /Users/yourname

[2026-02-20 14:34:47] Current disk usage: 32% (11Gi used, 25Gi available)

This will clean cache files, temporary files, and old logs.
Safari and browser data will NOT be touched.

Continue with cleanup? [y/N] y

================================================
[2026-02-20 14:34:48] 1. Time Machine Local Snapshots
================================================
[2026-02-20 14:34:50] Found 19 local snapshot(s) (estimated ~115.09G)
[2026-02-20 14:34:50] Deleting snapshots...
✓ Local snapshots deleted successfully

================================================
[2026-02-20 14:34:50] 2. Homebrew Cache
================================================
[2026-02-20 14:34:50] Current Homebrew cache: 998M
✓ Homebrew cleaned

================================================
[2026-02-20 14:34:55] 3. Application Cache Files
================================================
[2026-02-20 14:34:55] Spotify cache: 3.7G
✓ Spotify cache cleared
[2026-02-20 14:34:56] Claude Desktop update cache: 564M
✓ Claude update cache cleared

================================================
[2026-02-20 14:34:56] 9. npm/Yarn Cache
================================================
[2026-02-20 14:34:56] npm cache: 135M
✓ npm/yarn caches cleared: 135M

================================================
[2026-02-20 14:34:57] 16. Siri TTS Cache
================================================
[2026-02-20 14:34:57] Siri TTS cache: 223M
✓ Siri TTS cache cleared

================================================
[2026-02-20 14:34:57] 17. iCloud Mail Cache
================================================
[2026-02-20 14:34:57] iCloud Mail cache: 6.2M
✓ iCloud Mail cache cleared

================================================
[2026-02-20 14:34:57] 21. iOS/iPadOS Update Files (.ipsw)
================================================
[2026-02-20 14:34:57] Found: iPad_64bit_TouchID_ASTC_16.7.14_20H370_Restore.ipsw (5.20G)
[2026-02-20 14:34:57] Total: 1 file(s), 5.20G
[2026-02-20 14:34:57] Note: These are iOS/iPadOS firmware files used for device restores/updates.
[2026-02-20 14:34:57] They can be re-downloaded from Apple if needed.
[2026-02-20 14:34:57] Deleting iOS/iPadOS update files...
✓ iOS/iPadOS update files deleted (5.20G freed)

================================================
Cleanup Complete!
================================================

[2026-02-20 14:34:57] Initial disk usage: 32% (11Gi used, 25Gi available)
[2026-02-20 14:34:57] Final disk usage:   20% (11Gi used, 48Gi available)

✓ Actual space freed: 23.46G

Categories Processed:
  ✓ Time Machine Snapshots      ✓ Homebrew Cache
  ✓ Spotify Cache               ✓ Claude Desktop Cache
  ✓ System Cache Files          ✓ Old Log Files
  ✓ System Temporary Files      ✓ npm/Yarn Cache
  ✓ Python pip Cache            ✓ iOS Simulator Data
  ✓ Siri TTS Cache              ✓ iCloud Mail Cache
  ✓ iOS/iPadOS Update Files

Categories Skipped:
  ⊘ .DS_Store Files
```

</details>

### What made the difference

| Category | Space freed |
|---|---|
| Time Machine snapshots (19) | ~115 GB reclaimed from APFS purgeable pool |
| Spotify cache | 3.7 GB |
| iPad firmware (.ipsw) | **5.20 GB** |
| Claude Desktop update cache | 564 MB |
| Siri TTS cache | 223 MB |
| npm cache | 135 MB |
| iCloud Mail + misc | ~8 MB |
| **Total** | **23.46 GB actual** |

> The APFS snapshot estimate (125 GB) is intentionally conservative — actual freed space reflects what macOS released from the purgeable pool, which it manages dynamically.

## Enhanced Summary Report

After every run you get a full breakdown:

```
================================================
Cleanup Complete!
================================================

[2026-02-20 14:34:57] Initial disk usage: 32% (11Gi used, 25Gi available)
[2026-02-20 14:34:57] Final disk usage:   20% (11Gi used, 48Gi available)

✓ Actual space freed: 23.46G

Categories Processed:
  ✓ Time Machine Snapshots
  ✓ Homebrew Cache
  ✓ Spotify Cache
  ...

Categories Skipped:
  ⊘ .DS_Store Files

================================================
SAFETY GUARANTEES:
This script does NOT touch:
  - Safari or browser data/sessions
  - Application settings or configurations
  - User documents or media files
  - Active application data
================================================
```

## Understanding .DS_Store Files

`.DS_Store` (Desktop Services Store) files are hidden files automatically created by macOS in every folder you browse with Finder. They store:

- **View settings** - Icon size, sorting order, window size and position
- **Custom icons and backgrounds** - Visual customizations for folders
- **Display metadata** - How files should be displayed

### Why Clean Them?

- **Accumulation**: Every folder creates one - they add up over time
- **Backup clutter**: Increase backup sizes unnecessarily
- **Version control noise**: Frequently appear in git commits
- **Cross-platform problems**: Cause issues when sharing with Windows/Linux

### Are They Safe to Delete?

**Yes, completely safe!** They're automatically regenerated by Finder. Deleting them won't affect your files, applications, or system operation.

## Examples

### Development Machine Full Cleanup
```bash
sudo ./clean-mac-space.sh
```
Cleans everything including browsers, XCode, npm, pip, Docker, and other caches.

### Conservative Cleanup (Skip Dev Caches)
```bash
sudo ./clean-mac-space.sh --profile conservative
```
Cleans only safe categories - perfect if you don't want to rebuild projects.

### Quick Browser & System Cleanup
```bash
sudo ./clean-mac-space.sh --skip-xcode --skip-npm --skip-pip --skip-docker
```
Fast cleanup that won't affect development environments.

### Interactive Selection
```bash
sudo ./clean-mac-space.sh --interactive
```
Choose exactly what to clean with a user-friendly menu.

### Scheduled Cleanup via Cron
```bash
# Clean daily at 2 AM, threshold at 75% disk usage
0 2 * * * /usr/bin/sudo /usr/local/bin/clean-mac-space --quiet --threshold 75 --yes --profile minimal
```

## Permissions

This script requires `sudo` privileges to:
- Delete Time Machine snapshots
- Clean system temporary directories
- Access system cache locations
- Clean Docker system data

Running with `sudo` is necessary but safe - the script only operates on system cache and temporary directories.

## Troubleshooting

**Common issues**:

- **"This script requires sudo privileges"** - Run with `sudo ./clean-mac-space.sh`
- **"Cannot determine actual user"** - Don't run as root directly, use `sudo` from your regular account
- **Preview before deleting** - Use `--dry-run` to see what would be cleaned
- **Skip XCode rebuilds** - Use `--skip-xcode` or `--profile developer`

For comprehensive troubleshooting, see **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)**.

## Documentation

### 📚 Core Documentation

- **[Installation Guide](INSTALL.md)** - Complete installation instructions, configuration setup, and automation
- **[FAQ](FAQ.md)** - Frequently asked questions covering safety, features, troubleshooting, and comparisons
- **[Troubleshooting Guide](TROUBLESHOOTING.md)** - Solutions to common errors, permission issues, and recovery procedures
- **[Advanced Usage](ADVANCED.md)** - Multi-profile configs, CI/CD integration, monitoring, and enterprise deployment
- **[Contributing Guide](CONTRIBUTING.md)** - How to contribute, code style, testing, and adding cleanup categories
- **[Security Policy](SECURITY.md)** - Vulnerability reporting and security considerations
- **[Changelog](CHANGELOG.md)** - Version history and release notes

### 📖 In-Depth Guides

Explore [docs/](docs/) for comprehensive educational guides:

- **[Understanding macOS Caches](docs/understanding-macos-caches.md)** - Deep dive into cache types, how they work, and when to clean them
- **[When to Clean XCode Derived Data](docs/xcode-derived-data-guide.md)** - Comprehensive guide for iOS/Mac developers on managing XCode caches
- **[Docker Cache Management](docs/docker-cache-guide.md)** - Best practices for Docker cleanup without breaking workflows
- **[Automating macOS Maintenance](docs/automating-macos-maintenance.md)** - Complete automation guide with cron, LaunchD, and custom scripts

### 🎯 Quick Links

| I want to... | Read this |
|--------------|-----------|
| Install MacCleans | [Installation Guide](INSTALL.md) |
| Understand what's safe to delete | [Understanding Caches](docs/understanding-macos-caches.md) |
| Automate cleanup | [Automation Guide](docs/automating-macos-maintenance.md) |
| Fix an error | [Troubleshooting](TROUBLESHOOTING.md) |
| Use advanced features | [Advanced Usage](ADVANCED.md) |
| Manage XCode caches | [XCode Guide](docs/xcode-derived-data-guide.md) |
| Clean Docker | [Docker Guide](docs/docker-cache-guide.md) |
| Contribute code | [Contributing](CONTRIBUTING.md) |
| Report a bug | [Bug Template](.github/ISSUE_TEMPLATE/bug_report.md) |
| Report a vulnerability | [Security Policy](SECURITY.md) |
| Ask questions | [FAQ](FAQ.md) |

## Version History

See [CHANGELOG.md](CHANGELOG.md) for detailed version history and what changed in each release.

**Latest**: v3.2.0 (2026-02-20)
- iOS/iPadOS update file (.ipsw) detection and cleanup
- New `--skip-ios-updates` flag and `SKIP_IOS_UPDATES` config key
- Conservative and minimal profiles updated
- 21 cleanup categories total

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

MIT - Feel free to modify and distribute.

## Built With

This project is **vibe coded** with the help of [Claude](https://claude.ai) (Anthropic's AI). The idea, direction, and decisions are all human - Claude helps with the heavy lifting of writing code, docs, and catching things I'd miss.

**Why be transparent about it?** Because honesty is cool, and this is a free tool that does what other apps charge money for. No dodgy data collection, no subscriptions, no "premium tier" - just a bash script that cleans your Mac.

AI-assisted doesn't mean AI-generated-and-forgotten. Every change is reviewed, tested, and intentional. If you're curious about vibe coding or want to contribute (with or without AI help), you're welcome here.

## Support

- **Issues**: [GitHub Issues](https://github.com/Carme99/MacCleans.sh/issues)
- **Discussions**: [GitHub Discussions](https://github.com/Carme99/MacCleans.sh/discussions)
- **Releases**: [GitHub Releases](https://github.com/Carme99/MacCleans.sh/releases)
