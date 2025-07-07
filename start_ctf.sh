#!/bin/bash

# Redis RDI CTF Startup Script
# This script starts the Redis RDI CTF environment with separate containers

set -e

echo "🚀 Starting Redis RDI CTF Environment..."

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker and try again."
    exit 1
fi

# Check if Docker Compose is available
if ! command -v docker-compose > /dev/null 2>&1; then
    echo "❌ Docker Compose is not installed. Please install Docker Compose and try again."
    exit 1
fi

echo "🔨 Building and starting containers..."

# Start containers
docker-compose up -d --build

# Wait for services to be ready
echo "⏳ Waiting for services to start..."
sleep 15

# Check service health
echo "🔍 Checking service health..."

# Check PostgreSQL
echo -n "PostgreSQL: "
if docker exec rdi-ctf-postgres pg_isready -U postgres -d musicstore > /dev/null 2>&1; then
    echo "✅ Ready"
else
    echo "❌ Not ready"
fi

# Check Redis Insight
echo -n "Redis Insight: "
if curl -s http://localhost:5540 > /dev/null; then
    echo "✅ Ready"
else
    echo "❌ Not ready"
fi

# Check RDI CLI
echo -n "RDI CLI: "
if docker exec rdi-ctf-cli redis-di --version > /dev/null 2>&1; then
    echo "✅ Ready"
else
    echo "❌ Not ready"
fi

# Check Web Interface
echo -n "Web Interface: "
if curl -s http://localhost:8080 > /dev/null; then
    echo "✅ Ready"
else
    echo "❌ Not ready"
fi

echo ""
echo "🎯 Redis RDI CTF is ready!"
echo ""
echo "📊 CTF Dashboard: http://localhost:8080"
echo "🔍 Redis Insight: http://localhost:5540"
echo "🗄️ PostgreSQL: localhost:5432 (musicstore/postgres/postgres)"
echo ""
echo "📋 Next Steps:"
echo "1. Sign up for Redis Cloud: https://redis.com/try-free/"
echo "2. Create a Redis database and get connection details"
echo "3. Configure RDI with your Redis Cloud connection:"
echo "   docker exec -it rdi-ctf-cli cp /config/config.yaml.template /config/config.yaml"
echo "   docker exec -it rdi-ctf-cli nano /config/config.yaml"
echo "4. Start with Lab 01 in the web interface"
echo ""
echo "🛑 To stop the environment: ./stop_ctf.sh"
echo ""
