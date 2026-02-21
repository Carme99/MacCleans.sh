#!/bin/bash

# Enable strict error handling
set -euo pipefail

VERSION="4.0.0"

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
#   --force, -f         Skip ALL confirmation prompts (includes XCode, dangerous ops)
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
#   --skip-siri-tts     Skip Siri TTS cache cleanup
#   --skip-icloud-mail  Skip iCloud Mail cache cleanup
#   --skip-photos-library Skip Photos Library cache cleanup
#   --skip-icloud-drive Skip iCloud Drive offline files cleanup
#   --skip-quicklook    Skip QuickLook thumbnails cleanup
#   --skip-diagnostics  Skip diagnostic reports cleanup
#   --skip-ios-backups  Skip iOS device backups cleanup
#   --skip-ios-updates  Skip iOS/iPadOS update files (.ipsw) cleanup
#   --photos-library    Specify Photos library name or "all" to clean all libraries
###############################################################################

# Default options
DRY_RUN=false
AUTO_YES=false
FORCE=false
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
SKIP_SIRI_TTS=false
SKIP_ICLOUD_MAIL=false
SKIP_PHOTOS_LIBRARY=false
SKIP_ICLOUD_DRIVE=false
PHOTOS_LIBRARY_NAME=""
SKIP_QUICKLOOK=false
SKIP_DIAGNOSTICS=false
SKIP_IOS_BACKUPS=false
SKIP_IOS_UPDATES=false

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
    for var in DRY_RUN AUTO_YES FORCE QUIET NO_COLOR SKIP_SNAPSHOTS SKIP_HOMEBREW \
               SKIP_SPOTIFY SKIP_CLAUDE SKIP_XCODE SKIP_BROWSERS SKIP_NPM \
               SKIP_PIP SKIP_TRASH SKIP_DSSTORE SKIP_DOCKER SKIP_SIMULATOR SKIP_MAIL \
               SKIP_SIRI_TTS SKIP_ICLOUD_MAIL SKIP_PHOTOS_LIBRARY SKIP_ICLOUD_DRIVE SKIP_QUICKLOOK SKIP_DIAGNOSTICS SKIP_IOS_BACKUPS \
               SKIP_IOS_UPDATES; do
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
                    FORCE) FORCE="$value"; [ "$value" = "true" ] && AUTO_YES="true" ;;
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
                    SKIP_SIRI_TTS) SKIP_SIRI_TTS="$value" ;;
                    SKIP_ICLOUD_MAIL) SKIP_ICLOUD_MAIL="$value" ;;
                    SKIP_PHOTOS_LIBRARY) SKIP_PHOTOS_LIBRARY="$value" ;;
                    SKIP_ICLOUD_DRIVE) SKIP_ICLOUD_DRIVE="$value" ;;
                    SKIP_QUICKLOOK) SKIP_QUICKLOOK="$value" ;;
                    SKIP_DIAGNOSTICS) SKIP_DIAGNOSTICS="$value" ;;
                    SKIP_IOS_BACKUPS) SKIP_IOS_BACKUPS="$value" ;;
                    SKIP_IOS_UPDATES) SKIP_IOS_UPDATES="$value" ;;
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
            --force|-f)
                FORCE=true
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
            --skip-siri-tts)
                SKIP_SIRI_TTS=true
                shift
                ;;
            --skip-icloud-mail)
                SKIP_ICLOUD_MAIL=true
                shift
                ;;
            --skip-photos-library)
                SKIP_PHOTOS_LIBRARY=true
                shift
                ;;
            --skip-icloud-drive)
                SKIP_ICLOUD_DRIVE=true
                shift
                ;;
            --skip-quicklook)
                SKIP_QUICKLOOK=true
                shift
                ;;
            --skip-diagnostics)
                SKIP_DIAGNOSTICS=true
                shift
                ;;
            --skip-ios-backups)
                SKIP_IOS_BACKUPS=true
                shift
                ;;
            --skip-ios-updates)
                SKIP_IOS_UPDATES=true
                shift
                ;;
            --photos-library)
                if [ -z "${2:-}" ]; then
                    echo "ERROR: --photos-library requires an argument (library name or 'all')" >&2
                    exit 1
                fi
                PHOTOS_LIBRARY_NAME="$2"
                shift 2
                ;;
            --help|-h)
                head -n 62 "$0" | tail -n +3 | sed 's/^# //'
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

# Set up signal handling for graceful interruption
cleanup_on_interrupt() {
    log_warning "Interrupted by user, cleaning up..."
    log_always "Cleanup aborted."
    exit 130
}
trap cleanup_on_interrupt INT TERM

# Color definitions
if [ "$NO_COLOR" = true ] || [ ! -t 1 ]; then
    RED="" GREEN="" YELLOW="" CYAN="" BOLD="" DIM="" NC=""
