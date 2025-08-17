#!/bin/bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# Check if image exists
if ! docker image inspect "$IMAGE_NAME" &> /dev/null; then
    print_error "Docker image '${IMAGE_NAME}' not found."
    echo "Please run ./build.sh first to build the image."
    exit 1
fi

# Get current user information
USER_ID=$(id -u)
GROUP_ID=$(id -g)
USERNAME=$(whoami)

# Generate unique container name with timestamp
CONTAINER_NAME="devbox-${USERNAME}-$(date +%Y%m%d-%H%M%S)"

# Parse command line arguments
DOCKER_ARGS=""
ENTRYPOINT_ARGS=""
INTERACTIVE=true

while [[ $# -gt 0 ]]; do
    case "$1" in
        --enable-sudo|--disable-firewall|--claude-flow)
            ENTRYPOINT_ARGS="${ENTRYPOINT_ARGS} $1"
            shift
            ;;
        *)
            ENTRYPOINT_ARGS="${ENTRYPOINT_ARGS} $1"
            shift
            ;;
    esac
done

# Get current directory for mounting
CURRENT_DIR=$(pwd)

print_info "Starting container: ${CONTAINER_NAME}"
echo "  - Image: ${IMAGE_NAME}"
echo "  - Workspace: ${CURRENT_DIR}"
echo "  - User: ${USERNAME} (${USER_ID}:${GROUP_ID})"

# Determine if we should run interactively
if [ -t 0 ] && [ -t 1 ]; then
    DOCKER_TTY_FLAGS="-it"
else
    DOCKER_TTY_FLAGS=""
fi

# Build the Docker run command
DOCKER_CMD="docker run"
DOCKER_CMD="${DOCKER_CMD} ${DOCKER_TTY_FLAGS}"
DOCKER_CMD="${DOCKER_CMD} --rm"
DOCKER_CMD="${DOCKER_CMD} --name ${CONTAINER_NAME}"
#DOCKER_CMD="${DOCKER_CMD} --user ${USER_ID}:${GROUP_ID}"
DOCKER_CMD="${DOCKER_CMD} -v \"${CURRENT_DIR}:/workspace\""
DOCKER_CMD="${DOCKER_CMD} -e USER=${USERNAME}"
DOCKER_CMD="${DOCKER_CMD} -e HOME=/home/${USERNAME}"
DOCKER_CMD="${DOCKER_CMD} --cap-add SYS_ADMIN"
DOCKER_CMD="${DOCKER_CMD} --cap-add NET_ADMIN"
DOCKER_CMD="${DOCKER_CMD} --security-opt apparmor=unconfined"

# Add environment variables for terminal
if [ -n "${TERM:-}" ]; then
    DOCKER_CMD="${DOCKER_CMD} -e TERM=${TERM}"
fi

# Add the image and entrypoint arguments
DOCKER_CMD="${DOCKER_CMD} ${IMAGE_NAME}${ENTRYPOINT_ARGS}"

# Run the container
print_info "Launching DevBox environment..."
echo ""

# Execute the Docker command
eval ${DOCKER_CMD}
EXIT_CODE=$?

# Container has exited
if [ $EXIT_CODE -eq 0 ]; then
    print_info "Container exited successfully."
else
    print_warning "Container exited with code: ${EXIT_CODE}"
fi

exit $EXIT_CODE
