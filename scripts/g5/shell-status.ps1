#requires -Version 7.0
param([switch]$ConfirmApply,[string]$Root)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

# APPLY IN SHELL
# Shell-Status v1 — PS/도구 버전·경로·스크립트 존재 확인 (generated: 2025-09-15 01:15:47 +09:00)
#requires -Version 7.0
param([string]$Root)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
function Get-RepoRoot {
  if ($Root -and (Test-Path $Root)) { return (Resolve-Path $Root).Path }
  try { $r = git rev-parse --show-toplevel 2>$null; if ($r) { return $r } } catch {}
  return (Get-Location).Path
}
$Repo = Get-RepoRoot
Set-Location $Repo

Write-Host ("SHELL STATUS @ {0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')) -ForegroundColor Cyan
Write-Host ("Repo : {0}" -f $Repo) -ForegroundColor DarkGray
Write-Host ""

# PowerShell info
$psv = $PSVersionTable
Write-Host ("PS Version  : {0}" -f $psv.PSVersion)
Write-Host ("PS Edition  : {0}" -f $psv.PSEdition)
Write-Host ("PS Root     : {0}" -f $PSHOME)
Write-Host ""

# Tool versions (best-effort)
function Try-Ver($n,$cmd,$args){ try { $v = & $cmd $args 2>$null; Write-Host ("{0,-12}: {1}" -f $n,($v -split "`n" | Select-Object -First 1)) } catch { Write-Host ("{0,-12}: <not found>" -f $n) } }
Try-Ver "git" "git" "--version"
Try-Ver "gh"  "gh"  "--version"
Try-Ver "node" "node" "--version"
Try-Ver "npm"  "npm"  "--version"
Try-Ver "pnpm" "pnpm" "--version"

Write-Host ""
# Scripts presence
$paths = @(
  "scripts/g5/monitor-status.ps1",
  "scripts/g5/monitor-logs.ps1",
  "scripts/view-ci-summary.ps1"
)
foreach($p in $paths){
  $exists = Test-Path (Join-Path $Repo $p)
  Write-Host ("{0,-36} : {1}" -f $p, (if($exists){'OK'}else{'MISSING'}))
}