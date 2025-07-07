#!/bin/bash

# Redis RDI CTF Startup Script
# This script starts the Redis RDI CTF environment with separate containers

set -e

# Function to test Redis connection
test_redis_connection() {
    local host=$1
    local port=$2
    local password=$3
    local username=$4

    echo "🔍 Testing Redis connection..."

    # Create a temporary Python script to test the connection
    cat > /tmp/test_redis.py << EOF
import redis
import sys

try:
    r = redis.Redis(
        host='$host',
        port=$port,
        password='$password',
        username='$username',
        ssl=True,
        ssl_cert_reqs=None,
        socket_timeout=5,
        socket_connect_timeout=5
    )

    # Test the connection
    result = r.ping()
    if result:
        print("✅ Redis connection successful!")
        sys.exit(0)
    else:
        print("❌ Redis connection failed!")
        sys.exit(1)

except Exception as e:
    print(f"❌ Redis connection error: {e}")
    sys.exit(1)
EOF

    # Run the test (if Python is available)
    if command -v python3 > /dev/null 2>&1; then
        if python3 -c "import redis" > /dev/null 2>&1; then
            python3 /tmp/test_redis.py
            local test_result=$?
            rm -f /tmp/test_redis.py
            return $test_result
        else
            echo "⚠️  Python redis module not available, skipping connection test"
            rm -f /tmp/test_redis.py
            return 0
        fi
    else
        echo "⚠️  Python not available, skipping connection test"
        rm -f /tmp/test_redis.py
        return 0
    fi
}

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

# Check if RDI configuration exists
if [ ! -f "rdi-config/config.yaml" ]; then
    echo ""
    echo "🔧 Redis RDI Configuration Setup"
    echo "================================="
    echo ""

    # Check if .env file has Redis URL
    if [ -f ".env" ] && grep -q "REDIS_URL=" .env; then
        redis_url=$(grep "REDIS_URL=" .env | cut -d'=' -f2-)
        if [[ $redis_url =~ ^redis://([^:]+):([^@]+)@([^:]+):([0-9]+)$ ]]; then
            echo "🔍 Found Redis connection in .env file:"
            echo "   URL: ${redis_url:0:20}...${redis_url: -20}"
            echo ""
            read -p "Use this Redis connection? (y/n): " use_env_redis
            if [[ $use_env_redis =~ ^[Yy]$ ]]; then
                redis_username="${BASH_REMATCH[1]}"
                redis_password="${BASH_REMATCH[2]}"
                redis_host="${BASH_REMATCH[3]}"
                redis_port="${BASH_REMATCH[4]}"

                echo ""
                echo "✅ Using Redis connection from .env file"
                echo "   Host: $redis_host"
                echo "   Port: $redis_port"
                echo "   Username: $redis_username"
                echo ""

                # Create config file from template
                cp rdi-config/config.yaml.template rdi-config/config.yaml

                # Update with Redis details from .env
                sed -i "s/YOUR_REDIS_CLOUD_HOST/$redis_host/" rdi-config/config.yaml
                sed -i "s/YOUR_REDIS_CLOUD_PORT/$redis_port/" rdi-config/config.yaml
                sed -i "s/YOUR_REDIS_CLOUD_PASSWORD/$redis_password/" rdi-config/config.yaml
                sed -i "s/username: default/username: $redis_username/" rdi-config/config.yaml

                echo "✅ Redis Cloud configuration saved!"
                echo ""

                # Test the Redis connection
                test_redis_connection "$redis_host" "$redis_port" "$redis_password" "$redis_username"
                echo ""

                # Skip the manual configuration
                redis_option="configured"
            fi
        fi
    fi

    if [ "$redis_option" != "configured" ]; then
        echo "You need to configure RDI to connect to your Redis instance."
        echo ""
        echo "Options:"
        echo "1. Configure Redis Cloud (recommended - free account at redis.com)"
        echo "2. Use local Redis (will start Redis container automatically)"
        echo "3. Configure manually later"
        echo ""
        read -p "Choose option (1, 2, or 3): " redis_option
    fi

    case $redis_option in
        1)
            echo ""
            echo "📝 Redis Cloud Configuration"
            echo "=============================="
            echo ""
            echo "Please provide your Redis Cloud connection string:"
            echo "(Get this from your Redis Cloud dashboard - click 'Connect' → 'Redis CLI')"
            echo "Format: redis://default:password@host:port"
            echo ""
            read -p "Redis Cloud Connection String: " redis_connection_string

            # Parse the connection string
            if [[ $redis_connection_string =~ ^redis://([^:]+):([^@]+)@([^:]+):([0-9]+)$ ]]; then
                redis_username="${BASH_REMATCH[1]}"
                redis_password="${BASH_REMATCH[2]}"
                redis_host="${BASH_REMATCH[3]}"
                redis_port="${BASH_REMATCH[4]}"

                echo ""
                echo "✅ Parsed connection details:"
                echo "   Host: $redis_host"
                echo "   Port: $redis_port"
                echo "   Username: $redis_username"
                echo "   Password: [HIDDEN]"
                echo ""

                # Create config file from template
                cp rdi-config/config.yaml.template rdi-config/config.yaml

                # Update with user's Redis Cloud details
                sed -i "s/YOUR_REDIS_CLOUD_HOST/$redis_host/" rdi-config/config.yaml
                sed -i "s/YOUR_REDIS_CLOUD_PORT/$redis_port/" rdi-config/config.yaml
                sed -i "s/YOUR_REDIS_CLOUD_PASSWORD/$redis_password/" rdi-config/config.yaml
                sed -i "s/username: default/username: $redis_username/" rdi-config/config.yaml

                echo "✅ Redis Cloud configuration saved!"
                echo ""

                # Test the Redis connection
                test_redis_connection "$redis_host" "$redis_port" "$redis_password" "$redis_username"
                echo ""
            else
                echo ""
                echo "❌ Invalid connection string format!"
                echo "Expected format: redis://username:password@host:port"
                echo "Example: redis://default:mypassword@redis-12345.c123.us-east-1-2.ec2.redns.redis-cloud.com:12345"
                echo ""
                echo "Falling back to manual configuration..."
                echo ""
                read -p "Redis Cloud Host (e.g., redis-12345.c123.us-east-1-2.ec2.redns.redis-cloud.com): " redis_host
                read -p "Redis Cloud Port (e.g., 12345): " redis_port
                read -s -p "Redis Cloud Password: " redis_password
                echo ""
                read -p "Redis Cloud Username (default: default): " redis_username
                redis_username=${redis_username:-default}

                # Create config file from template
                cp rdi-config/config.yaml.template rdi-config/config.yaml

                # Update with user's Redis Cloud details
                sed -i "s/YOUR_REDIS_CLOUD_HOST/$redis_host/" rdi-config/config.yaml
                sed -i "s/YOUR_REDIS_CLOUD_PORT/$redis_port/" rdi-config/config.yaml
                sed -i "s/YOUR_REDIS_CLOUD_PASSWORD/$redis_password/" rdi-config/config.yaml
                sed -i "s/username: default/username: $redis_username/" rdi-config/config.yaml

                echo ""
                echo "✅ Redis Cloud configuration saved!"
                echo ""

                # Test the Redis connection
                test_redis_connection "$redis_host" "$redis_port" "$redis_password" "$redis_username"
                echo ""
            fi
            ;;
        2)
            echo ""
            echo "🐳 Local Redis Configuration"
            echo "============================="
            echo ""
            echo "Will start local Redis container and configure RDI to use it."

            # Create config for local Redis
            cp rdi-config/config.yaml.template rdi-config/config.yaml
            sed -i "s/YOUR_REDIS_CLOUD_HOST/redis-local/" rdi-config/config.yaml
            sed -i "s/YOUR_REDIS_CLOUD_PORT/6379/" rdi-config/config.yaml
            sed -i "s/YOUR_REDIS_CLOUD_PASSWORD//" rdi-config/config.yaml
            sed -i "s/tls: true/tls: false/" rdi-config/config.yaml
            sed -i "s/tls_skip_verify: true/tls_skip_verify: false/" rdi-config/config.yaml

            # Use local redis profile
            COMPOSE_PROFILES="local-redis"
            export COMPOSE_PROFILES

            echo "✅ Local Redis configuration saved!"
            echo ""
            ;;
        3)
            echo ""
            echo "⚠️  Manual Configuration Selected"
            echo "================================="
            echo ""
            echo "You can configure RDI later using:"
            echo "  docker exec -it rdi-ctf-cli cp /config/config.yaml.template /config/config.yaml"
            echo "  docker exec -it rdi-ctf-cli nano /config/config.yaml"
            echo ""
            ;;
        "configured")
            # Configuration already done from .env file
            echo "✅ Using Redis configuration from .env file"
            ;;
        *)
            echo "❌ Invalid option. Proceeding without configuration."
            ;;
    esac
