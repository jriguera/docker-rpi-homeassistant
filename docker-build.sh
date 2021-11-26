#!/usr/bin/env bash
set -euf -o pipefail

DOCKER=docker
NAME="homeassistant"
VERSION=$(cd "$(dirname "${BASH_SOURCE[0]}")/home-assistant-core" && git describe --tags | head -n1)
ARCH=""

case "$(uname -m)" in
    armv7l)
        ARCH=armhf
        if [ -r /proc/device-tree/model ]
        then
            ARCH='raspberrypi'
            ARCH=${ARCH}$(awk '{ print $3 }' /proc/device-tree/model)
        fi
    ;;
    x86_64|amd64)
        ARCH='amd64'
    ;;
    *)
        echo "ERROR: unsupported architecture: $(uname -m)"
        exit 1
    ;;
esac

exec $DOCKER build \
    --squash \
    --build-arg VERSION=${VERSION} \
    --build-arg ARCH=${ARCH} \
    --build-arg TZ=$(timedatectl  | awk '/Time zone:/{ print $3 }') \
    .  -t $NAME

