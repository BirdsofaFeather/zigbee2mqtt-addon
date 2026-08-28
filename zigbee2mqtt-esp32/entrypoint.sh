#!/bin/sh
set -e

OPTIONS_FILE="/data/options.json"
CONFIG_DIR="/app/data"
CONFIG_FILE="${CONFIG_DIR}/configuration.yaml"

if [ ! -f "$OPTIONS_FILE" ]; then
  echo "ERROR: $OPTIONS_FILE not found; cannot read add-on options."
  exit 1
fi

mkdir -p "$CONFIG_DIR"

# Read a value from options.json.
# Returns empty string if the key is missing, null, or blank.
get_opt() {
  value="$(jq -r "$1 // empty" "$OPTIONS_FILE" 2>/dev/null || true)"
  value="$(printf '%s' "$value" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
  [ "$value" = "null" ] && value=""
  printf '%s' "$value"
}

# Escapes backslashes and double quotes for safe YAML values.
yaml_escape() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

# ---------- data_path ----------
DATA_PATH="$(get_opt '.data_path')"
[ -z "$DATA_PATH" ] && DATA_PATH="/app/data"
CONFIG_FILE="${DATA_PATH}/configuration.yaml"
mkdir -p "$DATA_PATH"

# ---------- socat ----------
SOCAT_ENABLED="$(get_opt '.socat.enabled')"
SOCAT_MASTER="$(get_opt '.socat.master')"
SOCAT_SLAVE="$(get_opt '.socat.slave')"
SOCAT_OPTIONS="$(get_opt '.socat.options')"
SOCAT_LOG="$(get_opt '.socat.log')"

# ---------- mqtt ----------
MQTT_SERVER="$(get_opt '.mqtt.server')"
MQTT_USER="$(get_opt '.mqtt.user')"
MQTT_PASSWORD="$(get_opt '.mqtt.password')"
MQTT_CA="$(get_opt '.mqtt.ca')"
MQTT_KEY="$(get_opt '.mqtt.key')"
MQTT_CERT="$(get_opt '.mqtt.cert')"
MQTT_BASE_TOPIC="$(get_opt '.mqtt.base_topic')"
[ -z "$MQTT_BASE_TOPIC" ] && MQTT_BASE_TOPIC="zigbee2mqtt"

# ---------- serial ----------
SERIAL_PORT="$(get_opt '.serial.port')"
SERIAL_ADAPTER="$(get_opt '.serial.adapter')"
SERIAL_BAUDRATE="$(get_opt '.serial.baudrate')"
SERIAL_RTSCTS="$(get_opt '.serial.rtscts')"

echo "Generating ${CONFIG_FILE} from add-on options..."
echo "Using data_path: ${DATA_PATH}"

# ---------- Render configuration.yaml ----------
{
  echo "homeassistant: true"

  echo "mqtt:"
  echo "  base_topic: $(yaml_escape "$MQTT_BASE_TOPIC")"
  echo "  server: $(yaml_escape "$MQTT_SERVER")"

  # Optional auth — only emit when set
  [ -n "$MQTT_USER" ]     && echo "  user: $(yaml_escape "$MQTT_USER")"
  [ -n "$MQTT_PASSWORD" ] && echo "  password: $(yaml_escape "$MQTT_PASSWORD")"

  # Optional TLS — only emit when actually configured (never blank)
  [ -n "$MQTT_CA" ]   && echo "  ca: $(yaml_escape "$MQTT_CA")"
  [ -n "$MQTT_KEY" ]  && echo "  key: $(yaml_escape "$MQTT_KEY")"
  [ -n "$MQTT_CERT" ] && echo "  cert: $(yaml_escape "$MQTT_CERT")"

  echo "serial:"
  if [ "$SOCAT_ENABLED" = "true" ]; then
    # With socat, Zigbee2MQTT reads the PTY link (/tmp/ttyZ2M), not the TCP side.
    echo "  port: /tmp/ttyZ2M"
  else
    echo "  port: $(yaml_escape "$SERIAL_PORT")"
  fi
  [ -n "$SERIAL_ADAPTER" ]  && echo "  adapter: $(yaml_escape "$SERIAL_ADAPTER")"
  [ -n "$SERIAL_BAUDRATE" ] && echo "  baudrate: ${SERIAL_BAUDRATE}"
  [ -n "$SERIAL_RTSCTS" ]   && echo "  rtscts: ${SERIAL_RTSCTS}"

  echo "frontend:"
  echo "  enabled: true"
  echo "  port: 8080"
} > "$CONFIG_FILE"

echo "Generated ${CONFIG_FILE}:"
cat "$CONFIG_FILE"

# ---------- Start socat if enabled ----------
if [ "$SOCAT_ENABLED" = "true" ]; then
  echo "socat enabled — starting serial-over-TCP bridge..."
  SOCAT_ARGS="$SOCAT_OPTIONS"
  [ "$SOCAT_LOG" = "true" ] && SOCAT_ARGS="$SOCAT_ARGS -v"
  socat $SOCAT_ARGS "$SOCAT_MASTER" "$SOCAT_SLAVE" &
  SOCAT_PID=$!
  echo "socat started with PID $SOCAT_PID"
  sleep 2
fi

# ---------- Hand off to Zigbee2MQTT ----------
if [ -x /docker-entrypoint.sh ]; then
  exec /docker-entrypoint.sh "$@"
fi

exec "$@"
