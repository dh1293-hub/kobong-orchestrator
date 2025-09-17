#requires -Version 7.0
param(
  [Parameter(Mandatory=$true)][int]$Pr,
  [string]$Root,
  [string]$Base='origin/main',
  [int]$FetchTimeoutSec=90,
  [switch]$ConfirmApply
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

function Resolve-RepoRoot([string]$Root){
  if (-not [string]::IsNullOrWhiteSpace($Root)) { return (Resolve-Path $Root).Path }
  $top = (& git rev-parse --show-toplevel 2>$null); if ($top) { return $top }
  return (Get-Location).Path
}
$RepoRoot = Resolve-RepoRoot -Root $Root
Set-Location $RepoRoot

$LockFile = Join-Path $RepoRoot (".gpt5.lock.rebase-{0}" -f $Pr)
if (Test-Path $LockFile) { Write-Error "CONFLICT: $([IO.Path]::GetFileName($LockFile)) exists."; exit 11 }
"locked $(Get-Date -Format o)" | Out-File $LockFile -NoNewline

$sw=[Diagnostics.Stopwatch]::StartNew()
$trace=[guid]::NewGuid().ToString()
$log=Join-Path $RepoRoot 'logs\apply-log.jsonl'
New-Item -ItemType Directory -Force -Path (Split-Path $log) | Out-Null
function LogRec($lvl,$outcome,$msg,$err=''){ $r=@{timestamp=(Get-Date).ToString('o');level=$lvl;traceId=$trace;module='pr';action='rebase-onto-main';inputHash=("PR#{0}" -f $Pr);outcome=$outcome;durationMs=$sw.ElapsedMilliseconds;errorCode=$err;message=$msg} | ConvertTo-Json -Compress; Add-Content -Path $log -Value $r }

try {
  $env:GIT_PAGER=''; $env:LESS='-FRX'; $env:GIT_TERMINAL_PROMPT='0'
  $env:GH_PAGER='';  $env:GH_PROMPT_DISABLED='1'; $env:GH_NO_UPDATE_NOTIFIER='1'

  # PR 메타 조회
  $remote = git remote get-url origin
  if ($remote -notmatch 'github\.com[:/](.+?)/(.+?)(?:\.git)?$') { throw "Cannot parse origin URL: $remote" }
  $owner=$Matches[1]; $repo=$Matches[2]
  $prJson = gh api ("repos/{0}/{1}/pulls/{2}" -f $owner,$repo,$Pr) 2>$null
  if (-not $prJson) { throw "PR#$Pr not found" }
  $prObj = $prJson | ConvertFrom-Json
  $headRef = $prObj.head.ref

  # 현재 브랜치/더티상태 체크 → 자동 stash
  $origBranch = (git rev-parse --abbrev-ref HEAD).Trim()
  $hadDirty = -not [string]::IsNullOrWhiteSpace((git status --porcelain))
  $stashRef = $null
  if ($hadDirty) {
    $msg = "gpt5-temp-stash-$trace"
    git stash push -u -m $msg | Out-Null
    $stashRef = (git stash list --pretty="%gd %gs" | Select-String $msg | ForEach-Object { ($_.ToString() -split '\s+')[0] } | Select-Object -First 1)
    if (-not $stashRef) { throw "Stash expected but not found." }
  }

  # 최신 가져오기 (조용히)
  $fetchTool = Join-Path $RepoRoot 'scripts\g5\fetch-quiet.ps1'
  if (Test-Path $fetchTool) {
    pwsh -File $fetchTool -Root $RepoRoot -TimeoutSec $FetchTimeoutSec -Prune -Tags | Out-Null
  } else {
    git fetch origin --prune --tags --no-recurse-submodules --filter=blob:none | Out-Null
  }

  # PR 브랜치 로컬 확보 + 체크아웃
  $spec = "$($headRef):$($headRef)"
  git fetch origin $spec | Out-Null
  git switch $headRef | Out-Null

  # 리베이스 → 실패 시 머지 폴백
  $rebaseOk = $true
  try { git rebase $Base | Out-Null } catch { $rebaseOk = $false; git rebase --abort 2>$null | Out-Null }

  if (-not $rebaseOk) {
    try { git merge --no-edit $Base | Out-Null } catch { git merge --abort 2>$null | Out-Null; LogRec 'ERROR' 'FAILURE' "merge conflict; manual resolution required on $headRef" 'MERGE_CONFLICT'; throw "Merge conflict on $headRef" }
  }

  # 푸시
  if ($rebaseOk) { git push --force-with-lease origin $headRef | Out-Null } else { git push origin $headRef | Out-Null }

  # 원래 브랜치 복귀 + stash pop (있으면)
  git switch $origBranch | Out-Null
  if ($stashRef) {
    try { git stash pop $stashRef | Out-Null } catch { LogRec 'ERROR' 'PARTIAL' "stash pop had conflicts; stash kept as $stashRef" 'STASH_CONFLICT' }
  }

  LogRec 'INFO' 'OK' ("updated {0} onto {1} via {2}" -f $headRef,$Base, ($(if($rebaseOk){'rebase'}else{'merge'})))
  exit 0
}
catch {
  LogRec 'ERROR' 'FAILURE' $_.Exception.Message $_.Exception.Message
  exit 13
}
finally {
  Remove-Item -Force $LockFile -ErrorAction SilentlyContinue
}
