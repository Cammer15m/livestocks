#!/bin/bash

# Polygon.io Data Fetcher Startup Script
# This script sets up and starts the Polygon.io data fetching service

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

print_status $BLUE "🚀 Starting Polygon.io Data Fetcher Setup..."

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    print_status $RED "❌ Docker is not running. Please start Docker first."
    exit 1
fi

# Check if PostgreSQL container is running
if ! docker ps --format "{{.Names}}" | grep -q "rdi-postgres"; then
    print_status $YELLOW "⚠️  PostgreSQL container not found. Starting the main environment first..."
    
    # Check if start.sh exists and run it
    if [ -f "./start.sh" ]; then
        print_status $BLUE "📦 Starting main environment..."
        ./start.sh
    else
        print_status $RED "❌ start.sh not found. Please ensure the main environment is set up."
        exit 1
    fi
    
    # Wait for PostgreSQL to be ready
    print_status $BLUE "⏳ Waiting for PostgreSQL to be ready..."
    timeout=60
    counter=0
    while [ $counter -lt $timeout ]; do
        if docker exec rdi-postgres pg_isready -U postgres >/dev/null 2>&1; then
            print_status $GREEN "✅ PostgreSQL is ready"
            break
        fi
        sleep 2
        counter=$((counter + 2))
    done
    
    if [ $counter -ge $timeout ]; then
        print_status $RED "❌ PostgreSQL failed to start within ${timeout} seconds"
        exit 1
    fi
fi

# Create Polygon.io database schema
print_status $BLUE "📊 Setting up Polygon.io database schema..."
if docker exec rdi-postgres psql -U postgres -d chinook -f /tmp/create_polygon_tables.sql >/dev/null 2>&1; then
    print_status $GREEN "✅ Database schema created successfully"
else
    # Copy the schema file to the container and run it
    if [ -f "./create_polygon_tables.sql" ]; then
        docker cp ./create_polygon_tables.sql rdi-postgres:/tmp/create_polygon_tables.sql
        if docker exec rdi-postgres psql -U postgres -d chinook -f /tmp/create_polygon_tables.sql; then
            print_status $GREEN "✅ Database schema created successfully"
        else
            print_status $RED "❌ Failed to create database schema"
            exit 1
        fi
    else
        print_status $RED "❌ create_polygon_tables.sql not found"
        exit 1
    fi
fi

# Check if Python dependencies are installed in the container
print_status $BLUE "📦 Checking Python dependencies..."
if docker exec rdi-postgres python3 -c "import polygon" >/dev/null 2>&1; then
    print_status $GREEN "✅ Polygon.io Python client is available"
else
    print_status $YELLOW "⚠️  Installing Polygon.io Python dependencies..."
    
    # Copy requirements.txt to container and install
    if [ -f "./requirements.txt" ]; then
        docker cp ./requirements.txt rdi-postgres:/tmp/requirements.txt
        if docker exec rdi-postgres pip3 install -r /tmp/requirements.txt; then
            print_status $GREEN "✅ Dependencies installed successfully"
        else
            print_status $RED "❌ Failed to install dependencies"
            exit 1
        fi
    else
        print_status $RED "❌ requirements.txt not found"
        exit 1
    fi
fi

# Copy Python scripts to the container
print_status $BLUE "📁 Copying Polygon.io scripts to container..."
scripts=("polygon_config.py" "polygon_fetcher.py" "polygon_monitor.py" "polygon_utils.py")

for script in "${scripts[@]}"; do
    if [ -f "./$script" ]; then
        docker cp "./$script" rdi-postgres:/tmp/
        print_status $GREEN "✅ Copied $script"
    else
        print_status $RED "❌ $script not found"
        exit 1
    fi
done

# Create environment file for the container
print_status $BLUE "⚙️  Setting up environment configuration..."
cat > polygon.env << EOF
POLYGON_API_KEY=ObYzcj_rvlU1czNwYLmRZJgg7TXWAX5q
POLYGON_API_NAME=Default
DB_HOST=localhost
DB_PORT=5432
DB_NAME=chinook
DB_USER=postgres
DB_PASSWORD=postgres
DEFAULT_TICKERS=AAPL,GOOGL,MSFT,TSLA,AMZN
FETCH_INTERVAL_MINUTES=60
DAYS_BACK_INITIAL=30
ENABLE_REALTIME=false
ENABLE_DAILY_AGGREGATES=true
ENABLE_MINUTE_AGGREGATES=false
ENABLE_TRADES=false
ENABLE_QUOTES=false
LOG_LEVEL=INFO
REQUESTS_PER_MINUTE=5
MAX_RETRIES=3
RETRY_DELAY_SECONDS=30
EOF

