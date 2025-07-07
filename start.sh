#!/bin/bash

# Redis RDI Training Environment Startup Script
# Handles cleanup, validation, and robust startup

set -e  # Exit on any error

# ---------------------------------------------------------------------------
# Configuration and Validation
# ---------------------------------------------------------------------------
: ${DOMAIN?"Need to set DOMAIN environment variable"}
[ -z "$PASSWORD" ] && export PASSWORD=redislabs

echo "Redis RDI Training Environment Startup"
echo "======================================="
echo "Domain: $DOMAIN"
echo "Password: [MASKED]"
echo ""

# ---------------------------------------------------------------------------
# Pre-flight Checks and Docker Installation
# ---------------------------------------------------------------------------
echo "Running pre-flight checks..."

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

# Function to install Docker
install_docker() {
    echo "Docker not found. Installing Docker..."
    detect_os

    case $OS in
        ubuntu|debian)
            echo "  - Detected Ubuntu/Debian system"
            echo "  - Updating package lists..."
            sudo apt update -qq
            echo "  - Installing Docker and Docker Compose..."
            sudo apt install -y docker.io docker-compose curl
            sudo systemctl start docker
            sudo systemctl enable docker
            # Add current user to docker group
            sudo usermod -aG docker $USER
            echo "  - Docker installation completed"
            ;;
        centos|rhel|fedora)
            echo "  - Detected CentOS/RHEL/Fedora system"
            if command -v dnf >/dev/null 2>&1; then
                sudo dnf install -y docker docker-compose curl
            else
                sudo yum install -y docker docker-compose curl
            fi
            sudo systemctl start docker
            sudo systemctl enable docker
            sudo usermod -aG docker $USER
            echo "  - Docker installation completed"
            ;;
        *)
            echo "ERROR: Unsupported OS ($OS). Please install Docker manually."
            echo "Visit: https://docs.docker.com/engine/install/"
            exit 1
            ;;
    esac

    echo "  - Waiting for Docker to start..."
    sleep 5
}

# Check if Docker is installed
if ! command -v docker >/dev/null 2>&1; then
    install_docker
fi

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    echo "  - Docker is installed but not running. Starting Docker..."
    sudo systemctl start docker
    sleep 5

    # Check again
    if ! docker info >/dev/null 2>&1; then
        echo "ERROR: Failed to start Docker. Please check Docker installation."
        exit 1
    fi
fi

# Check if Docker Compose is available
if ! command -v docker-compose >/dev/null 2>&1; then
    echo "  - Docker Compose not found. Installing..."
    detect_os

    case $OS in
        ubuntu|debian)
            sudo apt install -y docker-compose
            ;;
        centos|rhel|fedora)
            if command -v dnf >/dev/null 2>&1; then
                sudo dnf install -y docker-compose
            else
                sudo yum install -y docker-compose
            fi
            ;;
        *)
            # Fallback: install via pip or direct download
            echo "  - Installing Docker Compose via pip..."
            sudo apt install -y python3-pip 2>/dev/null || sudo yum install -y python3-pip 2>/dev/null || true
            sudo pip3 install docker-compose 2>/dev/null || {
                echo "  - Installing Docker Compose directly..."
                sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
                sudo chmod +x /usr/local/bin/docker-compose
            }
            ;;
    esac
fi

# Final check
if ! command -v docker-compose >/dev/null 2>&1; then
    echo "ERROR: Docker Compose installation failed. Please install manually."
    exit 1
fi

echo "SUCCESS: Docker and Docker Compose are available"

# Check if user is in docker group
if ! groups $USER | grep -q docker; then
    echo "WARNING: User $USER is not in docker group."
    echo "You may need to log out and back in, or run: newgrp docker"
fi

# Install additional dependencies if needed
echo "  - Checking additional dependencies..."
missing_deps=()

# Check for curl
if ! command -v curl >/dev/null 2>&1; then
    missing_deps+=("curl")
fi

# Check for git
if ! command -v git >/dev/null 2>&1; then
    missing_deps+=("git")
fi

# Check for envsubst (part of gettext)
if ! command -v envsubst >/dev/null 2>&1; then
    missing_deps+=("gettext-base")
fi

# Install missing dependencies
if [ ${#missing_deps[@]} -gt 0 ]; then
    echo "  - Installing missing dependencies: ${missing_deps[*]}"
    detect_os

    case $OS in
        ubuntu|debian)
            sudo apt install -y "${missing_deps[@]}"
            ;;
        centos|rhel|fedora)
            if command -v dnf >/dev/null 2>&1; then
                sudo dnf install -y "${missing_deps[@]}"
            else
                sudo yum install -y "${missing_deps[@]}"
            fi
            ;;
    esac
