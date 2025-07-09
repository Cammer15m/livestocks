# RDI container with systemd support for K3s installation
FROM ubuntu:22.04

ENV container docker

# Install systemd and required packages for RDI installation
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
    && apt-get clean \
    && systemctl mask dev-hugepages.mount sys-fs-fuse-connections.mount

# Create labuser with sudo privileges
RUN useradd -m -s /bin/bash labuser && \
    usermod -aG sudo labuser && \
    echo "labuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Configure SSH for container access
RUN mkdir -p /var/run/sshd && \
    echo 'root:redislabs' | chpasswd && \
    echo 'labuser:redislabs' | chpasswd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    systemctl enable ssh

# Download and extract RDI installation
RUN mkdir -p /rdi
WORKDIR /rdi
ENV RDI_VERSION=1.10.0
RUN curl -L https://redis-enterprise-software-downloads.s3.amazonaws.com/redis-di/rdi-installation-$RDI_VERSION.tar.gz -o rdi-installation-$RDI_VERSION.tar.gz
RUN tar -xzf rdi-installation-$RDI_VERSION.tar.gz
RUN rm rdi-installation-$RDI_VERSION.tar.gz
RUN chown -R labuser:labuser /rdi

# Copy scripts for load generation
COPY from-repo/scripts /scripts
RUN chown -R labuser:labuser /scripts

# Install Python dependencies for load generation
RUN python3 -m pip install --upgrade pip
RUN python3 -m pip install psycopg2-binary pandas redis

# Create a startup script that displays information
RUN echo '#!/bin/bash\n\
echo "🚀 RDI Container with systemd Ready for Manual Installation"\n\
echo "========================================================"\n\
echo ""\n\
echo "📁 RDI Installation files are ready at: /rdi/rdi_install/'$RDI_VERSION'/"\n\
echo "🔧 To install RDI manually:"\n\
echo "   1. Access the container: docker exec -it rdi-manual bash"\n\
echo "   2. Navigate to: cd /rdi/rdi_install/'$RDI_VERSION'/"\n\
echo "   3. Run installation: sudo ./install.sh"\n\
echo ""\n\
echo "💡 Installation prompts and suggested answers:"\n\
echo "   - RDI hostname: redis-17173.c14.us-east-1-2.ec2.redns.redis-cloud.com"\n\
echo "   - RDI port: 17173"\n\
echo "   - Username: [press enter for default]"\n\
echo "   - Password: redislabs"\n\
echo "   - TLS: N"\n\
echo "   - HTTPS port: 443 [press enter]"\n\
echo "   - iptables: Y"\n\
echo "   - DNS: Y"\n\
echo "   - Upstream DNS: 8.8.8.8,8.8.4.4"\n\
echo "   - Source database: 5 (PostgreSQL)"\n\
echo ""\n\
echo "🔗 Connection details for RDI configuration:"\n\
echo "   - Redis Cloud (metadata): redis-17173.c14.us-east-1-2.ec2.redns.redis-cloud.com:17173"\n\
echo "   - PostgreSQL (source): postgresql:5432 (user: postgres, password: postgres, db: chinook)"\n\
echo ""\n\
echo "🐳 systemd is running as PID 1 - K3s should work now!"\n\
echo ""\n\
' > /rdi-info.sh && chmod +x /rdi-info.sh

# Create systemd service to show RDI info on startup
RUN echo '[Unit]\n\
Description=RDI Information Display\n\
After=multi-user.target\n\
\n\
[Service]\n\
Type=oneshot\n\
ExecStart=/rdi-info.sh\n\
StandardOutput=journal\n\
\n\
[Install]\n\
WantedBy=multi-user.target\n\
' > /etc/systemd/system/rdi-info.service && \
    systemctl enable rdi-info.service

# Expose SSH and RDI ports
EXPOSE 22 443 12001 13000

# Set working directory
WORKDIR /rdi/rdi_install/1.10.0

# systemd needs these volumes and signals
VOLUME ["/sys/fs/cgroup"]
STOPSIGNAL SIGRTMIN+3

# Start systemd as PID 1
CMD ["/sbin/init"]
