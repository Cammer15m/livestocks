@echo off

echo Stopping Redis RDI Training Environment...

REM Check if Docker Compose is available
docker compose version >nul 2>&1
if errorlevel 1 (
    docker-compose --version >nul 2>&1
    if errorlevel 1 (
        echo Docker Compose is not available. Please install Docker Compose.
        pause
        exit /b 1
    ) else (
        set DOCKER_COMPOSE=docker-compose
    )
) else (
    set DOCKER_COMPOSE=docker compose
)

%DOCKER_COMPOSE% -f docker-compose-cloud.yml down --remove-orphans

echo Environment stopped.
pause
