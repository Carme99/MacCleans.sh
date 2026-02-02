#!/bin/bash

# Enable strict error handling
set -euo pipefail

VERSION="3.0.0"

###############################################################################
# Mac Space Cleanup Script
# Purpose: Free up space on small SSDs by cleaning safe cache/temp files
# Safe: Does not touch Safari, browser sessions, or critical user data
#
# Usage:
#   sudo ~/Scripts/clean-mac-space.sh                    # Interactive cleanup
#   sudo ~/Scripts/clean-mac-space.sh --dry-run          # Preview only
#   sudo ~/Scripts/clean-mac-space.sh --yes              # Skip confirmation
#   sudo ~/Scripts/clean-mac-space.sh --quiet            # Minimal output
#   sudo ~/Scripts/clean-mac-space.sh --threshold 85     # Only run if disk >85%
#   sudo ~/Scripts/clean-mac-space.sh --skip-spotify     # Skip Spotify cache
#   sudo ~/Scripts/clean-mac-space.sh --skip-homebrew    # Skip Homebrew cleanup
#   sudo ~/Scripts/clean-mac-space.sh --interactive      # Interactive category selection
#   sudo ~/Scripts/clean-mac-space.sh --profile developer # Use preset profile
#
# Configuration:
#   Settings can be saved in ~/.maccleans.conf or ~/.config/maccleans/config
#   Command line arguments will override config file settings
#
# Options:
#   --dry-run, -n       Preview what would be cleaned without deleting
#   --yes, -y           Skip confirmation prompt
#   --quiet, -q         Minimal output (useful for cron)
#   --no-color          Disable colored output
#   --version, -v       Display version information
#   --threshold N       Only run if disk usage is above N% (default: 0)
#   --interactive, -i   Interactive category selection mode
#   --profile NAME      Use preset profile (conservative, developer, aggressive, minimal)
#   --skip-snapshots    Skip Time Machine snapshot deletion
#   --skip-homebrew     Skip Homebrew cache cleanup
#   --skip-spotify      Skip Spotify cache cleanup
#   --skip-claude       Skip Claude Desktop cache cleanup
#   --skip-xcode        Skip XCode derived data cleanup
#   --skip-browsers     Skip browser cache cleanup (Chrome, Firefox, Edge)
#   --skip-npm          Skip npm/yarn cache cleanup
#   --skip-pip          Skip Python pip cache cleanup
#   --skip-trash        Skip emptying trash bin
#   --skip-dsstore      Skip .DS_Store file cleanup
#   --skip-docker       Skip Docker cache cleanup
#   --skip-simulator    Skip iOS Simulator data cleanup
#   --skip-mail         Skip Mail app cache cleanup
###############################################################################

# Default options
DRY_RUN=false
AUTO_YES=false
QUIET=false
NO_COLOR=false
INTERACTIVE=false
PROFILE=""
THRESHOLD=0
SKIP_SNAPSHOTS=false
SKIP_HOMEBREW=false
SKIP_SPOTIFY=false
SKIP_CLAUDE=false
SKIP_XCODE=false
SKIP_BROWSERS=false
SKIP_NPM=false
SKIP_PIP=false
SKIP_TRASH=false
SKIP_DSSTORE=false
SKIP_DOCKER=false
SKIP_SIMULATOR=false
SKIP_MAIL=false

# Configuration file locations (checked in order)
CONFIG_FILES=(
    "$HOME/.maccleans.conf"
    "$HOME/.config/maccleans/config"
    "${XDG_CONFIG_HOME:-$HOME/.config}/maccleans/config"
)

###############################################################################
# Helper Functions
###############################################################################

# Validate boolean value
validate_boolean() {
    local value="$1"
    if [ "$value" != "true" ] && [ "$value" != "false" ]; then
        return 1
    fi
    return 0
}

# Validate numeric value in range
validate_numeric() {
    local value="$1"
    local min="$2"
    local max="$3"

    if ! [[ "$value" =~ ^[0-9]+$ ]]; then
        return 1
    fi

    if [ "$value" -lt "$min" ] || [ "$value" -gt "$max" ]; then
        return 1
    fi

    return 0
}

# Validate configuration values
validate_config() {
    local errors=0

    # Validate boolean values
    for var in DRY_RUN AUTO_YES QUIET NO_COLOR SKIP_SNAPSHOTS SKIP_HOMEBREW \
               SKIP_SPOTIFY SKIP_CLAUDE SKIP_XCODE SKIP_BROWSERS SKIP_NPM \
               SKIP_PIP SKIP_TRASH SKIP_DSSTORE SKIP_DOCKER SKIP_SIMULATOR SKIP_MAIL; do
        local value="${!var}"
        if ! validate_boolean "$value"; then
            echo "ERROR: Invalid config value for $var: '$value' (must be true or false)" >&2
            errors=$((errors + 1))
        fi
    done

    # Validate threshold
    if ! validate_numeric "$THRESHOLD" 0 100; then
        echo "ERROR: Invalid THRESHOLD value: '$THRESHOLD' (must be 0-100)" >&2
        errors=$((errors + 1))
    fi

    if [ $errors -gt 0 ]; then
        echo "ERROR: Configuration validation failed with $errors error(s)" >&2
        exit 1
    fi

    return 0
}

# Load and parse configuration file
load_config_file() {
    for config_file in "${CONFIG_FILES[@]}"; do
        if [ -f "$config_file" ]; then
            while IFS='=' read -r key value 2>/dev/null || [ -n "$key" ]; do
                # Skip comments and empty lines
                [[ "$key" =~ ^[[:space:]]*# ]] && continue
                [[ -z "$key" ]] && continue

                # Trim whitespace
                key=$(echo "$key" | xargs)
                value=$(echo "$value" | xargs)

                case "$key" in
                    DRY_RUN) DRY_RUN="$value" ;;
                    AUTO_YES) AUTO_YES="$value" ;;
                    QUIET) QUIET="$value" ;;
                    NO_COLOR) NO_COLOR="$value" ;;
                    THRESHOLD) THRESHOLD="$value" ;;
                    SKIP_SNAPSHOTS) SKIP_SNAPSHOTS="$value" ;;
                    SKIP_HOMEBREW) SKIP_HOMEBREW="$value" ;;
                    SKIP_SPOTIFY) SKIP_SPOTIFY="$value" ;;
                    SKIP_CLAUDE) SKIP_CLAUDE="$value" ;;
                    SKIP_XCODE) SKIP_XCODE="$value" ;;
                    SKIP_BROWSERS) SKIP_BROWSERS="$value" ;;
                    SKIP_NPM) SKIP_NPM="$value" ;;
                    SKIP_PIP) SKIP_PIP="$value" ;;
                    SKIP_TRASH) SKIP_TRASH="$value" ;;
                    SKIP_DSSTORE) SKIP_DSSTORE="$value" ;;
                    SKIP_DOCKER) SKIP_DOCKER="$value" ;;
                    SKIP_SIMULATOR) SKIP_SIMULATOR="$value" ;;
                    SKIP_MAIL) SKIP_MAIL="$value" ;;
                esac
            done < "$config_file"
            break
        fi
    done
}

