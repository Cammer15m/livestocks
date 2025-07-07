#!/bin/bash

# Redis RDI Training Environment Stop Script
# Safely stops all services and cleans up resources

echo "🛑 Stopping Redis RDI Training Environment"
echo "=========================================="

# Stop ttyd terminal if running
echo "🖥️ Stopping terminal services..."
pkill -f "ttyd.*7681" 2>/dev/null || true
echo "   ✅ Terminal services stopped"

# Stop Docker Compose services
echo "🐳 Stopping Docker containers..."
if [ -f "docker-compose.yml" ]; then
    docker-compose down -v --remove-orphans
    echo "   ✅ All containers stopped and removed"
else
    echo "   ⚠️  docker-compose.yml not found"
fi

# Stop any remaining RDI-related containers
echo "🧹 Cleaning up any remaining containers..."
docker stop $(docker ps -q --filter "name=rdi") 2>/dev/null || true
docker stop $(docker ps -q --filter "name=re-") 2>/dev/null || true
docker stop $(docker ps -q --filter "name=redis") 2>/dev/null || true
docker rm $(docker ps -aq --filter "name=rdi") 2>/dev/null || true
docker rm $(docker ps -aq --filter "name=re-") 2>/dev/null || true
docker rm $(docker ps -aq --filter "name=redis") 2>/dev/null || true

# Clean up temporary files
echo "📁 Cleaning up temporary files..."
rm -rf rdi-installation-*.tar.gz 2>/dev/null || true
rm -rf rdi_install 2>/dev/null || true
rm -rf create_cluster.json 2>/dev/null || true
echo "   ✅ Temporary files cleaned"

# Optional: Clean up Docker resources
read -p "🗑️  Clean up Docker images and volumes? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "   • Removing unused Docker resources..."
    docker system prune -f >/dev/null 2>&1 || true
    echo "   ✅ Docker resources cleaned"
fi

echo ""
echo "✅ Redis RDI Training Environment stopped successfully!"
echo ""
echo "📋 To restart:"
echo "   export DOMAIN=localhost"
echo "   ./start.sh"
