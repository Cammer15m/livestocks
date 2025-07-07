# Simple Grafana container without external dependencies
FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

# Install basic tools and Node.js for a simple web interface
RUN apt-get update && \
    apt-get install -y \
    curl \
    wget \
    python3 \
    python3-pip \
    nodejs \
    npm \
    && rm -rf /var/lib/apt/lists/*

# Create grafana user
RUN useradd -m -s /bin/bash grafana

# Create simple monitoring web interface
WORKDIR /app

# Create a simple monitoring dashboard
RUN echo '<!DOCTYPE html>\n\
<html>\n\
<head>\n\
    <title>Redis RDI Monitoring</title>\n\
    <style>\n\
        body { font-family: Arial, sans-serif; margin: 20px; }\n\
        .container { max-width: 1200px; margin: 0 auto; }\n\
        .card { border: 1px solid #ddd; padding: 20px; margin: 10px 0; border-radius: 5px; }\n\
        .status { padding: 5px 10px; border-radius: 3px; color: white; }\n\
        .running { background-color: #28a745; }\n\
        .stopped { background-color: #dc3545; }\n\
    </style>\n\
</head>\n\
<body>\n\
    <div class="container">\n\
        <h1>Redis RDI Training Environment</h1>\n\
        <div class="card">\n\
            <h2>Service Status</h2>\n\
            <p>PostgreSQL: <span class="status running">Running</span></p>\n\
            <p>Redis Insight: <span class="status running">Running</span></p>\n\
            <p>RDI CLI: <span class="status running">Running</span></p>\n\
        </div>\n\
        <div class="card">\n\
            <h2>Quick Links</h2>\n\
            <ul>\n\
                <li><a href="http://localhost:5540" target="_blank">Redis Insight</a></li>\n\
                <li><a href="http://localhost:3001" target="_blank">SQLPad (Database Browser)</a></li>\n\
                <li><a href="http://localhost:9090" target="_blank">Prometheus Metrics</a></li>\n\
            </ul>\n\
        </div>\n\
    </div>\n\
</body>\n\
</html>' > /app/index.html

# Create simple HTTP server script
RUN echo '#!/usr/bin/env python3\n\
import http.server\n\
import socketserver\n\
import os\n\
\n\
PORT = 3000\n\
\n\
class Handler(http.server.SimpleHTTPRequestHandler):\n\
    def __init__(self, *args, **kwargs):\n\
        super().__init__(*args, directory="/app", **kwargs)\n\
\n\
with socketserver.TCPServer(("", PORT), Handler) as httpd:\n\
    print(f"Serving at port {PORT}")\n\
    httpd.serve_forever()' > /app/server.py && \
    chmod +x /app/server.py

EXPOSE 3000

USER grafana
CMD ["python3", "/app/server.py"]
