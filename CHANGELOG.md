# Changelog

All notable changes to MacCleans.sh are documented in this file.

## [3.2.1] - 2026-02-21

### Security Fixes

- **Eval vulnerability fix**: Replaced unsafe `eval echo ~$SUDO_USER` with safer `getent passwd` or `/Users/$SUDO_USER` fallback. This prevents potential code injection if SUDO_USER is set to a malicious value.
- **Symlink attack prevention**: Fixed trash bin deletion to use `find -type f -delete` instead of glob expansion, preventing potential symlink attacks that could follow links outside the trash directory.

### Added

- **New --force/-f flag**: Skips ALL confirmation prompts including dangerous operations like XCode cleanup. Useful for fully unattended automation. Implies --yes.
- **Signal handling**: Added SIGINT/SIGTERM trap for graceful interruption. Script now cleanly exits with proper message when interrupted (Ctrl+C).

### Improved

- **XCode cleanup**: Now respects --force flag to allow fully automated XCode cleanup without prompts.

## [3.2.0] - 2026-02-20

### Added

- iOS/iPadOS update file (.ipsw) detection and cleanup
- New `--skip-ios-updates` flag
- Conservative and minimal profiles updated to skip iOS updates by default

## [3.1.0] - 2026-02-08

### Added

**Comprehensive Documentation Suite**
- New `CONTRIBUTING.md` - Complete contribution guide with:
  - Testing guidelines and code style standards
  - Step-by-step instructions for adding cleanup categories
  - Pull request submission process
  - ShellCheck compliance requirements
- New `ADVANCED.md` - Advanced usage guide covering:
  - Multi-profile configurations
  - CI/CD integration (GitHub Actions, GitLab, Jenkins, CircleCI)
  - Monitoring and alerting (Slack, Prometheus, macOS notifications)
  - Custom cleanup categories
  - Enterprise deployment strategies
  - Performance optimization
- New `FAQ.md` - Comprehensive FAQ with 50+ questions covering:
  - General questions and safety concerns
  - Features and usage
  - Troubleshooting
  - Performance and results
  - Technical details
- New `TROUBLESHOOTING.md` - Detailed troubleshooting guide with:
  - Solutions to common errors
  - Permission issue fixes
  - Installation and execution problems
  - Configuration troubleshooting
  - Recovery and rollback procedures
  - Debug mode instructions

**Educational Guides (docs/)**
- `docs/understanding-macos-caches.md` - Deep dive into cache types, how they work, and when to clean them
- `docs/xcode-derived-data-guide.md` - Comprehensive guide for iOS/Mac developers on managing XCode caches with real-world examples
- `docs/docker-cache-guide.md` - Docker cache management best practices and cleanup strategies
- `docs/automating-macos-maintenance.md` - Complete automation guide with cron, LaunchD, and custom scripts
- `docs/README.md` - Navigation hub for all documentation

**Documentation Improvements**
- Updated main README with comprehensive documentation section
- Added quick reference table for common use cases
- New documentation badge in README header
- Cross-referenced navigation between all docs
- Shield badges throughout all documentation

**Safety Improvements**
- Removed `--volumes` flag from Docker cleanup to protect database data
- Removed destructive `xcrun simctl erase all` from Simulator cleanup
- Docker cleanup now only removes dangling images, stopped containers, and unused networks
- Simulator cleanup now only removes unavailable simulators

**Space Tracking**
- Added byte-accurate space tracking to System Cache section
- Added byte-accurate space tracking to Temp Files section
- Added byte-accurate space tracking to .DS_Store section
- Added estimated reclaimable space tracking to Docker section

**Project Infrastructure**
- New `SECURITY.md` - Security policy with responsible disclosure guidelines
- New `.github/ISSUE_TEMPLATE/bug_report.md` - Structured bug report template
- New `.github/ISSUE_TEMPLATE/feature_request.md` - Feature request template
- New `.github/pull_request_template.md` - PR template with checklist
- Added table of contents to README
- Streamlined README by removing duplicate FAQ/Troubleshooting sections

### Improved

- Better documentation discoverability from main README
- Comprehensive resources for users at all skill levels
- Clear guidance for contributors
- Real-world examples and use cases throughout
- More accurate space freed reporting in summary
- Safer default behavior for Docker and Simulator cleanup

## [3.0.0] - 2026-02-02

See main branch for v3.0.0 release notes.

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
