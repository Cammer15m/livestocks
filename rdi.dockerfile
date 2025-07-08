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

# Create a Python-based RDI server that mimics the real RDI API
RUN echo '#!/bin/bash\n\
python3 -c "\n\
import http.server\n\
import ssl\n\
import json\n\
import base64\n\
from urllib.parse import urlparse, parse_qs\n\
\n\
class RDIHandler(http.server.BaseHTTPRequestHandler):\n\
    def do_OPTIONS(self):\n\
        self.send_response(200)\n\
        self.send_header(\"Access-Control-Allow-Origin\", \"*\")\n\
        self.send_header(\"Access-Control-Allow-Methods\", \"GET, POST, PUT, DELETE, OPTIONS\")\n\
        self.send_header(\"Access-Control-Allow-Headers\", \"Content-Type, Authorization\")\n\
        self.end_headers()\n\
    \n\
    def do_GET(self):\n\
        # Basic auth check\n\
        auth_header = self.headers.get(\"Authorization\")\n\
        if not auth_header or not auth_header.startswith(\"Basic \"):\n\
            self.send_response(401)\n\
            self.send_header(\"WWW-Authenticate\", \"Basic realm=RDI\")\n\
            self.end_headers()\n\
            return\n\
        \n\
        self.send_response(200)\n\
        self.send_header(\"Content-type\", \"application/json\")\n\
        self.send_header(\"Access-Control-Allow-Origin\", \"*\")\n\
        self.end_headers()\n\
        \n\
        if self.path == \"/api/v1/status\":\n\
            response = {\"status\": \"running\", \"version\": \"1.10.0\"}\n\
        else:\n\
            response = {\"message\": \"RDI Server Ready\"}\n\
        \n\
        self.wfile.write(json.dumps(response).encode())\n\
    \n\
    def do_POST(self):\n\
        self.send_response(200)\n\
        self.send_header(\"Content-type\", \"application/json\")\n\
        self.send_header(\"Access-Control-Allow-Origin\", \"*\")\n\
        self.end_headers()\n\
        self.wfile.write(json.dumps({\"success\": True}).encode())\n\
\n\
# Create SSL context with self-signed cert\n\
import tempfile\n\
import os\n\
os.system(\"openssl req -x509 -newkey rsa:2048 -keyout /tmp/key.pem -out /tmp/cert.pem -days 365 -nodes -subj '/CN=localhost'\")\n\
\n\
httpd = http.server.HTTPServer((\"\", 13000), RDIHandler)\n\
context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)\n\
context.load_cert_chain(\"/tmp/cert.pem\", \"/tmp/key.pem\")\n\
httpd.socket = context.wrap_socket(httpd.socket, server_side=True)\n\
\n\
print(\"RDI Server running on https://localhost:13000\")\n\
httpd.serve_forever()\n\
" &\n\
tail -f /dev/null\n\
' > /start-rdi-server.sh && chmod +x /start-rdi-server.sh

# Expose RDI server port
EXPOSE 13000

USER labuser:labuser
WORKDIR /home/labuser
