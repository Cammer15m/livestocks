#!/bin/bash

# Offline Docker Installation Script
# Downloads Docker packages for offline installation

set -e

echo "Redis RDI Training Environment - Offline Docker Installer"
echo "========================================================="

# Create packages directory
mkdir -p packages/docker

# Function to detect OS
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        VERSION=$VERSION_ID
    elif [ -f /etc/redhat-release ]; then
        OS="centos"
    elif [ -f /etc/debian_version ]; then
        OS="debian"
    else
        OS="unknown"
    fi
}

# Function to download Docker packages for Ubuntu/Debian
download_docker_deb() {
    echo "Downloading Docker packages for Ubuntu/Debian..."
    
    cd packages/docker
    
    # Download Docker CE packages
    wget -q https://download.docker.com/linux/ubuntu/dists/focal/pool/stable/amd64/containerd.io_1.6.24-1_amd64.deb
    wget -q https://download.docker.com/linux/ubuntu/dists/focal/pool/stable/amd64/docker-ce-cli_24.0.7-1~ubuntu.20.04~focal_amd64.deb
    wget -q https://download.docker.com/linux/ubuntu/dists/focal/pool/stable/amd64/docker-ce_24.0.7-1~ubuntu.20.04~focal_amd64.deb
    wget -q https://download.docker.com/linux/ubuntu/dists/focal/pool/stable/amd64/docker-buildx-plugin_0.11.2-1~ubuntu.20.04~focal_amd64.deb
    wget -q https://download.docker.com/linux/ubuntu/dists/focal/pool/stable/amd64/docker-compose-plugin_2.21.0-1~ubuntu.20.04~focal_amd64.deb
    
    # Download Docker Compose standalone
    wget -q -O docker-compose https://github.com/docker/compose/releases/download/v2.21.0/docker-compose-linux-x86_64
    chmod +x docker-compose
    
    cd ../..
    echo "Docker packages downloaded to packages/docker/"
}

# Function to download Docker packages for CentOS/RHEL
download_docker_rpm() {
    echo "Downloading Docker packages for CentOS/RHEL..."
    
    cd packages/docker
    
    # Download Docker CE packages
    wget -q https://download.docker.com/linux/centos/8/x86_64/stable/Packages/containerd.io-1.6.24-3.1.el8.x86_64.rpm
    wget -q https://download.docker.com/linux/centos/8/x86_64/stable/Packages/docker-ce-cli-24.0.7-1.el8.x86_64.rpm
    wget -q https://download.docker.com/linux/centos/8/x86_64/stable/Packages/docker-ce-24.0.7-1.el8.x86_64.rpm
    wget -q https://download.docker.com/linux/centos/8/x86_64/stable/Packages/docker-buildx-plugin-0.11.2-1.el8.x86_64.rpm
    wget -q https://download.docker.com/linux/centos/8/x86_64/stable/Packages/docker-compose-plugin-2.21.0-1.el8.x86_64.rpm
    
    # Download Docker Compose standalone
    wget -q -O docker-compose https://github.com/docker/compose/releases/download/v2.21.0/docker-compose-linux-x86_64
    chmod +x docker-compose
    
    cd ../..
    echo "Docker packages downloaded to packages/docker/"
}

# Function to install Docker from local packages
install_docker_offline() {
    echo "Installing Docker from local packages..."
    detect_os
    
    cd packages/docker
    
    case $OS in
        ubuntu|debian)
            echo "Installing Docker on Ubuntu/Debian..."
            sudo dpkg -i *.deb || sudo apt-get install -f -y
            sudo cp docker-compose /usr/local/bin/
            ;;
        centos|rhel|fedora)
            echo "Installing Docker on CentOS/RHEL/Fedora..."
            sudo rpm -ivh *.rpm
            sudo cp docker-compose /usr/local/bin/
            ;;
        *)
            echo "ERROR: Unsupported OS for offline installation"
            exit 1
            ;;
    esac
    
    cd ../..
    
    # Start and enable Docker
    sudo systemctl start docker
    sudo systemctl enable docker
    
    # Add user to docker group
    sudo usermod -aG docker $USER
    
    echo "Docker installed successfully!"
    echo "Please log out and back in to use Docker without sudo"
}

# Main execution
if [ "$1" = "download" ]; then
    detect_os
    case $OS in
        ubuntu|debian)
            download_docker_deb
            ;;
        centos|rhel|fedora)
            download_docker_rpm
            ;;
        *)
            echo "ERROR: Unsupported OS for package download"
            exit 1
            ;;
    esac
elif [ "$1" = "install" ]; then
    if [ ! -d "packages/docker" ] || [ -z "$(ls -A packages/docker)" ]; then
        echo "ERROR: No Docker packages found. Run './install-docker-offline.sh download' first"
        exit 1
    fi
    install_docker_offline
else
    echo "Usage:"
    echo "  ./install-docker-offline.sh download  - Download Docker packages"
    echo "  ./install-docker-offline.sh install   - Install Docker from local packages"
    echo ""
    echo "Run 'download' on a machine with internet, then copy the repo to offline machine and run 'install'"
fi
