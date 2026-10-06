FROM docker.io/library/caddy:alpine AS caddy
FROM ghcr.io/pfm-powerforme/self-controller:latest AS controller
FROM ghcr.io/pfm-powerforme/frontend-vaultwarden:latest AS frontend

FROM docker.io/library/rust:alpine AS backend
ARG REPO
ARG ARCH
ARG CPU_ARCH
ARG TAG
ARG IMAGE_VERSION
ENV REPO=$REPO \
     ARCH=$ARCH \
     CPU_ARCH=$CPU_ARCH \
     TAG=$TAG \
     IMAGE_VERSION=$IMAGE_VERSION

ENV USER="root" \
     CARGO_HOME="/root/.cargo" \
     VW_VERSION=$TAG \
     CARGO_PROFILE=release \
     FEATURES="sqlite,enable_mimalloc,s3,vendored_openssl,oidc-accept-rfc3339-timestamps,oidc-accept-string-booleans" \
     PKG_CONFIG_ALL_STATIC=1

WORKDIR /
RUN --mount=type=cache,target=/var/cache/apk \
    --mount=type=cache,target=/etc/apk/cache \
    apk add --no-cache tzdata
RUN --mount=type=cache,target=/var/cache/apk \
    --mount=type=cache,target=/etc/apk/cache \
    apk add --virtual .build-deps \
                bash \
                build-base \
                pkgconf \
                git \
                perl \
                make \
                sqlite-dev \
                sqlite-static
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN mkdir -pv "${CARGO_HOME}" && \
     rustup set profile minimal && \
     rustup target add ${CPU_ARCH}-unknown-linux-musl && \
     echo "[target.${CPU_ARCH}-unknown-linux-musl]" > "${CARGO_HOME}/config.toml" && \
     echo 'rustflags = ["-C", "target-feature=+crt-static", "-C", "relocation-model=static", "-C", "link-arg=-static", "-C", "link-arg=-no-pie"]' >> "${CARGO_HOME}/config.toml"
RUN USER=root cargo new --bin /backend
WORKDIR /backend/
COPY source-src/Cargo.toml source-src/Cargo.lock source-src/rust-toolchain.toml source-src/build.rs ./
COPY source-src/macros/ ./macros/
RUN --mount=type=cache,id=vw-cargo-registry,target=/root/.cargo/registry,sharing=locked \
    --mount=type=cache,id=vw-cargo-git,target=/root/.cargo/git,sharing=locked \
    --mount=type=cache,id=vw-target,target=/backend/target,sharing=locked \
    cargo build --features ${FEATURES} --profile "${CARGO_PROFILE}" --target ${CPU_ARCH}-unknown-linux-musl && \
    find . -not -path "./target*" -delete
COPY source-src/ .
RUN --mount=type=cache,id=vw-cargo-registry,target=/root/.cargo/registry,sharing=locked \
    --mount=type=cache,id=vw-cargo-git,target=/root/.cargo/git,sharing=locked \
    --mount=type=cache,id=vw-target,target=/backend/target,sharing=locked \
    touch build.rs src/main.rs && \
    cargo build --features ${FEATURES} --profile "${CARGO_PROFILE}" --target ${CPU_ARCH}-unknown-linux-musl && \
    mkdir -p /backend/final && \
    if [[ "${CARGO_PROFILE}" == "dev" ]] ; then \
        cp "/backend/target/${CPU_ARCH}-unknown-linux-musl/debug/vaultwarden" /backend/final/vaultwarden ; \
    else \
        cp "/backend/target/${CPU_ARCH}-unknown-linux-musl/${CARGO_PROFILE}/vaultwarden" /backend/final/vaultwarden ; \
    fi


FROM gcr.io/distroless/static-debian13 AS runtime
ARG TAG
ENV PATH="/usr/bin:/" \
     LC_ALL="C.UTF-8" \
     LANG="C.UTF-8" \
     TMPDIR="/tmp" \
     ROCKET_PROFILE="production" \
     ROCKET_ADDRESS=127.0.0.1 \
     ROCKET_PORT=8000 \
     VW_VERSION=$TAG \
     VW_WORKDIR="/opt/vw" \
     CR_AUTOBACKUP_BACKUP_PATH="/opt/vw/data" \
     CR_AUTOBACKUP_BACKUP_NAME="vaultwarden" \
     CR_CONTROLLER_CONFIG="/etc/controller/config.json"

COPY --from=caddy /usr/bin/caddy /usr/bin/caddy
COPY --from=controller /usr/bin/controller /usr/bin/controller
COPY --chown=65532:65532 --from=frontend /frontend/ /opt/vw/web-vault/
COPY --chown=65532:65532 --from=backend /backend/final/vaultwarden /opt/vw/vaultwarden
COPY --from=backend /usr/share/zoneinfo/Asia/Shanghai /usr/share/zoneinfo/Asia/Shanghai
COPY --from=backend /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
COPY rootfs/ /

WORKDIR ${VW_WORKDIR}
VOLUME ${VW_WORKDIR}/data
EXPOSE 8080
ENTRYPOINT ["/usr/bin/controller"]
