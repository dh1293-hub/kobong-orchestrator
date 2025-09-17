# APPLY IN SHELL
#requires -Version 7.0
param([switch]$ConfirmApply,[string]$Root='.')
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

$RepoRoot=(Resolve-Path $Root).Path
Set-Location $RepoRoot

# --- lock ---
$LockFile = Join-Path $RepoRoot ".gpt5.lock"
if (Test-Path $LockFile) { Remove-Item -Force $LockFile }
"locked $(Get-Date -Format o)" | Out-File $LockFile -NoNewline
$sw=[Diagnostics.Stopwatch]::StartNew()
$trace=[guid]::NewGuid().ToString()
function Write-StdLog {
  param([string]$Module,[string]$Action,[string]$Level='INFO',[string]$Message='',[string]$ErrorCode='',[string]$Outcome='',[string]$InputHash='')
  $rec=@{timestamp=(Get-Date).ToString('o');level=$Level;traceId=$trace;module=$Module;action=$Action;inputHash=$InputHash;outcome=$Outcome;durationMs=$sw.ElapsedMilliseconds;errorCode=$ErrorCode;message=$Message} | ConvertTo-Json -Compress
  $log=Join-Path $RepoRoot 'logs/apply-log.jsonl'; New-Item -ItemType Directory -Force -Path (Split-Path $log) | Out-Null; Add-Content $log $rec
}
try {
  git fetch origin --tags | Out-Null
  $baseSha=(git rev-parse origin/main).Trim(); if (-not $baseSha) { throw "resolve origin/main failed" }

  $lastTag = (git tag --list "v*" --sort=-v:refname | Select-Object -First 1)
  if (-not $lastTag) { throw "no v* tag" }
  if ($lastTag -notmatch '^v(\d+)\.(\d+)\.(\d+)$') { throw "bad tag: $lastTag" }
  $maj=[int]$Matches[1];$min=[int]$Matches[2];$pat=[int]$Matches[3]+1
  $newTag="v$maj.$min.$pat"
  Write-Host "== Plan =="; Write-Host "• last tag : $lastTag"; Write-Host "• new tag  : $newTag"; Write-Host "• tag base : origin/main @$baseSha"

  if (git rev-parse -q --verify "refs/tags/$newTag" 2>$null) { throw "exists: $newTag" }
  if ($ConfirmApply) {
    git tag -a $newTag $baseSha -m "chore(release): $newTag"
    git push origin $newTag
  } else {
    Write-Host "[DRY-RUN] would: tag $newTag at $baseSha and push"
  }

  # CHANGELOG backfill PR
  $branch="release/changelog-$newTag"
  if ($ConfirmApply) {
    git switch -C $branch origin/main | Out-Null
    $ch=Join-Path $RepoRoot 'CHANGELOG.md'
    if (Test-Path $ch) {
      $today=(Get-Date -Format 'yyyy-MM-dd')
      $old=Get-Content $ch -Raw -Encoding utf8
      $entry="## $newTag ($today)`n- Maintenance: automated patch release.`n`n"
      $tmp="$ch.tmp"; ($entry+$old) | Out-File $tmp -Encoding utf8 -NoNewline
      Move-Item -Force $tmp $ch
      git add CHANGELOG.md
      git commit -m "chore(release): $newTag changelog"
      git push -u origin $branch
      $title="chore(release): $newTag changelog"
      $body ="Automated changelog backfill for $newTag."
      $null = gh pr create -H $branch -B main -t $title -b $body 2>$null
      # GH CLI 호환 가드: 번호 재조회 → 폴백 API
      $prNum = $null
      try { $prNum = gh pr list --head $branch --limit 1 --json "number" --jq ".[0].number" 2>$null } catch {}
      if (-not $prNum) {
        try { $prNum = gh api repos/:owner/:repo/pulls -f head=$branch -f base=main -f title=$title -f body=$body --jq .number } catch {}
      }
      if ($prNum) { gh pr merge $prNum --auto --squash 2>$null }
    } else { Write-Host "[warn] CHANGELOG.md not found — skip" }
  } else { Write-Host "[DRY-RUN] would open backfill PR for $newTag" }

  Write-StdLog -Module 'release-vpatch.safe' -Action 'tag+backfill' -Outcome 'OK' -Message $newTag
} catch {
  Write-StdLog -Module 'release-vpatch.safe' -Action 'apply' -Level 'ERROR' -Message $_.Exception.Message
  throw
} finally { Remove-Item -Force $LockFile -ErrorAction SilentlyContinue }