# Load configuration
load_config_file

# Parse command-line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --dry-run|-n)
                DRY_RUN=true
                shift
                ;;
            --yes|-y)
                AUTO_YES=true
                shift
                ;;
            --quiet|-q)
                QUIET=true
                shift
                ;;
            --no-color)
                NO_COLOR=true
                shift
                ;;
            --version|-v)
                echo "MacCleans v$VERSION"
                exit 0
                ;;
            --interactive|-i)
                INTERACTIVE=true
                shift
                ;;
            --profile)
                if [ -z "${2:-}" ]; then
                    echo "ERROR: --profile requires an argument (conservative, developer, aggressive, minimal)" >&2
                    exit 1
                fi
                PROFILE="$2"
                shift 2
                ;;
            --threshold)
                if [ -z "${2:-}" ]; then
                    echo "ERROR: --threshold requires a numeric argument (0-100)" >&2
                    exit 1
                fi
                THRESHOLD="$2"
                shift 2
                ;;
            --skip-snapshots)
                SKIP_SNAPSHOTS=true
                shift
                ;;
            --skip-homebrew)
                SKIP_HOMEBREW=true
                shift
                ;;
            --skip-spotify)
                SKIP_SPOTIFY=true
                shift
                ;;
            --skip-claude)
                SKIP_CLAUDE=true
                shift
                ;;
            --skip-xcode)
                SKIP_XCODE=true
                shift
                ;;
            --skip-browsers)
                SKIP_BROWSERS=true
                shift
                ;;
            --skip-npm)
                SKIP_NPM=true
                shift
                ;;
            --skip-pip)
                SKIP_PIP=true
                shift
                ;;
            --skip-trash)
                SKIP_TRASH=true
                shift
                ;;
            --skip-dsstore)
                SKIP_DSSTORE=true
                shift
                ;;
            --skip-docker)
                SKIP_DOCKER=true
                shift
                ;;
            --skip-simulator)
                SKIP_SIMULATOR=true
                shift
                ;;
            --skip-mail)
                SKIP_MAIL=true
                shift
                ;;
            --help|-h)
                head -n 50 "$0" | tail -n +3 | sed 's/^# //'
                exit 0
                ;;
            *)
                echo "ERROR: Unknown option: $1" >&2
                echo "Use --help for usage information" >&2
                exit 1
                ;;
        esac
    done
}

# Parse arguments
parse_arguments "$@"

# Validate configuration after loading and parsing
validate_config

# Color definitions
if [ "$NO_COLOR" = true ] || [ ! -t 1 ]; then
    RED="" GREEN="" YELLOW="" BLUE="" MAGENTA="" CYAN="" BOLD="" DIM="" NC=""
else
    RED='\033[0;31m' GREEN='\033[0;32m' YELLOW='\033[1;33m'
    BLUE='\033[0;34m' MAGENTA='\033[0;35m' CYAN='\033[0;36m'
    BOLD='\033[1m' DIM='\033[2m' NC='\033[0m'
fi

# Function to log with timestamp
log() {
    if [ "$QUIET" = false ]; then
        echo -e "${DIM}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
    fi
}

# Function to log without timestamp
log_plain() {
    if [ "$QUIET" = false ]; then
        echo -e "$1"
    fi
}

# Function to always log (even in quiet mode)
log_always() {
    echo -e "$1"
}

# Function to log success
log_success() {
    if [ "$QUIET" = false ]; then
        echo -e "${GREEN}✓${NC} $1"
    fi
}

# Function to log warning
log_warning() {
    if [ "$QUIET" = false ]; then
        echo -e "${YELLOW}⚠${NC} $1"
    fi
}

# Function to log error
log_error() {
    echo -e "${RED}✗${NC} $1" >&2
}

# Function to convert human-readable size to bytes
size_to_bytes() {
    local size=$1
    local number=$(echo "$size" | grep -oE '[0-9.]+' || echo "0")
    local unit=$(echo "$size" | grep -oE '[A-Za-z]+' || echo "B")

    # Convert to integer (bash doesn't handle floats)
    number=${number%.*}

    case $unit in
        K|k|KB|kb) echo $((number * 1024)) ;;
        M|m|MB|mb) echo $((number * 1024 * 1024)) ;;
        G|g|GB|gb) echo $((number * 1024 * 1024 * 1024)) ;;
        T|t|TB|tb) echo $((number * 1024 * 1024 * 1024 * 1024)) ;;
        *) echo "$number" ;;
    esac
}

# Function to convert bytes to human-readable
bytes_to_human() {
    local bytes=$1
    if [ "$bytes" -lt 1024 ]; then
        echo "${bytes}B"
    elif [ "$bytes" -lt 1048576 ]; then
        echo "$((bytes / 1024))K"
    elif [ "$bytes" -lt 1073741824 ]; then
        echo "$((bytes / 1048576))M"
    elif [ "$bytes" -lt 1099511627776 ]; then
        echo "$(awk "BEGIN {printf \"%.2f\", $bytes / 1073741824}")G"
    else
        echo "$(awk "BEGIN {printf \"%.2f\", $bytes / 1099511627776}")T"
    fi
}

###############################################################################
# System Validation and Health Checks
###############################################################################

# Check if running with sudo
if [ "$EUID" -ne 0 ]; then
    log_error "This script requires sudo privileges."
    log_always "Please run with: sudo $0 [options]"
    exit 1
fi

# Get and validate actual user
if [ -n "${SUDO_USER:-}" ]; then
    ACTUAL_USER="$SUDO_USER"
    USER_HOME=$(eval echo "~$SUDO_USER")
else
    ACTUAL_USER=$(whoami)
    USER_HOME="$HOME"
fi

# Validate user
if [ -z "$ACTUAL_USER" ] || [ "$ACTUAL_USER" = "root" ]; then
    log_error "Cannot determine actual user (running as root without SUDO_USER)"
    log_always "This script should be run with sudo, not as root directly"
    exit 1
fi

# Validate home directory exists
if [ ! -d "$USER_HOME" ]; then
    log_error "User home directory does not exist: $USER_HOME"
    exit 1
fi

# Validate home directory is under /Users (typical macOS path)
if [[ ! "$USER_HOME" =~ ^/Users/ ]] && [[ ! "$USER_HOME" =~ ^/home/ ]]; then
    log_warning "User home directory is not in standard location: $USER_HOME"
    if [ "$AUTO_YES" = false ] && [ "$QUIET" = false ]; then
        read -p "Continue anyway? [y/N] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_always "Aborted by user"
            exit 0
        fi
    fi
