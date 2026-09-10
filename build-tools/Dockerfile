FROM debian:12

# Update apt cache
RUN apt-get update

# Install WebRTC base dependencies
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    apt-utils \
    ca-certificates \
    ccache \
    curl \
    file \
    git \
    python3 \
    python3-setuptools \
    sudo \
    wget \
    xz-utils

# Install WebRTC for Linux compile dependencies
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    libxml2 \
    lsb-release \
    pkg-config

# Add user
ARG USERNAME=docker-webrtc
ARG UID=1000
ARG GID=1000
RUN groupadd -g $GID -o $USERNAME \
 && useradd -l -m -u $UID -g $GID -o -s /bin/bash $USERNAME \
 && usermod -a -G sudo $USERNAME \
 && echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Get Chromium depot tools
RUN git clone --depth 1 https://chromium.googlesource.com/chromium/tools/depot_tools.git /opt/depot_tools \
 && chown -R $UID:$GID /opt/depot_tools
ENV PATH /opt/depot_tools:$PATH

# Create workdir
RUN mkdir /webrtc && chown $UID:$GID /webrtc

# Setup CCache
ENV CCACHE_DIR /webrtc/.ccache
ENV CCACHE_BASEDIR /webrtc/src
ENV CCACHE_SLOPPINESS include_file_mtime

# Run as user
USER $USERNAME

# fetch/gclient refuse to run at all until depot_tools' private Python3/CIPD toolchain
# is bootstrapped ("python3_bin_reldir.txt not found..."), which hasn't happened yet on
# this fresh clone. ensure_bootstrap does that bootstrap directly. Do it here so it's
# baked into the image instead of repeated (and pulling a lot of data) on every build.
RUN ensure_bootstrap \
 && fetch --help > /dev/null \
 && gclient --help > /dev/null

# Set working directory
WORKDIR /webrtc
