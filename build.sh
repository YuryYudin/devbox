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

# Get the script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DOCKERFILE_DIR="${SCRIPT_DIR}/dockerfiles"

# Check if Dockerfile exists
if [ ! -f "${DOCKERFILE_DIR}/Dockerfile" ]; then
    print_error "Dockerfile not found at ${DOCKERFILE_DIR}/Dockerfile"
    exit 1
fi

# Check if other required files exist
REQUIRED_FILES=("docker-entrypoint" "init-firewall" "allowlist")
for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "${DOCKERFILE_DIR}/${file}" ]; then
        print_error "Required file not found: ${DOCKERFILE_DIR}/${file}"
        exit 1
    fi
done

# Auto-detect user information
USER_ID=$(id -u)
GROUP_ID=$(id -g)
USERNAME=$(whoami)

print_info "Building with user configuration:"
echo "  - Username: ${USERNAME}"
echo "  - User ID: ${USER_ID}"
echo "  - Group ID: ${GROUP_ID}"

# Extract Claude Code version from Dockerfile
CLAUDE_VERSION=$(grep -E "npm install -g @anthropic-ai/claude-code" "${DOCKERFILE_DIR}/Dockerfile" | head -1 | grep -oE "@[^[:space:]]+$" || echo "")
if [ -z "$CLAUDE_VERSION" ]; then
    CLAUDE_VERSION="latest"
else
    # Remove @ symbol and package name prefix
    CLAUDE_VERSION=$(echo "$CLAUDE_VERSION" | sed 's/@anthropic-ai\/claude-code//' | sed 's/@//')
    if [ -z "$CLAUDE_VERSION" ]; then
        CLAUDE_VERSION="latest"
    fi
fi

print_info "Claude Code version: ${CLAUDE_VERSION}"

# Set image name and tag
IMAGE_NAME="devbox"
IMAGE_TAG="claude-${CLAUDE_VERSION}"
FULL_IMAGE_NAME="${IMAGE_NAME}:${IMAGE_TAG}"

print_info "Building Docker image: ${FULL_IMAGE_NAME}"

# Copy docker-entrypoint.sh to the expected name for the Dockerfile
cp "${DOCKERFILE_DIR}/docker-entrypoint" "${DOCKERFILE_DIR}/docker-entrypoint.sh"

# Clean up Docker system to free space
print_info "Cleaning up Docker system to free space..."
docker system prune -f

# Build the Docker image with no cache to reduce space usage
docker build \
    --no-cache \
    --build-arg USER_ID="${USER_ID}" \
    --build-arg GROUP_ID="${GROUP_ID}" \
    --build-arg USERNAME="${USERNAME}" \
    --build-arg NODE_VERSION="--lts" \
    -t "${FULL_IMAGE_NAME}" \
    -t "${IMAGE_NAME}:latest" \
    -f "${DOCKERFILE_DIR}/Dockerfile" \
    "${DOCKERFILE_DIR}"

# Clean up the temporary file
rm -f "${DOCKERFILE_DIR}/docker-entrypoint.sh"

if [ $? -eq 0 ]; then
    print_info "Docker image built successfully!"
    echo ""
    echo "Tagged as:"
    echo "  - ${FULL_IMAGE_NAME}"
    echo "  - ${IMAGE_NAME}:latest"
    echo ""
    echo "To run the container, use: ./run.sh"
else
    print_error "Docker build failed!"
    exit 1
fi
