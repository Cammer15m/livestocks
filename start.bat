@echo off
echo Redis RDI Training Environment
echo ==============================
echo.

REM Check if PowerShell script exists
if not exist "start.ps1" (
    echo Error: start.ps1 not found!
    echo Please make sure you're in the correct directory.
    pause
    exit /b 1
)

echo Starting Redis RDI Training Environment...
echo.
echo Note: Running PowerShell with bypass execution policy...
echo.

REM Run PowerShell script with execution policy bypass
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "& '%~dp0start.ps1'"

if errorlevel 1 (
    echo.
    echo Error: PowerShell script failed!
    echo Please check the error messages above.
    pause
    exit /b 1
)

echo.
echo Script completed successfully.
pause
