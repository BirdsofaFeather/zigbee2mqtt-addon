FROM ghcr.io/tostmann/zigbee2mqtt-esp32:latest

# Install jq (parse options) and socat (serial-over-TCP bridge).
# Handles both Alpine (apk) and Debian (apt-get) base images.
RUN \
  (apk add --no-cache jq socat 2>/dev/null) \
  || (apt-get update && apt-get install -y jq socat && rm -rf /var/lib/apt/lists/*)

# Hint to Tini to act as a subreaper (silences the PID 1 warning)
ENV TINI_SUBREAPER=1

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
