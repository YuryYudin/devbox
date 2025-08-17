# DevBox - Claude Code Docker Container

DevBox is a secure, isolated Docker container environment for running Claude Code CLI. It provides a consistent development environment with built-in security features and support for multiple programming languages.

## Features

- 🔒 **Secure Isolation**: Runs Claude Code in a sandboxed Docker container
- 🛡️ **Built-in Firewall**: Network traffic filtering with customizable allowlist
- 🔧 **Pre-configured Environment**: Includes common development tools and languages
- 📦 **Language Support**: Node.js, Python, Java (JDK 17 & 21), Ruby, and more
- 🔄 **Auto-updates**: Checks for updates from GitHub repository
- 🎯 **Claude Flow Support**: Integrated support for Claude's workflow mode
- 💾 **Persistent Authentication**: Saves Claude Code login across sessions
- 📁 **Per-Directory Configs**: Different Claude settings for different projects
- 🖥️ **Cross-platform**: Works on macOS, Linux, and Windows (with WSL2)

## Prerequisites

- Docker Desktop or Docker Engine
- Git
- Bash shell (on Windows, use WSL2 or Git Bash)

## Installation

### Quick Install

Run this command to install DevBox:

```bash
curl -fsSL https://raw.githubusercontent.com/YuryYudin/devbox/main/install.sh | bash
```

### Manual Installation

1. Clone the repository:
```bash
git clone https://github.com/YuryYudin/devbox.git ~/.devbox
```

2. Make scripts executable:
```bash
chmod +x ~/.devbox/*.sh ~/.devbox/dockerfiles/*
```

3. Build the container:
```bash
cd ~/.devbox && ./build.sh
```

4. (Optional) Create a symlink for easier access:
```bash
ln -s ~/.devbox/devbox.sh ~/.local/bin/devbox
```

5. Add ~/.local/bin to your PATH if not already present:
```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
# Or for zsh users:
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

## Usage

### Basic Usage

Start DevBox in your current directory:
```bash
devbox
```

Or if you haven't created a symlink:
```bash
~/.devbox/devbox.sh
```

### Command-Line Arguments

#### devbox.sh Arguments

| Argument | Description | Example |
|----------|-------------|---------|
| `--enable-sudo` | Enable sudo access inside the container | `devbox --enable-sudo` |
| `--disable-firewall` | Disable the built-in firewall protection | `devbox --disable-firewall` |
| `--claude-flow` | Launch with Claude Flow workflow mode | `devbox --claude-flow` |
| (any command) | Run a specific command in the container | `devbox npm install` |

**Examples:**

```bash
# Start interactive shell with sudo enabled
devbox --enable-sudo

# Run Claude Code with workflow mode
devbox --claude-flow

# Execute a single command
devbox python script.py

# Combine options
devbox --enable-sudo --disable-firewall

# Run npm commands
devbox npm install
devbox npm run build
```

### Updating DevBox

DevBox automatically checks for updates when you run it. You can:

1. **Accept the update prompt** when starting DevBox
2. **Manually update** at any time:
```bash
cd ~/.devbox && git pull && ./build.sh
```

## File Structure

```
~/.devbox/
├── build.sh              # Container build script
├── devbox.sh            # Main launcher script
├── install.sh           # Installation script
├── dockerfiles/
│   ├── Dockerfile       # Container definition
│   ├── docker-entrypoint # Container entry point
│   ├── init-firewall    # Firewall initialization
│   ├── allowlist        # Network allowlist
│   └── dockerignore     # Docker build exclusions
├── claude-configs/      # Shared Claude authentication
│   └── .claude/         # Authentication tokens
├── slots/               # Per-directory configurations
│   └── <project_name>/  # Project-specific settings
│       └── .claude.json # Claude configuration
└── .git/                # Git repository
```

## Security Features

### Network Firewall

DevBox includes a built-in firewall that:
- Blocks all outgoing network connections by default
- Allows connections only to domains in the allowlist
- Can be disabled with `--disable-firewall` if needed

### Allowlist Configuration

Edit `~/.devbox/dockerfiles/allowlist` to customize allowed domains:

```text
# Package registries
registry.npmjs.org
pypi.org
rubygems.org

