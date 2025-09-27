#!/bin/bash
set -euo pipefail

# Check for help command first (before any other operations)
if [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]] || [[ "${1:-}" == "help" ]]; then
    # Colors for output
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    NC='\033[0m' # No Color
    
    # Function to display help information
    echo -e "${BLUE}"
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║                          DevBox Help                          ║"
    echo "║              Claude Code Docker Container                      ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    echo "DevBox provides a secure, isolated Docker environment for Claude Code CLI"
    echo "with built-in development tools and configurable security features."
    echo ""
    echo -e "${GREEN}USAGE:${NC}"
    echo "  devbox [COMMAND] [OPTIONS]"
    echo ""
    echo -e "${GREEN}COMMANDS:${NC}"
    echo "  update                    Update DevBox and rebuild container with latest packages"
    echo "  --list-containers         List all DevBox containers and their status"
    echo "  --clean-all               Remove all DevBox containers (with confirmation)"
    echo "  --rebuild-containers      Rebuild all containers (removes and recreates)"
    echo "  --help, -h               Show this help message"
    echo ""
    echo -e "${GREEN}OPTIONS:${NC}"
    echo "  --enable-sudo            Enable sudo access inside the container"
    echo "  --disable-firewall       Disable the built-in firewall protection"
    echo "  --dangerously-skip-permissions"
    echo "                           Skip Claude Code permission checks (use with caution)"
    echo "  --no-claude              Start tmux session without Claude Code (manual development)"
    echo "  --no-tmux                Run without tmux (direct shell or Claude)"
    echo "  --enable-docker          Enable Docker-in-Docker support (mount Docker socket)"
    echo "  --clean-on-shutdown      Remove container after use (default: preserve for reuse)"
    echo "  --preserve-homedir       Preserve home directory when rebuilding containers"
    echo "  --mount PATH             Mount additional path(s) at their original locations"
    echo "                           Can be specified multiple times for multiple mounts"
    echo ""
    echo -e "${GREEN}EXAMPLES:${NC}"
    echo "  devbox                              # Start Claude Code in tmux (default)"
    echo "  devbox --help                       # Show this help"
    echo "  devbox update                       # Update DevBox to latest version"
    echo "  devbox --list-containers            # List all containers"
    echo "  devbox --clean-all                  # Remove all containers"
    echo "  devbox --rebuild-containers         # Rebuild all containers"
    echo "  devbox --rebuild-containers --preserve-homedir  # Rebuild with data"
    echo "  devbox --enable-sudo                # Start with sudo access"
    echo "  devbox --no-claude                  # Start tmux without Claude (manual dev)"
    echo "  devbox --no-tmux                    # Run Claude directly (no tmux)"
    echo "  devbox --no-tmux --no-claude        # Plain bash shell"
    echo "  devbox --enable-docker              # Enable Docker commands"
    echo "  devbox --clean-on-shutdown          # Remove container after use"
    echo "  devbox --enable-sudo --enable-docker --disable-firewall"
    echo "                                      # Full development mode"
    echo "  devbox --mount /path/to/data        # Mount additional directory"
    echo "  devbox --mount /src --mount /config # Mount multiple directories"
    echo "  devbox npm install                  # Run specific command"
    echo "  devbox python script.py            # Execute script"
    echo ""
    echo -e "${GREEN}SECURITY MODES:${NC}"
    echo "  Default:     Firewall enabled, no sudo, no Docker access"
    echo "  Development: --enable-sudo --disable-firewall"
    echo "  Build Mode:  --enable-docker (for Docker-based builds)"
    echo "  Secure:      Default settings (recommended for untrusted code)"
    echo ""
    echo -e "${GREEN}CONFIGURATION:${NC}"
    echo "  Config Location:    ~/.devbox/"
    echo "  Authentication:     Automatically saved and restored"
    echo "  Project Settings:   Per-directory configuration slots"
    echo "  Updates:           Automatic checking with Git integration"
    echo ""
    echo -e "${GREEN}TMUX CONFIGURATION:${NC}"
    echo "  Prefix Key:         Ctrl+k (instead of default Ctrl+b)"
    echo "  Split Panes:        Ctrl+k | (vertical), Ctrl+k - (horizontal)"
    echo "  New Window:         Ctrl+k c"
    echo "  Next Window:        Ctrl+k n"
    echo "  Detach Session:     Ctrl+k d"
    echo "  Mouse Support:      Enabled (click to select, scroll history)"
    echo ""
    echo -e "${YELLOW}SECURITY WARNINGS:${NC}"
    echo "  --enable-sudo:      Grants full system access inside container"
    echo "  --disable-firewall: Removes network access restrictions" 
    echo "  --enable-docker:    Grants full access to host Docker daemon"
    echo "  --dangerously-skip-permissions: Bypasses Claude Code safety checks"
    echo ""
    echo -e "${GREEN}MORE INFO:${NC}"
    echo "  Documentation: https://github.com/YuryYudin/devbox"
    echo "  Issues:        https://github.com/YuryYudin/devbox/issues"
    echo "  Claude Code:   https://claude.ai/code"
    echo ""
    exit 0
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get current user information for container commands
USERNAME=$(whoami)

