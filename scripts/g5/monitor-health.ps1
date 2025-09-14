#requires -Version 7.0
param([int]$Port=8080,[int]$IntervalSec=15,[int]$MaxRestartsPerHour=12)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'

# repo root: scripts/g5 기준 두 단계 상위
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
Set-Location $repo

function Log([string]$msg,[string]$lvl='INFO'){
  $line = ('{0} [{1}] {2}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $lvl, $msg)
  Write-Host $line
  $logD = Join-Path $repo 'logs/monitor'
  New-Item -ItemType Directory -Force -Path $logD | Out-Null
  Add-Content -Path (Join-Path $logD ('monitor-'+(Get-Date -Format 'yyyyMMdd')+'.log')) -Value $line
}

function Get-Listeners([int]$p){
  Get-NetTCPConnection -LocalPort $p -State Listen -ErrorAction SilentlyContinue |
    Select-Object -ExpandProperty OwningProcess -Unique
}

function Start-HealthServer([int]$p){
  $node = (Get-Command node -ErrorAction Stop).Source
  $script = Join-Path $repo 'scripts/health-server.mjs'
  $logD = Join-Path $repo 'logs/serve'
  New-Item -ItemType Directory -Force -Path $logD | Out-Null
  $ts  = Get-Date -Format 'yyyyMMdd-HHmmss'
  $out = Join-Path $logD ("serve-{0}.out.log" -f $ts)
  $err = Join-Path $logD ("serve-{0}.err.log" -f $ts)
  $env:PORT = "$p"
  $proc = Start-Process -FilePath $node -ArgumentList "`"$script`"" -WorkingDirectory $repo `
          -NoNewWindow -PassThru -RedirectStandardOutput $out -RedirectStandardError $err
  Log ("start node {0} PORT={1} pid={2}" -f $script,$p,[int]$proc.Id)
}

# restart rate limit
$restartTimes = New-Object System.Collections.Generic.Queue[datetime]

while ($true) {
  $url = "http://localhost:$Port/health"
  & pwsh -NoProfile -File (Join-Path $PSScriptRoot 'health-probe.ps1') -Url $url
  $ok = $LASTEXITCODE -eq 0

  if (-not $ok) {
    # purge old restart timestamps (older than 1h)
    while ($restartTimes.Count -gt 0 -and (New-TimeSpan -Start $restartTimes.Peek() -End (Get-Date)).TotalMinutes -ge 60) {
      $null = $restartTimes.Dequeue()
    }
    if ($restartTimes.Count -ge $MaxRestartsPerHour) {
      Log ("restart skipped (rate-limit: {0}/h)" -f $MaxRestartsPerHour) 'WARN'
    } else {
      foreach ($pid in (Get-Listeners $Port)) { try { Stop-Process -Id $pid -Force -ErrorAction SilentlyContinue } catch {} }
      Start-HealthServer $Port
      $restartTimes.Enqueue((Get-Date))
      Start-Sleep -Seconds 2
      & pwsh -NoProfile -File (Join-Path $PSScriptRoot 'health-probe.ps1') -Url $url
      if ($LASTEXITCODE -eq 0) { Log 'heal OK after restart' } else { Log 'heal FAIL after restart' 'ERROR' }
    }
  }
  Start-Sleep -Seconds $IntervalSec
}