#!/bin/bash
set -e

echo "🐳 Building and Testing Redis RDI CTF Docker Container"
echo "====================================================="

# Build the container
echo "🔨 Building container..."
docker compose build

# Start the container
echo "🚀 Starting container..."
docker compose up -d

# Wait for container to be ready
echo "⏳ Waiting for services to start..."
sleep 30

# Test PostgreSQL connection
echo "🗄️ Testing PostgreSQL connection..."
if docker exec redis-rdi-ctf pg_isready -U rdi_user -d rdi_db -h localhost; then
    echo "✅ PostgreSQL is ready"
else
    echo "❌ PostgreSQL connection failed"
    exit 1
fi

# Test database content
echo "🎵 Testing database content..."
track_count=$(docker exec redis-rdi-ctf bash -c "PGPASSWORD='rdi_password' psql -U rdi_user -d rdi_db -h localhost -t -c 'SELECT COUNT(*) FROM \"Track\";'" | xargs)
echo "📊 Found $track_count tracks in database"

if [ "$track_count" -gt 0 ]; then
    echo "✅ Sample data loaded successfully"
else
    echo "❌ No sample data found"
    exit 1
fi

# Test web interface
echo "🌐 Testing web interface..."
if curl -f http://localhost:8080 >/dev/null 2>&1; then
    echo "✅ Web interface is accessible"
else
    echo "⚠️ Web interface not yet ready (may need more time)"
fi

# Show container logs
echo "📋 Container logs:"
docker logs redis-rdi-ctf --tail 20

echo ""
echo "🎉 Container is ready!"
echo "====================="
echo ""
echo "🔗 Access points:"
echo "  • Web UI: http://localhost:8080"
echo "  • SQLPad: http://localhost:3001"
echo "  • PostgreSQL: localhost:5432"
echo ""
echo "🚀 Next steps:"
echo "  1. Configure Redis in .env file"
echo "  2. docker exec -it redis-rdi-ctf bash"
echo "  3. cd labs/01_postgres_to_redis"
echo "  4. Start the CTF!"
echo ""
echo "🧹 To stop: docker compose down"
