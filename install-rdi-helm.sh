#!/usr/bin/env bash
set -euo pipefail

echo "🚀 Starting RDI Helm installation..."

# Get Redis connection details from environment variables (set by start script)
RDI_VERSION="1.12.2"
REDIS_HOST="${REDIS_HOST:-redis-17173.c14.us-east-1-2.ec2.redns.redis-cloud.com}"
REDIS_PORT="${REDIS_PORT:-17173}"
REDIS_USER="${REDIS_USER:-default}"
REDIS_PASSWORD="${REDIS_PASSWORD:-redislabs}"

echo "📊 Using Redis connection:"
echo "   Host: $REDIS_HOST"
echo "   Port: $REDIS_PORT"
echo "   User: $REDIS_USER"
echo "   Password: $REDIS_PASSWORD"
echo ""

# Download chart
echo "📦 Downloading RDI Helm chart version ${RDI_VERSION}..."
wget -qO rdi-${RDI_VERSION}.tgz \
  "https://redis-enterprise-software-downloads.s3.amazonaws.com/redis-di/rdi-${RDI_VERSION}.tgz"

# Generate values file with connection creds and JWT
echo "📝 Generating values file with Redis connection..."
helm show values rdi-${RDI_VERSION}.tgz > rdi-values.yaml
cat <<EOF >> rdi-values.yaml
connection:
  host: ${REDIS_HOST}
  port: ${REDIS_PORT}
  user: ${REDIS_USER}
  password: ${REDIS_PASSWORD}
api:
  jwtKey: "$(head -c32 /dev/urandom | base64)"
EOF

echo "✅ Values file configured with your Redis connection"

# Ensure Traefik ingress is installed
echo "🌐 Setting up Traefik ingress controller..."
helm repo add traefik https://traefik.github.io/charts
helm repo update
helm upgrade --install traefik traefik/traefik \
  --namespace kube-system --create-namespace
kubectl wait deployment/traefik -n kube-system \
  --for=condition=available --timeout=180s

# Deploy RDI via Helm
echo "🚀 Installing RDI via Helm..."
helm upgrade --install rdi rdi-${RDI_VERSION}.tgz \
  -f rdi-values.yaml \
  -n rdi --create-namespace

# Verify all RDI pods are running
echo "✅ Verifying RDI deployment..."
helm list -n rdi
kubectl get all -n rdi

echo ""
echo "🎉 RDI Helm installation complete!"
echo "📊 Check status with: kubectl get all -n rdi"
echo "📝 View logs with: kubectl logs -n rdi -l app=rdi"
