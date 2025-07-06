#!/usr/bin/env bash
set -e

# Redis RDI CTF - Complete Uninstall Script
# This script removes all components installed by install_all.sh

echo "🗑️ Redis RDI CTF - Complete Uninstall"
echo "======================================"
echo ""
echo "This script will remove:"
echo "  • Docker containers and images (~2.5GB)"
echo "  • PostgreSQL database and user"
echo "  • Docker volumes and networks"
echo "  • Environment configuration files"
echo "  • Optionally: PostgreSQL system package"
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

# Confirm with user
confirm_uninstall() {
    echo ""
    print_warning "⚠ This will permanently remove:"
    echo "  • All CTF data and progress"
    echo "  • Docker containers and images"
    echo "  • PostgreSQL database 'rdi_db' and user 'rdi_user'"
    echo "  • Configuration files (.env)"
    echo ""
    read -p "Are you sure you want to continue? (y/N): " -n 1 -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Uninstall cancelled by user"
        exit 0
    fi
}

# Stop and remove Docker containers
cleanup_docker_containers() {
    echo ""
    echo "=================================================="
    print_status "STEP 1: Removing Docker containers..."
    echo "=================================================="
    
    if command -v docker >/dev/null 2>&1; then
        # Stop containers
        print_status "Stopping Docker containers..."
        if docker-compose down >/dev/null 2>&1; then
            print_success "✓ Docker containers stopped"
        else
            print_warning "⚠ docker-compose down failed (containers may not exist)"
        fi
        
        # Remove individual containers if they exist
        containers=("postgres" "redis" "redisinsight" "sqlpad" "redis-rdi" "loadgen")
        for container in "${containers[@]}"; do
            if docker ps -a --format "table {{.Names}}" | grep -q "^${container}$"; then
                print_status "Removing container: $container"
                docker rm -f "$container" >/dev/null 2>&1 || true
                print_success "✓ Removed $container"
            fi
        done
    else
        print_warning "⚠ Docker not found, skipping container cleanup"
    fi
}

# Remove Docker images
cleanup_docker_images() {
    echo ""
    echo "=================================================="
    print_status "STEP 2: Removing Docker images..."
    echo "=================================================="
    
    if command -v docker >/dev/null 2>&1; then
        images=("postgres:15" "redis:7-alpine" "redis/redisinsight:latest" "sqlpad/sqlpad:6" "redis/rdi:latest")
        
        for image in "${images[@]}"; do
            if docker images --format "table {{.Repository}}:{{.Tag}}" | grep -q "^${image}$"; then
                print_status "Removing image: $image"
                docker rmi "$image" >/dev/null 2>&1 || true
                print_success "✓ Removed $image"
            fi
        done
        
        # Remove any dangling images
        print_status "Removing dangling images..."
        docker image prune -f >/dev/null 2>&1 || true
        print_success "✓ Cleaned up dangling images"
    else
        print_warning "⚠ Docker not found, skipping image cleanup"
    fi
}

# Remove Docker volumes and networks
cleanup_docker_volumes() {
    echo ""
    echo "=================================================="
    print_status "STEP 3: Removing Docker volumes and networks..."
    echo "=================================================="
    
    if command -v docker >/dev/null 2>&1; then
        # Remove volumes
        volumes=("redis_rdi_ctf_postgres_data" "redis_rdi_ctf_redis_data" "redis_rdi_ctf_redisinsight_data")
        for volume in "${volumes[@]}"; do
            if docker volume ls --format "table {{.Name}}" | grep -q "^${volume}$"; then
                print_status "Removing volume: $volume"
                docker volume rm "$volume" >/dev/null 2>&1 || true
                print_success "✓ Removed $volume"
            fi
        done
        
        # Remove network
        if docker network ls --format "table {{.Name}}" | grep -q "^redis_rdi_ctf_ctf_network$"; then
            print_status "Removing network: redis_rdi_ctf_ctf_network"
            docker network rm redis_rdi_ctf_ctf_network >/dev/null 2>&1 || true
            print_success "✓ Removed network"
        fi
        
        # Clean up unused volumes
        print_status "Removing unused volumes..."
        docker volume prune -f >/dev/null 2>&1 || true
        print_success "✓ Cleaned up unused volumes"
    else
        print_warning "⚠ Docker not found, skipping volume cleanup"
    fi
}

