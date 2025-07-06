#!/usr/bin/env bash
set -e

# Redis RDI CTF - Environment Setup Script
# This script helps participants set up their local environment

echo "🚀 Redis RDI CTF - Environment Setup"
echo "====================================="
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

# Check if .env file exists
check_env_file() {
    if [ ! -f ".env" ]; then
        print_warning ".env file not found. Creating from template..."
        if [ -f ".env.example" ]; then
            cp .env.example .env
            print_success "✓ Created .env file from template"
            print_warning "⚠ Please edit .env file with your Redis Cloud connection details"
            return 1
        else
            print_error "✗ .env.example file not found"
            return 1
        fi
    fi
    return 0
}

# Test PostgreSQL connection
test_postgres() {
    print_status "Testing PostgreSQL connection..."
    
    if command -v psql >/dev/null 2>&1; then
        if psql -U rdi_user -d rdi_db -h localhost -c "SELECT 1;" >/dev/null 2>&1; then
            print_success "✓ PostgreSQL connection successful"
            return 0
        else
            print_error "✗ Cannot connect to PostgreSQL database 'rdi_db'"
            print_status "Please ensure:"
            echo "  1. PostgreSQL is installed and running"
            echo "  2. Database 'rdi_db' exists"
            echo "  3. User 'rdi_user' has access"
            return 1
        fi
    else
        print_error "✗ psql command not found. Please install PostgreSQL"
        return 1
    fi
}

# Test Redis Cloud connection
test_redis() {
    print_status "Testing Redis Cloud connection..."
    
    # Load environment variables
    if [ -f ".env" ]; then
        export $(cat .env | grep -v '^#' | xargs)
    fi
    
    if [ -z "$REDIS_URL" ]; then
        print_error "✗ REDIS_URL not set in .env file"
        return 1
    fi
    
    if command -v redis-cli >/dev/null 2>&1; then
        if redis-cli -u "$REDIS_URL" ping >/dev/null 2>&1; then
            print_success "✓ Redis Cloud connection successful"
            return 0
        else
            print_error "✗ Cannot connect to Redis Cloud"
            print_status "Please check your REDIS_URL in .env file"
            return 1
        fi
    else
        print_error "✗ redis-cli command not found. Please install Redis CLI"
        return 1
    fi
}

# Load sample data
load_sample_data() {
    print_status "Loading sample data into PostgreSQL..."
    
    if [ -f "seed/postgres.sql" ]; then
        if psql -U rdi_user -d rdi_db -h localhost < seed/postgres.sql >/dev/null 2>&1; then
            print_success "✓ Sample data loaded successfully"
            
            # Show data summary
            user_count=$(psql -U rdi_user -d rdi_db -h localhost -t -c "SELECT COUNT(*) FROM users;" | xargs)
            product_count=$(psql -U rdi_user -d rdi_db -h localhost -t -c "SELECT COUNT(*) FROM products;" | xargs)
            order_count=$(psql -U rdi_user -d rdi_db -h localhost -t -c "SELECT COUNT(*) FROM orders;" | xargs)
            
            print_status "Data summary:"
            echo "  • Users: $user_count"
            echo "  • Products: $product_count" 
            echo "  • Orders: $order_count"
            return 0
        else
            print_error "✗ Failed to load sample data"
            return 1
        fi
    else
        print_error "✗ Sample data file not found: seed/postgres.sql"
        return 1
    fi
}

# Test RDI connection
test_rdi() {
    print_status "Testing RDI connection..."
    
    if command -v curl >/dev/null 2>&1; then
        if curl -s http://localhost:8080/health >/dev/null 2>&1; then
            print_success "✓ RDI is running on port 8080"
            return 0
        else
            print_warning "⚠ RDI not accessible on port 8080"
            print_status "This is optional - you can use RDI later"
            return 1
        fi
    else
        print_warning "⚠ curl command not found. Cannot test RDI connection"
        return 1
    fi
}

# Inject CTF flags
inject_flags() {
    print_status "Injecting CTF flags..."
    
    if [ -f "flags/flag_injector.lua" ]; then
        if redis-cli -u "$REDIS_URL" EVAL "$(cat flags/flag_injector.lua)" 0 >/dev/null 2>&1; then
            print_success "✓ CTF flags injected successfully"
            return 0
        else
            print_error "✗ Failed to inject flags"
            return 1
        fi
    else
        print_error "✗ Flag injector script not found"
        return 1
    fi
}

# Main setup function
main() {
    echo "Starting environment setup..."
    echo ""
    
    # Check environment file
    if ! check_env_file; then
        print_error "Please configure your .env file and run this script again"
        exit 1
    fi
    
    # Test connections
    postgres_ok=false
    redis_ok=false
    
    if test_postgres; then
        postgres_ok=true
    fi
    
    if test_redis; then
        redis_ok=true
    fi
    
    # Load sample data if PostgreSQL is working
    if [ "$postgres_ok" = true ]; then
        load_sample_data
    fi
    
    # Test RDI (optional)
    test_rdi
    
    # Inject flags if Redis is working
    if [ "$redis_ok" = true ]; then
        inject_flags
    fi
    
    echo ""
    print_status "Setup Summary:"
    echo "  • PostgreSQL: $([ "$postgres_ok" = true ] && echo "✓ Ready" || echo "✗ Needs setup")"
    echo "  • Redis Cloud: $([ "$redis_ok" = true ] && echo "✓ Ready" || echo "✗ Needs setup")"
    echo "  • Sample Data: $([ "$postgres_ok" = true ] && echo "✓ Loaded" || echo "✗ Not loaded")"
    echo ""
    
    if [ "$postgres_ok" = true ] && [ "$redis_ok" = true ]; then
        print_success "🎉 Environment setup complete! You're ready for the CTF."
        echo ""
        print_status "Next steps:"
        echo "  1. Open RedisInsight and connect to your Redis Cloud instance"
        echo "  2. Set up RDI (if not already done)"
        echo "  3. Start with Lab 1: labs/01_postgres_to_redis/"
        echo "  4. Check your progress: python3 scripts/check_flags.py"
    else
        print_warning "⚠ Setup incomplete. Please resolve the issues above."
        echo ""
        print_status "Need help? Check the setup guide:"
        echo "  • SIMPLE_TEST_GUIDE.md"
        echo "  • SETUP_INSTRUCTIONS.md"
    fi
}

# Run main function
main "$@"
