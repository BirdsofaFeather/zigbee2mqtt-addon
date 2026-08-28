ARG BUILD_FROM
FROM ghcr.io/tostmann/zigbee2mqtt-esp32:latest

COPY run.sh /run.sh
RUN chmod a+x /run.sh

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD [ "/sbin/tini", "--", "/bin/sh", "/run.sh" ]
