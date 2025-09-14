@echo off
setlocal
rem === Resolve pwsh path ===
set "PW=%ProgramFiles%\PowerShell\7\pwsh.exe"
if exist "%ProgramW6432%\PowerShell\7\pwsh.exe" set "PW=%ProgramW6432%\PowerShell\7\pwsh.exe"
if not exist "%PW%" set "PW=pwsh.exe"

rem === Repo/Script/Port ===
set "REPO=D:/ChatGPT5_AI_Link/dosc/kobong-orchestrator"
set "SCRIPT=%REPO%\scripts\g5\monitor-health.ps1"
set "PORT=8080"

rem === Run hidden in background ===
start "" "%PW%" -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "%SCRIPT%" -Port %PORT%
exit /b 0