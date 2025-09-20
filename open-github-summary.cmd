:: # NO-SHELL
@echo off
chcp 65001 >nul 2>nul
set "ROOT=D:\ChatGPT5_AI_Link\dosc\kobong-orchestrator"
set "PWSH=%ProgramFiles%\PowerShell\7\pwsh.exe"
if not exist "%PWSH%" set "PWSH=%SystemRoot%\System32\WindowsPowerShell\\v1.0\\powershell.exe"
start "GitHub Summary API" "%PWSH%" -NoExit -File "%ROOT%\\scripts\\github\\run-github-summary.ps1" -Root "%ROOT%" -Owner "dh1293-hub" -Repo "kobong-orchestrator" -Port 8787 -ConfirmApply
