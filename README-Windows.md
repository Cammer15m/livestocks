# Redis RDI CTF - Windows Setup

## Quick Start for Windows

### Option 1: Command Prompt (Recommended)
```cmd
start-windows.bat
```

### Option 2: PowerShell (if execution policy allows)
```powershell
.\start.ps1
```

### Option 3: PowerShell with bypass (if scripts are disabled)
```powershell
powershell -ExecutionPolicy Bypass -File start.ps1
```

## Requirements

1. **Docker Desktop** - Must be installed and running
2. **PowerShell** - Built into Windows (no additional installation needed)
3. **Redis Cloud instance** - You'll need the connection string

## Files for Windows Users

- **`start-windows.bat`** - Main startup script (handles PowerShell execution policy)
- **`stop-windows.bat`** - Stop script
- **`start.ps1`** - PowerShell script (same logic as Linux start.sh)
- **`stop.ps1`** - PowerShell stop script

## Troubleshooting

### "Execution of scripts is disabled on this system"
- Use `start-windows.bat` instead of running PowerShell directly
- The batch file automatically bypasses the execution policy

### "Docker is not running"
1. Open Docker Desktop from Start menu
2. Wait for the whale icon in system tray to be steady (not animated)
3. Run the script again

### "Invalid connection string format"
Make sure your Redis Cloud connection string follows this format:
```
redis://username:password@host:port
```

Example:
```
redis://default:mypassword@redis-17173.c14.us-east-1-2.ec2.redns.redis-cloud.com:17173
```

## What the script does

1. Prompts for your Redis Cloud connection string
2. Parses and validates the connection details
3. Creates `.env` file with your Redis configuration
4. Starts Docker containers (PostgreSQL, Redis Insight, SQLPad)
5. Waits for services to be ready
6. Shows you the dashboard URLs

## Access URLs (after startup)

- **Dashboard**: http://localhost:8080
- **Redis Insight**: http://localhost:5540
- **SQLPad**: http://localhost:3001 (admin@rl.org / redislabs)

## Stopping the Environment

```cmd
stop-windows.bat
```

Or:

```powershell
.\stop.ps1
```
