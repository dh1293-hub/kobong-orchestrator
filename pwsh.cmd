@echo off
setlocal
where pwsh >nul 2>&1
if %ERRORLEVEL%==0 (
  pwsh %*
  exit /b %ERRORLEVEL%
)
powershell -NoProfile -ExecutionPolicy Bypass -File %*
exit /b %ERRORLEVEL%
