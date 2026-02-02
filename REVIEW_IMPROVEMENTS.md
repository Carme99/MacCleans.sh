# MacCleans.sh - Comprehensive Repository Review & Improvement Suggestions

## Executive Summary

MacCleans.sh is a well-designed, production-ready macOS cleanup utility with excellent documentation and user safety features. The codebase is mature (v2.5.0), but there are opportunities to enhance code quality, robustness, user experience, and maintainability.

**Overall Assessment**: ⭐⭐⭐⭐ (4/5)
- Strong foundation with good practices
- Clear documentation and safety-first design
- Room for modernization and enhanced testing

---

## 1. Code Quality & Best Practices

### Issues Identified

1. **No ShellCheck Integration** (Priority: HIGH)
   - Script doesn't follow shellcheck best practices
   - Missing `set -euo pipefail` for safer execution

2. **Code Duplication** (Priority: MEDIUM)
   - Size calculation blocks are repeated 12+ times
   - Cleanup logic patterns are similar across categories

3. **Dependency on `bc`** (Priority: LOW)
   - `bc` may not be available on all systems
   - Bash can handle integer math natively

4. **Hard-coded Paths** (Priority: LOW)
   - Usage examples reference `~/Scripts/` which may not exist

### Recommendations

#### 1.1 Add ShellCheck Integration
```bash
# Add to beginning of script (after shebang)
set -euo pipefail  # Exit on error, undefined vars, pipe failures
```

**Create `.github/workflows/shellcheck.yml`:**
```yaml
name: ShellCheck
on: [push, pull_request]
jobs:
  shellcheck:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run ShellCheck
        uses: ludeeus/action-shellcheck@master
        with:
          scandir: '.'
          severity: warning
```

#### 1.2 Extract Reusable Functions
**Before** (current code - repeated everywhere):
```bash
SPOTIFY_SIZE=$(du -sh "$SPOTIFY_CACHE" 2>/dev/null | awk '{print $1}')
if [ -n "$SPOTIFY_SIZE" ] && [ "$SPOTIFY_SIZE" != "0B" ]; then
    log "Spotify cache: $SPOTIFY_SIZE"
    SPOTIFY_BYTES=$(size_to_bytes "$SPOTIFY_SIZE")
    # ... cleanup logic
fi
```

**After** (refactored):
```bash
# New helper function
cleanup_directory() {
    local dir="$1"
    local name="$2"
    local skip_confirm="${3:-false}"

    if [ ! -d "$dir" ]; then
        log "No $name found"
        return 0
    fi

    local size=$(du -sh "$dir" 2>/dev/null | awk '{print $1}')
    if [ -z "$size" ] || [ "$size" = "0B" ]; then
        log "$name is empty"
        return 0
    fi

    log "$name: $size"
    local bytes=$(size_to_bytes "$size")

    if [ "$DRY_RUN" = true ]; then
        log "Would clear $name: $size"
    else
        if [ "$skip_confirm" = false ]; then
            confirm_action "$name cleanup" || return 0
        fi
        log "Cleaning $name..."
        rm -rf "$dir"/* 2>/dev/null
        log "✓ $name cleared"
    fi

    TOTAL_BYTES_FREED=$((TOTAL_BYTES_FREED + bytes))
}

# Usage
cleanup_directory "$SPOTIFY_CACHE" "Spotify cache" true
```

#### 1.3 Replace `bc` with Bash Arithmetic
```bash
# Replace size_to_bytes function
size_to_bytes() {
    local size=$1
    local number=$(echo "$size" | grep -oE '[0-9.]+')
    local unit=$(echo "$size" | grep -oE '[A-Za-z]+')

    # Convert to integer (bash doesn't handle floats)
    number=${number%.*}

    case $unit in
        K|k|KB|kb) echo $((number * 1024)) ;;
        M|m|MB|mb) echo $((number * 1024 * 1024)) ;;
        G|g|GB|gb) echo $((number * 1024 * 1024 * 1024)) ;;
        *) echo "$number" ;;
    esac
}

# Replace bytes_to_human
bytes_to_human() {
    local bytes=$1
    if [ $bytes -lt 1024 ]; then
        echo "${bytes}B"
    elif [ $bytes -lt 1048576 ]; then
        echo "$((bytes / 1024))K"
    elif [ $bytes -lt 1073741824 ]; then
        echo "$((bytes / 1048576))M"
    else
        echo "$((bytes / 1073741824))G"
    fi
}
```

