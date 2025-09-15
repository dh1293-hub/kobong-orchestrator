@echo off
setlocal enableextensions enabledelayedexpansion
set "PWSH=%ProgramFiles%\PowerShell\7\pwsh.exe"
if not exist "%PWSH%" set "PWSH=pwsh"
set "ROOT=D:\ChatGPT5_AI_Link\dosc\kobong-orchestrator"
cd /d "%ROOT%"

if "%~1"=="" goto :usage
set "SCRIPT=%~1"
shift

set "ARGSLIST="
:collect
if "%~1"=="" goto :run
set "ARGSLIST=!ARGSLIST!,""%~1"""
shift
goto :collect

:run
if defined ARGSLIST set "ARGSLIST=%ARGSLIST:~1%"
"%PWSH%" -NoProfile -ExecutionPolicy Bypass -WorkingDirectory "%ROOT%" -File "%ROOT%\scripts\g5\guard-run.ps1" -Script "%SCRIPT%" -Args !ARGSLIST!
exit /b %ERRORLEVEL%

:usage
echo Usage: kobong-run.cmd ^<script-relative^> [args...]
echo   ex) kobong-run.cmd scripts\g5\monitor-status.ps1 -Once -Port 8080
exit /b 1