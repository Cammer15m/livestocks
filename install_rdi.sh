#!/bin/bash

set -e

INSTALL_DIR="/root/rdi_install/1.10.0"
INSTALLER="install.sh"

echo "🧠 RDI install wrapper starting..."
echo "📁 Checking install directory: $INSTALL_DIR"

if [ ! -d "$INSTALL_DIR" ]; then
  echo "❌ Install directory not found: $INSTALL_DIR"
  exit 1
fi

if ! command -v script &>/dev/null; then
  echo "📦 'script' not found. Installing..."
  apt update && apt install -y bsdutils
fi

echo "🚀 Launching install with pseudo-TTY via 'script'..."
echo "👉 You'll be prompted: 'Remove K3s? [y/N]' — type **N** and press Enter!"

cd "$INSTALL_DIR"

# Start the installer with a real TTY
script -q -c "./$INSTALLER" /dev/null
