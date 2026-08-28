#!/bin/sh
set -e

OPTIONS_FILE="/data/options.json"

if [ ! -f "$OPTIONS_FILE" ]; then
  echo "ERROR: $OPTIONS_FILE not found; cannot read add-on options."
  exit 1
fi

# Read a value; returns empty string for null/missing/blank
get_opt() {
  value="$(jq -r "$1 // empty" "$OPTIONS_FILE" 2>/dev/null || true)"
  value="$(printf '%s' "$value" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
  [ "$value" = "null" ] && value=""
  printf '%s' "$value"
}

# ---------- Read options ----------
DATA_PATH="$(get_opt '.data_path')"
[ -z "$DATA_PATH" ] && DATA_PATH="/app/data"

MQTT_SERVER="$(get_opt '.mqtt_server')"
MQTT_USER="$(get_opt '.mqtt_user')"
MQTT_PASSWORD="$(get_opt '.mqtt_password')"

SERIAL_PORT="$(get_opt '.serial_port')"
SERIAL_ADAPTER="$(get_opt '.serial_adapter')"
[ -z "$SERIAL_ADAPTER" ] && SERIAL_ADAPTER="zboss"

HOMEASSISTANT="$(get_opt '.homeassistant')"
[ -z "$HOMEASSISTANT" ] && HOMEASSISTANT="true"

PERMIT_JOIN="$(get_opt '.permit_join')"
[ -z "$PERMIT_JOIN" ] && PERMIT_JOIN="false"

mkdir -p "$DATA_PATH"
CONFIG_FILE="${DATA_PATH}/configuration.yaml"

echo "Generating ${CONFIG_FILE} from add-on options..."
echo "Using data_path: ${DATA_PATH}"

# ---------- Render a minimal configuration.yaml ----------
{
  echo "homeassistant: ${HOMEASSISTANT}"
  echo "permit_join: ${PERMIT_JOIN}"

  echo "mqtt:"
  echo "  server: ${MQTT_SERVER}"
  [ -n "$MQTT_USER" ]     && echo "  user: ${MQTT_USER}"
  [ -n "$MQTT_PASSWORD" ] && echo "  password: ${MQTT_PASSWORD}"

  echo "serial:"
  echo "  port: ${SERIAL_PORT}"
  echo "  adapter: ${SERIAL_ADAPTER}"

  echo "frontend:"
  echo "  enabled: true"
  echo "  port: 8080"
} > "$CONFIG_FILE"

echo "Generated Zigbee2MQTT configuration:"
cat "$CONFIG_FILE"

# ---------- Hand off to Zigbee2MQTT ----------
if [ -x /docker-entrypoint.sh ]; then
  exec /docker-entrypoint.sh "$@"
fi

exec "$@"
