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

# Check if Docker is installed
$dockerInstalled = $false
try {
    $null = Get-Command docker -ErrorAction Stop
    $dockerInstalled = $true
} catch {
    # Check if Docker Desktop is installed but not in PATH
    $dockerDesktopPaths = @(
        "${env:ProgramFiles}\Docker\Docker\resources\bin\docker.exe",
        "${env:ProgramFiles(x86)}\Docker\Docker\resources\bin\docker.exe",
        "$env:LOCALAPPDATA\Programs\Docker\Docker\resources\bin\docker.exe"
    )

    $dockerFound = $false
    foreach ($path in $dockerDesktopPaths) {
        if (Test-Path $path) {
            Write-Host "Docker Desktop found but not in PATH. Adding to PATH..." -ForegroundColor Yellow
            $dockerDir = Split-Path $path -Parent
            $env:PATH = "$dockerDir;$env:PATH"
            $dockerInstalled = $true
            $dockerFound = $true
            break
        }
    }

    if (-not $dockerFound) {
        Write-Host "Docker is not installed." -ForegroundColor Red
        Write-Host ""
        Write-Host "Please install Docker Desktop for Windows:"
        Write-Host "1. Download from: https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe"
        Write-Host "2. Run the installer and follow the setup wizard"
        Write-Host "3. Restart your computer if prompted"
        Write-Host "4. Start Docker Desktop from the Start menu"
        Write-Host "5. Wait for Docker to fully start (whale icon in system tray should be steady)"
        Write-Host "6. Run this script again"
        Read-Host "Press Enter to exit"
        exit 1
    }
}

# Check if Docker is running
if ($dockerInstalled) {
    try {
        docker info | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw "Docker daemon not running"
        }
    } catch {
        Write-Host "Docker is installed but not running." -ForegroundColor Yellow
        Write-Host "Attempting to start Docker Desktop automatically..." -ForegroundColor Yellow

        # Try to start Docker Desktop
        $dockerDesktopExe = @(
            "${env:ProgramFiles}\Docker\Docker\Docker Desktop.exe",
            "${env:ProgramFiles(x86)}\Docker\Docker\Docker Desktop.exe",
            "$env:LOCALAPPDATA\Programs\Docker\Docker\Docker Desktop.exe"
        )

        $dockerStarted = $false
        foreach ($exe in $dockerDesktopExe) {
            if (Test-Path $exe) {
                Write-Host "Starting Docker Desktop..." -ForegroundColor Yellow
                Start-Process -FilePath $exe -WindowStyle Hidden
                $dockerStarted = $true
                break
            }
        }

        if ($dockerStarted) {
            Write-Host "Waiting for Docker to start (this may take 30-60 seconds)..." -ForegroundColor Yellow
            Start-Sleep -Seconds 10

            # Wait for Docker daemon to be ready
            $maxAttempts = 30
            $attempt = 1
            while ($attempt -le $maxAttempts) {
                try {
                    docker info | Out-Null
                    if ($LASTEXITCODE -eq 0) {
                        Write-Host "Docker is now running and ready!" -ForegroundColor Green
                        break
                    }
                } catch {}

                if ($attempt -lt $maxAttempts) {
                    Write-Host "Waiting for Docker daemon... (attempt $attempt/$maxAttempts)"
                    Start-Sleep -Seconds 2
                    $attempt++
                } else {
                    Write-Host "Docker Desktop is starting but not ready yet." -ForegroundColor Yellow
                    Write-Host "Please wait a moment and run the script again." -ForegroundColor Yellow
                    Read-Host "Press Enter to exit"
                    exit 0
                }
            }
        } else {
            Write-Host "Could not automatically start Docker Desktop." -ForegroundColor Red
            Write-Host ""
            Write-Host "Please start Docker Desktop manually:"
            Write-Host "1. Open Docker Desktop from the Start menu"
            Write-Host "2. Wait for it to fully start (whale icon in system tray should be steady)"
            Write-Host "3. Run this script again"
            Read-Host "Press Enter to exit"
            exit 1
        }
    }
}

# Check if Docker Compose is available (matching bash script logic)
$DOCKER_COMPOSE = ""
$composeFound = $false

# First check: try both docker-compose and docker compose commands
try {
    $null = Get-Command docker-compose -ErrorAction Stop
    docker-compose --version | Out-Null
    if ($LASTEXITCODE -eq 0) {
        $composeFound = $true
    }
} catch {}

if (-not $composeFound) {
    try {
        docker compose version | Out-Null
        if ($LASTEXITCODE -eq 0) {
            $composeFound = $true
        }
    } catch {}
}

