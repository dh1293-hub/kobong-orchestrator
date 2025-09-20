#requires -Version 7.0
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repo = 'D:\ChatGPT5_AI_Link\dosc\kobong-orchestrator'
Set-Location $repo
if (-not $env:KOBONG_API_URL)     { $env:KOBONG_API_URL     = 'http://127.0.0.1:8080' }
if (-not $env:KOBONG_HMAC_SECRET) { $env:KOBONG_HMAC_SECRET = Read-Host 'Enter KOBONG_HMAC_SECRET' }

Write-Host "== CLIENT SHELL ==" -ForegroundColor Green
Write-Host ("API_URL : {0}" -f $env:KOBONG_API_URL)
Write-Host ("SECRET : length={0}" -f (($env:KOBONG_HMAC_SECRET ?? '').Length))

try {
  $u = $env:KOBONG_API_URL.TrimEnd('/') + '/health'
  $r = Invoke-WebRequest $u -TimeoutSec 5
  Write-Host ("Health : {0} {1}" -f $r.StatusCode, ($r.Content.Substring(0,[Math]::Min(140,$r.Content.Length)) + '...'))
} catch {
  Write-Warning ("Health check failed: " + $_.Exception.Message)
}
