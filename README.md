# Plutainer 🚀

**Plutonium Game Servers in a Docker Container**

Plutainer is a versatile, game-agnostic Docker image designed to simplify running dedicated servers for your favourite Plutonium-supported titles. Configure everything with environment variables and get your server online in minutes.

## ✨ Features

-   **Multi-Game Support**: A single image runs servers for T4, T5, T6, and IW5.
-   **Configuration via Environment**: No need to edit files inside the container. Manage your server entirely through environment variables.
-   **Automatic Updates**: The container automatically runs the Plutonium updater on every startup to ensure your server is always on the latest version.
-   **Built-in Health Checks**: The Docker health check intelligently monitors your game server's status to ensure it's responsive.
-   **Persistent Storage**: Easily manage server data, logs, and configurations by mounting persistent volumes.

## 🏁 Getting Started

The recommended way to run Plutainer is with Docker Compose.

### 1. Directory Structure

Before you start, create a directory structure on your host machine to store your persistent data. We recommend a separate directory for each server instance to keep configurations and logs isolated.

```
/opt/pluto-servers/
├── t6zm-server-1/     # This directory will be mounted to /home/plutouser/plutonium
├── t6mp-server-1/
├── iw5-server-1/
└── docker-compose.yml
```

### 2. Docker Compose

Create a `docker-compose.yml` file with the following content. This example sets up a Black Ops 2 Zombies server.

```yaml
services:
  t6-zombies-server:
    # Use the latest image from the GitHub Container Registry
    image: ghcr.io/ayymoss/plutainer:latest
    container_name: t6zm-server-1
    restart: unless-stopped

    # Expose the game port. The left side is the host port, the right is the container port.
    # The default container port is game-dependent (e.g., T6=4976).
    ports:
      - "4976:4976/udp"

    volumes:
      # Mount your dedicated server game files as read-only.
      # This is the full game dump required by the Plutonium dedicated server guide.
      - /path/to/your/t6_game_files:/home/plutouser/gamefiles:ro

      # Mount a directory for persistent data (configs, logs, player data).
      # Use a unique directory for each server instance.
      - /opt/pluto-servers/t6zm-server-1:/home/plutouser/plutonium

    environment:
      # --- Required Variables ---
      - PLUTO_SERVER_KEY=YOUR_SUPER_SECRET_KEY
      - PLUTO_CONFIG_FILE=dedicated_zm.cfg
      - PLUTO_GAME=t6zm
      - PLUTO_PORT=4976

      # --- Optional Variables ---
      - PLUTO_SERVER_NAME=My Awesome T6 Zombies Server!
```

For a complete example of each server and IW4MAdmin, please see: [EXAMPLE-docker-compose.yml](EXAMPLE-docker-compose.yml)

### 3. Launch the Server

