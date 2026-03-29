      ⚡  MacCleans  ⚡
            v5.1.6

Free 10-50GB on your Mac with one command.

[![Version](https://img.shields.io/badge/Version-5.1.6-blue.svg)](CHANGELOG.md)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![macOS](https://img.shields.io/badge/macOS-10.15+-blue.svg)](https://www.apple.com/macos/)
[![Stars](https://img.shields.io/github/stars/Carme99/MacCleans.sh?style=social)](https://github.com/Carme99/MacCleans.sh/stargazers)

---

## Quick Start

```bash
# Install via Homebrew (recommended)
brew tap Carme99/tap
brew install mac-cleans

# Or install via curl
curl -fsSL https://raw.githubusercontent.com/Carme99/MacCleans.sh/main/installer.sh | bash

# Preview what would be cleaned
sudo mac-cleans --dry-run

# Clean everything (non-interactive)
sudo mac-cleans --yes
```

---

## Example Output

```bash
$ sudo Mac-Clean --dry-run
[!] Disk usage: 85% - scanning...
[✓] XCode Derived Data: 12.3 GB
[✓] Homebrew Cache: 2.1 GB
[✓] Docker Cache: 8.5 GB
[✓] npm/Yarn Cache: 1.2 GB
[⚡] Would reclaim: ~23 GB
```

```bash
$ sudo Mac-Clean --json
{
  "version": "5.1",
  "timestamp": "2026-03-07T10:30:00Z",
  "dry_run": false,
  "results": {
    "categories": {
      "processed": [
        "XCode Derived Data",
        "Homebrew Cache",
        "Docker Cache"
      ],
      "skipped": [
        "Time Machine Snapshots"
      ]
    },
    "disk_usage": {
      "before": 85,
      "after": 77
    },
    "space_freed": {
      "bytes": 24696061952,
      "human": "23.00 GB"
    }
  }
}
```

---

## Features

- **Safe by Design** - Only removes cache/temp files, never touches user data
- **29 Categories** - XCode, Docker, Homebrew, npm, pip, browsers, and more
- **Interactive Mode** - Choose exactly what to clean
- **Profiles** - Quick presets: conservative, developer, aggressive, minimal
- **JSON Output** - `--json` flag for automation/monitoring

---

## What Gets Cleaned

| Category | Typical Size |
|----------|-------------|
| XCode Derived Data | 5-50GB |
| Docker Cache | 1-20GB |
| Homebrew Cache | 1-5GB |
| npm/pip Cache | 500MB-5GB |
| Time Machine Snapshots | 10-100GB |
| +24 more | |

[Full list →](docs/advanced.md#what-gets-cleaned)

---

## Installation

```bash
# Installer (recommended)
curl -fsSL https://raw.githubusercontent.com/Carme99/MacCleans.sh/main/installer.sh | bash

# Or manual
curl -fsSL https://raw.githubusercontent.com/Carme99/MacCleans.sh/main/clean-mac-space.sh -o /usr/local/bin/Mac-Clean
chmod +x /usr/local/bin/Mac-Clean
```

[More options →](docs/install.md)

---

## Common Commands

| Use Case | Command |
|----------|---------|
| Preview | `sudo Mac-Clean --dry-run` |
| Clean all | `sudo Mac-Clean --yes` |
| Skip all confirmations | `sudo Mac-Clean --force` |
| Interactive | `sudo Mac-Clean --interactive` |
| Use profile | `sudo Mac-Clean --profile developer` |
| Skip category | `sudo Mac-Clean --skip-xcode` |
| Threshold | `sudo Mac-Clean --threshold 80` |
| JSON output | `sudo Mac-Clean --json` |

---

## Documentation

| Guide | Description |
|-------|-------------|
| [docs/install.md](docs/install.md) | Installation & setup |
| [docs/quickstart.md](docs/quickstart.md) | 5-minute guide |
| [docs/advanced.md](docs/advanced.md) | Automation & CI/CD |
| [docs/faq.md](docs/faq.md) | Common questions |
| [docs/troubleshooting.md](docs/troubleshooting.md) | Help |
| [CHANGELOG.md](CHANGELOG.md) | Version history |
| [CONTRIBUTING.md](CONTRIBUTING.md) | Contributing |

---

## What's New in v5.1

- **Photos Library Fix** - Size calculation now only measures cache (Thumbnails, Previews) instead of entire library
- **npm Cache Fix** - Size display now correctly shows "211M" instead of "211B"

## What's New in v5.0

- **Homebrew Support** - Install via `brew tap Carme99/tap && brew install mac-cleans`
- **Shell Completions** - Bash, Zsh, and Fish completions included
- **Progress Spinner** - Visual feedback during long operations
- **Improved Errors** - Better error messages with recovery suggestions

## What's New in v4.3

- **Enhanced iCloud sync check** - Detects pending uploads before iCloud cleanup
- **Xcode rebuild protection** - `--yes` no longer bypasses Xcode confirmation; requires `--force`
- **Disk space guard** - Pre-check ensures 200MB free before cleanup starts
- **Better error reporting** - Deletion failures tracked and reported in summary

## What's New in v4.2

- **JSON Output** - `--json` flag for automation/monitoring
- **Documentation Restructure** - Detailed docs moved to `docs/` folder

[Full changelog →](CHANGELOG.md)

---

## License

[MIT](LICENSE) - Free, open source, privacy-first.
