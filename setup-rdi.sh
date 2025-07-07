#!/bin/bash

echo "🔧 Setting up RDI pipeline..."

# Wait for PostgreSQL to be ready
echo "⏳ Waiting for PostgreSQL..."
docker exec rdi-cli bash -c 'while ! pg_isready -h postgresql -p 5432 -U postgres; do sleep 2; done'

# Substitute environment variables in config
echo "📝 Configuring RDI with environment variables..."
docker exec rdi-cli bash -c 'envsubst < /config/config-cloud.yaml > /tmp/config.yaml'

# Configure RDI
echo "⚙️ Configuring RDI..."
docker exec rdi-cli redis-di configure --rdi-host localhost:13000 --rdi-password redislabs

# Deploy the configuration
echo "🚀 Deploying RDI pipeline..."
docker exec rdi-cli redis-di deploy --config /tmp/config.yaml

# Start RDI
echo "▶️ Starting RDI..."
docker exec rdi-cli redis-di start

# Check status
echo "📊 Checking RDI status..."
docker exec rdi-cli redis-di status

echo ""
echo "✅ RDI setup complete!"
echo "🎯 Start load generator: docker exec -it rdi-loadgen python /scripts/generate_load.py"
echo "🔍 Monitor at: http://localhost:5540 (Redis Insight)"
