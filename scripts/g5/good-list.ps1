#requires -Version 7.0
param([string]$Root="D:\ChatGPT5_AI_Link\dosc\kobong-orchestrator")
Set-StrictMode -Version Latest; $ErrorActionPreference='Stop'
$RepoRoot=(Resolve-Path $Root).Path
$RollDir = Join-Path $RepoRoot '.rollbacks\good'
if (-not (Test-Path $RollDir)) { Write-Host "(no good slots)"; exit 0 }
Get-ChildItem $RollDir -Filter 'good-*.zip' | Sort-Object LastWriteTimeUtc -Descending |
  Select-Object @{n='When';e={$_.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss')}},Name,FullName,Length |
  Format-Table -AutoSize