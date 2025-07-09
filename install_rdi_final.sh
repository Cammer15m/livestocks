#!/bin/bash

set -euo pipefail
INSTALL_DIR="/root/rdi_install/1.10.0"
REDIS_HOST="localhost"
RDI_CLI="${INSTALL_DIR}/deps/rdi-cli/ubuntu-20.04/redis-di"

echo "🚀 [Phase 1] Installing K3s..."
if ! command -v k3s >/dev/null; then
    curl -sfL https://get.k3s.io | sh -
    echo "✅ K3s installed"
else
    echo "⏩ K3s already installed, skipping."
fi

echo "🕒 Waiting for Traefik to become ready..."
for i in {1..30}; do
    status=$(k3s kubectl get pods -n kube-system -l app.kubernetes.io/name=traefik -o jsonpath="{.items[0].status.containerStatuses[0].ready}" 2>/dev/null || echo "false")
    if [[ "$status" == "true" ]]; then
        echo "✅ Traefik is ready."
        break
    fi
    echo "⏳ Still waiting for Traefik... ($i/30)"
    sleep 10
done

if [[ "$status" != "true" ]]; then
    echo "❌ Timeout: Traefik did not become ready in time."
    exit 1
fi

echo "🚀 [Phase 2] Installing RDI core components..."
cd "$INSTALL_DIR"
chmod +x "$RDI_CLI"

# Set environment variables to bypass K3s detection and force non-interactive mode
export RDI_FORCE=true
export RDI_SKIP_PREREQ=true

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
