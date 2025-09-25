# APPLY IN SHELL
# scripts/g5/run-watchdog.ps1 (v1.2 — hidden start, export cooldown, local API keepalive)
#requires -Version 7.0
param([int]$IntervalSec=30,[int]$StaleMinutes=2,[int]$ExportCooldownSec=120,[int]$ApiPort=5174)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'

function Get-RepoRoot { try { (git rev-parse --show-toplevel 2>$null) } catch { (Get-Location).Path } }
function Is-Alive([string]$regex){
  try { Get-CimInstance Win32_Process | Where-Object { ($_.Name -match 'pwsh|node') -and ($_.CommandLine -match $regex) } } catch {}
}
function Start-PwshHidden([string[]]$Args){ Start-Process pwsh -WindowStyle Hidden -ArgumentList $Args | Out-Null }
function Start-NodeHidden([string[]]$Args){
  $node = Get-Command node -ErrorAction SilentlyContinue
  if ($node) { Start-Process $node.Source -WindowStyle Hidden -ArgumentList $Args | Out-Null }
}

# export cooldown
$script:lastExport = (Get-Date).AddYears(-1)
function Bump-Exporter{
  if (((Get-Date) - $script:lastExport).TotalSeconds -lt $ExportCooldownSec) { return }
  $script:lastExport = Get-Date
  $export = Join-Path (Get-RepoRoot) 'scripts\g5\github-status-export.ps1'
  if (Test-Path $export) { Start-PwshHidden @('-NoLogo','-NoProfile','-ExecutionPolicy','Bypass','-File', $export) }
}

function Ensure-LocalApi{
  $root = Get-RepoRoot
  $api  = Join-Path $root 'scripts\g5\api\local-api-server.js'
  if (-not (Test-Path $api)) { return }
  if (-not (Is-Alive 'local-api-server\.js')) {
    $json = Join-Path $root 'public\data\gh-monitor.json'
    $node = Get-Command node -ErrorAction SilentlyContinue
    if ($node) {
      Start-Process $node.Source -WindowStyle Hidden -ArgumentList @($api, "$ApiPort", $json) -WorkingDirectory (Split-Path $api -Parent) | Out-Null
    }
  }
}

while($true){
  try{
    $root = Get-RepoRoot

    # 1) JSON freshness → export (쿨다운)
    $json = Join-Path $root 'public\data\gh-monitor.json'
    if (Test-Path $json){
      $age = (Get-Date) - (Get-Item $json).LastWriteTime
      if ($age.TotalMinutes -gt $StaleMinutes){ Bump-Exporter }
    } else { Bump-Exporter }

    # 2) monitor runner
    if (-not (Is-Alive 'run-github-monitor\.ps1')) {
      Start-PwshHidden @('-NoLogo','-NoProfile','-ExecutionPolicy','Bypass','-File', (Join-Path $root 'scripts\g5\run-github-monitor.ps1'), '-IntervalSec','45')
    }

    # 3) badge sync runner (webui\public 우선)
    $tp=@()
    $wpub = Join-Path $root 'webui\public'; if (Test-Path $wpub){ $tp += $wpub }
    $rpub = Join-Path $root 'public';       if (Test-Path $rpub){ $tp += $rpub }
    if (-not (Is-Alive 'run-public-badge-sync\.ps1')) {
      $args = @('-NoLogo','-NoProfile','-ExecutionPolicy','Bypass',
                '-File', (Join-Path $root 'scripts\g5\run-public-badge-sync.ps1'),
                '-IntervalSec','20','-SrcJson', (Join-Path $root 'public\data\gh-monitor.json'))
      foreach($p in @($tp)){ $args += @('-TargetPublicDirs', $p) }
      Start-PwshHidden $args
    }

    # 4) local api server (SSE/metrics)
    Ensure-LocalApi

  } catch {
    Write-Host "[WD] warn: $($_.Exception.Message)"
  }
  Start-Sleep -Seconds $IntervalSec
}