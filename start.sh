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
    echo "🧪 After installation, test RDI:"
    echo "   docker exec -it rdi-manual redis-di --help"
    echo "   docker exec -it rdi-manual redis-di status"
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