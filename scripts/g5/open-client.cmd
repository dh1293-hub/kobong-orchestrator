@echo off
setlocal
REM ── 콘솔 한글 깨짐 방지(선택) ──
chcp 65001 >nul 2>nul

REM ── 리포지토리 루트 경로 ──
set "ROOT=D:\ChatGPT5_AI_Link\dosc\kobong-orchestrator"

REM ── PowerShell 7 우선, 없으면 Windows PowerShell ──
set "PWSH=%ProgramFiles%\PowerShell\7\pwsh.exe"
if not exist "%PWSH%" set "PWSH=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"

REM ── 새 창으로 PowerShell만 띄우기(아무 검사/요청 안 함) ──
start "KOBONG CLIENT" "%PWSH%" -NoLogo -NoExit -ExecutionPolicy Bypass ^
  -Command "try { Set-Location -Path '%ROOT%' } catch { Write-Host '[WARN] repo not found: %ROOT%' -ForegroundColor Yellow }; Write-Host '[INFO] Client shell ready' -ForegroundColor Green"

endlocal
exit /b 0


