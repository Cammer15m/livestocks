# Use the existing RDI CLI image as base since it already has RDI components
FROM ubuntu:22.04

USER root

# Install required packages including build dependencies for pandas and Redis server
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    tar \
    python3 \
    python3-pip \
    postgresql-client \
    sudo \
    systemd \
    systemd-sysv \
    openssh-server \
    iptables \
    build-essential \
    python3-dev \
    && rm -rf /var/lib/apt/lists/*

# Enable systemd for RDI installation
RUN systemctl set-default multi-user.target





# Create labuser
RUN useradd -m -s /bin/bash labuser && \
    usermod -aG sudo labuser && \
    echo "labuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# RDI - following exact rdi-training pattern
RUN mkdir /rdi
WORKDIR /rdi
ENV RDI_VERSION=1.10.0
RUN curl https://redis-enterprise-software-downloads.s3.amazonaws.com/redis-di/rdi-installation-$RDI_VERSION.tar.gz -O
RUN tar -xvf rdi-installation-$RDI_VERSION.tar.gz
RUN rm rdi-installation-$RDI_VERSION.tar.gz
WORKDIR /rdi/rdi_install/$RDI_VERSION

USER labuser:labuser

COPY from-repo/scripts /scripts

USER root:root

# Upgrade pip and install requirements with verbose output to see errors
RUN python3 -m pip install --upgrade pip
RUN python3 -m pip install --verbose -r /scripts/generate-load-requirements.txt

# Expose RDI server port
EXPOSE 13000

WORKDIR /home/labuser

# Create RDI installation script that uses Redis Cloud credentials from environment
RUN echo '#!/bin/bash\n\
set -x  # Enable debug output\n\
exec > >(tee -a /var/log/rdi-startup.log) 2>&1  # Log everything\n\
\n\
echo "=== RDI Installation Starting ==="\n\
echo "Current user: $(whoami)"\n\
echo "Current directory: $(pwd)"\n\
echo "Environment variables:"\n\
env | grep REDIS\n\
\n\
# Wait for Redis Enterprise container to be ready\n\
echo "Waiting for Redis Enterprise container to be ready..."\n\
sleep 30\n\
\n\
# Navigate to RDI installation directory\n\
echo "Navigating to RDI installation directory..."\n\
cd /rdi/rdi_install/1.10.0/\n\
echo "Current directory: $(pwd)"\n\
ls -la\n\
\n\
# Run RDI installation with shared Redis database credentials from environment\n\
echo "Starting RDI installation..."\n\
echo "Using Redis Host: ${REDIS_HOST:-3.148.243.197}"\n\
echo "Using Redis Port: ${REDIS_PORT:-13000}"\n\
echo "Using Redis User: ${REDIS_USER:-default}"\n\
echo -e "${REDIS_HOST:-3.148.243.197}\\n${REDIS_PORT:-13000}\\n${REDIS_USER:-default}\\n${REDIS_PASSWORD:-redislabs}\\nN\\n\\nY\\nY\\n8.8.8.8,8.8.4.4\\n2\\n" | sudo ./install.sh -l DEBUG\n\
\n\
echo "=== RDI Installation Complete ==="\n\
echo "Checking what processes are running:"\n\
ps aux\n\
\n\
echo "Checking what ports are listening:"\n\
netstat -tlnp || ss -tlnp\n\
\n\
# Keep container running\n\
tail -f /dev/null\n\
' > /start.sh && chmod +x /start.sh

CMD ["/start.sh"]
