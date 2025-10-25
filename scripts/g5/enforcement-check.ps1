# Verify branch protection by creating a temporary PR that should fail to merge (no approvals)
#requires -PSEdition Core
#requires -Version 7.0
param(
  [string]$Root = "D:\ChatGPT5_AI_Link\dosc\Kobong-Orchestrator-VIP",
  [string]$BaseBranch = "main",
  [string]$Owner = "dh1293-hub",
  [string]$Repo  = "kobong-orchestrator",
  [switch]$ConfirmApply  # when absent => DRYRUN (plan only)
)

Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'

function KLC($msg){ Write-Host ">>> $msg" }

# Resolve repo path (flat-aware)
$repoPath = (Test-Path (Join-Path $Root '.git')) ? $Root : (Join-Path (Join-Path (Join-Path $Root 'repos') $Owner) $Repo)

# Preflight
try { $null = git --version } catch { throw "git not found" }
try { $null = gh --version } catch { throw "gh CLI not found" }
if (-not (Test-Path (Join-Path $repoPath '.git'))) { throw "repo not found at $repoPath" }

# Prepare names
$ts = (Get-Date).ToString('yyyyMMdd-HHmmss')
$branch  = "probe/enforcement-$ts"
$title   = "[probe] enforcement check $ts"
$body    = "Automated probe to verify branch protection. This PR SHOULD NOT MERGE (no approvals)."

$plan = @"
Plan:
  - Create temp branch: $branch from $BaseBranch
  - Add empty commit & push to origin
  - Open PR into $BaseBranch
  - Attempt merge (expect **failure** if protection works)
  - Close PR & delete remote branch (cleanup)
"@

if (-not $ConfirmApply){
  Write-Host "[DRYRUN]`n$plan"
  return
}

Push-Location $repoPath
try {
  git fetch origin --prune
  git switch $BaseBranch
  git pull --ff-only

  git switch -c $branch
  git commit --allow-empty -m "$title"
  git push -u origin $branch

  $prUrl = gh pr create --base $BaseBranch --head $branch --title "$title" --body "$body"
  if (-not $prUrl) { throw "failed to create PR" }
  KLC "PR opened: $prUrl"

  $mergeOk = $true
  try {
    gh pr merge --merge --delete-branch --subject "probe merge" --body "probe"
  } catch {
    $mergeOk = $false
    KLC "Merge blocked as expected: $($_.Exception.Message)"
  }

  if ($mergeOk){
    Write-Warning "Merge unexpectedly SUCCEEDED. Protection might be off or too permissive!"
    try { gh pr close --delete-branch } catch {}
    exit 1
  } else {
    try { gh pr close --delete-branch } catch {}
    KLC "Probe complete. Enforcement appears ACTIVE."
    exit 0
  }
}
finally {
  Pop-Location
}
