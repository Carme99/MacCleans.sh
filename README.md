[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![macOS](https://img.shields.io/badge/macOS-10.15+-blue.svg)](https://www.apple.com/macos/)
[![Shell](https://img.shields.io/badge/Shell-Bash-black.svg)](https://www.gnu.org/software/bash/)
[![Maintenance](https://img.shields.io/badge/Maintained%3F-yes-green.svg)](https://github.com/Carme99/MacCleans.sh/graphs/commit-activity)
[![Documentation](https://img.shields.io/badge/Docs-Comprehensive-brightgreen.svg)](docs/)

# Mac Space Cleanup Script

A comprehensive macOS disk cleanup utility that safely frees up disk space by removing cache files, temporary files, and other safe-to-delete items.

## ✨ What's New in v3.0.0

- 🎯 **Interactive Mode**: Select exactly what to clean with `--interactive`
- 📋 **Configuration Profiles**: Preset cleanup modes (conservative, developer, aggressive, minimal)
- ✅ **Enhanced Validation**: Config validation and system health checks
- 🔒 **Security Improvements**: User validation and better error handling
- 🐳 **Docker Cache Cleanup**: Clean Docker images, containers, and volumes
- 📱 **iOS Simulator Cleanup**: Clear simulator data and caches
- 📧 **Mail App Cache**: Clean Mail application caches
- 📊 **Enhanced Summary Report**: Detailed breakdown of what was cleaned vs skipped
- 🛡️ **ShellCheck Compliant**: Strict error handling with `set -euo pipefail`
- ℹ️ **Version Flag**: Check version with `--version` or `-v`

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
15. **Mail App Cache** 🆕 - Mail application caches (100MB-1GB)

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
- **Number shortcuts**: 1-13 for instant toggle
- **Visual cursor** shows current selection
- **Real-time status** with color-coded checkmarks

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
| `--skip-docker` | | Skip Docker cache cleanup 🆕 |
| `--skip-simulator` | | Skip iOS Simulator data cleanup 🆕 |
| `--skip-mail` | | Skip Mail app cache cleanup 🆕 |
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
- **Docker Cache**: 1-20GB+ (if you use Docker) 🆕
- **Browser Caches**: 1-5GB
- **npm/Yarn Cache**: 500MB-5GB (if you develop with Node.js)
- **iOS Simulator Data**: 1-10GB+ (if you develop iOS apps) 🆕
- **pip Cache**: 100MB-2GB (if you code in Python)
- **Homebrew Cache**: 500MB-2GB
- **Mail Cache**: 100MB-1GB 🆕
- **Trash Bin**: Variable (whatever you've deleted)
- **Old Logs & Temps**: 100MB-1GB

**Total potential recovery: 15-100GB** depending on your system usage.

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

## Enhanced Summary Report 🆕

After cleanup, you'll see a detailed summary:

```
================================================
Cleanup Complete!
================================================

Initial disk usage: 85% (250G used, 50G available)
Final disk usage:   78% (235G used, 65G available)

✓ Approximate space freed: 15.2G

Categories Processed:
  ✓ Time Machine Snapshots
  ✓ Homebrew Cache
  ✓ Browser Caches
  ✓ npm/Yarn Cache
  ✓ Docker Cache
  ✓ Trash Bin
  ✓ .DS_Store Files

Categories Skipped:
  ⊘ XCode Derived Data
  ⊘ iOS Simulator Data
  ⊘ Python pip Cache

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

### "This script requires sudo privileges"
Run with `sudo`:
```bash
sudo ./clean-mac-space.sh
```

### "Cannot determine actual user"
Don't run as root directly. Use sudo from your regular user account:
```bash
# DON'T: sudo su, then ./clean-mac-space.sh
# DO: sudo ./clean-mac-space.sh
```

### XCode cleanup warning appears but I want to skip it
Use `--skip-xcode` flag or profile:
```bash
sudo ./clean-mac-space.sh --skip-xcode
# OR
sudo ./clean-mac-space.sh --profile developer
```

### I want to see what would be deleted first
Use `--dry-run` flag:
```bash
sudo ./clean-mac-space.sh --dry-run
```

### Configuration file not being loaded
Check file location and format:
```bash
ls -la ~/.maccleans.conf
# Format should be KEY=value (no spaces around =)
```

### System warnings about high load or active backups
The script will warn you if:
- System load is high (>10)
- Time Machine backup is running

You can proceed anyway or wait for a better time.

### Disk usage hasn't changed much
Some caches are small. XCode and Docker (if present) are typically the largest. Run in dry-run mode to see actual sizes before cleanup.

## Documentation

### 📚 Core Documentation

- **[Installation Guide](INSTALL.md)** - Complete installation instructions, configuration setup, and automation
- **[FAQ](FAQ.md)** - Frequently asked questions covering safety, features, troubleshooting, and comparisons
- **[Troubleshooting Guide](TROUBLESHOOTING.md)** - Solutions to common errors, permission issues, and recovery procedures
- **[Advanced Usage](ADVANCED.md)** - Multi-profile configs, CI/CD integration, monitoring, and enterprise deployment
- **[Contributing Guide](CONTRIBUTING.md)** - How to contribute, code style, testing, and adding cleanup categories
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
| Ask questions | [FAQ](FAQ.md) |

## Version History

See [CHANGELOG.md](CHANGELOG.md) for detailed version history and what changed in each release.

**Latest**: v3.0.0 (2026-02-02)
- Interactive mode and configuration profiles
- Docker, iOS Simulator, and Mail cache cleanup
- Enhanced validation and system health checks
- Improved error handling and summary reporting

## FAQ

### Q: Is it safe to run this script?
A: Yes. The script only removes cache and temporary files that macOS can regenerate. It never touches user documents, application settings, or system critical files.

### Q: How often should I run this?
A: Depends on your usage:
- Heavy developers: Weekly
- Regular users: Monthly
- Light users: Quarterly
- Automated with `--threshold`: Let it decide

### Q: Will this break my applications?
A: No. Applications may need to rebuild caches (slower first launch) but won't break. XCode projects will need to rebuild (5-30 min).

### Q: Can I undo the cleanup?
A: No. Deleted files cannot be recovered. Always use `--dry-run` first to preview.

### Q: Why does it need sudo?
A: To access system cache directories and Time Machine snapshots that require elevated privileges.

### Q: Does this work on Apple Silicon Macs?
A: Yes, fully compatible with both Intel and Apple Silicon Macs running macOS 10.15+.

### Q: What's the difference between profiles and skip flags?
A: Profiles are convenient presets. Skip flags give you granular control. You can combine them: `--profile developer --skip-npm`.

### Q: Is interactive mode available in quiet mode?
A: No. Interactive mode requires user input, so it's disabled when `--quiet` is used.

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

MIT - Feel free to modify and distribute.

## Support

- **Issues**: [GitHub Issues](https://github.com/Carme99/MacCleans.sh/issues)
- **Discussions**: [GitHub Discussions](https://github.com/Carme99/MacCleans.sh/discussions)
- **Releases**: [GitHub Releases](https://github.com/Carme99/MacCleans.sh/releases)
