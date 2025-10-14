# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Building the Container
```bash
./build.sh
```
Builds the Docker image with the current user's configuration (username, UID, GID). The build script automatically detects and tags the image based on the Claude Code version specified in the Dockerfile.

### Running DevBox
```bash
./devbox.sh [OPTIONS] [COMMAND]
```

Key options:
- `--enable-sudo` - Enable sudo access inside container
- `--disable-firewall` - Disable network firewall restrictions
- `--enable-docker` - Mount Docker socket for Docker-in-Docker operations
- `--mount /path` - Mount additional directories at their original locations (can be used multiple times)
- `--start-claude` - Start Claude Code (by default, not started)
- `--start-tmux` - Start tmux session (by default, not started)
- `--clean-on-shutdown` - Remove container after use (default preserves containers)
- `--rebuild-containers` - Force rebuild of all containers
- `--preserve-homedir` - Preserve home directories when rebuilding

### Container Management
```bash
./devbox.sh --list-containers    # List all DevBox containers
./devbox.sh --clean-all          # Remove all DevBox containers
./devbox.sh update               # Update DevBox and rebuild with latest packages
```

### Examples with Additional Mounts
```bash
# Mount a single additional directory
./devbox.sh --mount /data/shared

# Mount multiple directories
./devbox.sh --mount /data/shared --mount /config/app --mount /var/logs

# Combine with other options
./devbox.sh --mount /data --enable-docker --disable-firewall
```

## Architecture Overview

DevBox creates isolated Docker containers for running Claude Code CLI with configurable security and development tools. The architecture consists of:

### Core Components

1. **devbox.sh** (Main Launcher - 1000+ lines)
   - Handles all command-line arguments and orchestration
   - Manages container lifecycle (creation, reuse, cleanup)
   - Implements configuration persistence across sessions
   - Creates per-directory containers for project isolation
   - Auto-detects and pulls updates from GitHub

2. **build.sh** (Container Builder)
   - Detects user configuration (UID, GID, username)
   - Builds Docker image with appropriate tags
   - Validates Docker daemon availability

3. **dockerfiles/Dockerfile**
   - Ubuntu 24.04 base with extensive development tools
   - Installs: Java (JDK 17 & 21), Scala, Python3, Ruby, Node.js (via NVM)
   - Includes Docker CLI, build tools, network utilities
   - Configures user matching host system for file permissions

4. **dockerfiles/docker-entrypoint**
   - Container initialization script
   - Sets up tmux with custom configuration (Ctrl+k prefix)
   - Manages firewall initialization
   - Handles Claude Code startup modes

5. **dockerfiles/init-firewall**
   - Implements iptables-based network filtering
   - Reads allowlist and configures DNS resolution
   - Blocks unauthorized outbound connections

### Configuration Persistence

DevBox maintains state across sessions through a multi-tiered storage system:

- **~/.devbox/claude-configs/** - Shared Claude authentication tokens
- **~/.devbox/slots/<project>/** - Per-directory project configurations
- **/tmp/devbox-claude-<container>/** - Temporary metadata during runtime

The `prepare_claude_config()` and `save_claude_config()` functions in devbox.sh handle the complex logic of preserving and restoring Claude configurations between container runs.

### Container Naming Strategy

Containers are named as `devbox-<username>-<sanitized_path>` where the path is derived from the current directory, ensuring each project gets its own persistent container.

### Security Model

- **Default**: Firewall enabled, no sudo, no Docker access
- **Network filtering**: Via iptables and ipset with configurable allowlist
- **User mapping**: Container user matches host user for proper file permissions
- **Optional relaxation**: Flags to enable sudo, disable firewall, or mount Docker socket

### Update Mechanism

The script checks for updates by comparing local and remote Git commits, offering to pull and rebuild when updates are available. The `update` command performs a full rebuild with latest packages.

## Key Implementation Details

- Container reuse logic checks for existing containers and reattaches/restarts as needed
- Home directory preservation during rebuilds uses tar archives in /tmp
- Docker-in-Docker support requires explicit `--enable-docker` flag for security
- Tmux configuration provides developer-friendly keybindings and mouse support
- Multiple runtime modes: plain bash (default), Claude only, tmux only, or Claude in tmux (with both flags)