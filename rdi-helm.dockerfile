# RDI Helm-based container with proper K3s support
FROM ubuntu:22.04

ENV container docker
ENV DEBIAN_FRONTEND=noninteractive

# Install systemd and required packages
RUN apt-get update && apt-get install -y \
    systemd \
    systemd-sysv \
    curl \
    wget \
    tar \
    sudo \
    gnupg2 \
    lsb-release \
    net-tools \
    iproute2 \
    iputils-ping \
    openssh-server \
    iptables \
    python3 \
    python3-pip \
    postgresql-client \
    openssl \
    ca-certificates \
    && apt-get clean \
    && systemctl mask dev-hugepages.mount sys-fs-fuse-connections.mount

# Create labuser with sudo privileges
RUN useradd -m -s /bin/bash labuser && \
    usermod -aG sudo labuser && \
    echo "labuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Configure SSH
RUN mkdir -p /var/run/sshd && \
    echo 'root:redislabs' | chpasswd && \
    echo 'labuser:redislabs' | chpasswd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    systemctl enable ssh

# Install Helm
RUN curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Install kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
    chmod +x kubectl && \
    mv kubectl /usr/local/bin/

# Install K3s with proper Docker configuration
RUN curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--write-kubeconfig-mode=644 --docker" sh -

# Download RDI Helm chart
WORKDIR /rdi
ENV RDI_VERSION=1.12.2
RUN wget https://redis-enterprise-software-downloads.s3.amazonaws.com/redis-di/rdi-${RDI_VERSION}.tgz

# Generate default values file
RUN helm show values rdi-${RDI_VERSION}.tgz > rdi-values.yaml

# Copy installation scripts
COPY install-rdi-helm.sh /rdi/
COPY configure-rdi-values.sh /rdi/
RUN chmod +x /rdi/*.sh

# Create startup script
RUN echo '#!/bin/bash\n\
echo "🚀 RDI Helm Container Ready"\n\
echo "========================================"\n\
echo ""\n\
echo "📁 RDI Helm files ready at: /rdi/"\n\
echo "🔧 To configure and install RDI:"\n\
echo "   1. Configure values: ./configure-rdi-values.sh"\n\
echo "   2. Install RDI: ./install-rdi-helm.sh --skip-download"\n\
echo ""\n\
echo "💡 Default Redis Cloud connection:"\n\
echo "   - Host: redis-17173.c14.us-east-1-2.ec2.redns.redis-cloud.com"\n\
echo "   - Port: 17173"\n\
echo "   - Password: redislabs"\n\
echo ""\n\
echo "🐳 K3s and Helm are ready for RDI deployment!"\n\
echo ""\n\
' > /rdi-helm-info.sh && chmod +x /rdi-helm-info.sh

# Create systemd service for info display
RUN echo '[Unit]\n\
Description=RDI Helm Information Display\n\
After=multi-user.target\n\
\n\
[Service]\n\
Type=oneshot\n\
ExecStart=/rdi-helm-info.sh\n\
StandardOutput=journal\n\
\n\
[Install]\n\
WantedBy=multi-user.target\n\
' > /etc/systemd/system/rdi-helm-info.service && \
    systemctl enable rdi-helm-info.service

# Expose ports
EXPOSE 22 443 12001 13000 80 8080

# Set working directory
WORKDIR /rdi

# systemd configuration
VOLUME ["/sys/fs/cgroup"]
STOPSIGNAL SIGRTMIN+3

# Start systemd as PID 1
CMD ["/sbin/init"]
