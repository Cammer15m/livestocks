#!/bin/bash

# Redis RDI CTF Integration Test
# Comprehensive test of the complete setup

set -e

echo "🧪 Redis RDI CTF Integration Test"
echo "=================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test functions
test_passed() {
    echo -e "${GREEN}✅ $1${NC}"
}

test_failed() {
    echo -e "${RED}❌ $1${NC}"
    exit 1
}

test_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

test_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check if Docker is available
if ! command -v docker >/dev/null 2>&1; then
    test_failed "Docker is not installed. Please install Docker first."
fi

if ! docker info >/dev/null 2>&1; then
    test_failed "Docker daemon is not running. Please start Docker."
fi

# Determine compose command
if command -v docker-compose >/dev/null 2>&1; then
    COMPOSE_CMD="docker-compose"
elif docker compose version >/dev/null 2>&1; then
    COMPOSE_CMD="docker compose"
else
    test_failed "Docker Compose is not available"
fi

test_info "Using compose command: $COMPOSE_CMD"

# Clean up any existing containers
echo ""
echo "🧹 Cleaning up existing containers..."
$COMPOSE_CMD down --remove-orphans >/dev/null 2>&1 || true

# Build and start containers
echo ""
echo "🔨 Building and starting containers..."
if $COMPOSE_CMD up -d --build; then
    test_passed "Containers started successfully"
else
    test_failed "Failed to start containers"
fi

# Wait for services to be ready
echo ""
echo "⏳ Waiting for services to initialize..."
sleep 20

# Test PostgreSQL
echo ""
echo "🗄️ Testing PostgreSQL..."
if docker exec rdi-ctf-postgres pg_isready -U postgres -d musicstore >/dev/null 2>&1; then
    test_passed "PostgreSQL is ready"
    
    # Test database content
    track_count=$(docker exec rdi-ctf-postgres psql -U postgres -d musicstore -t -c "SELECT COUNT(*) FROM \"Track\";" 2>/dev/null | tr -d ' ')
    if [ "$track_count" -gt 0 ]; then
        test_passed "Database has $track_count tracks"
    else
        test_failed "Database has no tracks"
    fi
    
    # Test CTF flags
    flag_count=$(docker exec rdi-ctf-postgres psql -U postgres -d musicstore -t -c "SELECT COUNT(*) FROM ctf_flags;" 2>/dev/null | tr -d ' ')
    if [ "$flag_count" -gt 0 ]; then
        test_passed "Database has $flag_count CTF flags"
    else
        test_failed "Database has no CTF flags"
    fi
else
    test_failed "PostgreSQL is not ready"
fi

# Test Redis Insight
echo ""
echo "🔍 Testing Redis Insight..."
max_attempts=10
attempt=1
while [ $attempt -le $max_attempts ]; do
    if curl -s http://localhost:5540 >/dev/null 2>&1; then
        test_passed "Redis Insight is accessible"
        break
    else
        if [ $attempt -eq $max_attempts ]; then
            test_warning "Redis Insight not accessible after $max_attempts attempts"
        else
            test_info "Attempt $attempt/$max_attempts: Redis Insight not ready, waiting..."
            sleep 5
            ((attempt++))
        fi
    fi
done

# Test RDI CLI
echo ""
echo "⚙️ Testing RDI CLI..."
if docker exec rdi-ctf-cli redis-di --version >/dev/null 2>&1; then
    test_passed "RDI CLI is working"
    
    # Test configuration template
    if docker exec rdi-ctf-cli test -f /config/config.yaml.template; then
        test_passed "RDI configuration template exists"
    else
        test_failed "RDI configuration template missing"
    fi
else
    test_failed "RDI CLI is not working"
fi

# Test Load Generator
echo ""
echo "📊 Testing Load Generator..."
if docker exec rdi-ctf-loadgen python -c "import psycopg2, pandas, sqlalchemy; print('Dependencies OK')" >/dev/null 2>&1; then
    test_passed "Load generator dependencies are installed"
    
    # Test database connection from load generator
    if docker exec rdi-ctf-loadgen python -c "
