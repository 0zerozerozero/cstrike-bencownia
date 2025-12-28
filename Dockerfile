FROM ghcr.io/bordeux/cstrike-server:latest

LABEL org.opencontainers.image.description="Counter Strike 1.6 for Bencownia.com"
LABEL org.opencontainers.image.source=https://github.com/bordeux/cstrike-bencownia

ENV AMXMODX_AUTOCOMPILE=0
COPY ./cstrike ${CSTRIKE_BASE_PATH}
RUN ${HELPERS_PATH}/amxmodx-compile.sh ${CSTRIKE_BASE_PATH}/addons/amxmodx