fi

echo "🔨 Building and starting containers..."

# Start containers (with local Redis if configured)
if [ "${COMPOSE_PROFILES}" = "local-redis" ]; then
    docker-compose --profile local-redis up -d --build
else
    docker-compose up -d --build
fi

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

# Show next steps based on configuration
if [ -f "rdi-config/config.yaml" ]; then
    echo "📋 Next Steps:"
    echo "1. Deploy and start RDI:"
    echo "   docker exec -it rdi-ctf-cli redis-di deploy --config /config/config.yaml"
    echo "   docker exec -it rdi-ctf-cli redis-di start"
    echo "2. Check RDI status:"
    echo "   docker exec -it rdi-ctf-cli redis-di status"
    echo "3. Start with Lab 01 in the web interface"
    echo ""
    echo "🔧 To modify RDI config:"
    echo "   docker exec -it rdi-ctf-cli nano /config/config.yaml"
else
    echo "📋 Next Steps:"
    echo "1. Configure RDI with your Redis connection:"
    echo "   docker exec -it rdi-ctf-cli cp /config/config.yaml.template /config/config.yaml"
    echo "   docker exec -it rdi-ctf-cli nano /config/config.yaml"
    echo "2. Deploy and start RDI:"
    echo "   docker exec -it rdi-ctf-cli redis-di deploy --config /config/config.yaml"
    echo "   docker exec -it rdi-ctf-cli redis-di start"
    echo "3. Start with Lab 01 in the web interface"
fi

echo ""
echo "🛑 To stop the environment: ./stop_ctf.sh"
echo ""
