#requires -Version 7.0
param(
  [switch]$Trigger,
  [string]$Ref = 'main',
  [int]$Port = 8080,
  [int]$PollSec = 3,
  [string]$WorkflowName = 'Health Monitor',
  [string]$WorkflowPath = '.github/workflows/health-monitor.yml'
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'

function Get-LastRunId {
  param([string]$Ref,[string]$WorkflowName)
  gh run list --workflow $WorkflowName --branch $Ref --limit 1 --json databaseId --jq '.[0].databaseId' 2>$null
}

if ($Trigger) {
  gh workflow run $WorkflowPath --ref $Ref -f port=$Port | Out-Null
  Start-Sleep 2
}
$runId = Get-LastRunId -Ref $Ref -WorkflowName $WorkflowName
if (-not $runId) { Write-Host "No run found on $Ref for '$WorkflowName'" -ForegroundColor Yellow; exit 1 }
Write-Host "Watching runId=$runId (branch=$Ref, port=$Port, wf=$WorkflowName)" -ForegroundColor Cyan

$lastCount = 0
do {
  try {
    $status = gh run view $runId --json status,conclusion,updatedAt,url --jq '{status:.status,conclusion:.conclusion,updatedAt:.updatedAt,url:.url}'
    if ($status) { $o = $status | ConvertFrom-Json; Write-Host ("[{0}] {1}/{2}  {3}" -f $o.updatedAt,$o.status,$o.conclusion,$o.url) -ForegroundColor DarkGray }
  } catch { }

  $log = gh run view $runId --log
  $lines = $log -split "`r?`n"
  $new = $lines.Count - $lastCount
  if ($new -gt 0) {
    $lines[$lastCount..($lines.Count-1)] | ForEach-Object { Write-Host $_ }
    $lastCount = $lines.Count
  }

  $st = gh run view $runId --json status,conclusion --jq '{s:.status,c:.conclusion}'
  if ($st) {
    $o = $st | ConvertFrom-Json
    if ($o.s -ne 'in_progress' -and $o.s -ne 'queued') {
      Write-Host "Run finished: status=$($o.s) conclusion=$($o.c)" -ForegroundColor Green
      break
    }
  }
  Start-Sleep -Seconds $PollSec
} while ($true)