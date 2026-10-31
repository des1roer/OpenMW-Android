FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential cmake make ninja-build unzip zip bzip2 xz-utils wget curl git ca-certificates \
    pkg-config python3 gettext-base patch file autoconf automake libtool nasm yasm \
    openjdk-17-jdk-headless ccache rsync gcc-multilib g++-multilib && rm -rf /var/lib/apt/lists/*
