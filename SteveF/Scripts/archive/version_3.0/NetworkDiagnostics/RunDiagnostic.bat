@echo off
setlocal

set SCRIPT_DIR=C:\Scripts\NetworkDiagnostics
set MAIN_SCRIPT=%SCRIPT_DIR%\NetworkDiagnostics.ps1

where powershell >nul 2>&1
if errorlevel 1 (
    echo PowerShell not found. Please install PowerShell to run diagnostics.
    pause
    exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%MAIN_SCRIPT%"

pause
endlocal
