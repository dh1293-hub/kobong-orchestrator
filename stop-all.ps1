# APPLY IN SHELL
#requires -Version 7.0
param([int]$ApiPort=8787,[int]$WebPort=8080,[string]$Root="D:\ChatGPT5_AI_Link\dosc\kobong-orchestrator")
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
# 백엔드 안전 종료(콘솔에 표시된 키 없이 강제 정지)
(Get-NetTCPConnection -LocalPort $ApiPort -State Listen -ErrorAction SilentlyContinue |
  Select-Object -Expand OwningProcess -Unique) | ForEach-Object { Stop-Process -Id $_ -Force -ErrorAction SilentlyContinue }
# 웹 서버 강제 정지
(Get-NetTCPConnection -LocalPort $WebPort -State Listen -ErrorAction SilentlyContinue |
  Select-Object -Expand OwningProcess -Unique) | ForEach-Object { Stop-Process -Id $_ -Force -ErrorAction SilentlyContinue }
# stale lock 제거
$Lock = Join-Path $Root '.gpt5.lock'; if (Test-Path $Lock) { Remove-Item -Force $Lock }
Write-Host "[OK] stopped API:$ApiPort, WEB:$WebPort and cleared lock."
