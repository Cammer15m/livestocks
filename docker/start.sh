#!/bin/bash
set -e

echo "🚀 Starting Redis RDI CTF Container..."

# Initialize PostgreSQL if needed
if [ ! -f /var/lib/postgresql/14/main/PG_VERSION ]; then
    echo "📊 Initializing PostgreSQL..."
    sudo -u postgres /usr/lib/postgresql/14/bin/initdb -D /var/lib/postgresql/14/main
fi

# Start PostgreSQL temporarily to set up database
echo "🗄️ Starting PostgreSQL..."
sudo -u postgres /usr/lib/postgresql/14/bin/pg_ctl -D /var/lib/postgresql/14/main -l /var/log/postgresql.log start

# Wait for PostgreSQL to be ready
echo "⏳ Waiting for PostgreSQL to be ready..."
for i in {1..30}; do
    if sudo -u postgres psql -c "SELECT 1;" >/dev/null 2>&1; then
        echo "✅ PostgreSQL is ready"
        break
    fi
    if [ $i -eq 30 ]; then
        echo "❌ PostgreSQL failed to start"
        exit 1
    fi
    sleep 1
done

# Check if database exists, create if not
if ! sudo -u postgres psql -lqt | cut -d \| -f 1 | grep -qw rdi_db; then
    echo "🔧 Setting up CTF database..."
    sudo -u postgres psql -c "CREATE USER rdi_user WITH PASSWORD 'rdi_password';" || true
    sudo -u postgres psql -c "CREATE DATABASE rdi_db OWNER rdi_user;" || true
    sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE rdi_db TO rdi_user;" || true
    
    # Load sample data
    echo "🎵 Loading sample music data..."
    PGPASSWORD='rdi_password' psql -U rdi_user -d rdi_db -h localhost < /app/seed/music_database.sql
    
    # Get counts
    track_count=$(PGPASSWORD='rdi_password' psql -U rdi_user -d rdi_db -h localhost -t -c 'SELECT COUNT(*) FROM "Track";' | xargs)
    album_count=$(PGPASSWORD='rdi_password' psql -U rdi_user -d rdi_db -h localhost -t -c 'SELECT COUNT(*) FROM "Album";' | xargs)
    echo "✅ Loaded $track_count tracks from $album_count albums"
else
    echo "✅ Database already exists"
fi

# Stop PostgreSQL (supervisor will restart it)
sudo -u postgres /usr/lib/postgresql/14/bin/pg_ctl -D /var/lib/postgresql/14/main stop

# Create .env file if it doesn't exist
if [ ! -f /app/.env ]; then
    echo "📝 Creating default .env file..."
    cp /app/.env.template /app/.env
fi

# Show startup information
echo ""
echo "🎉 Redis RDI CTF Container Started!"
echo "=================================="
echo ""
echo "📊 Services:"
echo "  • RDI Web UI: http://localhost:8080"
echo "  • PostgreSQL: Available via container shell"
echo ""
echo "🔗 Database Connection:"
echo "  • Host: localhost"
echo "  • Port: 5432"
echo "  • Database: rdi_db"
echo "  • User: rdi_user"
echo "  • Password: rdi_password"
echo ""
echo "⚙️ Configuration:"
echo "  • Edit /app/.env to configure Redis connection"
echo "  • Default connects to localhost:6379"
echo ""
echo "🚀 Getting Started:"
echo "  1. Open: http://localhost:8080"
echo "  2. Configure Redis connection in .env"
echo "  3. Enter container: docker exec -it redis-rdi-ctf bash"
echo "  4. Run: python3 scripts/rdi_connector.py"
echo "  5. Start Lab 1: cd labs/01_postgres_to_redis"
echo ""

# Start supervisor to manage all services
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