# Check for list-containers command
if [[ "${1:-}" == "--list-containers" ]]; then
    echo -e "${GREEN}[INFO]${NC} Listing all DevBox containers..."
    echo ""
    
    # Get all DevBox containers
    DEVBOX_CONTAINERS=$(docker ps -a --filter "name=devbox-${USERNAME}-" --format "table {{.Names}}\t{{.Status}}\t{{.Size}}\t{{.CreatedAt}}" 2>/dev/null)
    
    if [ -z "$DEVBOX_CONTAINERS" ] || [ "$DEVBOX_CONTAINERS" = "NAMES	STATUS	SIZE	CREATEDAT" ]; then
        echo -e "${GREEN}[INFO]${NC} No DevBox containers found."
        echo ""
        echo "Containers are automatically created when you run devbox in a directory."
        echo "Each directory gets its own dedicated container for isolation."
    else
        echo "$DEVBOX_CONTAINERS"
        echo ""
        
        # Count containers
        CONTAINER_COUNT=$(echo "$DEVBOX_CONTAINERS" | tail -n +2 | wc -l | tr -d ' ')
        echo -e "${GREEN}[INFO]${NC} Found $CONTAINER_COUNT DevBox container(s)"
        echo ""
        echo "To remove a specific container: docker rm <container-name>"
        echo "To remove all containers: devbox --clean-all"
        echo "To remove containers after use: devbox --clean-on-shutdown"
    fi
    
    exit 0
fi

# Check for clean-all command
if [[ "${1:-}" == "--clean-all" ]]; then
    echo -e "${GREEN}[INFO]${NC} DevBox Container Cleanup"
    echo ""
    
    # Get all DevBox containers
    DEVBOX_CONTAINERS=$(docker ps -a --filter "name=devbox-${USERNAME}-" --format "{{.Names}}" 2>/dev/null)
    
    if [ -z "$DEVBOX_CONTAINERS" ]; then
        echo -e "${GREEN}[INFO]${NC} No DevBox containers found to clean up."
        exit 0
    fi
    
    # Count containers
    CONTAINER_COUNT=$(echo "$DEVBOX_CONTAINERS" | wc -l | tr -d ' ')
    
    echo -e "${YELLOW}[WARNING]${NC} Found $CONTAINER_COUNT DevBox container(s) to remove:"
    echo ""
    
    # Show detailed container info
    docker ps -a --filter "name=devbox-${USERNAME}-" --format "table {{.Names}}\t{{.Status}}\t{{.Size}}"
    echo ""
    
    echo -e "${YELLOW}[WARNING]${NC} This will permanently delete all your DevBox containers and their data."
    echo -e "${YELLOW}[WARNING]${NC} Your source code and Claude authentication will NOT be affected."
    echo ""
    echo -n "Are you sure you want to remove ALL DevBox containers? (y/N): "
    
    # Handle input for both interactive and non-interactive environments
    if [ -t 0 ]; then
        # Interactive mode - read from stdin
        read -r response
    else
        # Non-interactive mode - try to read from stdin
        read -r response
    fi
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        echo -e "${GREEN}[INFO]${NC} Removing all DevBox containers..."
        
        # Remove containers one by one for better error handling
        echo "$DEVBOX_CONTAINERS" | while IFS= read -r container; do
            if [ -n "$container" ]; then
                echo "  Removing: $container"
                docker rm -f "$container" >/dev/null 2>&1 || echo -e "${YELLOW}[WARNING]${NC} Failed to remove: $container"
            fi
        done
        
        echo ""
        echo -e "${GREEN}[INFO]${NC} ✅ Container cleanup completed!"
        echo ""
        echo "Next time you run devbox, new containers will be created automatically."
    else
        echo -e "${GREEN}[INFO]${NC} Container cleanup cancelled."
    fi
    
    exit 0
fi

