# APPLY IN SHELL
# kobong-run.ps1 — wrapper to guard-run (generated)
#requires -Version 7.0
param([Parameter(Mandatory)][string]$Script,[string[]]$Args,[string]$Root)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'

function Get-RepoRoot{
  if($Root -and (Test-Path $Root)){ return (Resolve-Path $Root).Path }
  try{ $r=git rev-parse --show-toplevel 2>$null; if($r){return $r} }catch{}
  return (Get-Location).Path
}
$Repo = Get-RepoRoot
Set-Location $Repo
$guard = Join-Path $Repo 'scripts/g5/guard-run.ps1'
if(-not (Test-Path $guard)){ Write-Host "[FAIL] guard-run.ps1 not found" -ForegroundColor Red; return }
& $guard -Script $Script -Args $Args
return