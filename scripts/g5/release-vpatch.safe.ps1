# APPLY IN SHELL
#requires -Version 7.0
param([switch]$ConfirmApply,[string]$Root='.')
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

$RepoRoot = (Resolve-Path $Root).Path
Set-Location $RepoRoot

# Lock
$LockFile = Join-Path $RepoRoot ".gpt5.lock"
if (Test-Path $LockFile) { Remove-Item -Force $LockFile }
"locked $(Get-Date -Format o)" | Out-File $LockFile -NoNewline
$sw=[Diagnostics.Stopwatch]::StartNew()
$trace=[guid]::NewGuid().ToString()

try {
  git fetch origin --tags | Out-Null
  $baseSha = (git rev-parse origin/main).Trim()
  if (-not $baseSha) { throw "Failed to resolve origin/main" }

  $lastTag = (git tag --list "v*" --sort=-v:refname | Select-Object -First 1)
  if (-not $lastTag) { throw "No existing v* tag found" }
  if ($lastTag -notmatch '^v(\d+)\.(\d+)\.(\d+)$') { throw "Bad tag format: $lastTag" }
  $maj=[int]$Matches[1]; $min=[int]$Matches[2]; $pat=[int]$Matches[3]+1
  $newTag = "v$maj.$min.$pat"

  Write-Host "== Plan ==";
  Write-Host "• last tag : $lastTag"
  Write-Host "• new tag  : $newTag"
  Write-Host "• tag base : origin/main @$baseSha"

  if (git rev-parse -q --verify "refs/tags/$newTag" 2>$null) { throw "Tag already exists: $newTag" }

  if ($ConfirmApply) {
    git tag -a $newTag $baseSha -m "chore(release): $newTag"
    git push origin $newTag
  } else {
    Write-Host "[DRY-RUN] would: git tag -a $newTag $baseSha ; git push origin $newTag"
  }

  # CHANGELOG backfill PR
  $branch = "release/changelog-$newTag"
  if ($ConfirmApply) {
    git switch -C $branch origin/main | Out-Null
    $ch = Join-Path $RepoRoot 'CHANGELOG.md'
    if (Test-Path $ch) {
      $today=(Get-Date -Format 'yyyy-MM-dd')
      $old = Get-Content $ch -Raw -Encoding utf8
      $entry = "## $newTag ($today)`n- Maintenance: automated patch release.`n`n"
      $tmp="$ch.tmp"; ($entry+$old) | Out-File $tmp -Encoding utf8 -NoNewline
      Move-Item -Force $tmp $ch
      git add CHANGELOG.md
      git commit -m "chore(release): $newTag changelog"
      git push -u origin $branch
      $title="chore(release): $newTag changelog"
      $body ="Automated changelog backfill for $newTag."
      $out = gh pr create -H $branch -B main -t $title -b $body
      Write-Host $out
      gh pr merge --auto --squash 2>$null
    } else {
      Write-Host "[warn] CHANGELOG.md not found — skipping backfill PR."
    }
  } else {
    Write-Host "[DRY-RUN] would create $branch, prepend CHANGELOG, push & open auto-merge PR"
  }

  # log
  $rec=@{timestamp=(Get-Date).ToString('o');level='INFO';traceId=$trace;module='release-vpatch.safe';action='tag+backfill';applied=[bool]$ConfirmApply;newTag=$newTag;durationMs=$sw.ElapsedMilliseconds} | ConvertTo-Json -Compress
  $log=Join-Path $RepoRoot 'logs/apply-log.jsonl'; New-Item -ItemType Directory -Force -Path (Split-Path $log) | Out-Null; Add-Content -Path $log -Value $rec
} catch {
  $rec=@{timestamp=(Get-Date).ToString('o');level='ERROR';traceId=$trace;module='release-vpatch.safe';action='apply';error=$_.Exception.Message;durationMs=$sw.ElapsedMilliseconds} | ConvertTo-Json -Compress
  $log=Join-Path $RepoRoot 'logs/apply-log.jsonl'; New-Item -ItemType Directory -Force -Path (Split-Path $log) | Out-Null; Add-Content -Path $log -Value $rec
  throw
} finally {
  Remove-Item -Force $LockFile -ErrorAction SilentlyContinue
}