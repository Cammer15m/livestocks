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

# Install Redis Enterprise
RUN curl -fsSL https://download.redislabs.com/redis-enterprise/install.sh | bash



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
echo "=== Redis Enterprise and RDI Installation Starting ==="\n\
echo "Current user: $(whoami)"\n\
echo "Current directory: $(pwd)"\n\
echo "Environment variables:"\n\
env | grep REDIS\n\
\n\
# Start Redis Enterprise\n\
echo "Starting Redis Enterprise..."\n\
/opt/redislabs/bin/rladmin cluster create name cluster.local username admin@rl.org password redislabs\n\
\n\
# Wait for Redis Enterprise to be ready\n\
echo "Waiting for Redis Enterprise to be ready..."\n\
sleep 30\n\
\n\
# Create RDI database via API\n\
echo "Creating RDI database..."\n\
curl -k -X POST https://localhost:9443/v1/bdbs -H "Content-Type: application/json" -u admin@rl.org:redislabs -d '"'"'{"name": "rdi-db", "type": "redis", "memory_size": 268435456, "port": 12001, "oss_cluster": false, "replication": true, "sharding": false, "data_persistence": "aof_every_write", "authentication_redis_pass": "redislabs", "roles": ["active"], "rdi": {"enabled": true, "source": true}}'"'"'\n\
\n\
# Wait for database to be ready\n\
echo "Waiting for RDI database to be ready..."\n\
sleep 10\n\
\n\
# Navigate to RDI installation directory\n\
echo "Navigating to RDI installation directory..."\n\
cd /rdi/rdi_install/1.10.0/\n\
echo "Current directory: $(pwd)"\n\
ls -la\n\
\n\
# Run RDI installation with Redis Cloud credentials from environment\n\
echo "Starting RDI installation..."\n\
echo -e "localhost\\n12001\\ndefault\\nredislabs\\nN\\n13000\\nY\\nY\\n8.8.8.8,8.8.4.4\\n2\\n" | sudo ./install.sh -l DEBUG\n\
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
