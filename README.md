[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![macOS](https://img.shields.io/badge/macOS-10.15+-blue.svg)](https://www.apple.com/macos/)
[![Shell](https://img.shields.io/badge/Shell-Bash-black.svg)](https://www.gnu.org/software/bash/)
[![Maintenance](https://img.shields.io/badge/Maintained%3F-yes-green.svg)](https://github.com/Carme99/MacCleans.sh/graphs/commit-activity)
[![Documentation](https://img.shields.io/badge/Docs-Comprehensive-brightgreen.svg)](docs/)

# Mac Space Cleanup Script

A comprehensive macOS cleanup utility that safely frees up disk space by removing cache files, temporary files, and other safe-to-delete items.

## Features

- **Safe by Design**: Only removes cache and temp files, never touches user data, documents, or application settings
- **Opt-Out Approach**: New cleanup categories enabled by default with `--skip-*` flags
- **Preview Mode**: Use `--dry-run` to see what would be deleted before confirming
- **Detailed Reporting**: Shows exact space freed for each category
- **Interactive Warnings**: Special alerts for risky operations like XCode cache deletion
- **Configuration File Support**: Save your preferred settings in `~/.maccleans.conf`
- **Colored Output**: Visual feedback with color-coded success, warnings, and errors

## Installation

See [INSTALL.md](INSTALL.md) for detailed installation instructions including:
- Quick installation methods (curl download or git clone)
- Setting up configuration files
- Automated cleanup with cron or launchd

## What Gets Cleaned

- **Time Machine Local Snapshots** - Old backup snapshots (with safety checks)
- **Homebrew Cache** - Package manager cache and old downloads
- **Application Caches** - Spotify, Claude Desktop, and system app caches
- **System Caches** - GeoServices, helpd, parsecd, and compiler cache (>30 days old)
- **Old Logs** - Log files older than 7 days
- **Temporary Files** - System temp directories (`/tmp`, `/var/tmp`)

### New in V2.0

- **Browser Caches** - Chrome, Firefox, and Microsoft Edge caches
- **XCode Derived Data** - XCode build cache (with interactive warning)
- **npm/Yarn Cache** - Node.js package manager caches
- **Python pip Cache** - Python package manager cache
- **Trash Bin** - Empties user trash directory
- **.DS_Store Files** - macOS system metadata files

### Understanding .DS_Store Files

`.DS_Store` (Desktop Services Store) files are hidden files automatically created by macOS in every folder you browse with Finder. They're essentially preference caches that store:

- **View settings** - Icon size, sorting order, window size and position
- **Custom icons and backgrounds** - Visual customizations for folders
- **Display metadata** - How files should be displayed (thumbnails, list view, etc.)

#### Why Clean Them?

**Accumulation**: Every folder you open in Finder creates one. Over time, especially on shared drives and after copying many folders, they accumulate significantly.

**Backup clutter**: They increase backup sizes and can cause issues when syncing across devices or to cloud storage.

**Version control noise**: `.DS_Store` files frequently appear in git commits and cause merge conflicts.

**Cross-platform problems**: When sharing folders with Windows or Linux users, these files can cause compatibility issues.

#### Are They Safe to Delete?

**Yes, completely safe!** They're automatically regenerated the next time you use Finder. Deleting them won't affect:
- Your actual files or documents
- Application functionality
- System operation
- Folder organization or contents

Think of them as cached UI preferences - useful but regenerable.

## Usage

### Basic Usage

```bash
# Preview what will be cleaned (dry-run mode)
sudo ./clean-mac-space.sh --dry-run

# Perform actual cleanup (will prompt for confirmation)
sudo ./clean-mac-space.sh

# Skip confirmation prompt
sudo ./clean-mac-space.sh --yes
```

### With Options

```bash
# Skip specific categories
sudo ./clean-mac-space.sh --skip-xcode --skip-dsstore

# Minimal output (useful for cron/automation)
sudo ./clean-mac-space.sh --quiet

# Only run if disk is above 80% full
sudo ./clean-mac-space.sh --threshold 80

# Combine options
sudo ./clean-mac-space.sh --dry-run --skip-browsers --skip-npm
```

## All Available Flags

| Flag | Short | Description |
|------|-------|-------------|
| `--dry-run` | `-n` | Preview what would be cleaned without deleting |
| `--yes` | `-y` | Skip confirmation prompt and proceed |
| `--quiet` | `-q` | Minimal output (useful for cron) |
| `--no-color` | | Disable colored output |
| `--threshold N` | | Only run if disk usage is above N% |
| `--skip-snapshots` | | Skip Time Machine snapshot deletion |
| `--skip-homebrew` | | Skip Homebrew cache cleanup |
| `--skip-spotify` | | Skip Spotify cache cleanup |
| `--skip-claude` | | Skip Claude Desktop cache cleanup |
| `--skip-xcode` | | Skip XCode derived data cleanup |
| `--skip-browsers` | | Skip browser cache cleanup (Chrome, Firefox, Edge) |
| `--skip-npm` | | Skip npm/yarn cache cleanup |
| `--skip-pip` | | Skip Python pip cache cleanup |
| `--skip-trash` | | Skip emptying trash bin |
| `--skip-dsstore` | | Skip .DS_Store file cleanup |
| `--help` | `-h` | Show usage information |

## Safety Guarantees

This script **NEVER** touches:
- Safari or browser history/sessions/bookmarks
- Application settings or configurations
- User documents or media files
- Active application data
- System critical files

All operations are scoped to safe cache and temporary directories.

## Typical Space Recovery

Depending on your usage, you can typically recover:

- **XCode Derived Data**: 5-50GB+ (if you develop)
- **Browser Caches**: 1-5GB
- **npm/Yarn Cache**: 500MB-5GB (if you develop)
- **pip Cache**: 100MB-2GB (if you code in Python)
- **Homebrew Cache**: 500MB-2GB
- **Trash Bin**: Variable
- **Old Logs & Temps**: 100MB-1GB

**Total potential recovery: 10-70GB** depending on your system usage.

## Permissions

This script requires `sudo` privileges to:
- Delete Time Machine snapshots
- Clean system temporary directories
- Access system cache locations

Running with `sudo` is necessary but safe - the script only operates on system cache and temporary directories.

## Configuration Files

You can save your preferred settings in a configuration file to avoid repeating command line flags. The script checks for config files in this order:

1. `~/.maccleans.conf`
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

## Examples

### Development Machine Full Cleanup
```bash
sudo ./clean-mac-space.sh
```
Cleans everything including browsers, XCode, npm, pip, and other caches (default behavior).

### Conservative Cleanup (Skip Dev Caches)
```bash
sudo ./clean-mac-space.sh --skip-xcode --skip-npm --skip-pip --skip-browsers
```
Cleans only safe categories (logs, trash, system caches) - perfect if you don't want to rebuild projects.

### Quick Browser & Trash Cleanup
```bash
sudo ./clean-mac-space.sh --skip-xcode --skip-npm --skip-pip --skip-spotify --skip-claude
```
Fast cleanup that won't affect development environments.

### Scheduled Cleanup via Cron
```bash
# Clean daily at 2 AM, threshold at 75% disk usage
0 2 * * * /usr/bin/sudo ./clean-mac-space.sh --quiet --threshold 75 --yes
```

## Troubleshooting

### "This script needs sudo privileges"
Run with `sudo`:
```bash
sudo ./clean-mac-space.sh
```

### XCode cleanup warning appears but I want to skip it
Use `--skip-xcode` flag:
```bash
sudo ./clean-mac-space.sh --skip-xcode
```

### I want to see what would be deleted first
Use `--dry-run` flag:
```bash
sudo ./clean-mac-space.sh --dry-run
```

### Disk usage hasn't changed much
Some caches are small. XCode derived data (if present) is typically the largest. Run in dry-run mode to see actual sizes before cleanup.

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

## License

MIT - Feel free to modify and distribute.
