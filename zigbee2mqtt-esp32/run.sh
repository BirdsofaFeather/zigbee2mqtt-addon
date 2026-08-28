#!/bin/sh
set -e

# Parse add-on options from HA's options.json using node (always available in this image)
OPTIONS=/data/options.json

MQTT_SERVER=$(node -e "process.stdout.write(require('$OPTIONS').mqtt_server || 'mqtt://core-mosquitto')")
MQTT_USER=$(node -e "process.stdout.write(require('$OPTIONS').mqtt_user || '')")
MQTT_PASSWORD=$(node -e "process.stdout.write(require('$OPTIONS').mqtt_password || '')")
SERIAL_PORT=$(node -e "process.stdout.write(require('$OPTIONS').serial_port || '/dev/ttyACM0')")
TRANSMIT_POWER=$(node -e "process.stdout.write(String(require('$OPTIONS').transmit_power ?? 20))")
ZIGBEE_CHANNEL=$(node -e "process.stdout.write(String(require('$OPTIONS').zigbee_channel ?? 11))")

# Only write configuration.yaml on first run to avoid overwriting user changes
if [ ! -f /config/configuration.yaml ]; then
cat > /config/configuration.yaml <<EOF
mqtt:
  server: ${MQTT_SERVER}
  user: ${MQTT_USER}
  password: ${MQTT_PASSWORD}
serial:
  port: ${SERIAL_PORT}
  adapter: zboss
advanced:
  transmit_power: ${TRANSMIT_POWER}
  channel: ${ZIGBEE_CHANNEL}
frontend:
  port: 8080
EOF
fi

exec node /app/index.js
