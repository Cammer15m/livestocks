#!/usr/bin/env bash
set -e

# Redis RDI CTF - RDI Automated Setup
# This script automatically installs and configures Redis RDI

echo "🔗 Redis RDI CTF - RDI Setup"
echo "============================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Docker is installed
check_docker() {
    if command -v docker >/dev/null 2>&1; then
        if docker info >/dev/null 2>&1; then
            print_success "✓ Docker is installed and running"
            return 0
        else
            print_error "✗ Docker is installed but not running"
            print_status "Please start Docker and re-run this script"
            return 1
        fi
    else
        return 1
    fi
}

# Install Docker based on OS
install_docker() {
    local os=$(uname -s)
    print_status "Installing Docker..."
    
    case $os in
        "Linux")
            if [ -f /etc/debian_version ]; then
                # Debian/Ubuntu
                print_status "Installing Docker on Debian/Ubuntu..."
                sudo apt update
                sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release
                curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
                echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
                sudo apt update
                sudo apt install -y docker-ce docker-ce-cli containerd.io
                sudo systemctl start docker
                sudo systemctl enable docker
                sudo usermod -aG docker $USER
            elif [ -f /etc/redhat-release ]; then
                # RedHat/CentOS
                print_status "Installing Docker on RedHat/CentOS..."
                sudo yum install -y yum-utils
                sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
                sudo yum install -y docker-ce docker-ce-cli containerd.io
                sudo systemctl start docker
                sudo systemctl enable docker
                sudo usermod -aG docker $USER
            fi
            ;;
        "Darwin")
            print_error "macOS detected. Please install Docker Desktop manually:"
            print_error "1. Download from: https://www.docker.com/products/docker-desktop"
            print_error "2. Install and start Docker Desktop"
            print_error "3. Re-run this script"
            exit 1
            ;;
        *)
            print_error "Unsupported operating system for automatic Docker installation"
            print_error "Please install Docker manually and re-run this script"
            exit 1
            ;;
    esac
    
    print_warning "⚠ You may need to log out and back in for Docker group membership to take effect"
    print_warning "Or run: newgrp docker"
}

# Pull RDI Docker image
pull_rdi_image() {
    print_status "Pulling Redis RDI Docker image..."
    
    # Try to pull the latest RDI image
    if docker pull redis/rdi:latest >/dev/null 2>&1; then
        print_success "✓ Redis RDI image pulled successfully"
    else
        print_warning "⚠ Could not pull redis/rdi:latest, trying alternative..."
        # Try alternative image names
        if docker pull redislabs/rdi:latest >/dev/null 2>&1; then
            print_success "✓ Redis RDI image pulled successfully (alternative)"
        else
            print_error "✗ Could not pull Redis RDI image"
            print_error "Please check your internet connection and Docker installation"
            return 1
        fi
    fi
}

# Stop existing RDI container if running
stop_existing_rdi() {
    if docker ps -q -f name=redis-rdi >/dev/null 2>&1; then
        print_status "Stopping existing RDI container..."
        docker stop redis-rdi >/dev/null 2>&1 || true
        docker rm redis-rdi >/dev/null 2>&1 || true
        print_success "✓ Existing RDI container stopped"
    fi
}

# Start RDI container
start_rdi_container() {
    print_status "Starting Redis RDI container..."
    
    # Stop any existing container
    stop_existing_rdi
    
    # Start new RDI container
    if docker run -d \
        --name redis-rdi \
        -p 8080:8080 \
        -p 8081:8081 \
        --restart unless-stopped \
        redis/rdi:latest >/dev/null 2>&1; then
        print_success "✓ RDI container started successfully"
    else
        # Try alternative image
        if docker run -d \
            --name redis-rdi \
            -p 8080:8080 \
            -p 8081:8081 \
            --restart unless-stopped \
            redislabs/rdi:latest >/dev/null 2>&1; then
            print_success "✓ RDI container started successfully (alternative image)"
        else
            print_error "✗ Failed to start RDI container"
            return 1
        fi
    fi
}

# Wait for RDI to be ready
wait_for_rdi() {
    print_status "Waiting for RDI to be ready..."
    
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s http://localhost:8080/health >/dev/null 2>&1; then
            print_success "✓ RDI is ready and responding"
            return 0
        fi
        
        echo -n "."
        sleep 2
        attempt=$((attempt + 1))
    done
    
    echo ""
    print_error "✗ RDI did not become ready within 60 seconds"
    print_status "Checking container logs..."
    docker logs redis-rdi --tail 20
    return 1
}

# Test RDI connection
test_rdi() {
    print_status "Testing RDI connection..."
    
    if curl -s http://localhost:8080/health | grep -q "ok" 2>/dev/null; then
        print_success "✓ RDI health check passed"
        return 0
    else
        print_error "✗ RDI health check failed"
        return 1
    fi
}

# Show RDI information
show_rdi_info() {
    echo ""
    print_success "🎉 Redis RDI setup complete!"
    echo ""
    print_status "RDI Access Information:"
    echo "  • Web UI: http://localhost:8080"
    echo "  • API: http://localhost:8081"
    echo "  • Container: redis-rdi"
    echo ""
    print_status "Useful Docker commands:"
    echo "  • View logs: docker logs redis-rdi"
    echo "  • Stop RDI: docker stop redis-rdi"
    echo "  • Start RDI: docker start redis-rdi"
    echo "  • Restart RDI: docker restart redis-rdi"
    echo ""
    print_status "Next step: Open http://localhost:8080 in your browser"
}

# Main setup function
main() {
    print_status "Starting Redis RDI setup..."
    echo ""
    
    # Check Docker installation
    if ! check_docker; then
        print_status "Docker not found. Installing Docker..."
        install_docker
        
        # Re-check Docker after installation
        if ! check_docker; then
            print_error "Docker installation failed or Docker is not running"
            exit 1
        fi
    fi
    
    # Pull RDI image
    if ! pull_rdi_image; then
        exit 1
    fi
    
    # Start RDI container
    if ! start_rdi_container; then
        exit 1
    fi
    
    # Wait for RDI to be ready
    if ! wait_for_rdi; then
        exit 1
    fi
    
    # Test RDI
    if test_rdi; then
        show_rdi_info
    else
        print_error "RDI setup completed but health check failed"
        print_status "Try accessing http://localhost:8080 manually"
    fi
}

# Run main function
main "$@"
