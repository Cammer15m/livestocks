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

# Function to install Docker Desktop automatically on macOS
install_docker_macos() {
    echo "Installing Docker Desktop automatically..."

    # Download Docker Desktop
    echo "Downloading Docker Desktop..."
    curl -L -o /tmp/Docker.dmg "https://desktop.docker.com/mac/main/universal/Docker.dmg"

    # Mount the DMG
    echo "Mounting Docker installer..."
    hdiutil attach /tmp/Docker.dmg -quiet

    # Copy Docker to Applications
    echo "Installing Docker to Applications..."
    cp -R "/Volumes/Docker/Docker.app" "/Applications/"

    # Unmount the DMG
    hdiutil detach "/Volumes/Docker" -quiet

    # Clean up
    rm /tmp/Docker.dmg

    echo "Docker Desktop installed successfully!"

    # Add Docker to PATH immediately
    export PATH="/Applications/Docker.app/Contents/Resources/bin:$PATH"

    # Add to shell profile permanently
    SHELL_PROFILE=""
    if [[ -n "$ZSH_VERSION" ]] || [[ "$SHELL" == *"zsh"* ]]; then
        SHELL_PROFILE="$HOME/.zshrc"
    elif [[ -n "$BASH_VERSION" ]] || [[ "$SHELL" == *"bash"* ]]; then
        SHELL_PROFILE="$HOME/.bash_profile"
    fi

    if [[ -n "$SHELL_PROFILE" ]]; then
        if ! grep -q "/Applications/Docker.app/Contents/Resources/bin" "$SHELL_PROFILE" 2>/dev/null; then
            echo 'export PATH="/Applications/Docker.app/Contents/Resources/bin:$PATH"' >> "$SHELL_PROFILE"
            echo "Added Docker to $SHELL_PROFILE for future terminal sessions"
        fi
    fi

    # Start Docker Desktop
    echo "Starting Docker Desktop..."
    open -a Docker

    echo "Waiting for Docker to start (this may take 30-60 seconds)..."
    sleep 10

    # Wait for Docker daemon to be ready
    local max_attempts=30
    local attempt=1
    while ! docker info &>/dev/null && [ $attempt -le $max_attempts ]; do
        echo "Waiting for Docker daemon... (attempt $attempt/$max_attempts)"
        sleep 2
        ((attempt++))
    done

    if docker info &>/dev/null; then
        echo "Docker is now running and ready!"
    else
        echo "Docker installation completed but daemon not ready yet."
        echo "Please wait a moment and run the script again: ./start.sh"
        exit 0
    fi
}

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # Check if Docker Desktop exists but not in PATH
        if [[ -f "/Applications/Docker.app/Contents/Resources/bin/docker" ]]; then
            echo "Docker Desktop found but not in PATH. Adding to PATH..."
            export PATH="/Applications/Docker.app/Contents/Resources/bin:$PATH"

            # Add to shell profile permanently
            SHELL_PROFILE=""
            if [[ -n "$ZSH_VERSION" ]] || [[ "$SHELL" == *"zsh"* ]]; then
                SHELL_PROFILE="$HOME/.zshrc"
            elif [[ -n "$BASH_VERSION" ]] || [[ "$SHELL" == *"bash"* ]]; then
                SHELL_PROFILE="$HOME/.bash_profile"
            fi

            if [[ -n "$SHELL_PROFILE" ]]; then
                if ! grep -q "/Applications/Docker.app/Contents/Resources/bin" "$SHELL_PROFILE" 2>/dev/null; then
                    echo 'export PATH="/Applications/Docker.app/Contents/Resources/bin:$PATH"' >> "$SHELL_PROFILE"
                    echo "Added Docker to $SHELL_PROFILE for future terminal sessions"
                fi
            fi
        else
            # Docker not installed, install it automatically
            install_docker_macos
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
