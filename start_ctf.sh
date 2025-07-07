#!/bin/bash

# Redis RDI CTF Startup Script
# Shows startup logs for verification, then keeps container running in background

set -e  # Exit on any error

echo "🚀 Starting Redis RDI CTF..."
echo "📋 This will show startup logs, then run in background if successful"
echo ""

# Check if Redis is configured
if grep -q "REDIS_URL=redis://username:password@host:port" .env; then
    echo "🔧 Redis Cloud configuration needed!"
    echo ""
    echo "Options:"
    echo "1. Configure Redis Cloud (recommended - free account at redis.com)"
    echo "2. Use local Redis (will start Redis container automatically)"
    echo ""
    read -p "Choose option (1 or 2): " redis_option

    if [ "$redis_option" = "1" ]; then
        echo ""
        echo "📝 Please provide your Redis Cloud connection details:"
        echo "   (Get these from your Redis Cloud dashboard)"
        echo ""
        read -p "Redis Host (e.g., redis-12345.c1.us-east-1-1.ec2.cloud.redislabs.com): " redis_host
        read -p "Redis Port (usually 12345): " redis_port
        read -p "Redis Username (usually 'default'): " redis_username
        read -s -p "Redis Password: " redis_password
        echo ""

        # Update .env file
        redis_url="redis://${redis_username}:${redis_password}@${redis_host}:${redis_port}"
        sed -i "s|REDIS_URL=redis://username:password@host:port|REDIS_URL=${redis_url}|" .env

        echo "✅ Redis Cloud configuration saved to .env"
        echo ""

    elif [ "$redis_option" = "2" ]; then
        echo ""
        echo "🐳 Configuring for local Redis..."

        # Comment out REDIS_URL and uncomment local settings
        sed -i 's/^REDIS_URL=/#REDIS_URL=/' .env
        sed -i 's/^# REDIS_HOST=/REDIS_HOST=/' .env
        sed -i 's/^# REDIS_PORT=/REDIS_PORT=/' .env
        sed -i 's/^# REDIS_PASSWORD=/REDIS_PASSWORD=/' .env

        echo "✅ Local Redis configuration saved to .env"
        echo "🚀 Will start with local Redis container"
        echo ""

        # Use local redis profile
        COMPOSE_PROFILES="local-redis"
        export COMPOSE_PROFILES
    else
        echo "❌ Invalid option. Please run the script again."
        exit 1
    fi
fi

# Start container in background (with local Redis if configured)
if [ "${COMPOSE_PROFILES}" = "local-redis" ]; then
    docker-compose --profile local-redis up -d --build
else
    docker-compose up -d --build
fi

# Wait a moment for container to start
sleep 2

# Follow logs until setup is complete
echo "📊 Monitoring startup process..."
timeout 60 docker logs -f redis-rdi-ctf 2>&1 | while read line; do
    echo "$line"
    
    # Check for setup completion
    if [[ "$line" == *"exited: setup_check (exit status 0; expected)"* ]]; then
        echo ""
        echo "✅ Setup verification completed successfully!"
        echo "🎯 Redis RDI CTF is now running in background"
        echo ""
        echo "🌐 Access your CTF at: http://localhost:8080"
        echo "📋 View logs anytime: docker logs redis-rdi-ctf"
        echo "🛑 Stop container: docker-compose down"
        echo ""
        break
    fi
    
    # Check for setup failure
    if [[ "$line" == *"exited: setup_check (exit status"* ]] && [[ "$line" != *"exit status 0"* ]]; then
        echo ""
        echo "❌ Setup verification failed!"
        echo "🛑 Stopping container..."
        docker-compose down
        exit 1
    fi
    
    # Check for other critical failures
    if [[ "$line" == *"FATAL"* ]] || [[ "$line" == *"ERROR"* ]]; then
        echo ""
        echo "❌ Critical error detected!"
        echo "🛑 Stopping container..."
        docker-compose down
        exit 1
    fi
done

# Verify container is still running
if docker ps | grep -q redis-rdi-ctf; then
    echo "🎉 Redis RDI CTF is ready and running in background!"
    exit 0
else
    echo "❌ Container failed to start properly"
    exit 1
fi
