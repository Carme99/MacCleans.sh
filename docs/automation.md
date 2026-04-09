# Automation

Run MacCleans automatically using cron or launchd.

## Automated Cleanup

### Why Automate?

- Keeps disk space under control without manual effort
- Runs during off-hours (overnight, weekends)
- No need to remember to run it manually
- Can trigger automatically when disk space is low

### Methods

| Method | Best For | Requires User | persists Across Reboots |
|--------|----------|---------------|------------------------|
| cron | Simple scheduling | No | Yes |
| launchd | Advanced triggers | No | Yes |
| polka | Threshold-based | No | Yes |

## Cron

### Basic Syntax

Edit your crontab:

```bash
crontab -e
```

### Examples

Run every Sunday at 3 AM:

```
0 3 * * 0 sudo Mac-Clean --quiet --yes --profile conservative
```

Run every day at 2 AM:

```
0 2 * * * sudo Mac-Clean --quiet --yes --threshold 80
```

Run every Monday and Thursday at midnight:

```
0 0 * * 1,4 sudo Mac-Clean --quiet --yes --profile conservative
```

Run first day of each month at 1 AM:

```
0 1 1 * * sudo Mac-Clean --quiet --yes --profile aggressive
```

### Cron Format

```
┌───────────── minute (0-59)
│ ┌───────────── hour (0-23)
│ │ ┌───────────── day of month (1-31)
│ │ │ ┌───────────── month (1-12)
│ │ │ │ ┌───────────── day of week (0-7, 0 and 7 are Sunday)
│ │ │ │ │
* * * * * command
```

## launchd

launchd is macOS's native service management system. It persists across reboots and handles system sleep/wake.

### Creating a Launch Daemon

Create a plist file:

```bash
sudo nano /Library/LaunchDaemons/com.maccleans.plist
```

Example - run daily at 3 AM:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.maccleans.plist</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/local/bin/Mac-Clean</string>
        <string>--quiet</string>
        <string>--yes</string>
        <string>--profile</string>
        <string>conservative</string>
    </array>
    <key>StartCalendarInterval</key>
    <dict>
        <key>Hour</key>
        <integer>3</integer>
        <key>Minute</key>
        <integer>0</integer>
    </dict>
</dict>
</plist>
```

Load the daemon:

```bash
sudo launchctl load /Library/LaunchDaemons/com.maccleans.plist
```

### Threshold-Based with launchd

Run automatically when disk usage exceeds 85%:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.maccleans.plist</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/local/bin/Mac-Clean</string>
        <string>--quiet</string>
        <string>--yes</string>
        <string>--threshold</string>
        <string>85</string>
        <string>--profile</string>
        <string>conservative</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>StartInterval</key>
    <integer>3600</integer>
</dict>
</plist>
```

`StartInterval` runs every 3600 seconds (1 hour). The script will only clean when disk usage exceeds your threshold.

## polka

polka is a simple macOS menu bar app that monitors disk space and runs MacCleans automatically.

```
brew install --cask polka
```

Features:
- Menu bar app showing disk usage
- Runs MacCleans when disk usage exceeds your threshold
- Notification when cleanup completes
- Configurable schedule

## Threshold Mode

The `--threshold` flag triggers cleanup only when your disk is getting full:

```bash
# Only clean when disk is above 85%
sudo Mac-Clean --quiet --yes --threshold 85
```

This is useful for cron jobs that run frequently but only act when needed.

### Combining Threshold with Profiles

```bash
# Run every hour, clean if above 85%, be conservative
sudo Mac-Clean --quiet --threshold 85 --profile conservative

# Run every day, clean if above 80%, be aggressive
sudo Mac-Clean --quiet --threshold 80 --profile aggressive
```

## Notifications

Enable desktop notifications:

```bash
# macOS notification
osascript -e 'display notification "MacCleans complete" with title "MacCleans"'

# Add to crontab
0 3 * * 0 sudo Mac-Clean --quiet --yes --profile conservative && osascript -e 'display notification "MacCleans complete" with title "MacCleans"'
```

## Log Output

Save output to a log file:

```bash
# Append to log
sudo Mac-Clean --quiet --yes >> ~/.maccleans.log 2>&1

# Log with timestamp
sudo Mac-Clean --quiet --yes | while IFS= read -r line; do echo "$(date '+%Y-%m-%d %H:%M:%S') $line"; done >> ~/.maccleans.log
```

## Useful Aliases

Add to your `~/.zshrc` or `~/.bashrc`:

```bash
# Quick cleanup
alias cleanc='sudo Mac-Clean --yes'

# Preview first
alias cleanp='sudo Mac-Clean --dry-run'

# Conservative cleanup
alias cleancs='sudo Mac-Clean --profile conservative --yes'

# Developer cleanup
alias cleandev='sudo Mac-Clean --profile developer --yes'
```

Then reload:

```bash
source ~/.zshrc
```

## Troubleshooting Automation

### Script Not Running

Check if the job is scheduled:

```bash
crontab -l              # List cron jobs
sudo launchctl list      # List launchd jobs
```

### Permission Issues

launchd runs as root, but cron jobs may need full paths:

```bash
# Use full path in crontab
0 3 * * 0 /usr/local/bin/Mac-Clean --quiet --yes --profile conservative
```

### Checking Logs

```bash
# View recent logs
tail -f ~/.maccleans.log

# View system logs
log show --predicate 'process == "Mac-Clean"' --last 24h
```

## Security Considerations

- Scripts running via cron/launchd have root privileges
- Use `--profile conservative` for automated runs (safer defaults)
- Avoid `--force` in automated scripts
- Review what you clean before automating
- Keep logs to track what was cleaned

---

<p align="center">

[Back to Documentation](index.md) · [Configuration](configuration.md) · [Command Reference](command-reference.md)

</p>
