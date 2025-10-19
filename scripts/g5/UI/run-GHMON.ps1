# APPLY IN SHELL
#requires -PSEdition Core
#requires -Version 7.0
param(
  [int]$Port = 5192,
  [string]$Root = (Split-Path -Parent $MyInvocation.MyCommand.Path),
  [switch]$ConfirmApply
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

# Paths
$repo = Resolve-Path $Root
$logs = Join-Path $repo 'logs'
New-Item -ItemType Directory -Force -Path $logs | Out-Null

# Node check/install (winget → MSI 폴백)
function Ensure-Node {
  try {
    $v = & node -v 2>$null
    if ($LASTEXITCODE -eq 0 -and $v) { Write-Host "Node found: $v"; return }
  } catch {}
  Write-Host "Node not found. Installing LTS via winget (or MSI fallback)..." -ForegroundColor Yellow
  try {
    winget install --id OpenJS.NodeJS.LTS -e --accept-package-agreements --accept-source-agreements
  } catch {
    $msi = Join-Path $env:TEMP "node-lts.msi"
    Invoke-WebRequest "https://nodejs.org/dist/latest-v20.x/node-v20.17.0-x64.msi" -OutFile $msi
    Start-Process msiexec.exe -ArgumentList "/i","$msi","/qn","/norestart" -Wait
    Remove-Item $msi -Force
  }
}

Ensure-Node

# Start server
$script = Join-Path $repo "GitHub-Monitoring/server/ghmon-mock-server.js"
if(-not (Test-Path $script)){ throw "Server script not found: $script" }

$proc = Start-Process -FilePath "node" -ArgumentList "`"$script`" --port $Port" -WorkingDirectory $repo -PassThru
$pidFile = Join-Path $logs "ghmon-mock.pid"
$proc.Id | Out-File -FilePath $pidFile -Encoding ascii -Force

# Wait for /health
$base = "http://localhost:$Port/api/ghmon"
$ok = $false
for($i=0; $i -lt 30; $i++){
  try {
    $r = Invoke-WebRequest -Uri "$base/health" -UseBasicParsing -TimeoutSec 2
    if($r.StatusCode -eq 200 -and ($r.Content | ConvertFrom-Json).ok){ $ok = $true; break }
  } catch {}
  Start-Sleep -Milliseconds 300
}
if(-not $ok){ Write-Warning "Health check failed, but continuing..." } else { Write-Host "GHMON /health OK" -ForegroundColor Green }

# Open UI
Start-Process "http://localhost:$Port/GitHub-Monitoring-Min.html"
Write-Host "Server PID: $($proc.Id). To stop: scripts/g5/ui/stop-GHMON.ps1" -ForegroundColor Cyan
