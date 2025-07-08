# Use the existing RDI CLI image as base since it already has RDI components
FROM ubuntu:22.04

USER root

# Install required packages
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    tar \
    python3 \
    python3-pip \
    postgresql-client \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Create labuser
RUN useradd -m -s /bin/bash labuser && \
    usermod -aG sudo labuser && \
    echo "labuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Download and extract RDI installation package using the exact same method as build.sh
ENV RDI_VERSION=1.10.0
RUN mkdir -p /downloads && \
    chmod 744 /downloads && \
    curl --output /downloads/rdi-installation-$RDI_VERSION.tar.gz -O https://redis-enterprise-software-downloads.s3.amazonaws.com/redis-di/rdi-installation-$RDI_VERSION.tar.gz && \
    cd /downloads && \
    tar -xzf rdi-installation-$RDI_VERSION.tar.gz && \
    chmod -R 744 /downloads

USER labuser:labuser

COPY from-repo/scripts /scripts

USER root:root

RUN python3 -m pip install -r /scripts/generate-load-requirements.txt

# Expose RDI server port
EXPOSE 13000

WORKDIR /home/labuser
