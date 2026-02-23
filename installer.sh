#!/bin/bash

###############################################################################
# Mac-Clean Installer
# Purpose: Install Mac-Clean (macOS Disk Cleanup Utility) to /usr/local/bin
###############################################################################

set -euo pipefail

# Check for sudo at the start - re-run with sudo if needed
if [ "$EUID" -ne 0 ]; then
    exec sudo bash "$0" "$@"
fi

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

echo -e "${BOLD}Mac-Clean Installer v1.0.0${NC}"
echo -e "${BOLD}=============================${NC}"
echo ""

# Check for curl or wget
if ! command -v curl &> /dev/null && ! command -v wget &> /dev/null; then
    log_error "Neither curl nor wget found. Please install one of them."
    exit 1
fi

# Check if we can write to /usr/local/bin (should already be root due to early check)
if [ ! -w "$INSTALL_DIR" ]; then
    log_error "Cannot write to $INSTALL_DIR. Check permissions."
    exit 1
fi

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

if ! $DOWNLOAD_CMD "$GITHUB_RAW_URL" > "$INSTALL_PATH" 2>/dev/null; then
    log_error "Failed to download Mac-Clean"
    log_info "Trying alternative URL..."
    
    # Try main branch
    ALT_URL="https://raw.githubusercontent.com/Carme99/MacCleans.sh/master/clean-mac-space.sh"
    if ! $DOWNLOAD_CMD "$ALT_URL" > "$INSTALL_PATH" 2>/dev/null; then
        log_error "Failed to download from alternative URL as well"
        exit 1
    fi
fi

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