Place your server configuration file (e.g., `dedicated_zm.cfg`) inside the correct sub-directory within your persistent data volume (see [Game-Specific Configuration](#-game-specific-configuration) for paths). Then, start the container:

```sh
docker compose up -d
```

Your server will start, automatically update its files, and become available for players to join!

## 👤 User and File Permissions

For enhanced security, Plutainer does not run as the `root` user. Instead, it uses a dedicated, unprivileged user named `plutouser`.

*   **User:** `plutouser`
*   **User ID (UID):** `1000`
*   **Group ID (GID):** `1000`

### Why This Matters

When you mount volumes from your host machine into the container, the `plutouser` (with UID `1000`) needs to have the appropriate permissions to read and write to those directories. If the ownership on your host directories is incorrect, the server may fail to start or be unable to save data.

On many desktop Linux distributions (like Ubuntu), the first user you create is automatically assigned UID `1000`. If you are that user, you may not need to do anything. However, if you created the directories as `root` (e.g., using `sudo mkdir`), you will need to update their ownership.

### How to Fix Permissions

To ensure the container has the correct access, you should change the ownership of your persistent data directory to match the container's user. Run the following command on your host machine, adjusting the path to match your setup:

```sh
sudo chown -R 1000:1000 /path/to/your/server-data/
```

For example, using the directory structure from our guide:

```sh
sudo chown -R 1000:1000 /opt/pluto-servers/t6zm-server-1/
```

The `-R` flag applies the ownership recursively, ensuring all files and sub-folders have the correct permissions. While the container only needs to *read* the game files, applying correct ownership to that volume as well is good practice to avoid any potential read-related issues.

## ⚙️ Configuration

Plutainer is configured entirely through environment variables.

### Required Variables

| Variable | Description | Example |
| :--- | :--- | :--- |
| `PLUTO_SERVER_KEY` | Your server key from the [Plutonium Key Page](https://platform.plutonium.pw/serverkeys). | `VQMBh6Ifwsdk9tHPepseBtIdiNVmwU4U` |
| `PLUTO_CONFIG_FILE` | The name of your server's `.cfg` file. Its required location depends on the game. | `dedicated.cfg` |
| `PLUTO_GAME` | The game mode to launch. See the list of supported games below. | `t6zm` |
| `PLUTO_MAX_CLIENTS` | **Required for T5 (Black Ops 1) only.** The max players. For T5 Zombies, this is `4`; for MP, it can be up to `18`. | `18` |
| `PLUTO_PORT` | Overrides the default game port. | (Game-specific default) |

### Optional Variables

| Variable | Description | Default |
| :--- | :--- | :--- |
| `PLUTO_SERVER_NAME` | A friendly name for your server. | `Plutonium Docker Server` |
| `PLUTO_MOD` | Loads a mod by setting the `fs_game` variable for the server. | (Not set) |
| `PLUTO_HEALTHCHECK` | Set to `false` to disable the Docker health check. Useful for debugging. | `true` |
| `PLUTO_AUTO_UPDATE` | Set to `false` to disable auto-updating. Useful if you have scripts that may break. | `true` |

## 🎮 Supported Games & Defaults

The `PLUTO_GAME` environment variable accepts the following values. Note that each game has a different default port and expects its configuration file (`PLUTO_CONFIG_FILE`) in a specific directory.

| `PLUTO_GAME` Value | Game | Default Port | Required Config Path (inside the persistent volume) |
| :--- | :--- | :--- | :--- |
| `t6mp` | Black Ops 2 Multiplayer | `4976/udp` | `/storage/t6/` |
| `t6zm` | Black Ops 2 Zombies | `4976/udp` | `/storage/t6/` |
| `t5mp` | Black Ops 1 Multiplayer | `28960/udp` | `/storage/t5/` |
| `t5sp` | Black Ops 1 Zombies | `28960/udp` | `/storage/t5/` |
| `t4mp` | World at War Multiplayer | `28960/udp` | `../gamefiles/main/` **(See Note)** |
| `t4sp` | World at War Zombies | `28960/udp` | `../gamefiles/main/` **(See Note)** |
| `iw5mp` | Modern Warfare 3 MP | `27016/udp` | `../gamefiles/admin/` **(See Note)** |

> **Note on T4 & IW5 Configs:** Due to how these other games load configurations, your `.cfg` file for T4 and IW5 must be placed within your mounted **game files**, not the persistent data volume. 

## 🔌 Advanced: IW4MAdmin & RCON

Connecting a containerized IW4MAdmin to your Plutainer server requires special network configuration.

This guide applies to a specific scenario:
*   Your Plutainer game server is running in a container.
*   IW4MAdmin is running in a **separate container on the same host**, but on a **different Docker bridge network**.

Do **not** run IW4MAdmin from within the same bridge network as your Plutainer containers.
In this setup, when IW4MAdmin sends an RCON command, the game server sees the request as coming from its own network's **gateway IP**, not the IW4MAdmin container's IP.

**Solution: Whitelist the Gateway**

You must whitelist your Plutainer container's network gateway IP for RCON commands.

**Example:**
Consider this `docker-compose.yml` network configuration:
```yaml
networks:
  pluto-net:
    driver: bridge
    ipam:
      config:
        - subnet: 172.26.10.0/24
          gateway: 172.26.10.1 # <--- This is the gateway IP
```
If your game server is attached to `pluto-net`, you must add `"172.26.10.1"` to your server's `.cfg` RCON whitelist directive to grant IW4MAdmin access.

This issue does **not** occur if you are running IW4MAdmin directly on the host machine (bare-metal) or on an entirely different machine.

## 📚 Support?

Discord Support: https://discord.gg/PjrFw4tNES

Please note that I will not be supporting Plutonium-specific issues. There is an expectation that you're already familiar with Docker. If you're brand new, please visit https://docs.docker.com/get-started/

This Discord is to be specific to Plutainer and its setup and configuration (including IW4MAdmin).
