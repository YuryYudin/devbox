FROM ubuntu:24.04
ARG USER_ID GROUP_ID USERNAME NODE_VERSION

# Set non-interactive mode
ENV DEBIAN_FRONTEND=noninteractive

# Set timezone to BST
RUN ln -sf /usr/share/zoneinfo/Europe/London /etc/localtime

# Add repos and update/install packages
RUN apt-get update && apt-get -y install \
    openjdk-21-jdk \
    openjdk-17-jdk \
    scala \
    net-tools \
    iputils-ping \
    dnsutils \
    tcpdump \
    netcat-openbsd \
    init \
    telnet \
    bash-completion \
    screen \
    tmux \
    git \
    iptables \
    ipset \
    sudo \
    rsync \
    htop \
    wget \
    unzip \
    tar \
    gcc \
    cmake \
    vim \
    patch \
    build-essential \
    git \
    curl \
    rpm \
    ruby \
    zip \
    python3 \
    lsb-release \
    libgtest-dev \
    libgmock-dev \ 
    libmsgpack-dev \
    googletest \
    gradle \
    maven \
    ca-certificates \
    gnupg

# Install Docker CLI
RUN install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg && \
    chmod a+r /etc/apt/keyrings/docker.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt-get update && \
    apt-get -y install docker-ce-cli docker-buildx-plugin docker-compose-plugin

# Create same user and group as a local user
RUN groupadd -g $GROUP_ID $USERNAME || true && \
    useradd -m -u $USER_ID -g $GROUP_ID -s /bin/bash $USERNAME

USER $USERNAME
WORKDIR /home/$USERNAME

RUN set -e; f="/home/$USERNAME/.bashrc"; [ -f "$f" ] || touch "$f"; \
    sed -i "s/^alias la='ls -A'$/alias la='ls -lA'/" "$f"; \
    sed -i "s/^alias l='ls -CF'$/alias l='ls -aCF'/" "$f"; \
    grep -qxF "alias m='less'" "$f" || echo "alias m='less'" >> "$f"

RUN echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc

ENV DEVCONTAINER=true

ENV NVM_DIR="/home/$USERNAME/.nvm"
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash

RUN bash -c "source $NVM_DIR/nvm.sh && \
    if [[ \"$NODE_VERSION\" == '--lts' ]]; then \
        nvm install --lts && \
        nvm alias default 'lts/*'; \
    else \
        nvm install $NODE_VERSION && \
        nvm alias default $NODE_VERSION; \
    fi && \
    nvm use default"

RUN echo 'export NVM_DIR="$HOME/.nvm"' >> ~/.bashrc && \
    echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> ~/.bashrc && \
    echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"' >> ~/.bashrc

RUN bash -c "source $NVM_DIR/nvm.sh && \
    nvm use default && \
    npm install -g @anthropic-ai/claude-code && \
    npm install -g claude-flow@alpha"

RUN cat > ~/.tmux.conf <<'EOF'
set -g aggressive-resize on
set -g mouse on
set -g history-limit 10000

bind C-k send-prefix
set -g prefix C-k
unbind C-b
set -s escape-time 1
set -g base-index 1
setw -g pane-base-index 1

bind | split-window -h
bind - split-window -v

bind -r C-n select-window -t :+
bind -r C-k select-window -t :!
bind -r C-c new-window 
EOF

USER root

# Add sudoers entry for claude user (following Anthropic's model)
RUN echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$USERNAME && \
    chmod 0440 /etc/sudoers.d/$USERNAME

RUN mkdir -p /home/$USERNAME/.devbox
# Copy init-firewall script
COPY --chmod=755 init-firewall /home/$USERNAME/init-firewall
COPY --chmod=644 allowlist /home/$USERNAME/.devbox/allowlist
RUN chown $USER_ID:$GROUP_ID /home/$USERNAME/init-firewall /home/$USERNAME/.devbox/allowlist

USER $USERNAME
RUN bash -c "source $NVM_DIR/nvm.sh && claude --version"

USER root

COPY --chown=$USERNAME docker-entrypoint.sh /usr/local/bin/docker-entrypoint
RUN sed -i "s|DOCKERUSER|$USERNAME|g" /usr/local/bin/docker-entrypoint && \
    sed -i "s|DOCKERUSER|$USERNAME|g" /home/$USERNAME/init-firewall && \
    chmod +x /usr/local/bin/docker-entrypoint

ENTRYPOINT ["/usr/local/bin/docker-entrypoint"]