---

## 2. Error Handling & Robustness

### Issues Identified

1. **No Config File Validation** (Priority: HIGH)
   - Malformed config values could cause unexpected behavior
   - No validation of boolean values or numeric thresholds

2. **Missing Verification** (Priority: MEDIUM)
   - No check if files were actually deleted
   - No validation of available disk space before operations

3. **No Rollback Capability** (Priority: LOW)
   - Can't undo deletions (expected, but could be improved)

### Recommendations

#### 2.1 Add Config File Validation
```bash
# Add after config file loading (line 91)
validate_config() {
    # Validate boolean values
    for var in DRY_RUN AUTO_YES QUIET NO_COLOR SKIP_SNAPSHOTS SKIP_HOMEBREW \
               SKIP_SPOTIFY SKIP_CLAUDE SKIP_XCODE SKIP_BROWSERS SKIP_NPM \
               SKIP_PIP SKIP_TRASH SKIP_DSSTORE; do
        local value="${!var}"
        if [ "$value" != "true" ] && [ "$value" != "false" ]; then
            log_error "Invalid config value for $var: '$value' (must be true or false)"
            exit 1
        fi
    done

    # Validate threshold
    if ! [[ "$THRESHOLD" =~ ^[0-9]+$ ]] || [ "$THRESHOLD" -lt 0 ] || [ "$THRESHOLD" -gt 100 ]; then
        log_error "Invalid THRESHOLD value: '$THRESHOLD' (must be 0-100)"
        exit 1
    fi

    # Check config file permissions (should not be world-writable)
    for config_file in "${CONFIG_FILES[@]}"; do
        if [ -f "$config_file" ]; then
            local perms=$(stat -f "%Lp" "$config_file" 2>/dev/null || stat -c "%a" "$config_file" 2>/dev/null)
            if [ "${perms: -1}" != "0" ] && [ "${perms: -1}" != "4" ]; then
                log_warning "Config file $config_file is world-writable (security risk)"
            fi
            break
        fi
    done
}

validate_config
```

#### 2.2 Add Verification After Deletion
```bash
# Add function to verify cleanup
verify_cleanup() {
    local dir="$1"
    local name="$2"

    if [ -d "$dir" ]; then
        local remaining=$(du -sh "$dir" 2>/dev/null | awk '{print $1}')
        if [ -n "$remaining" ] && [ "$remaining" != "0B" ]; then
            log_warning "$name cleanup incomplete: $remaining remaining"
            return 1
        fi
    fi
    return 0
}
```

#### 2.3 Add System Health Checks
```bash
# Add at the start of script (after getting user info)
perform_system_checks() {
    # Check if system is under heavy load
    local load=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | cut -d. -f1)
    if [ "$load" -gt 10 ]; then
        log_warning "System load is high ($load). Consider running later."
        if [ "$AUTO_YES" = false ]; then
            read -p "Continue anyway? [y/N] " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                exit 0
            fi
        fi
    fi

    # Check if backup is running (Time Machine)
    if tmutil status 2>/dev/null | grep -q "Running = 1"; then
        log_warning "Time Machine backup is running"
        if [ "$AUTO_YES" = false ]; then
            read -p "Continue with cleanup? [y/N] " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                exit 0
            fi
        fi
    fi
}

perform_system_checks
```

---

## 3. Security Considerations

### Issues Identified

1. **No USER/HOME Validation** (Priority: MEDIUM)
   - `SUDO_USER` and `USER_HOME` are used without validation
   - Could be exploited if environment is manipulated

2. **No Download Verification** (Priority: MEDIUM)
   - Direct download installation has no checksum verification

### Recommendations

#### 3.1 Validate User and Home Directory
```bash
# Replace user detection (lines 250-257)
if [ "$EUID" -ne 0 ]; then
    log_always "Error: This script needs sudo privileges."
    log_always "Please run with: sudo ~/Scripts/clean-mac-space.sh [options]"
    exit 1
fi

# Get and validate actual user
if [ -n "$SUDO_USER" ]; then
    ACTUAL_USER="$SUDO_USER"
    USER_HOME=$(eval echo ~$SUDO_USER)
else
    ACTUAL_USER=$(whoami)
    USER_HOME="$HOME"
fi

# Validate user and home directory
if [ -z "$ACTUAL_USER" ] || [ "$ACTUAL_USER" = "root" ]; then
    log_error "Cannot determine actual user (running as root without SUDO_USER)"
    exit 1
fi

if [ ! -d "$USER_HOME" ]; then
    log_error "User home directory does not exist: $USER_HOME"
    exit 1
fi

# Validate home directory is under /Users
if [[ ! "$USER_HOME" =~ ^/Users/ ]]; then
    log_warning "User home directory is not in /Users: $USER_HOME"
    read -p "Continue anyway? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 0
    fi
fi
```

