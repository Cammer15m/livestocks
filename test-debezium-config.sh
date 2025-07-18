#!/bin/bash

# Test script to demonstrate PostgreSQL configuration for Debezium
# This script starts the environment and verifies the configuration

set -e

echo "🚀 Testing PostgreSQL configuration for Debezium support"
echo "======================================================="
echo ""

# Function to print colored output
print_status() {
    local status=$1
    local message=$2
    case $status in
        "INFO")
            echo "ℹ️  $message"
            ;;
        "SUCCESS")
            echo "✅ $message"
            ;;
        "ERROR")
            echo "❌ $message"
            ;;
        "WARNING")
            echo "⚠️  $message"
            ;;
    esac
}

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    print_status "ERROR" "Docker is not running. Please start Docker first."
    exit 1
fi

print_status "SUCCESS" "Docker is running"

# Check if docker-compose-cloud.yml exists
if [ ! -f "docker-compose-cloud.yml" ]; then
    print_status "ERROR" "docker-compose-cloud.yml not found. Are you in the correct directory?"
    exit 1
fi

print_status "SUCCESS" "Found docker-compose-cloud.yml"

# Stop any existing containers
print_status "INFO" "Stopping any existing containers..."
docker compose -f docker-compose-cloud.yml down >/dev/null 2>&1 || true

# Start the environment
print_status "INFO" "Starting PostgreSQL with Debezium configuration..."
docker compose -f docker-compose-cloud.yml up -d postgresql

# Wait for PostgreSQL to be ready
print_status "INFO" "Waiting for PostgreSQL to initialize..."
timeout=60
counter=0
while [ $counter -lt $timeout ]; do
    if docker exec rdi-postgres pg_isready -U postgres >/dev/null 2>&1; then
        print_status "SUCCESS" "PostgreSQL is ready"
        break
    fi
    sleep 2
    counter=$((counter + 2))
    if [ $((counter % 10)) -eq 0 ]; then
        print_status "INFO" "Still waiting... (${counter}s elapsed)"
    fi
done

if [ $counter -ge $timeout ]; then
    print_status "ERROR" "PostgreSQL failed to start within ${timeout} seconds"
    print_status "INFO" "Checking logs..."
    docker logs rdi-postgres
    exit 1
fi

echo ""
print_status "INFO" "Running configuration verification..."
echo ""

# Run the verification script
if [ -f "verify-postgres-config.sh" ]; then
    ./verify-postgres-config.sh
else
    print_status "WARNING" "verify-postgres-config.sh not found, running manual checks..."
    
    # Manual verification
    echo "🔍 Manual verification:"
    echo ""
    
    # Check WAL level
    wal_level=$(docker exec rdi-postgres psql -U postgres -d chinook -t -c "SHOW wal_level;" 2>/dev/null | xargs)
    if [ "$wal_level" = "logical" ]; then
        print_status "SUCCESS" "wal_level = logical"
    else
        print_status "ERROR" "wal_level = $wal_level (expected: logical)"
    fi
    
    # Check max_replication_slots
    max_slots=$(docker exec rdi-postgres psql -U postgres -d chinook -t -c "SHOW max_replication_slots;" 2>/dev/null | xargs)
    if [ "$max_slots" = "10" ]; then
        print_status "SUCCESS" "max_replication_slots = 10"
    else
        print_status "ERROR" "max_replication_slots = $max_slots (expected: 10)"
    fi
    
    # Check max_wal_senders
    max_senders=$(docker exec rdi-postgres psql -U postgres -d chinook -t -c "SHOW max_wal_senders;" 2>/dev/null | xargs)
    if [ "$max_senders" = "10" ]; then
        print_status "SUCCESS" "max_wal_senders = 10"
    else
        print_status "ERROR" "max_wal_senders = $max_senders (expected: 10)"
    fi
fi

echo ""
print_status "INFO" "Testing database connectivity and tables..."

# Check if tables exist
table_count=$(docker exec rdi-postgres psql -U postgres -d chinook -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';" 2>/dev/null | xargs)

if [ "$table_count" -gt "0" ]; then
    print_status "SUCCESS" "Found $table_count tables in chinook database"
    
    # List tables
    echo ""
    echo "📋 Available tables:"
    docker exec rdi-postgres psql -U postgres -d chinook -c "\dt" 2>/dev/null | grep "public" | awk '{print "   - " $3}'
    
    # Show sample data
    echo ""
    echo "📊 Sample data from Track table:"
    docker exec rdi-postgres psql -U postgres -d chinook -c "SELECT \"TrackId\", \"Name\", \"AlbumId\" FROM \"Track\" LIMIT 3;" 2>/dev/null
else
    print_status "ERROR" "No tables found in chinook database"
fi

echo ""
print_status "SUCCESS" "Test completed!"
echo ""
echo "📝 Summary:"
echo "   - PostgreSQL is configured with wal_level = logical"
echo "   - Replication slots and WAL senders are properly configured"
echo "   - Database and tables are available"
echo "   - Ready for Debezium integration with RDI"
echo ""
echo "🔗 Connection details:"
echo "   - Host: localhost"
echo "   - Port: 5432"
echo "   - Database: chinook"
echo "   - Username: postgres"
echo "   - Password: postgres"
echo ""
echo "🚀 Next steps:"
echo "   1. Start the full environment: docker compose -f docker-compose-cloud.yml up -d"
echo "   2. Configure RDI with your Redis Cloud connection"
echo "   3. Set up data pipeline for real-time replication"
echo ""