fi

# System health checks
perform_health_checks() {
    local warnings=0

    # Check system load (if uptime available)
    if command -v uptime &> /dev/null; then
        local load_avg=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | cut -d. -f1 || echo "0")
        if [ "$load_avg" -gt 10 ]; then
            log_warning "System load is high ($load_avg). Performance may be impacted."
            warnings=$((warnings + 1))
        fi
    fi

    # Check if Time Machine backup is running
    if command -v tmutil &> /dev/null; then
        if tmutil status 2>/dev/null | grep -q "Running = 1"; then
            log_warning "Time Machine backup is currently running"
            warnings=$((warnings + 1))
        fi
    fi

    # If warnings and not auto-yes, ask for confirmation
    if [ $warnings -gt 0 ] && [ "$AUTO_YES" = false ] && [ "$QUIET" = false ]; then
        log_plain ""
        read -p "System warnings detected. Continue anyway? [y/N] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_always "Aborted by user"
            exit 0
        fi
    fi
}

###############################################################################
# Profile Loading
###############################################################################

load_profile() {
    case "$PROFILE" in
        conservative)
            log "Loading conservative profile (skipping development caches)"
            SKIP_XCODE=true
            SKIP_NPM=true
            SKIP_PIP=true
            SKIP_BROWSERS=true
            SKIP_DOCKER=true
            SKIP_SIMULATOR=true
            ;;
        developer)
            log "Loading developer profile (skipping only XCode)"
            SKIP_XCODE=true
            ;;
        aggressive)
            log "Loading aggressive profile (cleaning everything)"
            # Clean everything - no skips
            ;;
        minimal)
            log "Loading minimal profile (only safe system caches)"
            SKIP_XCODE=true
            SKIP_NPM=true
            SKIP_PIP=true
            SKIP_BROWSERS=true
            SKIP_DOCKER=true
            SKIP_SPOTIFY=true
            SKIP_CLAUDE=true
            SKIP_SIMULATOR=true
            SKIP_MAIL=true
            ;;
        "")
            # No profile specified
            ;;
        *)
            log_error "Unknown profile: $PROFILE"
            log_always "Valid profiles: conservative, developer, aggressive, minimal"
            exit 1
            ;;
    esac
}

###############################################################################
# Interactive Selection Mode
###############################################################################

interactive_selection() {
    log_plain ""
    log_plain "${BOLD}Interactive Category Selection${NC}"
    log_plain "================================================"
    log_plain ""
    log_plain "Select categories to clean (toggle with number):"
    log_plain ""

    while true; do
        # Display menu with current state
        local status

        status="[${GREEN}✓${NC}]"; [ "$SKIP_SNAPSHOTS" = true ] && status="[ ]"
        log_plain "  $status  1. Time Machine Snapshots"

        status="[${GREEN}✓${NC}]"; [ "$SKIP_HOMEBREW" = true ] && status="[ ]"
        log_plain "  $status  2. Homebrew Cache"

        status="[${GREEN}✓${NC}]"; [ "$SKIP_SPOTIFY" = true ] && status="[ ]"
        log_plain "  $status  3. Spotify Cache"

        status="[${GREEN}✓${NC}]"; [ "$SKIP_CLAUDE" = true ] && status="[ ]"
        log_plain "  $status  4. Claude Desktop Cache"

        status="[${GREEN}✓${NC}]"; [ "$SKIP_XCODE" = true ] && status="[ ]"
        log_plain "  $status  5. XCode Derived Data"

        status="[${GREEN}✓${NC}]"; [ "$SKIP_BROWSERS" = true ] && status="[ ]"
        log_plain "  $status  6. Browser Caches (Chrome, Firefox, Edge)"

        status="[${GREEN}✓${NC}]"; [ "$SKIP_NPM" = true ] && status="[ ]"
        log_plain "  $status  7. npm/Yarn Cache"

        status="[${GREEN}✓${NC}]"; [ "$SKIP_PIP" = true ] && status="[ ]"
        log_plain "  $status  8. Python pip Cache"

        status="[${GREEN}✓${NC}]"; [ "$SKIP_TRASH" = true ] && status="[ ]"
        log_plain "  $status  9. Trash Bin"

        status="[${GREEN}✓${NC}]"; [ "$SKIP_DSSTORE" = true ] && status="[ ]"
        log_plain "  $status 10. .DS_Store Files"

        status="[${GREEN}✓${NC}]"; [ "$SKIP_DOCKER" = true ] && status="[ ]"
        log_plain "  $status 11. Docker Cache"

        status="[${GREEN}✓${NC}]"; [ "$SKIP_SIMULATOR" = true ] && status="[ ]"
        log_plain "  $status 12. iOS Simulator Data"

        status="[${GREEN}✓${NC}]"; [ "$SKIP_MAIL" = true ] && status="[ ]"
        log_plain "  $status 13. Mail App Cache"

        log_plain ""
        log_plain "Enter number to toggle, 'all' to select all, 'none' to deselect all, 'done' to continue:"
        read -r selection

        case "$selection" in
            1) [ "$SKIP_SNAPSHOTS" = true ] && SKIP_SNAPSHOTS=false || SKIP_SNAPSHOTS=true ;;
            2) [ "$SKIP_HOMEBREW" = true ] && SKIP_HOMEBREW=false || SKIP_HOMEBREW=true ;;
            3) [ "$SKIP_SPOTIFY" = true ] && SKIP_SPOTIFY=false || SKIP_SPOTIFY=true ;;
            4) [ "$SKIP_CLAUDE" = true ] && SKIP_CLAUDE=false || SKIP_CLAUDE=true ;;
            5) [ "$SKIP_XCODE" = true ] && SKIP_XCODE=false || SKIP_XCODE=true ;;
            6) [ "$SKIP_BROWSERS" = true ] && SKIP_BROWSERS=false || SKIP_BROWSERS=true ;;
            7) [ "$SKIP_NPM" = true ] && SKIP_NPM=false || SKIP_NPM=true ;;
            8) [ "$SKIP_PIP" = true ] && SKIP_PIP=false || SKIP_PIP=true ;;
            9) [ "$SKIP_TRASH" = true ] && SKIP_TRASH=false || SKIP_TRASH=true ;;
            10) [ "$SKIP_DSSTORE" = true ] && SKIP_DSSTORE=false || SKIP_DSSTORE=true ;;
            11) [ "$SKIP_DOCKER" = true ] && SKIP_DOCKER=false || SKIP_DOCKER=true ;;
            12) [ "$SKIP_SIMULATOR" = true ] && SKIP_SIMULATOR=false || SKIP_SIMULATOR=true ;;
            13) [ "$SKIP_MAIL" = true ] && SKIP_MAIL=false || SKIP_MAIL=true ;;
            all)
                SKIP_SNAPSHOTS=false SKIP_HOMEBREW=false SKIP_SPOTIFY=false SKIP_CLAUDE=false
                SKIP_XCODE=false SKIP_BROWSERS=false SKIP_NPM=false SKIP_PIP=false
                SKIP_TRASH=false SKIP_DSSTORE=false SKIP_DOCKER=false SKIP_SIMULATOR=false
                SKIP_MAIL=false
                ;;
            none)
                SKIP_SNAPSHOTS=true SKIP_HOMEBREW=true SKIP_SPOTIFY=true SKIP_CLAUDE=true
                SKIP_XCODE=true SKIP_BROWSERS=true SKIP_NPM=true SKIP_PIP=true
                SKIP_TRASH=true SKIP_DSSTORE=true SKIP_DOCKER=true SKIP_SIMULATOR=true
                SKIP_MAIL=true
                ;;
            done)
                break
                ;;
            *)
                log_warning "Invalid selection: $selection"
                ;;
        esac

        # Clear screen for next iteration (optional)
        echo ""
        echo "----------------------------------------"
        echo ""
    done

    log_plain ""
}