#### 3.2 Add Checksum Verification for Downloads
**Update INSTALL.md with checksums:**
```markdown
## Verified Installation

Download with checksum verification:

```bash
# Download script
curl -o clean-mac-space.sh https://raw.githubusercontent.com/Carme99/MacCleans.sh/main/clean-mac-space.sh

# Verify checksum (replace with actual SHA256)
echo "SHA256_HASH  clean-mac-space.sh" | shasum -a 256 -c -

# Install if verification passes
chmod +x clean-mac-space.sh
sudo mv clean-mac-space.sh /usr/local/bin/clean-mac-space
```
```

**Add release checksums to GitHub releases**

---

## 4. User Experience Enhancements

### Recommendations

#### 4.1 Add Version Flag
```bash
VERSION="2.5.0"

# In argument parsing section
--version|-v)
    echo "MacCleans v$VERSION"
    exit 0
    ;;
```

#### 4.2 Add Progress Indicators
```bash
# Install progress indicator library or create simple spinner
show_progress() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while ps -p $pid > /dev/null 2>&1; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# Usage
log "Cleaning Homebrew cache..."
(brew cleanup -s 2>/dev/null) & show_progress $!
```

#### 4.3 Add Interactive Selection Mode
```bash
# New flag: --interactive or -i
--interactive|-i)
    INTERACTIVE=true
    shift
    ;;

# Interactive selection function
interactive_selection() {
    log_plain "Select categories to clean:"
    log_plain ""

    declare -A categories=(
        ["1"]="Time Machine Snapshots|SKIP_SNAPSHOTS"
        ["2"]="Homebrew Cache|SKIP_HOMEBREW"
        ["3"]="Spotify Cache|SKIP_SPOTIFY"
        ["4"]="Claude Desktop Cache|SKIP_CLAUDE"
        ["5"]="XCode Derived Data|SKIP_XCODE"
        ["6"]="Browser Caches|SKIP_BROWSERS"
        ["7"]="npm/Yarn Cache|SKIP_NPM"
        ["8"]="Python pip Cache|SKIP_PIP"
        ["9"]="Trash Bin|SKIP_TRASH"
        ["10"]=".DS_Store Files|SKIP_DSSTORE"
    )

    for key in $(echo "${!categories[@]}" | tr ' ' '\n' | sort -n); do
        IFS='|' read -r name var <<< "${categories[$key]}"
        local status="[✓]"
        [ "${!var}" = true ] && status="[ ]"
        log_plain "  $status $key. $name"
    done

    log_plain ""
    read -p "Enter numbers to toggle (space-separated), or 'all', or 'done': " selection
    # ... implement toggle logic
}
```

#### 4.4 Enhanced Summary Report
```bash
# At end of script, replace summary section
print_detailed_summary() {
    log_plain "================================================"
    log_plain "Cleanup Summary"
    log_plain "================================================"
    log_plain ""

    # Categories processed
    log_plain "Categories processed:"
    [ "$SKIP_SNAPSHOTS" = false ] && log_plain "  ✓ Time Machine Snapshots"
    [ "$SKIP_HOMEBREW" = false ] && log_plain "  ✓ Homebrew Cache"
    # ... list all categories

    log_plain ""

    # Categories skipped
    local skipped=false
    [ "$SKIP_SNAPSHOTS" = true ] && skipped=true
    if [ "$skipped" = true ]; then
        log_plain "Categories skipped:"
        [ "$SKIP_SNAPSHOTS" = true ] && log_plain "  ⊘ Time Machine Snapshots"
        # ... list skipped
    fi

    log_plain ""
    log_plain "Disk usage:"
    log_plain "  Before: ${DISK_USAGE}% (${DISK_USED} used, ${DISK_AVAIL} available)"
    log_plain "  After:  ${DISK_USAGE_AFTER}% (${DISK_USED_AFTER} used, ${DISK_AVAIL_AFTER} available)"

    if [ $TOTAL_BYTES_FREED -gt 0 ]; then
        HUMAN_FREED=$(bytes_to_human $TOTAL_BYTES_FREED)
        log_plain "  Freed:  $HUMAN_FREED"
    fi
}
```

