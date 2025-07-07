#!/bin/bash

# Redis RDI CTF Stop Script
# Safely stops all CTF containers and verifies they are stopped

set -e  # Exit on any error

echo "🛑 Stopping Redis RDI CTF..."
echo ""

# Check if containers are running
if docker ps | grep -q redis-rdi-ctf; then
    echo "📋 Found running CTF containers"
    
    # Stop containers gracefully
    echo "🔄 Stopping containers..."
    docker-compose down
    
    # Wait a moment for cleanup
    sleep 2
    
    # Verify containers are stopped
    if docker ps | grep -q redis-rdi-ctf; then
        echo "⚠️  Containers still running, forcing stop..."
        docker-compose down --remove-orphans
        sleep 2
    fi
    
    # Final verification
    if docker ps | grep -q redis-rdi-ctf; then
        echo "❌ Failed to stop containers. Manual intervention needed:"
        echo "   docker stop redis-rdi-ctf"
        echo "   docker rm redis-rdi-ctf"
        exit 1
    else
        echo "✅ All CTF containers stopped successfully"
    fi
    
else
    echo "ℹ️  No CTF containers currently running"
fi

# Check for any stopped containers
if docker ps -a | grep -q redis-rdi-ctf; then
    echo ""
    echo "🧹 Cleaning up stopped containers..."
    docker-compose down --remove-orphans
    echo "✅ Cleanup complete"
fi

echo ""
echo "🎯 Redis RDI CTF is now stopped"
echo ""
echo "📋 To start again: ./start_ctf.sh"
echo "🗑️  To remove all data: docker-compose down -v"
echo ""
