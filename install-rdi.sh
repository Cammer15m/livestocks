#!/bin/bash

# Helper script to guide through RDI manual installation
# This script provides step-by-step guidance for installing RDI in the container

echo "🔧 Redis RDI Manual Installation Guide"
echo "======================================"
echo ""

# Check if containers are running
if ! docker ps | grep -q "rdi-manual"; then
    echo "❌ RDI container is not running."
    echo "Please start the environment first:"
    echo "   ./start.sh"
    exit 1
fi

if ! docker ps | grep -q "rdi-postgres"; then
    echo "❌ PostgreSQL container is not running."
    echo "Please start the environment first:"
    echo "   ./start.sh"
    exit 1
fi

echo "✅ Containers are running"
echo ""

# Get container IP for RDI hostname
CONTAINER_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' rdi-manual)
if [ -z "$CONTAINER_IP" ]; then
    CONTAINER_IP="172.16.22.21"
fi

echo "🔍 Container Information:"
echo "   RDI Container IP: $CONTAINER_IP"
echo "   PostgreSQL: postgresql:5432"
echo "   Shared Redis: 3.148.243.197:13000"
echo ""

echo "📋 Installation Steps:"
echo ""
echo "1️⃣  Access the RDI container:"
echo "   docker exec -it rdi-manual bash"
echo ""
echo "2️⃣  Navigate to the RDI installation directory:"
echo "   cd /rdi/rdi_install/1.10.0/"
echo ""
echo "3️⃣  Run the RDI installer:"
echo "   sudo ./install.sh"
echo ""
echo "4️⃣  Answer the installation prompts:"
echo ""

# Create a formatted table of installation prompts
cat << 'EOF'
┌─────────────────────────────────┬─────────────────────────────────┐
│ Prompt                          │ Suggested Answer                │
├─────────────────────────────────┼─────────────────────────────────┤
│ RDI hostname                    │ [press enter] or 172.16.22.21   │
│ RDI port                        │ 12001                           │
│ Username                        │ [press enter for default]       │
│ Password                        │ redislabs                       │
│ Use TLS?                        │ N                               │
│ HTTPS port                      │ 443 [press enter]              │
│ Proceed with iptables?          │ Y                               │
│ Proceed with DNS?               │ Y                               │
│ Upstream DNS servers            │ 8.8.8.8,8.8.4.4               │
│ Source database type            │ 2 (PostgreSQL)                 │
└─────────────────────────────────┴─────────────────────────────────┘
EOF

echo ""
echo "5️⃣  After installation, verify RDI is running:"
echo "   redis-di status"
echo "   redis-di --help"
echo ""

echo "🔗 Connection Details for RDI Configuration:"
echo ""
echo "📊 Shared Redis (RDI Metadata):"
echo "   Host: 3.148.243.197"
echo "   Port: 13000"
echo "   User: default"
echo "   Password: redislabs"
echo ""
echo "🗄️  PostgreSQL (Source Database):"
echo "   Host: postgresql"
echo "   Port: 5432"
echo "   Database: chinook"
echo "   User: postgres"
echo "   Password: postgres"
echo ""

echo "🚀 Quick Start Commands:"
echo ""
echo "# Access RDI container and install"
echo "docker exec -it rdi-manual bash"
echo "cd /rdi/rdi_install/1.10.0/ && sudo ./install.sh"
echo ""
echo "# After installation, configure RDI pipeline"
echo "redis-di configure --rdi-host 3.148.243.197:13000 --rdi-password redislabs"
echo ""

echo "💡 Tips:"
echo "   - The installation takes 2-3 minutes"
echo "   - If you make a mistake, you can restart the container and try again"
echo "   - Use 'docker logs rdi-manual' to see container startup messages"
echo "   - PostgreSQL is already configured with wal_level=logical for Debezium"
echo ""

# Offer to start the installation process
echo "❓ Would you like to start the installation now? (y/n)"
read -r response

if [[ "$response" =~ ^[Yy]$ ]]; then
    echo ""
    echo "🚀 Starting RDI installation..."
    echo "You will be dropped into the RDI container."
    echo "Run: cd /rdi/rdi_install/1.10.0/ && sudo ./install.sh"
    echo ""
    echo "Press any key to continue..."
    read -r
    
    # Execute into the container
    docker exec -it rdi-manual bash
else
    echo ""
    echo "👍 No problem! Run this script again when you're ready."
    echo "Or manually access the container with: docker exec -it rdi-manual bash"
fi

echo ""
echo "📚 For more help, see the README.md file or check container logs."