---

## 5. Testing & CI/CD

### Current State
- No automated testing
- No CI/CD pipeline
- Manual releases

### Recommendations

#### 5.1 Add Unit Tests with BATS
**Create `tests/test_basic.bats`:**
```bash
#!/usr/bin/env bats

@test "script exists and is executable" {
    [ -x clean-mac-space.sh ]
}

@test "help flag works" {
    run ./clean-mac-space.sh --help
    [ "$status" -eq 0 ]
}

@test "dry-run mode doesn't delete files" {
    # Create test cache
    mkdir -p /tmp/test-cache
    echo "test" > /tmp/test-cache/test.txt

    # Run in dry-run
    run sudo ./clean-mac-space.sh --dry-run

    # File should still exist
    [ -f /tmp/test-cache/test.txt ]
    rm -rf /tmp/test-cache
}

@test "invalid threshold is rejected" {
    run ./clean-mac-space.sh --threshold 150
    [ "$status" -ne 0 ]
}

@test "size_to_bytes function works correctly" {
    source clean-mac-space.sh
    result=$(size_to_bytes "1G")
    [ "$result" -eq 1073741824 ]
}
```

**Create `tests/test_functions.bats`:**
```bash
#!/usr/bin/env bats

setup() {
    source clean-mac-space.sh
}

@test "bytes_to_human converts KB correctly" {
    result=$(bytes_to_human 2048)
    [ "$result" = "2K" ]
}

@test "bytes_to_human converts MB correctly" {
    result=$(bytes_to_human 5242880)
    [ "$result" = "5M" ]
}

@test "bytes_to_human converts GB correctly" {
    result=$(bytes_to_human 1073741824)
    [ "$result" = "1G" ]
}
```

#### 5.2 GitHub Actions CI/CD Pipeline
**Create `.github/workflows/ci.yml`:**
```yaml
name: CI

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  shellcheck:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Run ShellCheck
        uses: ludeeus/action-shellcheck@master
        with:
          scandir: '.'
          severity: warning

  tests:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3

      - name: Install BATS
        run: brew install bats-core

      - name: Run tests
        run: bats tests/

  integration:
    runs-on: macos-latest
    needs: [shellcheck, tests]
    steps:
      - uses: actions/checkout@v3

      - name: Make executable
        run: chmod +x clean-mac-space.sh

      - name: Test dry-run
        run: sudo ./clean-mac-space.sh --dry-run --yes

      - name: Test with skip flags
        run: sudo ./clean-mac-space.sh --dry-run --yes --skip-xcode --skip-npm
```

**Create `.github/workflows/release.yml`:**
```yaml
name: Release

on:
  push:
    tags:
      - 'v*'

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Create checksums
        run: |
          sha256sum clean-mac-space.sh > checksums.txt

      - name: Create Release
        uses: softprops/action-gh-release@v1
        with:
          files: |
            clean-mac-space.sh
            checksums.txt
            maccleans.conf.example
          body_path: CHANGELOG.md
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

---

## 6. Additional Features

### 6.1 Docker Cache Cleanup
```bash
###############################################################################
# 13. Docker Cache
###############################################################################
if [ "$SKIP_DOCKER" = false ]; then
    log_plain "================================================"
    log "13. Docker Cache"
    log_plain "================================================"

    if command -v docker &> /dev/null; then
        # Get docker disk usage
        DOCKER_SIZE=$(docker system df -v 2>/dev/null | grep "Total" | awk '{print $4}')

        if [ -n "$DOCKER_SIZE" ] && [ "$DOCKER_SIZE" != "0B" ]; then
            log "Docker cache: $DOCKER_SIZE"
            DOCKER_BYTES=$(size_to_bytes "$DOCKER_SIZE")

            if [ "$DRY_RUN" = true ]; then
                log "Would clean Docker cache: $DOCKER_SIZE"
                TOTAL_BYTES_FREED=$((TOTAL_BYTES_FREED + DOCKER_BYTES))
            else
                log "Cleaning Docker cache..."
                # Remove dangling images, stopped containers, unused networks
                docker system prune -af --volumes 2>/dev/null
                log "✓ Docker cache cleared"
                TOTAL_BYTES_FREED=$((TOTAL_BYTES_FREED + DOCKER_BYTES))
            fi
        else
            log "Docker cache is empty"
        fi
    else
        log "Docker not installed, skipping"
    fi
    log_plain ""
