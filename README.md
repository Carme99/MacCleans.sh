# MacCleans

```
  __  __                   ____   _                              
 |  \/  |   __ _    ___   / ___| | |   ___    __ _   _ __    ___ 
 | |\/| |  / _` |  / __| | |     | |  / _ \  / _` | | '_ \  / __|
 | |  | | | (_| | | (__  | |___  | | |  __/ | (_| | | | | | \__ \
 |_|  |_|  \__,_|  \___|  \____| |_|  \___|  \__,_| |_| |_| |___/
```

**Free 10-50GB on your Mac with one command.**

[![Version](https://img.shields.io/badge/Version-5.8.0-blue.svg)](CHANGELOG.md)
![CodeRabbit Pull Request Reviews](https://img.shields.io/coderabbit/prs/github/Carme99/MacCleans.sh?utm_source=oss&utm_medium=github&utm_campaign=Carme99%2FMacCleans.sh&labelColor=171717&color=FF570A&link=https%3A%2F%2Fcoderabbit.ai&label=CodeRabbit+Reviews)
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
| Browser Testing Tool Caches | 500MB-2GB | Re-downloaded on next test |
| Crash Reports | 100MB-1GB | Old crash dumps (>7 days) |
| User Tool Caches | 500MB-2GB | `~/.cache/` redownloads on demand |
| +20 more | | [See all categories](docs/reference/categories.md) |

---

## Features

| | | |
|----------|----------|----------|
| Safe by design | 32 categories | Interactive mode |
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

Full docs at [docs/README.md](docs/README.md). Quick links:

| I want to... | Guide |
|---|---|
| Run it for the first time | [tutorials/getting-started.md](docs/tutorials/getting-started.md) |
| See a one-screen walkthrough | [tutorials/first-cleanup.md](docs/tutorials/first-cleanup.md) |
| Install | [how-to/install.md](docs/how-to/install.md) |
| Configure skip flags | [how-to/configure.md](docs/how-to/configure.md) |
| Find a specific flag | [reference/commands.md](docs/reference/commands.md) |
| See what each category cleans | [reference/categories.md](docs/reference/categories.md) |
| Understand the architecture | [explanation/how-it-works.md](docs/explanation/how-it-works.md) |
| Got an error? | [how-to/troubleshooting.md](docs/how-to/troubleshooting.md) |
| Add a new cleanup category | [contributing/adding-a-category.md](docs/contributing/adding-a-category.md) |

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
