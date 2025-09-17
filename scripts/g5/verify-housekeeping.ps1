#requires -Version 7.0
param(
  [string]$TaskName = "Kobong Weekly Housekeeping",
  [int]$TimeoutSec = 60,
  [switch]$RunNow,
  [string]$Root
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $RunNow = $true }

# Repo root
$RepoRoot = if ($Root) { (Resolve-Path -LiteralPath $Root).Path } else { (git rev-parse --show-toplevel 2>$null) ?? (Get-Location).Path }
$Log = Join-Path $RepoRoot 'logs/apply-log.jsonl'
New-Item -ItemType Directory -Force -Path (Split-Path $Log) | Out-Null
if (-not (Test-Path $Log)) { New-Item -ItemType File -Path $Log | Out-Null }

# Baseline
$before = Get-Content -LiteralPath $Log -Tail 1
if ($RunNow) { schtasks.exe /Run /TN $TaskName | Out-Null }

# Poll for new line
$deadline = (Get-Date).AddSeconds($TimeoutSec)
$newLine = $null
do {
  Write-Host -NoNewline "."; Start-Sleep 2
  $last = Get-Content -LiteralPath $Log -Tail 1
  if ($last -ne $before -and $last.Trim().Length -gt 0) { $newLine = $last; break }
} while ((Get-Date) -lt $deadline)

# Scheduler info
try {
  $sti = Get-ScheduledTaskInfo -TaskName $TaskName
  $state = (Get-ScheduledTask -TaskName $TaskName).State
  Write-Host ("[sched] State={0}  LastRun={1}  NextRun={2}" -f $state, $sti.LastRunTime, $sti.NextRunTime)
} catch {
  schtasks.exe /Query /TN $TaskName /V /FO LIST
}

# Log a verify record
$ok = [bool]$newLine
$rec = @{
  timestamp=(Get-Date).ToString('o'); level='INFO'; traceId=[guid]::NewGuid().ToString();
  module='verify-housekeeping'; action=($RunNow ? 'run+probe' : 'probe');
  outcome=($ok ? 'OK' : 'TIMEOUT'); durationMs=0; errorCode='';
  message=($ok ? 'new log line detected' : 'no new line within timeout')
} | ConvertTo-Json -Compress
Add-Content -Path $Log -Value $rec

if ($ok) {
  Write-Host "`n[OK] New log line:" -ForegroundColor Green
  $newLine
} else {
  Write-Warning "No new log entry within $TimeoutSec s. Task may still be running."
}
