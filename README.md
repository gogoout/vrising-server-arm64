# V Rising Docker Image (ARM64)

This Docker image allows you to run the V Rising Windows game server on an ARM64 Linux machine using FEX-Emu and Wine.
Only tested on Oracle Cloud ARM instances.

[![Docker Pulls](https://badgen.net/docker/pulls/gogoout/vrising-arm64?icon=docker&label=pulls)](https://hub.docker.com/r/gogoout/vrising-arm64/)
[![Docker Stars](https://badgen.net/docker/stars/gogoout/vrising-arm64?icon=docker&label=stars)](https://hub.docker.com/r/gogoout/vrising-arm64/)
[![Docker Image Size](https://badgen.net/docker/size/gogoout/vrising-arm64/latest/arm64?icon=docker&label=image%20size)](https://hub.docker.com/r/gogoout/vrising-arm64/)
[![Github stars](https://badgen.net/github/stars/gogoout/vrising-server-arm64?icon=github&label=stars)](https://github.com/gogoout/vrising-server-arm64)
[![Github last-commit](https://img.shields.io/github/last-commit/gogoout/vrising-server-arm64)](https://github.com/gogoout/vrising-server-arm64)

## Prerequisites

- Docker installed on your ARM64 Linux machine
- Exposed UDP ports 9876 and 9877 on your ARM64 Linux machine

## Getting Started

- Create a container from the built image and map the necessary ports:

```bash
docker run -d --name vrising -p 9876:9876/udp -p 9877:9877/udp -v /path/to/save-data:/vrising/data -v /path/to/server:/vrising/server gogoout/vrising-arm64
```

- Docker compose

```yaml
version: '3.8'
services:
  vrising:
    stdin_open: true # equivalent of -i
    tty: true        # equivalent of -t
    # build: . # Build from Dockerfile
    restart: unless-stopped
    container_name: vrising
    labels:
      vrising-app: true
    image: gogoout/vrising-arm64
    network_mode: bridge
    environment:
      - TZ=Asia/Tokyo
    volumes:
      - '/home/ubuntu/v/server:/vrising/server:rw'
      - '/home/ubuntu/v/data:/vrising/data:rw'
    ports:
      - '9876:9876/udp'
      - '9877:9877/udp'
      - '25575:25575/tcp'
  autoheal:
    restart: always
    image: willfarrell/autoheal
    environment:
      - AUTOHEAL_CONTAINER_LABEL=vrising-app
      - AUTOHEAL_INTERVAL=15
      - AUTOHEAL_ONLY_MONITOR_RUNNING=true
      - AUTOHEAL_START_PERIOD=600
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
```

Replace `/path/to/save-data` with the path where you want to store the server's save data on your host machine.
Replace `/path/to/server` with the path where you want to store the server's save data on your host machine.

## Configuration

Upon first run, the server will generate default configuration files at `/vrising/data/Settings/` if not provided. You
can modify this file to customize your server settings
following [official guide](https://github.com/StunlockStudios/vrising-dedicated-server-instructions).

## Volumes

The Docker image accepts the following volumes:

| Volume Path            | Description                                  |
|------------------------|----------------------------------------------|
| `/vrising/server`      | Location where the game server persists      |
| `/vrising/data`        | Location for save data, server configs, etc. |
| `/home/steam/steamcmd` | Location where SteamCMD is saved             |

## Known Issues

- The server would random crash (without error log) after sometimes. I have included a health check script to test the server if it is not
  running. It's recommended to use docker-compose to run the server. The autoheal container will restart the server if
  it's not running.
- The health check script checks if any files is being modified in the last 3 minutes. So be sure to set your
  AutoSaveInterval to less than 3 minutes.

## Acknowledgments

- [FEX-Emu](https://fex-emu.com/)
- [Wine](https://www.winehq.org/)
- [Stunlock Studios](https://www.stunlockstudios.com/)
- [nitrog0d/palworld-arm64](https://github.com/nitrog0d/palworld-arm64) where I copied fex script into this repo
- [TrueOsiris/docker-vrising](https://github.com/TrueOsiris/docker-vrising) where I copied shell script to init the
  server
- [dirtboll/winebox64](https://github.com/dirtboll/winebox64) where I copied the wine related code
