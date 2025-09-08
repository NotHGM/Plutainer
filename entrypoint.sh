#!/bin/bash
#
# This entrypoint script is responsible for validating the container's
# environment, setting sensible defaults, and launching the specified
# Plutonium game server.
#

#
# --- Branding ---
#
cat << "EOF"
 ____  _       _        _                 
|  _ \| |_   _| |_ __ _(_)_ __   ___ _ __ 
| |_) | | | | | __/ _` | | '_ \ / _ \ '__|
|  __/| | |_| | || (_| | | | | |  __/ |   
|_|   |_|\__,_|\__\__,_|_|_| |_|\___|_|   
                                          
EOF

echo
echo "Brought to you by Ayymoss"
echo

# --- Step 1: Update Plutonium Files ---
PLUTO_CDN_INFO_LOC="/home/plutouser/plutonium/cdn_info.json"
if [[ ! -f "${PLUTO_CDN_INFO_LOC}" ]]; then
  echo "First container run detected. Downloading Plutonium initial files... This may take a few minutes."
  /home/plutouser/plutonium-updater
else
  if [[ "${PLUTO_AUTO_UPDATE}" == "false" ]]; then
    echo "Skipping Plutonium update because PLUTO_AUTO_UPDATE is set to 'false'."
  else
    echo "Checking for Plutonium updates... This may take a few minutes if an update is available."
    /home/plutouser/plutonium-updater
  fi
fi

cd /home/plutouser/plutonium

# --- Step 2: Validate Required Environment Variables ---
MISSING_VAR=false
INVALID_VAR=false
VALID_GAMES="iw5mp t4mp t4sp t5mp t5sp t6mp t6zm"
BASE_GAME=${PLUTO_GAME%??}
PLUTO_SERVER_NAME=${PLUTO_SERVER_NAME:-"Plutonium Docker Server"}

if [[ -z "${PLUTO_GAME}" ]]; then
  echo "ERROR: The 'PLUTO_GAME' environment variable is not set." >&2
  MISSING_VAR=true
elif [[ ! " ${VALID_GAMES} " =~ " ${PLUTO_GAME} " ]]; then
  echo "ERROR: Invalid value for 'PLUTO_GAME': \"${PLUTO_GAME}\"." >&2
  INVALID_VAR=true
fi

if [[ -z "${PLUTO_SERVER_KEY}" ]]; then
  echo "ERROR: The 'PLUTO_SERVER_KEY' environment variable is not set." >&2
  echo "  > You must provide a server key from https://platform.plutonium.pw/serverkeys" >&2
  MISSING_VAR=true
fi

if [[ -z "${PLUTO_CONFIG_FILE}" ]]; then
  echo "ERROR: The 'PLUTO_CONFIG_FILE' environment variable is not set." >&2
  echo "  > You must specify the name of the server configuration file (e.g., 'dedicated.cfg')." >&2
  MISSING_VAR=true
fi

if [[ "$MISSING_VAR" == "true" || "$INVALID_VAR" == "true" ]]; then
  echo "-------------------------------------------------" >&2
  if [[ "$INVALID_VAR" == "true" ]]; then
      echo "An invalid value was provided. Valid game modes are: ${VALID_GAMES}" >&2
  fi
  echo "One or more configuration errors found. Halting startup." >&2
  echo "Exiting in 10 seconds..." >&2
  sleep 10
  exit 1
fi

# --- Step 3: Set Game-Aware Default Port (If Needed) ---
if [[ -z "${PLUTO_PORT}" ]]; then
  echo "Optional PLUTO_PORT is not set, determining default port for ${BASE_GAME}..."
  case "${BASE_GAME}" in
    "iw5")
      PLUTO_PORT="27016"
      ;;
    "t4" | "t5")
      PLUTO_PORT="28960"
      ;;
    "t6")
      PLUTO_PORT="4976"
      ;;
    *)
      echo "ERROR: Could not determine a default port for game '${PLUTO_GAME}'." >&2
	  sleep 10
      exit 1
      ;;
  esac
  echo "Default port set to ${PLUTO_PORT}"
fi

# --- Step 4: Build Server Command Arguments ---
declare -a CMD_ARGS=(
    "${PLUTO_GAME}"
    /home/plutouser/gamefiles
    -dedicated
    +set key "${PLUTO_SERVER_KEY}"
    +set net_port "${PLUTO_PORT}"
)

if [[ "${BASE_GAME}" == "iw5" ]]; then
    CMD_ARGS+=(+set sv_config "${PLUTO_CONFIG_FILE}")
else
    CMD_ARGS+=(+exec "${PLUTO_CONFIG_FILE}")
fi

if [[ -n "${PLUTO_MOD}" ]]; then
    CMD_ARGS+=(+set fs_game "${PLUTO_MOD}")
fi
if [[ -n "${PLUTO_MAX_CLIENTS}" ]]; then
    CMD_ARGS+=(+set sv_maxclients "${PLUTO_MAX_CLIENTS}")
fi

if [[ "${BASE_GAME}" == "iw5" ]]; then
    CMD_ARGS+=(+start_map_rotate)
else
    CMD_ARGS+=(+map_rotate)
fi

# --- Step 5: Launch the Plutonium Server ---
echo "Starting Plutonium ${PLUTO_GAME} Server: ${PLUTO_SERVER_NAME}"
echo "EXECUTING: wine bin/plutonium-bootstrapper-win32.exe ${CMD_ARGS[@]}"
exec wine bin/plutonium-bootstrapper-win32.exe "${CMD_ARGS[@]}"
