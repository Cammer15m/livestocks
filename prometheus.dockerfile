# Simple Prometheus alternative without external dependencies
FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

# Install basic tools
RUN apt-get update && \
    apt-get install -y \
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Install Flask for simple metrics endpoint
RUN pip3 install flask

# Create prometheus user
RUN useradd -m -s /bin/bash prometheus

WORKDIR /app

# Create simple metrics server
RUN echo 'from flask import Flask, Response\n\
import time\n\
import random\n\
\n\
app = Flask(__name__)\n\
\n\
@app.route("/metrics")\n\
def metrics():\n\
    # Generate simple metrics\n\
    metrics_data = f"""# HELP rdi_training_up RDI Training Environment Status\n\
# TYPE rdi_training_up gauge\n\
rdi_training_up 1\n\
\n\
# HELP rdi_containers_running Number of running containers\n\
# TYPE rdi_containers_running gauge\n\
rdi_containers_running {random.randint(4, 6)}\n\
\n\
# HELP rdi_postgres_connections PostgreSQL connections\n\
# TYPE rdi_postgres_connections gauge\n\
rdi_postgres_connections {random.randint(1, 5)}\n\
\n\
# HELP rdi_redis_keys Redis keys count\n\
# TYPE rdi_redis_keys gauge\n\
rdi_redis_keys {random.randint(100, 1000)}\n\
\n\
# HELP rdi_sync_lag_seconds RDI sync lag in seconds\n\
# TYPE rdi_sync_lag_seconds gauge\n\
rdi_sync_lag_seconds {random.uniform(0.1, 2.0):.2f}\n\
"""\n\
    return Response(metrics_data, mimetype="text/plain")\n\
\n\
@app.route("/")\n\
def index():\n\
    return """<!DOCTYPE html>\n\
<html>\n\
<head><title>Prometheus - RDI Training</title></head>\n\
<body>\n\
    <h1>Prometheus Metrics - RDI Training</h1>\n\
    <p><a href="/metrics">View Metrics</a></p>\n\
    <p>This is a simplified metrics endpoint for the RDI training environment.</p>\n\
</body>\n\
</html>"""\n\
\n\
if __name__ == "__main__":\n\
    print("📊 Prometheus metrics server starting on http://0.0.0.0:9090")\n\
    app.run(host="0.0.0.0", port=9090, debug=False)' > /app/prometheus.py

EXPOSE 9090

USER prometheus
CMD ["python3", "/app/prometheus.py"]
