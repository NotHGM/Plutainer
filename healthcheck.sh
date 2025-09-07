#!/bin/bash
#
# This script checks the server's health by determining the correct port and
# then sending an RCON "status" command.
#
# It is intentionally verbose to aid in manual debugging and to provide
# context in Docker's healthcheck logs.
#

# --- Step 1: Check if health checks are explicitly disabled ---
if [[ "${PLUTO_HEALTHCHECK}" == "false" ]]; then
  echo "[INFO] Health check is disabled by environment variable."
  exit 0
fi

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Step 2: Validate that required variables are set ---
echo "[INFO] Validating required environment variables..."
if [[ -z "${PLUTO_GAME}" || -z "${PLUTO_CONFIG_FILE}" ]]; then
  echo "[FAIL] Health check failed: Required env vars are missing: PLUTO_GAME, PLUTO_CONFIG_FILE" >&2
  exit 1
fi
echo "       - PLUTO_GAME='${PLUTO_GAME}'"
echo "       - PLUTO_CONFIG_FILE='${PLUTO_CONFIG_FILE}'"


# --- Step 3: Determine the correct port to check ---
echo "[INFO] Determining server port..."
BASE_GAME=${PLUTO_GAME%??}
HEALTHCHECK_PORT=${PLUTO_PORT}

if [[ -z "${HEALTHCHECK_PORT}" ]]; then
  echo "       - PLUTO_PORT is not set, determining default for game '${BASE_GAME}'..."
  case "${BASE_GAME}" in
    "iw5")      HEALTHCHECK_PORT="27016" ;;
    "t4" | "t5") HEALTHCHECK_PORT="28960" ;;
    "t6")       HEALTHCHECK_PORT="4976"  ;;
    *)
      echo "[FAIL] Health check failed: Could not determine default port for game '${PLUTO_GAME}'." >&2
      exit 1
      ;;
  esac
  echo "       - Default port set to ${HEALTHCHECK_PORT}."
else
  echo "       - Using custom port from PLUTO_PORT: ${HEALTHCHECK_PORT}."
fi


# --- Step 4: Determine the game-specific config file path ---
echo "[INFO] Determining configuration file path..."
case "${BASE_GAME}" in
  "t4")
    CONFIG_PATH="/home/plutouser/gamefiles/main/${PLUTO_CONFIG_FILE}"
    ;;
  "iw5")
    CONFIG_PATH="/home/plutouser/gamefiles/admin/${PLUTO_CONFIG_FILE}"
    ;;
  *)
    CONFIG_PATH="/home/plutonium/storage/${BASE_GAME}/${PLUTO_CONFIG_FILE}"
    ;;
esac
echo "       - Expecting config file at: ${CONFIG_PATH}"

if [[ ! -f "${CONFIG_PATH}" ]]; then
  echo "[FAIL] Health check failed: Config file not found at ${CONFIG_PATH}" >&2
  exit 1
fi


# --- Step 5: Extract RCON password from config ---
echo "[INFO] Extracting RCON password from config..."
RCON_PASSWORD=$(grep -v '^[[:space:]]*//' "${CONFIG_PATH}" | grep -i 'rcon_password' | sed -n 's/.*"\([^"]*\)".*/\1/p' | tail -1)

if [[ -z "${RCON_PASSWORD}" ]]; then
  echo "[FAIL] Health check failed: Could not find 'rcon_password' in ${CONFIG_PATH}" >&2
  exit 1
fi
echo "       - RCON password extracted successfully."


# --- Step 6: Query the server ---
echo "[INFO] Querying server at 127.0.0.1:${HEALTHCHECK_PORT}..."
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
echo "[INFO] Validating server response..."
if echo "${RESPONSE}" | grep -q "map:"; then
  echo "[OK] Health check passed: Server is responsive on port ${HEALTHCHECK_PORT}."
  exit 0
else
  echo "[FAIL] Health check failed: Server response did not contain 'map:'" >&2
  echo "[FAIL] Received: ${RESPONSE}" >&2
  exit 1
fi
