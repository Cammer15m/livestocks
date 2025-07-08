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

# Copy and extract RDI installation package
ENV RDI_VERSION=1.10.0
COPY rdi-training/rdi-installation-$RDI_VERSION.tar.gz /downloads/
RUN cd /downloads && \
    tar -xzf rdi-installation-$RDI_VERSION.tar.gz && \
    chmod -R 744 /downloads

USER labuser:labuser

COPY from-repo/scripts /scripts

USER root:root

RUN python3 -m pip install -r /scripts/generate-load-requirements.txt

# Expose RDI server port
EXPOSE 13000

WORKDIR /home/labuser
