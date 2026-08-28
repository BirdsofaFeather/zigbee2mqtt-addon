#!/bin/sh
set -e

OPTIONS_FILE=/data/options.json

if [ ! -f "$OPTIONS_FILE" ]; then
  echo "ERROR: $OPTIONS_FILE not found; cannot read add-on options."
  exit 1
fi

# Read a value from options.json, returning empty string if null/missing
get_opt() {
  jq -r "$1 // \"\"" "$OPTIONS_FILE"
}

# ---------- data_path ----------
DATA_PATH=$(get_opt '.data_path')
[ -z "$DATA_PATH" ] && DATA_PATH="/app/data"

# ---------- socat ----------
SOCAT_ENABLED=$(get_opt '.socat.enabled')
SOCAT_MASTER=$(get_opt '.socat.master')
SOCAT_SLAVE=$(get_opt '.socat.slave')
SOCAT_OPTIONS=$(get_opt '.socat.options')
SOCAT_LOG=$(get_opt '.socat.log')

# ---------- mqtt ----------
MQTT_SERVER=$(get_opt '.mqtt.server')
MQTT_CA=$(get_opt '.mqtt.ca')
MQTT_KEY=$(get_opt '.mqtt.key')
MQTT_CERT=$(get_opt '.mqtt.cert')
MQTT_USER=$(get_opt '.mqtt.user')
MQTT_PASSWORD=$(get_opt '.mqtt.password')
MQTT_BASE_TOPIC=$(get_opt '.mqtt.base_topic')
[ -z "$MQTT_BASE_TOPIC" ] && MQTT_BASE_TOPIC="zigbee2mqtt"

# ---------- serial ----------
SERIAL_PORT=$(get_opt '.serial.port')
SERIAL_ADAPTER=$(get_opt '.serial.adapter')
SERIAL_BAUDRATE=$(get_opt '.serial.baudrate')
SERIAL_RTSCTS=$(get_opt '.serial.rtscts')

mkdir -p "$DATA_PATH"
CONFIG_FILE="$DATA_PATH/configuration.yaml"

echo "Generating $CONFIG_FILE from add-on options..."
echo "Using data_path: $DATA_PATH"

# ---------- Render configuration.yaml ----------
{
  echo "homeassistant: true"
  echo "mqtt:"
  echo "  base_topic: ${MQTT_BASE_TOPIC}"
  echo "  server: ${MQTT_SERVER}"
  [ -n "$MQTT_CA" ]       && echo "  ca: ${MQTT_CA}"
  [ -n "$MQTT_KEY" ]      && echo "  key: ${MQTT_KEY}"
  [ -n "$MQTT_CERT" ]     && echo "  cert: ${MQTT_CERT}"
  [ -n "$MQTT_USER" ]     && echo "  user: ${MQTT_USER}"
  [ -n "$MQTT_PASSWORD" ] && echo "  password: ${MQTT_PASSWORD}"

  echo "serial:"
  if [ "$SOCAT_ENABLED" = "true" ]; then
    # With socat, Zigbee2MQTT reads from the PTY linked by master (/tmp/ttyZ2M),
    # NOT the TCP side. The TCP listener (:8485) is for the remote coordinator.
    echo "  port: /tmp/ttyZ2M"
  else
    echo "  port: ${SERIAL_PORT}"
  fi
  [ -n "$SERIAL_ADAPTER" ]  && echo "  adapter: ${SERIAL_ADAPTER}"
  [ -n "$SERIAL_BAUDRATE" ] && echo "  baudrate: ${SERIAL_BAUDRATE}"
  [ -n "$SERIAL_RTSCTS" ]   && echo "  rtscts: ${SERIAL_RTSCTS}"

  echo "frontend:"
  echo "  enabled: true"
  echo "  port: 8080"

  echo "advanced:"
  echo "  channel: 25"
} > "$CONFIG_FILE"

# ---------- Start socat if enabled ----------
if [ "$SOCAT_ENABLED" = "true" ]; then
  echo "socat enabled — starting serial-over-TCP bridge..."
  SOCAT_ARGS="$SOCAT_OPTIONS"
  [ "$SOCAT_LOG" = "true" ] && SOCAT_ARGS="$SOCAT_ARGS -v"

  # Master: PTY at /tmp/ttyZ2M, Slave: TCP listener on 8485
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
