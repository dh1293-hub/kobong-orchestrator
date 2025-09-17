@echo off
setlocal
set "SCRIPT=%~dp0pre-commit.ps1"
where pwsh >nul 2>nul
if errorlevel 1 (
  set "PWSH=%ProgramFiles%\PowerShell\7\pwsh.exe"
) else (
  for /f "usebackq delims=" %%P in (`where pwsh`) do set "PWSH=%%P"
)
"%PWSH%" -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%" %*
exit /b %ERRORLEVEL%