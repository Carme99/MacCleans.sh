# Automating macOS Maintenance

[![Automation](https://img.shields.io/badge/Automation-Best%20Practices-blue.svg)]()
[![macOS](https://img.shields.io/badge/macOS-System%20Administration-green.svg)]()

Complete guide to automating MacCleans and other macOS maintenance tasks for a hands-off, healthy Mac.

## Why Automate?

### The Problem with Manual Maintenance

**Humans forget**:
- "I'll clean this up next week" (never happens)
- Months pass, disk fills up
- Emergency cleanup during important work

**Inconsistent**:
- Sometimes deep clean, sometimes light
- Different flags each time
- No pattern or schedule

**Time-consuming**:
- Manual execution every time
- Waiting for completion
- Checking results

### Benefits of Automation

✅ **Consistent**: Same cleanup, same schedule, every time

✅ **Proactive**: Prevents disk full emergencies

✅ **Hands-off**: Set it once, forget about it

✅ **Optimized timing**: Runs when you're not working (3 AM)

✅ **Threshold-based**: Only runs when needed

✅ **Logged**: Track what was cleaned and when

## Automation Methods

### Method Comparison

| Method | Difficulty | Power | Best For |
|--------|-----------|-------|----------|
| **Cron** | Easy | Good | Simple schedules |
| **LaunchD** | Medium | Excellent | macOS-native, flexible |
| **Shell Script** | Easy | Basic | Custom logic |
| **Automator** | Easy | Limited | GUI users |
| **Keyboard Maestro** | Easy | Good | Power users (paid) |

## Cron-Based Automation

### What is Cron?

Unix scheduling tool that runs commands at specified times.

**Syntax**:
```
* * * * * command
│ │ │ │ │
│ │ │ │ └─── Day of week (0-7, Sunday = 0 or 7)
│ │ │ └───── Month (1-12)
│ │ └─────── Day of month (1-31)
│ └───────── Hour (0-23)
└─────────── Minute (0-59)
```

### Basic Cron Setup

**Edit crontab**:
```bash
crontab -e
```

**Add cleanup job**:
```bash
# Daily at 3 AM
0 3 * * * /usr/bin/sudo /usr/local/bin/clean-mac-space --quiet --yes --threshold 80 >> ~/Library/Logs/maccleans.log 2>&1
```

**Save and exit**: `:wq` (in vim)

**Verify**:
```bash
crontab -l
```

### Cron Schedule Examples

```bash
# Every day at 2 AM
0 2 * * * /usr/local/bin/clean-mac-space --quiet --yes --threshold 85

# Every Sunday at 3 AM
0 3 * * 0 /usr/local/bin/clean-mac-space --quiet --yes --profile developer

# First day of month at 4 AM
0 4 1 * * /usr/local/bin/clean-mac-space --quiet --yes --profile aggressive

# Every 6 hours
0 */6 * * * /usr/local/bin/clean-mac-space --quiet --yes --threshold 90

# Weekdays at 1 AM (Monday-Friday)
0 1 * * 1-5 /usr/local/bin/clean-mac-space --quiet --yes --threshold 80

# Every hour (emergency monitoring)
0 * * * * /usr/local/bin/clean-mac-space --quiet --yes --threshold 95
```

### Advanced Cron with Logging

```bash
# Daily cleanup with timestamped logs
0 3 * * * /usr/bin/sudo /usr/local/bin/clean-mac-space --quiet --yes --threshold 80 >> ~/Library/Logs/maccleans-$(date +\%Y\%m\%d).log 2>&1

# Rotate logs monthly
0 0 1 * * find ~/Library/Logs -name "maccleans-*.log" -mtime +30 -delete
```

### Cron Limitations on macOS

⚠️ **macOS Restrictions**:
- May not wake computer from sleep
- Restricted by System Integrity Protection
- Requires Full Disk Access in newer macOS

**Solution**: Use LaunchD instead for better macOS integration

## LaunchD Automation (Recommended)

### What is LaunchD?

macOS native task scheduler with better integration than cron.

**Advantages over Cron**:
- ✅ Can wake Mac from sleep
- ✅ Better system integration
- ✅ More reliable on modern macOS
- ✅ Handles errors gracefully
- ✅ Supports complex schedules

### Basic LaunchD Setup

**1. Create plist file**:

```bash
nano ~/Library/LaunchAgents/com.maccleans.cleanup.plist
```

**2. Add configuration**:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.maccleans.cleanup</string>

    <key>ProgramArguments</key>
    <array>
        <string>/usr/local/bin/clean-mac-space</string>
        <string>--quiet</string>
        <string>--yes</string>
        <string>--threshold</string>
        <string>80</string>
    </array>

    <key>StartCalendarInterval</key>
    <dict>
        <key>Hour</key>
        <integer>3</integer>
        <key>Minute</key>
        <integer>0</integer>
    </dict>

    <key>StandardOutPath</key>
    <string>/tmp/maccleans.log</string>

    <key>StandardErrorPath</key>
    <string>/tmp/maccleans.err</string>

    <key>RunAtLoad</key>
    <false/>
</dict>
</plist>
```

**3. Load the agent**:

```bash
launchctl load ~/Library/LaunchAgents/com.maccleans.cleanup.plist
```

**4. Verify it's loaded**:

```bash
launchctl list | grep maccleans
```

### LaunchD Schedule Examples

**Daily at specific time**:
```xml
<key>StartCalendarInterval</key>
<dict>
    <key>Hour</key>
    <integer>2</integer>
    <key>Minute</key>
    <integer>30</integer>
</dict>
```

**Weekly on Sunday**:
```xml
<key>StartCalendarInterval</key>
<dict>
    <key>Weekday</key>
    <integer>0</integer>
    <key>Hour</key>
    <integer>3</integer>
    <key>Minute</key>
    <integer>0</integer>
</dict>
```

**Multiple times per day**:
```xml
<key>StartCalendarInterval</key>
<array>
    <dict>
        <key>Hour</key>
        <integer>3</integer>
        <key>Minute</key>
        <integer>0</integer>
    </dict>
    <dict>
        <key>Hour</key>
        <integer>15</integer>
        <key>Minute</key>
        <integer>0</integer>
    </dict>
</array>
```

**Every N seconds** (not recommended for cleanup):
```xml
<key>StartInterval</key>
<integer>3600</integer> <!-- Every hour -->
```

### Advanced LaunchD Features

**Run when disk is full** (custom condition):
```xml
<!-- Add a wrapper script that checks disk -->
<key>ProgramArguments</key>
<array>
    <string>/Users/you/Scripts/check-disk-and-clean.sh</string>
</array>
```

**Environment variables**:
```xml
<key>EnvironmentVariables</key>
<dict>
    <key>PATH</key>
    <string>/usr/local/bin:/usr/bin:/bin</string>
</dict>
```

**Only run when Mac is idle**:
```xml
<key>StartInterval</key>
<integer>3600</integer>
<key>LowPriorityIO</key>
<true/>
<key>Nice</key>
<integer>1</integer>
```

## Multi-Tier Automation Strategy

### The Smart Approach

Don't use one cleanup for everything. Use multiple tiers:

**Tier 1: Light Daily Cleanup**
- Profile: Minimal
- Threshold: 85%
- Schedule: Every day at 3 AM
- Purpose: Prevent buildup

**Tier 2: Weekly Deep Clean**
- Profile: Developer (skips XCode)
- Threshold: 75%
- Schedule: Sunday at 2 AM
- Purpose: Regular maintenance

**Tier 3: Monthly Aggressive**
- Profile: Aggressive (includes XCode)
- Threshold: 0% (always run)
- Schedule: 1st of month at 4 AM
- Purpose: Deep clean everything

**Tier 4: Emergency**
- Profile: Aggressive
- Threshold: 95%
- Schedule: Every hour
- Purpose: Disk full prevention

### Implementing Multi-Tier with LaunchD

**Create 4 separate agents**:

```bash
# Daily light
~/Library/LaunchAgents/com.maccleans.daily.plist

# Weekly deep
~/Library/LaunchAgents/com.maccleans.weekly.plist

# Monthly aggressive
~/Library/LaunchAgents/com.maccleans.monthly.plist

# Hourly emergency
~/Library/LaunchAgents/com.maccleans.emergency.plist
```

**Load all**:
```bash
launchctl load ~/Library/LaunchAgents/com.maccleans.*.plist
```

## Custom Wrapper Scripts

### Intelligent Cleanup Script

Create smarter automation with custom logic:

```bash
#!/bin/bash
# ~/Scripts/smart-cleanup.sh

LOG_FILE=~/Library/Logs/smart-cleanup.log
DATE=$(date "+%Y-%m-%d %H:%M:%S")

# Get disk usage percentage
DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')

echo "[$DATE] Disk usage: ${DISK_USAGE}%" >> "$LOG_FILE"

# Tier-based cleanup
if [[ $DISK_USAGE -lt 75 ]]; then
    echo "[$DATE] Disk OK, no cleanup needed" >> "$LOG_FILE"
    exit 0
elif [[ $DISK_USAGE -lt 85 ]]; then
    echo "[$DATE] Running light cleanup" >> "$LOG_FILE"
    sudo /usr/local/bin/clean-mac-space --quiet --yes --profile minimal >> "$LOG_FILE" 2>&1
elif [[ $DISK_USAGE -lt 95 ]]; then
    echo "[$DATE] Running deep cleanup" >> "$LOG_FILE"
    sudo /usr/local/bin/clean-mac-space --quiet --yes --profile developer >> "$LOG_FILE" 2>&1
else
    echo "[$DATE] EMERGENCY cleanup" >> "$LOG_FILE"
    sudo /usr/local/bin/clean-mac-space --quiet --yes --profile aggressive >> "$LOG_FILE" 2>&1

    # Send notification
    osascript -e 'display notification "Emergency cleanup completed" with title "MacCleans" sound name "Glass"'
fi

echo "[$DATE] Cleanup complete" >> "$LOG_FILE"
```

**Make executable**:
```bash
chmod +x ~/Scripts/smart-cleanup.sh
```

**Schedule with LaunchD**:
```xml
<key>ProgramArguments</key>
<array>
    <string>/Users/you/Scripts/smart-cleanup.sh</string>
</array>
```

### Pre-Cleanup Health Check

Check system health before cleaning:

```bash
#!/bin/bash
# ~/Scripts/pre-cleanup-check.sh

# Check if Time Machine backup is running
if tmutil status | grep -q "Running = 1"; then
    echo "Time Machine backup in progress, skipping cleanup"
    exit 0
fi

# Check system load
LOAD=$(uptime | awk '{print $(NF-2)}' | sed 's/,//')
if (( $(echo "$LOAD > 5.0" | bc -l) )); then
    echo "System load too high ($LOAD), skipping cleanup"
    exit 0
fi

# All clear, run cleanup
sudo /usr/local/bin/clean-mac-space --quiet --yes --threshold 80
```

## Notifications and Monitoring

### macOS Notifications

**Send notification after cleanup**:

```bash
#!/bin/bash
# After cleanup in script
FREED=$(grep "Approximate space freed" /tmp/maccleans.log | tail -1 | awk '{print $4$5}')

osascript -e "display notification \"Freed: $FREED\" with title \"MacCleans Cleanup\" sound name \"Glass\""
```

### Slack Integration

**Send results to Slack**:

```bash
#!/bin/bash
SLACK_WEBHOOK="https://hooks.slack.com/services/YOUR/WEBHOOK/URL"

# Run cleanup and capture output
OUTPUT=$(sudo /usr/local/bin/clean-mac-space --quiet --yes 2>&1)
FREED=$(echo "$OUTPUT" | grep "space freed" | awk '{print $4$5}')
DISK=$(df -h / | awk 'NR==2 {print $5}')

# Send to Slack
curl -X POST "$SLACK_WEBHOOK" \
    -H 'Content-Type: application/json' \
    -d "{\"text\":\"🧹 MacCleans Cleanup Complete\n💾 Freed: $FREED\n📊 Disk usage: $DISK\n🖥️ Host: $(hostname)\"}"
```

### Email Reports

**Send email summary**:

```bash
#!/bin/bash
# Requires mail command configured

OUTPUT=$(sudo /usr/local/bin/clean-mac-space --quiet --yes 2>&1)

echo "$OUTPUT" | mail -s "MacCleans Weekly Report - $(hostname)" you@example.com
```

### Dashboard Integration

**Log to JSON for dashboard**:

```bash
#!/bin/bash
LOG_FILE=~/Library/Logs/maccleans-metrics.json

DISK_BEFORE=$(df -h / | awk 'NR==2 {print $5}')
sudo /usr/local/bin/clean-mac-space --quiet --yes
DISK_AFTER=$(df -h / | awk 'NR==2 {print $5}')

cat >> "$LOG_FILE" << EOF
{
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "disk_before": "$DISK_BEFORE",
  "disk_after": "$DISK_AFTER",
  "hostname": "$(hostname)"
}
EOF
```

## Maintenance Calendar Template

### Example Schedule

| Day | Time | Task | Profile | Threshold |
|-----|------|------|---------|-----------|
| Daily | 3:00 AM | Light cleanup | Minimal | 85% |
| Sunday | 2:00 AM | Deep clean | Developer | 75% |
| 1st of month | 4:00 AM | Aggressive clean | Aggressive | 0% |
| Every hour | :00 | Emergency check | Aggressive | 95% |
| Weekly | 5:00 AM | Log rotation | N/A | N/A |
| Monthly | 6:00 AM | Health report | N/A | N/A |

## Troubleshooting Automation

### Cron Not Running

**Check cron daemon**:
```bash
sudo launchctl list | grep cron
```

**Check Full Disk Access**:
System Preferences → Security & Privacy → Full Disk Access → Add Terminal/Cron

**Test manually**:
```bash
/usr/local/bin/clean-mac-space --dry-run
```

### LaunchD Not Running

**Check if loaded**:
```bash
launchctl list | grep maccleans
```

**Check for errors**:
```bash
cat /tmp/maccleans.err
```

**Reload agent**:
```bash
launchctl unload ~/Library/LaunchAgents/com.maccleans.cleanup.plist
launchctl load ~/Library/LaunchAgents/com.maccleans.cleanup.plist
```

**Test manually**:
```bash
launchctl start com.maccleans.cleanup
```

### Script Not Executing

**Check permissions**:
```bash
chmod +x /usr/local/bin/clean-mac-space
chmod +x ~/Scripts/smart-cleanup.sh
```

**Check paths**:
```bash
which clean-mac-space
# Should output: /usr/local/bin/clean-mac-space
```

**Check logs**:
```bash
tail -f /tmp/maccleans.log
```

## Best Practices

### Do's ✅

✅ **Test before automating**
```bash
# Run manually first
sudo ./clean-mac-space.sh --dry-run
```

✅ **Use thresholds**
```bash
# Don't waste time cleaning when space is fine
--threshold 80
```

✅ **Log everything**
```bash
>> ~/Library/Logs/maccleans.log 2>&1
```

✅ **Monitor logs**
```bash
# Check periodically
tail ~/Library/Logs/maccleans.log
```

✅ **Multiple tiers** (light daily, deep weekly)

✅ **Notifications** for important events

✅ **Version control** your scripts
```bash
git init ~/Scripts
```

### Don'ts ❌

❌ **Run too frequently** (hourly cleanup = pointless)

❌ **Skip logging** (how do you know it worked?)

❌ **Ignore errors** (check logs!)

❌ **One-size-fits-all** (use different profiles)

❌ **No thresholds** (wastes CPU when space is fine)

❌ **Forget to test** (broken automation is worse than none)

## Summary

**Recommended Setup**:

1. **LaunchD agent** for daily light cleanup (threshold 85%)
2. **Weekly deep clean** (Sunday, threshold 75%)
3. **Monthly aggressive** (1st of month, profile aggressive)
4. **Custom script** for intelligent tier-based logic
5. **Notifications** for emergency cleanups
6. **Logging** for all runs

**Quick Start**:
```bash
# Copy example LaunchD plist
cp maccleans.conf.example ~/Library/LaunchAgents/com.maccleans.daily.plist

# Edit schedule and paths
nano ~/Library/LaunchAgents/com.maccleans.daily.plist

# Load
launchctl load ~/Library/LaunchAgents/com.maccleans.daily.plist

# Verify
launchctl list | grep maccleans
```

---

**Related Reading**:
- [Advanced Usage Guide](../ADVANCED.md)
- [Understanding macOS Caches](understanding-macos-caches.md)
- [Back to Main README](../README.md)