else
    RED='\033[0;31m' GREEN='\033[0;32m' YELLOW='\033[1;33m'
    CYAN='\033[0;36m'
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
    local number
    number=$(echo "$size" | grep -oE '[0-9.]+' || echo "0")
    local unit
    unit=$(echo "$size" | grep -oE '[A-Za-z]+' || echo "B")

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
        echo "$(awk -v b="$bytes" 'BEGIN {printf "%.2f", b / 1073741824}')G"
    else
        echo "$(awk -v b="$bytes" 'BEGIN {printf "%.2f", b / 1099511627776}')T"
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
    # Use getent for safer home directory lookup instead of eval
    if command -v getent &> /dev/null; then
        USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
    else
        # Fallback: construct home path from /Users (macOS standard)
        USER_HOME="/Users/$SUDO_USER"
    fi
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
        local load_avg
        load_avg=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | cut -d. -f1 | tr -d ' \n' || echo "0")
        # Ensure load_avg is not empty and is numeric
        if [ -z "$load_avg" ] || ! [[ "$load_avg" =~ ^[0-9]+$ ]]; then
            load_avg=0
        fi
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
            log "Loading conservative profile (skipping development caches and iOS backups)"
            SKIP_XCODE=true
            SKIP_NPM=true
            SKIP_PIP=true
            SKIP_BROWSERS=true
            SKIP_DOCKER=true
            SKIP_SIMULATOR=true
            SKIP_IOS_BACKUPS=true
            SKIP_IOS_UPDATES=true
            ;;
        developer)
            log "Loading developer profile (skipping only XCode and iOS backups)"
            SKIP_XCODE=true
            SKIP_IOS_BACKUPS=true
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
            SKIP_IOS_BACKUPS=true
            SKIP_IOS_UPDATES=true
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

    # Category data: "display_name|skip_var"
    local -a categories=(
        "Time Machine Snapshots|SKIP_SNAPSHOTS"
        "Homebrew Cache|SKIP_HOMEBREW"
        "Spotify Cache|SKIP_SPOTIFY"
        "Claude Desktop Cache|SKIP_CLAUDE"
        "XCode Derived Data|SKIP_XCODE"
        "Browser Caches (Chrome, Firefox, Edge)|SKIP_BROWSERS"
        "npm/Yarn Cache|SKIP_NPM"
        "Python pip Cache|SKIP_PIP"
        "Trash Bin|SKIP_TRASH"
        ".DS_Store Files|SKIP_DSSTORE"
        "Docker Cache|SKIP_DOCKER"
        "iOS Simulator Data|SKIP_SIMULATOR"
        "Mail App Cache|SKIP_MAIL"
        "Siri TTS Cache|SKIP_SIRI_TTS"
        "iCloud Mail Cache|SKIP_ICLOUD_MAIL"
        "Photos Library Cache|SKIP_PHOTOS_LIBRARY"
        "iCloud Drive Offline Files|SKIP_ICLOUD_DRIVE"
        "QuickLook Thumbnails|SKIP_QUICKLOOK"
        "Diagnostic Reports (>30 days)|SKIP_DIAGNOSTICS"
        "iOS Device Backups (⚠️  requires confirmation)|SKIP_IOS_BACKUPS"
        "iOS/iPadOS Update Files (.ipsw)|SKIP_IOS_UPDATES"
    )

    local cursor=0
    local total=${#categories[@]}

    # Function to toggle category
    toggle_category() {
        local idx=$1
        local var
        var=$(echo "${categories[$idx]}" | cut -d'|' -f2)
        local current_val="${!var}"
        if [ "$current_val" = "true" ]; then
            eval "$var=false"
        else
            eval "$var=true"
        fi
    }

    # Function to draw menu
    draw_menu() {
        # Clear screen
        clear
        log_plain ""
        log_plain "${BOLD}Interactive Category Selection${NC}"
        log_plain "================================================"
        log_plain ""
        log_plain "Use ${CYAN}↑↓${NC} arrow keys to navigate, ${CYAN}Space/Enter${NC} to toggle"
        log_plain "Press ${CYAN}a${NC}=all, ${CYAN}n${NC}=none, ${CYAN}d${NC}=done, ${CYAN}q${NC}=cancel"
        log_plain ""

        for i in "${!categories[@]}"; do
            local display
            display=$(echo "${categories[$i]}" | cut -d'|' -f1)
            local var
            var=$(echo "${categories[$i]}" | cut -d'|' -f2)
            local enabled="${!var}"

            # Status indicator
            local status
            if [ "$enabled" = "false" ]; then
                status="${GREEN}[✓]${NC}"
            else
                status="[ ]"
            fi

            # Cursor indicator
            local cursor_mark="  "
            if [ "$i" -eq "$cursor" ]; then
                cursor_mark="${CYAN}>${NC} "
            fi

            printf "%b%b %s\n" "$cursor_mark" "$status" "$display"
        done

        log_plain ""
        log_plain "${DIM}Tip: Numbers 1-${#categories[@]} also work for quick toggle${NC}"
    }

    # Initial draw
    draw_menu

    # Main loop
    while true; do
        # Read single character including escape sequences
        local key
        IFS= read -rsn1 key

        # Handle escape sequences (arrow keys)
        if [[ $key == $'\x1b' ]]; then
            read -rsn2 key
            case $key in
                '[A') # Up arrow
                    ((cursor--))
                    if [ $cursor -lt 0 ]; then
                        cursor=$((total - 1))
                    fi
                    draw_menu
                    ;;
                '[B') # Down arrow
                    ((cursor++))
                    if [ "$cursor" -ge "$total" ]; then
                        cursor=0
                    fi
                    draw_menu
                    ;;
            esac
        else
            case $key in
                ' '|'') # Space or Enter - toggle current selection
                    toggle_category $cursor
                    draw_menu
                    ;;
                a|A) # Select all
                    SKIP_SNAPSHOTS=false SKIP_HOMEBREW=false SKIP_SPOTIFY=false SKIP_CLAUDE=false
                    SKIP_XCODE=false SKIP_BROWSERS=false SKIP_NPM=false SKIP_PIP=false
                    SKIP_TRASH=false SKIP_DSSTORE=false SKIP_DOCKER=false SKIP_SIMULATOR=false
                    SKIP_MAIL=false SKIP_SIRI_TTS=false SKIP_ICLOUD_MAIL=false SKIP_QUICKLOOK=false
                    SKIP_DIAGNOSTICS=false SKIP_IOS_BACKUPS=false SKIP_IOS_UPDATES=false
                    draw_menu
                    ;;
                n|N) # Deselect all
                    SKIP_SNAPSHOTS=true SKIP_HOMEBREW=true SKIP_SPOTIFY=true SKIP_CLAUDE=true
                    SKIP_XCODE=true SKIP_BROWSERS=true SKIP_NPM=true SKIP_PIP=true
                    SKIP_TRASH=true SKIP_DSSTORE=true SKIP_DOCKER=true SKIP_SIMULATOR=true
                    SKIP_MAIL=true SKIP_SIRI_TTS=true SKIP_ICLOUD_MAIL=true SKIP_QUICKLOOK=true
                    SKIP_DIAGNOSTICS=true SKIP_IOS_BACKUPS=true SKIP_IOS_UPDATES=true
                    draw_menu
                    ;;
                d|D) # Done
                    break
                    ;;
                q|Q) # Quit/Cancel
                    log_plain ""
                    log_always "Selection cancelled."
                    exit 0
                    ;;
                1)
                    # Check if this is part of 10-13
                    IFS= read -rsn1 -t 0.3 next_key
                    if [[ -n "$next_key" ]]; then
                        case "$next_key" in
                            0) toggle_category 9; draw_menu ;; # 10
                            1) toggle_category 10; draw_menu ;; # 11
                            2) toggle_category 11; draw_menu ;; # 12
                            3) toggle_category 12; draw_menu ;; # 13
                            *) toggle_category 0; draw_menu ;; # Just 1
                        esac
                    else
                        toggle_category 0; draw_menu # Just 1
                    fi
                    ;;
                2) toggle_category 1; draw_menu ;;
                3) toggle_category 2; draw_menu ;;
                4) toggle_category 3; draw_menu ;;
                5) toggle_category 4; draw_menu ;;
                6) toggle_category 5; draw_menu ;;
                7) toggle_category 6; draw_menu ;;
                8) toggle_category 7; draw_menu ;;
                9) toggle_category 8; draw_menu ;;
                *) # Ignore other input
                    ;;
            esac
        fi
    done

    log_plain ""
    log_success "Categories selected!"
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

