Of course. A good README is essential for any project. This one is designed to be high-level and guide users directly to a working Docker Compose setup, with clear explanations for the volumes and essential environment variables.

Here is the `README.md` for your GitHub project.

---

# Plutainer 🚀

**Plutonium Game Servers in a Docker Container**

Plutainer is a versatile, game-agnostic Docker image designed to simplify running dedicated servers for your favorite Plutonium-supported titles. Configure everything with environment variables and get your server online in minutes.

Brought to you by [Ayymoss](https://github.com/ayymoss).

## ✨ Features

-   **Multi-Game Support**: A single image runs servers for T4, T5, T6, and IW5.
-   **Configuration via Environment**: No need to edit files inside the container. Manage your server entirely through environment variables.
-   **Automatic Updates**: The container automatically runs the Plutonium updater on every startup to ensure your server is always on the latest version.
-   **Built-in Health Checks**: The Docker health check intelligently monitors your game server's status.
-   **Persistent Storage**: Easily manage server data, logs, and configurations by mounting persistent volumes.

## 🏁 Getting Started

The recommended way to run Plutainer is with Docker Compose.

### 1. Directory Structure

Before you start, create a directory structure on your host machine to store your persistent data. We recommend a separate directory for each server instance.

```
/servers/
├── t6zm-server-1/     # This directory will be mounted to /home/plutouser/plutonium
├── t6mp-server-1/
└── iw5-server-1/
```

### 2. Docker Compose

Create a `docker-compose.yml` file with the following content. This example sets up a Black Ops 2 Zombies server.

```yaml
version: "3.8"

services:
  t6-zombies-server:
    # Use the latest image from the GitHub Container Registry
    image: ghcr.io/ayymoss/plutainer:latest
    container_name: t6zm-server-1
    restart: unless-stopped

    # Expose the game port. The left side is the host port, the right is the container port.
    # The default container port is game-dependent (e.g., T6=4976, T4/T5=28960, IW5=27016).
    ports:
      - "4976:4976/udp"

    volumes:
      # Mount your dedicated server game files as read-only.
      # This is the full game dump required by the Plutonium dedicated server guide.
      - /path/to/your/t6_game_files:/home/plutouser/gamefiles:ro

      # Mount a directory for persistent data (configs, logs, player data).
      # Use a unique directory for each server instance.
      - ./t6zm-server-1:/home/plutouser/plutonium

    environment:
      # --- Required Variables ---
      - PLUTO_SERVER_KEY=<YOUR_SERVER_KEY>
      - PLUTO_CONFIG_FILE=dedicated_zm.cfg
      - PLUTO_GAME=t6zm

      # --- Optional Variables ---
      - PLUTO_SERVER_NAME=My Awesome T6 Zombies Server!
```

### 3. Launch the Server

Place your server configuration file (e.g., `dedicated_zm.cfg`) inside the persistent data directory you created (`./t6zm-server-1/`). Then, start the container:

```sh
docker-compose up -d
```

Your server will start, automatically update, and become available for players to join.

## ⚙️ Configuration

Plutainer is configured entirely through environment variables.

### Required Variables

| Variable            | Description                                                                                                                              | Example                               |
| ------------------- | ---------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------- |
| `PLUTO_SERVER_KEY`  | Your server key from the [Plutonium Key Page](https://platform.plutonium.pw/serverkeys).                                                   | `VQMBh6Ifwsdk9tHPepseBtIdiNVmwU4U`     |
| `PLUTO_CONFIG_FILE` | The name of your server's `.cfg` file. This file must be placed in the persistent data volume.                                            | `dedicated.cfg`                       |
| `PLUTO_GAME`        | The game mode to launch. See the list of supported games below.                                                                          | `t6zm`                                |
| `PLUTO_MAX_CLIENTS` | **Required for T5 (Black Ops 1) only.** The maximum number of players. For T5 Zombies, this is typically `4`; for MP, it can be up to `18`. | `18`                                  |

### Optional Variables

| Variable              | Description                                                                                                                                                | Default                            |
| --------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------- |
| `PLUTO_SERVER_NAME`   | A friendly name for your server.                                                                                                                           | `Plutonium Docker Server`          |
| `PLUTO_PORT`          | Overrides the default game port. **Not recommended**; it's better to map ports using Docker's `ports` directive.                                             | (Game-specific default)            |
| `PLUTO_MOD`           | Loads a mod by setting `fs_game`.                                                                                                                          | (Not set)                          |
| `PLUTO_HEALTHCHECK`   | Set to `false` to disable the Docker health check. Useful for debugging.                                                                                   | `true`                             |

## 🎮 Supported Games

The following values are valid for the `PLUTO_GAME` environment variable:

-   `t6mp` (Black Ops 2 Multiplayer)
-   `t6zm` (Black Ops 2 Zombies)
-   `t5mp` (Black Ops 1 Multiplayer)
-   `t5sp` (Black Ops 1 Zombies)
-   `t4mp` (World at War Multiplayer)
-   `t4sp` (World at War Zombies)
-   `iw5mp` (Modern Warfare 3 Multiplayer)

## 📚 Wiki

For in-depth information on server configuration, game-specific directory nuances, and advanced usage, please see the **[Plutainer Wiki](https://github.com/Ayymoss/Plutainer/wiki)**. (Note: Link will be active once the wiki is created).