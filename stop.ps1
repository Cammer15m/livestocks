#!/usr/bin/env pwsh

Write-Host "Stopping Redis RDI Training Environment..." -ForegroundColor Yellow

# Check if Docker Compose is available (matching start.ps1 logic)
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

# Determine which Docker Compose command to use (matching start.ps1 logic)
try {
    $null = Get-Command docker-compose -ErrorAction Stop
    $DOCKER_COMPOSE = "docker-compose"
} catch {
    $DOCKER_COMPOSE = "docker compose"
}

if ($DOCKER_COMPOSE -eq "docker-compose") {
    & docker-compose -f "docker-compose-cloud.yml" down --remove-orphans
} else {
    & docker compose -f "docker-compose-cloud.yml" down --remove-orphans
}

Write-Host "Environment stopped." -ForegroundColor Green
Read-Host "Press Enter to continue"
