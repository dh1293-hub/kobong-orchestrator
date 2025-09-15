@echo off
setlocal
set "REPO=D:/ChatGPT5_AI_Link/dosc/kobong-orchestrator"
set "PS1=scripts/view-ci-summary.ps1"
rem Prefer system-installed PS7
if exist "%ProgramFiles%\PowerShell\7\pwsh.exe" (
  set "PWSH=%ProgramFiles%\PowerShell\7\pwsh.exe"
) else if exist "%ProgramW6432%\PowerShell\7\pwsh.exe" (
  set "PWSH=%ProgramW6432%\PowerShell\7\pwsh.exe"
) else (
  set "PWSH=pwsh"
)
pushd "%REPO%"
start "" "%PWSH%" -NoExit -NoProfile -ExecutionPolicy Bypass -File "%PS1%"
endlocal