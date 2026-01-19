FROM ubuntu:22.04

RUN apt-get update && apt-get install -y curl git
RUN curl -fsSL https://claude.ai/install.sh | bash
RUN echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
ENV IS_SANDBOX=1

RUN mkdir /src
WORKDIR /src
