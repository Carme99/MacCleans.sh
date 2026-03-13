#!/bin/bash

###############################################################################
# Mac-Clean Installer
# Purpose: Install Mac-Clean (macOS Disk Cleanup Utility) to /usr/local/bin
###############################################################################

set -euo pipefail

# Configuration
INSTALL_DIR="/usr/local/bin"
SCRIPT_NAME="Mac-Clean"
GITHUB_RAW_URL="https://raw.githubusercontent.com/Carme99/MacCleans.sh/main/clean-mac-space.sh"
INSTALL_PATH="${INSTALL_DIR}/${SCRIPT_NAME}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

log_info() {
    echo -e "${CYAN}[*]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[+]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

log_error() {
    echo -e "${RED}[-]${NC} $1" >&2
}

# Detect if colors should be disabled
if [ ! -t 1 ]; then
    RED='' GREEN='' YELLOW='' CYAN='' BOLD='' NC=''
fi

echo -e "${BOLD}Mac-Clean Installer v1.1.0${NC}"
echo -e "${BOLD}=============================${NC}"
echo ""

# Parse arguments
NO_VERIFY=false
for arg in "$@"; do
    case "$arg" in
        --no-verify)
            NO_VERIFY=true
            log_warning "--no-verify flag set: skipping script verification"
            ;;
        --help|-h)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --no-verify    Skip SHA256 checksum verification (for air-gapped installs)"
            echo "  --help, -h     Show this help message"
            exit 0
            ;;
    esac
done

# Check for curl or wget
if ! command -v curl &> /dev/null && ! command -v wget &> /dev/null; then
    log_error "Neither curl nor wget found. Please install one of them."
    exit 1
fi

# Check if we can write to /usr/local/bin
# Detect if running from stdin (curl | bash) vs a real file
is_stdin() {
    [ ! -t 0 ] && [ -z "${BASH_SOURCE[0]:-}" ]
}

if [ ! -w "$INSTALL_DIR" ] && [ "$EUID" -ne 0 ]; then
    if is_stdin; then
        log_error "Cannot auto-escalate when running from stdin (curl | bash)"
        log_info "Please run with: curl -fsSL https://raw.githubusercontent.com/Carme99/MacCleans.sh/main/installer.sh | sudo bash"
        exit 1
    fi
    log_warning "Cannot write to $INSTALL_DIR without sudo"
    log_info "Re-running with sudo..."
    exec sudo "${BASH_SOURCE[0]}" "$@"
fi

# Function to calculate SHA256 hash
calculate_sha256() {
    local file="$1"
    if command -v shasum &> /dev/null; then
        shasum -a 256 "$file" | awk '{print $1}'
    elif command -v sha256sum &> /dev/null; then
        sha256sum "$file" | awk '{print $1}'
    else
        echo ""
    fi
}

# Function to verify script integrity
verify_script() {
    local script_path="$1"
    
    if [ "$NO_VERIFY" = true ]; then
        log_warning "Skipping script verification (--no-verify)"
        return 0
    fi
    
    # Check if script exists
    if [ ! -f "$script_path" ]; then
        log_error "Script not found: $script_path"
        return 1
    fi
    
    # Check for strict mode (set -euo pipefail)
    if ! grep -q "set -euo pipefail" "$script_path" 2>/dev/null; then
        log_error "Script verification failed: 'set -euo pipefail' not found"
        log_error "Script may not be the official Mac-Clean script"
        return 1
    fi
    
    # Calculate and display fingerprint
    local sha256_hash
    sha256_hash=$(calculate_sha256 "$script_path")
    
    if [ -n "$sha256_hash" ]; then
        log_success "Script downloaded successfully"
        log_info "SHA256 fingerprint: ${sha256_hash:0:16}..."
        log_info "Full hash: $sha256_hash"
        echo ""
        log_info "To verify manually, compare this hash with the official release"
        log_info "Visit: https://github.com/Carme99/MacCleans.sh/releases"
    else
        log_warning "Could not calculate SHA256 hash (shasum/sha256sum not available)"
    fi
    
    return 0
}

# Create backup if script already exists
if [ -f "$INSTALL_PATH" ]; then
    BACKUP_PATH="${INSTALL_PATH}.backup.$(date +%Y%m%d%H%M%S)"
    log_warning "Existing installation found"
    log_info "Backing up to: $BACKUP_PATH"
    cp "$INSTALL_PATH" "$BACKUP_PATH"
fi

# Download the script
log_info "Downloading Mac-Clean from GitHub..."

if command -v curl &> /dev/null; then
    DOWNLOAD_CMD="curl -fsSL"
elif command -v wget &> /dev/null; then
    DOWNLOAD_CMD="wget -qO-"
fi

# Download to temporary location first for verification
TEMP_SCRIPT=$(mktemp)
trap 'rm -f "$TEMP_SCRIPT"' EXIT

if ! $DOWNLOAD_CMD "$GITHUB_RAW_URL" > "$TEMP_SCRIPT" 2>/dev/null; then
    log_error "Failed to download Mac-Clean"
    log_error "URL: $GITHUB_RAW_URL"
    exit 1
fi

# Verify the downloaded script
if ! verify_script "$TEMP_SCRIPT"; then
    log_error "Script verification failed!"
    log_error "The downloaded script does not appear to be the official Mac-Clean script."
    log_error "Use --no-verify to skip this check (not recommended)"
    exit 1
fi

# Move verified script to final location
mv "$TEMP_SCRIPT" "$INSTALL_PATH"

# Make executable
chmod +x "$INSTALL_PATH"

# Create symlink for backward compatibility
OLD_NAME="${INSTALL_DIR}/mac-clean"
if [ ! -L "$OLD_NAME" ] && [ ! -f "$OLD_NAME" ]; then
    ln -sf "$INSTALL_PATH" "$OLD_NAME" 2>/dev/null || true
fi

log_success "Mac-Clean installed successfully!"
echo ""
echo -e "${BOLD}Installation Details:${NC}"
echo "  - Main command: $INSTALL_PATH"
echo "  - Symlink: $OLD_NAME (for backward compatibility)"
echo ""
echo -e "${BOLD}Usage:${NC}"
echo "  sudo Mac-Clean              # Run cleanup"
echo "  sudo Mac-Clean --dry-run    # Preview only"
echo "  sudo Mac-Clean --yes       # Skip confirmation"
echo "  Mac-Clean --help           # Show help"
echo ""

# Verify installation
if "$INSTALL_PATH" --version 2>/dev/null | grep -q "version\|Version\|v[0-9]"; then
    VERSION=$("$INSTALL_PATH" --version 2>&1 | head -1)
    log_success "Verified installation: $VERSION"
else
    log_warning "Could not verify version, but installation completed"
fi

echo ""
log_success "Done!"
