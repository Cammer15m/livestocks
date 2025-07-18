#!/bin/bash

echo "Starting PostgreSQL Load Generator..."
echo "===================================="
echo ""

# Check if PostgreSQL container is running
if ! docker ps --format "{{.Names}}" | grep -q "rdi-postgres"; then
    echo "Error: PostgreSQL container (rdi-postgres) is not running!"
    echo "Please start the environment first: ./start.sh"
    exit 1
fi

# Check if PostgreSQL is ready
echo "Checking PostgreSQL connection..."
if ! docker exec rdi-postgres pg_isready -U postgres &>/dev/null; then
    echo "Error: PostgreSQL is not ready!"
    echo "Please wait for PostgreSQL to start up completely."
    exit 1
fi

echo "PostgreSQL is ready. Setting up load generator..."

# Python and dependencies are already installed in the custom container
echo "Python environment ready in container..."

echo ""
echo "Starting continuous load generation..."
echo "Press Ctrl+C to stop the load generator"
echo ""
echo "Load generator will:"
echo "  - Insert random track records continuously"
echo "  - Use real track names from track.csv"
echo "  - Generate random GenreId (1-5)"
echo "  - Only Metal tracks (GenreId=2) will sync to Redis"
echo ""
echo "Monitor Redis data at: http://localhost:5540"
echo ""

# Run the load generator in the container
# Use environment variables to connect to localhost from inside container
docker exec -e POSTGRES_HOST=localhost rdi-postgres python3 /tmp/generate_load.py