# Check for rebuild-containers command
if [[ "${1:-}" == "--rebuild-containers" ]]; then
    echo -e "${GREEN}[INFO]${NC} DevBox Container Rebuild"
    echo ""
    
    # Check if --preserve-homedir flag is present
    PRESERVE_HOMEDIR=false
    for arg in "$@"; do
        if [[ "$arg" == "--preserve-homedir" ]]; then
            PRESERVE_HOMEDIR=true
            break
        fi
    done
    
    # Get all DevBox containers
    DEVBOX_CONTAINERS=$(docker ps -a --filter "name=devbox-${USERNAME}-" --format "{{.Names}}" 2>/dev/null)
    
    if [ -z "$DEVBOX_CONTAINERS" ]; then
        echo -e "${GREEN}[INFO]${NC} No DevBox containers found to rebuild."
        echo ""
        echo "Containers will be created fresh when you run devbox in each directory."
        exit 0
    fi
    
    # Count containers
    CONTAINER_COUNT=$(echo "$DEVBOX_CONTAINERS" | wc -l | tr -d ' ')
    
    echo -e "${YELLOW}[WARNING]${NC} Found $CONTAINER_COUNT DevBox container(s) to rebuild:"
    echo ""
    
    # Show detailed container info
    docker ps -a --filter "name=devbox-${USERNAME}-" --format "table {{.Names}}\t{{.Status}}\t{{.CreatedAt}}"
    echo ""
    
    if [ "$PRESERVE_HOMEDIR" = true ]; then
        echo -e "${GREEN}[INFO]${NC} Home directory preservation: ENABLED"
        echo "Contents of /home/${USERNAME} will be backed up and restored"
    else
        echo -e "${YELLOW}[WARNING]${NC} Home directory preservation: DISABLED"
        echo "All installed packages and configuration in containers will be lost!"
        echo "Use --preserve-homedir to keep your development environment"
    fi
    echo ""
    
    echo -n "Are you sure you want to rebuild ALL DevBox containers? (y/N): "
    
    # Handle input for both interactive and non-interactive environments
    if [ -t 0 ]; then
        read -r response
    else
        read -r response
    fi
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        echo -e "${GREEN}[INFO]${NC} Rebuilding all DevBox containers..."
        echo ""
        
        # Create temporary backup directory if preserving
        if [ "$PRESERVE_HOMEDIR" = true ]; then
            BACKUP_BASE_DIR="/tmp/devbox-backups-$(date +%Y%m%d-%H%M%S)"
            mkdir -p "$BACKUP_BASE_DIR"
            echo -e "${GREEN}[INFO]${NC} Backup directory: $BACKUP_BASE_DIR"
            echo ""
        fi
        
        # Process containers one by one
        echo "$DEVBOX_CONTAINERS" | while IFS= read -r container; do
            if [ -n "$container" ]; then
                echo -e "${BLUE}Processing:${NC} $container"
                
                # Extract project name from container name (remove devbox-username- prefix)
                PROJECT_NAME="${container#devbox-${USERNAME}-}"
                
                # Check if container is running
                CONTAINER_STATUS=$(docker container inspect --format='{{.State.Status}}' "$container" 2>/dev/null || echo "unknown")
                
                # Backup home directory if requested and container exists
                if [ "$PRESERVE_HOMEDIR" = true ] && [ "$CONTAINER_STATUS" != "unknown" ]; then
                    BACKUP_DIR="${BACKUP_BASE_DIR}/${PROJECT_NAME}"
                    mkdir -p "$BACKUP_DIR"
                    
                    echo "  → Backing up home directory..."
                    
                    # Start container if it's not running
                    if [ "$CONTAINER_STATUS" != "running" ]; then
                        docker start "$container" >/dev/null 2>&1
                        sleep 1  # Give container time to start
                    fi
                    
                    # Create tar archive of home directory
                    if docker exec "$container" tar czf - -C /home "${USERNAME}" 2>/dev/null > "${BACKUP_DIR}/home.tar.gz"; then
                        echo "  ✓ Backed up to ${BACKUP_DIR}/home.tar.gz"
                        echo "$container" > "${BACKUP_DIR}/container_name.txt"
                    else
                        echo -e "  ${YELLOW}✗ Failed to backup (container may be corrupted)${NC}"
                    fi
                    
                    # Stop container if we started it
                    if [ "$CONTAINER_STATUS" != "running" ]; then
                        docker stop "$container" >/dev/null 2>&1
                    fi
                fi
                
                # Remove old container
                echo "  → Removing old container..."
                if docker rm -f "$container" >/dev/null 2>&1; then
                    echo "  ✓ Container removed"
                else
                    echo -e "  ${YELLOW}✗ Failed to remove container${NC}"
                fi
                
                echo ""
            fi
        done
        
        # Get the latest image ID for restoration tracking
        LATEST_IMAGE_ID=$(docker image inspect --format='{{.Id}}' "devbox:latest" 2>/dev/null || echo "")
        
        if [ "$PRESERVE_HOMEDIR" = true ] && [ -d "$BACKUP_BASE_DIR" ]; then
            echo -e "${GREEN}[INFO]${NC} ✅ Container rebuild completed!"
            echo ""
            echo -e "${GREEN}[INFO]${NC} Home directory backups saved to: $BACKUP_BASE_DIR"
            echo ""
            echo "To restore home directories after containers are recreated:"
            echo "  1. Run devbox in each project directory to create new containers"
            echo "  2. The home directories will be automatically restored on first run"
            echo ""
            
            # Save backup info for automatic restoration
            echo "$BACKUP_BASE_DIR" > "$HOME/.devbox/last_backup_dir"
            echo "$LATEST_IMAGE_ID" > "$HOME/.devbox/last_rebuild_image"
        else
            echo -e "${GREEN}[INFO]${NC} ✅ Container rebuild completed!"
            echo ""
            echo "Next time you run devbox in each directory, new containers will be created."
            echo "Note: You will need to reinstall any packages (npm install, pip install, etc.)"
        fi
    else
        echo -e "${GREEN}[INFO]${NC} Container rebuild cancelled."
    fi
    
    exit 0
fi

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

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed."
    echo "Please install Docker from https://docs.docker.com/get-docker/"
    exit 1
fi

# Check if Docker daemon is running
if ! docker info &> /dev/null; then
    print_error "Docker daemon is not running."
    echo "Please start Docker:"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "  - Open Docker Desktop application"
    else
        echo "  - Run: sudo systemctl start docker"
    fi
    exit 1
fi

# Default image name
IMAGE_NAME="devbox:latest"

# Function to check for updates from GitHub
check_for_updates() {
    local DEVBOX_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    
    # Only check for updates if we're in a git repository
    if [ -d "${DEVBOX_DIR}/.git" ]; then
        # Fetch latest changes without merging
        git -C "${DEVBOX_DIR}" fetch origin main &>/dev/null || return 1
        
        # Check if we're behind
        LOCAL=$(git -C "${DEVBOX_DIR}" rev-parse HEAD 2>/dev/null)
        REMOTE=$(git -C "${DEVBOX_DIR}" rev-parse origin/main 2>/dev/null)
        
        if [ "$LOCAL" != "$REMOTE" ]; then
            return 0  # Updates available
        fi
    fi
    return 1  # No updates or not a git repo
}

