FROM redislabs/redis-di-cli:v0.118.0

USER root:root

# Install basic tools
RUN microdnf install -y openssh-server curl python3 python3-pip

# Create labuser
RUN adduser labuser && \
    usermod -aG wheel labuser

# Generate SSH keys
RUN ssh-keygen -A

# Install Python dependencies for RDI
RUN python3 -m pip install redis psycopg2-binary

# Create scripts directory
RUN mkdir -p /scripts

# Switch to labuser
USER labuser:labuser

# Set working directory
WORKDIR /home/labuser

# Default command
CMD ["tail", "-f", "/dev/null"]
