# Counter-Strike 1.6 Server - Bencownia

A customized Counter-Strike 1.6 server running in Docker with custom maps, plugins, and game modes.

## Overview

This project provides a fully configured Counter-Strike 1.6 dedicated server with:
- Custom maps (aim, awp, de, cs, fy game modes)
- AMX Mod X plugins and configurations
- Custom models, sounds, and sprites
- Docker-based deployment for easy setup

## Requirements

- Docker
- Docker Compose

## Quick Start

1. Clone the repository
2. Update the server password in `docker-compose.yml` (change `SERVER_PASSWORD`)
3. Start the server:

```bash
docker-compose up -d
```

The server will be available on:
- Game Port: `27015` (UDP/TCP)
- Web Admin: `8080` (TCP)

## Configuration

### Server Settings

Edit `docker-compose.yml` to customize:
- `SERVER_PORT`: Server port (default: 27015)
- `SERVER_MAP`: Starting map (default: de_dust2)
- `SERVER_MAX_PLAYERS`: Maximum players (default: 20)
- `SERVER_PASSWORD`: Server password (default: change-me)
- `SERVER_LAN`: LAN mode (0 = Internet, 1 = LAN)

### Maps

Custom maps are located in `cstrike/maps/` and include:
- Aim maps (aim_*, tir_*)
- AWP maps (awp_*)
- Bomb defusal maps (de_*)
- Hostage rescue maps (cs_*)
- Fun maps (fy_*, fun_*)

### AMX Mod X

The server includes AMX Mod X with:
- Custom plugins in `cstrike/addons/amxmodx/scripting/`
- Map-specific configurations in `cstrike/addons/amxmodx/configs/maps/`
- Custom spawn points in `cstrike/addons/amxmodx/configs/spawns/`

## Project Structure

```
cstrike-bencownia/
├── cstrike/                    # Server files and customizations
│   ├── addons/
│   │   └── amxmodx/           # AMX Mod X plugins and configs
│   │       ├── configs/       # Plugin configurations
│   │       ├── data/          # Plugin data files
│   │       └── scripting/     # Plugin source code
│   ├── maps/                  # Custom maps (.bsp files)
│   ├── models/                # Custom models
│   ├── sound/                 # Custom sounds
│   ├── sprites/               # Custom sprites
│   ├── gfx/                   # Graphics and skyboxes
│   └── overviews/             # Map overviews
├── cstrike_workdir/           # Server working directory (volume)
├── docker-compose.yml         # Docker Compose configuration
└── Dockerfile                 # Docker build configuration
```

## Running the Server

### Start the server
```bash
docker-compose up -d
```

### View logs
```bash
docker-compose logs -f
```

### Stop the server
```bash
docker-compose down
```

### Restart the server
```bash
docker-compose restart
```

## Connecting to the Server

In Counter-Strike 1.6:
1. Open the console (~)
2. Type: `connect <your-server-ip>:27015`
3. Enter the server password when prompted

## Notes

- The server runs on linux/amd64 platform
- For macOS M-series chips, CPU_MHZ is set to 2400
- Custom content is mounted from `./cstrike` to `/opt/steam/hlds/cstrike_overwrites`
- Server working directory is persisted in `./cstrike_workdir`

## Base Image

This server uses [ghcr.io/bordeux/cstrike-server](https://github.com/bordeux/cstrike-server) as the base image.