fi
```

### 6.2 iOS Simulator Data
```bash
###############################################################################
# 14. iOS Simulator Data
###############################################################################
if [ "$SKIP_SIMULATOR" = false ]; then
    log_plain "================================================"
    log "14. iOS Simulator Data"
    log_plain "================================================"

    SIMULATOR_DIR="$USER_HOME/Library/Developer/CoreSimulator"
    if [ -d "$SIMULATOR_DIR" ]; then
        SIM_SIZE=$(du -sh "$SIMULATOR_DIR" 2>/dev/null | awk '{print $1}')

        if [ -n "$SIM_SIZE" ] && [ "$SIM_SIZE" != "0B" ]; then
            log "iOS Simulator data: $SIM_SIZE"
            SIM_BYTES=$(size_to_bytes "$SIM_SIZE")

            if [ "$DRY_RUN" = true ]; then
                log "Would clean iOS Simulator data: $SIM_SIZE"
                TOTAL_BYTES_FREED=$((TOTAL_BYTES_FREED + SIM_BYTES))
            else
                log "Cleaning iOS Simulator data..."
                xcrun simctl delete unavailable 2>/dev/null
                xcrun simctl erase all 2>/dev/null
                log "✓ iOS Simulator data cleared"
                TOTAL_BYTES_FREED=$((TOTAL_BYTES_FREED + SIM_BYTES))
            fi
        else
            log "iOS Simulator data is empty"
        fi
    else
        log "iOS Simulator not found"
    fi
    log_plain ""
fi
```

### 6.3 Large Files Finder
```bash
# New flag: --find-large
--find-large)
    FIND_LARGE=true
    LARGE_FILE_SIZE="${2:-1G}"  # Default 1GB
    shift 2
    ;;

# Implementation
if [ "$FIND_LARGE" = true ]; then
    log_plain "================================================"
    log "Finding Large Files (>${LARGE_FILE_SIZE})"
    log_plain "================================================"

    log "Searching for files larger than $LARGE_FILE_SIZE..."
    find "$USER_HOME" -type f -size +$LARGE_FILE_SIZE 2>/dev/null | \
        while read -r file; do
            size=$(du -h "$file" 2>/dev/null | awk '{print $1}')
            log_plain "  $size - $file"
        done
    log_plain ""
fi
```

### 6.4 Configuration Profiles
```bash
# New flag: --profile
--profile)
    PROFILE="$2"
    shift 2
    ;;

# Load profile
load_profile() {
    case "$PROFILE" in
        conservative)
            SKIP_XCODE=true
            SKIP_NPM=true
            SKIP_PIP=true
            SKIP_BROWSERS=true
            SKIP_DOCKER=true
            ;;
        developer)
            SKIP_XCODE=true
            ;;
        aggressive)
            # Clean everything
            ;;
        minimal)
            SKIP_XCODE=true
            SKIP_NPM=true
            SKIP_PIP=true
            SKIP_BROWSERS=true
            SKIP_DOCKER=true
            SKIP_SPOTIFY=true
            SKIP_CLAUDE=true
            ;;
        *)
            log_error "Unknown profile: $PROFILE"
            exit 1
            ;;
    esac
}

[ -n "$PROFILE" ] && load_profile
```

---

## 7. Documentation Improvements

### 7.1 Add CONTRIBUTING.md
```markdown
# Contributing to MacCleans

## Development Setup

1. Fork the repository
2. Clone your fork
3. Create a feature branch
4. Install development dependencies:
   ```bash
   brew install bats-core shellcheck
   ```

## Running Tests

```bash
# Run shellcheck
shellcheck clean-mac-space.sh

# Run unit tests
bats tests/

# Test locally
sudo ./clean-mac-space.sh --dry-run
```

## Code Style

- Use 4-space indentation
- Follow shellcheck recommendations
- Add comments for complex logic
- Keep functions under 50 lines

## Submitting Changes

1. Write tests for new features
2. Ensure all tests pass
3. Update documentation
4. Update CHANGELOG.md
5. Submit a pull request

## Adding New Cleanup Categories

Template for new categories:

