#!/usr/bin/env bash
set -e

# Redis RDI CTF - Complete Automated Setup
# This master script runs all setup scripts in the correct order

echo "🚀 Redis RDI CTF - Complete Setup"
echo "=================================="
echo ""
echo "This script will automatically install and configure:"
echo "  • PostgreSQL with sample music data (~350MB)"
echo "  • Redis RDI (via Docker) (~2.5GB total images)"
echo "  • Python dependencies (~50MB)"
echo "  • Environment configuration"
echo ""
echo "📊 System Requirements:"
echo "  • RAM: 4GB minimum, 8GB+ recommended"
echo "  • Disk: ~3GB free space required"
echo "  • Docker: Will be installed if missing"
echo "  • Python 3.7+ with pip"
echo ""
echo "🐍 Python packages to be installed:"
echo "  • redis>=4.0.0 (Redis client)"
echo "  • psycopg2-binary>=2.9.0 (PostgreSQL adapter)"
echo "  • flask>=2.0.0 (Web framework)"
echo "  • pandas>=1.3.0 (Data manipulation)"
echo "  • sqlalchemy>=1.4.0 (Database toolkit)"
echo "  • python-dotenv>=0.19.0 (Environment variables)"
echo "  • requests>=2.28.0 (HTTP library)"
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

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check if we're in the right directory
check_directory() {
    if [ ! -f "$SCRIPT_DIR/setup_postgres.sh" ] || [ ! -f "$SCRIPT_DIR/setup_rdi.sh" ]; then
        print_error "Setup scripts not found in $SCRIPT_DIR"
        print_error "Please run this script from the Redis_RDI_CTF directory"
        exit 1
    fi
}

# Make scripts executable
make_executable() {
    print_status "Making setup scripts executable..."
    chmod +x "$SCRIPT_DIR"/*.sh
    print_success "✓ Scripts are now executable"
}

# Confirm with user
confirm_setup() {
    echo ""
    print_warning "⚠ This script will install software on your system:"
    echo "  • PostgreSQL (system package)"
    echo "  • Docker (if not already installed)"
    echo "  • Python packages (via pip)"
    echo ""
    read -p "Do you want to continue? (y/N): " -n 1 -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Setup cancelled by user"
        exit 0
    fi
}

# Step 1: PostgreSQL Setup
setup_postgres() {
    echo ""
    echo "=================================================="
    print_status "STEP 1: Setting up PostgreSQL..."
    echo "=================================================="
    
    if bash "$SCRIPT_DIR/setup_postgres.sh"; then
        print_success "✓ PostgreSQL setup completed"
    else
        print_error "✗ PostgreSQL setup failed"
        exit 1
    fi
}

# Step 2: RDI Setup
setup_rdi() {
    echo ""
    echo "=================================================="
    print_status "STEP 2: Setting up Redis RDI..."
    echo "=================================================="
    
    if bash "$SCRIPT_DIR/setup_rdi.sh"; then
        print_success "✓ RDI setup completed"
    else
        print_error "✗ RDI setup failed"
        exit 1
    fi
}

# Step 3: Python Dependencies
setup_python() {
    echo ""
    echo "=================================================="
    print_status "STEP 3: Installing Python dependencies..."
    echo "=================================================="
    
    if [ -f "$SCRIPT_DIR/../requirements.txt" ]; then
        print_status "Installing Python packages..."
        if pip3 install -r "$SCRIPT_DIR/../requirements.txt" >/dev/null 2>&1; then
            print_success "✓ Python dependencies installed"
        else
            print_warning "⚠ Some Python packages may have failed to install"
            print_status "You can install them manually later with:"
            print_status "pip3 install -r requirements.txt"
        fi
    else
        print_warning "⚠ requirements.txt not found, skipping Python dependencies"
    fi
}

# Step 4: Environment Setup
setup_environment() {
    echo ""
    echo "=================================================="
    print_status "STEP 4: Setting up environment..."
    echo "=================================================="
    
    # Create .env file if it doesn't exist
    if [ ! -f "$SCRIPT_DIR/../.env" ]; then
        if [ -f "$SCRIPT_DIR/../.env.example" ]; then
            cp "$SCRIPT_DIR/../.env.example" "$SCRIPT_DIR/../.env"
            print_success "✓ Created .env file from template"
            print_warning "⚠ Please edit .env file with your Redis Cloud connection details"
        else
            print_warning "⚠ .env.example not found, skipping environment setup"
        fi
    else
        print_success "✓ .env file already exists"
    fi
    
    # Run environment setup script if it exists
    if [ -f "$SCRIPT_DIR/setup_environment.sh" ]; then
        print_status "Running environment validation..."
        bash "$SCRIPT_DIR/setup_environment.sh" || true
    fi
}

# Show final instructions
show_final_instructions() {
    echo ""
    echo "=================================================="
    print_success "🎉 SETUP COMPLETE!"
    echo "=================================================="
    echo ""
    print_status "What's been installed:"
    echo "  ✓ PostgreSQL with music database (localhost:5432)"
    echo "  ✓ Redis RDI web interface (http://localhost:8080)"
    echo "  ✓ Python dependencies for data generation"
    echo "  ✓ Sample music data (15 tracks, 8 albums)"
    echo ""
    print_status "Next steps:"
    echo "  1. Edit .env file with your Redis Cloud connection details"
    echo "  2. Open http://localhost:8080 in your browser"
    echo "  3. Create your first RDI pipeline:"
    echo "     • Source: postgresql://rdi_user:rdi_password@localhost:5432/rdi_db"
    echo "     • Target: Your Redis Cloud connection string"
    echo "     • Table: Track (or Album, Genre, MediaType)"
    echo "  4. Start the labs in the labs/ directory"
    echo ""
    print_status "Useful commands:"
    echo "  • Test PostgreSQL: psql -U rdi_user -d rdi_db -h localhost"
    echo "  • Generate data: python3 scripts/generate_load.py"
    echo "  • Check flags: python3 scripts/check_flags.py"
    echo "  • View RDI logs: docker logs redis-rdi"
    echo ""
    print_status "Need help? Check the documentation:"
    echo "  • SIMPLE_TEST_GUIDE.md - Step-by-step testing"
    echo "  • SETUP_INSTRUCTIONS.md - Detailed setup guide"
    echo "  • labs/ - CTF challenges and exercises"
    echo ""
    print_success "Happy learning! 🎵🔗"
}

# Main setup function
main() {
    print_status "Starting complete Redis RDI CTF setup..."
    
    # Pre-flight checks
    check_directory
    make_executable
    confirm_setup
    
    # Run setup steps
    setup_postgres
    setup_rdi
    setup_python
    setup_environment
    
    # Show final instructions
    show_final_instructions
}

# Handle interruption
trap 'echo ""; print_warning "Setup interrupted by user"; exit 1' INT

# Run main function
main "$@"
