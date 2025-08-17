#!/bin/bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored messages
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# ASCII banner
echo -e "${BLUE}"
echo "╔═══════════════════════════════════════╗"
echo "║     DevBox Installation Script        ║"
echo "║     Claude Code Docker Container      ║"
echo "╚═══════════════════════════════════════╝"
echo -e "${NC}"

# Configuration
GITHUB_REPO="https://github.com/YuryYudin/devbox.git"
TARGET_DIR="$HOME/.devbox"

# Check if Git is installed
print_step "Checking Git installation..."
if ! command -v git &> /dev/null; then
    print_error "Git is not installed."
    echo ""
    echo "Please install Git first:"
    echo "  - macOS: brew install git"
    echo "  - Linux: sudo apt-get install git (or equivalent)"
    echo "  - Windows: https://git-scm.com/download/win"
    exit 1
fi
print_info "Git is installed ✓"

# Check if Docker is installed
print_step "Checking Docker installation..."
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed."
    echo ""
    echo "Please install Docker first:"
    echo "  - macOS: https://docs.docker.com/desktop/install/mac-install/"
    echo "  - Linux: https://docs.docker.com/engine/install/"
    echo "  - Windows: https://docs.docker.com/desktop/install/windows-install/"
    exit 1
fi
print_info "Docker is installed ✓"

# Check if Docker daemon is running
print_step "Checking Docker daemon status..."
if ! docker info &> /dev/null; then
    print_error "Docker daemon is not running."
    echo ""
    echo "Please start Docker:"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "  - Open Docker Desktop application"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "  - Run: sudo systemctl start docker"
        echo "  - Enable at boot: sudo systemctl enable docker"
    fi
    exit 1
fi
print_info "Docker daemon is running ✓"

# Function to check if directory is empty
is_directory_empty() {
    [ -z "$(ls -A "$1" 2>/dev/null)" ]
}

# Handle existing installation
if [ -d "${TARGET_DIR}" ]; then
    # Check if directory is empty
    if is_directory_empty "${TARGET_DIR}"; then
        print_info "Directory ${TARGET_DIR} exists but is empty. Proceeding with installation."
	rmdir ${TARGET_DIR}
	print_info "Removed empty target dir."
    else
        print_warning "Directory ${TARGET_DIR} already exists and contains files."
        
        # Check if it's a git repository
        if [ -d "${TARGET_DIR}/.git" ]; then
            echo "Existing DevBox installation found (Git repository)."
            echo -n "Do you want to update to the latest version? (y/N): "
            # Fix for curl | bash - read from /dev/tty if available
            if [ -t 0 ] || [ -e /dev/tty ]; then
                read -r response < /dev/tty
            else
                print_warning "Cannot read user input when piped through curl."
                print_info "Please run the installer directly:"
                echo "  curl -fsSL https://raw.githubusercontent.com/YuryYudin/devbox/main/install.sh -o install.sh"
                echo "  bash install.sh"
                exit 1
            fi
            if [[ "$response" =~ ^[Yy]$ ]]; then
            print_step "Updating DevBox..."
            cd "${TARGET_DIR}"
            
            # Stash any local changes
            if ! git diff --quiet || ! git diff --cached --quiet; then
                print_info "Stashing local changes..."
                git stash push -m "Auto-stash before update $(date +%Y-%m-%d_%H:%M:%S)"
            fi
            
            # Pull latest changes
            git pull origin main
            print_info "DevBox updated to latest version!"
            
            # Check if there were stashed changes
            if git stash list | grep -q "Auto-stash before update"; then
                print_warning "Local changes were stashed. Run 'cd ${TARGET_DIR} && git stash pop' to restore them."
            fi
            else
                print_info "Installation cancelled. Use existing installation."
                exit 0
            fi
        else
            # Not a git repo, need to backup and reinstall
            echo "Existing DevBox installation found (not Git-controlled)."
            echo -n "Do you want to replace it with the Git-controlled version? (y/N): "
            # Fix for curl | bash - read from /dev/tty if available
            if [ -t 0 ] || [ -e /dev/tty ]; then
                read -r response < /dev/tty
            else
                print_warning "Cannot read user input when piped through curl."
                print_info "Please run the installer directly:"
                echo "  curl -fsSL https://raw.githubusercontent.com/YuryYudin/devbox/main/install.sh -o install.sh"
                echo "  bash install.sh"
                exit 1
            fi
            if [[ ! "$response" =~ ^[Yy]$ ]]; then
                print_info "Installation cancelled."
                exit 0
            fi
            print_info "Backing up existing installation..."
            BACKUP_DIR="${TARGET_DIR}.backup.$(date +%Y%m%d-%H%M%S)"
            mv "${TARGET_DIR}" "${BACKUP_DIR}"
            print_info "Existing installation backed up to: ${BACKUP_DIR}"
        fi
    fi
