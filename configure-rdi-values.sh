#!/bin/bash

# Script to set up environment for RDI Helm installation

echo "🔧 Setting up RDI environment for Helm installation..."

# Check if environment variables are already set
if [[ -n "$REDIS_HOST" && -n "$REDIS_PORT" && -n "$REDIS_PASSWORD" ]]; then
    echo "✅ Redis connection details already configured:"
    echo "   Host: $REDIS_HOST"
    echo "   Port: $REDIS_PORT"
    echo "   Password: $REDIS_PASSWORD"
else
    echo "❌ Redis connection details not found in environment."
    echo "   These should be set by start-helm-lab.sh"
    echo ""
    echo "💡 To manually set them:"
    echo "   export REDIS_HOST=your-redis-host"
    echo "   export REDIS_PORT=your-redis-port"
    echo "   export REDIS_PASSWORD=your-redis-password"
    exit 1
fi

echo ""
echo "🚀 Environment ready! You can now run:"
echo "   ./install-rdi-helm.sh"
echo ""
echo "📝 The installation script will automatically:"
echo "   1. Download RDI Helm chart"
echo "   2. Configure values with your Redis connection"
echo "   3. Install Traefik ingress controller"
echo "   4. Deploy RDI via Helm"
echo "   5. Verify the deployment"
