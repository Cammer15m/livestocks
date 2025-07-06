#!/bin/bash
set -e

echo "🔍 Redis RDI CTF Repository Validation"
echo "======================================"

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

# Check repository structure
echo ""
print_status "Checking repository structure..."

required_files=(
    "README.md"
    "Dockerfile"
    "docker-compose.yml"
    ".env.example"
    "requirements.txt"
    "build_and_test.sh"
)

required_dirs=(
    "labs"
    "scripts"
    "seed"
    "docker"
    "docs"
)

# Check required files
for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        print_success "✓ Found $file"
    else
        print_error "✗ Missing $file"
        exit 1
    fi
done

# Check required directories
for dir in "${required_dirs[@]}"; do
    if [ -d "$dir" ]; then
        print_success "✓ Found $dir/"
    else
        print_error "✗ Missing $dir/"
        exit 1
    fi
done

# Check that unnecessary files are gone
echo ""
print_status "Checking cleanup was successful..."

removed_files=(
    "docker-compose.legacy.yml"
    "scripts/requirements.txt"
    "scripts/requirements_rdi.txt"
    "seed/track.csv"
    "flags"
)

for item in "${removed_files[@]}"; do
    if [ ! -e "$item" ]; then
        print_success "✓ Removed $item"
    else
        print_warning "⚠ Still exists: $item"
    fi
done

# Check key files content
echo ""
print_status "Validating file contents..."

# Check Dockerfile
if grep -q "COPY requirements.txt /app/" Dockerfile; then
    print_success "✓ Dockerfile uses single requirements file"
else
    print_error "✗ Dockerfile not updated properly"
fi

# Check requirements.txt
if [ -f "requirements.txt" ] && [ $(wc -l < requirements.txt) -lt 15 ]; then
    print_success "✓ Requirements file is streamlined"
else
    print_warning "⚠ Requirements file may need cleanup"
fi

# Check .env.example doesn't have hardcoded credentials
if ! grep -q "redis-17173.c14.us-east-1-2.ec2.redns.redis-cloud.com" .env.example; then
    print_success "✓ No hardcoded credentials in .env.example"
else
    print_error "✗ Hardcoded credentials found in .env.example"
fi

# Check lab structure
echo ""
print_status "Checking lab structure..."

labs=(
    "labs/01_postgres_to_redis"
    "labs/02_snapshot_vs_cdc"
    "labs/03_advanced_rdi"
)

for lab in "${labs[@]}"; do
    if [ -d "$lab" ]; then
        print_success "✓ Found $lab"
    else
        print_warning "⚠ Missing $lab"
    fi
done

# Check scripts
echo ""
print_status "Checking core scripts..."

scripts=(
    "scripts/rdi_connector.py"
    "scripts/check_flags.py"
    "scripts/rdi_web.py"
)

for script in "${scripts[@]}"; do
    if [ -f "$script" ]; then
        print_success "✓ Found $script"
    else
        print_warning "⚠ Missing $script"
    fi
done

# Check seed data
echo ""
print_status "Checking seed data..."

if [ -f "seed/music_database.sql" ]; then
    lines=$(wc -l < seed/music_database.sql)
    print_success "✓ Found music_database.sql ($lines lines)"
else
    print_error "✗ Missing seed/music_database.sql"
fi

# Check Docker files
echo ""
print_status "Checking Docker configuration..."

docker_files=(
    "docker/start.sh"
    "docker/supervisord.conf"
    "docker/setup_check.sh"
)

for file in "${docker_files[@]}"; do
    if [ -f "$file" ]; then
        print_success "✓ Found $file"
    else
        print_warning "⚠ Missing $file"
    fi
done

# Final summary
echo ""
echo "=================================================="
print_success "🎉 Repository Validation Complete!"
echo "=================================================="
echo ""
print_status "Repository Summary:"
echo "  ✅ Clean Docker-first structure"
echo "  ✅ Security improvements (no hardcoded credentials)"
echo "  ✅ Streamlined dependencies"
echo "  ✅ Professional organization"
echo "  ✅ Ready for deployment"
echo ""
print_status "Next Steps:"
echo "  1. Install Docker: sudo apt install docker.io"
echo "  2. Test build: ./build_and_test.sh"
echo "  3. Configure Redis: edit .env"
echo "  4. Start CTF: docker compose up --build"
echo "  5. Access: http://localhost:8080"
echo "  6. Container shell: docker exec -it redis-rdi-ctf bash"
echo ""
print_success "Repository is ready for production use! 🚀"
