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

# Download, install and cleanup RDI installation package
ENV RDI_VERSION=1.10.0
RUN curl --output /tmp/rdi-installation-$RDI_VERSION.tar.gz https://redis-enterprise-software-downloads.s3.amazonaws.com/redis-di/rdi-installation-$RDI_VERSION.tar.gz && \
    cd /tmp && \
    tar -xzf rdi-installation-$RDI_VERSION.tar.gz && \
    cd rdi-installation-$RDI_VERSION && \
    ./install.sh && \
    rm -rf /tmp/rdi-installation-$RDI_VERSION.tar.gz /tmp/rdi-installation-$RDI_VERSION

USER labuser:labuser

COPY from-repo/scripts /scripts

USER root:root

RUN python3 -m pip install -r /scripts/generate-load-requirements.txt

# Expose RDI server port
EXPOSE 13000

WORKDIR /home/labuser

# Start RDI server on port 13000
CMD ["/opt/redis-di/bin/redis-di-server", "--port", "13000"]
