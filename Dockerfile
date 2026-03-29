FROM debian:bookworm

ENV DEBIAN_FRONTEND=noninteractive
ENV IS_SANDBOX=1

RUN apt-get update && apt-get install -y \
    build-essential \
    chromium \
    chromium-driver \
    cmake \
    curl \
    dtach \
    git \
    libcurl4-openssl-dev \
    libffi-dev \
    libpq-dev \
    libreadline-dev \
    libssl-dev \
    libxml2-dev \
    libxslt1-dev \
    libyaml-dev \
    nodejs \
    npm \
    pkg-config \
    poppler-utils \
    postgresql \
    postgresql-contrib \
    postgresql-15-postgis-3 \
    redis-server \
    software-properties-common \
    sudo \
    tmux \
    wget \
    zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

# Install ttyd from GitHub releases
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then TTYD_ARCH="x86_64"; elif [ "$ARCH" = "aarch64" ]; then TTYD_ARCH="aarch64"; fi && \
    curl -fsSL "https://github.com/tsl0922/ttyd/releases/latest/download/ttyd.${TTYD_ARCH}" -o /usr/local/bin/ttyd && \
    chmod +x /usr/local/bin/ttyd

RUN curl -fsSL https://claude.ai/install.sh | bash && \
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
ENV PATH="/root/.local/bin:${PATH}"

RUN mkdir /src
WORKDIR /src

ARG NODE_MAJOR_VERSION=22

# Install asdf version manager (v0.16+ is a Go binary, not git clone)
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then ARCH="amd64"; elif [ "$ARCH" = "aarch64" ]; then ARCH="arm64"; fi && \
    mkdir -p ~/.asdf/bin && \
    curl -sSfL https://github.com/asdf-vm/asdf/releases/download/v0.16.7/asdf-v0.16.7-linux-${ARCH}.tar.gz | tar xz -C ~/.asdf/bin && \
    echo 'export PATH="$HOME/.asdf/bin:$HOME/.asdf/shims:$PATH"' >> ~/.bashrc

ENV PATH="/root/.asdf/bin:/root/.asdf/shims:${PATH}"

RUN echo 'legacy_version_file = yes' > ~/.asdfrc

# Install Node.js via asdf
RUN asdf plugin add nodejs && \
    asdf install nodejs latest:${NODE_MAJOR_VERSION} && \
    asdf set --home nodejs latest:${NODE_MAJOR_VERSION}

# Add ruby plugin (no ruby version installed by default)
RUN asdf plugin add ruby
RUN asdf plugin add crystal

# Install ccusage
RUN npm install -g ccusage && asdf reshim nodejs

# Install Playwright for MCP support
RUN npm install -g playwright && asdf reshim nodejs && \
    npx playwright install-deps chromium && \
    npx playwright install chromium

# Configure PostgreSQL to allow service start
RUN sed -i 's/local   all             postgres                                peer/local   all             postgres                                trust/' /etc/postgresql/15/main/pg_hba.conf && \
    sed -i 's/local   all             all                                     peer/local   all             all                                     trust/' /etc/postgresql/15/main/pg_hba.conf && \
    sed -i 's|host    all             all             127.0.0.1/32            scram-sha-256|host    all             all             127.0.0.1/32            trust|' /etc/postgresql/15/main/pg_hba.conf && \
    sed -i 's|host    all             all             ::1/128                 scram-sha-256|host    all             all             ::1/128                 trust|' /etc/postgresql/15/main/pg_hba.conf && \
    echo "listen_addresses = 'localhost'" >> /etc/postgresql/15/main/postgresql.conf

# Set up environment
ENV DEBIAN_FRONTEND=dialog

RUN echo 'set -g mouse on' >> /root/.tmux.conf

RUN mkdir -p /root/.claude

RUN cat > /root/.claude.json << EOF
{
  "hasCompletedOnboarding": true,
  "theme": "dark",
  "attribution": {
    "commit": "",
    "pr": ""
  }
}
EOF

RUN cat <<EOT >> /root/.claude/CLAUDE.md
- This is SANDBOX environment, where you have multiple tools pre-installed.
- You can start postgres by running: \`service postgresql start\`
- You can start redis server by running: \`service redis-server start\`
- Node.js major version installed: ${NODE_MAJOR_VERSION} using \`asdf\`
- Ruby plugin is available via asdf (\`asdf install ruby <version>\`)
- Playwright is installed for browser automation MCP
EOT

RUN echo "cat /root/.claude/CLAUDE.md" >> /root/.bashrc

# Create dummy config for ccusage and test all needed commands
RUN mkdir -p /root/.config/claude && \
    touch /root/.config/claude/config.json && \
    ccusage --version && \
    node --version && \
    psql --version && \
    redis-server --version && \
    npx playwright --version && \
    chromium --version && \
    chromedriver --version && \
    ttyd --version && \
    service postgresql start && \
    service redis-server start && \
    service postgresql stop && \
    service redis-server stop


RUN claude mcp add playwright npx @playwright/mcp@latest

RUN cat <<'ENTRYPOINT_SCRIPT' > /entrypoint.sh && chmod +x /entrypoint.sh
#!/bin/bash

wait

service --status-all

echo 'set -g mouse on' >> /root/.tmux.conf

asdf install &

if [ "${1}" == "ttydautostart" ]; then
  exec ttyd -W tmux new -A -s main bash
else
  exec "${@}"
fi
ENTRYPOINT_SCRIPT

EXPOSE 3000 7681
ENTRYPOINT ["/entrypoint.sh"]
CMD ["ttydautostart"]
