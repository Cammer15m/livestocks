#!/usr/bin/env pwsh

Write-Host "Stopping Redis RDI Training Environment..." -ForegroundColor Yellow

# Check if Docker Compose is available
$DOCKER_COMPOSE = ""
$composeFound = $false

# Try docker-compose first (more common on Windows)
try {
    $result = docker-compose --version 2>$null
    if ($LASTEXITCODE -eq 0) {
        $DOCKER_COMPOSE = "docker-compose"
        $composeFound = $true
    }
} catch {
    # Ignore error, try next option
}

# Try docker compose if docker-compose didn't work
if (-not $composeFound) {
    try {
        $result = docker compose version 2>$null
        if ($LASTEXITCODE -eq 0) {
            $DOCKER_COMPOSE = "docker compose"
            $composeFound = $true
        }
    } catch {
        # Ignore error
    }
}

if (-not $composeFound) {
    Write-Host "Docker Compose is not available. Please install Docker Compose." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

if ($DOCKER_COMPOSE -eq "docker-compose") {
    & docker-compose -f "docker-compose-cloud.yml" down --remove-orphans
} else {
    & docker compose -f "docker-compose-cloud.yml" down --remove-orphans
}

Write-Host "Environment stopped." -ForegroundColor Green
Read-Host "Press Enter to continue"
