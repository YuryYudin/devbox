FROM ubuntu:24.04
ARG USER_ID GROUP_ID USERNAME NODE_VERSION

# Set non-interactive mode
ENV DEBIAN_FRONTEND=noninteractive

# Set timezone to BST
RUN ln -sf /usr/share/zoneinfo/Europe/London /etc/localtime

# Install essential packages first (minimal for space)
RUN apt-get update --allow-insecure-repositories && \
    apt-get install -y --allow-unauthenticated --no-install-recommends \
        ca-certificates \
        gnupg \
        curl \
        wget \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

# Install core development packages in batches to manage space
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    less \
    build-essential \
    gcc \
    cmake \
    make \
    vim \
    sudo \
    tmux \
    screen \
    nasm \
    yasm \
    gawk \ 
    jq \
    libmariadbd-dev \
    libssl-dev \
    protobuf-compiler \ 
    libprotobuf-dev \
    ninja-build \
    ccache \
    bash-completion \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

# Install Java and development tools (keep recommends for JDK)
RUN apt-get update && apt-get install -y \
    openjdk-21-jdk \
    openjdk-17-jdk \
    && apt-get install -y --no-install-recommends \
    scala \
    gradle \
    maven \
    python3 \
    python3-pip \
    ruby \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

# Install Python packages for JIRA/Excel scripts
RUN pip3 install --no-cache-dir --break-system-packages \
    jira>=3.5.0 \
    pandas>=2.0.0 \
    openpyxl>=3.1.0 \
    python-dateutil>=2.8.0 \
    requests \
    matplotlib \
    python-dotenv
    

# Install network and system tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    net-tools \
    iputils-ping \
    dnsutils \
    tcpdump \
    netcat-openbsd \
    telnet \
    init \
    iptables \
    ipset \
    rsync \
    htop \
    unzip \
    tar \
    patch \
    rpm \
    zip \
    lsb-release \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

# Install clang-19 and LLVM toolchain from LLVM repository
RUN wget -qO /etc/apt/trusted.gpg.d/apt.llvm.org.asc https://apt.llvm.org/llvm-snapshot.gpg.key && \
    echo "deb http://apt.llvm.org/$(lsb_release -sc)/ llvm-toolchain-$(lsb_release -sc) main" | tee /etc/apt/sources.list.d/apt.llvm.org.list && \
    apt-get update && apt-get install -y --no-install-recommends \
    clang-19 \
    lld-19 \
    llvm-19 \
    libc++-19-dev \
    libc++abi-19-dev \
    clang-tools-19 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

# Install development libraries
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgtest-dev \
    libgmock-dev \
    libmsgpack-dev \
    googletest \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

# Install Docker CLI
RUN install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg && \
    chmod a+r /etc/apt/keyrings/docker.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt-get update && \
    apt-get -y install docker-ce-cli docker-buildx-plugin docker-compose-plugin \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

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
    npm install -g claude-flow"

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