fi

# ---------------------------------------------------------------------------
# Cleanup Previous Runs
# ---------------------------------------------------------------------------
echo ""
echo "Cleaning up any previous runs..."

# Stop and remove any existing containers
if docker-compose ps -q 2>/dev/null | grep -q .; then
    echo "  - Stopping existing containers..."
    docker-compose down --remove-orphans --volumes 2>/dev/null || true
fi

# Remove any orphaned containers from old setups
echo "  - Removing orphaned containers..."
docker stop $(docker ps -q --filter "name=rdi-ctf") 2>/dev/null || true
docker rm $(docker ps -aq --filter "name=rdi-ctf") 2>/dev/null || true
docker stop $(docker ps -q --filter "name=redis-rdi-ctf") 2>/dev/null || true
docker rm $(docker ps -aq --filter "name=redis-rdi-ctf") 2>/dev/null || true

# Clean up any dangling resources
echo "  - Cleaning up Docker resources..."
docker system prune -f >/dev/null 2>&1 || true

echo "SUCCESS: Cleanup completed"

# ---------------------------------------------------------------------------
# Environment Setup
# ---------------------------------------------------------------------------
echo ""
echo "Setting up environment..."

sudo chmod -R 777 grafana/ 2>/dev/null || chmod -R 777 grafana/ 2>/dev/null || true

export HOSTNAME=$(hostname -s)
export PASSWORD=$PASSWORD
export HOST_IP=$(hostname -I | awk '{print $1}')
export RDI_VERSION=1.10.0

echo "  - Hostname: $HOSTNAME"
echo "  - Host IP: $HOST_IP"
echo "  - RDI Version: $RDI_VERSION"

# Generate configuration files
echo "  - Generating configuration files..."
if [ -f "./grafana_config/grafana.ini.template" ]; then
    envsubst < ./grafana_config/grafana.ini.template > ./grafana_config/grafana.ini
    echo "    SUCCESS: Grafana config generated"
else
    echo "    WARNING: Grafana template not found, using defaults"
fi

if [ -f "./prometheus/prometheus.yml.template" ]; then
    envsubst < ./prometheus/prometheus.yml.template > ./prometheus/prometheus.yml
    echo "    SUCCESS: Prometheus config generated"
else
    echo "    WARNING: Prometheus template not found, using defaults"
fi

# ---------------------------------------------------------------------------
# Docker Compose Startup
# ---------------------------------------------------------------------------
echo ""
echo "Starting Docker containers..."

# Wait for snap/bin if needed (some systems)
if [ -d "/snap/bin" ]; then
    while [ ! -x /snap/bin ]; do
        echo "  - Waiting for /snap/bin to be ready..."
        sleep 5
    done
fi

# Start containers with build
echo "  - Building and starting containers..."
docker-compose up -d --build --remove-orphans

# ---------------------------------------------------------------------------
# Container Health Checks
# ---------------------------------------------------------------------------
echo ""
echo "Waiting for containers to be healthy..."

# Wait for containers to start
sleep 10

# Check container status
echo "  - Checking container status..."
failed_containers=()
for container in $(docker-compose ps --services); do
    if ! docker-compose ps $container | grep -q "Up"; then
        failed_containers+=($container)
    fi
done

