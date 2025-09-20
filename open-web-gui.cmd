:: # NO-SHELL
@echo off
chcp 65001 >nul 2>nul
set "ROOT=D:\ChatGPT5_AI_Link\dosc\kobong-orchestrator"
set "WEB=%ROOT%\web"
set "PWSH=%ProgramFiles%\PowerShell\7\pwsh.exe"
if not exist "%PWSH%" set "PWSH=%SystemRoot%\System32\WindowsPowerShell\vp1.0\powershell.exe"
start "Web GUI" "%PWSH%" -NoExit -File "%WEB%\serve-web.ps1" -Port 8080 -Root "%WEB%"
start "" "http://127.0.0.1:8080/"