###############################################################################
# Main Script Execution
###############################################################################

# Print header
log_plain "================================================"
if [ "$DRY_RUN" = true ]; then
    log_plain "Mac Space Cleanup Script v$VERSION (DRY RUN MODE)"
    log_plain "Preview only - no files will be deleted"
else
    log_plain "Mac Space Cleanup Script v$VERSION"
fi
log_plain "================================================"
log_plain ""

# Perform health checks
perform_health_checks

# Load profile if specified
if [ -n "$PROFILE" ]; then
    load_profile
fi

# Interactive selection mode
if [ "$INTERACTIVE" = true ] && [ "$QUIET" = false ]; then
    interactive_selection
fi

# Get initial disk usage
DISK_USAGE=$(df -h / | tail -1 | awk '{print $5}' | sed 's/%//')
DISK_AVAIL=$(df -h / | tail -1 | awk '{print $4}')
DISK_USED=$(df -h / | tail -1 | awk '{print $3}')

log "Running as user: $ACTUAL_USER"
log "Home directory: $USER_HOME"
log_plain ""
log "Current disk usage: ${DISK_USAGE}% (${DISK_USED} used, ${DISK_AVAIL} available)"

# Check threshold
if [ "$THRESHOLD" -gt 0 ] && [ "$DISK_USAGE" -lt "$THRESHOLD" ]; then
    log_always ""
    log_always "Disk usage (${DISK_USAGE}%) is below threshold (${THRESHOLD}%)."
    log_always "No cleanup needed. Exiting."
    exit 0
fi

log_plain ""

# Track total space freed and categories processed
TOTAL_BYTES_FREED=0
declare -a PROCESSED_CATEGORIES=()
declare -a SKIPPED_CATEGORIES=()

# Confirmation prompt (skip in dry-run or if --yes flag)
if [ "$DRY_RUN" = false ] && [ "$AUTO_YES" = false ]; then
    log_plain "This will clean cache files, temporary files, and old logs."
    log_plain "Safari and browser data will NOT be touched."
    log_plain ""
    read -p "Continue with cleanup? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_always "Cleanup cancelled."
        exit 0
    fi
    log_plain ""
fi

###############################################################################
# 1. Time Machine Local Snapshots
###############################################################################
if [ "$SKIP_SNAPSHOTS" = false ]; then
    PROCESSED_CATEGORIES+=("Time Machine Snapshots")
    log_plain "================================================"
    log "1. Time Machine Local Snapshots"
    log_plain "================================================"

    # Check if Time Machine backup is currently running
    TM_RUNNING=$(tmutil status 2>/dev/null | grep -c "Running = 1" || echo "0")
    if [ "$TM_RUNNING" -gt 0 ]; then
        log_warning "Time Machine backup is currently running"
        log "Skipping snapshot deletion for safety"
    else
        SNAPSHOTS=$(tmutil listlocalsnapshots / 2>/dev/null | grep -c "com.apple.TimeMachine" || echo "0")
        if [ "$SNAPSHOTS" -gt 0 ]; then
            log "Found $SNAPSHOTS local snapshot(s)"
            if [ "$DRY_RUN" = true ]; then
                log "Would delete $SNAPSHOTS snapshot(s)"
            else
                log "Deleting snapshots..."
                tmutil deletelocalsnapshots / 2>/dev/null || log_warning "Some snapshots could not be deleted"
                log_success "Local snapshots deleted successfully"
            fi
        else
            log "No local snapshots found"
        fi
    fi
    log_plain ""
else
    SKIPPED_CATEGORIES+=("Time Machine Snapshots")
fi

###############################################################################
# 2. Homebrew Cache
###############################################################################
if [ "$SKIP_HOMEBREW" = false ]; then
    PROCESSED_CATEGORIES+=("Homebrew Cache")
    log_plain "================================================"
    log "2. Homebrew Cache"
    log_plain "================================================"

    if command -v brew &> /dev/null; then
        BREW_CACHE_SIZE=$(du -sh "$USER_HOME/Library/Caches/Homebrew" 2>/dev/null | awk '{print $1}' || echo "0B")

        if [ -n "$BREW_CACHE_SIZE" ] && [ "$BREW_CACHE_SIZE" != "0B" ]; then
            log "Current Homebrew cache: $BREW_CACHE_SIZE"
            BREW_BYTES=$(size_to_bytes "$BREW_CACHE_SIZE")

            if [ "$DRY_RUN" = true ]; then
                log "Would clean Homebrew cache: $BREW_CACHE_SIZE"
                log "Would remove unused dependencies (brew autoremove)"
                TOTAL_BYTES_FREED=$((TOTAL_BYTES_FREED + BREW_BYTES))
            else
                log "Cleaning Homebrew cache..."
                sudo -u "$ACTUAL_USER" brew cleanup -s 2>/dev/null || log_warning "Homebrew cleanup encountered issues"

                log "Removing unused dependencies..."
                sudo -u "$ACTUAL_USER" brew autoremove 2>/dev/null || log_warning "Homebrew autoremove encountered issues"

                log_success "Homebrew cleaned"
                TOTAL_BYTES_FREED=$((TOTAL_BYTES_FREED + BREW_BYTES))
            fi
        else
            log "Homebrew cache is empty"
        fi
    else
        log "Homebrew not installed, skipping"
    fi
    log_plain ""
else
    SKIPPED_CATEGORIES+=("Homebrew Cache")
fi