if [ ${#failed_containers[@]} -gt 0 ]; then
    echo "ERROR: Some containers failed to start: ${failed_containers[*]}"
    echo "Container logs:"
    for container in "${failed_containers[@]}"; do
        echo "--- $container ---"
        docker-compose logs --tail=10 $container
    done
    exit 1
fi

echo "SUCCESS: All containers started successfully"

# ---------------------------------------------------------------------------
# Service Configuration
# ---------------------------------------------------------------------------
echo ""
echo "Configuring services..."

# Wait for PostgreSQL to be ready
echo "  - Waiting for PostgreSQL to be ready..."
timeout=60
while ! docker exec postgresql pg_isready -U postgres >/dev/null 2>&1; do
    timeout=$((timeout - 1))
    if [ $timeout -eq 0 ]; then
        echo "ERROR: PostgreSQL failed to start within 60 seconds"
        exit 1
    fi
    sleep 1
done
echo "    SUCCESS: PostgreSQL is ready"

# Configure Grafana
echo "  - Configuring Grafana dashboards..."
if [ -d "grafana" ] && [ -f "grafana/config_grafana.sh" ]; then
    cd grafana
    bash config_grafana.sh 2>/dev/null || echo "    WARNING: Grafana configuration failed, continuing..."
    cd ..
    echo "    SUCCESS: Grafana configured"
else
    echo "    WARNING: Grafana configuration script not found"
fi

# Final container restart to ensure everything is properly configured
echo "  - Final service restart..."
sleep 10
docker-compose up -d
sleep 10


# ---------------------------------------------------------------------------
# Final Health Checks and Service Verification
# ---------------------------------------------------------------------------
echo ""
echo "Running final health checks..."

# Check all expected containers are running
expected_containers=("postgresql" "grafana" "prometheus" "redis-insight" "rdi-cli" "sqlpad")
failed_services=()

for container in "${expected_containers[@]}"; do
    if docker ps --format "table {{.Names}}" | grep -q "^$container$"; then
        echo "  SUCCESS: $container is running"
    else
        echo "  ERROR: $container is not running"
        failed_services+=($container)
    fi
done

# Check service ports
echo "  - Checking service ports..."
services_to_check=(
    "5540:Redis Insight"
    "3000:Grafana"
    "5432:PostgreSQL"
    "9090:Prometheus"
    "3001:SQLPad"
)

for service in "${services_to_check[@]}"; do
    port=$(echo $service | cut -d: -f1)
    name=$(echo $service | cut -d: -f2)

    if netstat -tuln 2>/dev/null | grep -q ":$port " || ss -tuln 2>/dev/null | grep -q ":$port "; then
        echo "    SUCCESS: $name (port $port) is accessible"
    else
        echo "    WARNING: $name (port $port) may not be ready yet"
    fi
done

# ---------------------------------------------------------------------------
# Terminal Setup (Optional)
# ---------------------------------------------------------------------------
echo ""
echo "🖥️ Setting up terminal access..."

if command -v ttyd >/dev/null 2>&1 && id -u labuser >/dev/null 2>&1; then
    echo "   • Starting ttyd terminal on port 7681..."
    sudo -u labuser nohup ttyd -W -p 7681 -t disableLeaveAlert=true -t fontSize=14 -t 'cursorStyle=bar' --client-option reconnect=true bash -c "cd /home/labuser && exec bash" >/dev/null 2>&1 &
    echo "   ✅ Terminal available at http://localhost:7681"
else
    echo "   ⚠️  ttyd or labuser not available, skipping terminal setup"
fi

# ---------------------------------------------------------------------------
# Startup Complete
# ---------------------------------------------------------------------------
echo ""
echo "🎉 Redis RDI Training Environment Started Successfully!"
echo "======================================================"
echo ""
echo "📊 Available Services:"
echo "   • Redis Enterprise UI:  http://localhost:8443"
echo "   • Redis Insight:         http://localhost:5540"
echo "   • Grafana Monitoring:    http://localhost:3000"
echo "   • PostgreSQL Database:   localhost:5432"
echo "   • Prometheus Metrics:    http://localhost:9090"
echo "   • SQLPad (DB Browser):   http://localhost:3001"
echo "   • Docker Logs (Dozzle):  http://localhost:8080"
if command -v ttyd >/dev/null 2>&1; then
echo "   • Terminal Access:       http://localhost:7681"
fi
echo ""
echo "🔐 Default Credentials:"
echo "   • Redis Enterprise:      admin@rl.org / $PASSWORD"
echo "   • Grafana:               admin / $PASSWORD"
echo "   • PostgreSQL:            postgres / postgres"
echo ""
echo "🚀 Next Steps:"
echo "   1. Access Redis Enterprise UI to create databases"
echo "   2. Use Redis Insight to configure RDI pipelines"
echo "   3. Monitor with Grafana dashboards"
echo "   4. Check PostgreSQL data with SQLPad"
echo ""

if [ ${#failed_services[@]} -gt 0 ]; then
    echo "⚠️  Warning: Some services failed to start: ${failed_services[*]}"
    echo "   Check logs with: docker-compose logs [service-name]"
    echo ""
fi

echo "📋 Useful Commands:"
echo "   • View logs:     docker-compose logs -f [service]"
echo "   • Stop all:      ./stop.sh"
echo "   • Restart:       ./start.sh"
echo ""
echo "✅ Environment is ready for Redis RDI training!"
