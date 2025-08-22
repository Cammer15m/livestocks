@echo off
echo Stopping Redis RDI Training Environment...
echo.

REM Check if PowerShell script exists
if not exist "stop.ps1" (
    echo Error: stop.ps1 not found!
    echo Please make sure you're in the correct directory.
    pause
    exit /b 1
)

echo Running PowerShell with bypass execution policy...
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "& '%~dp0stop.ps1'"

if errorlevel 1 (
    echo.
    echo Error: PowerShell script failed!
    pause
    exit /b 1
)

echo.
echo Script completed successfully.
pause
