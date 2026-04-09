# Getting Started

First time? Start here. This guide will walk you through installing MacCleans and running your first cleanup.

## Prerequisites

- **macOS 10.15 (Catalina)** or later
- **sudo access** - the script needs admin privileges to clean system caches
- **Terminal** - you'll need to run commands in Terminal

## Installation

### Homebrew (Recommended)

```bash
brew install carme99/tap/mac-cleans
```

### Curl

```bash
curl -fsSL https://raw.githubusercontent.com/Carme99/MacCleans.sh/main/installer.sh | bash
```

For more installation options, see [Installation](installation.md).

## Your First Cleanup

**Always preview first!** The `--dry-run` flag shows what would be cleaned without deleting anything.

```bash
sudo Mac-Clean --dry-run
```

You'll see output like this:

```
[!] Disk usage: 85% - scanning...
[✓] Xcode Derived Data: 12.3 GB
[✓] Homebrew Cache: 2.1 GB
[✓] Docker: 8.5 GB
[✓] npm/Yarn Cache: 1.2 GB
[⚡] Would reclaim: ~23 GB
```

## Understanding the Output

| Symbol | Meaning |
|--------|---------|
| `[✓]` | This category will be cleaned |
| `[!]` | Warning or important info |
| `[⚡]` | Summary of space to be reclaimed |
| `[skip]` | Category skipped (not found or zero size) |

## Actually Cleaning

Once you're happy with the preview, run without `--dry-run`:

```bash
sudo Mac-Clean --yes
```

The script will:
1. Ask for confirmation (if not using `--yes`)
2. Clean each category
3. Show you how much space was freed
4. Report any errors

## Safe by Design

MacCleans only removes cache and temporary files that macOS and applications can regenerate. It never touches:

- Your documents, photos, or media
- Application settings or configurations
- Browser history, bookmarks, or passwords
- Email messages

## Dry-Run First!

**Always run `--dry-run` before cleaning.** This lets you:

- See exactly what would be deleted
- Spot any categories you want to keep
- Verify the script is working correctly

## Next Steps

### Choose a Profile

Profiles are presets for different use cases:

```bash
# Conservative - skips development caches (recommended for most)
sudo Mac-Clean --profile conservative

# Developer - skips only Xcode (if you develop with Xcode)
sudo Mac-Clean --profile developer

# Aggressive - cleans everything
sudo Mac-Clean --profile aggressive

# Minimal - only essential cleanup
sudo Mac-Clean --profile minimal
```

See [Profiles](profiles.md) for full details.

### Skip Specific Categories

Don't want to clean something? Skip it:

```bash
sudo Mac-Clean --yes --skip-xcode --skip-docker
```

### Interactive Mode

Pick exactly what to clean:

```bash
sudo Mac-Clean --interactive
```

Use arrow keys to navigate, space to select, Enter to confirm.

## Common First-Timer Questions

**Q: Will this delete my important files?**
A: No. MacCleans only removes cache and temp files. Your documents are safe.

**Q: Do I need to reboot after?**
A: No. Caches rebuild automatically when needed.

**Q: How often should I run this?**
A: Monthly is fine for most users. Weekly for heavy users. Use `--threshold` to automate.

**Q: My disk is nearly full and Mac is slow. Help!**
A: Run `sudo Mac-Clean --profile aggressive --yes` for maximum cleanup.

## Getting Help

| Problem | Solution |
|---------|----------|
| "command not found" | [Installation troubleshooting](installation.md) |
| Permission denied | Make sure you're using `sudo` |
| Not working as expected | [Troubleshooting](troubleshooting.md) |
| Have a suggestion? | [Open an issue](https://github.com/Carme99/MacCleans.sh/issues) |

## What's Next?

| Topic | Guide |
|-------|-------|
| See all cleanup options | [All Categories](all-categories.md) |
| Automate regular cleanup | [Automation](automation.md) |
| Configure for your needs | [Configuration](configuration.md) |
| Automate with cron/launchd | [Automation](automation.md) |

---

<p align="center">

[Back to Documentation](index.md) · [All Categories](all-categories.md) · [Next: Installation](installation.md)

</p>
