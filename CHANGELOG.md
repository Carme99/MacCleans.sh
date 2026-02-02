# Changelog

All notable changes to MacCleans.sh are documented in this file.

## [3.0.0] - 2026-02-02

### Added

**Interactive Mode** 🎯
- New `--interactive` or `-i` flag for visual category selection
- Toggle categories on/off with numbered menu
- Quick commands: 'all', 'none', 'done'
- Real-time status display with color-coded checkmarks
- Perfect for users who want full control over what gets cleaned

**Configuration Profiles** 📋
- New `--profile` flag with 4 preset modes:
  - `conservative` - Skip all development caches (safe for all users)
  - `developer` - Skip only XCode (avoid rebuild times)
  - `aggressive` - Clean everything (maximum space recovery)
  - `minimal` - Only safe system caches (quickest, safest)
- Profiles can be combined with individual skip flags
- Perfect for quick, consistent cleanups

**New Cleanup Categories**
- **Docker Cache** 🐳 - Clean Docker images, containers, volumes, and build cache
  - Uses `docker system prune -af --volumes`
  - Shows disk usage before cleanup
  - Can recover 1-20GB+ depending on usage
- **iOS Simulator Data** 📱 - Clear iOS simulator caches and data
  - Deletes unavailable simulators
  - Erases all simulator data
  - Can recover 1-10GB+ for iOS developers
- **Mail App Cache** 📧 - Clean Mail application caches
  - Removes `~/Library/Caches/com.apple.mail`
  - Safe to delete (regenerates automatically)
  - Can recover 100MB-1GB

**Enhanced Validation & Security** 🔒
- Config file validation:
  - Boolean value validation (must be true/false)
  - Numeric threshold validation (must be 0-100)
  - Clear error messages for invalid configurations
- User validation improvements:
  - Validates SUDO_USER and USER_HOME
  - Prevents running as root directly
  - Verifies home directory exists and is in standard location
  - Better error messages when validation fails
- System health checks:
  - Warns if system load is high (>10)
  - Detects running Time Machine backups
  - Allows user to proceed or abort based on warnings

**Enhanced Summary Report** 📊
- Detailed "Categories Processed" section with ✓ indicators
- "Categories Skipped" section with ⊘ indicators
- Improved formatting with bold headers
- Before/after disk usage comparison
- Total space freed calculation
- Safety guarantees reminder at the end

**Additional Features**
- `--version` or `-v` flag to display version number
- `--skip-docker` flag for Docker cache
- `--skip-simulator` flag for iOS Simulator data
- `--skip-mail` flag for Mail app cache
- Better error messages throughout script
- ShellCheck compliance with `set -euo pipefail`
- Improved safety with bash parameter expansion (${VAR:?})

### Improved

**Error Handling**
- Strict error handling with `set -euo pipefail`
- Better error messages with context
- Graceful handling of missing commands
- Proper exit codes for all error conditions
- Validation before destructive operations

**Code Quality**
- ShellCheck compliant bash code
- Eliminated dependency on `bc` (pure bash arithmetic)
- Better function organization and naming
- Improved variable scoping with `local`
- Consistent error handling patterns
- Protected against word splitting and glob expansion

**User Experience**
- More informative log messages
- Better visual hierarchy in output
- Contextual warnings (high load, active backups)
- Clearer indication of what was processed vs skipped
- Improved dry-run output with better formatting

### Changed

- Bumped version from 2.5.0 to 3.0.0 (major release)
- Size conversion now uses pure bash instead of `bc`
- Float calculations for GB/TB display now use `awk`
- Configuration validation runs after argument parsing
- Home directory validation is more comprehensive

### Documentation

- Updated README.md with all v3.0.0 features
- Added detailed profiles explanation
- Added interactive mode documentation
- Added system health checks section
- Enhanced FAQ with profile and interactive mode questions
- Updated examples to showcase new features
- Added CONTRIBUTING.md reference
- New badge for version 3.0.0

- Updated INSTALL.md with new flags and features
- Updated maccleans.conf.example with new options
- Added pro tips section in config file
- Added profile usage examples

### Details

