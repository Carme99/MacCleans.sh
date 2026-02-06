# Advanced Usage Guide

[![macOS](https://img.shields.io/badge/macOS-10.15+-blue.svg)](https://www.apple.com/macos/)
[![Advanced](https://img.shields.io/badge/Level-Advanced-red.svg)]()
[![Automation](https://img.shields.io/badge/Use%20Case-Automation-orange.svg)]()

This guide covers advanced usage scenarios, custom configurations, CI/CD integration, and power-user workflows for MacCleans.sh.

## Table of Contents

- [Advanced Configuration](#advanced-configuration)
- [Multiple Cleanup Schedules](#multiple-cleanup-schedules)
- [CI/CD Integration](#cicd-integration)
- [Monitoring & Alerting](#monitoring--alerting)
- [Custom Cleanup Categories](#custom-cleanup-categories)
- [Performance Optimization](#performance-optimization)
- [Enterprise Deployment](#enterprise-deployment)
- [Advanced Troubleshooting](#advanced-troubleshooting)

## Advanced Configuration

### Multi-Profile Configuration

Create multiple configuration files for different use cases:

```bash
# Daily light cleanup
~/.maccleans.daily.conf
QUIET=true
AUTO_YES=true
THRESHOLD=85
SKIP_XCODE=true
SKIP_DOCKER=true
SKIP_SIMULATOR=true
SKIP_BROWSERS=true

# Weekly deep clean
~/.maccleans.weekly.conf
QUIET=true
AUTO_YES=true
THRESHOLD=70
SKIP_XCODE=true  # Still skip to avoid rebuild times

# Emergency cleanup (disk nearly full)
~/.maccleans.emergency.conf
QUIET=false
AUTO_YES=true
THRESHOLD=0  # Always run
# Don't skip anything - clean everything
```

Use them with environment variables:

```bash
# Daily run
MACCLEANS_CONFIG=~/.maccleans.daily.conf sudo -E clean-mac-space

# Weekly run
MACCLEANS_CONFIG=~/.maccleans.weekly.conf sudo -E clean-mac-space

# Emergency
MACCLEANS_CONFIG=~/.maccleans.emergency.conf sudo -E clean-mac-space
```

### Environment-Specific Configuration

```bash
# Development machine
cat > ~/.maccleans.dev.conf << 'EOF'
# Skip development caches to avoid rebuild times
SKIP_XCODE=true
SKIP_NPM=true
SKIP_PIP=true
SKIP_DOCKER=true
SKIP_SIMULATOR=true

# Clean everything else
SKIP_BROWSERS=false
SKIP_TRASH=false
SKIP_DSSTORE=false

# Automated settings
AUTO_YES=true
THRESHOLD=80
EOF

# CI/CD build server
cat > ~/.maccleans.ci.conf << 'EOF'
# Clean everything aggressively
SKIP_XCODE=false
SKIP_NPM=false
SKIP_PIP=false
SKIP_DOCKER=false
SKIP_BROWSERS=false

# No threshold - always clean
THRESHOLD=0
AUTO_YES=true
QUIET=true
EOF

# Production server (conservative)
cat > ~/.maccleans.prod.conf << 'EOF'
# Only clean safe system caches
SKIP_XCODE=true
SKIP_NPM=true
SKIP_PIP=true
SKIP_DOCKER=true
SKIP_BROWSERS=true
SKIP_SIMULATOR=true

# Manual confirmation required
AUTO_YES=false
QUIET=false
THRESHOLD=90
EOF
```

## Multiple Cleanup Schedules

### Advanced Cron Setup

Create sophisticated cleanup schedules with different profiles:

```bash
# Edit crontab
crontab -e

# Add multiple schedules
# Daily at 3 AM - light cleanup if disk > 85%
0 3 * * * MACCLEANS_CONFIG=~/.maccleans.daily.conf /usr/bin/sudo -E /usr/local/bin/clean-mac-space >> ~/Library/Logs/maccleans-daily.log 2>&1

# Weekly on Sunday at 2 AM - deeper cleanup if disk > 70%
0 2 * * 0 MACCLEANS_CONFIG=~/.maccleans.weekly.conf /usr/bin/sudo -E /usr/local/bin/clean-mac-space >> ~/Library/Logs/maccleans-weekly.log 2>&1

# Monthly on 1st at 4 AM - full cleanup
0 4 1 * * /usr/bin/sudo /usr/local/bin/clean-mac-space --yes --quiet --profile aggressive >> ~/Library/Logs/maccleans-monthly.log 2>&1

# Hourly check for emergency situation (disk > 95%)
0 * * * * DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//'); if [ $DISK_USAGE -gt 95 ]; then /usr/bin/sudo /usr/local/bin/clean-mac-space --yes --quiet --profile aggressive >> ~/Library/Logs/maccleans-emergency.log 2>&1; fi
```

### LaunchD with Multiple Agents

Create separate launch agents for different schedules:

**Daily Cleanup** (`~/Library/LaunchAgents/com.maccleans.daily.plist`):

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.maccleans.daily</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/local/bin/clean-mac-space</string>
        <string>--quiet</string>
        <string>--yes</string>
        <string>--threshold</string>
        <string>85</string>
        <string>--profile</string>
        <string>minimal</string>
    </array>
    <key>StartCalendarInterval</key>
    <dict>
        <key>Hour</key>
        <integer>3</integer>
        <key>Minute</key>
        <integer>0</integer>
    </dict>
    <key>StandardOutPath</key>
    <string>/tmp/maccleans-daily.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/maccleans-daily.err</string>
</dict>
</plist>
```

**Weekly Deep Clean** (`~/Library/LaunchAgents/com.maccleans.weekly.plist`):

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.maccleans.weekly</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/local/bin/clean-mac-space</string>
        <string>--quiet</string>
        <string>--yes</string>
        <string>--threshold</string>
        <string>70</string>
        <string>--profile</string>
        <string>developer</string>
    </array>
    <key>StartCalendarInterval</key>
    <dict>
        <key>Weekday</key>
        <integer>0</integer>
        <key>Hour</key>
        <integer>2</integer>
        <key>Minute</key>
        <integer>0</integer>
    </dict>
    <key>StandardOutPath</key>
    <string>/tmp/maccleans-weekly.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/maccleans-weekly.err</string>
</dict>
</plist>
```

Load both agents:

```bash
launchctl load ~/Library/LaunchAgents/com.maccleans.daily.plist
launchctl load ~/Library/LaunchAgents/com.maccleans.weekly.plist
```

## CI/CD Integration

### GitHub Actions

Clean up GitHub Actions runners to prevent disk space issues:

```yaml
# .github/workflows/cleanup.yml
name: Cleanup macOS Runner

on:
  schedule:
    - cron: '0 2 * * *'  # Daily at 2 AM
  workflow_dispatch:  # Manual trigger

jobs:
  cleanup:
    runs-on: macos-latest
    steps:
      - name: Download MacCleans
        run: |
          curl -o /tmp/clean-mac-space.sh https://raw.githubusercontent.com/Carme99/MacCleans.sh/main/clean-mac-space.sh
          chmod +x /tmp/clean-mac-space.sh

      - name: Disk Space Before
        run: df -h

      - name: Run Cleanup
        run: |
          sudo /tmp/clean-mac-space.sh \
            --yes \
            --quiet \
            --skip-xcode \
            --threshold 70

      - name: Disk Space After
        run: df -h

      - name: Upload Logs
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: cleanup-logs
          path: /tmp/maccleans*.log
```

### GitLab CI

```yaml
# .gitlab-ci.yml
cleanup:macos:
  stage: maintenance
  tags:
    - macos
  only:
    - schedules
  script:
    - curl -o /tmp/clean-mac-space.sh https://raw.githubusercontent.com/Carme99/MacCleans.sh/main/clean-mac-space.sh
    - chmod +x /tmp/clean-mac-space.sh
    - df -h
    - sudo /tmp/clean-mac-space.sh --yes --quiet --profile developer
    - df -h
  artifacts:
    when: always
    paths:
      - /tmp/maccleans*.log
```

### Jenkins Pipeline

```groovy
// Jenkinsfile
pipeline {
    agent {
        label 'macos'
    }

    triggers {
        cron('0 2 * * *')  // Daily at 2 AM
    }

    stages {
        stage('Disk Check') {
            steps {
                sh 'df -h'
            }
        }

        stage('Cleanup') {
            steps {
                sh '''
                    curl -o /tmp/clean-mac-space.sh https://raw.githubusercontent.com/Carme99/MacCleans.sh/main/clean-mac-space.sh
                    chmod +x /tmp/clean-mac-space.sh
                    sudo /tmp/clean-mac-space.sh --yes --quiet --threshold 75
                '''
            }
        }

        stage('Verify') {
            steps {
                sh 'df -h'
            }
        }
    }

    post {
        always {
            archiveArtifacts artifacts: '/tmp/maccleans*.log', allowEmptyArchive: true
        }
    }
}
```

### CircleCI

```yaml
# .circleci/config.yml
version: 2.1

workflows:
  maintenance:
    triggers:
      - schedule:
          cron: "0 2 * * *"
          filters:
            branches:
              only:
                - main
    jobs:
      - cleanup

jobs:
  cleanup:
    macos:
      xcode: "14.0.0"
    steps:
      - run:
          name: Check Disk Space
          command: df -h

      - run:
          name: Download and Run Cleanup
          command: |
            curl -o /tmp/clean-mac-space.sh https://raw.githubusercontent.com/Carme99/MacCleans.sh/main/clean-mac-space.sh
            chmod +x /tmp/clean-mac-space.sh
            sudo /tmp/clean-mac-space.sh --yes --quiet --profile developer

      - run:
          name: Verify Cleanup
          command: df -h

      - store_artifacts:
          path: /tmp/maccleans*.log
```

## Monitoring & Alerting

### Disk Space Monitoring Script

Create a monitoring script that alerts when disk is getting full:

```bash
#!/bin/bash
# ~/Scripts/disk-monitor.sh

THRESHOLD=80
SLACK_WEBHOOK="https://hooks.slack.com/services/YOUR/WEBHOOK/URL"

# Get current disk usage
USAGE=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')

if [[ $USAGE -gt $THRESHOLD ]]; then
    # Run cleanup
    CLEANUP_OUTPUT=$(sudo /usr/local/bin/clean-mac-space --yes --quiet --threshold $THRESHOLD 2>&1)

    # Get new disk usage
    NEW_USAGE=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')

    # Send Slack notification
    curl -X POST "$SLACK_WEBHOOK" \
        -H 'Content-Type: application/json' \
        -d "{\"text\":\"🧹 MacCleans Auto-Cleanup\\n📊 Disk usage: ${USAGE}% → ${NEW_USAGE}%\\n💾 Host: $(hostname)\"}"
fi
```

Schedule with cron:

```bash
# Check every hour
0 * * * * ~/Scripts/disk-monitor.sh
```

### Integration with Prometheus

Export disk metrics for Prometheus monitoring:

```bash
#!/bin/bash
# ~/Scripts/disk-metrics.sh

# Create metrics file for node_exporter
METRICS_FILE="/var/tmp/disk_cleanup.prom"

cat > "$METRICS_FILE" << EOF
# HELP disk_cleanup_last_run_timestamp Last time disk cleanup ran
# TYPE disk_cleanup_last_run_timestamp gauge
disk_cleanup_last_run_timestamp $(date +%s)

# HELP disk_usage_percent Current disk usage percentage
# TYPE disk_usage_percent gauge
disk_usage_percent $(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')

# HELP disk_cleanup_freed_bytes Bytes freed by last cleanup
# TYPE disk_cleanup_freed_bytes gauge
disk_cleanup_freed_bytes $(sudo /usr/local/bin/clean-mac-space --yes --quiet | grep -oP '\d+(\.\d+)?G' | head -1 | sed 's/G//' | awk '{print $1 * 1024 * 1024 * 1024}')
EOF
```

### macOS Notification Integration

Get notifications when cleanup completes:

```bash
#!/bin/bash
# ~/Scripts/cleanup-with-notification.sh

# Run cleanup and capture output
OUTPUT=$(sudo /usr/local/bin/clean-mac-space --yes --quiet 2>&1)

# Extract freed space
FREED=$(echo "$OUTPUT" | grep -o "Approximate space freed: [0-9.]*[GM]" | cut -d: -f2)

# Send macOS notification
osascript -e "display notification \"Freed: $FREED\" with title \"MacCleans Complete\" sound name \"Glass\""
```

## Custom Cleanup Categories

### Forking and Adding Custom Categories

Example: Adding Rust cargo cache cleanup

```bash
# Fork the repository and add this function:

cleanup_rust_cargo() {
    if [[ "${SKIP_CARGO}" == "true" ]]; then
        log_skip "Rust Cargo Cache"
        SKIPPED_CATEGORIES+=("Rust Cargo Cache")
        return 0
    fi

    log_info "Cleaning Rust Cargo cache..."

    local cargo_path="${USER_HOME}/.cargo/registry"
    local initial_size=0

    if [[ -d "${cargo_path}" ]]; then
        initial_size=$(du -sk "${cargo_path}" 2>/dev/null | awk '{print $1}')
    fi

    if [[ "${DRY_RUN}" == "true" ]]; then
        if [[ -d "${cargo_path}" ]]; then
            log_dry_run "Would delete: ${cargo_path} ($(format_size ${initial_size}))"
        fi
        return 0
    fi

    # Use cargo clean if available
    if command -v cargo &> /dev/null; then
        cargo cache --autoclean 2>/dev/null || true
    fi

    # Clean old registry files
    if [[ -d "${cargo_path}" ]]; then
        find "${cargo_path}" -type f -atime +30 -delete 2>/dev/null || true
        log_success "Cleaned Rust Cargo cache: $(format_size ${initial_size})"
        TOTAL_FREED=$((TOTAL_FREED + initial_size))
        PROCESSED_CATEGORIES+=("Rust Cargo Cache")
    fi
}

# Add to argument parsing:
--skip-cargo)
    SKIP_CARGO=true
    shift
    ;;

# Add to main execution:
cleanup_rust_cargo
```

### Wrapper Script for Organization-Specific Needs

Create a wrapper that adds company-specific cleanup:

```bash
#!/bin/bash
# ~/Scripts/company-cleanup.sh

# Run standard MacCleans
sudo /usr/local/bin/clean-mac-space "$@"

# Add company-specific cleanup
echo "Running company-specific cleanup..."

# Clean internal tools cache
rm -rf ~/Library/Caches/CompanyTool 2>/dev/null || true

# Clean old build artifacts
find ~/company-projects -name "build" -type d -mtime +7 -exec rm -rf {} + 2>/dev/null || true

# Clean old screenshots from /tmp
find /tmp -name "Screenshot*.png" -mtime +3 -delete 2>/dev/null || true

echo "Company-specific cleanup complete"
```

## Performance Optimization

### Parallel Cleanup Execution

Modify the script to run categories in parallel (advanced users):

```bash
#!/bin/bash
# Example: Parallel cleanup wrapper

cleanup_parallel() {
    # Run multiple cleanups simultaneously
    (
        cleanup_homebrew &
        cleanup_browsers &
        cleanup_npm &
        cleanup_pip &
        wait
    )
}

# Use with caution - may increase system load
```

### Selective Cleanup Based on Disk Usage

Smart cleanup that targets biggest offenders first:

```bash
#!/bin/bash
# ~/Scripts/smart-cleanup.sh

USAGE=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')

if [[ $USAGE -lt 80 ]]; then
    echo "Disk usage ${USAGE}% - no cleanup needed"
    exit 0
elif [[ $USAGE -lt 90 ]]; then
    # Light cleanup
    sudo /usr/local/bin/clean-mac-space --yes --quiet --profile minimal
elif [[ $USAGE -lt 95 ]]; then
    # Medium cleanup
    sudo /usr/local/bin/clean-mac-space --yes --quiet --profile conservative
else
    # Emergency cleanup - everything
    sudo /usr/local/bin/clean-mac-space --yes --quiet --profile aggressive
fi
```

## Enterprise Deployment

### MDM Deployment (Jamf, Munki, etc.)

Deploy MacCleans across organization:

```bash
#!/bin/bash
# Deploy script for Jamf Pro

# Download latest version
curl -o /usr/local/bin/clean-mac-space https://raw.githubusercontent.com/Carme99/MacCleans.sh/main/clean-mac-space.sh
chmod +x /usr/local/bin/clean-mac-space

# Deploy organization config
cat > /etc/maccleans.conf << 'EOF'
# Corporate default configuration
QUIET=true
AUTO_YES=true
THRESHOLD=85
SKIP_XCODE=true
SKIP_DOCKER=false
EOF

# Create LaunchDaemon (runs as root)
cat > /Library/LaunchDaemons/com.company.maccleans.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.company.maccleans</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/local/bin/clean-mac-space</string>
        <string>--quiet</string>
        <string>--yes</string>
        <string>--threshold</string>
        <string>85</string>
    </array>
    <key>StartCalendarInterval</key>
    <dict>
        <key>Hour</key>
        <integer>2</integer>
        <key>Minute</key>
        <integer>0</integer>
    </dict>
    <key>StandardOutPath</key>
    <string>/var/log/maccleans.log</string>
    <key>StandardErrorPath</key>
    <string>/var/log/maccleans.err</string>
</dict>
</plist>
EOF

# Load the daemon
launchctl load /Library/LaunchDaemons/com.company.maccleans.plist

echo "MacCleans deployed successfully"
```

### Centralized Logging

Send logs to central logging server:

```bash
#!/bin/bash
# ~/Scripts/cleanup-with-logging.sh

LOG_SERVER="logs.company.com"
HOSTNAME=$(hostname)

# Run cleanup and capture output
OUTPUT=$(sudo /usr/local/bin/clean-mac-space --yes --quiet 2>&1)

# Send to logging server (syslog/rsyslog)
echo "$OUTPUT" | logger -t maccleans -n "$LOG_SERVER" -P 514

# Or send via HTTP
curl -X POST "https://$LOG_SERVER/api/logs" \
    -H "Content-Type: application/json" \
    -d "{\"host\":\"$HOSTNAME\",\"message\":\"$OUTPUT\",\"timestamp\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}"
```

## Advanced Troubleshooting

### Debugging Mode

Enable verbose debugging:

```bash
# Run with bash debugging
bash -x /usr/local/bin/clean-mac-space --dry-run 2>&1 | tee debug.log

# Or add to script temporarily:
set -x  # Enable debugging
# ... your cleanup commands ...
set +x  # Disable debugging
```

### Performance Profiling

Measure which categories take longest:

```bash
#!/bin/bash
# Profile cleanup performance

time sudo /usr/local/bin/clean-mac-space --dry-run

# Or profile each category individually:
for category in xcode browsers npm pip docker; do
    echo "Profiling: $category"
    time sudo /usr/local/bin/clean-mac-space --dry-run --skip-all-except-$category
done
```

### Recovery from Failed Cleanup

If cleanup causes issues:

```bash
# Check what was deleted
grep "Cleaned" /var/log/maccleans.log

# Restore from Time Machine
tmutil listbackups
sudo tmutil restore /path/to/deleted/item

# Rebuild caches
# Most caches regenerate automatically on next app launch
# For browsers, just reopen them
# For XCode, open your project and rebuild
```

## Best Practices Summary

1. **Always test with --dry-run first**
2. **Use appropriate profiles for your use case**
3. **Set conservative thresholds for automated runs**
4. **Monitor disk space trends over time**
5. **Keep logs for troubleshooting**
6. **Test configuration changes before deployment**
7. **Have a rollback plan (Time Machine)**
8. **Document custom modifications**
9. **Review cleanup results periodically**
10. **Keep MacCleans updated to latest version**

---

Need help with advanced scenarios? [Open an issue](https://github.com/Carme99/MacCleans.sh/issues) or check the [FAQ](FAQ.md).
