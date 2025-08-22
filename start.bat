@echo off
setlocal enabledelayedexpansion

echo Redis RDI Training Environment
echo ==============================
echo.

REM Gather Redis Cloud connection details from user
echo Redis Cloud Configuration
echo Please paste your Redis Cloud connection string:
echo This Redis instance will be used as the target database.
echo.
echo Format: redis://username:password@host:port
echo Example: redis://default:mypassword@redis-17173.c14.us-east-1-2.ec2.redns.redis-cloud.com:17173
echo.
set /p REDIS_CONNECTION_STRING="Redis connection string: "

REM Create temporary PowerShell script for parsing (escape single quotes)
set "ESCAPED_CONNECTION_STRING=%REDIS_CONNECTION_STRING:'=''%"
echo $connectionString = '%ESCAPED_CONNECTION_STRING%' > parse_redis.ps1
echo if ($connectionString -match 'redis://([^:]+):([^@]+)@([^:]+):([0-9]+)') { >> parse_redis.ps1
echo     Write-Output $matches[1] >> parse_redis.ps1
echo     Write-Output $matches[2] >> parse_redis.ps1
echo     Write-Output $matches[3] >> parse_redis.ps1
echo     Write-Output $matches[4] >> parse_redis.ps1
echo } else { >> parse_redis.ps1
echo     Write-Output 'ERROR' >> parse_redis.ps1
echo } >> parse_redis.ps1

REM Parse the connection string using PowerShell
for /f "tokens=1,2,3,4" %%a in ('powershell -ExecutionPolicy Bypass -File parse_redis.ps1') do (
    if "%%a"=="ERROR" (
        echo Error: Invalid connection string format!
        echo Expected format: redis://username:password@host:port
        echo Example: redis://default:mypassword@redis-17173.c14.us-east-1-2.ec2.redns.redis-cloud.com:17173
        del parse_redis.ps1 2>nul
        pause
        exit /b 1
    )
    set REDIS_USER=%%a
    set REDIS_PASSWORD=%%b
    set REDIS_HOST=%%c
    set REDIS_PORT=%%d
)

REM Clean up temporary file
del parse_redis.ps1 2>nul

REM Debug output
echo Debug: REDIS_USER=%REDIS_USER%
echo Debug: REDIS_HOST=%REDIS_HOST%
echo Debug: REDIS_PORT=%REDIS_PORT%

REM Validate required fields
if "%REDIS_HOST%"=="" (
    echo Error: Redis host is required!
    echo.
    echo Example Redis Cloud connection string:
    echo    redis://default:password@redis-17173.c14.us-east-1-2.ec2.redns.redis-cloud.com:17173
    pause
    exit /b 1
)

if "%REDIS_PORT%"=="" (
    echo Error: Redis port is required!
    echo.
    echo Example Redis Cloud connection string:
    echo    redis://default:password@redis-17173.c14.us-east-1-2.ec2.redns.redis-cloud.com:17173
    pause
    exit /b 1
)

if "%REDIS_PASSWORD%"=="" (
    echo Error: Redis password is required!
    echo.
    echo Example Redis Cloud connection string:
    echo    redis://default:password@redis-17173.c14.us-east-1-2.ec2.redns.redis-cloud.com:17173
    pause
    exit /b 1
)

echo.
echo Parsed connection details:
echo    Host: %REDIS_HOST%
echo    Port: %REDIS_PORT%
echo    User: %REDIS_USER%
echo    Password: ********
echo.

REM Configure environment with user's Redis Cloud instance
(
echo # Redis Cloud Configuration (user provided)
echo REDIS_HOST=%REDIS_HOST%
echo REDIS_PORT=%REDIS_PORT%
echo REDIS_PASSWORD=%REDIS_PASSWORD%
echo REDIS_USER=%REDIS_USER%
) > .env

REM Check if Docker is running
docker info >nul 2>&1
if errorlevel 1 (
    echo Docker is not running. Please start Docker Desktop and try again.
    echo.
    echo To start Docker Desktop:
    echo 1. Open Docker Desktop from the Start menu
    echo 2. Wait for it to fully start (whale icon in system tray should be steady)
    echo 3. Run this script again
    pause
    exit /b 1
)

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

REM Check if docker-compose-cloud.yml exists
if not exist "docker-compose-cloud.yml" (
    echo Error: docker-compose-cloud.yml file not found!
    echo Please make sure you're running this script from the correct directory.
    pause
    exit /b 1
)

echo Cleaning up any existing containers...
%DOCKER_COMPOSE% -f docker-compose-cloud.yml down --remove-orphans
if errorlevel 1 (
    echo Warning: Error during cleanup, but continuing...
)

echo Starting Redis RDI Training Environment...
%DOCKER_COMPOSE% -f docker-compose-cloud.yml up -d
if errorlevel 1 (
    echo Error: Failed to start containers!
    echo Please check Docker Desktop is running and try again.
    pause
    exit /b 1
)

echo Waiting for services to start...
timeout /t 10 /nobreak >nul

REM Wait for PostgreSQL to be ready
echo Waiting for PostgreSQL to be ready...
set /a postgres_attempts=0
:wait_postgres
set /a postgres_attempts+=1
docker exec rdi-postgres pg_isready -U postgres -d chinook >nul 2>&1
if errorlevel 1 (
    if %postgres_attempts% LSS 30 (
        echo    Still waiting for PostgreSQL... (attempt %postgres_attempts%/30)
        timeout /t 5 /nobreak >nul
        goto wait_postgres
    ) else (
        echo Warning: PostgreSQL may not be ready yet, but continuing...
    )
)

echo Checking container status...
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo.
echo Environment ready!
echo.
echo Dashboard: http://localhost:8080
echo Redis Insight: http://localhost:5540 (connect to your Redis: %REDIS_HOST%:%REDIS_PORT%)
echo SQLPad (PostgreSQL): http://localhost:3001 (admin@rl.org / redislabs)
echo.
echo PostgreSQL connection details:
echo    Host: localhost, Port: 5432, User: postgres, Password: postgres, DB: chinook
echo.
echo Your Redis Cloud target database:
echo    Host: %REDIS_HOST%
echo    Port: %REDIS_PORT%
echo    User: %REDIS_USER%
echo    Password: ********
echo.
echo To stop: stop.bat
echo.
pause
