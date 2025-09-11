#!/bin/bash

# PostgreSQL Diagnostic Script for Redis RDI Training Environment
# This script helps troubleshoot PostgreSQL startup and initialization issues

echo "PostgreSQL Diagnostic Tool"
echo "=========================="
echo ""

# Function to print status with color
print_status() {
    local status=$1
    local message=$2
    case $status in
        "SUCCESS")
            echo "✅ $message"
            ;;
        "ERROR")
            echo "❌ $message"
            ;;
        "WARNING")
            echo "⚠️  $message"
            ;;
        "INFO")
            echo "ℹ️  $message"
            ;;
    esac
}

# Check if Docker is running
echo "1. Checking Docker status..."
if ! docker info &>/dev/null; then
    print_status "ERROR" "Docker is not running or not accessible"
    echo "   Please start Docker and try again"
    exit 1
fi
print_status "SUCCESS" "Docker is running"
echo ""

# Check if PostgreSQL container exists
echo "2. Checking PostgreSQL container..."
if docker ps -a --format "{{.Names}}" | grep -q "rdi-postgres"; then
    container_status=$(docker ps -a --filter "name=rdi-postgres" --format "{{.Status}}")
    if docker ps --format "{{.Names}}" | grep -q "rdi-postgres"; then
        print_status "SUCCESS" "PostgreSQL container is running: $container_status"
    else
        print_status "ERROR" "PostgreSQL container exists but is not running: $container_status"
        echo ""
        echo "Container logs:"
        docker logs rdi-postgres --tail 20
        exit 1
    fi
else
    print_status "ERROR" "PostgreSQL container 'rdi-postgres' not found"
    echo "   Please run ./start.sh to create the container"
    exit 1
fi
echo ""

# Check PostgreSQL process inside container
echo "3. Checking PostgreSQL process..."
if docker exec rdi-postgres ps aux | grep -q "postgres.*postgres"; then
    print_status "SUCCESS" "PostgreSQL process is running"
    docker exec rdi-postgres ps aux | grep postgres
else
    print_status "ERROR" "PostgreSQL process not found"
    echo ""
    echo "All processes in container:"
    docker exec rdi-postgres ps aux
fi
echo ""

# Check PostgreSQL readiness
echo "4. Checking PostgreSQL readiness..."
if docker exec rdi-postgres pg_isready -U postgres -d chinook &>/dev/null; then
    print_status "SUCCESS" "PostgreSQL is ready and accepting connections"
else
    print_status "ERROR" "PostgreSQL is not ready"
    echo ""
    echo "Detailed pg_isready output:"
    docker exec rdi-postgres pg_isready -U postgres -d chinook
fi
echo ""

# Check database and tables
echo "5. Checking database and tables..."
if docker exec rdi-postgres psql -U postgres -d chinook -c "\dt" &>/dev/null; then
    print_status "SUCCESS" "Database 'chinook' exists and is accessible"
    echo ""
    echo "Tables in chinook database:"
    docker exec rdi-postgres psql -U postgres -d chinook -c "\dt"
    echo ""
    echo "Table record counts:"
    docker exec rdi-postgres psql -U postgres -d chinook -c "
    SELECT 'Album' as table_name, COUNT(*) as record_count FROM \"Album\"
    UNION ALL
    SELECT 'MediaType' as table_name, COUNT(*) as record_count FROM \"MediaType\"
    UNION ALL
    SELECT 'Genre' as table_name, COUNT(*) as record_count FROM \"Genre\"
    UNION ALL
    SELECT 'Track' as table_name, COUNT(*) as record_count FROM \"Track\";
    "
else
    print_status "ERROR" "Cannot access database 'chinook'"
    echo ""
    echo "Available databases:"
    docker exec rdi-postgres psql -U postgres -l
fi
echo ""

# Check PostgreSQL configuration
echo "6. Checking PostgreSQL configuration for Debezium..."
config_check=$(docker exec rdi-postgres psql -U postgres -d chinook -t -c "SHOW wal_level;" 2>/dev/null | tr -d ' ')
if [ "$config_check" = "logical" ]; then
    print_status "SUCCESS" "WAL level is set to 'logical' (required for Debezium)"
else
    print_status "ERROR" "WAL level is '$config_check', should be 'logical'"
fi

replication_slots=$(docker exec rdi-postgres psql -U postgres -d chinook -t -c "SHOW max_replication_slots;" 2>/dev/null | tr -d ' ')
if [ "$replication_slots" -gt 0 ]; then
    print_status "SUCCESS" "Max replication slots: $replication_slots"
else
    print_status "ERROR" "Max replication slots: $replication_slots (should be > 0)"
fi

wal_senders=$(docker exec rdi-postgres psql -U postgres -d chinook -t -c "SHOW max_wal_senders;" 2>/dev/null | tr -d ' ')
if [ "$wal_senders" -gt 0 ]; then
    print_status "SUCCESS" "Max WAL senders: $wal_senders"
else
    print_status "ERROR" "Max WAL senders: $wal_senders (should be > 0)"
fi
echo ""

# Check container logs
echo "7. Recent PostgreSQL logs..."
print_status "INFO" "Last 20 lines of PostgreSQL container logs:"
docker logs rdi-postgres --tail 20
echo ""

# Check container resource usage
echo "8. Container resource usage..."
print_status "INFO" "Container stats:"
docker stats rdi-postgres --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}\t{{.NetIO}}\t{{.BlockIO}}"
echo ""

# Summary
echo "9. Summary and recommendations..."
if docker exec rdi-postgres pg_isready -U postgres -d chinook &>/dev/null && \
   docker exec rdi-postgres psql -U postgres -d chinook -c "SELECT COUNT(*) FROM \"Track\";" &>/dev/null; then
    print_status "SUCCESS" "PostgreSQL is fully operational!"
    echo ""
    echo "✅ All checks passed. PostgreSQL is ready for Redis RDI training."
    echo ""
    echo "Next steps:"
    echo "  - Access SQLPad: http://localhost:3001 (admin@rl.org / redislabs)"
    echo "  - Configure RDI pipeline in Redis Insight: http://localhost:5540"
    echo "  - Generate test data: ./generate_load.sh"
else
    print_status "ERROR" "PostgreSQL has issues that need to be resolved"
    echo ""
    echo "Troubleshooting steps:"
    echo "  1. Check the logs above for specific error messages"
    echo "  2. Try restarting: ./stop.sh && ./start.sh"
    echo "  3. Check available disk space: df -h"
    echo "  4. Check available memory: free -h"
    echo "  5. If issues persist, check Docker Desktop settings"
fi
