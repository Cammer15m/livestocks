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

# Copy the load generation script and data into the container
docker cp generate_load.py rdi-postgres:/tmp/
docker cp track.csv rdi-postgres:/tmp/
docker cp requirements.txt rdi-postgres:/tmp/

# Install Python dependencies in the container
echo "Installing Python dependencies in container..."
echo "This may take a moment..."

# Check if python3 is already installed
if ! docker exec rdi-postgres which python3 &>/dev/null; then
    echo "Installing Python3..."
    docker exec --user root rdi-postgres bash -c "
        apt-get update -qq
        apt-get install -y python3 python3-pip
    "
    if [ $? -ne 0 ]; then
        echo "Error: Failed to install Python3 in PostgreSQL container"
        exit 1
    fi
fi

# Install Python packages
echo "Installing Python packages..."
docker exec --user root rdi-postgres bash -c "pip3 install -r /tmp/requirements.txt"
if [ $? -ne 0 ]; then
    echo "Error: Failed to install Python packages"
    exit 1
fi

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
