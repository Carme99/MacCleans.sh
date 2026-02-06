# Frequently Asked Questions (FAQ)

[![Questions](https://img.shields.io/badge/Got%20Questions%3F-We've%20Got%20Answers-blue.svg)]()
[![Community](https://img.shields.io/badge/Community-Friendly-green.svg)]()

Comprehensive answers to common questions about MacCleans.sh.

## Table of Contents

- [General Questions](#general-questions)
- [Safety & Security](#safety--security)
- [Features & Usage](#features--usage)
- [Troubleshooting](#troubleshooting)
- [Performance & Results](#performance--results)
- [Technical Details](#technical-details)
- [Comparison with Other Tools](#comparison-with-other-tools)

## General Questions

### Q: What is MacCleans.sh?

**A:** MacCleans.sh is a free, open-source disk cleanup utility for macOS that safely removes cache files, temporary files, and other regenerable data to free up disk space. It's designed to be safe, transparent, and highly configurable.

### Q: Is this tool safe to use?

**A:** Yes, absolutely. MacCleans only removes cache and temporary files that macOS and applications can regenerate. It never touches:
- User documents
- Photos, videos, or media files
- Application settings or configurations
- System critical files
- Browser history, bookmarks, or passwords
- Email messages or data

### Q: Do I need to pay for this?

**A:** No! MacCleans.sh is completely free and open-source under the MIT license. You can use it, modify it, and distribute it freely.

### Q: How is this different from commercial tools like CleanMyMac?

**A:** See our [Comparison Guide](COMPARISON.md) for detailed comparisons. In short:
- **MacCleans**: Free, open-source, transparent, command-line based
- **Commercial tools**: Paid, closed-source, GUI-based, additional features

MacCleans focuses on being safe, scriptable, and transparent about what it does.

### Q: What macOS versions are supported?

**A:** MacCleans supports macOS 10.15 (Catalina) and later, including:
- macOS 15 Sequoia
- macOS 14 Sonoma
- macOS 13 Ventura
- macOS 12 Monterey
- macOS 11 Big Sur
- macOS 10.15 Catalina

It works on both Intel and Apple Silicon (M1/M2/M3) Macs.

### Q: How often should I run this?

**A:** It depends on your usage:

- **Heavy developers**: Weekly (especially if using XCode, Docker, npm)
- **Regular users**: Monthly
- **Light users**: Quarterly
- **Automated**: Set a threshold (e.g., run when disk > 80% full)

You can also run it manually whenever you need space.

### Q: Will this speed up my Mac?

**A:** Indirectly, yes:
- **More free disk space** = better macOS performance (macOS slows down when disk is >90% full)
- **Less cache scanning** = slightly faster file operations
- **Cleanup isn't a speed optimization tool** - it's a space recovery tool

For actual speed improvements, consider upgrading RAM or using an SSD.

## Safety & Security

### Q: Why does this need sudo/admin privileges?

**A:** Sudo is required to:
1. Delete Time Machine local snapshots (system-level operation)
2. Access system cache directories (owned by root)
3. Clean `/tmp` and `/var/tmp` (system temp directories)
4. Clean Docker system resources (requires elevated privileges)

The script validates it's being run correctly and won't work without proper permissions.

### Q: Can I review what will be deleted before running?

**A:** Yes! Use the `--dry-run` flag:

```bash
sudo ./clean-mac-space.sh --dry-run
```

This shows exactly what would be deleted without actually deleting anything.

### Q: What if I accidentally delete something important?

**A:** This is extremely unlikely because:
1. The script only targets cache/temp directories
2. All paths are hardcoded to safe locations
3. Nothing in user documents is touched

However, if you have Time Machine enabled, you can restore from backup:

```bash
tmutil listbackups
sudo tmutil restore /path/to/deleted/item
```

**Best practice**: Always run `--dry-run` first!

### Q: Is my data sent anywhere?

**A:** No. MacCleans runs 100% locally on your machine. It doesn't:
- Connect to the internet
- Send telemetry or analytics
- Phone home
- Track usage

It's completely offline and private.

### Q: Can I audit the code?

**A:** Yes! The entire script is open-source. You can:
- Read the source code: [clean-mac-space.sh](clean-mac-space.sh)
- Review on GitHub: [Carme99/MacCleans.sh](https://github.com/Carme99/MacCleans.sh)
- Run ShellCheck on it yourself
- Inspect every command before running

Transparency is a core principle of this project.

## Features & Usage

### Q: What's the difference between profiles?

**A:** Profiles are presets for different use cases:

| Profile | Best For | What It Skips | Recovery Potential |
|---------|----------|---------------|-------------------|
| **Conservative** | Regular users, non-developers | XCode, npm, pip, browsers, Docker, Simulator | 5-20GB |
| **Developer** | Active developers | Only XCode (avoid rebuild times) | 10-40GB |
| **Aggressive** | Maximum space recovery | Nothing - cleans everything | 15-100GB+ |
| **Minimal** | Quick, safe cleanup | All application caches | 2-10GB |

Choose based on your needs:

```bash
# Safe for everyone
sudo ./clean-mac-space.sh --profile conservative

# Developers who don't use XCode
sudo ./clean-mac-space.sh --profile developer

# Need maximum space NOW
sudo ./clean-mac-space.sh --profile aggressive

# Quick daily cleanup
sudo ./clean-mac-space.sh --profile minimal
```

### Q: How do I use interactive mode?

**A:** Run with `--interactive` or `-i`:

```bash
sudo ./clean-mac-space.sh --interactive
```

You'll see a menu where you can:
- **Navigate**: ↑↓ arrow keys
- **Toggle categories**: Space or Enter
- **Quick select all**: Press 'a'
- **Deselect all**: Press 'n'
- **Number shortcuts**: Press 1-13 to toggle specific items
- **Done selecting**: Press 'd'
- **Cancel**: Press 'q'

Selected items show **[✓]**, unselected show **[ ]**.

### Q: Can I combine profiles with skip flags?

**A:** Yes! Command-line flags override profile settings:

```bash
# Developer profile but also skip npm
sudo ./clean-mac-space.sh --profile developer --skip-npm

# Aggressive profile but skip Docker
sudo ./clean-mac-space.sh --profile aggressive --skip-docker
```

### Q: How do configuration files work?

**A:** Create `~/.maccleans.conf` with your preferred settings:

```bash
# My preferred settings
SKIP_XCODE=true
SKIP_DOCKER=true
AUTO_YES=true
THRESHOLD=85
```

The script will load this automatically. Command-line flags override config settings.

Config file locations (checked in order):
1. `~/.maccleans.conf`
2. `~/.config/maccleans/config`
3. `${XDG_CONFIG_HOME}/maccleans/config`

### Q: What does the threshold flag do?

**A:** `--threshold N` only runs cleanup if disk usage is above N%:

```bash
# Only run if disk is >80% full
sudo ./clean-mac-space.sh --threshold 80
```

Perfect for automated cron jobs - it won't waste time cleaning when you have plenty of space.

### Q: Can I automate this to run regularly?

**A:** Yes! See [INSTALL.md](INSTALL.md) for cron and launchd examples. Quick example:

```bash
# Edit crontab
crontab -e

# Add line to run daily at 2 AM if disk >75% full
0 2 * * * /usr/bin/sudo /usr/local/bin/clean-mac-space --quiet --yes --threshold 75
```

## Troubleshooting

### Q: I get "command not found" after installation

**A:** Your PATH might not include `/usr/local/bin`. Fix:

```bash
# Check PATH
echo $PATH | grep /usr/local/bin

# If not found, add to shell config
echo 'export PATH="/usr/local/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

Or use the full path:

```bash
sudo /usr/local/bin/clean-mac-space --dry-run
```

### Q: I get "permission denied" errors

**A:** Make sure you're using `sudo`:

```bash
# Wrong (no sudo)
./clean-mac-space.sh

# Correct (with sudo)
sudo ./clean-mac-space.sh
```

Also verify the script is executable:

```bash
chmod +x clean-mac-space.sh
```

### Q: The script says "Cannot determine actual user"

**A:** Don't run as root directly. Use sudo from your regular user account:

```bash
# Wrong
sudo su
./clean-mac-space.sh

# Correct
sudo ./clean-mac-space.sh
```

### Q: XCode warning appears but I don't use XCode

**A:** Skip XCode cleanup:

```bash
sudo ./clean-mac-space.sh --skip-xcode

# Or use developer profile (skips XCode by default)
sudo ./clean-mac-space.sh --profile developer
```

### Q: My configuration file isn't being loaded

**A:** Check:

1. **File location** - must be exactly `~/.maccleans.conf` (check spelling)
2. **File format** - must be `KEY=value` (no spaces around `=`)
3. **File permissions** - make sure you can read it: `cat ~/.maccleans.conf`

```bash
# Correct format
SKIP_XCODE=true

# Wrong (spaces around =)
SKIP_XCODE = true

# Wrong (quotes around value - not needed for booleans)
SKIP_XCODE="true"
```

### Q: Cleanup didn't free as much space as expected

**A:** Common reasons:

1. **Categories were skipped** - Check summary report for "Categories Skipped"
2. **Caches were small** - Not everyone has large caches
3. **Recent cleanup** - If you ran it recently, there's less to clean
4. **Dry-run mode** - You need to run without `--dry-run` to actually delete

The biggest space recovery comes from:
- XCode Derived Data (5-50GB) - if you develop with XCode
- Docker (1-20GB) - if you use Docker
- Browsers (1-5GB) - if you browse a lot
- npm/yarn (500MB-5GB) - if you do Node.js development

### Q: Browser stopped working after cleanup

**A:** This shouldn't happen as we only clean caches, but if it does:

1. **Just restart the browser** - it will rebuild caches
2. **Check if browser is actually broken** or just slower on first launch
3. **Cache rebuilding is normal** - first launch after cleanup may be slower
4. **Extensions reload** - may need to re-authenticate to some extensions

Your history, bookmarks, and passwords are **never touched**.

### Q: System warnings about high load or active backups

**A:** These are informational warnings:

**High system load**: The script notices your CPU is busy. You can:
- Wait for load to decrease
- Proceed anyway (usually safe)
- Run cleanup later

**Active Time Machine backup**: The script detects a backup in progress. You can:
- Wait for backup to complete (recommended)
- Proceed anyway (script won't delete snapshots during active backup)

## Performance & Results

### Q: How much space can I recover?

**A:** Highly variable based on usage:

**Typical recovery by user type:**

| User Type | Typical Recovery | Largest Categories |
|-----------|------------------|-------------------|
| Regular user (no development) | 2-10GB | Browsers, Trash, System caches |
| Web developer (npm/yarn) | 5-20GB | npm, browsers, Trash |
| iOS developer (XCode) | 20-80GB | XCode, Simulators, browsers |
| Full-stack + Docker | 30-100GB+ | XCode, Docker, npm, pip |

**Recovery by category (if present):**
- XCode Derived Data: 5-50GB
- Docker: 1-20GB
- iOS Simulator: 1-10GB
- Browsers: 1-5GB
- npm/yarn: 500MB-5GB
- pip: 100MB-2GB
- Homebrew: 500MB-2GB
- Mail cache: 100MB-1GB
- Trash: Variable
- Other: 500MB-2GB

**First-time users typically see 10-40GB recovery** if they're developers.

### Q: How long does cleanup take?

**A:** Depends on how much needs to be cleaned:

- **Dry-run**: 5-30 seconds (just scanning)
- **Light cleanup** (few GB): 30 seconds - 2 minutes
- **Heavy cleanup** (50GB+): 3-10 minutes
- **XCode cleanup alone**: 2-5 minutes (if large)

Deletion is usually fast - most time is spent calculating sizes.

### Q: Will this damage my SSD?

**A:** No. Deleting files is a normal operation and doesn't harm SSDs. Modern SSDs have:
- Wear leveling
- Over-provisioning
- Lifespans measured in petabytes written

Cleaning caches a few times per month has negligible impact compared to normal daily usage.

### Q: What happens to deleted data?

**A:** Deleted files are **permanently removed**, not moved to Trash (except when emptying Trash itself).

**This is why dry-run is important!** Once deleted, files can only be recovered from backups.

### Q: Can I see what specific files were deleted?

**A:** The script shows categories and total space freed. For file-level details, run in dry-run mode:

```bash
sudo ./clean-mac-space.sh --dry-run --no-color > cleanup-preview.txt
```

This saves exactly what would be deleted to a file for review.

## Technical Details

### Q: What shell is this written in?

**A:** Bash (#!/bin/bash). It uses:
- Bash 3.2+ (comes with macOS)
- Standard Unix utilities (awk, sed, du, df, find, rm)
- No external dependencies required

### Q: Is this ShellCheck compliant?

**A:** Yes! The script passes ShellCheck with zero warnings/errors. We follow bash best practices:
- `set -euo pipefail` for strict error handling
- Quoted variables to prevent word splitting
- Proper error suppression with `|| true`
- Local variables in functions
- Validation before destructive operations

### Q: Can I run this on Linux?

**A:** No, it's macOS-specific. The script cleans macOS-specific paths like:
- `~/Library/Caches`
- Time Machine snapshots
- macOS application caches

Many concepts could be adapted for Linux, but you'd need a different script.

### Q: Does this work on Hackintosh?

**A:** Yes, as long as it's running real macOS. The script doesn't check for genuine Apple hardware.

### Q: What's the difference between .DS_Store cleanup and other categories?

**A:** `.DS_Store` files are unique:
- **What they are**: Hidden files created by macOS Finder
- **What they store**: Folder view settings, icon positions
- **Why clean them**: They accumulate over time, clutter backups, appear in git repos
- **Are they safe to delete**: Yes - Finder recreates them automatically
- **Scope**: We only clean from your home directory (safe)

Most users have 100MB-2GB of `.DS_Store` files scattered across their system.

### Q: Why skip XCode by default in some profiles?

**A:** XCode Derived Data contains build artifacts. Deleting it means:
- **Pro**: Frees 5-50GB of space
- **Con**: Next build takes 5-30 minutes longer (full rebuild)

For active XCode developers, rebuild time > disk space savings. That's why:
- **Conservative profile**: Skips XCode
- **Developer profile**: Skips XCode
- **Aggressive profile**: Includes XCode
- **Minimal profile**: Skips XCode

If you don't use XCode or it's been months since you used it, you can safely include it.

### Q: What's cleaned vs what's skipped by default?

**A:** By default (no flags), **everything is cleaned**. The script uses an **opt-out approach**:

**Cleaned by default (unless --skip-X):**
- Time Machine snapshots
- Homebrew cache
- Application caches (Spotify, Claude)
- System caches
- Logs
- Temp files
- Browsers
- XCode
- npm/yarn
- pip
- Docker
- iOS Simulator
- Mail cache
- Trash
- .DS_Store files

**Use --skip-X flags or profiles to exclude categories you want to keep.**

### Q: How does disk space calculation work?

**A:** The script:

1. **Before cleanup**: Runs `du -sk` on target directory to get size in kilobytes
2. **Performs cleanup**: Deletes files
3. **Calculates freed**: `freed = before_size - after_size` (after_size is 0 for full deletion)
4. **Formats output**: Converts KB to human-readable (MB/GB)

**Note**: Calculations are approximate because:
- Some files may be in use
- Permissions may prevent size calculation
- Sparse files and hard links complicate things

Actual disk space freed may vary slightly from reported amounts.

## Comparison with Other Tools

### Q: Should I use this or CleanMyMac?

**A:** See our [Comparison Guide](COMPARISON.md) for full details. Quick comparison:

**Use MacCleans if:**
- You want free, open-source software
- You prefer command-line tools
- You want full transparency (audit the code)
- You need automation/scripting
- You're comfortable with terminal

**Use CleanMyMac if:**
- You prefer GUI applications
- You want one-click simplicity
- You need advanced features (malware removal, app uninstaller)
- You don't mind paying
- You want official support

**You can use both!** They're complementary. Many users run MacCleans for regular automated cleanup and CleanMyMac for occasional deep cleaning with GUI.

### Q: How does this compare to using Disk Utility?

**A:** macOS Disk Utility doesn't clean caches. It:
- Formats drives
- Repairs disk permissions
- Shows disk usage

MacCleans actually **frees space** by deleting caches. They serve different purposes.

### Q: What about DaisyDisk / OmniDiskSweeper?

**A:** Those are **disk space analyzers**, not cleaners. They:
- Show visual maps of disk usage
- Help you find large files manually
- Don't automatically clean anything

MacCleans **automatically cleans known safe-to-delete locations**.

**Best combo**: Use DaisyDisk to find large files → Use MacCleans to clean caches automatically.

### Q: Can I use this with CleanMyMac / Onyx / etc.?

**A:** Yes! MacCleans plays nicely with other tools. Just:
1. Don't run them simultaneously
2. Run MacCleans after other tools (it's most conservative)
3. Check what each tool cleans to avoid redundancy

## Still Have Questions?

- **Check the docs**: [README](README.md) | [INSTALL](INSTALL.md) | [ADVANCED](ADVANCED.md)
- **Open an issue**: [GitHub Issues](https://github.com/Carme99/MacCleans.sh/issues)
- **Contribute**: [CONTRIBUTING](CONTRIBUTING.md)
- **Report bugs**: Include macOS version, script version, and full error output

---

**Didn't find your answer?** [Open an issue](https://github.com/Carme99/MacCleans.sh/issues/new) and we'll add it to this FAQ!
