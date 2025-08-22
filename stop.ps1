#!/usr/bin/env pwsh

Write-Host "Stopping Redis RDI Training Environment..." -ForegroundColor Yellow

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

& $DOCKER_COMPOSE.Split() -f "docker-compose-cloud.yml" down --remove-orphans

Write-Host "Environment stopped." -ForegroundColor Green
Read-Host "Press Enter to continue"
