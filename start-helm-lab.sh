#!/usr/bin/env bash
set -euo pipefail

echo "🚀 Starting Redis RDI CTF Lab with Helm-based RDI"
echo "=================================================="

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    echo "   Visit: https://docs.docker.com/get-docker/"
    exit 1
fi

# Check if Docker Compose is available
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo "❌ Docker Compose is not available. Please install Docker Compose."
    exit 1
fi

# Determine Docker Compose command
if command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE="docker-compose"
else
    DOCKER_COMPOSE="docker compose"
fi

echo "🐳 Building and starting containers..."
$DOCKER_COMPOSE -f docker-compose-helm.yml up -d --build

echo "⏳ Waiting for services to be ready..."
sleep 10

# Wait for PostgreSQL to be ready
echo "🗄️  Waiting for PostgreSQL..."
until docker exec rdi-postgres-helm pg_isready -U postgres -d chinook &>/dev/null; do
    echo "   Still waiting for PostgreSQL..."
    sleep 5
done
echo "✅ PostgreSQL is ready"

# Wait for RDI container to be ready
echo "🔧 Waiting for RDI Helm container..."
sleep 15
echo "✅ RDI Helm container is ready"

echo ""
echo "🎉 Redis RDI CTF Lab is now running!"
echo "===================================="
echo ""
echo "📊 Access Points:"
echo "   🌐 Web Interface:     http://localhost:8082"
echo "   🔍 Redis Insight:     http://localhost:5541"
echo "   📋 Log Viewer:        http://localhost:8083"
echo "   🗄️  PostgreSQL:        localhost:5433 (postgres/postgres)"
echo ""
echo "🔧 RDI Configuration:"
echo "   1. Access RDI container: docker exec -it rdi-helm bash"
echo "   2. Configure RDI:        cd /rdi && ./configure-rdi-values.sh"
echo "   3. Install RDI:          ./install-rdi-helm.sh --skip-download"
echo ""
echo "💡 Custom Redis Connection:"
echo "   Set environment variables before starting:"
echo "   export REDIS_HOST=your-redis-host"
echo "   export REDIS_PORT=your-redis-port"
echo "   export REDIS_PASSWORD=your-redis-password"
echo ""
echo "🛑 To stop the lab: ./stop-helm-lab.sh"
