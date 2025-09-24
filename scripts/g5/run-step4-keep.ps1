# APPLY IN SHELL
# scripts/g5/run-step4-keep.ps1  (v1.1)
#requires -Version 7.0
param([switch]$ConfirmApply,[string]$Root)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

function Get-RepoRoot {
  if ($Root) { return (Resolve-Path $Root).Path }
  $rp = (git rev-parse --show-toplevel 2>$null)
  if (-not $rp) { return (Get-Location).Path }
  return $rp
}

$RepoRoot = Get-RepoRoot
$LogDir   = Join-Path $RepoRoot 'logs\run'
New-Item -ItemType Directory -Force -Path $LogDir | Out-Null
$ts  = Get-Date -Format 'yyyyMMdd-HHmmss'
$log = Join-Path $LogDir ("step4-$ts.log")

$pwsh   = (Get-Command pwsh).Source
$script = Join-Path $RepoRoot 'scripts\g5\synthetic-pr-workload.ps1'
if (-not (Test-Path $script)) {
  "[$(Get-Date -Format o)] MISSING: $script" | Tee-Object -FilePath $log
  Write-Host "== Step-4 종료코드: 64"
  Write-Host "== 로그: $log"
  try { Start-Process notepad.exe $log } catch {}
  return
}

$args  = @('-NoLogo','-NoProfile','-ExecutionPolicy','Bypass','-File', $script)
if ($ConfirmApply) { $args += '-ConfirmApply' }

& $pwsh @args *>&1 | Tee-Object -FilePath $log -Append
$code = $LASTEXITCODE
Copy-Item -Force $log (Join-Path $LogDir 'last.log')

Write-Host ""
Write-Host "== Step-4 종료코드: $code"
Write-Host "== 로그: $log"
Write-Host ""

try { Start-Process notepad.exe $log } catch {}