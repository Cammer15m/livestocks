#!/usr/bin/env bash
set -euo pipefail

# 🎯 Install Redis Data Integration (RDI) via Helm on Kubernetes

echo "🚀 Starting RDI Helm installation..."

# 1. Set RDI version and download Helm chart
export RDI_VERSION=1.12.2
echo "📦 Downloading RDI Helm chart version ${RDI_VERSION}..."
wget https://redis-enterprise-software-downloads.s3.amazonaws.com/redis-di/rdi-${RDI_VERSION}.tgz

# 2. Generate default values, then edit connection details
echo "📝 Generating default values file..."
helm show values rdi-${RDI_VERSION}.tgz > rdi-values.yaml

echo "⚠️  IMPORTANT: You need to edit rdi-values.yaml before proceeding!"
echo "   Set these minimum values:"
echo "   connection:"
echo "     host: <REDIS_ENTERPRISE_HOST>"
echo "     port: 6379"
echo "     password: <YOUR_DB_PASSWORD>"
echo "   api:"
echo "     jwtKey: \"<32-byte base64 JWT secret>\""
echo ""
echo "   For this project, use:"
echo "   connection:"
echo "     host: 3.148.243.197"
echo "     port: 13000"
echo "     password: redislabs"
echo ""
echo "📝 Edit rdi-values.yaml now, then run this script again with --skip-download"
echo ""

# Check if user wants to skip the download and proceed with installation
if [[ "${1:-}" != "--skip-download" ]]; then
    echo "🛑 Stopping here. Edit rdi-values.yaml and run: $0 --skip-download"
    exit 0
fi

echo "🔄 Continuing with installation..."

# 3. Ensure Traefik is installed and ready in kube-system
echo "🌐 Setting up Traefik ingress controller..."
helm repo add traefik https://traefik.github.io/charts
helm repo update
helm upgrade --install traefik traefik/traefik \
  --namespace kube-system --create-namespace

echo "⏳ Waiting for Traefik to be ready..."
kubectl wait deployment/traefik -n kube-system \
  --for=condition=available --timeout=180s

# 4. Install deploy RDI via Helm into rdi namespace
echo "🚀 Installing RDI via Helm..."
helm upgrade --install rdi rdi-${RDI_VERSION}.tgz \
  -f rdi-values.yaml \
  -n rdi --create-namespace

# 5. Validate deployment
echo "✅ Validating RDI deployment..."
helm list -n rdi
kubectl get all -n rdi

echo ""
echo "🎉 RDI Helm installation complete!"
echo "📊 Check status with: kubectl get all -n rdi"
echo "📝 View logs with: kubectl logs -n rdi -l app=rdi"
