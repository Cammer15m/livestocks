# Use the existing RDI CLI image as base since it already has RDI components
FROM ubuntu:22.04

USER root

# Install required packages including build dependencies for pandas
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    tar \
    python3 \
    python3-pip \
    postgresql-client \
    sudo \
    build-essential \
    python3-dev \
    && rm -rf /var/lib/apt/lists/*

# Create labuser
RUN useradd -m -s /bin/bash labuser && \
    usermod -aG sudo labuser && \
    echo "labuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Download and extract RDI installation package (following rdi-training pattern)
ENV RDI_VERSION=1.10.0
RUN mkdir /rdi
WORKDIR /rdi
RUN curl https://redis-enterprise-software-downloads.s3.amazonaws.com/redis-di/rdi-installation-$RDI_VERSION.tar.gz -O
RUN tar -xzf rdi-installation-$RDI_VERSION.tar.gz
RUN rm rdi-installation-$RDI_VERSION.tar.gz
WORKDIR /rdi/rdi-installation-$RDI_VERSION

USER labuser:labuser

COPY from-repo/scripts /scripts

USER root:root

# Upgrade pip and install requirements with pre-built wheels when possible
RUN python3 -m pip install --upgrade pip
RUN python3 -m pip install --only-binary=all -r /scripts/generate-load-requirements.txt || \
    python3 -m pip install -r /scripts/generate-load-requirements.txt

# Expose RDI server port
EXPOSE 13000

WORKDIR /home/labuser

# Start RDI server on port 13000 from the extracted location
CMD ["/rdi/rdi-installation-1.10.0/bin/redis-di-server", "--port", "13000"]
