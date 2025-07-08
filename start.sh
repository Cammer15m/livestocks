#!/bin/bash

echo "🚀 Redis RDI Training Environment"
echo "=================================="
echo ""

# Redis Setup Options
echo "Redis Setup Options:"
echo "1. Use shared Redis database (3.148.243.197:13000 - ready to use)"
echo "2. Use Redis Cloud (your own Redis Cloud instance)"
echo "3. Use local Redis (quick setup, no external dependencies)"
echo ""
read -p "Choose option (1 for Shared, 2 for Cloud, 3 for Local): " redis_option

if [[ "$redis_option" == "1" ]]; then
    echo ""
    echo "✅ Using shared Redis database"
    echo "   Host: 3.148.243.197:13000"
    echo "   User: default"
    echo ""

    # Create .env file for shared Redis
    cat > .env << EOF
# Shared Redis Configuration
REDIS_HOST=3.148.243.197
REDIS_PORT=13000
REDIS_PASSWORD=redislabs
REDIS_USER=default
EOF

    echo "[SUCCESS] Shared Redis configuration saved"
    USE_CLOUD=true
elif [[ "$redis_option" == "2" ]]; then
    echo ""
    echo "Redis Cloud Setup:"
    echo "Please provide your Redis Cloud connection string."
    echo "Format: redis://default:password@host:port"
    echo "You can find this in your Redis Cloud dashboard under 'Connect'"
    echo ""
    read -p "Redis Cloud connection string: " redis_cloud_url

    if [[ -n "$redis_cloud_url" ]]; then
        # Parse the connection string
        if [[ "$redis_cloud_url" =~ redis://([^:]+):([^@]+)@([^:]+):([0-9]+) ]]; then
            export REDIS_USER="${BASH_REMATCH[1]}"
            export REDIS_PASSWORD="${BASH_REMATCH[2]}"
            export REDIS_HOST="${BASH_REMATCH[3]}"
            export REDIS_PORT="${BASH_REMATCH[4]}"

            # Create .env file
            cat > .env << EOF
# Redis Cloud Configuration
REDIS_HOST=$REDIS_HOST
REDIS_PORT=$REDIS_PORT
REDIS_PASSWORD=$REDIS_PASSWORD
REDIS_USER=$REDIS_USER
EOF

            echo "[SUCCESS] Redis Cloud configuration saved"
            echo "   Host: $REDIS_HOST:$REDIS_PORT"
            echo "   User: $REDIS_USER"
            echo ""
            USE_CLOUD=true
        else
            echo "[ERROR] Invalid Redis Cloud URL format"
            echo "Expected format: redis://default:password@host:port"
            exit 1
        fi
    else
        echo "[ERROR] Redis Cloud connection string is required"
        exit 1
    fi
elif [[ "$redis_option" == "3" ]]; then
    echo ""
    echo "✅ Using local Redis setup"
    USE_CLOUD=false
else
    echo "❌ Invalid option. Please choose 1, 2, or 3."
    exit 1
fi

echo "✅ Environment configured"
echo "🐳 Starting containers..."
echo ""

# Start appropriate environment based on choice
if [[ "$USE_CLOUD" == "true" ]]; then
    echo "Starting cloud-based environment..."
    docker-compose -f docker-compose-cloud.yml up -d --build

    echo ""
    echo "⏳ Waiting for services to start..."
    sleep 15

    echo ""
    echo "🎉 Environment ready!"
    echo ""
    echo "📊 Dashboard: http://localhost:8080"
    echo "🔍 Redis Insight: http://localhost:5540 (connect to your Redis Cloud)"
    echo ""
    echo "🧪 Test data flow:"
    echo "   docker exec -w /scripts rdi-loadgen python3 generate_load.py"
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