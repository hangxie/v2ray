#!/bin/bash

set -euo pipefail

mkdir -p build/
VERSION=$(curl -s https://api.github.com/repos/v2fly/v2ray-core/releases/latest | jq -r .name)

function build() {
    PKG_ARCH=$1

    case ${PKG_ARCH} in
        x86_64)
            BIN_ARCH=amd64
            ZIP=v2ray-linux-64.zip
            ;;
        aarch64)
            BIN_ARCH=arm64
            ZIP=v2ray-linux-arm64-v8a.zip
            ;;
        *)
            echo package for architecture ${PKG_ARCH} is not currently supported
            exit 0
            ;;
    esac

    DOCKER_NAME=rpm-build-${BIN_ARCH}
    RPM_VER=$(echo ${VERSION} | cut -f 1 -d \- | tr -d 'a-z')

    # Launch build container
    docker ps -a | grep ${DOCKER_NAME} && docker rm -f ${DOCKER_NAME}
    docker run -di --rm --name ${DOCKER_NAME} rockylinux:9

    # CCI does not support volume mount, so use docker cp instead
    docker cp ./rpm ${DOCKER_NAME}:/tmp/
    docker cp ./config.json ${DOCKER_NAME}:/tmp/
    docker cp ./v2ray.service ${DOCKER_NAME}:/tmp/

    # Build RPM
    docker exec -t ${DOCKER_NAME} bash -c "
        set -eou pipefail;
        dnf install -y systemd-rpm-macros zip rpm-build;
        mkdir -p /tmp/usr/bin/;
        curl -Lo /tmp/v2ray.zip https://github.com/v2fly/v2ray-core/releases/download/${VERSION}/${ZIP};
        unzip /tmp/v2ray.zip v2ray -d /tmp/;
        sed -i 's/^Version:.*/Version: ${RPM_VER}/;' /tmp/rpm/v2ray.spec;
        mkdir -p ~/rpmbuild/SOURCES;
        tar zcf ~/rpmbuild/SOURCES/v2ray-${RPM_VER}.tar.gz \
            --transform 's@^@v2ray-${RPM_VER}/@' \
            -C /tmp/ \
            v2ray config.json v2ray.service;
        rpmbuild -bb --target ${PKG_ARCH} /tmp/rpm/v2ray.spec;
        cp /root/rpmbuild/RPMS/${PKG_ARCH}/v2ray-${RPM_VER}-1.el9.${PKG_ARCH}.rpm /tmp/;
    "
    docker cp ${DOCKER_NAME}:/tmp/v2ray-${RPM_VER}-1.el9.${PKG_ARCH}.rpm ./build/v2ray-${RPM_VER}-1.${PKG_ARCH}.rpm

    # Clean up
    docker ps -a | grep ${DOCKER_NAME} && docker rm -f ${DOCKER_NAME}
}

build x86_64
build aarch64
