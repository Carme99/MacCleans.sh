# MacCleans.sh

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![macOS](https://img.shields.io/badge/macOS-10.15+-blue.svg)](https://www.apple.com/macos/)
[![Shell](https://img.shields.io/badge/Shell-Bash-black.svg)](https://www.gnu.org/software/bash/)
[![Maintenance](https://img.shields.io/badge/Maintained%3F-yes-green.svg)](https://github.com/Carme99/MacCleans.sh/graphs/commit-activity)

A safe and efficient macOS space cleanup script designed to free up storage on SSDs by removing cache files, temporary data, and old logs without touching your critical data.

## Features

✅ **Safe** - Does not touch Safari, browser sessions, user documents, or critical system data

✅ **Smart** - Selective cleanup with `--skip-*` options for fine-grained control

✅ **Dry-Run Mode** - Preview what will be cleaned before executing

✅ **Flexible** - Works with cron jobs using `--quiet` mode

✅ **Threshold-Based** - Only run when disk usage exceeds a specified percentage

✅ **Non-Destructive** - Cleans regenerable cache and temp files only

## What Gets Cleaned

- **Time Machine Local Snapshots** - Old backup snapshots (with safety checks)
- **Homebrew Cache** - Package manager cache and old downloads
- **Application Caches** - Spotify, Claude Desktop, and system app caches
- **System Caches** - GeoServices, helpd, parsecd, and compiler cache (>30 days old)
- **Old Logs** - Log files older than 7 days
- **Temporary Files** - System temp directories (`/tmp`, `/var/tmp`)

## What's NOT Touched

- ✋ Safari and browser session data
- ✋ Application settings and configurations
- ✋ User documents and media files
- ✋ Active application data
- ✋ System critical files

## Requirements

- macOS 10.15 (Catalina) or later
- `sudo` privileges (required for safe cleanup)
- `bc` command (usually pre-installed)

## Installation

### Quick Install

```bash
git clone https://github.com/Carme99/MacCleans.sh.git
cd MacCleans.sh
chmod +x clean-mac-space.sh

# Optional: Copy to your Scripts directory
mkdir -p ~/Scripts
cp clean-mac-space.sh ~/Scripts/
```

### Or Download Direct

```bash
wget https://raw.githubusercontent.com/Carme99/MacCleans.sh/main/clean-mac-space.sh
chmod +x clean-mac-space.sh
```

## Usage

### Basic Usage

```bash
# Interactive mode (confirms before deleting)
sudo ./clean-mac-space.sh

# Preview without deleting
sudo ./clean-mac-space.sh --dry-run

# Skip confirmation
sudo ./clean-mac-space.sh --yes

# Minimal output (useful for cron)
sudo ./clean-mac-space.sh --quiet
```

### Advanced Options

```bash
# Only run if disk usage is above 80%
sudo ./clean-mac-space.sh --threshold 80

# Skip specific cleanup tasks
sudo ./clean-mac-space.sh --skip-homebrew --skip-spotify
sudo ./clean-mac-space.sh --skip-snapshots
sudo ./clean-mac-space.sh --skip-claude

# Combine options
sudo ./clean-mac-space.sh --dry-run --quiet --threshold 75
```

### Cron Automation

To run cleanup automatically (e.g., daily at 2 AM):

```bash
# Edit crontab
sudo crontab -e

# Add this line:
0 2 * * * /path/to/clean-mac-space.sh --yes --quiet --threshold 80
```

## Command Options

| Option | Short | Description |
|--------|-------|-------------|
| `--dry-run` | `-n` | Preview what would be cleaned without deleting |
| `--yes` | `-y` | Skip confirmation prompt |
| `--quiet` | `-q` | Minimal output (useful for cron) |
| `--threshold N` | | Only run if disk usage is above N% |
| `--skip-snapshots` | | Skip Time Machine snapshot deletion |
| `--skip-homebrew` | | Skip Homebrew cache cleanup |
| `--skip-spotify` | | Skip Spotify cache cleanup |
| `--skip-claude` | | Skip Claude Desktop cache cleanup |
| `--help` | `-h` | Show usage information |

## Examples

### Example 1: Safe Test Run

```bash
sudo ./clean-mac-space.sh --dry-run
```

Previews what will be cleaned without making any changes.

### Example 2: Aggressive Cleanup

```bash
sudo ./clean-mac-space.sh --yes --quiet
```

Cleans everything without prompts or output (great for automation).

### Example 3: Smart Cleanup

```bash
sudo ./clean-mac-space.sh --threshold 80 --skip-snapshots
```

Only runs if disk is >80% full, preserves Time Machine snapshots.

### Example 4: Selective Cleanup

```bash
sudo ./clean-mac-space.sh --skip-homebrew --skip-spotify
```

Cleans everything except Homebrew cache and Spotify data.

## Output Example

```
================================================
Mac Space Cleanup Script
================================================

[2024-01-20 14:32:15] Running as user: jack
[2024-01-20 14:32:15] Home directory: /Users/jack
[2024-01-20 14:32:15] Current disk usage: 85% (450G used, 80G available)

================================================
1. Time Machine Local Snapshots
================================================
[2024-01-20 14:32:15] Found 3 local snapshot(s)
[2024-01-20 14:32:16] ✓ Local snapshots deleted successfully

[continues with other cleanup sections...]

================================================
Cleanup Complete!
================================================

[2024-01-20 14:33:22] Initial disk usage: 85% (450G used, 80G available)
[2024-01-20 14:33:22] Final disk usage:   78% (420G used, 110G available)
✓ Approximate space freed: 30G
```

## Safety Features

1. **Confirmation Prompts** - Interactive mode requires user confirmation before deletion
2. **Dry-Run Mode** - Test what will be cleaned before actually deleting
3. **Time Machine Safety** - Won't delete snapshots if backup is currently running
4. **Selective Skip Options** - Disable specific cleanups with `--skip-*` flags
5. **Non-Destructive** - Only removes regenerable cache and temporary files
6. **File Age Checks** - Only deletes old files (>7-30 days depending on type)

## Troubleshooting

### "Error: This script needs sudo privileges"

Run with `sudo`:

```bash
sudo ./clean-mac-space.sh
```

### Script Not Executable

Make it executable:

```bash
chmod +x clean-mac-space.sh
```

### Homebrew Cleanup Issues

If you see warnings during Homebrew cleanup, it's safe to ignore - this is non-critical:

```bash
sudo ./clean-mac-space.sh --skip-homebrew
```

### Still Low on Space?

After running this script, consider:

- Cleaning application support files: `rm -rf ~/Library/Application Support/[AppName]`
- Checking large files: `du -sh ~/Downloads/*` or `du -sh ~/Library/Caches/*`
- Removing old backups or downloads
- Using a tool like `ncdu` to analyze disk usage

## Performance Impact

The script is designed to be non-blocking:

- **Typical Runtime**: 2-10 minutes depending on system state
- **CPU Impact**: Minimal (uses standard Unix utilities)
- **System Disruption**: Safe to run while working (no critical system files touched)

## Contributing

Contributions welcome! Feel free to:

- Report issues
- Suggest improvements
- Add support for additional app caches
- Improve documentation

## License

MIT License - See [LICENSE](LICENSE) file for details.

## Disclaimer

While this script is designed to be safe and only removes regenerable cache/temp files, **use at your own risk**. Always test with `--dry-run` first. The author is not responsible for any data loss or system issues that may arise from running this script.

## Support

If you encounter issues:

1. Run with `--dry-run` to see what would be cleaned
2. Check that you have `sudo` privileges
3. Ensure macOS version is 10.15+
4. Try skipping specific cleanups with `--skip-*` flags
5. Open an issue on GitHub with details

---

Made with care for Mac users with small SSDs ✨