```bash
###############################################################################
# N. Category Name
###############################################################################
if [ "$SKIP_CATEGORY" = false ]; then
    log_plain "================================================"
    log "N. Category Name"
    log_plain "================================================"

    # Implementation here

    log_plain ""
fi
```
```

### 7.2 Add FAQ Section to README
```markdown
## Frequently Asked Questions

### Q: Is it safe to run this script?
A: Yes. The script only removes cache and temporary files that macOS can regenerate. It never touches user documents, application settings, or system critical files.

### Q: How often should I run this?
A: Depends on your usage:
- Heavy developers: Weekly
- Regular users: Monthly
- Light users: Quarterly

### Q: Will this break my applications?
A: No. Applications may need to rebuild caches (slower first launch) but won't break.

### Q: Can I undo the cleanup?
A: No. Deleted files cannot be recovered. Always use `--dry-run` first to preview.

### Q: Why does it need sudo?
A: To access system cache directories and Time Machine snapshots that require elevated privileges.

### Q: Does this work on Apple Silicon Macs?
A: Yes, fully compatible with both Intel and Apple Silicon Macs.

### Q: How much space will I recover?
A: Typically 10-70GB depending on:
- Whether you use XCode (5-50GB)
- Browser usage (1-5GB)
- Development tools (npm, pip, docker: 5-15GB)
```

### 7.3 Add Architecture Documentation
**Create `ARCHITECTURE.md`:**
```markdown
# MacCleans Architecture

## Script Structure

```
clean-mac-space.sh
├── Header & Documentation (lines 1-37)
├── Configuration Loading (lines 39-91)
│   ├── Default values
│   ├── Config file parsing
│   └── Environment variable support
├── Argument Parsing (lines 94-166)
├── Utility Functions (lines 168-241)
│   ├── Color definitions
│   ├── Logging functions
│   └── Size conversion functions
├── System Checks (lines 243-286)
│   ├── Sudo verification
│   ├── User detection
│   └── Disk usage check
├── Cleanup Modules (lines 307-806)
│   ├── 12 independent cleanup categories
│   └── Each with preview & execution modes
└── Summary & Reporting (lines 809-854)
```

## Design Principles

1. **Safety First**: Never touch user data
2. **Preview Mode**: Always allow dry-run
3. **Granular Control**: Individual skip flags per category
4. **Clear Feedback**: Color-coded output with detailed reporting
5. **Automation-Friendly**: Quiet mode and threshold-based execution

## Data Flow

```
User Input → Config Loading → Validation → System Checks → Cleanup Modules → Summary
     ↓           ↓                ↓              ↓                ↓             ↓
  CLI Args   ~/.maccleans.conf  Parse &      Sudo/Disk      Execute each    Calculate
                                 Validate     checks         category        space freed
```

## Error Handling Strategy

- Non-critical errors: Log warning, continue
- Critical errors: Log error, exit with non-zero
- All file operations: Suppress stderr (2>/dev/null)
- Validation: Fail fast on invalid config

## Extension Points

To add a new cleanup category:

1. Add `SKIP_CATEGORY` flag (line 54)
2. Add config parsing (line 86)
3. Add argument parsing (line 155)
4. Implement cleanup module (line 806)
5. Update documentation (README.md)
```

---

## 8. Distribution & Installation Improvements

### 8.1 Create Homebrew Formula
**Create `homebrew/maccleans.rb`:**
```ruby
class Maccleans < Formula
  desc "Comprehensive macOS disk cleanup utility"
  homepage "https://github.com/Carme99/MacCleans.sh"
  url "https://github.com/Carme99/MacCleans.sh/archive/v2.5.0.tar.gz"
  sha256 "SHA256_CHECKSUM_HERE"
  license "MIT"

  def install
    bin.install "clean-mac-space.sh" => "maccleans"
    doc.install "README.md", "INSTALL.md", "CHANGELOG.md"
    (prefix/"etc").install "maccleans.conf.example"
  end

  def caveats
    <<~EOS
      MacCleans requires sudo to run:
        sudo maccleans --dry-run

      Example configuration:
        cp #{prefix}/etc/maccleans.conf.example ~/.maccleans.conf
    EOS
  end

  test do
    system "#{bin}/maccleans", "--help"
  end
end
```

**Update README.md:**
```markdown
## Installation

### Homebrew (Recommended)
```bash
brew tap Carme99/maccleans
brew install maccleans

# Run
sudo maccleans --dry-run
```

