@echo off
setlocal
set "HOOK_DIR=%~dp0"
set "PS7=pwsh.exe"
where %PS7% >nul 2>&1
if errorlevel 1 (
  echo [BLOCK] PowerShell 7 (pwsh) not found; install PS7 to run pre-commit checks.
  exit /b 1
)
"%PS7%" -NoProfile -NonInteractive -File "%HOOK_DIR%pre-commit.ps1"
exit /b %ERRORLEVEL%