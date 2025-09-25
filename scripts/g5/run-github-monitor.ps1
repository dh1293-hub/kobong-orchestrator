# APPLY IN SHELL
# scripts/g5/run-github-monitor.ps1  (v0.2.1 — robust catch, single-quoted heredoc)
#requires -Version 7.0
param([int]$IntervalSec=45)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'

$root  = (git rev-parse --show-toplevel 2>$null); if (-not $root) { $root = (Get-Location).Path }
$export= Join-Path $root 'scripts\g5\github-status-export.ps1'
if (-not (Test-Path $export)) { throw "exporter missing: $export" }

while ($true) {
  try {
    & pwsh -NoLogo -NoProfile -ExecutionPolicy Bypass -File $export
  }
  catch {
    $msg = $_.Exception.Message
    Write-Host "[WARN] export failed: $msg"
  }
  Start-Sleep -Seconds $IntervalSec
}