# Function to check if container needs rebuild
check_container_version() {
    local needs_rebuild=false
    
    # Check if image exists
    if ! docker image inspect "$IMAGE_NAME" &> /dev/null; then
        return 1
    fi
    
    # Get the directory where devbox.sh is located
    DEVBOX_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    
    # Check if we're in the installed location
    if [[ "$DEVBOX_DIR" == "$HOME/.devbox" ]]; then
        # Check if Dockerfile has been modified since image was built
        if [ -f "${DEVBOX_DIR}/dockerfiles/Dockerfile" ]; then
            # Get image creation time
            IMAGE_CREATED=$(docker inspect -f '{{.Created}}' "$IMAGE_NAME" 2>/dev/null | cut -d'T' -f1-2 | tr -d 'T:-')
            
            # Get Dockerfile modification time
            if [[ "$OSTYPE" == "darwin"* ]]; then
                DOCKERFILE_MODIFIED=$(stat -f "%Sm" -t "%Y%m%d%H%M%S" "${DEVBOX_DIR}/dockerfiles/Dockerfile")
            else
                DOCKERFILE_MODIFIED=$(stat -c "%Y" "${DEVBOX_DIR}/dockerfiles/Dockerfile")
                DOCKERFILE_MODIFIED=$(date -d "@${DOCKERFILE_MODIFIED}" "+%Y%m%d%H%M%S")
            fi
            
            # Compare timestamps (simplified comparison)
            if [ -n "$IMAGE_CREATED" ] && [ -n "$DOCKERFILE_MODIFIED" ]; then
                IMAGE_TIMESTAMP="${IMAGE_CREATED:0:14}"
                if [[ "$DOCKERFILE_MODIFIED" > "$IMAGE_TIMESTAMP" ]]; then
                    needs_rebuild=true
                fi
            fi
        fi
    fi
    
    if [ "$needs_rebuild" = true ]; then
        return 2  # Needs rebuild
    fi
    
    return 0  # Image exists and is up to date
}

# Function to generate slot name from current directory
generate_slot_name() {
    local current_dir=$(pwd)
    # Replace special characters with underscores
    echo "${current_dir}" | sed 's/[^a-zA-Z0-9]/_/g' | sed 's/__*/_/g' | sed 's/^_//;s/_$//'
}

# Function to setup Claude configuration
setup_claude_config() {
    local DEVBOX_DIR="$(get_devbox_dir)"
    local SLOT_NAME=$(generate_slot_name)
    local SLOTS_DIR="${DEVBOX_DIR}/slots"
    local SLOT_DIR="${SLOTS_DIR}/${SLOT_NAME}"
    local CLAUDE_CONFIGS_DIR="${DEVBOX_DIR}/claude-configs"
    local TEMP_CONFIG_DIR="/tmp/devbox-claude-${CONTAINER_NAME}"
    
    # Create directories if they don't exist
    mkdir -p "${SLOTS_DIR}"
    mkdir -p "${CLAUDE_CONFIGS_DIR}"
    mkdir -p "${TEMP_CONFIG_DIR}"
    
    # Prepare configuration to copy into container
    local CONFIG_RESTORED=false
    
    # Check if we have a saved .claude folder
    if [ -d "${CLAUDE_CONFIGS_DIR}/.claude" ]; then
        cp -r "${CLAUDE_CONFIGS_DIR}/.claude" "${TEMP_CONFIG_DIR}/"
        CONFIG_RESTORED=true
        print_info "Restored Claude authentication from previous session"
    fi
    
    # Check if we have a slot-specific .claude.json
    if [ -f "${SLOT_DIR}/.claude.json" ]; then
        cp "${SLOT_DIR}/.claude.json" "${TEMP_CONFIG_DIR}/"
        CONFIG_RESTORED=true
        print_info "Restored project-specific Claude configuration for: $(pwd)"
    else
        # Try to find the most recent .claude.json from other slots
        if [ -d "${SLOTS_DIR}" ]; then
            # Find the most recently modified .claude.json file in any slot
            RECENT_CONFIG=$(find "${SLOTS_DIR}" -name ".claude.json" -type f 2>/dev/null | xargs ls -t 2>/dev/null | head -1)
            
            if [ -n "$RECENT_CONFIG" ] && [ -f "$RECENT_CONFIG" ]; then
                # Extract the slot name from the path for informational purposes
                RECENT_SLOT=$(basename "$(dirname "$RECENT_CONFIG")")
                
                cp "$RECENT_CONFIG" "${TEMP_CONFIG_DIR}/.claude.json"
                CONFIG_RESTORED=true
                print_info "No project configuration found for: $(pwd)"
                print_info "Using configuration from most recent project: ${RECENT_SLOT}"
            fi
        fi
    fi
    
    if [ "$CONFIG_RESTORED" = false ]; then
        print_info "First time using DevBox in this directory: $(pwd)"
        print_info "You may need to authenticate with Claude Code using /login"
    fi
    
    echo "${SLOT_NAME}" > "${TEMP_CONFIG_DIR}/.slot_name"
    echo "${SLOT_DIR}" > "${TEMP_CONFIG_DIR}/.slot_dir"
    echo "${CLAUDE_CONFIGS_DIR}" > "${TEMP_CONFIG_DIR}/.claude_configs_dir"
}

