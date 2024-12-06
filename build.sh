#!/bin/bash

docker context create multi-platform
docker buildx create multi-platform --platform linux/amd64,linux/arm64,linux/arm --use

VERSION=$(curl -s https://api.github.com/repos/v2fly/v2ray-core/releases/latest | jq -r .name)
docker buildx build --push \
    --platform linux/amd64,linux/arm64,linux/arm \
    -t hangxie/v2ray:${VERSION} -t hangxie/v2ray:latest \
    --build-arg VERSION=${VERSION} \
    .
