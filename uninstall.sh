#!/bin/bash
set -e

# Redis RDI CTF - Safe Uninstall Script
# This script safely removes the Redis RDI CTF project without affecting other Docker containers or system components

echo "🧹 Redis RDI CTF - Safe Uninstall Script"
echo "========================================"
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

# Check if we're in the right directory
if [ ! -f "docker-compose.yml" ] || [ ! -f "Dockerfile" ]; then
    print_error "This doesn't appear to be the Redis RDI CTF directory"
    print_error "Please run this script from the Redis_RDI_CTF directory"
    exit 1
fi

print_status "Starting safe uninstall process..."
echo ""

# Step 1: Stop and remove containers
print_status "Step 1: Stopping and removing Redis RDI CTF containers..."
if command -v docker-compose >/dev/null 2>&1; then
    COMPOSE_CMD="docker-compose"
elif command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
    COMPOSE_CMD="docker compose"
else
    print_warning "Docker Compose not found. Skipping container cleanup."
    COMPOSE_CMD=""
fi

if [ -n "$COMPOSE_CMD" ]; then
    # Stop containers
    print_status "Stopping containers..."
    $COMPOSE_CMD down 2>/dev/null || print_warning "No running containers to stop"
    
    # Remove containers and volumes
    print_status "Removing containers and volumes..."
    $COMPOSE_CMD down -v 2>/dev/null || print_warning "No containers or volumes to remove"
    
    print_success "Containers and volumes removed"
else
    print_warning "Skipping Docker container cleanup (Docker not available)"
fi

echo ""

# Step 2: Remove Docker images (safely)
print_status "Step 2: Removing Redis RDI CTF Docker images..."
if command -v docker >/dev/null 2>&1; then
    # Remove only our specific images
    IMAGES_TO_REMOVE=(
        "redis-rdi-ctf_redis-rdi-ctf"
        "redis-rdi-ctf-redis-rdi-ctf"
        "redis_rdi_ctf_redis-rdi-ctf"
        "redis_rdi_ctf-redis-rdi-ctf"
    )
    
    for image in "${IMAGES_TO_REMOVE[@]}"; do
        if docker images -q "$image" >/dev/null 2>&1; then
            print_status "Removing image: $image"
            docker rmi "$image" 2>/dev/null || print_warning "Could not remove image: $image"
        fi
    done
    
    # Remove dangling images created by this project
    print_status "Removing dangling images..."
    docker image prune -f >/dev/null 2>&1 || print_warning "Could not remove dangling images"
    
    print_success "Docker images cleaned up"
else
    print_warning "Docker not available, skipping image cleanup"
fi

echo ""

# Step 3: Clean up project directory (optional)
print_status "Step 3: Project directory cleanup options..."
echo ""
echo "Choose what to do with the project directory:"
echo "  1) Keep project directory (recommended for future use)"
echo "  2) Remove project directory completely"
echo "  3) Keep directory but clean generated files"
echo ""

read -p "Enter your choice (1-3) [default: 1]: " choice
choice=${choice:-1}

case $choice in
    1)
        print_success "Keeping project directory intact"
        ;;
    2)
        print_warning "This will remove the entire Redis_RDI_CTF directory!"
        read -p "Are you sure? Type 'yes' to confirm: " confirm
        if [ "$confirm" = "yes" ]; then
            cd ..
            rm -rf Redis_RDI_CTF
            print_success "Project directory removed completely"
            echo ""
            print_status "Uninstall complete! The Redis RDI CTF has been completely removed."
            exit 0
        else
            print_status "Directory removal cancelled"
        fi
        ;;
    3)
        print_status "Cleaning generated files..."
        # Remove logs and temporary files
        rm -f *.log 2>/dev/null || true
        rm -rf __pycache__ 2>/dev/null || true
        find . -name "*.pyc" -delete 2>/dev/null || true
        find . -name "*.pyo" -delete 2>/dev/null || true
        find . -name ".DS_Store" -delete 2>/dev/null || true
        print_success "Generated files cleaned"
        ;;
    *)
        print_warning "Invalid choice, keeping directory intact"
        ;;
esac

echo ""

# Step 4: Summary and verification
print_status "Step 4: Verification and summary..."
echo ""

# Check if containers are really gone
if command -v docker >/dev/null 2>&1; then
    REMAINING_CONTAINERS=$(docker ps -a --filter "name=redis-rdi-ctf" --format "{{.Names}}" 2>/dev/null || true)
    if [ -z "$REMAINING_CONTAINERS" ]; then
        print_success "✓ No Redis RDI CTF containers remaining"
    else
        print_warning "⚠ Some containers may still exist: $REMAINING_CONTAINERS"
    fi
    
    # Check for remaining images
    REMAINING_IMAGES=$(docker images --filter "reference=*redis*rdi*ctf*" --format "{{.Repository}}:{{.Tag}}" 2>/dev/null || true)
    if [ -z "$REMAINING_IMAGES" ]; then
        print_success "✓ No Redis RDI CTF images remaining"
    else
        print_warning "⚠ Some images may still exist: $REMAINING_IMAGES"
    fi
fi

echo ""
print_success "🎉 Redis RDI CTF uninstall completed successfully!"
echo ""
print_status "What was removed:"
echo "  ✓ Redis RDI CTF containers"
echo "  ✓ Redis RDI CTF Docker volumes"
echo "  ✓ Redis RDI CTF Docker images"
echo "  ✓ Temporary files (if selected)"
echo ""
print_status "What was NOT affected:"
echo "  ✓ Other Docker containers and images"
echo "  ✓ System Docker installation"
echo "  ✓ Other projects and applications"
echo "  ✓ System packages and dependencies"
echo ""

if [ -d "$(pwd)" ] && [ -f "README.md" ]; then
    print_status "To reinstall Redis RDI CTF:"
    echo "  1. Run: docker-compose up --build"
    echo "  2. Access: http://localhost:8080"
fi

echo ""
print_status "Uninstall complete! 🧹"
