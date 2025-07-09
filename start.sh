#!/bin/bash

echo "Redis RDI Training Environment"
echo "=============================="
echo ""

# Gather Redis Cloud connection details from user
echo "Redis Cloud Configuration"
echo "Please provide your Redis Cloud connection details:"
echo "This Redis instance will be used as the target database."
echo ""
echo "Note: Please ensure your Redis Cloud instance is configured with:"
echo "   Username: default"
echo "   Password: redislabs"
echo ""

# Prompt for Redis Cloud details (only host and port)
read -p "Redis Host (e.g., redis-12345.c1.region.ec2.redns.redis-cloud.com): " REDIS_HOST
read -p "Redis Port (e.g., 12345): " REDIS_PORT

# Set standard credentials
REDIS_USER="default"
REDIS_PASSWORD="redislabs"

# Validate required fields
if [[ -z "$REDIS_HOST" || -z "$REDIS_PORT" ]]; then
    echo "Error: Redis host and port are required!"
    echo ""
    echo "Example Redis Cloud connection string:"
    echo "   redis://default:redislabs@redis-12345.c1.region.ec2.redns.redis-cloud.com:12345"
    echo ""
    echo "   Host: redis-12345.c1.region.ec2.redns.redis-cloud.com"
    echo "   Port: 12345"
    echo "   Username: default (standard)"
    echo "   Password: redislabs (standard)"
    exit 1
fi

echo ""
echo "Redis Cloud configuration:"
echo "   Host: $REDIS_HOST"
echo "   Port: $REDIS_PORT"
echo "   User: $REDIS_USER (standard)"
echo "   Password: $REDIS_PASSWORD (standard)"
echo ""

# Configure environment with user's Redis Cloud instance
cat > .env << EOF
# Redis Cloud Configuration (user provided)
REDIS_HOST=$REDIS_HOST
REDIS_PORT=$REDIS_PORT
REDIS_PASSWORD=$REDIS_PASSWORD
REDIS_USER=$REDIS_USER
EOF

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    # On macOS, try to find Docker and add it to PATH permanently
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "Docker command not found. Searching for Docker Desktop..."

        # Common Docker Desktop locations
        DOCKER_PATHS=(
            "/Applications/Docker.app/Contents/Resources/bin"
            "/usr/local/bin"
            "/opt/homebrew/bin"
        )

        DOCKER_FOUND=""
        for path in "${DOCKER_PATHS[@]}"; do
            if [[ -f "$path/docker" ]]; then
                DOCKER_FOUND="$path"
                echo "Found Docker at: $path/docker"
                break
            fi
        done

        if [[ -n "$DOCKER_FOUND" ]]; then
            echo "Adding Docker to PATH permanently..."
            export PATH="$DOCKER_FOUND:$PATH"

            # Add to shell profile for permanent access
            SHELL_PROFILE=""
            if [[ -n "$ZSH_VERSION" ]] || [[ "$SHELL" == *"zsh"* ]]; then
                SHELL_PROFILE="$HOME/.zshrc"
            elif [[ -n "$BASH_VERSION" ]] || [[ "$SHELL" == *"bash"* ]]; then
                SHELL_PROFILE="$HOME/.bash_profile"
            fi

            if [[ -n "$SHELL_PROFILE" ]]; then
                # Check if PATH already contains Docker
                if ! grep -q "$DOCKER_FOUND" "$SHELL_PROFILE" 2>/dev/null; then
                    echo "export PATH=\"$DOCKER_FOUND:\$PATH\"" >> "$SHELL_PROFILE"
                    echo "Added Docker to $SHELL_PROFILE for future terminal sessions"
                fi
            fi

            echo "Docker command now available. Continuing..."
        else
            echo "Docker Desktop not found. Please install Docker Desktop..."
            echo ""
            echo "QUICK MANUAL INSTALL (2-3 minutes):"
            echo "1. Download: https://desktop.docker.com/mac/main/universal/Docker.dmg"
            echo "2. Open the downloaded .dmg file"
            echo "3. Drag Docker to Applications folder"
            echo "4. Open Docker Desktop from Applications"
            echo "5. Wait for Docker to start (whale icon in menu bar)"
            echo "6. Then run this script again: ./start.sh"
            echo ""
            echo "Opening download page..."
            open "https://www.docker.com/products/docker-desktop" 2>/dev/null || echo "Please visit: https://www.docker.com/products/docker-desktop"
            exit 0
        fi
    else
        # Linux
        echo "Detected Linux. Installing Docker..."
        curl -fsSL https://get.docker.com -o get-docker.sh
        sudo sh get-docker.sh
        sudo usermod -aG docker $USER
        echo "Docker installed. Please log out and log back in, then run this script again."
        exit 0
    fi
fi

# Check if Docker daemon is running
if ! docker info &> /dev/null; then
    echo "Docker is installed but not running."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "On macOS, please:"
        echo "1. Open Docker Desktop from Applications"
        echo "2. Wait for it to start completely"
        echo "3. Then run this script again"
    else
        echo "Please start the Docker service:"
        echo "sudo systemctl start docker"
    fi
    exit 1
fi

# Check if Docker Compose is available
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo "Docker Compose is not available. Please install Docker Compose."
    exit 1
fi

# Determine Docker Compose command
if command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE="docker-compose"
else
    DOCKER_COMPOSE="docker compose"
fi

echo "Cleaning up any existing containers..."
$DOCKER_COMPOSE -f docker-compose-cloud.yml down --remove-orphans

echo "Starting Redis RDI Training Environment..."
$DOCKER_COMPOSE -f docker-compose-cloud.yml up -d

echo "Waiting for services to start..."
sleep 10

# Wait for PostgreSQL to be ready
echo "Waiting for PostgreSQL to be ready..."
until docker exec rdi-postgres pg_isready -U postgres -d chinook &>/dev/null; do
    echo "   Still waiting for PostgreSQL..."
    sleep 5
done

echo "Checking container status..."
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""
echo "Environment ready!"
echo ""
echo "Dashboard: http://localhost:8080"
echo "Redis Insight: http://localhost:5540 (connect to your Redis: $REDIS_HOST:$REDIS_PORT)"
echo "SQLPad (PostgreSQL): http://localhost:3001 (admin@rl.org / redislabs)"
echo ""
echo "PostgreSQL connection details:"
echo "   Host: localhost, Port: 5432, User: postgres, Password: postgres, DB: chinook"
echo ""
echo "Your Redis Cloud target database:"
echo "   Host: $REDIS_HOST"
echo "   Port: $REDIS_PORT"
echo "   User: $REDIS_USER"
echo "   Password: $REDIS_PASSWORD"
echo ""
echo "To stop: ./stop.sh"
