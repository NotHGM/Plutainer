#!/bin/bash
#
# This script checks the server's health by determining the correct port and
# then sending an RCON "status" command.
#

# --- Step 1: Check if health checks are explicitly disabled ---
if [[ "${PLUTO_HEALTHCHECK}" == "false" ]]; then
  echo "Health check is disabled by environment variable."
  exit 0
fi

set -e

# --- Step 2: Validate that required variables are set ---
if [[ -z "${PLUTO_GAME}" || -z "${PLUTO_CONFIG_FILE}" ]]; then
  echo "Health check failed: Required env vars are missing: PLUTO_GAME, PLUTO_CONFIG_FILE" >&2
  exit 1
fi

# --- Step 3: Determine the correct port to check ---
BASE_GAME=${PLUTO_GAME%??}
HEALTHCHECK_PORT=${PLUTO_PORT}
if [[ -z "${HEALTHCHECK_PORT}" ]]; then
  case "${BASE_GAME}" in
    "iw5")      HEALTHCHECK_PORT="27016" ;;
    "t4" | "t5") HEALTHCHECK_PORT="28960" ;;
    "t6")       HEALTHCHECK_PORT="4976"  ;;
    *)
      echo "Health check failed: Could not determine default port for game '${PLUTO_GAME}'." >&2
      exit 1
      ;;
  esac
fi

# --- Step 4: Determine the game-specific config file path ---
case "${BASE_GAME}" in
  "t4")
    CONFIG_PATH="/home/plutouser/gamefiles/main/${PLUTO_CONFIG_FILE}"
    ;;
  "iw5")
    CONFIG_PATH="/home/plutouser/gamefiles/admin/${PLUTO_CONFIG_FILE}"
    ;;
  *)
    CONFIG_PATH="/home/plutouser/plutonium/storage/${BASE_GAME}/${PLUTO_CONFIG_FILE}"
    ;;
esac

if [[ ! -f "${CONFIG_PATH}" ]]; then
  echo "Health check failed: Config file not found at ${CONFIG_PATH}" >&2
  exit 1
fi

# --- Step 5: Extract RCON password from config ---
RCON_PASSWORD=$(grep -v '^[[:space:]]*//' "${CONFIG_PATH}" | grep -i 'rcon_password' | sed -n 's/.*"\([^"]*\)".*/\1/p' | tail -1)

if [[ -z "${RCON_PASSWORD}" ]]; then
  echo "Health check failed: Could not find 'rcon_password' in ${CONFIG_PATH}" >&2
  exit 1
fi

# --- Step 6: Query the server ---
RESPONSE=$(python3 -c "
import sys
import pyquake3

try:
    port = '${HEALTHCHECK_PORT}'
    password = '${RCON_PASSWORD}'
    server = pyquake3.PyQuake3(f'127.0.0.1:{port}', rcon_password=password)
    print(server.rcon('status'))
except Exception as e:
    print(f'RCON connection failed: {e}', file=sys.stderr)
    sys.exit(1)
")

# --- Step 7: Validate the server's response ---
if echo "${RESPONSE}" | grep -q "map:"; then
  echo "Health check passed: Server is responsive on port ${HEALTHCHECK_PORT}."
  exit 0
else
  echo "Health check failed: Server response did not contain 'map:'" >&2
  echo "Received: ${RESPONSE}" >&2
  exit 1
fi