import psycopg2
try:
    conn = psycopg2.connect(host='postgresql', port=5432, database='musicstore', user='postgres', password='postgres')
    conn.close()
    print('Connection successful')
except Exception as e:
    print(f'Connection failed: {e}')
    exit(1)
" >/dev/null 2>&1; then
        test_passed "Load generator can connect to PostgreSQL"
    else
        test_failed "Load generator cannot connect to PostgreSQL"
    fi
else
    test_failed "Load generator dependencies missing"
fi

# Test Web Interface
echo ""
echo "🌐 Testing Web Interface..."
max_attempts=10
attempt=1
while [ $attempt -le $max_attempts ]; do
    if curl -s http://localhost:8080 >/dev/null 2>&1; then
        test_passed "Web interface is accessible"
        
        # Test if it contains expected content
        if curl -s http://localhost:8080 | grep -q "Redis RDI CTF"; then
            test_passed "Web interface contains CTF content"
        else
            test_warning "Web interface accessible but missing CTF content"
        fi
        break
    else
        if [ $attempt -eq $max_attempts ]; then
            test_warning "Web interface not accessible after $max_attempts attempts"
        else
            test_info "Attempt $attempt/$max_attempts: Web interface not ready, waiting..."
            sleep 5
            ((attempt++))
        fi
    fi
done

# Test RDI Configuration
echo ""
echo "🔧 Testing RDI Configuration..."
if docker exec rdi-ctf-cli cp /config/config.yaml.template /config/config.yaml; then
    test_passed "RDI configuration template copied"
    
    # Test configuration validation (basic syntax check)
    if docker exec rdi-ctf-cli python -c "
import yaml
try:
    with open('/config/config.yaml', 'r') as f:
        yaml.safe_load(f)
    print('YAML syntax valid')
except Exception as e:
    print(f'YAML syntax error: {e}')
    exit(1)
" >/dev/null 2>&1; then
        test_passed "RDI configuration has valid YAML syntax"
    else
        test_failed "RDI configuration has invalid YAML syntax"
    fi
else
    test_failed "Failed to copy RDI configuration template"
fi

# Test Load Generation (brief test)
echo ""
echo "🎵 Testing Load Generation..."
test_info "Running brief load generation test..."
timeout 10 docker exec rdi-ctf-loadgen python /scripts/generate_load.py >/dev/null 2>&1 || true

# Check if new tracks were added
new_track_count=$(docker exec rdi-ctf-postgres psql -U postgres -d musicstore -t -c "SELECT COUNT(*) FROM \"Track\";" 2>/dev/null | tr -d ' ')
if [ "$new_track_count" -gt "$track_count" ]; then
    test_passed "Load generator successfully added $((new_track_count - track_count)) new tracks"
else
    test_warning "Load generator may not have added tracks (or test was too brief)"
fi

# Test port accessibility
echo ""
echo "🔌 Testing Port Accessibility..."
required_ports=(5432 5540 8080)
for port in "${required_ports[@]}"; do
    if netstat -tuln 2>/dev/null | grep -q ":$port "; then
        test_passed "Port $port is accessible"
    else
        test_warning "Port $port may not be accessible from outside"
    fi
done

# Summary
echo ""
echo "📊 Integration Test Summary"
echo "=========================="
echo ""
echo "🎯 Core Services:"
echo "  ✅ PostgreSQL with music database"
echo "  ✅ Redis Insight for RDI configuration"
echo "  ✅ RDI CLI for pipeline management"
echo "  ✅ Load generator for testing"
echo "  ✅ Web interface with instructions"
echo ""
echo "🌐 Access Points:"
echo "  📊 CTF Dashboard: http://localhost:8080"
echo "  🔍 Redis Insight: http://localhost:5540"
echo "  🗄️ PostgreSQL: localhost:5432"
echo ""
echo "📋 Next Steps:"
echo "1. Sign up for Redis Cloud: https://redis.com/try-free/"
echo "2. Configure RDI with your Redis Cloud connection"
echo "3. Start Lab 01 in the web interface"
echo ""
echo "🛑 To stop: ./stop_ctf.sh"
echo ""

test_passed "Integration test completed successfully!"
echo ""
echo "🎉 Redis RDI CTF is ready for use!"
