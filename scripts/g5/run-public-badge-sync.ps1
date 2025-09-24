# APPLY IN SHELL
# scripts/g5/run-public-badge-sync.ps1
#requires -Version 7.0
param([int]$IntervalSec=20,[string]$SrcJson,[string[]]$TargetPublicDirs=@())
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
function Sync-Oneshoot{
  if (-not (Test-Path $SrcJson)) { return }
  foreach($pd in @($TargetPublicDirs)){
    try {
      if (-not (Test-Path $pd)) { continue }
      $ddir = Join-Path $pd 'data'
      if (-not (Test-Path $ddir)) { New-Item -ItemType Directory -Force -Path $ddir | Out-Null }
      Copy-Item -Force $SrcJson (Join-Path $ddir (Split-Path $SrcJson -Leaf))
    } catch { $m=$_.Exception.Message; Write-Host "[WARN] sync failed for $pd : $m" }
  }
}
Sync-Oneshoot
while($true){ Start-Sleep -Seconds $IntervalSec; Sync-Oneshoot }