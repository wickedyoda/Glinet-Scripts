@echo off
setlocal

REM Set path to your PowerShell script
set ScriptPath=C:\scripts\NetworkDiagnostics.ps1

echo Starting Network Diagnostics at %DATE% %TIME%
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%ScriptPath%"

echo.
echo Diagnostics complete. Press any key to exit...
pause

endlocal
