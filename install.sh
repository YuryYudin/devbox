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

# Get the script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Define target directory
TARGET_DIR="$HOME/.devbox"

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

# Check if required files exist in source
print_step "Verifying source files..."
REQUIRED_ITEMS=(
    "dockerfiles"
    "dockerfiles/Dockerfile"
    "dockerfiles/docker-entrypoint"
    "dockerfiles/init-firewall"
    "dockerfiles/allowlist"
    "build.sh"
    "devbox.sh"
)

for item in "${REQUIRED_ITEMS[@]}"; do
    if [ ! -e "${SCRIPT_DIR}/${item}" ]; then
        print_error "Required file/directory not found: ${item}"
        exit 1
    fi
done
print_info "All source files present ✓"

# Create target directory if it doesn't exist
print_step "Setting up DevBox directory..."
if [ -d "${TARGET_DIR}" ]; then
    print_warning "Directory ${TARGET_DIR} already exists."
    echo -n "Do you want to overwrite the existing installation? (y/N): "
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        print_info "Installation cancelled."
        exit 0
    fi
    print_info "Backing up existing installation..."
    BACKUP_DIR="${TARGET_DIR}.backup.$(date +%Y%m%d-%H%M%S)"
    mv "${TARGET_DIR}" "${BACKUP_DIR}"
    print_info "Existing installation backed up to: ${BACKUP_DIR}"
fi

mkdir -p "${TARGET_DIR}"
print_info "Created directory: ${TARGET_DIR}"

# Copy files to target directory
print_step "Copying files to ${TARGET_DIR}..."

# Copy dockerfiles directory
cp -r "${SCRIPT_DIR}/dockerfiles" "${TARGET_DIR}/"
print_info "Copied dockerfiles directory"

# Copy scripts
cp "${SCRIPT_DIR}/build.sh" "${TARGET_DIR}/"
cp "${SCRIPT_DIR}/devbox.sh" "${TARGET_DIR}/"
print_info "Copied build.sh and devbox.sh scripts"

# Make scripts executable
chmod +x "${TARGET_DIR}/build.sh"
chmod +x "${TARGET_DIR}/devbox.sh"
chmod +x "${TARGET_DIR}/dockerfiles/docker-entrypoint"
chmod +x "${TARGET_DIR}/dockerfiles/init-firewall"
print_info "Made scripts executable"

# Create a version file to track installation
echo "$(date +%Y-%m-%d_%H:%M:%S)" > "${TARGET_DIR}/.installed"

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

# Create convenience symlinks in /usr/local/bin if user has permissions
print_step "Setting up command-line access..."
SYMLINK_DIR="/usr/local/bin"
SYMLINK_CREATED=false

if [ -w "${SYMLINK_DIR}" ] || [ -w /usr/local ] && [ ! -d "${SYMLINK_DIR}" ]; then
    # Create /usr/local/bin if it doesn't exist and we can write to /usr/local
    if [ ! -d "${SYMLINK_DIR}" ]; then
        mkdir -p "${SYMLINK_DIR}"
    fi
    
    # Create symlink
    if ln -sf "${TARGET_DIR}/devbox.sh" "${SYMLINK_DIR}/devbox" 2>/dev/null; then
        print_info "Created symlink: ${SYMLINK_DIR}/devbox"
        SYMLINK_CREATED=true
    fi
else
    print_warning "Cannot create symlink in ${SYMLINK_DIR} (requires sudo privileges)"
fi

# Installation complete
echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}       Installation completed successfully!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo ""
echo "DevBox has been installed to: ${TARGET_DIR}"
echo ""
echo "To use DevBox:"

if [ "$SYMLINK_CREATED" = true ]; then
    echo "  1. From any directory, run: devbox"
    echo "  2. Or run directly: ${TARGET_DIR}/devbox.sh"
else
    echo "  1. Run directly: ${TARGET_DIR}/devbox.sh"
    echo ""
    echo "  For easier access, you can:"
    echo "  - Add to PATH: echo 'export PATH=\"\$PATH:${TARGET_DIR}\"' >> ~/.bashrc"
    echo "  - Create alias: echo 'alias devbox=\"${TARGET_DIR}/devbox.sh\"' >> ~/.bashrc"
    echo "  - Create symlink (with sudo): sudo ln -s ${TARGET_DIR}/devbox.sh /usr/local/bin/devbox"
fi

echo ""
echo "Options:"
echo "  --enable-sudo       : Enable sudo in container"
echo "  --disable-firewall  : Disable firewall protection"
echo "  --claude-flow       : Use Claude's workflow mode"
echo ""
echo "Example: devbox --enable-sudo"
echo ""
print_info "Happy coding with DevBox! 🚀"