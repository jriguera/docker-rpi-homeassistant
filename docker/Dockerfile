FROM arm32v6/alpine:3.8

# docker build . -t homeassistant
# docker run -it -p 8123:8123  homeassistant
# docker run --name ha -p 8123:8123  -v $(pwd)/config:/config -d homeassistant

LABEL org.label-schema.description="Home Assistant image based on alpine for the Raspberry Pi."
LABEL org.label-schema.name="rpi-homeassistant"
LABEL org.label-schema.version="1.0"
LABEL org.label-schema.usage="/README.md"
LABEL org.label-schema.url="https://hub.docker.com/r/jriguera/rpi-homeassistant"
LABEL org.label-schema.vcs-url="https://github.com/jriguera/docker-rpi-homeassistant"
LABEL maintainer="Jose Riguera <jriguera@gmail.com>"
LABEL architecture="ARM32v7/armhf"

ARG VERSION=0.74.2
ARG CONFIGDIR=/config
ARG PORT=8123
ARG UID=1000
ARG GUID=1000
ARG TIMEZONE=Europe/Amsterdam

ENV HA_PORT="${PORT}"
ENV HA_CONFIG="${CONFIGDIR}"
ENV LANG=en_US.utf8
ENV LC_ALL=C.UTF-8
ENV ARCH=arm
ENV CROSS_COMPILE=/usr/bin/

RUN set -xe                                                                 && \
    apk -U upgrade                                                          && \
    # Installing Alpine packages
    apk add --no-cache \
        fping \
        python3 \
        tzdata \
        bash \
        ca-certificates \
        curl \
        libpq \
        net-tools \
        nmap \
        openssh-client \
        libxrandr \
        ffmpeg \
        yaml \
        bluez\
        glib \
        libsodium \
        jq \
        mariadb-client \
        mosquitto-clients \
        libxml2 \
        libgcrypt \
        libxslt \
        mpfr3 \
        mpc1 \
        bluez-libs \
        eudev-libs \
        iperf3 \
                                                                            && \
    # Timezone
    cp "/usr/share/zoneinfo/${TIMEZONE}" /etc/localtime                     && \
    echo "${TIMEZONE}" > /etc/timezone                                      && \
    # clean up
    rm -rf /tmp/* /var/tmp/* /var/cache/apk/* /var/cache/distfiles/* ~/.cache


WORKDIR ${CONFIGDIR}
COPY requirements.txt requirements.txt
RUN set -xe                                                                 && \
    addgroup -g "${GUID}" hass                                              && \
    adduser -h "${CONFIGDIR}" -D -G hass -s /bin/bash -u "${UID}" hass      && \
    # Building Python3 deps
    apk add --no-cache --virtual .build-deps \
        python3-dev \
        freetype-dev \
        g++ \
        gcc \
        make \
        autoconf \
        jpeg-dev \
        libffi-dev \
        libjpeg-turbo-dev \
        libpng-dev \
        zlib-dev \
        curl-dev \
        bluez-dev \
        libxrandr-dev \
        libxml2-dev \
        libxslt-dev \
        linux-headers \
        libsodium-dev \
        mariadb-dev \
        eudev-dev \
                                                                            && \
    # Configuring Python packages
    pip3 install --no-cache-dir --upgrade pip setuptools                    && \
    pip3 install --no-cache-dir --upgrade mysqlclient                       && \
    pip3 install --no-cache-dir --upgrade wheel uvloop cchardet cython      && \
    pip3 install --no-cache-dir homeassistant=="${VERSION}"                 && \
    pip3 install --no-cache-dir -r requirements.txt                         && \
    # clean up
    apk del .build-deps                                                     && \
    rm -rf /tmp/* /var/tmp/* /var/cache/apk/* /var/cache/distfiles/* ~/.cache


COPY *.sh /usr/local/bin/
RUN set -xe                                                                 && \
    chmod a+x /usr/local/bin/*                                              && \
    ln -s /usr/local/bin/hass.sh /usr/local/bin/docker-entrypoint.sh        && \
    ln -s /usr/local/bin/hass.sh /docker-entrypoint.sh                      && \
    ln -s /usr/local/bin/hass.sh /run.sh                                    && \
    mkdir -p /docker-entrypoint-initdb.d


VOLUME "${CONFIGDIR}"
EXPOSE "${PORT}"

ENTRYPOINT ["/run.sh"]

# Define default command
CMD ["--log-no-color"]
