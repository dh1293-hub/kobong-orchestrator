#requires -Version 7.0
param(
  [int]$Port = 8080,
  [string]$BindAddress = '127.0.0.1',
  [switch]$Reload = $true,
  [switch]$Detach = $false,
  [switch]$OpenDocs = $false,
  [string]$Root
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'

function Get-RepoRoot([string]$InputRoot){
  if ($InputRoot) { return (Resolve-Path -LiteralPath $InputRoot).Path }
  $git = (& git rev-parse --show-toplevel 2>$null)
  if ($git) { return (Resolve-Path -LiteralPath $git).Path }
  return (Resolve-Path -LiteralPath (Get-Location).Path).Path
}

$RepoRoot = Get-RepoRoot $Root
$serveDir = Join-Path $RepoRoot 'logs\serve'
New-Item -ItemType Directory -Force -Path $serveDir | Out-Null
$ts = (Get-Date).ToString('yyyyMMdd-HHmmss')
$outLog = Join-Path $serveDir "run-dev-$ts.out.log"
$errLog = Join-Path $serveDir "run-dev-$ts.err.log"
$pidFile = Join-Path $serveDir "uvicorn-$Port.pid"

$python = Join-Path $RepoRoot 'server\.venv\Scripts\python.exe'
if (-not (Test-Path $python)) {
  $python = (Get-Command python -ErrorAction SilentlyContinue).Source
}
if (-not $python) { throw "python not found. Please install or create server\.venv." }

$args = @('-m','uvicorn','server.app:app','--host',$BindAddress,'--port',[string]$Port)
if ($Reload) { $args += '--reload' }

if ($Detach) {
  $p = Start-Process -FilePath $python -ArgumentList $args -WorkingDirectory $RepoRoot `
       -PassThru -RedirectStandardOutput $outLog -RedirectStandardError $errLog -WindowStyle Hidden
  $p.Id | Out-File -FilePath $pidFile -Encoding ascii -NoNewline
  Write-Host "[serve] uvicorn server.app:app on http://$BindAddress`:$Port (pid=$($p.Id))"
  Write-Host "[pid ] $pidFile"
  Write-Host "[logs] $outLog (stdout), $errLog (stderr)"
  Write-Host "[serve] detached"
} else {
  Write-Host "[serve] uvicorn server.app:app on http://$BindAddress`:$Port"
  & $python @args 1> $outLog 2> $errLog
}

# 옵션: Docs/Health 확인 및 자동 열기
try {
  Start-Sleep -Milliseconds 400
  $h = Invoke-WebRequest -UseBasicParsing -TimeoutSec 2 -Uri "http://$BindAddress`:$Port/health"
  if ($h.StatusCode -eq 200) { Write-Host "[OK] http://$BindAddress`:$Port/health → 200" }
  $d = Invoke-WebRequest -UseBasicParsing -TimeoutSec 2 -Uri "http://$BindAddress`:$Port/docs"
  if ($d.StatusCode -eq 200) { Write-Host "[OK] http://$BindAddress`:$Port/docs   → 200" }
} catch { "[info] endpoint check skipped (server starting?)" | Write-Host }

if ($OpenDocs) {
  try { Start-Sleep -Milliseconds 300; Start-Process "http://$BindAddress`:$Port/docs" | Out-Null } catch {}
}