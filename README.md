# Zigbee2MQTT ESP32 Add-on

Custom Home Assistant add-on for the tostmann Zigbee2MQTT ESP32-C6 fork.

## Features

- Mirrors the official Zigbee2MQTT-style Options UI
  (`data_path`, `socat`, `mqtt`, `serial`)
- Generates `configuration.yaml` from the Options at each start
- Optionally starts `socat` when `socat.enabled: true`
- Wraps the upstream `ghcr.io/tostmann/zigbee2mqtt-esp32` image

## Repository structure

\```text
zigbee2mqtt-addon/
├── repository.yaml
├── README.md
└── zigbee2mqtt-esp32/
    ├── config.yaml
    ├── Dockerfile
    └── entrypoint.sh
\```

## Installation

1. In Home Assistant, go to **Settings → Add-ons → Add-on Store → ⋮ → Repositories**.
2. Add this repository's URL.
3. Install **Zigbee2MQTT ESP32** (Home Assistant builds the image locally from the Dockerfile).
4. Open the **Configuration** tab and set:
   - `mqtt.server`, `mqtt.user`, `mqtt.password`
   - `serial.port` (your `/dev/serial/by-id/...` path)
5. Start the add-on and open the Web UI.

## How configuration works

- Home Assistant stores your Options in `/data/options.json`.
- `entrypoint.sh` reads them on each start and writes `configuration.yaml` into `data_path`.
- Zigbee2MQTT reads `configuration.yaml` at startup from `/app/data`.

Editing Options in the UI and restarting regenerates `configuration.yaml`.

## Important notes

- The runtime data directory is `/app/data` (confirmed by the startup log
  `Using '/app/data' as data directory`). `data_path` defaults to `/app/data`
  so the UI and runtime agree.
- `mqtt.password` uses the `password` schema type so it renders as a masked field.
- `serial.adapter` is free-text for maximum compatibility.
- When `socat.enabled: true`:
  - A PTY is created at `/tmp/ttyZ2M` (master).
  - A TCP listener runs on port `8485` (slave) for the remote coordinator.
  - Zigbee2MQTT uses `serial.port: /tmp/ttyZ2M`.