docker cp polygon.env rdi-postgres:/tmp/.env
print_status $GREEN "✅ Environment configuration created"

# Test the setup by running initial data fetch
print_status $BLUE "🧪 Testing Polygon.io data fetcher..."
if docker exec -e PYTHONPATH=/tmp rdi-postgres python3 /tmp/polygon_fetcher.py; then
    print_status $GREEN "✅ Initial data fetch completed successfully"
else
    print_status $YELLOW "⚠️  Initial data fetch had issues, but continuing..."
fi

# Create a systemd-style service script for the monitor
print_status $BLUE "🔧 Creating monitoring service..."
cat > start-polygon-monitor.sh << 'EOF'
#!/bin/bash
# Start the Polygon.io monitoring service

echo "Starting Polygon.io Data Monitor..."
docker exec -d -e PYTHONPATH=/tmp rdi-postgres python3 /tmp/polygon_monitor.py

echo "Polygon.io Data Monitor started in background"
echo "To check logs: docker exec rdi-postgres tail -f /tmp/polygon_fetcher.log"
echo "To stop: docker exec rdi-postgres pkill -f polygon_monitor.py"
EOF

chmod +x start-polygon-monitor.sh
print_status $GREEN "✅ Monitoring service script created"

# Create a stop script
cat > stop-polygon-monitor.sh << 'EOF'
#!/bin/bash
# Stop the Polygon.io monitoring service

echo "Stopping Polygon.io Data Monitor..."
docker exec rdi-postgres pkill -f polygon_monitor.py
echo "Polygon.io Data Monitor stopped"
EOF

chmod +x stop-polygon-monitor.sh
print_status $GREEN "✅ Stop script created"

# Create a status check script
cat > check-polygon-status.sh << 'EOF'
#!/bin/bash
# Check Polygon.io data fetcher status

echo "=== Polygon.io Data Fetcher Status ==="
echo ""

# Check if monitor is running
if docker exec rdi-postgres pgrep -f polygon_monitor.py >/dev/null 2>&1; then
    echo "✅ Monitor Process: RUNNING"
    PID=$(docker exec rdi-postgres pgrep -f polygon_monitor.py)
    echo "   Process ID: $PID"
else
    echo "❌ Monitor Process: NOT RUNNING"
fi

echo ""

# Check database tables
echo "📊 Database Status:"
docker exec rdi-postgres psql -U postgres -d chinook -c "
SELECT 
    'stock_tickers' as table_name, COUNT(*) as records 
FROM stock_tickers
UNION ALL
SELECT 
    'daily_aggregates' as table_name, COUNT(*) as records 
FROM daily_aggregates
UNION ALL
SELECT 
    'data_fetch_log' as table_name, COUNT(*) as records 
FROM data_fetch_log;
" 2>/dev/null || echo "❌ Database connection failed"

echo ""

# Check recent logs
echo "📝 Recent Log Entries:"
docker exec rdi-postgres tail -n 5 /tmp/polygon_fetcher.log 2>/dev/null || echo "❌ Log file not found"
EOF

chmod +x check-polygon-status.sh
print_status $GREEN "✅ Status check script created"

# Start the monitoring service
print_status $BLUE "🚀 Starting Polygon.io Data Monitor..."
./start-polygon-monitor.sh

# Clean up temporary files
rm -f polygon.env

print_status $GREEN "🎉 Polygon.io Data Fetcher setup completed successfully!"
echo ""
print_status $BLUE "📋 Available Commands:"
echo "  • Start monitor:  ./start-polygon-monitor.sh"
echo "  • Stop monitor:   ./stop-polygon-monitor.sh"
echo "  • Check status:   ./check-polygon-status.sh"
echo "  • View logs:      docker exec rdi-postgres tail -f /tmp/polygon_fetcher.log"
echo ""
print_status $BLUE "📊 Database Access:"
echo "  • SQLPad:         http://localhost:3001 (admin@rl.org / redislabs)"
echo "  • Direct psql:    docker exec -it rdi-postgres psql -U postgres -d chinook"
echo ""
print_status $BLUE "🔍 Monitoring:"
echo "  • The system will fetch daily data for: AAPL, GOOGL, MSFT, TSLA, AMZN"
echo "  • Data is fetched every hour and stored in the 'daily_aggregates' table"
echo "  • Check status regularly with: ./check-polygon-status.sh"
echo ""
print_status $GREEN "✅ Setup complete! The Polygon.io data fetcher is now running."
