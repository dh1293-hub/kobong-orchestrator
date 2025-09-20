#requires -Version 7.0
param(
  [int]$Port=8000,
  [string]$BindHost='127.0.0.1',
  [int]$MaxRestarts=10,
  [int]$ProbeSec=5
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$RepoRoot = (git rev-parse --show-toplevel 2>$null); if (-not $RepoRoot) { $RepoRoot = (Get-Location).Path }
$ScriptsDir = Join-Path $RepoRoot 'scripts\server'
$RunProd = Join-Path $ScriptsDir 'run-prod.ps1'
if (-not (Test-Path $RunProd)) { throw "run-prod.ps1 not found: $RunProd" }
$restarts=0
while ($restarts -le $MaxRestarts) {
  Write-Host "[guard] start cycle=$restarts"
  $p = Start-Process -FilePath "pwsh" -ArgumentList @("-NoLogo","-NoProfile","-File",$RunProd,"-Port",$Port,"-BindHost",$BindHost) -PassThru -WorkingDirectory $RepoRoot
  Start-Sleep -Seconds 2
  $ok=$false
  for ($i=0; $i -lt 30; $i++) {
    try { $r=Invoke-RestMethod -Uri "http://$BindHost`:$Port/readyz" -TimeoutSec 2; if ($r.status -eq 'ok') { $ok=$true; break } } catch { }
    Start-Sleep -Seconds 1
  }
  if (-not $ok) { Write-Host "[guard] boot failed; killing pid=$($p.Id)"; $p | Stop-Process -Force; $restarts++; continue }
  while (-not $p.HasExited) {
    Start-Sleep -Seconds $ProbeSec
    try { $live=Invoke-RestMethod -Uri "http://$BindHost`:$Port/livez" -TimeoutSec 2; if ($live.status -ne 'ok') { throw "bad livez" } }
    catch { Write-Host "[guard] livez fail → restart"; try { $p | Stop-Process -Force } catch { }; break }
  }
  $restarts++
}
Write-Host "[guard] max restarts reached. exiting." -ForegroundColor Yellow
exit 12