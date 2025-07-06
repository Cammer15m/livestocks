FROM ubuntu:22.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    postgresql \
    postgresql-contrib \
    python3 \
    python3-pip \
    python3-venv \
    curl \
    wget \
    git \
    nano \
    vim \
    supervisor \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Create Python virtual environment
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Copy requirements and install Python dependencies
COPY requirements.txt /app/
RUN pip install --no-cache-dir -r requirements.txt

# Copy all project files
COPY . /app/

# Set up PostgreSQL
RUN service postgresql start && \
    sleep 5 && \
    sudo -u postgres psql -c "CREATE USER rdi_user WITH PASSWORD 'rdi_password';" && \
    sudo -u postgres psql -c "CREATE DATABASE rdi_db OWNER rdi_user;" && \
    sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE rdi_db TO rdi_user;" && \
    sleep 2 && \
    PGPASSWORD='rdi_password' psql -U rdi_user -d rdi_db -h localhost < seed/music_database.sql && \
    service postgresql stop

# Create supervisor configuration
RUN mkdir -p /var/log/supervisor

# Copy supervisor configuration
COPY docker/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Create startup script
COPY docker/start.sh /app/start.sh
RUN chmod +x /app/start.sh

# Create environment file template
RUN echo "# Redis RDI CTF Environment Configuration" > /app/.env.template && \
    echo "# Copy this to .env and configure your Redis connection" >> /app/.env.template && \
    echo "" >> /app/.env.template && \
    echo "# Redis Connection (required)" >> /app/.env.template && \
    echo "REDIS_HOST=localhost" >> /app/.env.template && \
    echo "REDIS_PORT=6379" >> /app/.env.template && \
    echo "REDIS_PASSWORD=" >> /app/.env.template && \
    echo "# Or use Redis Cloud URL:" >> /app/.env.template && \
    echo "# REDIS_URL=redis://username:password@host:port" >> /app/.env.template && \
    echo "" >> /app/.env.template && \
    echo "# PostgreSQL (pre-configured in container)" >> /app/.env.template && \
    echo "DB_HOST=localhost" >> /app/.env.template && \
    echo "DB_PORT=5432" >> /app/.env.template && \
    echo "DB_NAME=rdi_db" >> /app/.env.template && \
    echo "DB_USER=rdi_user" >> /app/.env.template && \
    echo "DB_PASSWORD=rdi_password" >> /app/.env.template

# Make scripts executable
RUN chmod +x scripts/*.sh scripts/*.py

# Expose ports
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD pg_isready -U rdi_user -d rdi_db -h localhost || exit 1

# Start services
CMD ["/app/start.sh"]
