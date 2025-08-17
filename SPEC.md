# DevBox Project Specification

## Project Overview
A Docker-based development environment focused on Claude Code and Claude-Flow, providing an isolated, consistent development workspace with pre-installed tools and security features.

## Components

### 1. Docker Container (Existing)
- **Base Image**: Ubuntu 24.04
- **Pre-installed Tools**:
  - Development tools: JDK 17/21, Git, build-essential, CMake, Maven, Gradle
  - Network tools: net-tools, tcpdump, netcat, iptables
  - Terminal tools: tmux, screen, vim
  - Node.js via NVM (LTS version by default)
  - Claude Code and Claude-Flow (alpha)
- **Security Features**:
  - Firewall with allowlist for approved domains
  - Optional sudo access (disabled by default)
  - User/group mapping to host system

### 2. Build Script (`build.sh`)

#### Purpose
Build the Docker container image with proper configuration and versioning.

#### Features
- **Automatic User Detection**: 
  - Extracts current user's ID, group ID, and username
  - Passes these as build arguments to Dockerfile
  
- **Version Management**:
  - Extracts Claude Code version from Dockerfile
  - Tags image as `devbox:claude-<version>`
  - Also tags as `devbox:latest`
  
- **Node.js Configuration**:
  - Sets NODE_VERSION to `--lts` by default
  
- **Validation**:
  - Checks if Docker is installed
  - Verifies Docker daemon is running
  - Suggests installation/startup if not available
  - Validates required Dockerfile and supporting files exist

#### Build Process
1. Validate Docker availability
2. Extract user information (UID, GID, username)
3. Parse Claude Code version from Dockerfile
4. Build image with appropriate build args
5. Tag image with version and latest

### 3. Wrapper Script (`run.sh`)

#### Purpose
Start and manage Docker container instances with proper volume mounting and configuration.

#### Features
- **Volume Mounting**:
  - Always mounts current directory as `/workspace` in container
  - Preserves file ownership through user/group mapping
  
- **Container Management**:
  - Always creates new container instance
  - Auto-removes container after exit
  - Generates unique container names with timestamps
  
- **Command-Line Arguments**:
  - `--enable-sudo`: Enable sudo access in container
  - `--disable-firewall`: Disable network firewall restrictions
  - `--claude-flow`: Use Claude-Flow instead of Claude Code
  - Additional arguments passed through to entrypoint
  
- **Environment**:
  - Passes through terminal settings
  - Maintains proper PATH configuration
  - Supports interactive and non-interactive modes

#### Execution Flow
1. Parse command-line arguments
2. Generate unique container name
3. Set up Docker run command with:
   - Volume mount of current directory
   - User/group mapping
   - TTY allocation for interactive mode
   - Appropriate flags based on arguments
4. Execute container with auto-removal
5. Return exit code from container

## Directory Structure
```
/Users/jjb/Work/Claude/devbox/
├── dockerfiles/
│   ├── Dockerfile
│   ├── docker-entrypoint
│   ├── init-firewall
│   ├── allowlist
│   └── dockerignore
├── build.sh            (to be created)
├── run.sh             (to be created)
└── SPEC.md            (this file)
```

## Usage Workflow

### Initial Setup
```bash
# Build the container image
./build.sh
```

### Daily Usage
```bash
# Start Claude Code in current directory
./run.sh

# Start Claude-Flow instead
./run.sh --claude-flow

# Run with sudo enabled
./run.sh --enable-sudo

# Disable firewall restrictions
./run.sh --disable-firewall

# Pass specific commands
./run.sh "help"
```

## Security Considerations
- Firewall enabled by default with domain allowlist
- Sudo access disabled by default
- Container runs as non-root user matching host user
- Network access restricted to approved domains (Anthropic, GitHub, etc.)
- Containers are ephemeral (removed after exit)

## Technical Requirements
- Docker Engine installed and running
- Linux or macOS host system
- Bash shell for scripts
- Internet access for initial build (package downloads)

## Future Enhancements (Out of Scope)
- Container reuse/persistence options
- Custom port mapping support
- Multiple workspace mounts
- Configuration file support
- Windows host support
- Docker Compose integration