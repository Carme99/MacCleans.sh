# MacCleans

```
██████╗ ███████╗███████╗██╗   ██╗███████╗
██╔══██╗██╔════╝██╔════╝██║   ██║██╔════╝
██║  ██║█████╗  █████╗  ██║   ██║███████╗
██║  ██║██╔══╝  ██╔══╝  ╚██╗ ██╔╝╚════██║
██████╔╝███████╗███████╗ ╚████╔╝  ███████║
╚═════╝ ╚══════╝╚══════╝  ╚═══╝   ╚══════╝
```

**Free 10-50GB on your Mac with one command.**

[![Version](https://img.shields.io/badge/Version-5.1.6-blue.svg)](CHANGELOG.md)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![macOS](https://img.shields.io/badge/macOS-10.15+-blue.svg)](https://www.apple.com/macos/)
[![ShellCheck](https://github.com/Carme99/MacCleans.sh/actions/workflows/shellcheck.yml/badge.svg)](https://github.com/Carme99/MacCleans.sh/actions)
[![Stars](https://img.shields.io/github/stars/Carme99/MacCleans.sh?style=social)](https://github.com/Carme99/MacCleans.sh/stargazers)

---

## Quick Start

```bash
# Install via Homebrew (recommended)
brew install carme99/tap/mac-cleans

# Or install via curl
curl -fsSL https://raw.githubusercontent.com/Carme99/MacCleans.sh/main/installer.sh | bash

# Preview what would be cleaned
sudo Mac-Clean --dry-run

# Clean everything (non-interactive)
sudo Mac-Clean --yes
```

---

## What You'll Get Back

| Category | Typical Size | Notes |
|----------|-------------|-------|
| Xcode Derived Data | 5-50GB | Rebuilds automatically |
| Docker | 1-20GB | Containers + images |
| Homebrew Cache | 1-5GB | Cached downloads |
| npm / Yarn / pnpm | 500MB-5GB | Node.js development |
| pip Cache | 100MB-2GB | Python development |
| Browser Caches | 1-5GB | Chrome, Firefox, Edge |
| iOS Simulator | 1-10GB | Slow rebuild |
| Time Machine | 10-100GB | Local snapshots |
| Trash | Variable | Permanent deletion |
| +20 more | | [See all categories](docs/all-categories.md) |

---

## Features

| | | |
|----------|----------|----------|
| Safe by design | 29 categories | Interactive mode |
| Profile presets | JSON output | CI/CD ready |

---

## Installation

### Homebrew (recommended)

```bash
brew install carme99/tap/mac-cleans
```

### Curl

```bash
curl -fsSL https://raw.githubusercontent.com/Carme99/MacCleans.sh/main/installer.sh | bash
```

### Git Clone

```bash
git clone https://github.com/Carme99/MacCleans.sh.git
cd MacCleans.sh
chmod +x clean-mac-space.sh
sudo ./clean-mac-space.sh --dry-run
```

---

## Common Commands

| Use Case | Command |
|----------|---------|
| Preview | `sudo Mac-Clean --dry-run` |
| Clean all | `sudo Mac-Clean --yes` |
| Skip all confirmations | `sudo Mac-Clean --force` |
| Interactive | `sudo Mac-Clean --interactive` |
| Developer preset | `sudo Mac-Clean --profile developer` |
| Skip specific | `sudo Mac-Clean --skip-xcode` |
| Threshold | `sudo Mac-Clean --threshold 80` |
| JSON output | `sudo Mac-Clean --json` |

---

## Documentation

| Guide | Description |
|-------|-------------|
| [Getting Started](docs/getting-started.md) | First time? Start here |
| [Installation](docs/installation.md) | Installation methods and verification |
| [All Categories](docs/all-categories.md) | Complete list of what gets cleaned |
| [Profiles](docs/profiles.md) | Conservative, developer, aggressive, minimal |
| [Command Reference](docs/command-reference.md) | All flags, options, and JSON output |
| [Configuration](docs/configuration.md) | Config files and environment variables |
| [Automation](docs/automation.md) | Cron, LaunchD, and CI/CD integration |
| [Developer Guide](docs/developer-guide.md) | Adding new cleanup categories |
| [Storage Explained](docs/storage-explained.md) | How macOS storage works |
| [Error Codes](docs/error-codes.md) | Exit codes and troubleshooting |
| [FAQ](docs/faq.md) | Common questions |
| [Troubleshooting](docs/troubleshooting.md) | Problems and solutions |
| [Security](docs/security.md) | Auditing and safety |

---

## Example Output

```bash
$ sudo Mac-Clean --dry-run
[!] Disk usage: 85% - scanning...
[✓] Xcode Derived Data: 12.3 GB
[✓] Homebrew Cache: 2.1 GB
[✓] Docker: 8.5 GB
[✓] npm/Yarn Cache: 1.2 GB
[⚡] Would reclaim: ~23 GB
```

---

## About

Built for fun and learning. No subscriptions, no cloud, no telemetry.

**Why?** Because my MacBook Air had 256GB and CleanMyMac wanted £25/year for the privilege of cleaning up after myself.

This script does one thing: it frees up disk space by removing safe-to-delete cache and temporary files. Everything is open source, auditable, and runs 100% locally on your machine.

---

## License

[MIT](LICENSE) - Free, open source, and transparent.

---

<p align="center">
  <a href="https://github.com/Carme99/MacCleans.sh">GitHub</a> ·
  <a href="https://github.com/Carme99/MacCleans.sh/issues">Issues</a> ·
  <a href="CHANGELOG.md">Changelog</a>
</p>
