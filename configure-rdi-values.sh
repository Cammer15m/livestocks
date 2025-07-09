#!/bin/bash

# Script to configure RDI values for Redis RDI CTF project

echo "🔧 Configuring RDI values for Redis RDI CTF project..."

# Check if user provided custom values via environment variables
if [[ -n "$REDIS_HOST" && -n "$REDIS_PORT" && -n "$REDIS_PASSWORD" ]]; then
    echo "📝 Using provided Redis connection details..."
else
    # Default Redis Cloud connection for the lab
    REDIS_HOST="${REDIS_HOST:-redis-17173.c14.us-east-1-2.ec2.redns.redis-cloud.com}"
    REDIS_PORT="${REDIS_PORT:-17173}"
    REDIS_PASSWORD="${REDIS_PASSWORD:-redislabs}"
    echo "📝 Using default Redis Cloud connection..."
fi

# Generate a random 32-character JWT key
JWT_KEY=$(openssl rand -base64 32)

echo "📝 Updating rdi-values.yaml with your configuration..."

# Update the connection section
sed -i "s/# host: \"\"/host: \"$REDIS_HOST\"/" rdi-values.yaml
sed -i "s/# port: \"\"/port: $REDIS_PORT/" rdi-values.yaml
sed -i "s/# password: \"\"/password: \"$REDIS_PASSWORD\"/" rdi-values.yaml

# Update the JWT key (escape special characters for sed)
JWT_KEY_ESCAPED=$(echo "$JWT_KEY" | sed 's/[[\.*^$()+?{|]/\\&/g')
sed -i "s/jwtKey: \"replace_on_install\"/jwtKey: \"$JWT_KEY_ESCAPED\"/" rdi-values.yaml

echo "✅ Configuration complete!"
echo ""
echo "📊 Updated values:"
echo "   Redis Host: $REDIS_HOST"
echo "   Redis Port: $REDIS_PORT"
echo "   Redis Password: $REDIS_PASSWORD"
echo "   JWT Key: $JWT_KEY"
echo ""
echo "🚀 You can now run the Helm installation with:"
echo "   ./install-rdi-helm.sh --skip-download"
echo ""
echo "💡 To use custom Redis connection, set environment variables:"
echo "   export REDIS_HOST=your-redis-host"
echo "   export REDIS_PORT=your-redis-port"
echo "   export REDIS_PASSWORD=your-redis-password"
echo "   ./configure-rdi-values.sh"
