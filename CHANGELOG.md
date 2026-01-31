# Changelog

All notable changes to MacCleans.sh are documented in this file.

## [2.0.0] - 2026-01-31

### Added

**New Cleanup Categories**
- **Browser Cache Cleanup** - Remove caches from Chrome, Firefox, and Microsoft Edge
- **XCode Derived Data** - Clean XCode build cache with interactive safety warning
- **npm/Yarn Cache** - Clear Node.js package manager caches  
- **Python pip Cache** - Remove Python package manager cache
- **Trash Bin Cleanup** - Safely empty user trash directory
- **.DS_Store File Cleanup** - Remove macOS system metadata files from user home directory

**New Command-Line Options**
- `--skip-xcode` - Skip XCode derived data cleanup
- `--skip-browsers` - Skip browser cache cleanup (Chrome, Firefox, Edge)
- `--skip-npm` - Skip npm/yarn cache cleanup
- `--skip-pip` - Skip Python pip cache cleanup
- `--skip-trash` - Skip emptying trash bin
- `--skip-dsstore` - Skip .DS_Store file cleanup

**Documentation**
- Updated README with new V2 features and categories
- Added detailed .DS_Store explanation (what they are, why to clean them, safety)
- Added version history and upgrade notes
- Expanded command options table

**Safety Features**
- Interactive confirmation for XCode cleanup (prevents unexpected rebuilds)
- .DS_Store scope limited to user home directory
- Full dry-run preview support for all new categories
- Proper error suppression on all operations

### Details

- Expanded from 6 to 12 cleanup categories
- Increased script size from 427 to 779 lines (+352 lines)
- All new categories enabled by default (opt-out approach via `--skip-*` flags)
- Proper space tracking for all new categories in final summary
- Existence checks before cleanup operations

### Potential Space Recovery

V2.0.0 can now recover significantly more space:

- **XCode Derived Data**: 5-50GB+ (developers)
- **Browser Caches**: 1-5GB
- **npm/Yarn Cache**: 500MB-5GB (developers)
- **pip Cache**: 100MB-2GB (Python developers)
- **Trash Bin**: Variable
- **Plus existing categories**: 1-10GB

**Total potential recovery with V2.0.0: 10-70GB+** depending on system usage

### Breaking Changes

None! V2.0.0 is fully backward compatible:
- All existing flags work identically
- Existing scripts and cron jobs continue to work
- Only additions, no removals

---

## [1.0.0] - 2024-01-15

### Features

**Cleanup Categories**
- Time Machine Local Snapshots - Old backup snapshots with safety checks
- Homebrew Cache - Package manager cache and unused dependencies
- Application Caches - Spotify and Claude Desktop safe caches
- System Cache Files - Old system service caches (30+ days)
- Old Log Files - Log files older than 7 days
- System Temporary Files - `/tmp` and `/var/tmp` directories

**Command-Line Options**
- `--dry-run, -n` - Preview without deleting
- `--yes, -y` - Skip confirmation
- `--quiet, -q` - Minimal output for automation
- `--threshold N` - Only run if disk usage above N%
- `--skip-snapshots` - Skip Time Machine cleanup
- `--skip-homebrew` - Skip Homebrew cleanup
- `--skip-spotify` - Skip Spotify cleanup
- `--skip-claude` - Skip Claude cleanup
- `--help, -h` - Show help

**Safety Features**
- Confirmation prompts in interactive mode
- Dry-run preview mode
- Time Machine safety (won't delete if backup is running)
- Selective skip options
- Non-destructive (only removes regenerable files)
- Age-based deletion (only old files)

**Space Recovery**
Typical recovery of 1-10GB from:
- Homebrew Cache: 500MB-2GB
- Old Logs: 100MB-1GB
- Application Caches: 100MB-2GB
- Temp Files: 100MB-500MB

---

## Upgrade Path: V1 to V2

### What's New

V2.0.0 adds significant new cleanup capabilities, especially for developers:

1. **Browser cleanup** - Chrome, Firefox, Edge caches
2. **XCode support** - XCode derived data with safety warnings
3. **Package manager caches** - npm, yarn, pip cleanup
4. **Trash management** - Trash bin emptying
5. **System metadata** - .DS_Store file cleanup

### Migration

No breaking changes - all existing configurations continue to work:

```bash
# Old command (V1) still works exactly the same
sudo ./clean-mac-space.sh --skip-homebrew

# New features are automatic but can be disabled
sudo ./clean-mac-space.sh --skip-xcode --skip-browsers
```

To preserve V1 behavior exactly (skip all new features):

```bash
sudo ./clean-mac-space.sh \
  --skip-xcode \
  --skip-browsers \
  --skip-npm \
  --skip-pip \
  --skip-trash \
  --skip-dsstore
```

---

## Future Considerations

Potential features for future releases:
- Language-specific caches (Rust, Go, Ruby)
- Docker/container cleanup
- Additional browser support (Brave, Opera)
- Configuration file support
- Detailed recovery statistics
- launchd integration for scheduled cleanup