###############################################################################
# 3. Application Cache Files
###############################################################################
log_plain "================================================"
log "3. Application Cache Files"
log_plain "================================================"

# Spotify cache (safe - will re-download)
if [ "$SKIP_SPOTIFY" = false ]; then
    PROCESSED_CATEGORIES+=("Spotify Cache")
    SPOTIFY_CACHE="$USER_HOME/Library/Caches/com.spotify.client"
    if [ -d "$SPOTIFY_CACHE" ]; then
        SPOTIFY_SIZE=$(du -sh "$SPOTIFY_CACHE" 2>/dev/null | awk '{print $1}' || echo "0B")

        if [ -n "$SPOTIFY_SIZE" ] && [ "$SPOTIFY_SIZE" != "0B" ]; then
            log "Spotify cache: $SPOTIFY_SIZE"
            SPOTIFY_BYTES=$(size_to_bytes "$SPOTIFY_SIZE")

            if [ "$DRY_RUN" = true ]; then
                log "Would clear Spotify cache: $SPOTIFY_SIZE"
                TOTAL_BYTES_FREED=$((TOTAL_BYTES_FREED + SPOTIFY_BYTES))
            else
                log "Cleaning Spotify cache..."
                rm -rf "${SPOTIFY_CACHE:?}"/* 2>/dev/null
                log_success "Spotify cache cleared"
                TOTAL_BYTES_FREED=$((TOTAL_BYTES_FREED + SPOTIFY_BYTES))
            fi
        else
            log "Spotify cache is empty"
        fi
    else
        log "No Spotify cache found"
    fi
else
    SKIPPED_CATEGORIES+=("Spotify Cache")
fi

# Claude Desktop ShipIt cache (safe - update cache)
if [ "$SKIP_CLAUDE" = false ]; then
    PROCESSED_CATEGORIES+=("Claude Desktop Cache")
    CLAUDE_SHIPIT="$USER_HOME/Library/Caches/com.anthropic.claudefordesktop.ShipIt"
    if [ -d "$CLAUDE_SHIPIT" ]; then
        CLAUDE_SIZE=$(du -sh "$CLAUDE_SHIPIT" 2>/dev/null | awk '{print $1}' || echo "0B")

        if [ -n "$CLAUDE_SIZE" ] && [ "$CLAUDE_SIZE" != "0B" ]; then
            log "Claude Desktop update cache: $CLAUDE_SIZE"
            CLAUDE_BYTES=$(size_to_bytes "$CLAUDE_SIZE")

            if [ "$DRY_RUN" = true ]; then
                log "Would clear Claude update cache: $CLAUDE_SIZE"
                TOTAL_BYTES_FREED=$((TOTAL_BYTES_FREED + CLAUDE_BYTES))
            else
                log "Cleaning Claude update cache..."
                rm -rf "${CLAUDE_SHIPIT:?}"/* 2>/dev/null
                log_success "Claude update cache cleared"
                TOTAL_BYTES_FREED=$((TOTAL_BYTES_FREED + CLAUDE_BYTES))
            fi
        else
            log "Claude cache is empty"
        fi
    fi
else
    SKIPPED_CATEGORIES+=("Claude Desktop Cache")
fi

log_plain ""

###############################################################################
# 4. System Cache Files
###############################################################################
PROCESSED_CATEGORIES+=("System Cache Files")
log_plain "================================================"
log "4. System Cache Files"
log_plain "================================================"

# Safe cache directories to clean (older than 30 days)
SAFE_CACHES=(
    "GeoServices"
    "com.apple.helpd"
    "com.apple.parsecd"
    "swift-frontend"
)

OLD_CACHE_COUNT=0
for CACHE_DIR in "${SAFE_CACHES[@]}"; do
    CACHE_PATH="$USER_HOME/Library/Caches/$CACHE_DIR"
    if [ -d "$CACHE_PATH" ]; then
        COUNT=$(find "$CACHE_PATH" -type f -mtime +30 2>/dev/null | wc -l | tr -d ' ')
        OLD_CACHE_COUNT=$((OLD_CACHE_COUNT + COUNT))
    fi
done

if [ "$OLD_CACHE_COUNT" -gt 0 ]; then
    log "Found $OLD_CACHE_COUNT old cache file(s) (>30 days)"

    if [ "$DRY_RUN" = true ]; then
        log "Would delete $OLD_CACHE_COUNT old cache file(s)"
    else
        log "Cleaning cache files older than 30 days..."
        for CACHE_DIR in "${SAFE_CACHES[@]}"; do
            CACHE_PATH="$USER_HOME/Library/Caches/$CACHE_DIR"
            if [ -d "$CACHE_PATH" ]; then
                find "$CACHE_PATH" -type f -mtime +30 -delete 2>/dev/null
            fi
        done
        log_success "Old cache files cleaned"
    fi
else
    log "No old cache files found (>30 days)"
fi
log_plain ""

###############################################################################
# 5. Old Log Files
###############################################################################
PROCESSED_CATEGORIES+=("Old Log Files")
log_plain "================================================"
log "5. Old Log Files"
log_plain "================================================"

OLD_LOG_COUNT=$(find "$USER_HOME/Library/Logs" -type f -name "*.log*" -mtime +7 2>/dev/null | wc -l | tr -d ' ')

if [ "$OLD_LOG_COUNT" -gt 0 ]; then
    OLD_LOG_SIZE=$(find "$USER_HOME/Library/Logs" -type f -name "*.log*" -mtime +7 -exec du -ch {} + 2>/dev/null | tail -1 | awk '{print $1}' || echo "0B")
    log "Found $OLD_LOG_COUNT old log file(s) (>7 days): $OLD_LOG_SIZE"
    LOG_BYTES=$(size_to_bytes "$OLD_LOG_SIZE")

    if [ "$DRY_RUN" = true ]; then
        log "Would delete $OLD_LOG_COUNT log file(s): $OLD_LOG_SIZE"
        TOTAL_BYTES_FREED=$((TOTAL_BYTES_FREED + LOG_BYTES))
    else
        log "Cleaning log files older than 7 days..."
        find "$USER_HOME/Library/Logs" -type f -name "*.log*" -mtime +7 -delete 2>/dev/null
        log_success "Old logs cleaned"
        TOTAL_BYTES_FREED=$((TOTAL_BYTES_FREED + LOG_BYTES))
    fi
else
    log "No old log files found (>7 days)"
fi
log_plain ""

###############################################################################
# 6. System Temporary Files
###############################################################################
PROCESSED_CATEGORIES+=("System Temporary Files")
log_plain "================================================"
log "6. System Temporary Files"
log_plain "================================================"

TMP_COUNT=$(find /private/var/tmp /private/tmp -type f 2>/dev/null | wc -l | tr -d ' ')

if [ "$TMP_COUNT" -gt 0 ]; then
    log "Found $TMP_COUNT temporary file(s)"

    if [ "$DRY_RUN" = true ]; then
        log "Would clean $TMP_COUNT temporary file(s)"
    else
        log "Cleaning system temporary files..."
        rm -rf /private/var/tmp/* 2>/dev/null
        rm -rf /private/tmp/* 2>/dev/null
        log_success "Temporary files cleaned"
    fi
else
    log "No temporary files found"
fi
log_plain ""

###############################################################################
# 7. Browser Caches (Chrome, Firefox, Edge)
###############################################################################
if [ "$SKIP_BROWSERS" = false ]; then
    PROCESSED_CATEGORIES+=("Browser Caches")
    log_plain "================================================"
    log "7. Browser Caches"
    log_plain "================================================"

    BROWSER_TOTAL_BYTES=0

    # Chrome
    CHROME_CACHE="$USER_HOME/Library/Caches/Google/Chrome"
    if [ -d "$CHROME_CACHE" ]; then
        CHROME_SIZE=$(du -sh "$CHROME_CACHE" 2>/dev/null | awk '{print $1}' || echo "0B")
        if [ -n "$CHROME_SIZE" ] && [ "$CHROME_SIZE" != "0B" ]; then
            log "Chrome cache: $CHROME_SIZE"
            CHROME_BYTES=$(size_to_bytes "$CHROME_SIZE")
            BROWSER_TOTAL_BYTES=$((BROWSER_TOTAL_BYTES + CHROME_BYTES))

            if [ "$DRY_RUN" = false ]; then
                rm -rf "${CHROME_CACHE:?}"/* 2>/dev/null
            fi
        fi
    fi

    # Firefox
    FIREFOX_CACHE="$USER_HOME/Library/Caches/Firefox"
    if [ -d "$FIREFOX_CACHE" ]; then
        FIREFOX_SIZE=$(du -sh "$FIREFOX_CACHE" 2>/dev/null | awk '{print $1}' || echo "0B")
        if [ -n "$FIREFOX_SIZE" ] && [ "$FIREFOX_SIZE" != "0B" ]; then
            log "Firefox cache: $FIREFOX_SIZE"
            FIREFOX_BYTES=$(size_to_bytes "$FIREFOX_SIZE")
            BROWSER_TOTAL_BYTES=$((BROWSER_TOTAL_BYTES + FIREFOX_BYTES))

            if [ "$DRY_RUN" = false ]; then
                rm -rf "${FIREFOX_CACHE:?}"/* 2>/dev/null
            fi
        fi
    fi

    # Microsoft Edge
    EDGE_CACHE="$USER_HOME/Library/Caches/com.microsoft.edgemac"
    if [ -d "$EDGE_CACHE" ]; then
        EDGE_SIZE=$(du -sh "$EDGE_CACHE" 2>/dev/null | awk '{print $1}' || echo "0B")
        if [ -n "$EDGE_SIZE" ] && [ "$EDGE_SIZE" != "0B" ]; then
            log "Edge cache: $EDGE_SIZE"
            EDGE_BYTES=$(size_to_bytes "$EDGE_SIZE")
            BROWSER_TOTAL_BYTES=$((BROWSER_TOTAL_BYTES + EDGE_BYTES))

            if [ "$DRY_RUN" = false ]; then
                rm -rf "${EDGE_CACHE:?}"/* 2>/dev/null
            fi
        fi
    fi

    if [ "$BROWSER_TOTAL_BYTES" -gt 0 ]; then
        BROWSER_HUMAN=$(bytes_to_human "$BROWSER_TOTAL_BYTES")
        if [ "$DRY_RUN" = true ]; then
            log "Would clear browser caches: $BROWSER_HUMAN"
        else
            log_success "Browser caches cleared: $BROWSER_HUMAN"
        fi
        TOTAL_BYTES_FREED=$((TOTAL_BYTES_FREED + BROWSER_TOTAL_BYTES))
    else
        log "No browser caches found"
    fi
    log_plain ""
else
    SKIPPED_CATEGORIES+=("Browser Caches")
fi

###############################################################################
# 8. XCode Derived Data
###############################################################################
if [ "$SKIP_XCODE" = false ]; then
    PROCESSED_CATEGORIES+=("XCode Derived Data")
    log_plain "================================================"
    log "8. XCode Derived Data"
    log_plain "================================================"

    XCODE_DD="$USER_HOME/Library/Developer/Xcode/DerivedData"
    if [ -d "$XCODE_DD" ]; then
        XCODE_SIZE=$(du -sh "$XCODE_DD" 2>/dev/null | awk '{print $1}' || echo "0B")

        if [ -n "$XCODE_SIZE" ] && [ "$XCODE_SIZE" != "0B" ]; then
            log "XCode derived data: $XCODE_SIZE"
            XCODE_BYTES=$(size_to_bytes "$XCODE_SIZE")

            # WARNING for non-dry-run, non-auto-yes mode
            if [ "$DRY_RUN" = false ] && [ "$AUTO_YES" = false ]; then
                log_always ""
                log_warning "WARNING: This will delete XCode build cache."
                log_always "   Active projects will need to rebuild (5-30 min first build)."
                log_always ""
                read -p "Continue with XCode cleanup? [y/N] " -n 1 -r
                echo
                if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                    log "XCode cleanup skipped by user"
                    log_plain ""
                else
                    log "Cleaning XCode derived data..."
                    rm -rf "${XCODE_DD:?}"/* 2>/dev/null
                    log_success "XCode derived data cleared"
                    TOTAL_BYTES_FREED=$((TOTAL_BYTES_FREED + XCODE_BYTES))
                fi
            elif [ "$DRY_RUN" = true ]; then
                log "Would clear XCode derived data: $XCODE_SIZE"
                TOTAL_BYTES_FREED=$((TOTAL_BYTES_FREED + XCODE_BYTES))
            else
                log "Cleaning XCode derived data..."
                rm -rf "${XCODE_DD:?}"/* 2>/dev/null
                log_success "XCode derived data cleared"
                TOTAL_BYTES_FREED=$((TOTAL_BYTES_FREED + XCODE_BYTES))
            fi
        else
            log "XCode derived data is empty"
        fi
    else
        log "XCode not installed, skipping"
    fi
    log_plain ""
else
    SKIPPED_CATEGORIES+=("XCode Derived Data")
fi

###############################################################################
# 9. npm/Yarn Cache
###############################################################################
if [ "$SKIP_NPM" = false ]; then
    PROCESSED_CATEGORIES+=("npm/Yarn Cache")
    log_plain "================================================"
    log "9. npm/Yarn Cache"
    log_plain "================================================"

    NODE_TOTAL_BYTES=0

    # npm cache
    NPM_CACHE="$USER_HOME/.npm"
    if [ -d "$NPM_CACHE" ]; then
        NPM_SIZE=$(du -sh "$NPM_CACHE" 2>/dev/null | awk '{print $1}' || echo "0B")
        if [ -n "$NPM_SIZE" ] && [ "$NPM_SIZE" != "0B" ]; then
            log "npm cache: $NPM_SIZE"
            NPM_BYTES=$(size_to_bytes "$NPM_SIZE")
            NODE_TOTAL_BYTES=$((NODE_TOTAL_BYTES + NPM_BYTES))

            if [ "$DRY_RUN" = false ]; then
                rm -rf "${NPM_CACHE:?}"/* 2>/dev/null
            fi
        fi
    fi

    # Yarn cache
    YARN_CACHE="$USER_HOME/.yarn/cache"
    if [ -d "$YARN_CACHE" ]; then
        YARN_SIZE=$(du -sh "$YARN_CACHE" 2>/dev/null | awk '{print $1}' || echo "0B")
        if [ -n "$YARN_SIZE" ] && [ "$YARN_SIZE" != "0B" ]; then
            log "Yarn cache: $YARN_SIZE"
            YARN_BYTES=$(size_to_bytes "$YARN_SIZE")
            NODE_TOTAL_BYTES=$((NODE_TOTAL_BYTES + YARN_BYTES))

            if [ "$DRY_RUN" = false ]; then
                rm -rf "${YARN_CACHE:?}"/* 2>/dev/null
            fi
        fi
    fi

    if [ "$NODE_TOTAL_BYTES" -gt 0 ]; then
        NODE_HUMAN=$(bytes_to_human "$NODE_TOTAL_BYTES")
        if [ "$DRY_RUN" = true ]; then
            log "Would clear npm/yarn caches: $NODE_HUMAN"
        else
            log_success "npm/yarn caches cleared: $NODE_HUMAN"
        fi
        TOTAL_BYTES_FREED=$((TOTAL_BYTES_FREED + NODE_TOTAL_BYTES))
    else
        log "No npm/yarn caches found"
    fi
    log_plain ""
else
    SKIPPED_CATEGORIES+=("npm/Yarn Cache")
fi

###############################################################################
# 10. Python pip Cache
###############################################################################
if [ "$SKIP_PIP" = false ]; then
    PROCESSED_CATEGORIES+=("Python pip Cache")
    log_plain "================================================"
    log "10. Python pip Cache"
    log_plain "================================================"

    PIP_CACHE="$USER_HOME/Library/Caches/pip"
    if [ -d "$PIP_CACHE" ]; then
        PIP_SIZE=$(du -sh "$PIP_CACHE" 2>/dev/null | awk '{print $1}' || echo "0B")

        if [ -n "$PIP_SIZE" ] && [ "$PIP_SIZE" != "0B" ]; then
            log "pip cache: $PIP_SIZE"
            PIP_BYTES=$(size_to_bytes "$PIP_SIZE")

            if [ "$DRY_RUN" = true ]; then
                log "Would clear pip cache: $PIP_SIZE"
                TOTAL_BYTES_FREED=$((TOTAL_BYTES_FREED + PIP_BYTES))
            else
                log "Cleaning pip cache..."
                rm -rf "${PIP_CACHE:?}"/* 2>/dev/null
                log_success "pip cache cleared"
                TOTAL_BYTES_FREED=$((TOTAL_BYTES_FREED + PIP_BYTES))
            fi
        else
            log "pip cache is empty"
        fi
    else
        log "pip cache not found"
    fi
    log_plain ""
else
    SKIPPED_CATEGORIES+=("Python pip Cache")
fi

###############################################################################
# 11. Trash Bin
###############################################################################
if [ "$SKIP_TRASH" = false ]; then
    PROCESSED_CATEGORIES+=("Trash Bin")
    log_plain "================================================"
    log "11. Trash Bin"
    log_plain "================================================"

    TRASH_DIR="$USER_HOME/.Trash"
    if [ -d "$TRASH_DIR" ]; then
        TRASH_SIZE=$(du -sh "$TRASH_DIR" 2>/dev/null | awk '{print $1}' || echo "0B")

        if [ -n "$TRASH_SIZE" ] && [ "$TRASH_SIZE" != "0B" ]; then
            log "Trash size: $TRASH_SIZE"
            TRASH_BYTES=$(size_to_bytes "$TRASH_SIZE")

            if [ "$DRY_RUN" = true ]; then
                log "Would empty trash: $TRASH_SIZE"
                TOTAL_BYTES_FREED=$((TOTAL_BYTES_FREED + TRASH_BYTES))
            else
                log "Emptying trash..."
                rm -rf "${TRASH_DIR:?}"/* 2>/dev/null
                rm -rf "${TRASH_DIR:?}"/.[!.]* 2>/dev/null
                log_success "Trash emptied"
                TOTAL_BYTES_FREED=$((TOTAL_BYTES_FREED + TRASH_BYTES))
            fi
        else
            log "Trash is already empty"
        fi
    fi
    log_plain ""
else
    SKIPPED_CATEGORIES+=("Trash Bin")
fi

###############################################################################
# 12. .DS_Store Files
###############################################################################
if [ "$SKIP_DSSTORE" = false ]; then
    PROCESSED_CATEGORIES+=(".DS_Store Files")
    log_plain "================================================"
    log "12. .DS_Store Files"
    log_plain "================================================"

    # Count .DS_Store files in user home
    DSSTORE_COUNT=$(find "$USER_HOME" -name ".DS_Store" -type f 2>/dev/null | wc -l | tr -d ' ')

    if [ "$DSSTORE_COUNT" -gt 0 ]; then
        log "Found $DSSTORE_COUNT .DS_Store file(s)"

        if [ "$DRY_RUN" = true ]; then
            log "Would delete $DSSTORE_COUNT .DS_Store file(s)"
        else
            log "Deleting .DS_Store files..."
            find "$USER_HOME" -name ".DS_Store" -type f -delete 2>/dev/null
            log_success ".DS_Store files deleted"
        fi
    else
        log "No .DS_Store files found"
    fi
    log_plain ""
else
    SKIPPED_CATEGORIES+=(".DS_Store Files")
fi

###############################################################################
# 13. Docker Cache
###############################################################################
if [ "$SKIP_DOCKER" = false ]; then
    PROCESSED_CATEGORIES+=("Docker Cache")
    log_plain "================================================"
    log "13. Docker Cache"
    log_plain "================================================"

    if command -v docker &> /dev/null; then
        # Get docker disk usage
        DOCKER_INFO=$(docker system df 2>/dev/null || echo "")

        if [ -n "$DOCKER_INFO" ]; then
            log "Docker system disk usage:"
            echo "$DOCKER_INFO" | tail -n +2 | while read -r line; do
                log "  $line"
            done

            if [ "$DRY_RUN" = true ]; then
                log "Would clean Docker cache (dangling images, stopped containers, unused networks)"
            else
                log "Cleaning Docker cache..."
                docker system prune -af --volumes 2>/dev/null || log_warning "Docker cleanup encountered issues"
                log_success "Docker cache cleared"
            fi
        else
            log "Docker is not running or has no data"
        fi
    else
        log "Docker not installed, skipping"
    fi
    log_plain ""
else
    SKIPPED_CATEGORIES+=("Docker Cache")
fi

###############################################################################
# 14. iOS Simulator Data
###############################################################################
if [ "$SKIP_SIMULATOR" = false ]; then
    PROCESSED_CATEGORIES+=("iOS Simulator Data")
    log_plain "================================================"
    log "14. iOS Simulator Data"
    log_plain "================================================"

    SIMULATOR_DIR="$USER_HOME/Library/Developer/CoreSimulator"
    if [ -d "$SIMULATOR_DIR" ]; then
        SIM_SIZE=$(du -sh "$SIMULATOR_DIR" 2>/dev/null | awk '{print $1}' || echo "0B")

        if [ -n "$SIM_SIZE" ] && [ "$SIM_SIZE" != "0B" ]; then
            log "iOS Simulator data: $SIM_SIZE"
            SIM_BYTES=$(size_to_bytes "$SIM_SIZE")

            if [ "$DRY_RUN" = true ]; then
                log "Would clean iOS Simulator data: $SIM_SIZE"
                TOTAL_BYTES_FREED=$((TOTAL_BYTES_FREED + SIM_BYTES))
            else
                log "Cleaning iOS Simulator data..."
                if command -v xcrun &> /dev/null; then
                    xcrun simctl delete unavailable 2>/dev/null || log_warning "Could not delete unavailable simulators"
                    xcrun simctl erase all 2>/dev/null || log_warning "Could not erase all simulators"
                    log_success "iOS Simulator data cleared"
                else
                    log_warning "xcrun command not found, skipping"
                fi
                TOTAL_BYTES_FREED=$((TOTAL_BYTES_FREED + SIM_BYTES))
            fi
        else
            log "iOS Simulator data is empty"
        fi
    else
        log "iOS Simulator not found"
    fi
    log_plain ""
else
    SKIPPED_CATEGORIES+=("iOS Simulator Data")
fi

###############################################################################
# 15. Mail App Cache
###############################################################################
if [ "$SKIP_MAIL" = false ]; then
    PROCESSED_CATEGORIES+=("Mail App Cache")
    log_plain "================================================"
    log "15. Mail App Cache"
    log_plain "================================================"

    MAIL_CACHE="$USER_HOME/Library/Caches/com.apple.mail"
    if [ -d "$MAIL_CACHE" ]; then
        MAIL_SIZE=$(du -sh "$MAIL_CACHE" 2>/dev/null | awk '{print $1}' || echo "0B")

        if [ -n "$MAIL_SIZE" ] && [ "$MAIL_SIZE" != "0B" ]; then
            log "Mail app cache: $MAIL_SIZE"
            MAIL_BYTES=$(size_to_bytes "$MAIL_SIZE")

            if [ "$DRY_RUN" = true ]; then
                log "Would clear Mail app cache: $MAIL_SIZE"
                TOTAL_BYTES_FREED=$((TOTAL_BYTES_FREED + MAIL_BYTES))
            else
                log "Cleaning Mail app cache..."
                rm -rf "${MAIL_CACHE:?}"/* 2>/dev/null
                log_success "Mail app cache cleared"
                TOTAL_BYTES_FREED=$((TOTAL_BYTES_FREED + MAIL_BYTES))
            fi
        else
            log "Mail app cache is empty"
        fi
    else
        log "Mail app cache not found"
    fi
    log_plain ""
else
    SKIPPED_CATEGORIES+=("Mail App Cache")
fi

###############################################################################
# Enhanced Summary Report
###############################################################################
log_plain "================================================"
if [ "$DRY_RUN" = true ]; then
    log_plain "${BOLD}Dry Run Complete - No Files Were Deleted${NC}"
    log_plain "================================================"
    log_plain ""

    # Show estimated space to be freed
    if [ "$TOTAL_BYTES_FREED" -gt 0 ]; then
        HUMAN_FREED=$(bytes_to_human "$TOTAL_BYTES_FREED")
        log_always "${GREEN}Estimated space that would be freed: $HUMAN_FREED${NC}"
        log_plain ""
    fi

    log_plain "To actually clean these files, run:"
    log_plain "  sudo $0"
else
    log_plain "${BOLD}Cleanup Complete!${NC}"
    log_plain "================================================"
    log_plain ""

    # Get final disk usage
    DISK_USAGE_AFTER=$(df -h / | tail -1 | awk '{print $5}' | sed 's/%//')
    DISK_AVAIL_AFTER=$(df -h / | tail -1 | awk '{print $4}')
    DISK_USED_AFTER=$(df -h / | tail -1 | awk '{print $3}')

    log "Initial disk usage: ${DISK_USAGE}% (${DISK_USED} used, ${DISK_AVAIL} available)"
    log "Final disk usage:   ${DISK_USAGE_AFTER}% (${DISK_USED_AFTER} used, ${DISK_AVAIL_AFTER} available)"

    if [ "$TOTAL_BYTES_FREED" -gt 0 ]; then
        HUMAN_FREED=$(bytes_to_human "$TOTAL_BYTES_FREED")
        log_always ""
        log_always "${GREEN}✓ Approximate space freed: $HUMAN_FREED${NC}"
    fi
fi

# Show categories processed
log_plain ""
log_plain "${BOLD}Categories Processed:${NC}"
if [ ${#PROCESSED_CATEGORIES[@]} -gt 0 ]; then
    for category in "${PROCESSED_CATEGORIES[@]}"; do
        log_plain "  ${GREEN}✓${NC} $category"
    done
else
    log_plain "  ${YELLOW}(none)${NC}"
fi

# Show categories skipped
if [ ${#SKIPPED_CATEGORIES[@]} -gt 0 ]; then
    log_plain ""
    log_plain "${BOLD}Categories Skipped:${NC}"
    for category in "${SKIPPED_CATEGORIES[@]}"; do
        log_plain "  ${DIM}⊘${NC} $category"
    done
fi

log_plain ""
log_plain "================================================"
log_plain ""
log_plain "${BOLD}SAFETY GUARANTEES:${NC}"
log_plain "This script does NOT touch:"
log_plain "  - Safari or browser data/sessions"
log_plain "  - Application settings or configurations"
log_plain "  - User documents or media files"
log_plain "  - Active application data"
log_plain "================================================"