fi

# Clone or update the repository
if [ ! -d "${TARGET_DIR}" ]; then
    print_step "Cloning DevBox repository..."
    git clone "${GITHUB_REPO}" "${TARGET_DIR}"
    print_info "Repository cloned successfully!"
else
    # If we get here, we've already updated above
    print_info "Using updated repository."
fi

# Make scripts executable
print_step "Setting up permissions..."
chmod +x "${TARGET_DIR}/build.sh"
chmod +x "${TARGET_DIR}/devbox.sh"
chmod +x "${TARGET_DIR}/dockerfiles/docker-entrypoint"
chmod +x "${TARGET_DIR}/dockerfiles/init-firewall"
print_info "Scripts made executable"

# Build the Docker container
print_step "Building Docker container..."
echo ""
cd "${TARGET_DIR}"
if ./build.sh; then
    print_info "Docker container built successfully!"
else
    print_error "Failed to build Docker container"
    exit 1
fi

# Create convenience symlink in ~/.local/bin
print_step "Setting up command-line access..."
SYMLINK_DIR="$HOME/.local/bin"
SYMLINK_CREATED=false

# Create ~/.local/bin if it doesn't exist
if [ ! -d "${SYMLINK_DIR}" ]; then
    mkdir -p "${SYMLINK_DIR}"
    print_info "Created directory: ${SYMLINK_DIR}"
fi

# Create symlink
if ln -sf "${TARGET_DIR}/devbox.sh" "${SYMLINK_DIR}/devbox" 2>/dev/null; then
    print_info "Created symlink: ${SYMLINK_DIR}/devbox"
    SYMLINK_CREATED=true
    
    # Check if ~/.local/bin is in PATH
    if [[ ":$PATH:" != *":${SYMLINK_DIR}:"* ]]; then
        print_warning "Note: ${SYMLINK_DIR} is not in your PATH"
        echo "To add it to your PATH, run:"
        if [ -f "$HOME/.zshrc" ]; then
            echo "  echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> ~/.zshrc"
            echo "  source ~/.zshrc"
        else
            echo "  echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> ~/.bashrc"
            echo "  source ~/.bashrc"
        fi
    fi
else
    print_warning "Failed to create symlink in ${SYMLINK_DIR}"
fi

# Installation complete
echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}       Installation completed successfully!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo ""
echo "DevBox has been installed to: ${TARGET_DIR}"
echo "Repository: ${GITHUB_REPO}"
echo ""
echo "To use DevBox:"

if [ "$SYMLINK_CREATED" = true ]; then
    if [[ ":$PATH:" == *":${SYMLINK_DIR}:"* ]]; then
        echo "  From any directory, run: devbox"
    else
        echo "  After adding ~/.local/bin to PATH, run: devbox"
        echo "  Or run directly now: ${SYMLINK_DIR}/devbox"
    fi
else
    echo "  Run directly: ${TARGET_DIR}/devbox.sh"
    echo ""
    echo "  For easier access, you can:"
    echo "  - Add to PATH: echo 'export PATH=\"\$PATH:${TARGET_DIR}\"' >> ~/.bashrc"
    echo "  - Create alias: echo 'alias devbox=\"${TARGET_DIR}/devbox.sh\"' >> ~/.bashrc"
fi

echo ""
echo "To update DevBox later:"
echo "  cd ${TARGET_DIR} && git pull && ./build.sh"
echo ""
echo "Options:"
echo "  --enable-sudo                   : Enable sudo in container"
echo "  --disable-firewall              : Disable firewall protection"
echo "  --dangerously-skip-permissions  : Skip Claude Code permission checks"
echo "  --no-claude                     : Start tmux without Claude Code"
echo "  --no-tmux                       : Run without tmux"
echo ""
echo "Example: devbox --enable-sudo"
echo ""
print_info "Happy coding with DevBox! 🚀"
