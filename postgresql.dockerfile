# Use a base Ubuntu image to avoid external pulls
FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

# Install PostgreSQL
RUN apt-get update && \
    apt-get install -y \
    postgresql-12 \
    postgresql-contrib-12 \
    postgresql-client-12 \
    && rm -rf /var/lib/apt/lists/*

# Set up PostgreSQL user and directories
RUN useradd -m postgres && \
    mkdir -p /var/lib/postgresql/data && \
    chown -R postgres:postgres /var/lib/postgresql && \
    mkdir -p /var/run/postgresql && \
    chown -R postgres:postgres /var/run/postgresql

# Configure PostgreSQL
RUN echo "host all all 0.0.0.0/0 md5" >> /etc/postgresql/12/main/pg_hba.conf && \
    echo "listen_addresses='*'" >> /etc/postgresql/12/main/postgresql.conf && \
    echo "wal_level = logical" >> /etc/postgresql/12/main/postgresql.conf && \
    echo "max_replication_slots = 10" >> /etc/postgresql/12/main/postgresql.conf && \
    echo "max_wal_senders = 10" >> /etc/postgresql/12/main/postgresql.conf

# Copy initialization script
COPY create_track_table.sql /docker-entrypoint-initdb.d/

# Create startup script
RUN echo '#!/bin/bash\n\
service postgresql start\n\
sudo -u postgres createdb chinook 2>/dev/null || true\n\
sudo -u postgres psql -c "ALTER USER postgres PASSWORD '\''postgres'\'';" 2>/dev/null || true\n\
sudo -u postgres psql -d chinook -f /docker-entrypoint-initdb.d/create_track_table.sql 2>/dev/null || true\n\
tail -f /var/log/postgresql/postgresql-12-main.log' > /start.sh && \
    chmod +x /start.sh

EXPOSE 5432

USER postgres
CMD ["/start.sh"]
