#!/bin/bash
set -e

# SHTT Installer Script
# Usage: curl -sSf https://shtt.show/install.sh | sh
# Or: curl -sSf https://raw.githubusercontent.com/shtt-show/shtt/trunk/install.sh | sh

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
GITHUB_REPO="shtt-show/shtt"
BINARY_NAME="shtt"
INSTALL_DIR="$HOME/.cargo/bin"

# Helper functions
log() {
    echo "${BLUE}[INFO]${NC} $1" >&2
}

warn() {
    echo "${YELLOW}[WARN]${NC} $1" >&2
}

error() {
    echo "${RED}[ERROR]${NC} $1" >&2
}

success() {
    echo "${GREEN}[SUCCESS]${NC} $1" >&2
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
check_prerequisites() {
    log "Checking prerequisites..."
    
    if ! command_exists curl; then
        error "curl is required but not installed. Please install curl and try again."
        exit 1
    fi
    
    if ! command_exists tar; then
        error "tar is required but not installed. Please install tar and try again."
        exit 1
    fi
    
    if ! command_exists cargo; then
        error "cargo is required but not installed."
        echo "Please install Rust and Cargo from https://rustup.rs/ and try again."
        exit 1
    fi
    
    success "All prerequisites are installed"
}

# Get the latest release tag from GitHub by scraping the tags page
get_latest_release() {
    log "Fetching latest release information..."
    
    # Scrape the GitHub tags page to find the latest version tag
    local latest_tag
    latest_tag=$(curl -s "https://github.com/$GITHUB_REPO/tags" | \
        grep -o '/'"$GITHUB_REPO"'/releases/tag/v[0-9]*\.[0-9]*\.[0-9]*' | \
        sed 's|.*/tag/||' | \
        sort -rV | \
        head -n1 2>/dev/null)
    
    # If still no tag, default to trunk
    if [ -z "$latest_tag" ]; then
        error "Could not determine latest release, using trunk branch"
        exit 1
    else
        echo "$latest_tag" | tr -d '\n'
    fi
}

# Download and extract source code
download_and_extract() {
    local version="$1"
    local temp_dir="$2"
    
    log "Downloading SHTT $version..."
    
    local download_url
    if [ "$version" = "trunk" ]; then
        download_url="https://github.com/$GITHUB_REPO/archive/refs/heads/trunk.tar.gz"
    else
        download_url="https://github.com/$GITHUB_REPO/archive/refs/tags/$version.tar.gz"
    fi
    
    # Download and extract in one command
    if ! curl -sSL "$download_url" | tar -xz -C "$temp_dir" --strip-components=1; then
        error "Failed to download and extract SHTT source code"
        exit 1
    fi
    
    success "Source code downloaded and extracted"
}

# Install SHTT using cargo
install_shtt() {
    local source_dir="$1"
    
    log "Installing SHTT using cargo..."
    
    cd "$source_dir"
    
    # Install using cargo
    if ! cargo install --path . --root "$HOME/.cargo"; then
        error "Failed to install SHTT with cargo"
        exit 1
    fi
    
    success "SHTT installed successfully"
}

# Verify installation
verify_installation() {
    log "Verifying installation..."
    
    # Check if the binary exists
    if [ ! -f "$INSTALL_DIR/$BINARY_NAME" ]; then
        error "Installation verification failed: $BINARY_NAME not found in $INSTALL_DIR"
        exit 1
    fi
    
    # Check if it's executable
    if [ ! -x "$INSTALL_DIR/$BINARY_NAME" ]; then
        error "Installation verification failed: $BINARY_NAME is not executable"
        exit 1
    fi
    
    # Try to run it
    if ! "$INSTALL_DIR/$BINARY_NAME" --version >/dev/null 2>&1; then
        warn "Installation completed but version check failed. The binary may still work."
    fi
    
    success "Installation verified"
}

# Check if PATH includes cargo bin directory
check_path() {
    if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
        warn "Warning: $INSTALL_DIR is not in your PATH"
        echo ""
        echo "To use shtt, either:"
        echo "  1. Add ~/.cargo/bin to your PATH by adding this to your shell profile:"
        echo "     export PATH=\"$INSTALL_DIR:\$PATH\""
        echo "  2. Or use the full path: $INSTALL_DIR/shtt"
        echo ""
        echo "For most systems, you can run:"
        echo "  echo 'export PATH=\"$INSTALL_DIR:\$PATH\"' >> ~/.bashrc"
        echo "  source ~/.bashrc"
        echo ""
    fi
}

# Main installation function
main() {
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                    SHTT Installer                            ║"
    echo "║              Simple History Tracking Tool                    ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    
    check_prerequisites
    
    # Create temporary directory
    local temp_dir
    temp_dir=$(mktemp -d)
    trap "rm -rf '$temp_dir'" EXIT
    
    # Get latest version
    local version
    version=$(get_latest_release)
    log "Installing SHTT version: [$version]"
    
    # Download and install
    download_and_extract "$version" "$temp_dir"
    install_shtt "$temp_dir"
    verify_installation
    check_path
    
    echo ""
    success "SHTT installation completed!"
    echo ""
    echo "Quick start:"
    echo "  shtt dump     # Show changes in current directory"
    echo "  shtt save     # Commit and push all changes"
    echo "  shtt pull     # Pull latest changes from origin"
    echo "  shtt wipe     # Reset to origin state"
    echo ""
    echo "For more information, visit: https://github.com/$GITHUB_REPO"
    echo ""
}

# Run main function
main "$@"
