#!/bin/bash

# Redis RDI CTF - PostgreSQL Container Diagnostic Script
# This script helps diagnose common issues with PostgreSQL container startup

echo "🔍 Redis RDI CTF - PostgreSQL Container Diagnostics"
echo "=================================================="
echo ""

# Function to print status messages
print_status() {
    local status=$1
    local message=$2
    case $status in
        "SUCCESS") echo "✅ $message" ;;
        "ERROR") echo "❌ $message" ;;
        "WARNING") echo "⚠️  $message" ;;
        "INFO") echo "ℹ️  $message" ;;
    esac
}

# Check if Docker is running
echo "1. Checking Docker status..."
if ! docker info &>/dev/null; then
    print_status "ERROR" "Docker is not running or not accessible"
    echo "   Please start Docker and try again:"
    echo "   - On macOS: Open Docker Desktop"
    echo "   - On Linux: sudo systemctl start docker"
    exit 1
fi
print_status "SUCCESS" "Docker is running"
echo ""

# Check if required files exist
echo "2. Checking required files..."
required_files=("docker-compose-cloud.yml" "postgresql.conf" "create_track_table.sql" "init-postgres-for-debezium.sql")
for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        print_status "SUCCESS" "Found $file"
    else
        print_status "ERROR" "Missing $file"
    fi
done
echo ""

# Check for port conflicts
echo "3. Checking for port conflicts..."
ports=(5432 5540 3001 8080)
for port in "${ports[@]}"; do
    if command -v lsof &> /dev/null; then
        if lsof -i :$port &>/dev/null; then
            print_status "WARNING" "Port $port is already in use"
            echo "   Process using port $port:"
            lsof -i :$port
        else
            print_status "SUCCESS" "Port $port is available"
        fi
    elif command -v netstat &> /dev/null; then
        if netstat -tuln | grep -q ":$port "; then
            print_status "WARNING" "Port $port appears to be in use"
        else
            print_status "SUCCESS" "Port $port is available"
        fi
    else
        print_status "INFO" "Cannot check port $port (no lsof or netstat available)"
    fi
done
echo ""

# Check current container status
echo "4. Checking container status..."
if docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(rdi-postgres|rdi-insight|rdi-sqlpad|rdi-web)" &>/dev/null; then
    echo "Current containers:"
    docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(rdi-postgres|rdi-insight|rdi-sqlpad|rdi-web)"
else
    print_status "INFO" "No Redis RDI CTF containers found"
fi
echo ""

# Check PostgreSQL container logs if it exists
echo "5. Checking PostgreSQL container logs..."
if docker ps -a --format "{{.Names}}" | grep -q "rdi-postgres"; then
    print_status "INFO" "PostgreSQL container exists, checking logs..."
    echo "Last 20 lines of PostgreSQL logs:"
    echo "=================================="
    docker logs --tail 20 rdi-postgres 2>&1
    echo "=================================="
else
    print_status "INFO" "PostgreSQL container not found"
fi
echo ""

# Check Docker Compose version
echo "6. Checking Docker Compose..."
if command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE="docker-compose"
    print_status "SUCCESS" "Found docker-compose: $(docker-compose --version)"
elif docker compose version &> /dev/null; then
    DOCKER_COMPOSE="docker compose"
    print_status "SUCCESS" "Found docker compose: $(docker compose version)"
else
    print_status "ERROR" "Docker Compose not found"
    echo "   Please install Docker Compose"
    exit 1
fi
echo ""

# Test PostgreSQL configuration file
echo "7. Testing PostgreSQL configuration..."
if [ -f "postgresql.conf" ]; then
    # Check for critical settings
    if grep -q "wal_level = logical" postgresql.conf; then
        print_status "SUCCESS" "wal_level = logical found in postgresql.conf"
    else
        print_status "ERROR" "wal_level = logical not found in postgresql.conf"
    fi
    
    if grep -q "max_replication_slots" postgresql.conf; then
        print_status "SUCCESS" "max_replication_slots found in postgresql.conf"
    else
        print_status "WARNING" "max_replication_slots not found in postgresql.conf"
    fi
else
    print_status "ERROR" "postgresql.conf not found"
fi
echo ""

# Provide recommendations
echo "8. Recommendations:"
echo "==================="

# Check if containers are running
if docker ps --format "{{.Names}}" | grep -q "rdi-postgres"; then
    if docker exec rdi-postgres pg_isready -U postgres &>/dev/null; then
        print_status "SUCCESS" "PostgreSQL is running and ready!"
        echo "   You can connect to PostgreSQL at localhost:5432"
        echo "   Database: chinook, User: postgres, Password: postgres"
    else
        print_status "WARNING" "PostgreSQL container is running but not ready"
        echo "   Try waiting a few more seconds and run: docker exec rdi-postgres pg_isready -U postgres"
    fi
else
    print_status "INFO" "To start the environment, run: ./start.sh"
    echo "   If that fails, try:"
    echo "   1. ./stop.sh (to clean up any partial state)"
    echo "   2. ./start.sh (to start fresh)"
fi

echo ""
echo "🔧 Common fixes:"
echo "   - Port conflict: Stop other services using ports 5432, 5540, 3001, 8080"
echo "   - Permission issues: Make sure Docker has access to current directory"
echo "   - Restart Docker: Sometimes Docker daemon needs a restart"
echo "   - Clean restart: ./stop.sh && ./start.sh"
echo ""
echo "📋 For more help, check the logs above or run:"
echo "   docker logs rdi-postgres"
echo "   docker logs rdi-sqlpad"
echo "   docker logs rdi-insight"