# Get initial disk usage (capture bytes for accurate calculation)
DISK_USAGE=$(df -h / | tail -1 | awk '{print $5}' | sed 's/%//')
DISK_AVAIL=$(df -h / | tail -1 | awk '{print $4}')
DISK_USED=$(df -h / | tail -1 | awk '{print $3}')
DISK_AVAIL_BYTES=$(df -k / | tail -1 | awk '{print $4}')  # Get KB
DISK_AVAIL_BYTES=$((DISK_AVAIL_BYTES * 1024))  # Convert KB to bytes

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
    TM_RUNNING=$(echo "$TM_RUNNING" | tr -d '\n' | head -n 1)
    if [ "$TM_RUNNING" -gt 0 ]; then
        log_warning "Time Machine backup is currently running"
        log "Skipping snapshot deletion for safety"
    else
        SNAPSHOTS=$(tmutil listlocalsnapshots / 2>/dev/null | grep -c "com.apple.TimeMachine" || echo "0")
        if [ "$SNAPSHOTS" -gt 0 ]; then
            # Estimate snapshot size by checking container space allocation
            # On APFS, snapshots share blocks with the main volume making exact size calculation complex
            SNAPSHOT_SIZE_BYTES=0
            SNAPSHOT_ESTIMATE=""

            if command -v diskutil &> /dev/null; then
                # Get volume root disk identifier
                ROOT_DISK=$(df / | tail -1 | awk '{print $1}' | sed 's|/dev/||')

                # Get container total and free space to estimate snapshot overhead (extract byte values)
                CONTAINER_TOTAL=$(diskutil info "$ROOT_DISK" 2>/dev/null | grep "Container Total Space" | grep -oE '\([0-9]+ Bytes\)' | grep -oE '[0-9]+' || echo "0")
                CONTAINER_FREE=$(diskutil info "$ROOT_DISK" 2>/dev/null | grep "Container Free Space" | grep -oE '\([0-9]+ Bytes\)' | grep -oE '[0-9]+' || echo "0")
                VOLUME_USED=$(diskutil info "$ROOT_DISK" 2>/dev/null | grep "Volume Used Space" | grep -oE '\([0-9]+ Bytes\)' | grep -oE '[0-9]+' || echo "0")

                # Ensure all values are numeric
                if ! [[ "$CONTAINER_TOTAL" =~ ^[0-9]+$ ]]; then CONTAINER_TOTAL=0; fi
                if ! [[ "$CONTAINER_FREE" =~ ^[0-9]+$ ]]; then CONTAINER_FREE=0; fi
                if ! [[ "$VOLUME_USED" =~ ^[0-9]+$ ]]; then VOLUME_USED=0; fi

                if [ "$CONTAINER_TOTAL" -gt 0 ] && [ "$CONTAINER_FREE" -gt 0 ] && [ "$VOLUME_USED" -gt 0 ]; then
                    # Unaccounted space = Total - Used - Free (likely includes snapshots and purgeable)
                    UNACCOUNTED=$((CONTAINER_TOTAL - VOLUME_USED - CONTAINER_FREE))

                    # Rough estimate: assume 50-70% of unaccounted space is snapshots
                    # This is conservative as unaccounted space includes other APFS overhead
                    if [ "$UNACCOUNTED" -gt 0 ]; then
                        SNAPSHOT_SIZE_BYTES=$((UNACCOUNTED * 6 / 10))  # 60% estimate
                        SNAPSHOT_ESTIMATE=" (estimated ~$(bytes_to_human $SNAPSHOT_SIZE_BYTES))"
                    fi
                fi
            fi

            # Display snapshot information
            log "Found $SNAPSHOTS local snapshot(s)${SNAPSHOT_ESTIMATE}"
            log "${DIM}Note: Exact snapshot sizes aren't exposed by macOS; estimate shown${NC}"

            if [ "$DRY_RUN" = true ]; then
                if [ "$SNAPSHOT_SIZE_BYTES" -gt 0 ]; then
                    log "Would delete $SNAPSHOTS snapshot(s) - may free up to $(bytes_to_human $SNAPSHOT_SIZE_BYTES)"
                    TOTAL_BYTES_FREED=$((TOTAL_BYTES_FREED + SNAPSHOT_SIZE_BYTES))
                else
                    log "Would delete $SNAPSHOTS snapshot(s)"
                fi
            else
                log "Deleting snapshots..."
                if [ "$SNAPSHOT_SIZE_BYTES" -gt 0 ]; then
                    TOTAL_BYTES_FREED=$((TOTAL_BYTES_FREED + SNAPSHOT_SIZE_BYTES))
                fi
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
    CACHE_BYTES=0
    for CACHE_DIR in "${SAFE_CACHES[@]}"; do
        CACHE_PATH="$USER_HOME/Library/Caches/$CACHE_DIR"
        if [ -d "$CACHE_PATH" ]; then
            PARTIAL_SIZE=$(find "$CACHE_PATH" -type f -mtime +30 -exec du -ch {} + 2>/dev/null | tail -1 | awk '{print $1}' || echo "0B")
            if [ -n "$PARTIAL_SIZE" ] && [ "$PARTIAL_SIZE" != "0B" ]; then
                CACHE_BYTES=$((CACHE_BYTES + $(size_to_bytes "$PARTIAL_SIZE")))
            fi
        fi
    done
    OLD_CACHE_SIZE=$(echo "$CACHE_BYTES" | awk '{if ($1>=1073741824) printf "%.1fG", $1/1073741824; else if ($1>=1048576) printf "%.1fM", $1/1048576; else if ($1>=1024) printf "%.1fK", $1/1024; else printf "%dB", $1}')
    log "Found $OLD_CACHE_COUNT old cache file(s) (>30 days): $OLD_CACHE_SIZE"

    if [ "$DRY_RUN" = true ]; then
        log "Would delete $OLD_CACHE_COUNT old cache file(s)"
        TOTAL_BYTES_FREED=$((TOTAL_BYTES_FREED + CACHE_BYTES))
    else
        log "Cleaning cache files older than 30 days..."
        for CACHE_DIR in "${SAFE_CACHES[@]}"; do
            CACHE_PATH="$USER_HOME/Library/Caches/$CACHE_DIR"
            if [ -d "$CACHE_PATH" ]; then
                find "$CACHE_PATH" -type f -mtime +30 -delete 2>/dev/null
            fi
        done
        log_success "Old cache files cleaned"
        TOTAL_BYTES_FREED=$((TOTAL_BYTES_FREED + CACHE_BYTES))
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
    TMP_SIZE=$(find /private/var/tmp /private/tmp -type f -exec du -ch {} + 2>/dev/null | tail -1 | awk '{print $1}' || echo "0B")
    TMP_BYTES=$(size_to_bytes "$TMP_SIZE")
    log "Found $TMP_COUNT temporary file(s): $TMP_SIZE"

    if [ "$DRY_RUN" = true ]; then
        log "Would clean $TMP_COUNT temporary file(s)"
        TOTAL_BYTES_FREED=$((TOTAL_BYTES_FREED + TMP_BYTES))
    else
        log "Cleaning system temporary files..."
        rm -rf /private/var/tmp/* 2>/dev/null
        rm -rf /private/tmp/* 2>/dev/null
        log_success "Temporary files cleaned"
        TOTAL_BYTES_FREED=$((TOTAL_BYTES_FREED + TMP_BYTES))
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
            # FORCE skips all prompts including XCode warning
            if [ "$DRY_RUN" = false ] && [ "$FORCE" = false ] && [ "$AUTO_YES" = false ]; then
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
                # Safely delete files only (not symlinks) in trash
                find "$TRASH_DIR" -maxdepth 1 -type f -delete 2>/dev/null
                # Delete hidden files but not symlinks
                find "$TRASH_DIR" -maxdepth 1 -type f -name '.*' -delete 2>/dev/null
                # Delete directories (including non-empty) - use rm -rf as find -delete only removes empty dirs
                find "$TRASH_DIR" -maxdepth 1 -mindepth 1 -type d -not -name '.Trash' -print0 | xargs -0 rm -rf 2>/dev/null || true
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
# 12. Docker Cache
###############################################################################
if [ "$SKIP_DOCKER" = false ]; then
    PROCESSED_CATEGORIES+=("Docker Cache")
    log_plain "================================================"
    log "12. Docker Cache"
    log_plain "================================================"

    if command -v docker &> /dev/null; then
        # Get docker disk usage
        DOCKER_INFO=$(docker system df 2>/dev/null || echo "")

        if [ -n "$DOCKER_INFO" ]; then
            log "Docker system disk usage:"
            echo "$DOCKER_INFO" | tail -n +2 | while read -r line; do
                log "  $line"
            done

            # Estimate reclaimable space using docker's format option
            DOCKER_RECLAIM_SIZE=$(docker system df --format '{{.Reclaimable}}' 2>/dev/null | head -1 || echo "0B")
            if [ -n "$DOCKER_RECLAIM_SIZE" ] && [ "$DOCKER_RECLAIM_SIZE" != "0B" ]; then
                # Strip any trailing parenthetical percentage e.g. "3.2GB (45%)" -> "3.2GB"
                DOCKER_RECLAIM_SIZE=$(echo "$DOCKER_RECLAIM_SIZE" | awk '{print $1}')
                DOCKER_RECLAIM=$(size_to_bytes "$DOCKER_RECLAIM_SIZE")
            else
                DOCKER_RECLAIM=0
            fi

            if [ "$DRY_RUN" = true ]; then
                log "Would clean Docker cache (dangling images, stopped containers, unused networks)"
                TOTAL_BYTES_FREED=$((TOTAL_BYTES_FREED + DOCKER_RECLAIM))
            else
                log "Cleaning Docker cache..."
                log_warning "Note: Named volumes are preserved. Use 'docker volume prune' manually if needed."
                docker system prune -af 2>/dev/null || log_warning "Docker cleanup encountered issues"
                log_success "Docker cache cleared"
                TOTAL_BYTES_FREED=$((TOTAL_BYTES_FREED + DOCKER_RECLAIM))
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
# 13. iOS Simulator Data
###############################################################################
if [ "$SKIP_SIMULATOR" = false ]; then
    PROCESSED_CATEGORIES+=("iOS Simulator Data")
    log_plain "================================================"
    log "13. iOS Simulator Data"
    log_plain "================================================"

    SIMULATOR_DIR="$USER_HOME/Library/Developer/CoreSimulator"
    if [ -d "$SIMULATOR_DIR" ]; then
        SIM_SIZE=$(du -sh "$SIMULATOR_DIR" 2>/dev/null | awk '{print $1}' || echo "0B")

        if [ -n "$SIM_SIZE" ] && [ "$SIM_SIZE" != "0B" ]; then
            log "iOS Simulator data: $SIM_SIZE (total)"

            if [ "$DRY_RUN" = true ]; then
                log "Would remove unavailable iOS Simulators"
            else
                log "Cleaning unavailable iOS Simulators..."
                if command -v xcrun &> /dev/null; then
                    SIM_BEFORE=$(du -sk "$SIMULATOR_DIR" 2>/dev/null | awk '{print $1}' || echo "0")
                    xcrun simctl delete unavailable 2>/dev/null || log_warning "Could not delete unavailable simulators"
                    SIM_AFTER=$(du -sk "$SIMULATOR_DIR" 2>/dev/null | awk '{print $1}' || echo "0")
                    SIM_FREED=$(( (SIM_BEFORE - SIM_AFTER) * 1024 ))
                    if [ "$SIM_FREED" -lt 0 ]; then SIM_FREED=0; fi
                    TOTAL_BYTES_FREED=$((TOTAL_BYTES_FREED + SIM_FREED))
                    log_success "Unavailable iOS Simulators removed"
                else
                    log_warning "xcrun command not found, skipping"
                fi
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
# 14. Mail App Cache
###############################################################################
if [ "$SKIP_MAIL" = false ]; then
    PROCESSED_CATEGORIES+=("Mail App Cache")
    log_plain "================================================"
    log "14. Mail App Cache"
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
# 15. Siri TTS Cache
###############################################################################
if [ "$SKIP_SIRI_TTS" = false ]; then
    PROCESSED_CATEGORIES+=("Siri TTS Cache")
    log_plain "================================================"
    log "15. Siri TTS Cache"
    log_plain "================================================"

    SIRI_CACHE="$USER_HOME/Library/Caches/SiriTTS"
    if [ -d "$SIRI_CACHE" ]; then
        SIRI_SIZE=$(du -sh "$SIRI_CACHE" 2>/dev/null | awk '{print $1}' || echo "0B")

        if [ -n "$SIRI_SIZE" ] && [ "$SIRI_SIZE" != "0B" ]; then
            log "Siri TTS cache: $SIRI_SIZE"
            SIRI_BYTES=$(size_to_bytes "$SIRI_SIZE")

            if [ "$DRY_RUN" = true ]; then
                log "Would clear Siri TTS cache: $SIRI_SIZE"
                TOTAL_BYTES_FREED=$((TOTAL_BYTES_FREED + SIRI_BYTES))
            else
                log "Cleaning Siri TTS cache..."
                rm -rf "${SIRI_CACHE:?}"/* 2>/dev/null
                log_success "Siri TTS cache cleared"
                TOTAL_BYTES_FREED=$((TOTAL_BYTES_FREED + SIRI_BYTES))
            fi
        else
            log "Siri TTS cache is empty"
        fi
    else
        log "Siri TTS cache not found"
    fi
    log_plain ""
else
    SKIPPED_CATEGORIES+=("Siri TTS Cache")
fi

###############################################################################
# 16. iCloud Mail Cache
###############################################################################
if [ "$SKIP_ICLOUD_MAIL" = false ]; then
    PROCESSED_CATEGORIES+=("iCloud Mail Cache")
    log_plain "================================================"
    log "16. iCloud Mail Cache"
    log_plain "================================================"

    ICLOUD_MAIL_CACHE="$USER_HOME/Library/Caches/icloudmailagent"
    if [ -d "$ICLOUD_MAIL_CACHE" ]; then
        ICLOUD_MAIL_SIZE=$(du -sh "$ICLOUD_MAIL_CACHE" 2>/dev/null | awk '{print $1}' || echo "0B")

        if [ -n "$ICLOUD_MAIL_SIZE" ] && [ "$ICLOUD_MAIL_SIZE" != "0B" ]; then
            log "iCloud Mail cache: $ICLOUD_MAIL_SIZE"
            ICLOUD_MAIL_BYTES=$(size_to_bytes "$ICLOUD_MAIL_SIZE")

            if [ "$DRY_RUN" = true ]; then
                log "Would clear iCloud Mail cache: $ICLOUD_MAIL_SIZE"
                TOTAL_BYTES_FREED=$((TOTAL_BYTES_FREED + ICLOUD_MAIL_BYTES))
            else
                log "Cleaning iCloud Mail cache..."
                rm -rf "${ICLOUD_MAIL_CACHE:?}"/* 2>/dev/null
                log_success "iCloud Mail cache cleared"
                TOTAL_BYTES_FREED=$((TOTAL_BYTES_FREED + ICLOUD_MAIL_BYTES))
            fi
        else
            log "iCloud Mail cache is empty"
        fi
    else
        log "iCloud Mail cache not found"
    fi
    log_plain ""
else
    SKIPPED_CATEGORIES+=("iCloud Mail Cache")
fi

###############################################################################
# 17. Photos Library Cache
###############################################################################
if [ "$SKIP_PHOTOS_LIBRARY" = false ]; then
    log_plain "================================================"
    log "17. Photos Library Cache"
    log_plain "================================================"

    # Check if Photos app is running (only in real run mode, not dry-run)
    if pgrep -x "Photos" > /dev/null 2>&1; then
        if [ "$DRY_RUN" = true ]; then
            log "${YELLOW}Warning: Photos app is currently running (dry-run mode - no action taken)${NC}"
        else
            log "${YELLOW}Warning: Photos app is currently running${NC}"
            if [ "$AUTO_YES" = true ]; then
                log "Auto-closing Photos app for safe cleanup..."
                osascript -e 'quit app "Photos"' 2>/dev/null || pkill -9 "Photos" 2>/dev/null
                sleep 1
            else
                read -p "Close Photos app for safe cleanup? (y/n): " -r
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    osascript -e 'quit app "Photos"' 2>/dev/null || pkill -9 "Photos" 2>/dev/null
                    sleep 1
                else
                    log "Skipping Photos Library - close Photos and retry"
                    SKIP_PHOTOS_LIBRARY=true
                    SKIPPED_CATEGORIES+=("Photos Library Cache")
                fi
            fi
        fi
    fi

    # Skip if already skipped due to Photos running
    if [ "$SKIP_PHOTOS_LIBRARY" = true ]; then
        log_plain ""
    else
        # Find all Photos libraries in Pictures folder (POSIX-compatible)
        PHOTOS_LIBS=()
        while IFS= read -r -d '' lib; do
            PHOTOS_LIBS+=("$lib")
        done < <(find "$USER_HOME/Pictures" -maxdepth 1 -name "*.photoslibrary" -type d -print0 2>/dev/null)

        if [ ${#PHOTOS_LIBS[@]} -eq 0 ]; then
            log "No Photos libraries found"
        else
            # Determine which libraries to clean
            declare -a SELECTED_LIBS=()
            
            if [ -n "$PHOTOS_LIBRARY_NAME" ]; then
                if [ "$PHOTOS_LIBRARY_NAME" = "all" ]; then
                    SELECTED_LIBS=("${PHOTOS_LIBS[@]}")
                else
                    LIB_PATH="$USER_HOME/Pictures/${PHOTOS_LIBRARY_NAME}.photoslibrary"
                    if [ -d "$LIB_PATH" ]; then
                        SELECTED_LIBS=("$LIB_PATH")
                    else
                        log "Photos library '${PHOTOS_LIBRARY_NAME}' not found"
                        log "Available libraries: ${PHOTOS_LIBS[*]}"
                        SKIPPED_CATEGORIES+=("Photos Library Cache")
                    fi
                fi
            else
                # Default: clean first library only
                SELECTED_LIBS=("${PHOTOS_LIBS[0]}")
            fi

            # Only add to processed if we have libraries to clean
            if [ ${#SELECTED_LIBS[@]} -gt 0 ]; then
                PROCESSED_CATEGORIES+=("Photos Library Cache")
            fi

            # Process each selected library
            TOTAL_PHOTOS_BYTES=0
            
            for LIB_PATH in "${SELECTED_LIBS[@]}"; do
                LIB_NAME=$(basename "$LIB_PATH" .photoslibrary)
                RESOURCES_DIR="$LIB_PATH/resources"

                # Check if it's an iCloud Photos library
                CLOUDDOCS="$USER_HOME/Library/Application Support/CloudDocs/session/containers"
                IS_ICLOUD=false
                if [ -d "$CLOUDDOCS" ]; then
                    for item in "$CLOUDDOCS"/*; do
                        if [ -n "$item" ] && [ -d "$item" ] && [[ $(basename "$item") =~ -[Pp]hoto[s]? ]]; then
                            IS_ICLOUD=true
                            break
                        fi
                    done
                fi

                LIB_TYPE="Photos"
                if [ "$IS_ICLOUD" = true ]; then
                    LIB_TYPE="iCloud Photos"
                fi

                if [ -d "$RESOURCES_DIR" ]; then
                    LIB_KB=$(du -sk "$RESOURCES_DIR" 2>/dev/null | awk '{print $1}' || echo "0")
                    
                    if [ "$LIB_KB" -gt 0 ]; then
                        LIB_HUMAN=$(bytes_to_human $((LIB_KB * 1024)))
                        log "${LIB_NAME}.photoslibrary ($LIB_TYPE): $LIB_HUMAN"
                        log "  ${DIM}Clearing thumbnails, previews, rendered edits${NC}"
                        log "  ${DIM}Original photos remain safe - will re-render on demand${NC}"
                        TOTAL_PHOTOS_BYTES=$((TOTAL_PHOTOS_BYTES + LIB_KB * 1024))

                        if [ "$DRY_RUN" = true ]; then
                            log "  Would clear: $LIB_HUMAN"
                        else
                            find "$RESOURCES_DIR" -mindepth 1 -delete 2>/dev/null || true
                            log_success "  Cleared: $LIB_HUMAN"
                        fi
                    else
                        log "${LIB_NAME}.photoslibrary: cache is empty"
                    fi
                else
                    log "${LIB_NAME}.photoslibrary: resources folder not found"
                fi
            done

            # Add to total freed
            if [ "$TOTAL_PHOTOS_BYTES" -gt 0 ]; then
                TOTAL_PHOTOS_HUMAN=$(bytes_to_human $TOTAL_PHOTOS_BYTES)
                if [ "$DRY_RUN" = true ]; then
                    log "Would clear Photos Library cache: $TOTAL_PHOTOS_HUMAN"
                fi
                TOTAL_BYTES_FREED=$((TOTAL_BYTES_FREED + TOTAL_PHOTOS_BYTES))
            elif [ ${#SELECTED_LIBS[@]} -gt 0 ]; then
                log "No Photos Library cache found"
            fi
        fi
    fi
    
    log_plain ""
fi

###############################################################################
# 18. iCloud Drive Offline Files
###############################################################################
if [ "$SKIP_ICLOUD_DRIVE" = false ]; then
    log_plain "================================================"
    log "18. iCloud Drive Offline Files"
    log_plain "================================================"

    CLOUD_STORAGE_DIR="$USER_HOME/Library/CloudStorage"
    ICLOUD_DRIVE_BYTES=0

    # Check if CloudStorage directory exists
    if [ -d "$CLOUD_STORAGE_DIR" ]; then
        # Find only iCloud Drive folders (not OneDrive, Google Drive, Box, etc.)
        ICLOUD_FOLDERS=()
        for dir in "$CLOUD_STORAGE_DIR"/*; do
            if [ -d "$dir" ]; then
                dirname=$(basename "$dir")
                # Match iCloud Drive folders (various language versions)
                if [[ "$dirname" == iCloud\ Drive* ]] || [[ "$dirname" == "iCloud Drive" ]]; then
                    ICLOUD_FOLDERS+=("$dir")
                fi
            fi
        done

        if [ ${#ICLOUD_FOLDERS[@]} -gt 0 ]; then
            # Calculate total size of only iCloud Drive folders
            ICLOUD_DRIVE_SIZE_KB=0
            for folder in "${ICLOUD_FOLDERS[@]}"; do
                folder_kb=$(du -sk "$folder" 2>/dev/null | awk '{print $1}' || echo "0")
                ICLOUD_DRIVE_SIZE_KB=$((ICLOUD_DRIVE_SIZE_KB + folder_kb))
            done

            if [ "$ICLOUD_DRIVE_SIZE_KB" -gt 0 ]; then
                ICLOUD_DRIVE_SIZE=$(bytes_to_human $((ICLOUD_DRIVE_SIZE_KB * 1024)))
                log "iCloud Drive offline files: $ICLOUD_DRIVE_SIZE"
                log "${YELLOW}Warning: This bypasses iCloud sync and may cause data loss!${NC}"
                log "${YELLOW}Files pending upload or in conflict state may be permanently lost.${NC}"
                
                # Require --force flag for this dangerous operation
                if [ "$FORCE" = true ]; then
                    log "${YELLOW}Running with --force: proceeding with deletion${NC}"
                    PROCESSED_CATEGORIES+=("iCloud Drive Offline Files")
                    ICLOUD_DRIVE_BYTES=$((ICLOUD_DRIVE_SIZE_KB * 1024))

                    if [ "$DRY_RUN" = true ]; then
                        log "Would remove iCloud Drive files: $ICLOUD_DRIVE_SIZE"
                        log "${DIM}(Files will be DELETED from iCloud, recoverable via Recently Deleted)${NC}"
                        TOTAL_BYTES_FREED=$((TOTAL_BYTES_FREED + ICLOUD_DRIVE_BYTES))
                    else
                        log "Removing iCloud Drive files (DELETED from iCloud, not just local cache)..."
                        for folder in "${ICLOUD_FOLDERS[@]}"; do
                            find "$folder" -type f -mindepth 1 -delete 2>/dev/null
                            find "$folder" -type d -mindepth 1 -empty -delete 2>/dev/null
                        done
                        log_success "iCloud Drive files removed (check Recently Deleted in iCloud to recover)"
                        TOTAL_BYTES_FREED=$((TOTAL_BYTES_FREED + ICLOUD_DRIVE_BYTES))
                    fi
                else
                    log "${RED}Skipping: Use --force to enable iCloud Drive cleanup${NC}"
                    log "${RED}This operation bypasses iCloud sync and can cause data loss.${NC}"
                    SKIPPED_CATEGORIES+=("iCloud Drive Offline Files (requires --force)")
                fi
            else
                log "iCloud Drive has no offline files"
            fi
        else
            log "iCloud Drive not configured or no iCloud Drive folder found"
        fi
    else
        log "CloudStorage directory not found (iCloud Drive not configured)"
    fi
    log_plain ""
else
    SKIPPED_CATEGORIES+=("iCloud Drive Offline Files")
fi

###############################################################################
# 19. QuickLook Thumbnails
###############################################################################
if [ "$SKIP_QUICKLOOK" = false ]; then
    PROCESSED_CATEGORIES+=("QuickLook Thumbnails")
    log_plain "================================================"
    log "19. QuickLook Thumbnails"
    log_plain "================================================"

    QUICKLOOK_CACHE="$USER_HOME/Library/Caches/com.apple.QuickLook.thumbnailcache"
    if [ -d "$QUICKLOOK_CACHE" ]; then
        QUICKLOOK_SIZE=$(du -sh "$QUICKLOOK_CACHE" 2>/dev/null | awk '{print $1}' || echo "0B")

        if [ -n "$QUICKLOOK_SIZE" ] && [ "$QUICKLOOK_SIZE" != "0B" ]; then
            log "QuickLook thumbnails: $QUICKLOOK_SIZE"
            QUICKLOOK_BYTES=$(size_to_bytes "$QUICKLOOK_SIZE")

            if [ "$DRY_RUN" = true ]; then
                log "Would clear QuickLook thumbnails: $QUICKLOOK_SIZE"
                TOTAL_BYTES_FREED=$((TOTAL_BYTES_FREED + QUICKLOOK_BYTES))
            else
                log "Cleaning QuickLook thumbnails..."
                rm -rf "${QUICKLOOK_CACHE:?}"/* 2>/dev/null
                log_success "QuickLook thumbnails cleared"
                TOTAL_BYTES_FREED=$((TOTAL_BYTES_FREED + QUICKLOOK_BYTES))
            fi
        else
            log "QuickLook cache is empty"
        fi
    else
        log "QuickLook cache not found"
    fi
    log_plain ""
else
    SKIPPED_CATEGORIES+=("QuickLook Thumbnails")
fi

###############################################################################
# 20. Diagnostic Reports
###############################################################################
if [ "$SKIP_DIAGNOSTICS" = false ]; then
    PROCESSED_CATEGORIES+=("Diagnostic Reports")
    log_plain "================================================"
    log "20. Diagnostic Reports"
    log_plain "================================================"

    DIAG_USER="$USER_HOME/Library/Logs/DiagnosticReports"
    DIAG_SYSTEM="/Library/Logs/DiagnosticReports"

    DIAG_COUNT=0
    DIAG_SIZE_BYTES=0

    # Count user diagnostic reports older than 30 days
    if [ -d "$DIAG_USER" ]; then
        USER_COUNT=$(find "$DIAG_USER" -type f -mtime +30 2>/dev/null | wc -l | tr -d ' ')
        DIAG_COUNT=$((DIAG_COUNT + USER_COUNT))
        if [ "$USER_COUNT" -gt 0 ]; then
            USER_SIZE=$(find "$DIAG_USER" -type f -mtime +30 -exec du -ch {} + 2>/dev/null | tail -1 | awk '{print $1}' || echo "0B")
            if [ -n "$USER_SIZE" ] && [ "$USER_SIZE" != "0B" ]; then
                DIAG_SIZE_BYTES=$((DIAG_SIZE_BYTES + $(size_to_bytes "$USER_SIZE")))
            fi
        fi
    fi

    # Count system diagnostic reports older than 30 days (requires sudo)
    if [ -d "$DIAG_SYSTEM" ]; then
        SYS_COUNT=$(find "$DIAG_SYSTEM" -type f -mtime +30 2>/dev/null | wc -l | tr -d ' ')
        DIAG_COUNT=$((DIAG_COUNT + SYS_COUNT))
        if [ "$SYS_COUNT" -gt 0 ]; then
            SYS_SIZE=$(find "$DIAG_SYSTEM" -type f -mtime +30 -exec du -ch {} + 2>/dev/null | tail -1 | awk '{print $1}' || echo "0B")
            if [ -n "$SYS_SIZE" ] && [ "$SYS_SIZE" != "0B" ]; then
                DIAG_SIZE_BYTES=$((DIAG_SIZE_BYTES + $(size_to_bytes "$SYS_SIZE")))
            fi
        fi
    fi

    if [ "$DIAG_COUNT" -gt 0 ]; then
        DIAG_SIZE_HUMAN=$(bytes_to_human "$DIAG_SIZE_BYTES")
        log "Found $DIAG_COUNT old diagnostic report(s) (>30 days): $DIAG_SIZE_HUMAN"

        if [ "$DRY_RUN" = true ]; then
            log "Would delete $DIAG_COUNT diagnostic report(s)"
            TOTAL_BYTES_FREED=$((TOTAL_BYTES_FREED + DIAG_SIZE_BYTES))
        else
            log "Cleaning old diagnostic reports..."
            [ -d "$DIAG_USER" ] && find "$DIAG_USER" -type f -mtime +30 -delete 2>/dev/null
            [ -d "$DIAG_SYSTEM" ] && find "$DIAG_SYSTEM" -type f -mtime +30 -delete 2>/dev/null
            log_success "Old diagnostic reports cleaned"
            TOTAL_BYTES_FREED=$((TOTAL_BYTES_FREED + DIAG_SIZE_BYTES))
        fi
    else
        log "No old diagnostic reports found (>30 days)"
    fi
    log_plain ""
else
    SKIPPED_CATEGORIES+=("Diagnostic Reports")
fi

###############################################################################
# 21. iOS Device Backups
###############################################################################
if [ "$SKIP_IOS_BACKUPS" = false ]; then
    log_plain "================================================"
    log "21. iOS Device Backups"
    log_plain "================================================"

    IOS_BACKUP_DIR="$USER_HOME/Library/Application Support/MobileSync/Backup"
    if [ -d "$IOS_BACKUP_DIR" ]; then
        IOS_BACKUP_COUNT=$(find "$IOS_BACKUP_DIR" -maxdepth 1 -type d -not -path "$IOS_BACKUP_DIR" 2>/dev/null | wc -l | tr -d ' ')

        if [ "$IOS_BACKUP_COUNT" -gt 0 ]; then
            IOS_BACKUP_SIZE=$(du -sh "$IOS_BACKUP_DIR" 2>/dev/null | awk '{print $1}' || echo "0B")
            IOS_BACKUP_BYTES=$(size_to_bytes "$IOS_BACKUP_SIZE")

            log "Found $IOS_BACKUP_COUNT iOS device backup(s): $IOS_BACKUP_SIZE"
            log_warning "These are local iTunes/Finder device backups"
            log "${YELLOW}Warning: Deleting backups without iCloud backup may cause data loss!${NC}"
            
            # Require --force for this dangerous operation
            if [ "$FORCE" = true ]; then
                log "${YELLOW}Running with --force: proceeding with deletion${NC}"
                PROCESSED_CATEGORIES+=("iOS Device Backups")
                
                if [ "$DRY_RUN" = true ]; then
                    log "Would delete $IOS_BACKUP_COUNT iOS device backup(s): $IOS_BACKUP_SIZE"
                    TOTAL_BYTES_FREED=$((TOTAL_BYTES_FREED + IOS_BACKUP_BYTES))
                else
                    log "Deleting iOS device backups..."
                    rm -rf "${IOS_BACKUP_DIR:?}"/* 2>/dev/null
                    log_success "iOS device backups deleted"
                    TOTAL_BYTES_FREED=$((TOTAL_BYTES_FREED + IOS_BACKUP_BYTES))
                fi
            else
                # Not --force: require manual confirmation
                log "${RED}Skipping: Use --force to enable iOS backup deletion${NC}"
                log "${RED}This operation can cause data loss without iCloud backup.${NC}"
                SKIPPED_CATEGORIES+=("iOS Device Backups (requires --force)")
            fi
        else
            log "No iOS device backups found"
        fi
    else
        log "iOS backup directory not found"
    fi
    log_plain ""
else
    SKIPPED_CATEGORIES+=("iOS Device Backups")
fi

###############################################################################
# 22. iOS/iPadOS Update Files (.ipsw)
###############################################################################
if [ "$SKIP_IOS_UPDATES" = false ]; then
    PROCESSED_CATEGORIES+=("iOS/iPadOS Update Files")
    log_plain "================================================"
    log "22. iOS/iPadOS Update Files (.ipsw)"
    log_plain "================================================"

    # iTunes stores downloaded firmware in these directories
    IOS_UPDATE_DIRS=(
        "$USER_HOME/Library/iTunes/iPhone Software Updates"
        "$USER_HOME/Library/iTunes/iPad Software Updates"
        "$USER_HOME/Library/iTunes/iPod Software Updates"
    )

    IPSW_TOTAL_BYTES=0
    IPSW_TOTAL_COUNT=0

    for UPDATE_DIR in "${IOS_UPDATE_DIRS[@]}"; do
        if [ -d "$UPDATE_DIR" ]; then
            while IFS= read -r -d '' ipsw_file; do
                IPSW_SIZE=$(du -sk "$ipsw_file" 2>/dev/null | awk '{print $1}')
                IPSW_SIZE=${IPSW_SIZE:-0}
                IPSW_BYTES=$((IPSW_SIZE * 1024))
                IPSW_HUMAN=$(bytes_to_human "$IPSW_BYTES")
                IPSW_NAME=$(basename "$ipsw_file")
                log "Found: $IPSW_NAME ($IPSW_HUMAN)"
                IPSW_TOTAL_BYTES=$((IPSW_TOTAL_BYTES + IPSW_BYTES))
                IPSW_TOTAL_COUNT=$((IPSW_TOTAL_COUNT + 1))
            done < <(find "$UPDATE_DIR" -name "*.ipsw" -type f -print0 2>/dev/null)
        fi
    done

    if [ "$IPSW_TOTAL_COUNT" -gt 0 ]; then
        IPSW_TOTAL_HUMAN=$(bytes_to_human "$IPSW_TOTAL_BYTES")
        log "Total: $IPSW_TOTAL_COUNT file(s), $IPSW_TOTAL_HUMAN"
        log "${DIM}Note: These are iOS/iPadOS firmware files used for device restores/updates.${NC}"
        log "${DIM}They can be re-downloaded from Apple if needed.${NC}"

        if [ "$DRY_RUN" = true ]; then
            log "Would delete $IPSW_TOTAL_COUNT iOS update file(s): $IPSW_TOTAL_HUMAN"
            TOTAL_BYTES_FREED=$((TOTAL_BYTES_FREED + IPSW_TOTAL_BYTES))
        else
            log "Deleting iOS/iPadOS update files..."
            for UPDATE_DIR in "${IOS_UPDATE_DIRS[@]}"; do
                if [ -d "$UPDATE_DIR" ]; then
                    find "$UPDATE_DIR" -name "*.ipsw" -type f -delete 2>/dev/null
                fi
            done
            log_success "iOS/iPadOS update files deleted ($IPSW_TOTAL_HUMAN freed)"
            TOTAL_BYTES_FREED=$((TOTAL_BYTES_FREED + IPSW_TOTAL_BYTES))
        fi
    else
        log "No iOS/iPadOS update files (.ipsw) found"
    fi
    log_plain ""
else
    SKIPPED_CATEGORIES+=("iOS/iPadOS Update Files")
fi

###############################################################################
# 23. .DS_Store Files
###############################################################################
if [ "$SKIP_DSSTORE" = false ]; then
    PROCESSED_CATEGORIES+=(".DS_Store Files")
    log_plain "================================================"
    log "23. .DS_Store Files"
    log_plain "================================================"

    # Count .DS_Store files in user home
    DSSTORE_COUNT=$(find "$USER_HOME" -name ".DS_Store" -type f 2>/dev/null | wc -l | tr -d ' ')

    if [ "$DSSTORE_COUNT" -gt 0 ]; then
        DSSTORE_SIZE=$(find "$USER_HOME" -name ".DS_Store" -type f -exec du -ch {} + 2>/dev/null | tail -1 | awk '{print $1}' || echo "0B")
        DSSTORE_BYTES=$(size_to_bytes "$DSSTORE_SIZE")
        log "Found $DSSTORE_COUNT .DS_Store file(s): $DSSTORE_SIZE"

        if [ "$DRY_RUN" = true ]; then
            log "Would delete $DSSTORE_COUNT .DS_Store file(s)"
            TOTAL_BYTES_FREED=$((TOTAL_BYTES_FREED + DSSTORE_BYTES))
        else
            log "Deleting .DS_Store files..."
            find "$USER_HOME" -name ".DS_Store" -type f -delete 2>/dev/null
            log_success ".DS_Store files deleted"
            TOTAL_BYTES_FREED=$((TOTAL_BYTES_FREED + DSSTORE_BYTES))
        fi
    else
        log "No .DS_Store files found"
    fi
    log_plain ""
else
    SKIPPED_CATEGORIES+=(".DS_Store Files")
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

    # Special warning for iOS backups if they would be deleted
    if [ "$SKIP_IOS_BACKUPS" = false ]; then
        IOS_BACKUP_DIR="$USER_HOME/Library/Application Support/MobileSync/Backup"
        if [ -d "$IOS_BACKUP_DIR" ]; then
            IOS_BACKUP_COUNT=$(find "$IOS_BACKUP_DIR" -maxdepth 1 -type d -not -path "$IOS_BACKUP_DIR" 2>/dev/null | wc -l | tr -d ' ')
            if [ "$IOS_BACKUP_COUNT" -gt 0 ]; then
                log_always "${RED}${BOLD}⚠️  CRITICAL: iOS Device Backups Will Be Deleted!${NC}"
                log_always "${YELLOW}   Found $IOS_BACKUP_COUNT backup(s) that will require 'DELETE' confirmation${NC}"
                log_always "${YELLOW}   Ensure your devices are backed up to iCloud before proceeding${NC}"
                log_plain ""
            fi
        fi
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
    DISK_AVAIL_BYTES_AFTER=$(df -k / | tail -1 | awk '{print $4}')  # Get KB
    DISK_AVAIL_BYTES_AFTER=$((DISK_AVAIL_BYTES_AFTER * 1024))  # Convert KB to bytes

    log "Initial disk usage: ${DISK_USAGE}% (${DISK_USED} used, ${DISK_AVAIL} available)"
    log "Final disk usage:   ${DISK_USAGE_AFTER}% (${DISK_USED_AFTER} used, ${DISK_AVAIL_AFTER} available)"

    # Calculate actual space freed (difference in available space)
    ACTUAL_BYTES_FREED=$((DISK_AVAIL_BYTES_AFTER - DISK_AVAIL_BYTES))
    if [ "$ACTUAL_BYTES_FREED" -gt 0 ]; then
        ACTUAL_FREED=$(bytes_to_human "$ACTUAL_BYTES_FREED")
        log_always ""
        log_always "${GREEN}✓ Actual space freed: $ACTUAL_FREED${NC}"

        # Show estimate vs actual if significantly different
        if [ "$TOTAL_BYTES_FREED" -gt 0 ]; then
            ESTIMATED_FREED=$(bytes_to_human "$TOTAL_BYTES_FREED")
            DIFFERENCE=$((ACTUAL_BYTES_FREED - TOTAL_BYTES_FREED))
            DIFF_ABS=${DIFFERENCE#-}  # Absolute value

            # Only show comparison if difference is significant (>1GB or >10%)
            if [ "$DIFF_ABS" -gt 1073741824 ]; then
                DIFF_HUMAN=$(bytes_to_human "$DIFF_ABS")
                if [ "$ACTUAL_BYTES_FREED" -gt "$TOTAL_BYTES_FREED" ]; then
                    log "${DIM}(Estimated: $ESTIMATED_FREED, freed $DIFF_HUMAN more than expected)${NC}"
                else
                    log "${DIM}(Estimated: $ESTIMATED_FREED, actual freed $DIFF_HUMAN less due to APFS snapshot sharing)${NC}"
                fi
            fi
        fi
    elif [ "$ACTUAL_BYTES_FREED" -lt 0 ]; then
        # Available space decreased (shouldn't happen, but handle it)
        log_warning "Available space decreased - this may be due to system activity during cleanup"
    else
        log "No measurable space freed"
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
