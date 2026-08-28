#!/usr/bin/with-contenv bashio

# Read options from HA add-on config
MQTT_SERVER=$(bashio::config 'mqtt_server')
MQTT_USER=$(bashio::config 'mqtt_user')
MQTT_PASSWORD=$(bashio::config 'mqtt_password')
SERIAL_PORT=$(bashio::config 'serial_port')

# Generate configuration.yaml for Zigbee2MQTT
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

# Start Zigbee2MQTT
exec node index.js
