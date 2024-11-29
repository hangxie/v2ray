FROM debian:12-slim
ARG DEBIAN_FRONTEND=noninteractive
ARG VERSION

RUN adduser --home /app --disabled-password --system app \
 && apt-get update -qq \
 && apt-get -y -qq install ca-certificates curl zip \
 && case $(uname -m) in \
        x86_64) \
            ZIP=v2ray-linux-64.zip \
            ;; \
        armv7*) \
            ZIP=v2ray-linux-arm32-v7a.zip \
            ;; \
        armv8*|aarch64) \
            ZIP=v2ray-linux-arm64-v8a.zip \
            ;; \
        *) \
            echo Unsupported arch $(uname -m); \
            exit 1 \
            ;; \
    esac \
 && curl -Lo /tmp/v2ray.zip \
        https://github.com/v2fly/v2ray-core/releases/download/${VERSION}/${ZIP} \
 && unzip /tmp/v2ray.zip v2ray -d /app/ \
 && chmod +x /app/v2ray \
 && chown app /app/v2ray \
 && apt -y -qq remove --purge curl zip \
 && apt -y -qq autoremove --purge \
 && rm -rf /var/lib/apt/lists/* /tmp/v2ray.zip

USER app
WORKDIR /app
ENTRYPOINT ["/app/v2ray"]
