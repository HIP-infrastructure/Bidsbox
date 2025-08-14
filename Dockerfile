ARG CI_REGISTRY_IMAGE
ARG TAG
ARG DOCKERFS_TYPE
ARG DOCKERFS_VERSION
FROM ${CI_REGISTRY_IMAGE}/${DOCKERFS_TYPE}:${DOCKERFS_VERSION}${TAG}
LABEL maintainer="florian.sipp@chuv.ch"

ARG DEBIAN_FRONTEND=noninteractive
ARG CARD
ARG CI_REGISTRY
ARG APP_NAME
ARG APP_VERSION

LABEL app_version=$APP_VERSION
LABEL app_tag=$TAG

WORKDIR /apps/${APP_NAME}
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update -qy && \
    apt-get install --no-install-recommends -qy \
    git python3 python3-pip \
    # libs necessary to have a working pyqt application \
    libxcb-icccm4 libxcb-randr0 libxcb-render-util0 \
    libxcb-shape0 libxcursor1 libxkbcommon-x11-0 \
    libxcb-keysyms1 libglib2.0-0 libdbus-1-3 fontconfig \
    libfontconfig1 libxcb-image0 libxcb-util1 libxcb-cursor0 && \
    # install using pip and git \
    pip install --no-cache git+https://github.com/HIP-infrastructure/Bidsificator/@v${APP_VERSION}#egg=Bidsificator && \
    apt-get remove -y --purge git && \
    apt-get autoremove -y --purge && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

ENV APP_SPECIAL="no"
ENV APP_CMD="bidsificator"
ENV PROCESS_NAME="bidsificator"
ENV APP_DATA_DIR_ARRAY=""
ENV DATA_DIR_ARRAY=""

HEALTHCHECK --interval=10s --timeout=10s --retries=5 --start-period=30s \
  CMD sh -c "/apps/${APP_NAME}/scripts/process-healthcheck.sh \
  && /apps/${APP_NAME}/scripts/ls-healthcheck.sh /home/${HIP_USER}/nextcloud/"

COPY ./scripts/ scripts/

ENTRYPOINT ["./scripts/docker-entrypoint.sh"]