- Script size increased from 855 to 1,384 lines (+529 lines)
- Now 15 cleanup categories (was 12 in v2.5.0)
- Three new skip flags added
- Two new command-line flags (--interactive, --profile)
- Enhanced validation adds ~150 lines of safety checks
- Interactive mode adds ~100 lines of UI code

### Potential Space Recovery

V3.0.0 can now recover even more space:

**New in 3.0.0:**
- **Docker Cache**: 1-20GB+ (Docker users)
- **iOS Simulator Data**: 1-10GB+ (iOS developers)
- **Mail App Cache**: 100MB-1GB (all users)

**From previous versions:**
- **XCode Derived Data**: 5-50GB+ (XCode developers)
- **Browser Caches**: 1-5GB
- **npm/Yarn Cache**: 500MB-5GB (Node developers)
- **pip Cache**: 100MB-2GB (Python developers)
- **Homebrew Cache**: 500MB-2GB
- **Trash Bin**: Variable
- **Other categories**: 500MB-2GB

**Total potential recovery with V3.0.0: 15-100GB+** depending on system usage

### Breaking Changes

None! V3.0.0 is fully backward compatible:
- All existing flags work identically
- Existing config files continue to work (just add new options if desired)
- Existing scripts and cron jobs continue to work
- Only additions and improvements, no removals

### Upgrade Notes

**From v2.5.0 to v3.0.0:**

All existing functionality preserved. New features are opt-in:

```bash
# Your old commands work exactly the same
sudo ./clean-mac-space.sh --yes --quiet

# New: Try interactive mode
sudo ./clean-mac-space.sh --interactive

# New: Use profiles for quick cleanup
sudo ./clean-mac-space.sh --profile developer
```

To skip new categories in automated scripts:

```bash
# Skip new v3.0.0 categories
sudo ./clean-mac-space.sh \
  --skip-docker \
  --skip-simulator \
  --skip-mail
```

**Configuration File Updates:**

If you have a `~/.maccleans.conf`, you can optionally add:

```bash
# New in v3.0.0
SKIP_DOCKER=false
SKIP_SIMULATOR=false
SKIP_MAIL=false
```

But this is optional - the script works fine without these additions.

---

## [2.5.0] - 2026-02-01

### Added

**Configuration File Support**
- Load persistent settings from configuration files
- Config file locations (checked in order):
  - `~/.maccleans.conf`
  - `~/.config/maccleans/config`
  - `${XDG_CONFIG_HOME}/maccleans/config`
- Command line arguments override config file settings
- Example configuration file (`maccleans.conf.example`)
- Support for all existing flags in config format

**Colored Output**
- Visual feedback with color-coded messages:
  - Green (✓) for success messages
  - Yellow (⚠) for warnings
  - Red (✗) for errors
  - Magenta for section headers
  - Cyan for highlighted values
  - Dimmed timestamps for better readability
- Automatically disabled when output is not a terminal
- Manual override with `--no-color` flag
- Enhanced log functions: `log_success()`, `log_warning()`, `log_error()`

**Documentation**
- New `INSTALL.md` - Comprehensive installation guide with:
  - Multiple installation methods (curl download, git clone)
  - Configuration file setup instructions
  - Automated cleanup setup (cron, launchd examples)
  - Troubleshooting section
- Updated README with:
  - Installation section linking to INSTALL.md
  - Configuration file documentation
  - New `--no-color` flag documentation
  - Updated feature list

**New Command-Line Options**
- `--no-color` - Disable colored output

### Improved

- Better user experience with visual feedback
- Reduced need for repetitive command-line flags
- Easier automation setup with config files
- More professional output formatting

### Details

- Config file parser supports comments and blank lines
- Safe config loading with validation
- Color support respects terminal capabilities
- All existing functionality preserved
- No breaking changes

---

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
- Language-specific caches (Rust, Go, Ruby, Gradle, Maven, Composer)
- Docker/container cleanup
- Additional browser support (Brave, Opera, Arc)
- Interactive mode with menu selection
- Detailed recovery statistics per category
- Progress indicators for long operations
- Notification support (macOS notifications when complete)
