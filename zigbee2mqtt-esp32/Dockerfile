ARG BUILD_FROM
FROM ghcr.io/tostmann/zigbee2mqtt-esp32:latest

ENV TINI_SUBREAPER=1

COPY run.sh /
RUN chmod a+x /run.sh

CMD [ "/run.sh" ]
