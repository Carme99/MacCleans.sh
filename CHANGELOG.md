# Changelog

All notable changes to MacCleans.sh are documented in this file.

## [4.2.0] - 2026-03-07

### New Features

- **JSON Output**: New `--json` / `-j` flag to output cleanup results in JSON format (useful for automation/monitoring)
  - Outputs version, timestamp, dry-run status, processed/skipped categories, disk usage before/after, and space freed
  - Perfect for CI/CD pipelines, monitoring scripts, and logging systems
  - JSON output suppresses all normal log messages for clean programmatic consumption

### Improvements

#### Code Quality & Security

- **Config Parsing**: Replaced fragile `xargs` with bash parameter expansion for more robust whitespace handling
  - Old: `key=$(echo "$key" | xargs)` - could fail on edge cases
  - New: Bash parameter expansion `${key#"${key%%[![:space:]]*}"}` - pure bash, more reliable
- **Consistent Safe Deletion**: Trash section now uses `safe_clear_directory()` function for consistent behavior
  - Aligns with other cleanup sections
  - Uses `find -delete` operations instead of risky glob patterns
  - Better symlink protection
- **Config File Updates**: Updated `config.example` to v4.2.0 with `JSON_OUTPUT=false` option added

### Security Restorations (Critical)

- **Lock File Prevention**: Restored `acquire_lock()` function to prevent multiple instances running simultaneously
  - Uses atomic mkdir-based locking
  - Prevents race conditions and potential corruption
- **Symlink Protection Restored**: Added `! -L` checks to all 15+ deletion sites
  - Prevents symlink attacks where malicious symlinks could redirect deletions
  - Uses `safe_clear_directory()` for all cache cleanups
- **iCloud Sync Check Restored**: Reintroduced `check_icloud_sync_status()` function
  - Checks for `.icloud` placeholder files before deletion
  - Uses `brctl` to detect active uploads/downloads
  - Prevents permanent data loss from iCloud
- **Age-Based tmp Deletion Restored**: System temp files now use `mtime +3` (3 days old)
  - Changed from blanket `rm -rf /private/tmp/*` to `find -mtime +3 -delete`
  - Prevents breaking running processes that have active temp files
- **Cleanup on Exit**: Restored `cleanup_on_exit()` function
  - Ensures lock files are properly released on script exit
  - Prevents stale locks from blocking future runs

### JSON Output Improvements

- **Fixed JSON Validity**: Resolved issues with unquoted booleans and strings
  - `dry_run` now outputs proper JSON boolean (`true`/`false`)
  - Category names are now properly escaped for JSON
- **Consolidated JSON**: Removed fragmented JSON implementations
  - Single JSON output at script end
  - Cleaner code structure

### Installer Improvements

- **curl|bash Safety**: Fixed auto-sudo escalation when running via `curl | bash`
  - Detects stdin execution and provides clear error message
  - Prevents unexpected behavior from re-execing from stdin

#### Documentation Restructure

- **Moved to docs/ folder**: 7 documentation files relocated to maintain cleaner repository root
  - `ADVANCED.md` → `docs/advanced.md`
  - `FAQ.md` → `docs/faq.md`
  - `INSTALL.md` → `docs/install.md`
  - `QUICKSTART.md` → `docs/quickstart.md`
  - `SECURITY.md` → `docs/security.md`
  - `TROUBLESHOOTING.md` → `docs/troubleshooting.md`
  - `COMPARISON.md` → `docs/comparison.md`
  - `maccleans.conf.example` → `docs/config.example`
- **README Rewrite**: Transformed from 530-line comprehensive manual to 174-line quick-start hub
  - Added ASCII art logo with lightning bolt branding
  - Added 2 terminal output examples (--dry-run and --json)
  - Condensed and scannable for new users
  - Links to detailed docs for in-depth information
- **Internal Links Updated**: All cross-document links updated to reflect new `docs/` folder structure
  - Updated `CONTRIBUTING.md` doc references
  - Fixed links in all 7 moved documentation files
  - Updated `docs/index.md` navigation hub
- **Testing Documentation**: Added JSON output testing instructions to `CONTRIBUTING.md`
  - Added "Test JSON Output" section with examples
  - Updated manual testing checklist to include JSON validation

#### README Visual Enhancements

