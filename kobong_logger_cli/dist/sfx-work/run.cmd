@echo off
setlocal
set SCRIPT=%~dp0install-logging-bundle.auto.ps1
if exist "%ProgramFiles%\PowerShell\7\pwsh.exe" (
  "%ProgramFiles%\PowerShell\7\pwsh.exe" -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%" -WithActions -Renormalize
) else (
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%" -WithActions -Renormalize
)
endlocal