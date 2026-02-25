FROM ubuntu

RUN apt-get update && apt-get install -y curl git
RUN curl -fsSL https://claude.ai/install.sh | bash
RUN echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
ENV IS_SANDBOX=1

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

RUN mkdir /src
WORKDIR /src
