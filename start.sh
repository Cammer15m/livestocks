#!/bin/bash

echo "🚀 Redis RDI Training Environment"
echo "=================================="
echo ""

# Silently configure shared Redis database for RDI metadata
cat > .env << EOF
# Shared Redis Configuration (automatically configured)
REDIS_HOST=3.148.243.197
REDIS_PORT=13000
REDIS_PASSWORD=redislabs
REDIS_USER=default
EOF

USE_CLOUD=true

echo "✅ Environment configured"
echo "🐳 Starting containers..."
echo ""

# Start appropriate environment based on choice
if [[ "$USE_CLOUD" == "true" ]]; then
    echo "Starting cloud-based environment..."

    # Clean up any existing containers first
    docker-compose -f docker-compose-cloud.yml down --remove-orphans 2>/dev/null || true

    if ! docker-compose -f docker-compose-cloud.yml up -d --build; then
        echo "❌ Failed to start containers. Checking logs..."
        docker-compose -f docker-compose-cloud.yml logs
        exit 1
    fi

    echo ""
    echo "⏳ Waiting for services to start..."
    sleep 15

    echo ""
    echo "🔍 Checking container status..."
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

    echo ""
    echo "🎉 Environment ready!"
    echo ""
    echo "📊 Dashboard: http://localhost:8080"
    echo "🔍 Redis Insight: http://localhost:5540 (connect to shared Redis: 3.148.243.197:13000)"
    echo ""
    echo "🧪 Test RDI:"
    echo "   docker exec -it rdi-cli redis-di --help"
    echo "   docker exec -it rdi-cli redis-di status"
else
    echo "Starting local Redis environment..."
    docker-compose up -d --build

    echo ""
    echo "⏳ Waiting for services to start..."
    sleep 30

    echo ""
    echo "🎉 Environment ready!"
    echo ""
    echo "📊 Redis Enterprise: https://localhost:8443 (admin@rl.org / redislabs)"
    echo "🔍 Redis Insight: http://localhost:5540"
    echo "📈 Grafana: http://localhost:3000 (admin / redislabs)"
    echo "🗄️ SQLPad: http://localhost:3001 (admin@rl.org / redislabs)"
    echo ""
    echo "🧪 Test data flow:"
    echo "   docker exec -w /scripts rdi-loadgen python3 generate_load.py"
fi
echo ""