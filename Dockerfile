FROM mcr.microsoft.com/dotnet/runtime:10.0

# Allow UID and GID to be set at build time (default: 99:100)
# Default values are chosen to match the 'nobody' user/group, which is default for Unraid
ARG AIO_UID=99
ARG AIO_GID=100

RUN set -xe; \
        apt-get update; \
        apt-get install -y --no-install-recommends \
                ca-certificates \
                curl \
                python3 \
                ; \
        rm -rf /var/lib/apt/lists/* \
                   /var/cache/apt/archives/*

COPY entrypoint.sh /entrypoint.sh
COPY ServerRun.sh /home/aio/ServerRun

ENV DOWNLOAD_DIR="/downloads" \
        DATA_DIR="/support_dir"

# Add a non-root user to run the server, with configurable UID/GID
RUN chmod +x /entrypoint.sh; \
        groupadd -g ${AIO_GID} aio || true; \
        useradd -m -u ${AIO_UID} -g ${AIO_GID} aio || true; \
        mkdir -p ${DOWNLOAD_DIR} ${DATA_DIR} /home/aio/app; \
        chown -R ${AIO_UID}:${AIO_GID} ${DOWNLOAD_DIR} ${DATA_DIR} /home/aio; \
        chmod +x /home/aio/ServerRun

EXPOSE 1234

USER ${AIO_UID}:${AIO_GID}

WORKDIR /home/aio

VOLUME [ "/downloads" ]
VOLUME [ "/support_dir" ]

ENTRYPOINT ["/entrypoint.sh"]

LABEL org.opencontainers.image.title="OpenRA AIO Server" \
        org.opencontainers.image.description="Dockerized environment for running OpenRA-based game servers" \
        org.opencontainers.image.authors="Olle" \
        org.opencontainers.image.source="https://github.com/ollejacobsen/openra-aio-server" \
        org.opencontainers.image.documentation="https://github.com/ollejacobsen/openra-aio-server#readme" \
        org.opencontainers.image.licenses="MIT"