# Function to save Claude configuration after container exits
save_claude_config() {
    local CONTAINER_NAME="$1"
    local TEMP_CONFIG_DIR="/tmp/devbox-claude-${CONTAINER_NAME}"
    
    print_info "Saving Claude configuration..."
    
    # Check if temp config directory exists
    if [ ! -f "${TEMP_CONFIG_DIR}/.slot_name" ]; then
        print_warning "No configuration metadata found. Skipping save."
        return
    fi
    
    # Read configuration paths
    local SLOT_NAME=$(cat "${TEMP_CONFIG_DIR}/.slot_name" 2>/dev/null)
    local SLOT_DIR=$(cat "${TEMP_CONFIG_DIR}/.slot_dir" 2>/dev/null)
    local CLAUDE_CONFIGS_DIR=$(cat "${TEMP_CONFIG_DIR}/.claude_configs_dir" 2>/dev/null)
    
    if [ -z "$SLOT_NAME" ] || [ -z "$SLOT_DIR" ] || [ -z "$CLAUDE_CONFIGS_DIR" ]; then
        print_error "Invalid configuration metadata. Cannot save."
        rm -rf "${TEMP_CONFIG_DIR}" 2>/dev/null
        return
    fi
    
    # Create directories if needed
    mkdir -p "${SLOT_DIR}" 2>/dev/null
    mkdir -p "${CLAUDE_CONFIGS_DIR}" 2>/dev/null
    
    # Check if container still exists (it should be stopped but not removed yet)
    if ! docker container inspect "${CONTAINER_NAME}" &>/dev/null; then
        print_warning "Container ${CONTAINER_NAME} not found. Cannot save configuration."
        rm -rf "${TEMP_CONFIG_DIR}" 2>/dev/null
        return
    fi
    
    local CONFIG_SAVED=false
    local CLAUDE_SAVED=false
    local JSON_SAVED=false
    
    # Save .claude folder (authentication tokens)
    print_info "  → Checking for authentication data..."
    if docker cp "${CONTAINER_NAME}:/home/${USERNAME}/.claude" "${TEMP_CONFIG_DIR}/.claude-new" 2>/dev/null; then
        if [ -d "${TEMP_CONFIG_DIR}/.claude-new" ]; then
            rm -rf "${CLAUDE_CONFIGS_DIR}/.claude" 2>/dev/null
            if mv "${TEMP_CONFIG_DIR}/.claude-new" "${CLAUDE_CONFIGS_DIR}/.claude" 2>/dev/null; then
                print_info "  ✓ Authentication data saved"
                CONFIG_SAVED=true
                CLAUDE_SAVED=true
            else
                print_warning "  ✗ Failed to move authentication data"
            fi
        fi
    else
        print_info "  - No authentication data found (normal for first run)"
    fi
    
    # Save .claude.json (project configuration)
    print_info "  → Checking for project configuration..."
    if docker cp "${CONTAINER_NAME}:/home/${USERNAME}/.claude.json" "${TEMP_CONFIG_DIR}/.claude.json-new" 2>/dev/null; then
        if [ -f "${TEMP_CONFIG_DIR}/.claude.json-new" ]; then
            if mv "${TEMP_CONFIG_DIR}/.claude.json-new" "${SLOT_DIR}/.claude.json" 2>/dev/null; then
                print_info "  ✓ Project configuration saved for slot: ${SLOT_NAME}"
                CONFIG_SAVED=true
                JSON_SAVED=true
            else
                print_warning "  ✗ Failed to move project configuration"
            fi
        fi
    else
        print_info "  - No project configuration found (normal for first run)"
    fi
    
    # Clean up temp directory
    rm -rf "${TEMP_CONFIG_DIR}" 2>/dev/null
    
    # Summary message
    if [ "$CONFIG_SAVED" = true ]; then
        echo ""
        print_info "Configuration persistence summary:"
        if [ "$CLAUDE_SAVED" = true ]; then
            print_info "  • Authentication: Saved to shared storage"
        fi
        if [ "$JSON_SAVED" = true ]; then
            print_info "  • Project settings: Saved for directory $(pwd)"
        fi
        print_info "  • Next run will restore your Claude configuration automatically"
    else
        print_info "No Claude configuration changes to save"
    fi
}

