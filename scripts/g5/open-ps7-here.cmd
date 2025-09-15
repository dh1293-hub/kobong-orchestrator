@echo off
setlocal
set PWSH=%ProgramFiles%\PowerShell\7\pwsh.exe
if not exist "%PWSH%" set PWSH=pwsh
cd /d "D:\ChatGPT5_AI_Link\dosc\kobong-orchestrator"
"%PWSH%" -NoLogo -NoProfile -ExecutionPolicy Bypass