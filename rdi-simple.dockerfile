# Use official Redis RDI CLI image (like rdi-training)
FROM redislabs/redis-di-cli:v0.118.0

USER root:root

# Install required packages including PostgreSQL development libraries
RUN microdnf install -y openssh-server python3-pip postgresql-devel gcc python3-devel

# Create labuser
RUN adduser labuser && \
    usermod -aG wheel labuser

# Generate SSH keys
RUN ssh-keygen -A

USER labuser:labuser

# Copy scripts
COPY from-repo/scripts /scripts

USER root:root

# Skip Python dependencies for now - focus on RDI functionality first
# RUN python3 -m pip install psycopg2-binary redis

# Create RDI configuration script
RUN echo '#!/bin/bash\n\
set -e\n\
echo "=== Configuring RDI with shared Redis database ==="\n\
echo "Shared Redis: ${REDIS_HOST:-3.148.243.197}:${REDIS_PORT:-13000}"\n\
\n\
# Configure RDI to use shared Redis database\n\
redis-di configure --rdi-host ${REDIS_HOST:-3.148.243.197}:${REDIS_PORT:-13000} --rdi-password ${REDIS_PASSWORD:-redislabs}\n\
\n\
echo "=== RDI Configuration Complete ==="\n\
\n\
# Keep container running\n\
tail -f /dev/null\n\
' > /start-rdi.sh && chmod +x /start-rdi.sh

# Switch to labuser
USER labuser
WORKDIR /home/labuser

CMD ["/start-rdi.sh"]
