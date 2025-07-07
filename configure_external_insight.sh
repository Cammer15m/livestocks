#!/bin/bash

# Helper script for configuring external Redis Insight with Redis RDI CTF
# This script provides connection details for external Redis Insight setup

echo "🔍 External Redis Insight Configuration Helper"
echo "=============================================="
echo ""
echo "This script helps you configure your external Redis Insight installation"
echo "to work with the Redis RDI CTF environment."
echo ""

# Check if config.yaml exists
if [ ! -f "rdi-config/config.yaml" ]; then
    echo "❌ RDI configuration not found!"
    echo "   Please run ./start_ctf.sh first to configure your Redis connection."
    exit 1
fi

# Extract Redis connection details from config.yaml
echo "📋 Redis Connection Details for External Redis Insight:"
echo "======================================================="
echo ""

# Extract host, port, password from config.yaml
redis_host=$(grep "host:" rdi-config/config.yaml | awk '{print $2}' | tr -d '"')
redis_port=$(grep "port:" rdi-config/config.yaml | awk '{print $2}')
redis_password=$(grep "password:" rdi-config/config.yaml | awk '{print $2}' | tr -d '"')
redis_username=$(grep "username:" rdi-config/config.yaml | awk '{print $2}' | tr -d '"')

echo "🔗 Redis Connection:"
echo "   Host: $redis_host"
echo "   Port: $redis_port"
echo "   Username: $redis_username"
echo "   Password: ${redis_password:0:8}..."
echo "   SSL/TLS: Yes (for Redis Cloud)"
echo ""

echo "🗄️ PostgreSQL Connection (Source Database):"
echo "   Host: localhost"
echo "   Port: 5432"
echo "   Database: musicstore"
echo "   Username: postgres"
echo "   Password: postgres"
echo ""

echo "📥 Download Redis Insight:"
echo "   URL: https://redis.io/downloads/#Redis_Insight"
echo "   Available for: Windows, macOS, Linux"
echo ""

echo "⚙️ Setup Instructions:"
echo "1. Download and install Redis Insight from the URL above"
echo "2. Open Redis Insight"
echo "3. Add a new Redis database connection with the details above"
echo "4. Navigate to the RDI section in Redis Insight"
echo "5. Configure RDI pipeline using the PostgreSQL connection details"
echo ""

echo "🔧 RDI Pipeline Configuration:"
echo "   Source: PostgreSQL (localhost:5432/musicstore)"
echo "   Target: Your Redis instance (details above)"
echo "   Tables: albums, artists, customers, tracks, etc."
echo ""

echo "📚 Additional Resources:"
echo "   - Redis RDI Documentation: https://redis.io/docs/data-integration/"
echo "   - Redis Insight Documentation: https://redis.io/docs/redis-insight/"
echo ""

echo "✅ Configuration details saved above for your reference!"
echo ""
echo "💡 Tip: Keep this terminal open for easy reference while configuring Redis Insight"
