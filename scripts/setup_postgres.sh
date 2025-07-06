#!/usr/bin/env bash
set -e

# Redis RDI CTF - PostgreSQL Automated Setup
# This script automatically installs and configures PostgreSQL

echo "🗄️ Redis RDI CTF - PostgreSQL Setup"
echo "===================================="
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

# Detect operating system
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [ -f /etc/debian_version ]; then
            echo "debian"
        elif [ -f /etc/redhat-release ]; then
            echo "redhat"
        else
            echo "linux"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
        echo "windows"
    else
        echo "unknown"
    fi
}

# Install PostgreSQL based on OS
install_postgres() {
    local os=$(detect_os)
    print_status "Detected OS: $os"
    
    case $os in
        "debian")
            print_status "Installing PostgreSQL on Debian/Ubuntu..."
            sudo apt update
            sudo apt install -y postgresql postgresql-contrib
            sudo systemctl start postgresql
            sudo systemctl enable postgresql
            ;;
        "redhat")
            print_status "Installing PostgreSQL on RedHat/CentOS..."
            sudo yum install -y postgresql-server postgresql-contrib
            sudo postgresql-setup initdb
            sudo systemctl start postgresql
            sudo systemctl enable postgresql
            ;;
        "macos")
            print_status "Installing PostgreSQL on macOS..."
            if command -v brew >/dev/null 2>&1; then
                brew install postgresql@15
                brew services start postgresql@15
            else
                print_error "Homebrew not found. Please install Homebrew first:"
                print_error "https://brew.sh"
                exit 1
            fi
            ;;
        "windows")
            print_error "Windows detected. Please install PostgreSQL manually:"
            print_error "1. Download from: https://www.postgresql.org/download/windows/"
            print_error "2. Run the installer"
            print_error "3. Set password for 'postgres' user"
            print_error "4. Re-run this script after installation"
            exit 1
            ;;
        *)
            print_error "Unsupported operating system: $os"
            print_error "Please install PostgreSQL manually and re-run this script"
            exit 1
            ;;
    esac
}

# Check if PostgreSQL is already installed
check_postgres() {
    if command -v psql >/dev/null 2>&1; then
        print_success "✓ PostgreSQL is already installed"
        return 0
    else
        return 1
    fi
}

# Create database and user
setup_database() {
    print_status "Setting up CTF database..."
    
    # Try to create user and database
    if sudo -u postgres psql -c "CREATE USER rdi_user WITH PASSWORD 'rdi_password';" 2>/dev/null; then
        print_success "✓ Created user 'rdi_user'"
    else
        print_warning "⚠ User 'rdi_user' already exists"
    fi
    
    if sudo -u postgres psql -c "CREATE DATABASE rdi_db OWNER rdi_user;" 2>/dev/null; then
        print_success "✓ Created database 'rdi_db'"
    else
        print_warning "⚠ Database 'rdi_db' already exists"
    fi
    
    # Grant privileges
    sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE rdi_db TO rdi_user;"
    print_success "✓ Granted privileges to rdi_user"
}

# Configure PostgreSQL for external connections
configure_postgres() {
    print_status "Configuring PostgreSQL for RDI access..."
    
    # Find PostgreSQL config directory
    local pg_version=$(sudo -u postgres psql -t -c "SELECT version();" | grep -oE '[0-9]+\.[0-9]+' | head -1)
    local config_dir="/etc/postgresql/$pg_version/main"
    
    if [ ! -d "$config_dir" ]; then
        # Try alternative locations
        config_dir=$(sudo -u postgres psql -t -c "SHOW config_file;" | xargs dirname 2>/dev/null || echo "")
    fi
    
    if [ -n "$config_dir" ] && [ -d "$config_dir" ]; then
        print_status "Found PostgreSQL config in: $config_dir"
        
        # Backup original files
        sudo cp "$config_dir/postgresql.conf" "$config_dir/postgresql.conf.backup" 2>/dev/null || true
        sudo cp "$config_dir/pg_hba.conf" "$config_dir/pg_hba.conf.backup" 2>/dev/null || true
        
        # Enable connections from localhost
        if ! sudo grep -q "listen_addresses = 'localhost'" "$config_dir/postgresql.conf" 2>/dev/null; then
            echo "listen_addresses = 'localhost'" | sudo tee -a "$config_dir/postgresql.conf" >/dev/null
        fi
        
        # Add authentication rule for rdi_user
        if ! sudo grep -q "rdi_user" "$config_dir/pg_hba.conf" 2>/dev/null; then
            echo "host    rdi_db          rdi_user        127.0.0.1/32            md5" | sudo tee -a "$config_dir/pg_hba.conf" >/dev/null
        fi
        
        # Restart PostgreSQL
        sudo systemctl restart postgresql 2>/dev/null || brew services restart postgresql@15 2>/dev/null || true
        print_success "✓ PostgreSQL configured for external access"
    else
        print_warning "⚠ Could not find PostgreSQL config directory"
        print_warning "You may need to manually configure PostgreSQL for external connections"
    fi
}

# Load sample data
load_sample_data() {
    print_status "Loading music sample data..."
    
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local sql_file="$script_dir/../seed/postgres.sql"
    
    if [ -f "$sql_file" ]; then
        if psql -U rdi_user -d rdi_db -h localhost < "$sql_file" >/dev/null 2>&1; then
            print_success "✓ Sample music data loaded successfully"
            
            # Show summary
            local track_count=$(psql -U rdi_user -d rdi_db -h localhost -t -c 'SELECT COUNT(*) FROM "Track";' | xargs)
            local album_count=$(psql -U rdi_user -d rdi_db -h localhost -t -c 'SELECT COUNT(*) FROM "Album";' | xargs)
            print_status "Loaded $track_count tracks from $album_count albums"
        else
            print_error "✗ Failed to load sample data"
            return 1
        fi
    else
        print_error "✗ Sample data file not found: $sql_file"
        return 1
    fi
}

# Test database connection
test_connection() {
    print_status "Testing database connection..."
    
    if psql -U rdi_user -d rdi_db -h localhost -c "SELECT 1;" >/dev/null 2>&1; then
        print_success "✓ Database connection successful"
        return 0
    else
        print_error "✗ Database connection failed"
        print_error "Please check PostgreSQL installation and configuration"
        return 1
    fi
}

# Main setup function
main() {
    print_status "Starting PostgreSQL setup for Redis RDI CTF..."
    echo ""
    
    # Check if already installed
    if ! check_postgres; then
        install_postgres
    fi
    
    # Setup database
    setup_database
    
    # Configure for external access
    configure_postgres
    
    # Load sample data
    load_sample_data
    
    # Test connection
    if test_connection; then
        echo ""
        print_success "🎉 PostgreSQL setup complete!"
        echo ""
        print_status "Database details:"
        echo "  • Host: localhost"
        echo "  • Port: 5432"
        echo "  • Database: rdi_db"
        echo "  • User: rdi_user"
        echo "  • Password: rdi_password"
        echo ""
        print_status "Next step: Run ./setup_rdi.sh"
    else
        print_error "Setup failed. Please check the errors above."
        exit 1
    fi
}

# Run main function
main "$@"
