# APPLY IN SHELL
# Kobong-Orchestrator — Monitor Logs v1.3  (generated: 2025-09-15 00:53:23 +09:00)
#requires -Version 7.0
param([string]$Root,[int]$LookbackMinutes=1440,[int]$Top=5,[switch]$Json,[string]$OutDir)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'

function Get-RepoRoot {
  if ($Root -and (Test-Path $Root)) { return (Resolve-Path $Root).Path }
  try { $r = git rev-parse --show-toplevel 2>$null; if ($r) { return $r } } catch {}
  return (Get-Location).Path
}
$RepoRoot = Get-RepoRoot
Set-Location $RepoRoot
if (-not $OutDir) { $OutDir = Join-Path $RepoRoot 'out/status' }
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

function Read-Jsonl($p){
  $res=@(); if (-not (Test-Path $p)) { return $res }
  Get-Content -Path $p -Encoding utf8 | ForEach-Object {
    if ([string]::IsNullOrWhiteSpace($_)) { return }
    try { $res += ($_ | ConvertFrom-Json) } catch {}
  }; return $res
}

$since      = (Get-Date).AddMinutes(-$LookbackMinutes)
$applyPath  = Join-Path $RepoRoot 'logs/apply-log.jsonl'
$apply      = @( Read-Jsonl $applyPath | Where-Object { $_.timestamp -and ([datetime]$_.timestamp) -ge $since } )

$applyTotal = $apply.Count
$ok         = @( $apply | Where-Object { $_.outcome -eq 'SUCCESS' } ).Count
$fail       = @( $apply | Where-Object { $_.outcome -eq 'FAILURE' } ).Count
$dry        = @( $apply | Where-Object { $_.outcome -eq 'DRYRUN'  } ).Count

$outStats   = @( $apply | Group-Object outcome )        | Sort-Object Count -Descending
$errStats   = @( $apply | Where-Object { $_.errorCode } | Group-Object errorCode ) | Sort-Object Count -Descending

Clear-Host
Write-Host ("KOBONG — LOG SUMMARY @ {0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')) -ForegroundColor Cyan
Write-Host ("Scope: last {0} min" -f $LookbackMinutes) -ForegroundColor DarkGray
Write-Host ""
Write-Host "[APPLY-LOG]" -ForegroundColor Yellow
Write-Host ("  · Total={0}  SUCCESS={1}  FAILURE={2}  DRYRUN={3}" -f $applyTotal,$ok,$fail,$dry)
if ($outStats.Count -gt 0) {
  Write-Host "  · Outcome Top:"
  $outStats | Select-Object -First $Top | ForEach-Object { Write-Host ("     - {0}: {1}" -f $_.Name,$_.Count) }
} else { Write-Host "  · Outcome Top: <none>" }
if ($errStats.Count -gt 0) {
  Write-Host "  · ErrorCode Top:"
  $errStats | Select-Object -First $Top | ForEach-Object { Write-Host ("     - {0}: {1}" -f $_.Name,$_.Count) }
} else { Write-Host "  · ErrorCode Top: <none>" }

if ($Json) {
  $ts  = Get-Date -Format 'yyyyMMdd-HHmmss'
  $obj = @{
    ts       = (Get-Date).ToString('o')
    rangeMin = $since.ToString('o')
    apply    = @{
      total     = $applyTotal
      outcomes  = @()
      topErrors = @()
    }
  }
  foreach($g in $outStats){ $obj.apply.outcomes  += @{ name=$g.Name; count=$g.Count } }
  foreach($g in ($errStats | Select-Object -First $Top)){ $obj.apply.topErrors += @{ code=$g.Name; count=$g.Count } }
  $tmp = Join-Path $OutDir "log_summary.$ts.json.tmp"
  $dst = Join-Path $OutDir "log_summary.$ts.json"
  $obj | ConvertTo-Json -Depth 6 | Out-File -FilePath $tmp -Encoding utf8 -NoNewline
  Move-Item -Force $tmp $dst
  Write-Host ("[Saved] {0}" -f $dst)
}