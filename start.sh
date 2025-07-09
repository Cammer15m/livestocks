#!/bin/bash

echo "🚀 Redis RDI Training Environment"
echo "=================================="
echo ""

# Gather Redis Cloud connection details from user
echo "📋 Redis Cloud Configuration"
echo "Please provide your Redis Cloud connection details:"
echo "This Redis instance will be used for BOTH RDI metadata AND target data."
echo ""
echo "💡 Note: Please ensure your Redis Cloud instance is configured with:"
echo "   Username: default"
echo "   Password: redislabs"
echo ""

# Prompt for Redis Cloud details (only host and port)
read -p "🔗 Redis Host (e.g., redis-12345.c1.region.ec2.redns.redis-cloud.com): " REDIS_HOST
read -p "🔌 Redis Port (e.g., 12345): " REDIS_PORT

# Set standard credentials
REDIS_USER="default"
REDIS_PASSWORD="redislabs"

# Validate required fields
if [[ -z "$REDIS_HOST" || -z "$REDIS_PORT" ]]; then
    echo "❌ Error: Redis host and port are required!"
    echo ""
    echo "💡 Example Redis Cloud connection string:"
    echo "   redis://default:redislabs@redis-12345.c1.region.ec2.redns.redis-cloud.com:12345"
    echo ""
    echo "   Host: redis-12345.c1.region.ec2.redns.redis-cloud.com"
    echo "   Port: 12345"
    echo "   Username: default (standard)"
    echo "   Password: redislabs (standard)"
    exit 1
fi

echo ""
echo "✅ Redis Cloud configuration:"
echo "   Host: $REDIS_HOST"
echo "   Port: $REDIS_PORT"
echo "   User: $REDIS_USER (standard)"
echo "   Password: $REDIS_PASSWORD (standard)"
echo ""

# Configure environment with user's Redis Cloud instance
cat > .env << EOF
# Redis Cloud Configuration (user provided)
REDIS_HOST=$REDIS_HOST
REDIS_PORT=$REDIS_PORT
REDIS_PASSWORD=$REDIS_PASSWORD
REDIS_USER=$REDIS_USER
EOF

USE_CLOUD=true

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    echo "✅ Docker installed. Please log out and log back in, then run this script again."
    exit 0
fi

# Check if Docker Compose is available
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo "❌ Docker Compose is not available. Please install Docker Compose."
    exit 1
fi

# Determine Docker Compose command
if command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE="docker-compose"
else
    DOCKER_COMPOSE="docker compose"
fi

echo "🧹 Cleaning up any existing containers..."
$DOCKER_COMPOSE -f docker-compose-cloud.yml down --remove-orphans

echo "🚀 Starting Redis RDI Training Environment..."
$DOCKER_COMPOSE -f docker-compose-cloud.yml up -d

echo "⏳ Waiting for services to start..."
sleep 10

# Wait for PostgreSQL to be ready
echo "🗄️ Waiting for PostgreSQL to be ready..."
until docker exec postgresql pg_isready -U postgres -d chinook &>/dev/null; do
    echo "   Still waiting for PostgreSQL..."
    sleep 5
done

if [ "$USE_CLOUD" = true ]; then
    echo "🔍 Checking container status..."
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

    echo ""
    echo "🎉 Environment ready!"
    echo ""
    echo "📊 Dashboard: http://localhost:8080"
    echo "🔍 Redis Insight: http://localhost:5540 (connect to your Redis: $REDIS_HOST:$REDIS_PORT)"
    echo ""
    echo "🔧 RDI Manual Installation Required:"
    echo "   1. Access RDI container: docker exec -it rdi-manual bash"
    echo "   2. Navigate to RDI: cd /rdi/rdi_install/1.10.0/"
    echo "   3. Run installer: sudo ./install.sh"
    echo ""
    echo "💡 Installation answers (using your Redis Cloud instance):"
    echo "   - Hostname: $REDIS_HOST"
    echo "   - Port: $REDIS_PORT"
    echo "   - Username: [press enter for default]"
    echo "   - Password: redislabs (standard)"
    echo "   - TLS: N"
    echo "   - HTTPS port: 443"
    echo "   - iptables: Y"
    echo "   - DNS: Y"
    echo "   - Upstream DNS: 8.8.8.8,8.8.4.4"
    echo "   - Source database: 5 (PostgreSQL)"
    echo ""
    echo "🔗 Your Redis Cloud instance will be used for:"
    echo "   ✅ RDI Metadata Database: $REDIS_HOST:$REDIS_PORT"
    echo "   ✅ Target Database: $REDIS_HOST:$REDIS_PORT"
    echo ""
    echo "🔗 PostgreSQL connection for RDI:"
    echo "   Host: localhost, Port: 5433, User: postgres, Password: postgres, DB: chinook"
    echo ""
    echo "🛑 To stop: ./stop.sh"
fi