if (-not $composeFound) {
    Write-Host "Docker Compose is not available." -ForegroundColor Red
    Write-Host "Please install Docker Compose or ensure Docker Desktop is fully installed." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Determine which Docker Compose command to use (matching bash script logic)
try {
    $null = Get-Command docker-compose -ErrorAction Stop
    $DOCKER_COMPOSE = "docker-compose"
    Write-Host "Using docker-compose command" -ForegroundColor Green
} catch {
    $DOCKER_COMPOSE = "docker compose"
    Write-Host "Using docker compose command" -ForegroundColor Green
}

# Check if docker-compose-cloud.yml exists
if (-not (Test-Path "docker-compose-cloud.yml")) {
    Write-Host "Error: docker-compose-cloud.yml file not found!" -ForegroundColor Red
    Write-Host "Please make sure you're running this script from the correct directory."
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "Cleaning up any existing containers..." -ForegroundColor Yellow
if ($DOCKER_COMPOSE -eq "docker-compose") {
    & docker-compose -f "docker-compose-cloud.yml" down --remove-orphans
} else {
    & docker compose -f "docker-compose-cloud.yml" down --remove-orphans
}

Write-Host "Starting Redis RDI Training Environment..." -ForegroundColor Yellow
if ($DOCKER_COMPOSE -eq "docker-compose") {
    & docker-compose -f "docker-compose-cloud.yml" up -d
} else {
    & docker compose -f "docker-compose-cloud.yml" up -d
}

if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Failed to start containers!" -ForegroundColor Red
    Write-Host "Please check Docker Desktop is running and try again."
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "Waiting for services to start..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

# Wait for PostgreSQL to be ready with enhanced logging
Write-Host "Waiting for PostgreSQL to be ready..." -ForegroundColor Yellow
Write-Host "This includes database initialization, table creation, and Debezium configuration..." -ForegroundColor Yellow

$attempts = 0
$maxAttempts = 60  # 5 minutes total
do {
    $attempts++

    # Check if container is running
    $containerRunning = docker ps --format "{{.Names}}" | Select-String "rdi-postgres"
    if (-not $containerRunning) {
        Write-Host "ERROR: PostgreSQL container is not running!" -ForegroundColor Red
        Write-Host "Checking container status:" -ForegroundColor Yellow
        docker ps -a --filter "name=rdi-postgres"
        Write-Host ""
        Write-Host "PostgreSQL container logs:" -ForegroundColor Yellow
        docker logs rdi-postgres --tail 20
        Read-Host "Press Enter to exit"
        exit 1
    }

    # Check PostgreSQL readiness
    try {
        docker exec rdi-postgres pg_isready -U postgres -d chinook | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "PostgreSQL is ready!" -ForegroundColor Green
            break
        }
    } catch {}

    # Show progress and logs every 10 attempts (50 seconds)
    if ($attempts % 10 -eq 0) {
        Write-Host "   Still waiting for PostgreSQL... (attempt $attempts/$maxAttempts)" -ForegroundColor Yellow
        Write-Host "   Container status:" -ForegroundColor Cyan
        try {
            docker exec rdi-postgres ps aux | Select-String "postgres"
        } catch {
            Write-Host "   Could not check PostgreSQL processes" -ForegroundColor Yellow
        }
        Write-Host "   Recent PostgreSQL logs:" -ForegroundColor Cyan
        try {
            docker logs rdi-postgres --tail 5 2>$null
        } catch {
            Write-Host "   Could not retrieve logs" -ForegroundColor Yellow
        }
        Write-Host ""
    } elseif ($attempts % 5 -eq 0) {
        Write-Host "   Still waiting for PostgreSQL... (attempt $attempts/$maxAttempts)" -ForegroundColor Yellow
    }

    Start-Sleep -Seconds 5
} while ($attempts -lt $maxAttempts)

if ($attempts -ge $maxAttempts) {
    Write-Host "ERROR: PostgreSQL failed to start within 5 minutes!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Container status:" -ForegroundColor Yellow
    docker ps -a --filter "name=rdi-postgres"
    Write-Host ""
    Write-Host "PostgreSQL logs:" -ForegroundColor Yellow
    docker logs rdi-postgres
    Write-Host ""
    Write-Host "Please check the logs above for errors and try again." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Verify database initialization
Write-Host "Verifying database initialization..." -ForegroundColor Yellow
try {
    docker exec rdi-postgres psql -U postgres -d chinook -c "SELECT COUNT(*) FROM \"Track\";" | Out-Null
    if ($LASTEXITCODE -eq 0) {
        $trackCount = docker exec rdi-postgres psql -U postgres -d chinook -t -c "SELECT COUNT(*) FROM \"Track\";"
        $trackCount = $trackCount.Trim()
        Write-Host "Database verification successful! Track table has $trackCount records." -ForegroundColor Green
    } else {
        Write-Host "WARNING: Could not verify database initialization. Continuing anyway..." -ForegroundColor Yellow
    }
} catch {
    Write-Host "WARNING: Could not verify database initialization. Continuing anyway..." -ForegroundColor Yellow
}

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
