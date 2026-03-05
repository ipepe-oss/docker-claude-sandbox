# Build gotty from source
FROM golang:1.23 AS gotty-builder
RUN git clone https://github.com/sorenisanerd/gotty.git /gotty && \
    cd /gotty && \
    CGO_ENABLED=0 go build -o /gotty-bin .

FROM ubuntu:22.04

RUN apt-get update && apt-get install -y curl git && \
    curl -fsSL https://claude.ai/install.sh | bash && \
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
ENV IS_SANDBOX=1
ENV PATH="/root/.local/bin:${PATH}"

RUN mkdir /src
WORKDIR /src

# Build arguments
ARG RUBY_VERSION=3.4.8
ARG NODE_MAJOR_VERSION=22

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Update and install essential packages
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    curl \
    dtach \
    git \
    wget \
    libssl-dev \
    libreadline-dev \
    zlib1g-dev \
    libpq-dev \
    libyaml-dev \
    libxml2-dev \
    libxslt1-dev \
    libcurl4-openssl-dev \
    software-properties-common \
    libffi-dev \
    nodejs \
    npm \
    pkg-config \
    postgresql \
    postgresql-contrib \
    redis-server \
    sudo \
    tmux \
    && rm -rf /var/lib/apt/lists/*

# Install rbenv and ruby-build
RUN git clone https://github.com/rbenv/rbenv.git ~/.rbenv && \
    echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc && \
    echo 'eval "$(rbenv init -)"' >> ~/.bashrc && \
    git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build && \
    echo 'export PATH="$HOME/.rbenv/plugins/ruby-build/bin:$PATH"' >> ~/.bashrc

# Install Ruby using rbenv with the version from build argument
ENV PATH="/root/.rbenv/bin:/root/.rbenv/shims:${PATH}"
RUN rbenv install ${RUBY_VERSION} && \
    rbenv global ${RUBY_VERSION} && \
    rbenv rehash

# Install nodenv and node-build
RUN git clone https://github.com/nodenv/nodenv.git ~/.nodenv && \
    echo 'export PATH="$HOME/.nodenv/bin:$PATH"' >> ~/.bashrc && \
    echo 'eval "$(nodenv init -)"' >> ~/.bashrc && \
    git clone https://github.com/nodenv/node-build.git ~/.nodenv/plugins/node-build && \
    echo 'export PATH="$HOME/.nodenv/plugins/node-build/bin:$PATH"' >> ~/.bashrc

# Install Node.js using nodenv with major version from build argument
ENV PATH="/root/.nodenv/bin:/root/.nodenv/shims:${PATH}"
RUN NODE_VERSION=$(nodenv install -l | grep "^${NODE_MAJOR_VERSION}\." | tail -1) && \
    nodenv install ${NODE_VERSION} && \
    nodenv global ${NODE_VERSION} && \
    nodenv rehash

# Install ccusage
RUN npm install -g ccusage && nodenv rehash

# Install gotty
COPY --from=gotty-builder /gotty-bin /usr/local/bin/gotty

RUN echo "permit-write = true" >> ~/.gotty && \
    echo "reconnect = true" >> ~/.gotty

# Install Chromium and ChromeDriver from Debian bookworm (Ubuntu 22.04 only has snap packages which don't work in Docker)
RUN echo "deb [trusted=yes] http://deb.debian.org/debian bookworm main" > /etc/apt/sources.list.d/debian-bookworm.list && \
    apt-get update && \
    apt-get install -y -t bookworm chromium chromium-driver && \
    rm /etc/apt/sources.list.d/debian-bookworm.list && \
    rm -rf /var/lib/apt/lists/*

# Install Playwright for MCP support
RUN npm install -g playwright && nodenv rehash && \
    npx playwright install-deps chromium && \
    npx playwright install chromium

# Configure PostgreSQL to allow service start
RUN sed -i 's/local   all             postgres                                peer/local   all             postgres                                trust/' /etc/postgresql/14/main/pg_hba.conf && \
    sed -i 's/local   all             all                                     peer/local   all             all                                     trust/' /etc/postgresql/14/main/pg_hba.conf

# Set up environment
ENV DEBIAN_FRONTEND=dialog

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
- Ruby version installed: ${RUBY_VERSION} using `rbenv`
- Node.js major version installed: ${NODE_MAJOR_VERSION} is installed using `nodenv`
- Playwright is installed for browser automation MCP
- You can use 'ccusage' command to check resource usage.
EOT

RUN echo "cat /root/.claude/CLAUDE.md" >> /root/.bashrc

# Create dummy config for ccusage and test all needed commands
RUN mkdir -p /root/.config/claude && \
    touch /root/.config/claude/config.json && \
    ccusage --version && \
    ruby --version && \
    node --version && \
    psql --version && \
    redis-server --version && \
    npx playwright --version && \
    chromium --version && \
    chromedriver --version && \
    gotty --version && \
    service postgresql start && \
    service redis-server start && \
    service postgresql stop && \
    service redis-server stop


RUN claude mcp add playwright npx @playwright/mcp@latest

# Create entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 8080 3000 5432 6379
ENTRYPOINT ["/entrypoint.sh"]
CMD ["gottyautostart"]
