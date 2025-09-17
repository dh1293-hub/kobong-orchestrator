#requires -Version 7.0
param(
  [Parameter(Mandatory=$true)][int]$Pr,
  [string]$Root,
  [int]$TimeoutSec = 600,
  [int]$PollSec = 6,
  [switch]$ConfirmApply
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

function Resolve-RepoRoot {
  param([string]$Root)
  if (-not [string]::IsNullOrWhiteSpace($Root)) { return (Resolve-Path $Root).Path }
  $top = (& git rev-parse --show-toplevel 2>$null)
  if ($top) { return $top }
  return (Get-Location).Path
}
$RepoRoot = Resolve-RepoRoot -Root $Root
Set-Location $RepoRoot

$LockFile = Join-Path $RepoRoot (".gpt5.pr-{0}.lock" -f $Pr)
if (Test-Path $LockFile) { Write-Error "CONFLICT: $([IO.Path]::GetFileName($LockFile)) exists."; exit 11 }
"locked $(Get-Date -Format o)" | Out-File $LockFile -NoNewline

$sw=[Diagnostics.Stopwatch]::StartNew()
$trace=[guid]::NewGuid().ToString()
$log = Join-Path $RepoRoot 'logs\apply-log.jsonl'
New-Item -ItemType Directory -Force -Path (Split-Path $log) | Out-Null

$env:GIT_PAGER='' ; $env:LESS='-FRX' ; $env:GIT_TERMINAL_PROMPT='0'
$env:GH_PAGER=''  ; $env:GH_PROMPT_DISABLED='1' ; $env:GH_NO_UPDATE_NOTIFIER='1'

function Write-Rec([string]$Outcome,[string]$Msg,[string]$Level='INFO'){
  $rec=@{timestamp=(Get-Date).ToString('o');level=$Level;traceId=$trace;module='pr';action='automerge-watch';inputHash=("PR#{0}" -f $Pr);outcome=$Outcome;durationMs=$sw.ElapsedMilliseconds;errorCode='';message=$Msg} | ConvertTo-Json -Compress
  Add-Content -Path $log -Value $rec
}

try {
  $remote = git remote get-url origin
  if ($remote -match 'github\.com[:/](.+?)/(.+?)(?:\.git)?$') { $owner=$Matches[1]; $repo=$Matches[2] } else { throw "Cannot parse origin URL: $remote" }

  try { gh pr merge $Pr --auto --squash 2>$null | Out-Null } catch { Write-Warning "gh pr merge --auto failed: $($_.Exception.Message)" }

  $deadline = (Get-Date).AddSeconds($TimeoutSec)
  do {
    $prJson = gh api ("repos/{0}/{1}/pulls/{2}" -f $owner,$repo,$Pr) 2>$null
    if (-not $prJson) { throw "PR#$Pr not found via API." }
    $pr = $prJson | ConvertFrom-Json
    $state = $pr.state
    $merged = [bool]$pr.merged
    $mergeable_state = $pr.mergeable_state
    $sha = $pr.head.sha
    $headRef = $pr.head.ref   # ← FIX: .@{ref} → .ref

    $checksState = 'unknown'
    try {
      $st = gh api ("repos/{0}/{1}/commits/{2}/status" -f $owner,$repo,$sha) 2>$null | ConvertFrom-Json
      if ($st) { $checksState = $st.state }
    } catch { $checksState = 'unknown' }

    Write-Host ("[watch] PR#{0} state={1} merged={2} mergeable_state={3} checks={4} ref={5}" -f $Pr,$state,$merged,$mergeable_state,$checksState,$headRef)

    if ($merged) { Write-Rec 'OK' ("merged=True blocked=False"); exit 0 }
    if ($state -eq 'closed' -and -not $merged) { Write-Rec 'FAILURE' ("closed without merge (mergeable_state=$mergeable_state)"); exit 11 }
    if ((Get-Date) -ge $deadline) { Write-Rec 'PARTIAL' ("timeout after ${TimeoutSec}s (mergeable_state=$mergeable_state; checks=$checksState)"); exit 12 }

    Start-Sleep -Seconds $PollSec
  } while ($true)
}
catch {
  $err=$_.Exception.Message; $stk=$_.ScriptStackTrace
  $rec=@{timestamp=(Get-Date).ToString('o');level='ERROR';traceId=$trace;module='pr';action='automerge-watch';inputHash=("PR#{0}" -f $Pr);outcome='FAILURE';durationMs=$sw.ElapsedMilliseconds;errorCode=$err;message=$stk} | ConvertTo-Json -Compress
  Add-Content -Path $log -Value $rec
  exit 13
}
finally {
  Remove-Item -Force $LockFile -ErrorAction SilentlyContinue
}
