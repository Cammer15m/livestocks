#!/bin/bash

# Redis RDI CTF Startup Script
# Shows startup logs for verification, then keeps container running in background

set -e  # Exit on any error

echo "🚀 Starting Redis RDI CTF..."
echo "📋 This will show startup logs, then run in background if successful"
echo ""

# Start container in background
docker-compose up -d

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
    echo "🎉 Redis RDI CTF is ready and running in background!"
    exit 0
else
    echo "❌ Container failed to start properly"
    exit 1
fi
