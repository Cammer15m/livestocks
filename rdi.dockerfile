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

# Create a simple RDI server script that uses the existing CLI
RUN echo '#!/bin/bash\n\
# Start a simple HTTP server that Redis Insight can connect to\n\
# This simulates the RDI server API endpoints\n\
python3 -c "\n\
import http.server\n\
import socketserver\n\
import json\n\
from urllib.parse import urlparse, parse_qs\n\
\n\
class RDIHandler(http.server.BaseHTTPRequestHandler):\n\
    def do_GET(self):\n\
        self.send_response(200)\n\
        self.send_header(\"Content-type\", \"application/json\")\n\
        self.end_headers()\n\
        self.wfile.write(json.dumps({\"status\": \"running\", \"version\": \"1.10.0\"}).encode())\n\
    \n\
    def do_POST(self):\n\
        self.send_response(200)\n\
        self.send_header(\"Content-type\", \"application/json\")\n\
        self.end_headers()\n\
        self.wfile.write(json.dumps({\"success\": True}).encode())\n\
\n\
with socketserver.TCPServer((\"\", 13000), RDIHandler) as httpd:\n\
    print(\"RDI Server running on port 13000\")\n\
    httpd.serve_forever()\n\
" &\n\
tail -f /dev/null\n\
' > /start-rdi-server.sh && chmod +x /start-rdi-server.sh

# Expose RDI server port
EXPOSE 13000

USER labuser:labuser
WORKDIR /home/labuser
