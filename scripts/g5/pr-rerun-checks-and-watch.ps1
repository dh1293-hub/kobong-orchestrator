#requires -Version 7.0
param(
  [Parameter(Mandatory=$true)][int]$Pr,
  [string]$Root,
  [int]$WatchTimeoutSec=300,
  [int]$PollSec=6,
  [switch]$ConfirmApply
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply=$true }

function Resolve-RepoRoot([string]$Root){
  if ($Root) { return (Resolve-Path $Root).Path }
  $t = (& git rev-parse --show-toplevel 2>$null); if ($t){ return $t }
  (Get-Location).Path
}
$RepoRoot = Resolve-RepoRoot -Root $Root
Set-Location $RepoRoot

$LockFile = Join-Path $RepoRoot (".gpt5.lock.rerun-{0}" -f $Pr)
if (Test-Path $LockFile) { Write-Error "CONFLICT: $([IO.Path]::GetFileName($LockFile)) exists."; exit 11 }
"locked $(Get-Date -Format o)" | Out-File $LockFile -NoNewline

$sw=[Diagnostics.Stopwatch]::StartNew()
$trace=[guid]::NewGuid().ToString()
$log = Join-Path $RepoRoot 'logs\apply-log.jsonl'
New-Item -ItemType Directory -Force -Path (Split-Path $log) | Out-Null
function rec($lvl,$outcome,$msg,$err=''){ $r=@{timestamp=(Get-Date).ToString('o');level=$lvl;traceId=$trace;module='pr';action='rerun-checks';inputHash=("PR#{0}" -f $Pr);outcome=$outcome;durationMs=$sw.ElapsedMilliseconds;errorCode=$err;message=$msg}|ConvertTo-Json -Compress; Add-Content -Path $log -Value $r }

try {
  $remote = git remote get-url origin
  if ($remote -notmatch 'github\.com[:/](.+?)/(.+?)(?:\.git)?$') { throw "Cannot parse origin URL: $remote" }
  $owner=$Matches[1]; $repo=$Matches[2]

  $prObj = (gh api ("repos/{0}/{1}/pulls/{2}" -f $owner,$repo,$Pr) | ConvertFrom-Json)
  $ref   = $prObj.head.ref
  $sha   = $prObj.head.sha

  # 해당 SHA의 워크플로우 런 조회
  $runs = gh api ("repos/{0}/{1}/actions/runs?branch={2}&per_page=50" -f $owner,$repo,$ref) | ConvertFrom-Json
  $target = @($runs.workflow_runs | Where-Object { $_.head_sha -eq $sha })
  $count = 0
  foreach($r in $target){
    try {
      gh run rerun $r.id 2>$null | Out-Null
      $count++
    } catch {}
  }
  rec 'INFO' 'OK' ("rerun requested for {0} runs on ref={1} sha={2}" -f $count,$ref,$sha)

  # 이어서 감시
  pwsh -File (Join-Path $RepoRoot 'scripts\g5\pr-automerge-watch.ps1') -Pr $Pr -TimeoutSec $WatchTimeoutSec -PollSec $PollSec -ConfirmApply
}
catch {
  rec 'ERROR' 'FAILURE' $_.Exception.Message $_.Exception.Message
  exit 13
}
finally {
  Remove-Item -Force $LockFile -ErrorAction SilentlyContinue
}
