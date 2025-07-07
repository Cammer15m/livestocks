#!/bin/bash

echo "🚀 Redis RDI Training - Quick Start"
echo "=================================="
echo ""

# Check if .env exists
if [ ! -f .env ]; then
    echo "⚠️  No .env file found. Creating from template..."
    cp .env.template .env
    echo ""
    echo "📝 Please edit .env with your Redis Cloud details:"
    echo "   - REDIS_HOST (from Redis Cloud dashboard)"
    echo "   - REDIS_PORT (from Redis Cloud dashboard)" 
    echo "   - REDIS_PASSWORD (from Redis Cloud dashboard)"
    echo ""
    echo "Then run this script again."
    exit 1
fi

echo "✅ Environment file found"
echo "🐳 Starting containers..."
echo ""

# Start the simplified environment
docker-compose -f docker-compose-cloud.yml up -d

echo ""
echo "⏳ Waiting for services to start..."
sleep 15

echo ""
echo "🎉 Environment ready!"
echo ""
echo "🔧 Setting up RDI pipeline automatically..."
./setup-rdi.sh

echo ""
echo "🎯 All done! Your Redis RDI training environment is ready!"
echo ""
echo "📊 Dashboard: http://localhost:8080"
echo "🔍 Redis Insight: http://localhost:5540"
echo ""
echo "🧪 Test data flow:"
echo "   docker exec -it rdi-loadgen python /scripts/generate_load.py"
echo ""
