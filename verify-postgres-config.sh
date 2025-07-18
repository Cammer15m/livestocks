#!/bin/bash

# Script to verify PostgreSQL configuration for Debezium support
# This script checks if PostgreSQL is properly configured with logical replication

echo "🔍 Verifying PostgreSQL configuration for Debezium..."

# Function to check if container is running
check_container() {
    local container_name=$1
    if docker ps --format "table {{.Names}}" | grep -q "^${container_name}$"; then
        echo "✅ Container ${container_name} is running"
        return 0
    else
        echo "❌ Container ${container_name} is not running"
        return 1
    fi
}

# Function to execute SQL and check result
check_postgres_setting() {
    local container_name=$1
    local setting_name=$2
    local expected_value=$3
    
    echo "Checking ${setting_name}..."
    
    result=$(docker exec ${container_name} psql -U postgres -d chinook -t -c "SHOW ${setting_name};" 2>/dev/null | xargs)
    
    if [ "$result" = "$expected_value" ]; then
        echo "✅ ${setting_name} = ${result} (correct)"
        return 0
    else
        echo "❌ ${setting_name} = ${result} (expected: ${expected_value})"
        return 1
    fi
}

# Determine which container to check
CONTAINER_NAME=""
if check_container "rdi-postgres"; then
    CONTAINER_NAME="rdi-postgres"
elif check_container "rdi-postgres-test"; then
    CONTAINER_NAME="rdi-postgres-test"
elif check_container "postgresql"; then
    CONTAINER_NAME="postgresql"
else
    echo "❌ No PostgreSQL container found running"
    echo "Please start your Docker Compose setup first:"
    echo "  docker compose -f docker-compose-cloud.yml up -d"
    exit 1
fi

echo ""
echo "Using container: ${CONTAINER_NAME}"
echo ""

# Wait for PostgreSQL to be ready
echo "⏳ Waiting for PostgreSQL to be ready..."
timeout=30
counter=0
while [ $counter -lt $timeout ]; do
    if docker exec ${CONTAINER_NAME} pg_isready -U postgres >/dev/null 2>&1; then
        echo "✅ PostgreSQL is ready"
        break
    fi
    sleep 1
    counter=$((counter + 1))
done

if [ $counter -eq $timeout ]; then
    echo "❌ PostgreSQL failed to become ready within ${timeout} seconds"
    exit 1
fi

echo ""
echo "🔧 Checking PostgreSQL configuration..."
echo ""

# Check critical settings for Debezium
all_good=true

if ! check_postgres_setting ${CONTAINER_NAME} "wal_level" "logical"; then
    all_good=false
fi

if ! check_postgres_setting ${CONTAINER_NAME} "max_replication_slots" "10"; then
    all_good=false
fi

if ! check_postgres_setting ${CONTAINER_NAME} "max_wal_senders" "10"; then
    all_good=false
fi

echo ""
echo "🔍 Checking database and user permissions..."

# Check if postgres user has replication privileges
replication_check=$(docker exec ${CONTAINER_NAME} psql -U postgres -d chinook -t -c "SELECT rolreplication FROM pg_roles WHERE rolname = 'postgres';" 2>/dev/null | xargs)

if [ "$replication_check" = "t" ]; then
    echo "✅ postgres user has replication privileges"
else
    echo "❌ postgres user does not have replication privileges"
    all_good=false
fi

# Check if chinook database exists
db_check=$(docker exec ${CONTAINER_NAME} psql -U postgres -t -c "SELECT 1 FROM pg_database WHERE datname = 'chinook';" 2>/dev/null | xargs)

if [ "$db_check" = "1" ]; then
    echo "✅ chinook database exists"
else
    echo "❌ chinook database does not exist"
    all_good=false
fi

# Check if tables exist
table_check=$(docker exec ${CONTAINER_NAME} psql -U postgres -d chinook -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';" 2>/dev/null | xargs)

if [ "$table_check" -gt "0" ]; then
    echo "✅ Tables exist in chinook database (${table_check} tables found)"
    
    # List the tables
    echo "📋 Tables in chinook database:"
    docker exec ${CONTAINER_NAME} psql -U postgres -d chinook -c "\dt" 2>/dev/null | grep "public" | awk '{print "   - " $3}'
else
    echo "❌ No tables found in chinook database"
    all_good=false
fi

echo ""
if [ "$all_good" = true ]; then
    echo "🎉 PostgreSQL is properly configured for Debezium!"
    echo ""
    echo "📝 Configuration Summary:"
    echo "   - WAL Level: logical ✅"
    echo "   - Max Replication Slots: 10 ✅"
    echo "   - Max WAL Senders: 10 ✅"
    echo "   - Replication User: postgres ✅"
    echo "   - Database: chinook ✅"
    echo "   - Tables: Available ✅"
    echo ""
    echo "🚀 Ready for RDI with Debezium!"
else
    echo "❌ PostgreSQL configuration issues found!"
    echo ""
    echo "🔧 To fix issues:"
    echo "   1. Stop the containers: docker compose down"
    echo "   2. Start them again: docker compose up -d"
    echo "   3. Wait for initialization to complete"
    echo "   4. Run this script again"
fi

echo ""
echo "📊 Additional Information:"
echo "Container: ${CONTAINER_NAME}"
echo "Connection: postgresql://postgres:postgres@localhost:5432/chinook"
echo ""
