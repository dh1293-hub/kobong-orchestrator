@echo off
setlocal
set "SCRIPT=%~dp0run-me.ps1"

if exist "%ProgramFiles%\PowerShell\7\pwsh.exe" goto use1
if exist "%ProgramW6432%\PowerShell\7\pwsh.exe" goto use2
where pwsh >nul 2>nul && goto usePATH

echo ERROR: PowerShell 7 (pwsh) not found. Install from https://aka.ms/powershell
pause
goto :eof

:use1
"%ProgramFiles%\PowerShell\7\pwsh.exe" -NoProfile -NoLogo -ExecutionPolicy Bypass -NoExit -File "%SCRIPT%"
goto :eof

:use2
"%ProgramW6432%\PowerShell\7\pwsh.exe" -NoProfile -NoLogo -ExecutionPolicy Bypass -NoExit -File "%SCRIPT%"
goto :eof

:usePATH
pwsh -NoProfile -NoLogo -ExecutionPolicy Bypass -NoExit -File "%SCRIPT%"
goto :eof