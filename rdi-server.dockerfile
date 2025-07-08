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
    && rm -rf /var/lib/apt/lists/*

# Create RDI user
RUN useradd -m -s /bin/bash rdi

# Download and install RDI
ENV RDI_VERSION=1.10.0
RUN mkdir -p /downloads && \
    cd /downloads && \
    wget https://download.redis.io/rdi/rdi-installation-${RDI_VERSION}.tar.gz && \
    tar -xzf rdi-installation-${RDI_VERSION}.tar.gz && \
    cd rdi_install/${RDI_VERSION} && \
    ./install.sh --silent --rdi-host localhost --rdi-port 13000 --rdi-password redislabs

# Expose RDI port
EXPOSE 13000

# Create startup script
RUN echo '#!/bin/bash\n\
# Start RDI server\n\
redis-di start-server --host 0.0.0.0 --port 13000 --password redislabs &\n\
# Keep container running\n\
tail -f /dev/null\n\
' > /start-rdi.sh && chmod +x /start-rdi.sh

WORKDIR /home/rdi

CMD ["/start-rdi.sh"]
