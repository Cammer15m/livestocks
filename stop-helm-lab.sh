#!/usr/bin/env bash
set -euo pipefail

echo "🛑 Stopping Redis RDI CTF Lab (Helm-based)"
echo "==========================================="

# Determine Docker Compose command
if command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE="docker-compose"
else
    DOCKER_COMPOSE="docker compose"
fi

echo "🐳 Stopping containers..."
$DOCKER_COMPOSE -f docker-compose-helm.yml down

echo "🧹 Cleaning up..."
# Remove any orphaned containers
docker container prune -f --filter "label=com.docker.compose.project=redis_rdi_ctf"

echo "✅ Lab stopped successfully!"
echo ""
echo "💡 To completely remove all data and images:"
echo "   $DOCKER_COMPOSE -f docker-compose-helm.yml down -v --rmi all"