# Function to get the actual DevBox directory (resolving symlinks)
get_devbox_dir() {
    local script_path="${BASH_SOURCE[0]}"
    
    # Resolve symlink if present
    if [ -L "$script_path" ]; then
        script_path="$(readlink "$script_path")"
        # Handle relative symlinks
        if [[ "$script_path" != /* ]]; then
            script_path="$(dirname "${BASH_SOURCE[0]}")/$script_path"
        fi
    fi
    
    # Get the directory containing the resolved script
    cd "$( dirname "$script_path" )" && pwd
}

# Get the actual DevBox directory
DEVBOX_DIR="$(get_devbox_dir)"

# Check for updates from GitHub (only if in git repo)
if [ -d "${DEVBOX_DIR}/.git" ]; then
    # Temporarily disable exit on error for update check
    set +e
    check_for_updates
    UPDATE_AVAILABLE=$?
    set -e
    
    if [ $UPDATE_AVAILABLE -eq 0 ]; then
        print_warning "New version of DevBox is available!"
        echo "To update, run: cd ${DEVBOX_DIR} && git pull && ./build.sh"
        echo ""
        echo -n "Do you want to update now? (y/N): "
        read -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            print_info "Updating DevBox..."
            
            # Stash any local changes
            if ! git -C "${DEVBOX_DIR}" diff --quiet || ! git -C "${DEVBOX_DIR}" diff --cached --quiet; then
                print_info "Stashing local changes..."
                git -C "${DEVBOX_DIR}" stash push -m "Auto-stash before update $(date +%Y-%m-%d_%H:%M:%S)"
            fi
            
            # Pull latest changes
            if git -C "${DEVBOX_DIR}" pull origin main; then
                print_info "DevBox updated successfully!"
                
                # Rebuild container
                print_info "Rebuilding container with new version..."
                if "${DEVBOX_DIR}/build.sh"; then
                    print_info "Container rebuilt successfully!"
                    echo ""
                    echo "Please restart devbox to use the new version."
                    exit 0
                else
                    print_error "Failed to rebuild container after update."
                    exit 1
                fi
            else
                print_error "Failed to update DevBox."
            fi
        else
            print_info "Continuing with current version."
            echo ""
        fi
    fi
fi

# Check container status
set +e
check_container_version
CHECK_RESULT=$?
set -e

if [ $CHECK_RESULT -eq 1 ]; then
    # Image doesn't exist
    print_warning "Docker image '${IMAGE_NAME}' not found."
    
    # Check if we can auto-build (build.sh exists in current devbox directory)
    AUTO_BUILD_DEVBOX_DIR="$(get_devbox_dir)"
    
    if [ -f "${AUTO_BUILD_DEVBOX_DIR}/build.sh" ]; then
        echo ""
        print_info "Auto-building container for first use..."
        echo ""
        if "${AUTO_BUILD_DEVBOX_DIR}/build.sh"; then
            print_info "Container built successfully!"
            echo ""
        else
            print_error "Failed to build container."
            exit 1
        fi
    else
        print_error "Please run ./build.sh first to build the image."
        print_info "Or install DevBox properly using: curl -fsSL https://raw.githubusercontent.com/YuryYudin/devbox/main/install.sh | bash"
        exit 1
    fi
elif [ $CHECK_RESULT -eq 2 ]; then
    # Image exists but needs rebuild
    print_warning "Container image may be out of date."
    echo "Dockerfile has been modified since the image was built."
    echo ""
    echo -n "Do you want to rebuild the container now? (y/N): "
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        REBUILD_DEVBOX_DIR="$(get_devbox_dir)"
        print_info "Rebuilding container..."
        echo ""
        if "${REBUILD_DEVBOX_DIR}/build.sh"; then
            print_info "Container rebuilt successfully!"
            echo ""
        else
            print_error "Failed to rebuild container."
            exit 1
        fi
    else
        print_info "Using existing container image (may be outdated)."
    fi
fi

# Get current user information
USER_ID=$(id -u)
GROUP_ID=$(id -g)
USERNAME=$(whoami)

# Generate deterministic container name based on project directory
SLOT_NAME=$(generate_slot_name)
CONTAINER_NAME="devbox-${USERNAME}-${SLOT_NAME}"

# Function to check if existing container needs rebuild
needs_container_rebuild() {
    local container_name="$1"
    
    # If container doesn't exist, no rebuild needed (will be created fresh)
    if ! docker container inspect "${container_name}" &>/dev/null; then
        return 1  # false - no rebuild needed, container doesn't exist
    fi
    
    # Get container image ID
    local container_image_id=$(docker container inspect --format='{{.Image}}' "${container_name}" 2>/dev/null)
    # Get current image ID
    local current_image_id=$(docker image inspect --format='{{.Id}}' "${IMAGE_NAME}" 2>/dev/null)
    
    # If image IDs don't match, container uses old image
    if [ "$container_image_id" != "$current_image_id" ]; then
        return 0  # true - rebuild needed
    fi
    
    return 1  # false - no rebuild needed
}

# Setup Claude configuration before starting container
setup_claude_config


# Check for update command first
if [[ "${1:-}" == "update" ]]; then
    print_info "Starting DevBox update process..."
    echo ""
    
    # Update from git if in git repo
    DEVBOX_DIR="$(get_devbox_dir)"
    
    if [ -d "${DEVBOX_DIR}/.git" ]; then
        print_step "Checking for DevBox updates from GitHub..."
        
        # Fetch latest changes
        if git -C "${DEVBOX_DIR}" fetch origin main &>/dev/null; then
            LOCAL=$(git -C "${DEVBOX_DIR}" rev-parse HEAD 2>/dev/null)
            REMOTE=$(git -C "${DEVBOX_DIR}" rev-parse origin/main 2>/dev/null)
            
            if [ "$LOCAL" != "$REMOTE" ]; then
                print_info "New DevBox version available. Updating..."
                
                # Stash any local changes
                if ! git -C "${DEVBOX_DIR}" diff --quiet || ! git -C "${DEVBOX_DIR}" diff --cached --quiet; then
                    print_info "Stashing local changes..."
                    git -C "${DEVBOX_DIR}" stash push -m "Auto-stash before update $(date +%Y-%m-%d_%H:%M:%S)"
                fi
                
                # Pull latest changes
                if git -C "${DEVBOX_DIR}" pull origin main; then
                    print_info "DevBox code updated successfully!"
                else
                    print_error "Failed to update DevBox code."
                    exit 1
                fi
            else
                print_info "DevBox is already up to date."
            fi
        else
            print_warning "Could not check for updates (network issue?)."
        fi
    else
        print_info "DevBox is not a git repository. Skipping code update."
    fi
    
    # Always rebuild container to get latest packages
    echo ""
    print_step "Rebuilding container with latest packages..."
    print_info "This will update Claude Code, claude-flow, and all other packages to their latest versions."
    echo ""
    
    if "${DEVBOX_DIR}/build.sh"; then
        echo ""
        print_info "✅ DevBox update completed successfully!"
        print_info "Container has been rebuilt with the latest versions of all packages."
        echo ""
        echo "You can now use DevBox with the latest updates."
    else
        print_error "Failed to rebuild container."
        exit 1
    fi
    
    exit 0
fi


# Parse command line arguments
DOCKER_ARGS=""
ENTRYPOINT_ARGS=""
INTERACTIVE=true
ENABLE_DOCKER=false
CLEAN_ON_SHUTDOWN=false
ADDITIONAL_MOUNTS=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --enable-sudo|--disable-firewall|--dangerously-skip-permissions|--no-claude|--no-tmux)
            ENTRYPOINT_ARGS="${ENTRYPOINT_ARGS} $1"
            shift
            ;;
        --enable-docker)
            ENABLE_DOCKER=true
            ENTRYPOINT_ARGS="${ENTRYPOINT_ARGS} $1"
            shift
            ;;
        --clean-on-shutdown)
            CLEAN_ON_SHUTDOWN=true
            shift
            ;;
        --mount)
            if [[ -z "${2:-}" ]]; then
                print_error "Error: --mount requires a path argument"
                exit 1
            fi
            # Resolve the path to absolute path
            MOUNT_PATH=$(realpath "$2" 2>/dev/null || echo "$2")
            if [[ ! -e "$MOUNT_PATH" ]]; then
                print_warning "Warning: Mount path does not exist: $2"
                echo "         Container will start but path may not be accessible"
            fi
            ADDITIONAL_MOUNTS+=("$MOUNT_PATH")
            shift 2
            ;;
        *)
            ENTRYPOINT_ARGS="${ENTRYPOINT_ARGS} $1"
            shift
            ;;
    esac
done

# Get current directory for mounting
CURRENT_DIR=$(pwd)
# Resolve any symlinks to get the real path
REAL_CURRENT_DIR=$(realpath "${CURRENT_DIR}")

print_info "Starting container: ${CONTAINER_NAME}"
echo "  - Image: ${IMAGE_NAME}"
echo "  - Workspace: ${REAL_CURRENT_DIR}"
echo "  - User: ${USERNAME} (${USER_ID}:${GROUP_ID})"
echo "  - Slot: $(generate_slot_name)"
if [[ ${#ADDITIONAL_MOUNTS[@]} -gt 0 ]]; then
    echo "  - Additional mounts:"
    for mount in "${ADDITIONAL_MOUNTS[@]}"; do
        echo "    • ${mount}"
    done
fi

# Determine if we should run interactively
if [ -t 0 ] && [ -t 1 ]; then
    DOCKER_TTY_FLAGS="-it"
else
    DOCKER_TTY_FLAGS=""
fi

# Build the Docker run command
DOCKER_CMD="docker run"
DOCKER_CMD="${DOCKER_CMD} ${DOCKER_TTY_FLAGS}"
DOCKER_CMD="${DOCKER_CMD} --name ${CONTAINER_NAME}"
#DOCKER_CMD="${DOCKER_CMD} --user ${USER_ID}:${GROUP_ID}"
DOCKER_CMD="${DOCKER_CMD} -v \"${REAL_CURRENT_DIR}:${REAL_CURRENT_DIR}\""
# Mount additional paths if specified
for mount_path in "${ADDITIONAL_MOUNTS[@]}"; do
    DOCKER_CMD="${DOCKER_CMD} -v \"${mount_path}:${mount_path}\""
done
DOCKER_CMD="${DOCKER_CMD} -e USER=${USERNAME}"
DOCKER_CMD="${DOCKER_CMD} -e USER_ID=${USER_ID}"
DOCKER_CMD="${DOCKER_CMD} -e GROUP_ID=${GROUP_ID}"
DOCKER_CMD="${DOCKER_CMD} -e HOME=/home/${USERNAME}"
DOCKER_CMD="${DOCKER_CMD} -e WORKSPACE_PATH=${REAL_CURRENT_DIR}"
DOCKER_CMD="${DOCKER_CMD} --cap-add SYS_ADMIN"
DOCKER_CMD="${DOCKER_CMD} --cap-add NET_ADMIN"
DOCKER_CMD="${DOCKER_CMD} --security-opt apparmor=unconfined"

# Mount the temp config directory
TEMP_CONFIG_DIR="/tmp/devbox-claude-${CONTAINER_NAME}"
DOCKER_CMD="${DOCKER_CMD} -v \"${TEMP_CONFIG_DIR}:/tmp/claude-config\""

# Mount Docker socket if Docker is enabled
if [ "$ENABLE_DOCKER" = true ]; then
    if [ -S "/var/run/docker.sock" ]; then
        DOCKER_CMD="${DOCKER_CMD} -v /var/run/docker.sock:/var/run/docker.sock"
        print_info "Docker-in-Docker enabled (mounting Docker socket)"
    else
        print_warning "Docker socket not found at /var/run/docker.sock - Docker commands may not work"
    fi
fi

# Add environment variables for terminal
if [ -n "${TERM:-}" ]; then
    DOCKER_CMD="${DOCKER_CMD} -e TERM=${TERM}"
fi

# Add the image and entrypoint arguments
DOCKER_CMD="${DOCKER_CMD} ${IMAGE_NAME}${ENTRYPOINT_ARGS}"

# Check if container already exists and can be reused
EXISTING_CONTAINER=""
CONTAINER_EXISTS=false

if docker container inspect "${CONTAINER_NAME}" &>/dev/null; then
    # Check if container needs rebuild due to image changes
    if needs_container_rebuild "${CONTAINER_NAME}"; then
        print_info "Container ${CONTAINER_NAME} uses outdated image"
        print_info "Removing and recreating container with latest image..."
        docker rm -f "${CONTAINER_NAME}" >/dev/null 2>&1 || true
        CONTAINER_EXISTS=false
    else
        CONTAINER_EXISTS=true
        EXISTING_CONTAINER="${CONTAINER_NAME}"
        
        # Check if container is running
        CONTAINER_STATUS=$(docker container inspect --format='{{.State.Status}}' "${CONTAINER_NAME}" 2>/dev/null)
        
        if [ "$CONTAINER_STATUS" = "running" ]; then
            print_info "Container ${CONTAINER_NAME} is already running"
            print_info "Attaching to existing container..."
            
            # Attach to running container
            docker exec -it "${CONTAINER_NAME}" /usr/local/bin/docker-entrypoint${ENTRYPOINT_ARGS}
            EXIT_CODE=$?
        elif [ "$CONTAINER_STATUS" = "exited" ]; then
            print_info "Reusing existing container: ${CONTAINER_NAME}"
            print_info "Starting container..."
            
            # Start existing stopped container
            docker start "${CONTAINER_NAME}" >/dev/null
            docker exec -it "${CONTAINER_NAME}" /usr/local/bin/docker-entrypoint${ENTRYPOINT_ARGS}
            EXIT_CODE=$?
            
            # Stop container after use (don't remove)
            docker stop "${CONTAINER_NAME}" >/dev/null 2>&1 || true
        else
            print_warning "Container ${CONTAINER_NAME} exists but in unexpected state: ${CONTAINER_STATUS}"
            print_info "Removing and recreating container..."
            docker rm -f "${CONTAINER_NAME}" >/dev/null 2>&1 || true
            CONTAINER_EXISTS=false
        fi
    fi
fi

# Create new container if none exists or if we removed the old one
if [ "$CONTAINER_EXISTS" = false ]; then
    print_info "Creating new container: ${CONTAINER_NAME}"
    print_info "Launching DevBox environment..."
    echo ""
    
    # Execute the Docker command
    eval ${DOCKER_CMD}
    EXIT_CODE=$?
    
    # Check if we should restore a backup for this container
    PROJECT_NAME="${CONTAINER_NAME#devbox-${USERNAME}-}"
    if [ -f "$HOME/.devbox/last_backup_dir" ]; then
        LAST_BACKUP_DIR=$(cat "$HOME/.devbox/last_backup_dir" 2>/dev/null)
        BACKUP_FILE="${LAST_BACKUP_DIR}/${PROJECT_NAME}/home.tar.gz"
        
        if [ -f "$BACKUP_FILE" ]; then
            print_info "Found home directory backup for this project"
            print_info "Restoring development environment..."
            
            # Start container if not running
            docker start "${CONTAINER_NAME}" >/dev/null 2>&1
            sleep 1
            
            # Restore the home directory
            if docker exec "${CONTAINER_NAME}" tar xzf - -C /home < "$BACKUP_FILE" 2>/dev/null; then
                print_info "✓ Home directory restored successfully"
                
                # Remove the backup file after successful restoration
                rm -f "$BACKUP_FILE"
                rm -f "${LAST_BACKUP_DIR}/${PROJECT_NAME}/container_name.txt"
                rmdir "${LAST_BACKUP_DIR}/${PROJECT_NAME}" 2>/dev/null || true
                
                # Clean up backup dir if empty
                rmdir "$LAST_BACKUP_DIR" 2>/dev/null || true
                if [ ! -d "$LAST_BACKUP_DIR" ]; then
                    rm -f "$HOME/.devbox/last_backup_dir"
                    rm -f "$HOME/.devbox/last_rebuild_image"
                fi
            else
                print_warning "Failed to restore home directory backup"
            fi
        fi
    fi
    
    # Stop container after use (don't remove unless --clean-on-shutdown)
    docker stop "${CONTAINER_NAME}" >/dev/null 2>&1 || true
fi

# Save Claude configuration after container exits
save_claude_config "${CONTAINER_NAME}"

# Clean up container after saving config (only if requested)
if [ "$CLEAN_ON_SHUTDOWN" = true ]; then
    print_info "Cleaning up container (--clean-on-shutdown specified)..."
    docker rm -f "${CONTAINER_NAME}" &>/dev/null || true
else
    print_info "Container ${CONTAINER_NAME} preserved for reuse"
    print_info "Use --clean-on-shutdown to remove containers after use"
fi

# Container has exited
if [ $EXIT_CODE -eq 0 ]; then
    print_info "Container exited successfully."
else
    print_warning "Container exited with code: ${EXIT_CODE}"
fi

exit $EXIT_CODE