# Development tools
github.com
gitlab.com

# AI Services
api.anthropic.com
api.openai.com

# Add your domains here
your-api.example.com
```

### Container Isolation

- Runs with limited capabilities by default
- User namespace mapping for security
- Read-only root filesystem (where applicable)
- No persistent storage outside mounted workspace

## Environment Details

### Pre-installed Software

**Languages & Runtimes:**
- Node.js (LTS version via NVM)
- Python 3
- Java (OpenJDK 17 & 21)
- Ruby
- GCC/G++ build tools

**Development Tools:**
- Git
- Vim
- Maven
- Gradle
- CMake
- Screen/Tmux

**Network Tools:**
- curl/wget
- netcat
- tcpdump
- dig/nslookup

**Claude Tools:**
- Claude Code CLI (`claude`)
- Claude Flow (`claude-flow`)

### Working Directory

Your current directory is mounted as `/workspace` inside the container. All file operations affect your actual files.

### Configuration Persistence

DevBox automatically saves your Claude Code authentication and configuration:
- **Authentication tokens** are saved in `~/.devbox/claude-configs/.claude/`
- **Project settings** are saved per directory in `~/.devbox/slots/<project_name>/`
- First-time users will need to authenticate with `/login` in Claude Code
- Subsequent runs will restore your authentication automatically

## Troubleshooting

### Docker Daemon Not Running

**macOS:**
```bash
# Start Docker Desktop application
open -a Docker
```

**Linux:**
```bash
sudo systemctl start docker
sudo systemctl enable docker  # Enable at boot
```

### Permission Denied

If you get permission errors:
```bash
# Add yourself to docker group (Linux)
sudo usermod -aG docker $USER
# Log out and back in for changes to take effect
```

### Container Build Fails

```bash
# Clean Docker cache and rebuild
docker system prune -a
cd ~/.devbox && ./build.sh
```

### Network Issues

If you need to access additional domains:
1. Edit `~/.devbox/dockerfiles/allowlist`
2. Add required domains
3. Rebuild: `cd ~/.devbox && ./build.sh`
4. Or disable firewall: `devbox --disable-firewall`

### Can't Find Command

If `devbox` command is not found:

```bash
# Check if ~/.local/bin is in your PATH
echo $PATH | grep -q "$HOME/.local/bin" || echo "Not in PATH"

# Add ~/.local/bin to PATH
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
# Or for zsh:
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc

# Alternatively, create an alias
echo 'alias devbox="$HOME/.devbox/devbox.sh"' >> ~/.bashrc
source ~/.bashrc
```

## Advanced Usage

### Custom Claude Configuration

Place your `.claude.json` configuration in your home directory before building:
```bash
cp /path/to/.claude.json ~/.claude.json
cd ~/.devbox && ./build.sh
```

### Persistent Sessions

Use tmux/screen inside the container for persistent sessions:
```bash
devbox
# Inside container:
tmux new -s work
# Detach: Ctrl+B, D
# Reattach later:
tmux attach -t work
```

### Volume Mounts

The current directory is automatically mounted. For additional mounts, modify `devbox.sh`:
```bash
# Add before the docker run command
DOCKER_CMD="${DOCKER_CMD} -v /path/to/host:/path/in/container"
```

## Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Open a Pull Request

## License

This project is open source. See the LICENSE file for details.

## Support

- **Issues**: [GitHub Issues](https://github.com/YuryYudin/devbox/issues)
- **Discussions**: [GitHub Discussions](https://github.com/YuryYudin/devbox/discussions)

## Acknowledgments

- Built for use with [Claude Code](https://claude.ai/code) by Anthropic
- Docker containerization for secure isolation
- Community contributions and feedback

---

**Note**: DevBox is designed to provide a secure, isolated environment for development. Always review and understand the security implications of running code in containers, especially when disabling security features like the firewall.