#requires -Version 7.0
param(
  [int]$Rounds = 1,
  [switch]$CreateReleasePage,
  [int]$BadgeTimeoutSec = 420,
  [int]$WatchIntervalSec = 6,
  [switch]$ContinueOnError,
  [switch]$ConfirmApply,
  [string]$Root
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

# RepoRoot & Train Lock
$RepoRoot = if ($Root) { $Root } else { (git rev-parse --show-toplevel 2>$null) ?? (Get-Location).Path }
Set-Location $RepoRoot
$TrainLock = Join-Path $RepoRoot '.gpt5.train.lock'
if (Test-Path $TrainLock) { Write-Error 'CONFLICT: .gpt5.train.lock exists.'; exit 11 }
"locked $(Get-Date -Format o)" | Out-File $TrainLock -Encoding utf8 -NoNewline

# Logger
$sw=[Diagnostics.Stopwatch]::StartNew()
$trace=[guid]::NewGuid().ToString()
function Log($level,$action,$msg,$code=''){
  $rec=@{
    timestamp=(Get-Date).ToString('o');level=$level;traceId=$trace;module='release-train';action=$action;
    inputHash='';outcome=$level;durationMs=$sw.ElapsedMilliseconds;errorCode=$code;message=$msg
  } | ConvertTo-Json -Compress
  $log=Join-Path $RepoRoot 'logs/apply-log.jsonl'
  New-Item -ItemType Directory -Force -Path (Split-Path $log) | Out-Null
  Add-Content -Path $log -Value $rec
}

function Find-ChangelogPr([string]$Tag){
  $head = "release/changelog-$Tag"
  try {
    $raw = gh pr list --state open  --limit 50 --json number,headRefName 2>$null
    $open = if ($raw) { $raw | ConvertFrom-Json } else { @() }
    $hit  = $open | Where-Object { $_.headRefName -eq $head } | Select-Object -First 1
    if ($hit) { return [int]$hit.number }
    $raw2 = gh pr list --state closed --limit 50 --json number,headRefName 2>$null
    $closed = if ($raw2) { $raw2 | ConvertFrom-Json } else { @() }
    $hit2 = $closed | Where-Object { $_.headRefName -eq $head } | Select-Object -First 1
    if ($hit2) { return [int]$hit2.number }
  } catch {}
  return $null
}

try {
  for ($i=1; $i -le $Rounds; $i++) {
    Log 'INFO' 'round-start' ("Round {0}/{1}" -f $i,$Rounds)

    # 0) 최신화
    git fetch origin main --prune | Out-Null
    git switch main | Out-Null
    git pull --ff-only | Out-Null

    # 1) 새 패치 릴리스(태그+changelog 브랜치/PR)
    try {
      if ($ConfirmApply) { pwsh -File .\scripts\g5\release-vpatch.safe.ps1 -ConfirmApply } else { pwsh -File .\scripts\g5\release-vpatch.safe.ps1 }
    } catch {
      Log 'ERROR' 'release-vpatch' $_.Exception.Message 'Code-013'
      if (-not $ContinueOnError) { throw }
      continue
    }

    # 2) 최신 태그 확인
    git fetch --tags --prune | Out-Null
    $tag = (git describe --tags --abbrev=0)
    if (-not $tag) { Log 'ERROR' 'detect-tag' 'No tag detected after release.' 'Code-013'; if (-not $ContinueOnError) { throw } else { continue } }
    Log 'INFO' 'detect-tag' ("new tag={0}" -f $tag)

    # 3) CHANGELOG PR 찾기(있으면)
    $pr = Find-ChangelogPr $tag
    if ($pr) { Log 'INFO' 'detect-pr' ("changelog PR=#{0}" -f $pr) } else { Log 'WARN' 'detect-pr' ("no changelog PR for {0} (maybe auto-merged or delayed)" -f $tag) }

    # 4) 안정화(배지 PR/README 반영 대기+머지+검증+(옵션)릴리스 페이지)
    try {
      $args = @('-Tag', $tag, '-BadgeTimeoutSec', $BadgeTimeoutSec, '-WatchIntervalSec', $WatchIntervalSec)
      if ($pr) { $args += @('-ChangelogPr', $pr) }
      if ($CreateReleasePage) { $args += '-CreateReleasePage' }
      if ($ConfirmApply) { $args += '-ConfirmApply' }
      pwsh -File .\scripts\g5\release-stabilize.ps1 @args
    } catch {
      Log 'ERROR' 'stabilize' $_.Exception.Message 'Code-013'
      if (-not $ContinueOnError) { throw }
    }

    Log 'INFO' 'round-done' ("Round {0} finished → {1}" -f $i,$tag)
  }

  Log 'INFO' 'train-done' 'All rounds completed.'
  "[DONE] Release train completed (Rounds=$Rounds)"
} catch {
  Log 'ERROR' 'train-fail' $_.Exception.Message 'Code-013'
  throw
} finally {
  Remove-Item -Force $TrainLock -ErrorAction SilentlyContinue
}
