#!/bin/bash

echo "🚀 Redis RDI Training - Streamlined Setup"
echo "=========================================="
echo ""

# Redis Cloud Configuration
echo "Redis Cloud Setup:"
echo "You'll need a Redis Cloud instance to complete this training."
echo "Get a free account at: https://redis.io/try-free"
echo ""

# Check if .env exists and has real values
if [ -f .env ] && grep -q "redis-.*\.redns\.redis-cloud\.com" .env; then
    echo "✅ Redis Cloud configuration found in .env"
    read -p "Do you want to use the existing configuration? (Y/n): " use_existing
    if [[ "$use_existing" =~ ^[Nn]$ ]]; then
        rm .env
    fi
fi

# Prompt for Redis Cloud details if needed
if [ ! -f .env ] || ! grep -q "redis-.*\.redns\.redis-cloud\.com" .env; then
    echo ""
    echo "Please provide your Redis Cloud connection details:"
    echo "(You can find these in your Redis Cloud dashboard under 'Connect')"
    echo ""

    read -p "Redis Cloud Host (e.g., redis-12345.c123.us-east-1-1.ec2.redns.redis-cloud.com): " redis_host
    read -p "Redis Cloud Port (e.g., 12345): " redis_port
    read -p "Redis Cloud Password: " redis_password
    read -p "Redis Cloud Username (usually 'default'): " redis_user

    # Set default username if empty
    [ -z "$redis_user" ] && redis_user="default"

    # Validate inputs
    if [[ -z "$redis_host" || -z "$redis_port" || -z "$redis_password" ]]; then
        echo "❌ Error: All fields are required (except username which defaults to 'default')"
        exit 1
    fi

    # Create .env file
    cat > .env << EOF
# Redis Cloud Configuration
REDIS_HOST=$redis_host
REDIS_PORT=$redis_port
REDIS_PASSWORD=$redis_password
REDIS_USER=$redis_user
EOF

    echo ""
    echo "✅ Redis Cloud configuration saved to .env"
fi

echo "✅ Environment configured"
echo "🐳 Starting containers..."
echo ""

# Start the streamlined environment
docker-compose -f docker-compose-cloud.yml up -d --build

echo ""
echo "⏳ Waiting for services to start..."
sleep 15

echo ""
echo "🎉 Environment ready!"
echo ""
echo "🎯 All done! Your Redis RDI training environment is ready!"
echo ""
echo "📊 Dashboard: http://localhost:8080"
echo "🔍 Redis Insight: http://localhost:5540"
echo ""
echo "🧪 Test data flow:"
echo "   docker exec -w /scripts rdi-loadgen python3 generate_load.py"
echo ""


