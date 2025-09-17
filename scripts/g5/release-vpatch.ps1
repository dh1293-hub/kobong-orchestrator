#requires -Version 7.0
<#  release-vpatch.ps1 — v1.2.1
    - PS7 전용 + 안전 헤더
    - .gpt5.lock 락/해제 보장
    - Dry-Run 기본, CONFIRM_APPLY=true 또는 -ConfirmApply 시 적용
    - origin/main 최신 커밋을 기준으로 패치 버전 자동 증가 (vX.Y.Z → vX.Y.(Z+1))
    - Dirty 상태면 auto-stash "pre-release-<ts>" 생성
    - 태그 push + GitHub Release 생성
    - CHANGELOG.md 생성 브랜치/PR + 오토머지
    - pre-release-* stash 자동 정리(기본 1개 보존)  # v1.2.1
#>
param(
  [switch]$ConfirmApply,
  [string]$Root,
  [int]$KeepStash = 1
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

# RepoRoot
$RepoRoot = if ($Root) {
  (Resolve-Path $Root).Path
} else {
  (git rev-parse --show-toplevel 2>$null) ?? (Get-Location).Path
}
Push-Location $RepoRoot
# 샌드박스 보조
function Assert-InRepo([string]$Path) {
  $full = (Resolve-Path $Path).Path
  if (-not $full.StartsWith((Resolve-Path $RepoRoot).Path, [StringComparison]::OrdinalIgnoreCase)) {
    throw 'PRECONDITION: path outside repository root.'
  }
}

# 락
$LockFile = Join-Path $RepoRoot '.gpt5.lock'
if (Test-Path $LockFile) { Write-Error 'CONFLICT: .gpt5.lock exists.'; exit 11 }
"locked $(Get-Date -Format o)" | Out-File $LockFile -NoNewline
$sw=[Diagnostics.Stopwatch]::StartNew()
$trace=[guid]::NewGuid().ToString()

try {
  if (-not (Test-Path (Join-Path $RepoRoot '.git'))) { throw 'PRECONDITION: not a git repo' }

  git fetch origin main --prune --tags | Out-Null
  $headCommit = (& git rev-parse origin/main).Trim()
  if ([string]::IsNullOrWhiteSpace($headCommit)) { throw 'PRECONDITION: origin/main not reachable' }

  $lastTag = (& git tag --list 'v*' --sort=-v:refname | Select-Object -First 1)
  if (-not $lastTag) { $lastTag = 'v0.1.0' } # baseline
  $m=[regex]::Match($lastTag,'^v(?<M>\d+)\.(?<m>\d+)\.(?<p>\d+)')
  if (-not $m.Success) { throw "PRECONDITION: last tag '$lastTag' not semver" }
  $newTag = 'v{0}.{1}.{2}' -f $m.Groups['M'].Value, $m.Groups['m'].Value, ([int]$m.Groups['p'].Value+1)

  $dirty = -not [string]::IsNullOrWhiteSpace( (& git status --porcelain).Trim() )
  $stashRef = $null
  $stamp = Get-Date -Format yyyyMMdd-HHmmss
  if ($dirty) {
    $stashRef = (& git stash push -u -m "pre-release-$stamp").Trim()
  }

  $plan = @(
    "• last tag :  + $lastTag",
    "• new tag  : $newTag",
    "• tag base : origin/main @$headCommit",
    "• stash    :  " + ($(if($dirty) { '+ pre-release-' + $stamp } else { '(none)' }))
  )
  $planStr = "== Plan ==`n" + ($plan -join "`n")
  Write-Host $planStr

  if (-not $ConfirmApply) {
    Write-Host "[DRY-RUN] Set CONFIRM_APPLY=true or pass -ConfirmApply to apply."
    return
  }

  # Tag+Release
  & git tag -a $newTag $headCommit -m $newTag
  & git push origin $newTag
  & gh release create $newTag -t "Release $newTag" -n "Automated patch release $newTag" | Out-Null

  # CHANGELOG 브랜치/PR
  $branch = "release/changelog-$newTag"
  & git switch -c $branch origin/main | Out-Null
  $chgPath = Join-Path $RepoRoot 'CHANGELOG.md'
  Assert-InRepo $chgPath

  $log = & git log "$lastTag..$headCommit" --pretty=format:"  • %h %s (%an, %ad)" --date=short
  $entry = @(
    "",
    "## $newTag — $(Get-Date -Format yyyy-MM-dd)",
    ""
  ) + $log + ("")

  $orig = (Test-Path $chgPath) ? (Get-Content $chgPath -Raw -Encoding utf8) : ""
  $bak = "$chgPath.bak-$(Get-Date -Format yyyyMMdd-HHmmss)"
  if (Test-Path $chgPath) { Copy-Item $chgPath $bak -Force }
  $tmp = "$chgPath.tmp"
  ($entry -join "`n") + "`n" + $orig | Out-File $tmp -Encoding utf8
  Move-Item -Force $tmp $chgPath

  & git add $chgPath
  & git commit -m "chore(release): $newTag changelog"
  & git push -u origin $branch
  $null = & gh pr create --title "chore(release): $newTag changelog" --body "- Add CHANGELOG for $newTag" --base main --head $branch
  & gh pr merge --auto --squash --delete-branch (gh pr view $branch --json number -q .number)

  # v1.2.1: pre-release-* stash 자동 정리 (기본 1개 보존)
  if ($KeepStash -lt 0) { $KeepStash = 0 }
  $lines   = @(git stash list | ForEach-Object { $_.ToString() })
  $matches = @($lines | Where-Object { $_ -match 'pre-release-\d{8}-\d{6}' })
  if ($matches.Count -gt $KeepStash) {
    $targets = @($matches | ForEach-Object { $_.Substring(0, $_.IndexOf(':')) })
    $dropList = @($targets | Select-Object -Skip $KeepStash)
    foreach ($s in $dropList) { git stash drop $s | Out-Null }
    Write-Host "[OK] Dropped:" ($dropList -join ', ')
  } else {
    Write-Host "[SKIP] Nothing to drop."
  }

  # 로그 기록
  $rec=@{
    timestamp=(Get-Date).ToString('o'); level='INFO'; traceId=$trace; module='release-vpatch';
    action='release'; inputHash=$newTag; outcome='SUCCESS'; durationMs=$sw.ElapsedMilliseconds;
    errorCode=''; message=$planStr
  } | ConvertTo-Json -Compress
  $logFile = Join-Path $RepoRoot 'logs/apply-log.jsonl'
  New-Item -ItemType Directory -Force -Path (Split-Path $logFile) | Out-Null
  Add-Content -Path $logFile -Value $rec

  Write-Host "[OK] Release created → $newTag"
  if ($stashRef) { Write-Host "[Note] Your work was stashed as: pre-release-$stamp  (복원: git stash list / git stash pop)" }
}
catch {
  $err=$_.Exception.Message
  $stk=$_.ScriptStackTrace
  $rec=@{timestamp=(Get-Date).ToString('o');level='ERROR';traceId=$trace;module='release-vpatch';action='release';inputHash='';outcome='FAILURE';durationMs=$sw.ElapsedMilliseconds;errorCode=$err;message=$stk} | ConvertTo-Json -Compress
  $logFile = Join-Path $RepoRoot 'logs/apply-log.jsonl'
  New-Item -ItemType Directory -Force -Path (Split-Path $logFile) | Out-Null
  Add-Content -Path $logFile -Value $rec
  Write-Error $err
  exit 13
}
finally {
  Remove-Item -Force $LockFile -ErrorAction SilentlyContinue
  Pop-Location
}