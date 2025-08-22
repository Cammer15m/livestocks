#!/usr/bin/env pwsh

Write-Host "Redis RDI Training Environment" -ForegroundColor Green
Write-Host "==============================" -ForegroundColor Green
Write-Host ""

# Gather Redis Cloud connection details from user
Write-Host "Redis Cloud Configuration" -ForegroundColor Yellow
Write-Host "Please paste your Redis Cloud connection string:"
Write-Host "This Redis instance will be used as the target database."
Write-Host ""
Write-Host "Format: redis://username:password@host:port"
Write-Host "Example: redis://default:mypassword@redis-17173.c14.us-east-1-2.ec2.redns.redis-cloud.com:17173"
Write-Host ""
$REDIS_CONNECTION_STRING = Read-Host "Redis connection string"

# Parse the connection string (same regex as bash version)
if ($REDIS_CONNECTION_STRING -match 'redis://([^:]+):([^@]+)@([^:]+):([0-9]+)') {
    $REDIS_USER = $matches[1]
    $REDIS_PASSWORD = $matches[2]
    $REDIS_HOST = $matches[3]
    $REDIS_PORT = $matches[4]

    Write-Host ""
    Write-Host "Parsed connection details:"
    Write-Host "   Host: $REDIS_HOST"
    Write-Host "   Port: $REDIS_PORT"
    Write-Host "   User: $REDIS_USER"
    Write-Host "   Password: ********"
} else {
    Write-Host "Error: Invalid connection string format!" -ForegroundColor Red
    Write-Host "Expected format: redis://username:password@host:port"
    Write-Host "Example: redis://default:mypassword@redis-17173.c14.us-east-1-2.ec2.redns.redis-cloud.com:17173"
    Read-Host "Press Enter to exit"
    exit 1
}

# Validate required fields
if ([string]::IsNullOrEmpty($REDIS_HOST) -or [string]::IsNullOrEmpty($REDIS_PORT) -or [string]::IsNullOrEmpty($REDIS_PASSWORD)) {
    Write-Host "Error: Redis host, port, and password are required!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Example Redis Cloud connection string:"
    Write-Host "   redis://default:password@redis-17173.c14.us-east-1-2.ec2.redns.redis-cloud.com:17173"
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host ""
Write-Host "Redis Cloud configuration:"
Write-Host "   Host: $REDIS_HOST"
Write-Host "   Port: $REDIS_PORT"
Write-Host "   User: $REDIS_USER"
Write-Host "   Password: ********"
Write-Host ""

# Configure environment with user's Redis Cloud instance
$envContent = @"
# Redis Cloud Configuration (user provided)
REDIS_HOST=$REDIS_HOST
REDIS_PORT=$REDIS_PORT
REDIS_PASSWORD=$REDIS_PASSWORD
REDIS_USER=$REDIS_USER
"@

$envContent | Out-File -FilePath ".env" -Encoding UTF8

# Check if Docker is running
try {
    docker info | Out-Null
} catch {
    Write-Host "Docker is not running. Please start Docker Desktop and try again." -ForegroundColor Red
    Write-Host ""
    Write-Host "To start Docker Desktop:"
    Write-Host "1. Open Docker Desktop from the Start menu"
    Write-Host "2. Wait for it to fully start (whale icon in system tray should be steady)"
    Write-Host "3. Run this script again"
    Read-Host "Press Enter to exit"
    exit 1
}

# Check if Docker Compose is available
$DOCKER_COMPOSE = ""
try {
    docker compose version | Out-Null
    $DOCKER_COMPOSE = "docker compose"
} catch {
    try {
        docker-compose --version | Out-Null
        $DOCKER_COMPOSE = "docker-compose"
    } catch {
        Write-Host "Docker Compose is not available. Please install Docker Compose." -ForegroundColor Red
        Read-Host "Press Enter to exit"
        exit 1
    }
}

# Check if docker-compose-cloud.yml exists
if (-not (Test-Path "docker-compose-cloud.yml")) {
    Write-Host "Error: docker-compose-cloud.yml file not found!" -ForegroundColor Red
    Write-Host "Please make sure you're running this script from the correct directory."
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "Cleaning up any existing containers..." -ForegroundColor Yellow
& $DOCKER_COMPOSE.Split() -f "docker-compose-cloud.yml" down --remove-orphans

Write-Host "Starting Redis RDI Training Environment..." -ForegroundColor Yellow
& $DOCKER_COMPOSE.Split() -f "docker-compose-cloud.yml" up -d

if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Failed to start containers!" -ForegroundColor Red
    Write-Host "Please check Docker Desktop is running and try again."
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "Waiting for services to start..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

# Wait for PostgreSQL to be ready
Write-Host "Waiting for PostgreSQL to be ready..." -ForegroundColor Yellow
$attempts = 0
$maxAttempts = 30
do {
    $attempts++
    try {
        docker exec rdi-postgres pg_isready -U postgres -d chinook | Out-Null
        if ($LASTEXITCODE -eq 0) { break }
    } catch {}
    
    if ($attempts -lt $maxAttempts) {
        Write-Host "   Still waiting for PostgreSQL... (attempt $attempts/$maxAttempts)"
        Start-Sleep -Seconds 5
    } else {
        Write-Host "Warning: PostgreSQL may not be ready yet, but continuing..." -ForegroundColor Yellow
        break
    }
} while ($attempts -lt $maxAttempts)

Write-Host "Checking container status..." -ForegroundColor Yellow
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

Write-Host ""
Write-Host "Environment ready!" -ForegroundColor Green
Write-Host ""
Write-Host "Dashboard: http://localhost:8080"
Write-Host "Redis Insight: http://localhost:5540 (connect to your Redis: $REDIS_HOST`:$REDIS_PORT)"
Write-Host "SQLPad (PostgreSQL): http://localhost:3001 (admin@rl.org / redislabs)"
Write-Host ""
Write-Host "PostgreSQL connection details:"
Write-Host "   Host: localhost, Port: 5432, User: postgres, Password: postgres, DB: chinook"
Write-Host ""
Write-Host "Your Redis Cloud target database:"
Write-Host "   Host: $REDIS_HOST"
Write-Host "   Port: $REDIS_PORT"
Write-Host "   User: $REDIS_USER"
Write-Host "   Password: ********"
Write-Host ""
Write-Host "To stop: .\stop.ps1"
Write-Host ""
Read-Host "Press Enter to continue"
