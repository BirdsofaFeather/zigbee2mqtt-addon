#!/bin/sh
set -e

# Read options passed as environment variables from HA add-on config
MQTT_SERVER="${MQTT_SERVER:-mqtt://core-mosquitto}"
MQTT_USER="${MQTT_USER:-}"
MQTT_PASSWORD="${MQTT_PASSWORD:-}"
SERIAL_PORT="${SERIAL_PORT:-/dev/ttyACM0}"

# Only write configuration.yaml on first run to avoid overwriting user changes
if [ ! -f /app/data/configuration.yaml ]; then
cat > /app/data/configuration.yaml <<EOF
mqtt:
  server: ${MQTT_SERVER}
  user: ${MQTT_USER}
  password: ${MQTT_PASSWORD}
serial:
  port: ${SERIAL_PORT}
frontend:
  port: 8080
EOF
fi

# Start Zigbee2MQTT
exec node /app/index.js
