#requires -Version 7.0
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repo = 'D:\ChatGPT5_AI_Link\dosc\kobong-orchestrator'
Set-Location $repo
if (-not (Test-Path "$repo\scripts\server\run-dev.ps1")) {
  Write-Host "[ERROR] scripts\server\run-dev.ps1 not found" -ForegroundColor Red
  return
}
if (-not $env:KOBONG_API_URL)     { $env:KOBONG_API_URL     = 'http://127.0.0.1:8080' }
if (-not $env:KOBONG_HMAC_SECRET) { $env:KOBONG_HMAC_SECRET = Read-Host 'Enter KOBONG_HMAC_SECRET' }

Write-Host "== SERVER START ==" -ForegroundColor Cyan
Write-Host ("API_URL : {0}" -f $env:KOBONG_API_URL)
Write-Host ("SECRET : length={0}" -f (($env:KOBONG_HMAC_SECRET ?? '').Length))
& "$repo\scripts\server\run-dev.ps1"
