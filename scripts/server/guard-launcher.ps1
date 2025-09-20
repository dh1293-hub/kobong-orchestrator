#requires -Version 7.0
param([int]$Port=8000,[string]$BindHost='127.0.0.1',[string]$Root)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'

if ($Root -and $Root -ne '') { $RepoRoot = (Resolve-Path -LiteralPath $Root).Path } else { $RepoRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath) }
Set-Location $RepoRoot
$env:PYTHONPATH = Join-Path $RepoRoot 'server'

# Single-instance guard via Global Mutex (by port)
$mtxName = "Global\KO-ServeGuard-$Port"
$created=$false
$mtx = New-Object System.Threading.Mutex($false, $mtxName, [ref]$created)
try {
  if (-not $mtx.WaitOne(0)) { Write-Host "[skip] Guard already running (mutex $mtxName)"; exit 0 }
  $Pwsh = Join-Path $PSHOME 'pwsh.exe'
  & $Pwsh -NoLogo -NoProfile -ExecutionPolicy Bypass -File (Join-Path $RepoRoot 'scripts\server\serve-guard.ps1') -Port $Port -BindHost $BindHost
} finally {
  try { if ($mtx) { $mtx.ReleaseMutex() | Out-Null } } catch {}
}