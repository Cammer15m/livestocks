# Multi-stage build for optimized RDI container
FROM ubuntu:22.04 as builder

# Install only build dependencies
RUN apt-get update && apt-get install -y \
    curl \
    tar \
    && rm -rf /var/lib/apt/lists/*

# Download and extract RDI in builder stage
WORKDIR /tmp
ENV RDI_VERSION=1.10.0
RUN curl -L https://redis-enterprise-software-downloads.s3.amazonaws.com/redis-di/rdi-installation-$RDI_VERSION.tar.gz -o rdi.tar.gz
RUN tar -xzf rdi.tar.gz && rm rdi.tar.gz

# Final stage - smaller runtime image
FROM ubuntu:22.04

# Install only runtime dependencies
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    postgresql-client \
    sudo \
    curl \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Create labuser
RUN useradd -m -s /bin/bash labuser && \
    usermod -aG sudo labuser && \
    echo "labuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Copy RDI from builder stage
COPY --from=builder /tmp/rdi_install /rdi/rdi_install

# Copy only necessary scripts
COPY from-repo/scripts/generate-load-requirements.txt /tmp/requirements.txt

# Install Python requirements
RUN python3 -m pip install --no-cache-dir --upgrade pip && \
    python3 -m pip install --no-cache-dir -r /tmp/requirements.txt && \
    rm /tmp/requirements.txt

# Set working directory
WORKDIR /rdi/rdi_install/1.10.0

# Create optimized startup script
RUN echo '#!/bin/bash\n\
set -e\n\
echo "=== RDI Installation Starting ==="\n\
echo "Using shared Redis metadata DB: ${REDIS_HOST:-3.148.243.197}:${REDIS_PORT:-13000}"\n\
\n\
# Wait a moment for network to be ready\n\
sleep 10\n\
\n\
# Run RDI installation with shared Redis database\n\
echo -e "${REDIS_HOST:-3.148.243.197}\\n${REDIS_PORT:-13000}\\n${REDIS_USER:-default}\\n${REDIS_PASSWORD:-redislabs}\\nN\\n13000\\nY\\nY\\n8.8.8.8,8.8.4.4\\n2\\n" | sudo ./install.sh -l INFO\n\
\n\
echo "=== RDI Installation Complete ==="\n\
\n\
# Keep container running\n\
tail -f /dev/null\n\
' > /start.sh && chmod +x /start.sh

# Expose RDI server port
EXPOSE 13000

# Switch to labuser
USER labuser
WORKDIR /home/labuser

CMD ["/start.sh"]