# Remove PostgreSQL database and user
cleanup_postgresql() {
    echo ""
    echo "=================================================="
    print_status "STEP 4: Cleaning up PostgreSQL..."
    echo "=================================================="
    
    if command -v psql >/dev/null 2>&1; then
        # Drop database
        print_status "Dropping database 'rdi_db'..."
        if sudo -u postgres psql -c "DROP DATABASE IF EXISTS rdi_db;" >/dev/null 2>&1; then
            print_success "✓ Database 'rdi_db' removed"
        else
            print_warning "⚠ Could not drop database (may not exist)"
        fi
        
        # Drop user
        print_status "Dropping user 'rdi_user'..."
        if sudo -u postgres psql -c "DROP USER IF EXISTS rdi_user;" >/dev/null 2>&1; then
            print_success "✓ User 'rdi_user' removed"
        else
            print_warning "⚠ Could not drop user (may not exist)"
        fi
    else
        print_warning "⚠ PostgreSQL not found, skipping database cleanup"
    fi
}

# Remove configuration files
cleanup_config() {
    echo ""
    echo "=================================================="
    print_status "STEP 5: Removing configuration files..."
    echo "=================================================="
    
    # Get script directory
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    # Remove .env file
    if [ -f "$SCRIPT_DIR/../.env" ]; then
        print_status "Removing .env file..."
        rm "$SCRIPT_DIR/../.env"
        print_success "✓ Removed .env file"
    else
        print_status "No .env file found"
    fi
}

# Optional: Remove PostgreSQL system package
optional_remove_postgresql() {
    echo ""
    echo "=================================================="
    print_status "OPTIONAL: Remove PostgreSQL system package"
    echo "=================================================="
    
    print_warning "⚠ This will remove PostgreSQL completely from your system"
    print_warning "⚠ This may affect other applications using PostgreSQL"
    echo ""
    read -p "Remove PostgreSQL system package? (y/N): " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if command -v apt-get >/dev/null 2>&1; then
            print_status "Removing PostgreSQL (Debian/Ubuntu)..."
            sudo apt-get remove --purge postgresql postgresql-* -y >/dev/null 2>&1 || true
            sudo apt-get autoremove -y >/dev/null 2>&1 || true
            print_success "✓ PostgreSQL removed"
        elif command -v yum >/dev/null 2>&1; then
            print_status "Removing PostgreSQL (RHEL/CentOS)..."
            sudo yum remove postgresql postgresql-* -y >/dev/null 2>&1 || true
            print_success "✓ PostgreSQL removed"
        elif command -v brew >/dev/null 2>&1; then
            print_status "Removing PostgreSQL (macOS)..."
            brew uninstall postgresql >/dev/null 2>&1 || true
            print_success "✓ PostgreSQL removed"
        else
            print_warning "⚠ Could not determine package manager"
        fi
    else
        print_status "Keeping PostgreSQL system package"
    fi
}

# Show Python packages info
show_python_packages() {
    echo ""
    echo "=================================================="
    print_status "Python packages information"
    echo "=================================================="
    
    print_status "The following Python packages were installed:"
    echo "  • redis>=4.0.0"
    echo "  • psycopg2-binary>=2.9.0"
    echo "  • flask>=2.0.0"
    echo "  • pandas>=1.3.0"
    echo "  • sqlalchemy>=1.4.0"
    echo "  • python-dotenv>=0.19.0"
    echo "  • requests>=2.28.0"
    echo ""
    print_warning "⚠ Python packages are NOT automatically removed"
    print_warning "⚠ They may be used by other projects"
    echo ""
    print_status "To remove them manually (if desired):"
    echo "  pip3 uninstall redis psycopg2-binary flask pandas sqlalchemy python-dotenv requests"
}

# Show final status
show_final_status() {
    echo ""
    echo "=================================================="
    print_success "🎉 UNINSTALL COMPLETE!"
    echo "=================================================="
    echo ""
    print_status "What was removed:"
    echo "  ✓ Docker containers and images"
    echo "  ✓ PostgreSQL database and user"
    echo "  ✓ Docker volumes and networks"
    echo "  ✓ Configuration files"
    echo ""
    print_status "What remains:"
    echo "  • Python packages (manual removal required)"
    echo "  • Docker Engine (if you want to keep it)"
    echo "  • PostgreSQL system package (if you chose to keep it)"
    echo ""
    print_success "Your system has been cleaned up! 🧹"
}

# Main uninstall function
main() {
    print_status "Starting complete Redis RDI CTF uninstall..."
    
    # Confirm with user
    confirm_uninstall
    
    # Run cleanup steps
    cleanup_docker_containers
    cleanup_docker_images
    cleanup_docker_volumes
    cleanup_postgresql
    cleanup_config
    
    # Optional steps
    optional_remove_postgresql
    show_python_packages
    
    # Show final status
    show_final_status
}

# Handle interruption
trap 'echo ""; print_warning "Uninstall interrupted by user"; exit 1' INT

# Run main function
main "$@"
