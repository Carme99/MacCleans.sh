# Quick Start Guide

> Get up and running with MacCleans in under 30 seconds.

---

## TL;DR

```bash
# One-line install
curl -sSL https://raw.githubusercontent.com/Carme99/MacCleans.sh/main/clean-mac-space.sh -o ~/Scripts/clean-mac-space.sh && chmod +x ~/Scripts/clean-mac-space.sh

# Preview what would be cleaned
sudo ~/Scripts/clean-mac-space.sh --dry-run
```

---

## Step-by-Step

### Step 1: Download the Script

```bash
# Create Scripts directory (if it doesn't exist)
mkdir -p ~/Scripts

# Download the latest version
curl -sSL https://raw.githubusercontent.com/Carme99/MacCleans.sh/main/clean-mac-space.sh -o ~/Scripts/clean-mac-space.sh

# Make it executable
chmod +x ~/Scripts/clean-mac-space.sh
```

### Step 2: Preview (Recommended First Run)

```bash
# Run with --dry-run to see what would be cleaned
sudo ~/Scripts/clean-mac-space.sh --dry-run
```

This shows you exactly what would be deleted without actually deleting anything.

### Step 3: Clean!

```bash
# Option A: Interactive mode (choose what to clean)
sudo ~/Scripts/clean-mac-space.sh --interactive

# Option B: Non-interactive (clean everything)
sudo ~/Scripts/clean-mac-space.sh --yes

# Option C: With confirmation
sudo ~/Scripts/clean-mac-space.sh
```

---

## Common Commands

| What you want | Command |
|---------------|---------|
| See what would be deleted | `sudo ~/Scripts/clean-mac-space.sh --dry-run` |
| Clean everything (no prompts) | `sudo ~/Scripts/clean-mac-space.sh --yes` |
| Choose what to clean | `sudo ~/Scripts/clean-mac-space.sh --interactive` |
| Use a preset profile | `sudo ~/Scripts/clean-mac-space.sh --profile developer` |
| Skip specific category | `sudo ~/Scripts/clean-mac-space.sh --skip-xcode` |

---

## Next Steps

### Set Up Automation (Optional)

Run automatically every day at 2 AM:

```bash
# Edit crontab
crontab -e

# Add this line:
0 2 * * * /Users/jacklee/Scripts/clean-mac-space.sh --yes --threshold 80 --quiet
```

### Create a Configuration File (Optional)

```bash
# Create config directory
mkdir -p ~/.config/maccleans

# Copy example config
cp maccleans.conf.example ~/.config/maccleans/config

# Edit to your preferences
nano ~/.config/maccleans/config
```

---

## What's Safe to Delete?

MacCleans only removes:
- ✅ Cache files (browser, app caches)
- ✅ Temporary files
- ✅ Build artifacts (XCode Derived Data)
- ✅ Log files
- ✅ Downloaded iCloud files (re-downloads on demand)
- ✅ Old backups

MacCleans NEVER touches:
- ❌ Your documents
- ❌ Your photos (they stay in iCloud)
- ❌ Your music, movies, downloads
- ❌ Application settings
- ❌ Browser bookmarks and history

---

## Troubleshooting

### "Permission denied"
Use `sudo`:
```bash
sudo ~/Scripts/clean-mac-space.sh --dry-run
```

### "Command not found"
Make the script executable:
```bash
chmod +x ~/Scripts/clean-mac-space.sh
```

### "No space freed"
Some categories may not have data to clean. Try `--dry-run` to see what's available.

---

## Learn More

- [Full Documentation](README.md)
- [Installation Guide](INSTALL.md)
- [Advanced Usage](ADVANCED.md)
- [FAQ](FAQ.md)
- [Troubleshooting](TROUBLESHOOTING.md)

---

**Need help?** Open an issue at https://github.com/Carme99/MacCleans.sh/issues
