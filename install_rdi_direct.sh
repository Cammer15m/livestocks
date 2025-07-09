#!/bin/bash

set -euo pipefail

INSTALL_DIR="/root/rdi_install/1.10.0"
REDIS_HOST="localhost"  # Change this if needed
RDI_CLI_DIR=$(ls "$INSTALL_DIR/deps/rdi-cli" | head -n1)
RDI_CLI="${INSTALL_DIR}/deps/rdi-cli/${RDI_CLI_DIR}/redis-di"

echo "🚀 [Phase 1] Installing K3s..."
if ! command -v k3s >/dev/null; then
    curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--write-kubeconfig-mode=644" sh -
    echo "✅ K3s installed"
else
    echo "⏩ K3s already installed, skipping."
fi

echo "🕒 Waiting for Traefik to become ready..."
for i in {1..30}; do
    READY=$(kubectl get deploy traefik -n kube-system -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
    if [[ "$READY" == "1" ]]; then
        echo "✅ Traefik is ready."
        break
    fi
    echo "⏳ Still waiting for Traefik... ($i/30)"
    sleep 5
done

if [[ "$READY" != "1" ]]; then
    echo "❌ Traefik did not become ready in time."
    exit 1
fi

echo "🚀 [Phase 2] Installing RDI core components..."
cd "$INSTALL_DIR"
chmod +x "$RDI_CLI"

# Set environment variables for non-interactive installation
export RDI_FORCE=true
export RDI_SKIP_PREREQ=true
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

"$RDI_CLI" install

echo "✅ Core RDI services deployed."

echo "🚀 [Phase 3] Deploying pipelines..."
PIPELINE_FILE="${INSTALL_DIR}/config/pipeline.yaml"

if [ -f "$PIPELINE_FILE" ]; then
    "$RDI_CLI" pipeline create --file "$PIPELINE_FILE"
    echo "✅ Pipeline deployed from: $PIPELINE_FILE"
else
    echo "⚠️ No pipeline.yaml found. Skipping pipeline deployment."
fi

echo "🏁 RDI installation complete!"
