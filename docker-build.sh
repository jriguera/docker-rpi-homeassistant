#!/usr/bin/env bash
set -euf -o pipefail

DOCKER=docker
NAME="homeassistant"
VERSION=$(cd "$(dirname "${BASH_SOURCE[0]}")/home-assistant" && git describe --tags | head -n1)
ARCH=""

case "$(uname -m)" in
    armv7l)
        ARCH='arm32v6'
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
    --build-arg VERSION=${VERSION} \
    --build-arg ARCH=${ARCH} \
    --build-arg TZ=$(timedatectl  | awk '/Time zone:/{ print $3 }') \
    .  -t $NAME
