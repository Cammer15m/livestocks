#!/bin/bash

# Redis RDI CTF Startup Script
# Shows startup logs for verification, then keeps container running in background

set -e  # Exit on any error

echo "🚀 Starting Redis RDI CTF..."
echo "📋 This will show startup logs, then run in background if successful"
echo ""

# Check if Redis is configured (look for placeholder values)
if grep -q "REDIS_URL=redis://default:password@redis-17173" .env; then
    echo "🔧 Redis Cloud configuration needed!"
    echo ""
    echo "Options:"
    echo "1. Configure Redis Cloud (recommended - free account at redis.com)"
    echo "2. Use local Redis (will start Redis container automatically)"
    echo ""
    read -p "Choose option (1 or 2): " redis_option

    if [ "$redis_option" = "1" ]; then
        echo ""
        echo "📝 Please provide your Redis Cloud connection string:"
        echo "   (Copy from your Redis Cloud dashboard - 'Connect using Redis CLI')"
        echo "   Example: redis://default:password@redis-17173.c14.us-east-1-2.ec2.redns.redis-cloud.com:17173"
        echo ""
        read -p "Redis Cloud URL: " redis_url

        # Validate URL format
        if [[ ! "$redis_url" =~ ^redis://.*@.*:[0-9]+$ ]]; then
            echo "❌ Invalid Redis URL format. Please use the complete URL from Redis Cloud."
            echo "   Format: redis://username:password@host:port"
            exit 1
        fi

        # Update .env file
        sed -i "s|REDIS_URL=redis://default:password@redis-17173.c14.us-east-1-2.ec2.redns.redis-cloud.com:17173|REDIS_URL=${redis_url}|" .env

        echo "✅ Redis Cloud configuration saved to .env"
        echo ""

        # Test Redis connection
        echo "🔍 Testing Redis connection..."
        if command -v redis-cli >/dev/null 2>&1; then
            # Use redis-cli if available
            if redis-cli -u "$redis_url" ping >/dev/null 2>&1; then
                echo "✅ Redis connection successful!"
                echo ""
            else
                echo "❌ Failed to connect to Redis Cloud!"
                echo "   Please check your connection string and try again."
                echo "   Make sure your Redis Cloud instance is running."
                exit 1
            fi
        else
            # Use Python as fallback
            echo "   (Using Python to test connection...)"
            if python3 -c "
import redis
import sys
try:
    r = redis.from_url('$redis_url')
    r.ping()
    print('✅ Redis connection successful!')
except Exception as e:
    print('❌ Failed to connect to Redis Cloud!')
    print(f'   Error: {e}')
    print('   Please check your connection string and try again.')
    sys.exit(1)
" 2>/dev/null; then
                echo ""
            else
                exit 1
            fi
        fi

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
        echo "ℹ️  Local Redis connection will be tested after container starts"
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
