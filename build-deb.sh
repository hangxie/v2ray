#!/bin/bash

set -euo pipefail

VERSION=$(curl -s https://api.github.com/repos/v2fly/v2ray-core/releases/latest | jq -r .name)

function build() {
    PKG_ARCH=$1

    case ${PKG_ARCH} in
        amd64)
            BIN_ARCH=amd64
            ZIP=v2ray-linux-64.zip \
            ;;
        arm64)
            BIN_ARCH=arm64
            ZIP=v2ray-linux-arm64-v8a.zip \
            ;;
        *)
            echo package for architecture ${PKG_ARCH} is not currently supported
            exit 0
            ;;
    esac

    DEB_VER=$(echo ${VERSION} | cut -f 1 -d \- | tr -d 'a-z')
    PKG_NAME=v2ray
    DOCKER_NAME=deb-build-${BIN_ARCH}

    # Launch build container
    docker ps -a | grep ${DOCKER_NAME} && docker rm -f ${DOCKER_NAME}
    docker run -di --rm --name ${DOCKER_NAME} debian:12-slim

    # CCI does not support volume mount, so use docker cp instead
    docker cp ./deb ${DOCKER_NAME}:/tmp/
    docker cp ./config.json ${DOCKER_NAME}:/tmp/
    docker cp ./v2ray.service ${DOCKER_NAME}:/tmp/

    # Build deb
    docker exec -t ${DOCKER_NAME} bash -c "
        set -euo pipefail;
        export DEBIAN_FRONTEND=noninteractive;
        apt-get update;
        apt-get install -y curl zip;
        mkdir -p /tmp/deb/usr/bin;
        curl -Lo /tmp/v2ray.zip https://github.com/v2fly/v2ray-core/releases/download/${VERSION}/${ZIP}; 
        unzip /tmp/v2ray.zip v2ray -d /tmp/deb/usr/bin/;
	    sed -i 's/^Version:.*/Version: ${DEB_VER}/; s/^Architecture:.*/Architecture: ${PKG_ARCH}/' /tmp/deb/DEBIAN/control;
        mkdir -p /tmp/deb/etc/v2ray;
        cp /tmp/config.json /tmp/deb/etc/v2ray/;
        mkdir -p /tmp/deb/lib/systemd/system;
        cp /tmp/v2ray.service /tmp/deb/lib/systemd/system/; 
        cd /tmp;
        dpkg-deb --build /tmp/deb;
    "
    docker cp ${DOCKER_NAME}:/tmp/deb.deb ./${PKG_NAME}_${DEB_VER}_${PKG_ARCH}.deb

    # Clean up
    docker ps -a | grep ${DOCKER_NAME} && docker rm -f ${DOCKER_NAME}
}

build amd64
build arm64
