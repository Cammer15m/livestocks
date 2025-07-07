#!/bin/bash

echo "🛑 Stopping Redis RDI Training Environment..."
echo ""

# Stop all containers
docker-compose -f docker-compose-cloud.yml down

echo "✅ All containers stopped"
echo ""
echo "To completely remove data volumes:"
echo "   docker-compose -f docker-compose-cloud.yml down -v"
echo ""
