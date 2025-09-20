#requires -Version 7.0
param([int]$Port=8000,[string]$BindHost='127.0.0.1')
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'

$RepoRoot=Split-Path -Parent (Split-Path -Parent $PSCommandPath)
$Artifacts=Join-Path $RepoRoot 'artifacts'
$OutDir=Join-Path $Artifacts ("diag-" + (Get-Date).ToString('yyyyMMdd-HHmmss'))
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

# sys-report
$IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
$report=@{
  ts=(Get-Date).ToString('o')
  user=("$env:USERDOMAIN\$env:USERNAME")
  isAdmin=$IsAdmin
  os=(Get-CimInstance Win32_OperatingSystem | Select-Object -First 1 Caption,Version,BuildNumber)
  psver=$PSVersionTable.PSVersion.ToString()
  repo=$RepoRoot
  port=$Port
  bindHost=$BindHost
}
$report | ConvertTo-Json -Depth 5 | Out-File (Join-Path $OutDir 'report.json') -Encoding utf8 -NoNewline

# copy key files (no .env for safety)
$LogsDir=Join-Path $RepoRoot 'logs\serve'
if (Test-Path $LogsDir) { Copy-Item -Path (Join-Path $LogsDir '*') -Destination (Join-Path $OutDir 'logs') -Recurse -Force -ErrorAction SilentlyContinue }
$ApplyLog=Join-Path $RepoRoot 'logs\apply-log.jsonl'; if (Test-Path $ApplyLog) { Copy-Item $ApplyLog (Join-Path $OutDir 'apply-log.jsonl') -Force }
$ServerRoot=Join-Path $RepoRoot 'server'
$KoApp=Join-Path $ServerRoot 'ko_app'
if (Test-Path $KoApp) { Copy-Item -Path $KoApp -Destination (Join-Path $OutDir 'ko_app') -Recurse -Force -ErrorAction SilentlyContinue }
$Req=Join-Path $ServerRoot 'requirements.txt'; if (Test-Path $Req) { Copy-Item $Req (Join-Path $OutDir 'requirements.txt') -Force }
$ReqDev=Join-Path $ServerRoot 'requirements-dev.txt'; if (Test-Path $ReqDev) { Copy-Item $ReqDev (Join-Path $OutDir 'requirements-dev.txt') -Force }

# network & tasks snapshot
try { Get-NetTCPConnection -LocalPort $Port -State Listen | ConvertTo-Json -Depth 5 | Out-File (Join-Path $OutDir 'net-port.json') -Encoding utf8 -NoNewline } catch {}
try { Get-ScheduledTask -TaskName 'KO-ServeGuard' | Export-ScheduledTask | Out-File (Join-Path $OutDir 'scheduled-task.xml') -Encoding utf8 } catch {}
try {
  $rk='HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
  if (Test-Path $rk) {
    $val=(Get-ItemProperty -Path $rk -Name 'KO-ServeGuard' -ErrorAction SilentlyContinue).'KO-ServeGuard'
    if ($val) { $val | Out-File (Join-Path $OutDir 'autorun.txt') -Encoding utf8 -NoNewline }
  }
} catch {}

# health checks
$base="http://$BindHost`:$Port"
function SaveJson($obj,$name){ ($obj|ConvertTo-Json -Compress) | Out-File (Join-Path $OutDir $name) -Encoding utf8 -NoNewline }
try { SaveJson (Invoke-RestMethod -Uri "$base/healthz" -TimeoutSec 3) 'healthz.json' } catch {}
try { SaveJson (Invoke-RestMethod -Uri "$base/readyz"  -TimeoutSec 3) 'readyz.json' } catch {}
try { SaveJson (Invoke-RestMethod -Uri "$base/livez"   -TimeoutSec 3) 'livez.json' } catch {}
try { SaveJson (Invoke-RestMethod -Uri "$base/api/v1/ping" -TimeoutSec 3) 'ping.json' } catch {}

# openapi export (best-effort)
$Export = Join-Path $RepoRoot 'scripts\server\export-openapi.ps1'
if (Test-Path $Export) {
  try { & pwsh -NoLogo -NoProfile -ExecutionPolicy Bypass -File $Export -OutDir $OutDir | Out-Host } catch {}
}

# zip
$zip=Join-Path $Artifacts ("diag-" + (Get-Date).ToString('yyyyMMdd-HHmmss') + ".zip")
try { Compress-Archive -Path $OutDir -DestinationPath $zip -Force } catch {}
Write-Host ("ALL GREEN ✅ — diagnostics at {0}" -f $zip) -ForegroundColor Green