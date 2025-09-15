# APPLY IN SHELL
# Run-Kobong-Logger v1 — kobong_logger_cli 존재 확인/헬프 (generated: 2025-09-15 01:15:47 +09:00)
#requires -Version 7.0
param()
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
if (Get-Command kobong_logger_cli -ErrorAction SilentlyContinue) {
  kobong_logger_cli --help
} else {
  Write-Host "[INFO] 'kobong_logger_cli' not found on PATH."
  Write-Host "      Please install or ensure it is reachable, then re-run."
}