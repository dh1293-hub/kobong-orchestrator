@echo off
setlocal
REM ── UTF-8 콘솔(선택) ──
chcp 65001 >nul 2>nul

REM ── 서버 폴더 고정 ──
set "SRVDIR=D:\ChatGPT5_AI_Link\dosc\kobong-orchestrator\server"

REM ── PowerShell 7 우선, 없으면 Windows PowerShell ──
set "PWSH=%ProgramFiles%\PowerShell\7\pwsh.exe"
if not exist "%PWSH%" set "PWSH=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"

if not exist "%SRVDIR%" (
  echo [ERROR] Server dir not found: %SRVDIR%
  pause
  exit /b 1
)

REM ── 새 창으로 PowerShell만 실행 (있으면 venv 활성화; 서버는 자동 실행 안 함) ──
start "KOBONG SERVER" "%PWSH%" -NoLogo -NoExit -ExecutionPolicy Bypass -Command ^
"$ErrorActionPreference='Continue'; ^
 Set-Location -Path '%SRVDIR%'; ^
 $env:PYTHONPATH = (Resolve-Path ..); ^
 if (Test-Path '.\.venv\Scripts\Activate.ps1') { ^
   & .\.venv\Scripts\Activate.ps1; ^
   Write-Host '[INFO] venv activated' -ForegroundColor Green ^
 } else { ^
   Write-Host '[WARN] .\.venv not found (continue without venv)' -ForegroundColor Yellow ^
 }; ^
 Write-Host ('[INFO] Server shell ready  Path={0}' -f (Get-Location)) -ForegroundColor Cyan; ^
 Write-Host 'Run:' -NoNewline; Write-Host '  python -m uvicorn server.app:app --host 127.0.0.1 --port 8080 --reload' -ForegroundColor Magenta"

endlocal
exit /b 0

