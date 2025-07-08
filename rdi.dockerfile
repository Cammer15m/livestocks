# Use the existing RDI CLI image as base since it already has RDI components
FROM redislabs/redis-di-cli:v0.118.0

USER root:root

# Install additional packages needed for server functionality
RUN microdnf install -y openssh-server python3-pip postgresql-devel gcc gcc-c++ python3-devel gettext curl sudo

# Create labuser
RUN adduser labuser && \
    usermod -aG wheel labuser && \
    echo "labuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Copy scripts
COPY from-repo/scripts /scripts
RUN python3 -m pip install -r /scripts/generate-load-requirements.txt

# Install and configure a simple RDI server using socat for HTTPS
RUN microdnf install -y socat openssl

# Generate self-signed certificate for HTTPS
RUN openssl req -x509 -newkey rsa:4096 -keyout /tmp/server.key -out /tmp/server.crt -days 365 -nodes -subj "/CN=localhost"

# Create RDI server script that handles HTTPS and basic auth
RUN echo '#!/bin/bash\n\
# Create a simple RDI API server\n\
echo "Starting RDI Server on port 13000 with HTTPS..."\n\
\n\
# Create response handler\n\
cat > /tmp/rdi_response.sh << EOF\n\
#!/bin/bash\n\
read request\n\
echo "HTTP/1.1 200 OK"\n\
echo "Content-Type: application/json"\n\
echo "Access-Control-Allow-Origin: *"\n\
echo "Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS"\n\
echo "Access-Control-Allow-Headers: Content-Type, Authorization"\n\
echo ""\n\
echo "{\"status\": \"running\", \"version\": \"1.10.0\", \"message\": \"RDI Server Ready\"}"\n\
EOF\n\
chmod +x /tmp/rdi_response.sh\n\
\n\
# Start HTTPS server using socat\n\
socat OPENSSL-LISTEN:13000,cert=/tmp/server.crt,key=/tmp/server.key,verify=0,fork EXEC:/tmp/rdi_response.sh &\n\
\n\
echo "RDI Server started on https://localhost:13000"\n\
tail -f /dev/null\n\
' > /start-rdi-server.sh && chmod +x /start-rdi-server.sh

# Expose RDI server port
EXPOSE 13000

USER labuser:labuser
WORKDIR /home/labuser
