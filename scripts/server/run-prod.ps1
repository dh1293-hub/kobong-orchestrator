#requires -Version 7.0
param(
  [int]$Port=8000,
  [string]$BindHost='127.0.0.1',
  [int]$Workers=0,
  [switch]$Reload,
  [int]$TimeoutStartSec=20
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$RepoRoot = (git rev-parse --show-toplevel 2>$null); if (-not $RepoRoot) { $RepoRoot = (Get-Location).Path }
$ServerRoot = Join-Path $RepoRoot 'server'
$Py = Join-Path $ServerRoot '.venv\Scripts\python.exe'
if (-not (Test-Path $Py)) { throw "Python venv not found: $Py" }
$logs = Join-Path $RepoRoot 'logs\serve'
New-Item -ItemType Directory -Force -Path $logs | Out-Null
$ts=(Get-Date).ToString('yyyyMMdd-HHmmss')
$outLog = Join-Path $logs ("prod-${ts}.out.log")
$errLog = Join-Path $logs ("prod-${ts}.err.log")
if (-not $env:KOBONG_ENV -or $env:KOBONG_ENV -eq '') { $env:KOBONG_ENV='prod' }
$env:PYTHONPATH = $ServerRoot
$argv = @('-m','uvicorn','ko_app.main:app','--host',$BindHost,'--port',$Port,'--log-level','info')
# add env-file if present (idempotent)
$envFile = Join-Path $ServerRoot '.env'
if (Test-Path $envFile -and ($argv -notcontains '--env-file')) { $argv += @('--env-file', $envFile) }
if ($Workers -gt 0) { $argv += @('--workers', $Workers) }
if ($Reload) { $argv += '--reload' }
# append log config (idempotent)
if ($argv -notcontains '--log-config') {
  $argv += @('--log-config', (Join-Path $ServerRoot 'logging.json'))
}
# select log config (v2)
$fmt = (($env:KOBONG_LOG_FORMAT) ?? 'logfmt').ToLower()
# remove any existing --log-config pairs
$argv2 = @()
for ($i2=0; $i2 -lt $argv.Count; $i2++) {
  if ($argv[$i2] -eq '--log-config') { $i2++; continue }
  $argv2 += $argv[$i2]
}
$argv = $argv2
$cfg = $null
if ($fmt -eq 'json') { $cfg = Join-Path $ServerRoot 'logging.json.json' }
elseif ($fmt -eq 'none') { $cfg = $null }
else { $cfg = Join-Path $ServerRoot 'logging.logfmt.json' }
if ($cfg) { $argv += @('--log-config', $cfg) }
$proc = Start-Process -FilePath $Py -ArgumentList $argv -WorkingDirectory $ServerRoot -PassThru -NoNewWindow `
  -RedirectStandardOutput $outLog -RedirectStandardError $errLog
"$($proc.Id)" | Out-File (Join-Path $logs 'last-prod.pid') -Encoding utf8
# 부팅 헬스 확인
$ok=$false
for ($i=0; $i -lt $TimeoutStartSec; $i++) {
  try { $r=Invoke-RestMethod -Uri "http://$BindHost`:$Port/healthz" -TimeoutSec 2; if ($r.status -eq 'ok') { $ok=$true; break } } catch { }
  Start-Sleep -Seconds 1
}
if ($ok) { Write-Host "[health] OK http://$BindHost`:$Port/healthz" -ForegroundColor Green } else { Write-Host "[health] not ready" -ForegroundColor Yellow }
# 로그 tail — 백그라운드 유지
Get-Content -Path $outLog -Wait -Encoding utf8