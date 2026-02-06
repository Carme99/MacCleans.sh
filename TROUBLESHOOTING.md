# Troubleshooting Guide

[![Help](https://img.shields.io/badge/Need%20Help%3F-We're%20Here-blue.svg)]()
[![Support](https://img.shields.io/badge/Community-Support-green.svg)]()

Comprehensive troubleshooting guide for MacCleans.sh - solutions to common problems and error messages.

## Table of Contents

- [Common Errors](#common-errors)
- [Permission Issues](#permission-issues)
- [Installation Problems](#installation-problems)
- [Execution Issues](#execution-issues)
- [Configuration Problems](#configuration-problems)
- [Unexpected Behavior](#unexpected-behavior)
- [Performance Issues](#performance-issues)
- [Recovery and Rollback](#recovery-and-rollback)
- [Getting Help](#getting-help)

## Common Errors

### Error: "command not found: clean-mac-space"

**Symptom**:
```bash
$ clean-mac-space
zsh: command not found: clean-mac-space
```

**Cause**: Script not in PATH or incorrect installation

**Solutions**:

**Solution 1**: Use full path
```bash
sudo /usr/local/bin/clean-mac-space --dry-run
```

**Solution 2**: Add to PATH
```bash
# Check if /usr/local/bin is in PATH
echo $PATH | grep /usr/local/bin

# If not found, add to shell config
echo 'export PATH="/usr/local/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

**Solution 3**: Reinstall
```bash
# Download again
sudo curl -o /usr/local/bin/clean-mac-space https://raw.githubusercontent.com/Carme99/MacCleans.sh/main/clean-mac-space.sh
sudo chmod +x /usr/local/bin/clean-mac-space
```

---

### Error: "This script requires sudo privileges"

**Symptom**:
```bash
$ ./clean-mac-space.sh
❌ This script requires sudo privileges
```

**Cause**: Running without sudo

**Solution**:
```bash
# Add sudo
sudo ./clean-mac-space.sh --dry-run
```

**Why needed**: Cleaning system caches and Time Machine snapshots requires admin privileges

---

### Error: "Cannot determine actual user"

**Symptom**:
```bash
$ sudo su
# ./clean-mac-space.sh
❌ Cannot determine actual user
```

**Cause**: Running as root directly instead of using sudo from user account

**Solution**:
```bash
# Exit root shell
exit

# Run with sudo from your user account
sudo ./clean-mac-space.sh --dry-run
```

**Why**: Script needs to know your home directory to clean user caches

---

### Error: "Permission denied"

**Symptom**:
```bash
$ ./clean-mac-space.sh
zsh: permission denied: ./clean-mac-space.sh
```

**Cause**: Script not executable

**Solution**:
```bash
# Make executable
chmod +x ./clean-mac-space.sh

# Then run
sudo ./clean-mac-space.sh --dry-run
```

---

### Error: "No such file or directory"

**Symptom**:
```bash
sudo /usr/local/bin/clean-mac-space
zsh: no such file or directory: /usr/local/bin/clean-mac-space
```

**Cause**: Script not installed or wrong path

**Solution**:
```bash
# Find the script
find ~ -name "clean-mac-space.sh" 2>/dev/null

# Or reinstall
curl -o /tmp/clean-mac-space.sh https://raw.githubusercontent.com/Carme99/MacCleans.sh/main/clean-mac-space.sh
sudo mv /tmp/clean-mac-space.sh /usr/local/bin/clean-mac-space
sudo chmod +x /usr/local/bin/clean-mac-space
```

---

### Error: "Invalid option" or "Unknown flag"

**Symptom**:
```bash
$ sudo ./clean-mac-space.sh --skip-foo
Unknown option: --skip-foo
```

**Cause**: Typo in flag name or using unsupported flag

**Solution**:
```bash
# Check available flags
sudo ./clean-mac-space.sh --help

# Common typos:
--skip-xcode     # Correct
--skip-Xcode     # Wrong (capital X)
--skip-npm       # Correct
--skipnpm        # Wrong (missing dash)
```

---

## Permission Issues

### Full Disk Access Required

**Symptom**: Operations fail silently or show permission errors

**Cause**: macOS requires Full Disk Access for some cleanup operations

**Solution**:

1. Open System Preferences → Security & Privacy → Privacy
2. Click "Full Disk Access"
3. Click the lock to make changes
4. Click "+" and add:
   - Terminal (if running from Terminal)
   - iTerm (if using iTerm)
   - /bin/bash (for automated scripts)

**After adding**: Restart Terminal and try again

---

### Time Machine Snapshot Deletion Fails

**Symptom**:
```
Deleting Time Machine snapshots...
Error: Unable to delete snapshots
```

**Cause**: Active Time Machine backup or insufficient permissions

**Solutions**:

**Solution 1**: Wait for backup to finish
```bash
# Check if backup is running
tmutil status | grep Running
```

**Solution 2**: Disable Time Machine temporarily
```bash
# Turn off (in System Preferences)
# Run cleanup
# Turn back on
```

**Solution 3**: Check SIP status
```bash
# System Integrity Protection might prevent deletion
csrutil status
```

---

### Homebrew Cache Cleanup Fails

**Symptom**:
```
Cleaning Homebrew cache...
Error: Permission denied
```

**Cause**: Homebrew permissions issue

**Solution**:
```bash
# Fix Homebrew permissions
sudo chown -R $(whoami) $(brew --prefix)/*

# Try cleanup again
sudo ./clean-mac-space.sh
```

---

## Installation Problems

### Download Fails

**Symptom**:
```bash
$ curl -o clean-mac-space.sh https://...
curl: (6) Could not resolve host
```

**Cause**: Network issue or GitHub down

**Solutions**:

**Solution 1**: Check internet connection
```bash
ping github.com
```

**Solution 2**: Try alternative download
```bash
# Using wget
wget https://raw.githubusercontent.com/Carme99/MacCleans.sh/main/clean-mac-space.sh

# Or clone repository
git clone https://github.com/Carme99/MacCleans.sh.git
```

---

### Can't Create /usr/local/bin

**Symptom**:
```bash
$ sudo mv clean-mac-space.sh /usr/local/bin/
mv: /usr/local/bin/: No such file or directory
```

**Cause**: /usr/local/bin doesn't exist (rare on modern macOS)

**Solution**:
```bash
# Create directory
sudo mkdir -p /usr/local/bin

# Move script
sudo mv clean-mac-space.sh /usr/local/bin/clean-mac-space
sudo chmod +x /usr/local/bin/clean-mac-space
```

---

## Execution Issues

### Script Hangs or Freezes

**Symptom**: Script runs but never completes

**Cause**: Stuck on large directory or waiting for input

**Solutions**:

**Solution 1**: Check what it's doing
```bash
# In another terminal
ps aux | grep clean-mac-space

# Check CPU usage
top | grep clean-mac-space
```

**Solution 2**: Kill and retry with dry-run
```bash
# Kill process
killall clean-mac-space

# Run in dry-run to see where it hangs
sudo ./clean-mac-space.sh --dry-run
```

**Solution 3**: Skip problematic category
```bash
# If it hangs on XCode
sudo ./clean-mac-space.sh --skip-xcode
```

---

### "Disk usage not changed" or Minimal Space Freed

**Symptom**: Script completes but frees <1GB

**Cause**: Caches already small or categories skipped

**Solutions**:

**Solution 1**: Check what was skipped
```bash
# Look in summary report for "Categories Skipped"
```

**Solution 2**: Run without skip flags
```bash
# Full cleanup
sudo ./clean-mac-space.sh --profile aggressive
```

**Solution 3**: Check individual cache sizes first
```bash
# XCode
du -sh ~/Library/Developer/Xcode/DerivedData/

# Docker
docker system df

# Browsers
du -sh ~/Library/Caches/Google/
du -sh ~/Library/Caches/Firefox/

# npm
du -sh ~/.npm/
```

---

### Interactive Mode Not Working

**Symptom**: Interactive mode doesn't respond to keys

**Cause**: Terminal compatibility issue or key bindings

**Solutions**:

**Solution 1**: Use different terminal
```bash
# Try in built-in Terminal.app
# Or try iTerm2
```

**Solution 2**: Use number shortcuts instead of arrows
```bash
# Press 1-13 to toggle categories
# Press 'd' when done
```

**Solution 3**: Fall back to flags
```bash
# Use traditional flags instead
sudo ./clean-mac-space.sh --skip-xcode --skip-docker
```

---

## Configuration Problems

### Config File Not Loading

**Symptom**: Settings in config file ignored

**Cause**: Wrong location, wrong format, or syntax error

**Solutions**:

**Solution 1**: Verify location
```bash
# Check config exists
ls -la ~/.maccleans.conf

# Should be in home directory
```

**Solution 2**: Check format
```bash
# Correct format
SKIP_XCODE=true

# Wrong formats
SKIP_XCODE = true       # Spaces around =
SKIP_XCODE="true"       # Quotes not needed
skip_xcode=true         # Lowercase
```

**Solution 3**: Validate config
```bash
# Source it manually to check for errors
source ~/.maccleans.conf

# If errors, fix them
nano ~/.maccleans.conf
```

**Solution 4**: Check file permissions
```bash
# Make sure you can read it
chmod 644 ~/.maccleans.conf
```

---

### Invalid Configuration Values

**Symptom**:
```
Invalid configuration value: THRESHOLD=abc
```

**Cause**: Non-numeric value for threshold or non-boolean for skip flags

**Solution**:
```bash
# Fix in config file
nano ~/.maccleans.conf

# Correct values:
THRESHOLD=80              # Number 0-100
SKIP_XCODE=true          # true or false (lowercase)
AUTO_YES=false           # true or false (lowercase)
```

---

## Unexpected Behavior

### XCode Warning Appears Every Time

**Symptom**: Always asks about XCode even though you want to skip

**Cause**: Not using skip flag or profile

**Solution**:
```bash
# Use skip flag
sudo ./clean-mac-space.sh --skip-xcode

# Or use profile that skips XCode
sudo ./clean-mac-space.sh --profile developer

# Or set in config
echo "SKIP_XCODE=true" >> ~/.maccleans.conf
```

---

### Cleanup Runs Even Though Disk Not Full

**Symptom**: Cleanup runs when disk is at 60%

**Cause**: No threshold set or threshold too low

**Solution**:
```bash
# Set threshold
sudo ./clean-mac-space.sh --threshold 80

# Or in config
echo "THRESHOLD=80" >> ~/.maccleans.conf
```

---

### Browser Stopped Working After Cleanup

**Symptom**: Browser won't start or crashes

**Cause**: Corrupted cache (rare) or browser was running during cleanup

**Solutions**:

**Solution 1**: Just restart browser
```bash
# Close completely (Command+Q)
# Reopen
```

**Solution 2**: Check browser isn't running during cleanup
```bash
# Close all browsers before running
sudo ./clean-mac-space.sh
```

**Solution 3**: Browser will rebuild cache
```bash
# First launch after cleanup may be slow
# Subsequent launches normal
```

---

### Docker Commands Fail After Cleanup

**Symptom**:
```bash
$ docker ps
Cannot connect to Docker daemon
```

**Cause**: Docker Desktop not running

**Solution**:
```bash
# Start Docker Desktop
open -a Docker

# Wait for it to start (check menu bar)
# Try command again
docker ps
```

---

## Performance Issues

### Cleanup Takes Too Long

**Symptom**: Runs for 30+ minutes

**Cause**: Large XCode Derived Data or Docker cache

**Solutions**:

**Solution 1**: Skip largest categories
```bash
# Skip XCode and Docker (biggest/slowest)
sudo ./clean-mac-space.sh --skip-xcode --skip-docker
```

**Solution 2**: Use minimal profile
```bash
sudo ./clean-mac-space.sh --profile minimal
```

**Solution 3**: Check what's taking time
```bash
# Run in verbose mode and watch
sudo ./clean-mac-space.sh --dry-run
```

---

### System Slow During Cleanup

**Symptom**: Mac becomes unresponsive

**Cause**: High disk I/O from deleting many files

**Solutions**:

**Solution 1**: Run during off-hours
```bash
# Schedule for night
# See: docs/automating-macos-maintenance.md
```

**Solution 2**: Check system load first
```bash
# If load is high, script will warn
# Wait for lower load
```

**Solution 3**: Close other applications
```bash
# Free up CPU/disk for cleanup
```

---

## Recovery and Rollback

### Accidentally Deleted Important Cache

**Symptom**: App won't work after cleanup

**Cause**: App had important data in cache (very rare)

**Solutions**:

**Solution 1**: Let app rebuild
```bash
# Most apps rebuild automatically
# Just relaunch the app
```

**Solution 2**: Restore from Time Machine
```bash
# If you have Time Machine backup
tmutil listbackups

# Restore specific folder
sudo tmutil restore /path/to/backup/Library/Caches/com.example.app
```

**Solution 3**: Reinstall app
```bash
# Nuclear option
# Uninstall and reinstall app
```

---

### Want to Undo Cleanup

**Symptom**: Changed mind after running cleanup

**Cause**: Deleted caches intentionally but now want them back

**Reality**: ❌ Cannot undo - caches are permanently deleted

**Prevention**: Always use `--dry-run` first!

```bash
# Always preview first
sudo ./clean-mac-space.sh --dry-run

# Review output
# Then run for real
sudo ./clean-mac-space.sh
```

---

### XCode Project Won't Build After Cleanup

**Symptom**: Build errors after Derived Data deletion

**Cause**: Need clean build

**Solution**:
```bash
# In XCode:
# Product → Clean Build Folder (Shift+Cmd+K)
# Product → Build (Cmd+B)

# Or from terminal:
xcodebuild clean
xcodebuild build
```

---

## Getting Help

### Before Asking for Help

Gather this information:

```bash
# 1. MacOS version
sw_vers

# 2. Script version
./clean-mac-space.sh --version

# 3. Command you ran
# (copy exact command)

# 4. Error message
# (full output, use --no-color for cleaner logs)

# 5. Disk usage
df -h

# 6. What you expected vs what happened
```

### Check Existing Resources

1. **README**: [README.md](README.md) - Feature overview
2. **FAQ**: [FAQ.md](FAQ.md) - Common questions
3. **Installation**: [INSTALL.md](INSTALL.md) - Setup issues
4. **Advanced**: [ADVANCED.md](ADVANCED.md) - Power user features
5. **Docs**: [docs/](docs/) - In-depth guides

### Search Existing Issues

Before opening a new issue:

```bash
# Search GitHub issues
https://github.com/Carme99/MacCleans.sh/issues?q=your+error
```

### Open a New Issue

If you can't find a solution:

1. Go to [GitHub Issues](https://github.com/Carme99/MacCleans.sh/issues/new)
2. Use this template:

```markdown
**Environment**:
- macOS version: (output of `sw_vers`)
- MacCleans version: (output of `./clean-mac-space.sh --version`)

**Command ran**:
```bash
sudo ./clean-mac-space.sh --your-flags
```

**Expected behavior**:
What you expected to happen

**Actual behavior**:
What actually happened

**Error output**:
```
(paste full error message)
```

**Additional context**:
Anything else relevant
```

### Emergency Support

**Disk completely full and can't run cleanup?**

```bash
# Emergency manual cleanup (safe)

# 1. Empty trash
rm -rf ~/.Trash/*

# 2. Clear browser caches manually
rm -rf ~/Library/Caches/Google/Chrome/*
rm -rf ~/Library/Caches/Firefox/*

# 3. Clear system temp
sudo rm -rf /tmp/*
sudo rm -rf /private/var/tmp/*

# 4. Homebrew cleanup
brew cleanup

# 5. Check disk space
df -h
```

---

## Debug Mode

### Enable Verbose Output

```bash
# Run with bash debugging
bash -x ./clean-mac-space.sh --dry-run 2>&1 | tee debug.log

# Review debug.log for issues
```

### Trace Specific Category

```bash
# Add debug output to script temporarily
# Edit script and add:
set -x  # Before problematic category
# ... cleanup function ...
set +x  # After problematic category
```

---

## Common Misconceptions

### "Cleaning caches will speed up my Mac"
**Reality**: Only if disk was >90% full. Otherwise minimal impact.

### "I should run cleanup daily"
**Reality**: Weekly or monthly is plenty. Caches rebuild quickly.

### "Bigger caches = slower Mac"
**Reality**: Cache size doesn't slow things (unless disk is full).

### "Cleanup broke my app"
**Reality**: Extremely rare. Apps rebuild caches. Check if app was already broken.

### "I lost data"
**Reality**: MacCleans only deletes caches (regenerable). Never touches documents.

---

## Still Having Issues?

**Quick Diagnostics**:

```bash
# Run full diagnostic
echo "=== System Info ==="
sw_vers
echo ""
echo "=== Disk Usage ==="
df -h /
echo ""
echo "=== MacCleans Version ==="
./clean-mac-space.sh --version
echo ""
echo "=== Test Run ==="
sudo ./clean-mac-space.sh --dry-run --no-color
```

**Copy output and [open an issue](https://github.com/Carme99/MacCleans.sh/issues/new)**

---

**Related Resources**:
- [FAQ](FAQ.md) - Frequently asked questions
- [Advanced Guide](ADVANCED.md) - Power user features
- [Contributing](CONTRIBUTING.md) - Help improve MacCleans

**Community**: We're here to help! Don't hesitate to ask questions.