### Direct Download
```bash
curl -o /usr/local/bin/maccleans https://raw.githubusercontent.com/Carme99/MacCleans.sh/main/clean-mac-space.sh
chmod +x /usr/local/bin/maccleans
```
```

### 8.2 Add Auto-Update Feature
```bash
# New flag: --update
--update)
    update_script
    exit 0
    ;;

# Update function
update_script() {
    log "Checking for updates..."

    # Get latest version from GitHub
    LATEST_VERSION=$(curl -s https://api.github.com/repos/Carme99/MacCleans.sh/releases/latest | \
        grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/')

    if [ -z "$LATEST_VERSION" ]; then
        log_error "Failed to check for updates"
        return 1
    fi

    if [ "$VERSION" = "$LATEST_VERSION" ]; then
        log_success "Already up to date (v$VERSION)"
        return 0
    fi

    log "New version available: v$LATEST_VERSION (current: v$VERSION)"
    read -p "Update now? [y/N] " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        SCRIPT_PATH=$(realpath "$0")
        TEMP_FILE=$(mktemp)

        log "Downloading latest version..."
        if curl -sL "https://raw.githubusercontent.com/Carme99/MacCleans.sh/main/clean-mac-space.sh" -o "$TEMP_FILE"; then
            chmod +x "$TEMP_FILE"
            sudo mv "$TEMP_FILE" "$SCRIPT_PATH"
            log_success "Updated to v$LATEST_VERSION"
        else
            log_error "Update failed"
            rm -f "$TEMP_FILE"
            return 1
        fi
    fi
}
```

---

## 9. Priority Implementation Roadmap

### Phase 1: Critical Improvements (Week 1-2)
1. ✅ Add ShellCheck integration and fix warnings
2. ✅ Implement config validation
3. ✅ Add version flag
4. ✅ Create CONTRIBUTING.md
5. ✅ Set up GitHub Actions CI/CD

### Phase 2: Code Quality (Week 3-4)
1. ✅ Refactor duplicate code into functions
2. ✅ Replace `bc` with bash arithmetic
3. ✅ Add unit tests with BATS
4. ✅ Improve error handling

### Phase 3: Features (Week 5-6)
1. ✅ Add Docker cache cleanup
2. ✅ Add iOS Simulator cleanup
3. ✅ Implement interactive mode
4. ✅ Add configuration profiles
5. ✅ Enhanced summary report

### Phase 4: Distribution (Week 7-8)
1. ✅ Create Homebrew formula
2. ✅ Add auto-update feature
3. ✅ Implement checksum verification
4. ✅ Create signed releases

### Phase 5: Documentation (Week 9-10)
1. ✅ Add FAQ section
2. ✅ Create ARCHITECTURE.md
3. ✅ Add screenshots/GIFs
4. ✅ Expand troubleshooting guide

---

## 10. Long-term Vision

### Potential Future Enhancements

1. **Web Dashboard**: Real-time disk usage monitoring
2. **GUI Application**: Native macOS app with SwiftUI
3. **Machine Learning**: Predict optimal cleanup schedule
4. **Cloud Sync**: Sync configurations across multiple Macs
5. **Notification Center**: macOS notifications for cleanups
6. **Backup Integration**: Optional backup before deletion
7. **Performance Metrics**: Track cleanup history and trends
8. **Plugin System**: Allow third-party cleanup modules

---

## Conclusion

MacCleans.sh is a solid, production-ready tool with excellent potential for growth. The suggested improvements focus on:

1. **Maintainability**: Better code structure, testing, CI/CD
2. **Robustness**: Enhanced error handling and validation
3. **User Experience**: More features, better feedback
4. **Distribution**: Easier installation and updates

### Quick Wins (Implement First)
- ✅ Add `--version` flag
- ✅ Add ShellCheck to CI
- ✅ Implement config validation
- ✅ Create Homebrew formula
- ✅ Add Docker cleanup

### High Impact (Medium Effort)
- ✅ Refactor duplicate code
- ✅ Add unit tests
- ✅ Interactive selection mode
- ✅ Auto-update feature

### Nice to Have (Long-term)
- Web dashboard
- GUI application
- Plugin system

---

**Generated**: 2026-02-02
**Reviewer**: Claude (Anthropic)
**Repository**: https://github.com/Carme99/MacCleans.sh
