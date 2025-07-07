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

        # Test Redis connection using Python
        echo "🔍 Testing Redis connection..."
        if timeout 10 python3 -c "
import sys
try:
    import redis
    r = redis.from_url('$redis_url', socket_timeout=5, socket_connect_timeout=5)
    result = r.ping()
    if result:
        print('✅ Redis connection successful!')
    else:
        print('❌ Redis ping failed!')
        sys.exit(1)
except ImportError:
    print('❌ Python redis library not installed!')
    print('   Please install: pip3 install redis')
    print('   Or see README for prerequisites.')
    sys.exit(1)
except Exception as e:
    print('❌ Failed to connect to Redis Cloud!')
    print(f'   Error: {str(e)}')
    print('   Please check your connection string and try again.')
    sys.exit(1)
"; then
            echo ""
        else
            exit 1
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
    echo "🎉 Redis RDI CTF container is running!"
    echo ""

    # Comprehensive health checks
    echo "🔍 Running post-startup health checks..."

    # Check 1: Container health status
    echo "   • Checking container health..."
    sleep 5  # Give container time to settle
    if docker inspect redis-rdi-ctf --format='{{.State.Health.Status}}' 2>/dev/null | grep -q "healthy"; then
        echo "     ✅ Container is healthy"
    else
        echo "     ⚠️  Container health check pending..."
    fi

    # Check 2: Web interface accessibility
    echo "   • Testing web interface..."
    if timeout 10 curl -s http://localhost:8080 >/dev/null 2>&1; then
        echo "     ✅ Web interface accessible on port 8080"
    else
        echo "     ❌ Web interface not responding"
        echo "     🔍 Check logs: docker logs redis-rdi-ctf"
        exit 1
    fi

    # Check 3: PostgreSQL service
    echo "   • Testing PostgreSQL database..."
    if docker exec redis-rdi-ctf pg_isready -U rdi_user -d rdi_db >/dev/null 2>&1; then
        echo "     ✅ PostgreSQL database is ready"
    else
        echo "     ❌ PostgreSQL database not responding"
        echo "     🔍 Check logs: docker logs redis-rdi-ctf"
        exit 1
    fi

    # Check 4: Redis connection from container
    echo "   • Testing Redis connection from container..."
    if docker exec redis-rdi-ctf python3 -c "
import redis
import os
from urllib.parse import urlparse

# Get Redis URL from environment
redis_url = os.getenv('REDIS_URL')
if redis_url:
    try:
        r = redis.from_url(redis_url, socket_timeout=5)
        r.ping()
        print('     ✅ Redis connection successful from container')
    except Exception as e:
        print(f'     ❌ Redis connection failed: {e}')
        exit(1)
else:
    print('     ⚠️  REDIS_URL not set in container')
    exit(1)
" 2>/dev/null; then
        echo ""
    else
        echo "     ❌ Redis connection failed from container"
        echo "     🔍 Check your Redis Cloud configuration"
        exit 1
    fi

    echo "✅ All health checks passed!"
    echo ""
    echo "🎉 Redis RDI CTF is ready and fully operational!"
    echo ""
    echo "🌐 Access your CTF at: http://localhost:8080"
    echo "📋 View logs: docker logs redis-rdi-ctf"
    echo "🛑 Stop CTF: ./stop_ctf.sh"
    exit 0
else
    echo "❌ Container failed to start properly"
    exit 1
fi
