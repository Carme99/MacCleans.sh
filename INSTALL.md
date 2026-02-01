# Installation Guide

This guide covers different methods to install and set up MacCleans on your macOS system.

## Quick Installation

### Method 1: Direct Download (Recommended)

Download and install in one command:

```bash
# Download to /usr/local/bin (system-wide installation)
sudo curl -o /usr/local/bin/clean-mac-space https://raw.githubusercontent.com/Carme99/MacCleans.sh/main/clean-mac-space.sh
sudo chmod +x /usr/local/bin/clean-mac-space

# Now you can run from anywhere:
sudo clean-mac-space --dry-run
```

Or install to your personal Scripts directory:

```bash
# Create Scripts directory if it doesn't exist
mkdir -p ~/Scripts

# Download the script
curl -o ~/Scripts/clean-mac-space.sh https://raw.githubusercontent.com/Carme99/MacCleans.sh/main/clean-mac-space.sh
chmod +x ~/Scripts/clean-mac-space.sh

# Run the script
sudo ~/Scripts/clean-mac-space.sh --dry-run
```

### Method 2: Git Clone

Clone the repository for easy updates:

```bash
# Clone to your preferred location
cd ~/
git clone https://github.com/Carme99/MacCleans.sh.git

# Make executable
chmod +x ~/MacCleans.sh/clean-mac-space.sh

# Create a symlink for easy access (optional)
sudo ln -s ~/MacCleans.sh/clean-mac-space.sh /usr/local/bin/clean-mac-space

# Run the script
sudo clean-mac-space --dry-run
```

To update later:
```bash
cd ~/MacCleans.sh
git pull
```

## Configuration Setup (Optional)

MacCleans supports configuration files for persistent settings:

### 1. Copy the example configuration

```bash
# Option A: Use ~/.maccleans.conf (recommended for simplicity)
cp ~/MacCleans.sh/maccleans.conf.example ~/.maccleans.conf

# Option B: Use XDG-compliant location
mkdir -p ~/.config/maccleans
cp ~/MacCleans.sh/maccleans.conf.example ~/.config/maccleans/config

# Option C: Use XDG_CONFIG_HOME (if you have it set)
mkdir -p "${XDG_CONFIG_HOME}/maccleans"
cp ~/MacCleans.sh/maccleans.conf.example "${XDG_CONFIG_HOME}/maccleans/config"
```

### 2. Edit your configuration

Open the config file in your favorite editor:

```bash
nano ~/.maccleans.conf
# or
vim ~/.maccleans.conf
# or
code ~/.maccleans.conf
```

### 3. Example configurations

**Conservative (skip development caches):**
```bash
# ~/.maccleans.conf
SKIP_XCODE=true
SKIP_NPM=true
SKIP_PIP=true
SKIP_BROWSERS=true
```

**Developer-friendly (skip only XCode):**
```bash
# ~/.maccleans.conf
SKIP_XCODE=true
```

**Automated cron job:**
```bash
# ~/.maccleans.conf
QUIET=true
AUTO_YES=true
THRESHOLD=80
```

## Setting Up Automated Cleanup (Optional)

### Using cron

Edit your crontab:
```bash
crontab -e
```

Add one of these lines:

```bash
# Run daily at 2 AM if disk usage > 75%
0 2 * * * /usr/bin/sudo /usr/local/bin/clean-mac-space --quiet --threshold 75 --yes >> ~/Library/Logs/maccleans.log 2>&1

# Run weekly on Sunday at 3 AM
0 3 * * 0 /usr/bin/sudo /usr/local/bin/clean-mac-space --quiet --yes >> ~/Library/Logs/maccleans.log 2>&1

# Run monthly on the 1st at 4 AM
0 4 1 * * /usr/bin/sudo /usr/local/bin/clean-mac-space --quiet --yes >> ~/Library/Logs/maccleans.log 2>&1
```

### Using launchd (macOS native)

Create a launch agent file:

```bash
nano ~/Library/LaunchAgents/com.maccleans.cleanup.plist
```

Add this content (adjust paths as needed):

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
        <string>--threshold</string>
        <string>80</string>
        <string>--yes</string>
    </array>
    <key>StartCalendarInterval</key>
    <dict>
        <key>Hour</key>
        <integer>2</integer>
        <key>Minute</key>
        <integer>0</integer>
    </dict>
    <key>StandardOutPath</key>
    <string>/tmp/maccleans.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/maccleans.err</string>
</dict>
</plist>
```

Load the launch agent:
```bash
launchctl load ~/Library/LaunchAgents/com.maccleans.cleanup.plist
```

## Uninstallation

To remove MacCleans:

```bash
# Remove the script
sudo rm /usr/local/bin/clean-mac-space
# or
rm -rf ~/MacCleans.sh
rm ~/Scripts/clean-mac-space.sh

# Remove configuration
rm ~/.maccleans.conf
rm -rf ~/.config/maccleans

# Remove cron job (if set up)
crontab -e
# Then delete the MacCleans line

# Remove launchd agent (if set up)
launchctl unload ~/Library/LaunchAgents/com.maccleans.cleanup.plist
rm ~/Library/LaunchAgents/com.maccleans.cleanup.plist
```

## Verification

After installation, verify it works:

```bash
# Check version/help
sudo clean-mac-space --help

# Run in dry-run mode to preview
sudo clean-mac-space --dry-run

# Check if config file is being loaded
sudo clean-mac-space --dry-run
# Look for: "Loaded configuration from: ..."
```

## Troubleshooting

### "command not found"

If you get "command not found" after installing to `/usr/local/bin`:

1. Check if `/usr/local/bin` is in your PATH:
   ```bash
   echo $PATH | grep /usr/local/bin
   ```

2. If not, add it to your shell profile (`~/.zshrc` or `~/.bash_profile`):
   ```bash
   echo 'export PATH="/usr/local/bin:$PATH"' >> ~/.zshrc
   source ~/.zshrc
   ```

### Permission denied

If you get permission errors:

```bash
# Make sure the script is executable
chmod +x /usr/local/bin/clean-mac-space

# Make sure you're running with sudo
sudo clean-mac-space --dry-run
```

### Config file not being loaded

Check these locations in order (first one found is used):

```bash
ls -la ~/.maccleans.conf
ls -la ~/.config/maccleans.conf
ls -la "${XDG_CONFIG_HOME}/maccleans/config"
```

Ensure the file has correct format (no spaces around `=`):
```bash
# Correct:
SKIP_XCODE=true

# Wrong:
SKIP_XCODE = true
```

## Getting Help

- View all options: `sudo clean-mac-space --help`
- Check the [README](README.md) for usage examples
- Report issues at: https://github.com/Carme99/MacCleans.sh/issues
