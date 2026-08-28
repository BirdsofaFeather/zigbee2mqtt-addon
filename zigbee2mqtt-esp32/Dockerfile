ARG BUILD_FROM
FROM ghcr.io/tostmann/zigbee2mqtt-esp32:latest

COPY run.sh /
RUN chmod a+x /run.sh

CMD [ "/run.sh" ]