- **ASCII Art Logo**: Added branded header with lightning bolt icon
  - Professional and instantly recognizable
  - Version number prominently displayed
- **Terminal Output Examples**: Added 2 practical code blocks
  - `--dry-run`: Shows discovery process, category scans, and space calculation
  - `--json`: Demonstrates programmatic output structure for automation
  - Builds user trust by showing exactly what they'll see
- **Better User Experience**: Transformed from boring text-heavy to visually engaging with personality

### Repository Structure

- **Root Files**: Simplified to essential files only
  - `README.md`, `CHANGELOG.md`, `CONTRIBUTING.md`, `LICENSE` kept at root
  - `clean-mac-space.sh`, `installer.sh` at root
  - All detailed docs in `docs/` folder

### Technical Details

- **Version Bump**: 4.1.2 → 4.2.0 (minor version for new functionality)
- **No Breaking Changes**: All existing CLI flags and behavior preserved
- **Backward Compatible**: Existing config files work without modification
- **Code Size**: README reduced by 67% while improving usability

### Community Impact

- **Better Onboarding**: New users can understand and use MacCleans in seconds
- **Improved Safety**: More robust code reduces edge case failures
- **Automation Ready**: JSON output enables programmatic usage
- **Easier Maintenance**: Cleaner repository structure reduces cognitive load

## [4.1.0] - 2026-02-23

### New Features

- **New Command Name**: Script now installs as `Mac-Clean` (with backward-compatible symlink as `mac-clean`)
- **Visual Feedback**: Added spinners, colored status indicators, and progress messages for better UX
- **brew update Integration**: New `--update` / `-u` flag to run `brew update` before cleanup

### New Cleanup Categories (5 additional)

- **CocoaPods Cache**: Clean `$HOME/Library/Caches/CocoaPods` using `pod cache clean --all`
- **Gradle Cache**: Clean `$HOME/.gradle/caches`
- **Go Module Cache**: Clean `$GOPATH/pkg/mod` using `go clean -modcache`
- **Bun Cache**: Clean `$HOME/.bun/install/cache`
- **pnpm Store**: Clean pnpm store using `pnpm store prune`

### Improvements

