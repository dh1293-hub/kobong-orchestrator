#requires -Version 7.0
param(
  [string]$Tag = 'v0.1.21',
  [int]$ChangelogPr = 105,
  [int]$BadgeTimeoutSec = 420,
  [int]$WatchIntervalSec = 6,
  [switch]$CreateReleasePage,
  [switch]$ConfirmApply
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

# Repo / Lock
$RepoRoot = (git rev-parse --show-toplevel 2>$null); if (-not $RepoRoot) { $RepoRoot = (Get-Location).Path }
Set-Location $RepoRoot
$LockFile = Join-Path $RepoRoot '.gpt5.lock'
if (Test-Path $LockFile) { Write-Error 'CONFLICT: .gpt5.lock exists.'; exit 11 }
"locked $(Get-Date -Format o)" | Out-File $LockFile -Encoding utf8 -NoNewline

# Logger
$sw=[Diagnostics.Stopwatch]::StartNew()
$trace=[guid]::NewGuid().ToString()
function Write-Rec([string]$level,[string]$action,[string]$msg,[string]$code=''){
  $rec=@{timestamp=(Get-Date).ToString('o');level=$level;traceId=$trace;module='release';action=$action;inputHash='';outcome=$level;durationMs=$sw.ElapsedMilliseconds;errorCode=$code;message=$msg}|ConvertTo-Json -Compress
  $log=Join-Path $RepoRoot 'logs/apply-log.jsonl'
  New-Item -ItemType Directory -Force -Path (Split-Path $log) | Out-Null
  Add-Content -Path $log -Value $rec
}

function Wait-Until([scriptblock]$Test,[int]$TimeoutSec=180,[int]$IntervalSec=5,[string]$Label='wait'){
  $t=[Diagnostics.Stopwatch]::StartNew()
  while ($t.Elapsed.TotalSeconds -lt $TimeoutSec) {
    try { if (& $Test) { return $true } } catch {}
    Start-Sleep -Seconds $IntervalSec
  }
  Write-Rec 'WARN' $Label ("Timeout after {0}s" -f $TimeoutSec) ''
  return $false
}

function Try-MergePr([int]$n){
  try { gh pr view $n | Out-Null } catch { Write-Rec 'WARN' 'pr-view' ("PR #{0} not found (maybe already merged?)" -f $n) ''; return }
  try { gh pr checks $n --watch | Out-Null } catch {}
  try {
    gh pr merge $n --squash --delete-branch --admin | Out-Null
    Write-Rec 'INFO' 'pr-merge' ("[OK] merged PR #{0}" -f $n) ''
  } catch {
    $msg = $_.Exception.Message -replace "`r?`n",' '
    Write-Rec 'WARN' 'pr-merge' ("Merge skipped/failed for PR #{0}: {1}" -f $n, $msg) ''
  }
}

try {
  # 0) Preflight
  git fetch origin main --prune | Out-Null
  git switch main | Out-Null
  git pull --ff-only | Out-Null
  Write-Rec 'INFO' 'preflight' ("RepoRoot={0}, Tag={1}" -f $RepoRoot,$Tag) ''

  # 1) Changelog PR 머지(있으면)
  if ($ChangelogPr -gt 0) { Try-MergePr $ChangelogPr }

  # 2) finalize (배지 워크플로 트리거)
  if ($ConfirmApply) { pwsh -File .\scripts\g5\finalize-release.ps1 -ConfirmApply } else { pwsh -File .\scripts\g5\finalize-release.ps1 }

  git fetch origin main --prune | Out-Null
  git switch main | Out-Null
  git pull --ff-only | Out-Null

  # 3) 배지 PR 탐지/머지(있으면)
  $badgeHead = "docs/readme-badge-$Tag"
  $badgePrNum = $null
  $found = Wait-Until -TimeoutSec $BadgeTimeoutSec -IntervalSec $WatchIntervalSec -Label 'wait-badge-pr' -Test {
    $raw = gh pr list --state open --limit 50 --json number,headRefName,title 2>$null
    if (-not $raw) { return $false }
    $open = $raw | ConvertFrom-Json
    $hit = $open | Where-Object { $_.headRefName -eq $badgeHead } | Select-Object -First 1
    if ($hit) { $script:badgePrNum = [int]$hit.number; return $true } else { return $false }
  }
  if ($found -and $badgePrNum) { Try-MergePr $badgePrNum } else { Write-Rec 'WARN' 'badge-pr' ("No open badge PR head={0} (within timeout)" -f $badgeHead) '' }

  # 4) README/CHANGELOG 검증(폴링 포함)
  $escTag = [regex]::Escape($Tag)
  $okReadme = Wait-Until -TimeoutSec $BadgeTimeoutSec -IntervalSec $WatchIntervalSec -Label 'wait-readme' -Test {
    $readme = Get-Content -Raw -Path ./README.md
    return ($readme -match "/releases/tag/$escTag")
  }
  if (-not $okReadme) { throw ("README not updated to {0}" -f $Tag) }

  $cl = Get-Content -Raw -Path ./CHANGELOG.md
  if ($cl -notmatch "(?m)^##\s*$escTag\b") { throw ("CHANGELOG missing {0} (merge may be pending)" -f $Tag) }

  git fetch --tags --prune | Out-Null
  $latest = (git describe --tags --abbrev=0)
  Write-Host ("[OK] VERIFIED → {0} (latest={1})" -f $Tag,$latest)
  Write-Rec 'INFO' 'verify' ("[OK] README & CHANGELOG → {0}" -f $Tag) ''

  # 5) (옵션) GitHub Release 페이지
  if ($CreateReleasePage) {
    try {
      $exists = (gh release view $Tag 2>$null)
      if (-not $exists) {
        $m=[regex]::Match($cl,"(?ms)^##\s*$escTag\b.*?(?=^##\s*v|\z)")
        $tmp=Join-Path $PWD "notes-$Tag.md"
        if ($m.Success){ $m.Value | Out-File $tmp -Encoding utf8 } else { ("Release {0}" -f $Tag) | Out-File $tmp -Encoding utf8 }
        gh release create $Tag --title ("Release {0}" -f $Tag) --notes-file $tmp | Out-Null
        Write-Rec 'INFO' 'create-gh-release' ("[OK] GitHub Release created → {0}" -f $Tag) ''
      } else {
        Write-Rec 'INFO' 'create-gh-release' ("[OK] GitHub Release already exists → {0}" -f $Tag) ''
      }
    } catch {
      Write-Rec 'WARN' 'create-gh-release' $_.Exception.Message ''
    }
  }
  Write-Host ("[DONE] Release stabilize → {0}" -f $Tag)
} catch {
  Write-Rec 'ERROR' 'step' $_.Exception.Message 'Code-013'
  throw
} finally {
  Remove-Item -Force $LockFile -ErrorAction SilentlyContinue
}
