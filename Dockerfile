# HA Docker

# docker build . -t homeassistant
# docker run -it -p 8123:8123  homeassistant
# docker run --name ha -p 8123:8123  -v $(pwd)/config:/config -d homeassistant

# amd64 raspberrypi4 raspberrypi3 armhf
ARG ARCH=armhf
ARG VERSION=stable
FROM "homeassistant/${ARCH}-homeassistant:${VERSION}"

ARG MYVERSION=jose0
ARG CONFIGDIR=/config
ARG PORT=8123
ARG TZ=Europe/Amsterdam
ARG UID=1000
ARG GUID=1000

LABEL org.label-schema.docker.schema-version="1.0"
LABEL org.label-schema.vendor="Jose Riguera"
LABEL org.label-schema.description="Home Assistant image based on alpine for the Raspberry Pi."
LABEL org.label-schema.name="rpi-homeassistant"
LABEL org.label-schema.version="${VERSION}-${MYVERSION}"
LABEL org.label-schema.usage="/README.md"
LABEL org.label-schema.url="https://hub.docker.com/r/jriguera/rpi-homeassistant"
LABEL org.label-schema.vcs-url="https://github.com/jriguera/docker-rpi-homeassistant"
LABEL maintainer="Jose Riguera <jriguera@gmail.com>"
LABEL architecture="${ARCH}"

ENV LANG="C.UTF-8"
ENV LC_ALL=C.UTF-8

RUN set -xe                                                                 && \
    # Create user hass
    addgroup -g "${GUID}" hass                                              && \
    adduser -h "${CONFIGDIR}" -D -G hass -s /bin/bash -u "${UID}" hass      && \
    # Timezone
    cp "/usr/share/zoneinfo/${TZ}" /etc/localtime                           && \
    echo "${TZ}" > /etc/timezone                                            && \
    # Installing Alpine packages
    # apk -U upgrade
    apk add --no-cache \
        tzdata \
        bash \
        su-exec \
        ca-certificates \
        openssh-client \
        mosquitto-clients \
        mariadb-client \
        pwgen \
        fping \
        jq \
        curl \
                                                                            && \
    # clean up
    rm -rf /tmp/* /var/tmp/* /var/cache/apk/* /var/cache/distfiles/* ~/.cache

COPY docker/*.sh /usr/local/bin/
RUN set -xe                                                                 && \
    chmod a+x /usr/local/bin/*                                              && \
    ln -s /usr/local/bin/hass.sh /usr/local/bin/docker-entrypoint.sh        && \
    ln -s /usr/local/bin/hass.sh /docker-entrypoint.sh                      && \
    ln -s /usr/local/bin/hass.sh /run.sh                                    && \
    ln -s /usr/local/bin/healthcheck.sh /healthcheck.sh                     && \
    mkdir -p /docker-entrypoint-initdb.d

ENV PORT="${PORT}"
ENV CONFIGDIR="${CONFIGDIR}"

WORKDIR ${CONFIGDIR}
VOLUME "${CONFIGDIR}"
EXPOSE "${PORT}"

HEALTHCHECK --interval=30s --timeout=10s --start-period=3m \
    CMD /healthcheck.sh

ENTRYPOINT ["/run.sh"]

# Define default command
CMD ["--log-no-color"]
