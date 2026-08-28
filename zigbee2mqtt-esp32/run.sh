#!/bin/sh
set -e

# Parse add-on options from HA's options.json using node (always available in this image)
OPTIONS=/data/options.json

MQTT_SERVER=$(node -e "process.stdout.write(require('$OPTIONS').mqtt_server || 'mqtt://core-mosquitto')")
MQTT_USER=$(node -e "process.stdout.write(require('$OPTIONS').mqtt_user || '')")
MQTT_PASSWORD=$(node -e "process.stdout.write(require('$OPTIONS').mqtt_password || '')")
SERIAL_PORT=$(node -e "process.stdout.write(require('$OPTIONS').serial_port || '/dev/ttyACM0')")

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
frontend:
  port: 8080
EOF
fi

exec node /app/index.js
