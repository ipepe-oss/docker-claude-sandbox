# ubuntu-claude

Docker image for running [Claude Code](https://claude.ai/code) in an Ubuntu container.

The image comes pre-configured with `~/.claude.json` settings:
- Onboarding completed
- Dark theme enabled

## Usage

### Basic usage

Run the container with your current directory mounted to `/src`:

```bash
docker run -it -v $(pwd):/src ipepe/ubuntu-claude
```

### Fish shell

```fish
docker run -it -v (pwd):/src ipepe/ubuntu-claude
```

### With custom working directory

```bash
docker run -it -v /path/to/project:/src ipepe/ubuntu-claude
```

### Interactive shell

```bash
docker run -it --entrypoint /bin/bash -v $(pwd):/src ipepe/ubuntu-claude
```

## Building

```bash
docker build -t ubuntu-claude .
```

## Multi-architecture build

To build and push for both amd64 and arm64:

```bash
./publish.sh
```
