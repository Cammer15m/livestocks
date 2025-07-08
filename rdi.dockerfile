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
    build-essential \
    python3-dev \
    && rm -rf /var/lib/apt/lists/*



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
# Navigate to RDI installation directory\n\
cd /rdi/rdi_install/1.10.0/\n\
\n\
# Run RDI installation with Redis Cloud credentials from environment\n\
echo -e "${REDIS_HOST}\\n${REDIS_PORT}\\n${REDIS_USER}\\n${REDIS_PASSWORD}\\nY\\n443\\nY\\nY\\n8.8.8.8,8.8.4.4\\n2\\n" | sudo ./install.sh -l DEBUG\n\
\n\
# Keep container running\n\
tail -f /dev/null\n\
' > /start.sh && chmod +x /start.sh

CMD ["/start.sh"]
