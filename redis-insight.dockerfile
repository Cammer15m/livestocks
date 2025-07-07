# Simple Redis Insight alternative without external dependencies
FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

# Install basic tools
RUN apt-get update && \
    apt-get install -y \
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Install Redis Python client
RUN pip3 install redis flask

# Create redis-insight user
RUN useradd -m -s /bin/bash redis-insight

WORKDIR /app

# Create simple Redis connection interface
COPY redis-insight-app.py /app/redis_insight.py

EXPOSE 5540

USER redis-insight
CMD ["python3", "/app/redis_insight.py"]
