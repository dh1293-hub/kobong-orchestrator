# APPLY IN SHELL
#requires -Version 7.0
param([switch]$ConfirmApply,[string]$Root='.',[string]$Version='',[string]$WorkflowPath='.github/workflows/release-docs.yml',[int]$MaxWaitSec=240)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

$RepoRoot=(Resolve-Path $Root).Path
Set-Location $RepoRoot
git fetch -p origin --tags | Out-Null
if (-not $Version) {
  $Version=(git tag --list "v*" --sort=-v:refname | Select-Object -First 1)
  if (-not $Version) { throw "no release tag" }
}

# lock+log
$LockFile=Join-Path $RepoRoot ".gpt5.lock"
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
  # resolve workflow id
  $wf=$null
  try { $wf=(gh api repos/:owner/:repo/actions/workflows | ConvertFrom-Json).workflows | Where-Object { $_.path -eq $WorkflowPath } | Select-Object -First 1 } catch {}
  if ($wf -and $ConfirmApply) { gh workflow run $wf.id --ref main 2>$null | Out-Null }

  # changelog PR (already opened by vpatch)
  $chg="release/changelog-$Version"
  $chgPr=$null
  try { $chgPr=gh pr list --head $chg --state all --limit 1 --json number --jq ".[0].number" 2>$null } catch {}
  if ($chgPr -and $ConfirmApply) { gh pr merge $chgPr --squash --auto 2>$null }

  # wait badge branch
  $badge="docs/readme-badge-$Version"
  $deadline=(Get-Date).AddSeconds($MaxWaitSec); $seen=$false
  while ((Get-Date) -lt $deadline) { if (git ls-remote --heads origin $badge) { $seen=$true; break }; Start-Sleep 5 }
  if ($seen) {
    $bpr=$null
    try { $bpr=gh pr list --head $badge --limit 1 --json number --jq ".[0].number" 2>$null } catch {}
    if (-not $bpr -and $ConfirmApply) {
      $title="docs(readme): update release badge ($badge)"; $body="Automated badge refresh."
      $null=gh pr create -H $badge -B main -t $title -b $body 2>$null
      # GH 가드: 번호 재조회 or API 폴백
      try { $bpr=gh pr list --head $badge --limit 1 --json number --jq ".[0].number" 2>$null } catch {}
      if (-not $bpr) { try { $bpr=gh api repos/:owner/:repo/pulls -f head=$badge -f base=main -f title=$title -f body=$body --jq .number } catch {} }
    }
    if ($bpr -and $ConfirmApply) {
      gh pr merge $bpr --squash --auto 2>$null
      gh pr checks $bpr --watch
    }
  }

  # verify main
  git switch main | Out-Null; git pull --ff-only | Out-Null
  $ok = Select-String -Path 'README.md' -Pattern ("releases/tag/{0}" -f $Version) -SimpleMatch -ErrorAction SilentlyContinue
  $esc= Select-String -Path 'README.md' -Pattern ($Version -replace '\.','\.') -SimpleMatch -ErrorAction SilentlyContinue
  $ch = Select-String -Path 'CHANGELOG.md' -Pattern $Version -SimpleMatch -ErrorAction SilentlyContinue
  Write-Host ($ok ? "[OK] README link → releases/tag/$Version" : "[WAIT] README not yet $Version")
  Write-Host ($esc ? "[FAIL] Escaped '$($Version -replace '\.','\.')' still present" : "[OK] No escaped version remnants")
  Write-Host ($ch ? "[OK] CHANGELOG mentions $Version" : "[WARN] CHANGELOG missing $Version")

  # cleanup merged branches
  if ($ConfirmApply) {
    foreach ($rb in @($badge,$chg)) {
      $n=$null;$s=$null
      try { $n=gh pr list --head $rb --state all --limit 1 --json number --jq ".[0].number" 2>$null } catch {}
      if ($n) { try { $s=gh pr view $n --json state --jq .state 2>$null } catch {} }
      if ($s -in @('MERGED','CLOSED')) {
        if (git ls-remote --heads origin $rb) { gh api -X DELETE "repos/:owner/:repo/git/refs/heads/$rb" 2>$null }
        if (git show-ref --verify --quiet "refs/heads/$rb") { git branch -D $rb | Out-Null }
      }
    }
  }
  Write-StdLog -Module 'finalize-release' -Action 'badge+verify+cleanup' -Outcome 'OK' -Message $Version
} catch {
  Write-StdLog -Module 'finalize-release' -Action 'run' -Level 'ERROR' -Message $_.Exception.Message
  throw
} finally { Remove-Item -Force $LockFile -ErrorAction SilentlyContinue }