- **Time Machine Snapshots**: Now shows accurate count only. Removed estimated size calculation since macOS doesn't expose snapshot sizes (previously showed unreliable estimates)
- **Interactive Menu**: Updated to include all 29 cleanup categories in correct order
- **Documentation**: Added attribution to [mac-cleanup](https://github.com/mac-cleanup/mac-cleanup-sh) for inspiration on several cleanup categories

### Bug Fixes

- Fixed section numbering after adding new categories (now 29 total, .DS_Store is section 29)
- Installer script now creates proper symlinks for backward compatibility

## [4.0.0] - 2026-02-21

### Major Features

- **Photos Library Multi-Library Support**: New `--photos-library` flag to target specific libraries or clean all libraries
  - `--photos-library "Photos Library"` - Target specific library by name
  - `--photos-library all` - Clean all found libraries
  - Default: cleans first/default library only
- **Enhanced iCloud Integration**: Improved iCloud Photos, Drive, and Mail cache cleanup with smart detection

### Breaking Changes

- Renamed `--skip-icloud-photos` → `--skip-photos-library`
- Renamed variable `SKIP_ICLOUD_PHOTOS` → `SKIP_PHOTOS_LIBRARY`
- Updated category name: "iCloud Photos Cache" → "Photos Library Cache"
- **FORCE=true in config now propagates to AUTO_YES=true**: This means iOS device backups and iCloud Drive files will be deleted without requiring 'DELETE' confirmation when FORCE=true is set in config. Users who previously relied on config-based FORCE=true for unattended runs should add `SKIP_IOS_BACKUPS=true` and `SKIP_ICLOUD_DRIVE=true` to their config if they don't want these categories deleted.

### Bug Fixes (v4.0.x)

#### Critical Fixes
- **Disk Space Calculation**: Fixed broken calculation using `df -h` multiplied by 512. Now uses `df -k` for accurate kilobyte-based calculation
- **iCloud Drive Scope**: Fixed deletion targeting ALL cloud providers (OneDrive, Google Drive, Box). Now only targets iCloud Drive folders using glob filter `iCloud Drive*`

#### High Severity Fixes
- **iOS Backups Safety**: Added `--force` requirement for iOS backup deletion (like iCloud Drive). Prevents accidental data loss
- **iCloud Drive Safety**: Added `--force` requirement with prominent warnings about data loss risk
- **Photos iCloud Detection**: Fixed `$HOME` → `$USER_HOME` for CloudDocs path (correct when running under sudo)
- **Summary Double-Counting**: Fixed Photos Library and iCloud Drive appearing in both processed AND skipped lists

#### Medium/Low Fixes
- **POSIX Compatibility**: Fixed `mapfile` command not found error on macOS (Bash 3.2). Replaced with POSIX-compatible `while IFS= read` loop
- **Dry-Run Photos Check**: Photos app running check now logs warning in dry-run mode without blocking space calculation
- **Photos App Auto-Close**: When `--yes` flag is used, script now auto-closes Photos app for safe cleanup
- **Section Numbering**: Fixed incorrect section numbers after .DS_Store was moved to end
- **iCloud Drive Recovery Message**: Fixed incorrect claim that files are "recoverable via Recently Deleted". Files are permanently deleted; local-only files pending upload cannot be recovered
- **Photos Database Safety**: Changed from `pkill -9` (SIGKILL) to graceful shutdown with SIGTERM + 5-second polling loop to prevent SQLite database corruption
- **Path Traversal Protection**: Added validation for `--photos-library` flag to reject path traversal attempts (`/` or `..`)
- **Diagnostic Reports Symlink**: Added symlink check to find commands in Diagnostic Reports section
- **BSD Find Compatibility**: Removed invalid `\! -L` predicate from find commands (not valid in macOS BSD find). Added `|| true` guards to prevent set -e aborts
- **Photos Summary Fix**: Added missing else clause so skipped Photos Library shows in summary
- **Dead Code Removal**: Removed redundant condition in iCloud Drive folder matching
- **Interactive Menu Security**: Replaced `eval` with case statement to prevent potential code injection
- **Photos Library Targeted Cleanup**: Only clear known cache subdirectories (derivatives, renders, caches, proxies), skip cpl/ to preserve iCloud sync state
- **Trash Cleanup**: Removed redundant find command (second -type f -name '.*' was unnecessary)
- **Code Refactoring**: Extracted Photos quit logic to reusable function to eliminate duplication
- **Robustness Improvements**: Improved parsing reliability for df, diskutil, docker, and uptime commands. Added numeric validation to prevent arithmetic errors

### Security & Stability

- **Eval vulnerability fix**: Replaced unsafe `eval` with safer alternatives
- **Symlink attack prevention**: Fixed trash deletion to prevent following malicious symlinks
- **Signal handling**: Graceful interruption handling

### Documentation

- **Complete README overhaul**: Modernized with badges, quick reference cards, categories grid
- **Added**: Quick Reference section, Command Reference tables, Why MacCleans comparison
- **Updated**: All documentation to reference v4.0
- **Danger Zone**: Added iCloud Drive to list of operations requiring `--force`

### Dependencies

- No new dependencies added
- Compatible with macOS 10.15+ (Catalina and later)
- Tested on macOS 26.4
- Compatible with Bash 3.2+ (macOS default)

### Documentation

- **Documentation restructure**: Moved guides to `docs/guides/` folder with new index at `docs/index.md`
- **New COMPARISON.md**: Tool comparison guide added
- **AI transparency**: Added AI assistance badges and acknowledgment
- **Security enhancements**: Expanded security policy with audit instructions
- **macOS 26.4**: Added compatibility badge and testing confirmation

## [3.3.0] - 2026-02-21

### Bug Fixes

- **Trash directory deletion**: Fixed trash cleanup to also delete directories, not just files. On macOS Trash commonly contains folders, so previous implementation left content behind and reported incorrect freed-space.
- **FORCE config propagation**: Fixed FORCE=true in config file to propagate to AUTO_YES, ensuring unattended runs don't block on prompts.

### Added

- **iCloud Photos cache cleanup**: New category to clear locally cached iCloud Photos (frees space while keeping photos in iCloud)
- **iCloud Drive offline files**: New category to remove offline copies of iCloud Drive files (files will re-download on demand)
- New `--skip-icloud-photos` flag
- New `--skip-icloud-drive` flag
- Added iCloud Photos and iCloud Drive to interactive mode selection

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
- `docs/index.md` - Navigation hub for all documentation

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
