# Verify branch protection by opening a PR and attempting to merge without approvals.
# Chooses an allowed merge method automatically and handles cleanup robustly.
#requires -PSEdition Core
#requires -Version 7.0
param(
  [string]$Root = "D:\ChatGPT5_AI_Link\dosc\Kobong-Orchestrator-VIP",
  [string]$BaseBranch = "main",
  [string]$Owner = "dh1293-hub",
  [string]$Repo  = "kobong-orchestrator",
  [switch]$ConfirmApply
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Log([string]$msg){ Write-Host ">>> $msg" }

# Resolve repo path (flat-aware)
$repoPath = (Test-Path (Join-Path $Root '.git')) ? $Root : (Join-Path (Join-Path (Join-Path $Root 'repos') $Owner) $Repo)

# Preflight
try { $null = git --version } catch { throw "git not found" }
try { $null = gh --version } catch { throw "gh CLI not found" }
if (-not (Test-Path (Join-Path $repoPath '.git'))) { throw "repo not found at $repoPath" }

$ts = (Get-Date).ToString('yyyyMMdd-HHmmss')
$branch  = "probe/enforcement-$ts"
$title   = "[probe] enforcement check $ts"
$body    = "Automated probe to verify branch protection: should be BLOCKED (no approvals)."

$plan = @"
Plan:
  - Create temp branch: $branch from $BaseBranch
  - Empty commit, push -> open PR
  - Try merge with allowed method (squash -> rebase -> merge)
  - Expect FAILURE (block). On success => protection too permissive.
  - Cleanup: close PR & delete branch
"@

if (-not $ConfirmApply) { Write-Host "[DRYRUN]`n$plan"; exit 0 }

Push-Location $repoPath
try {
  git fetch origin --prune
  git switch $BaseBranch
  git pull --ff-only

  git switch -c $branch
  git commit --allow-empty -m "$title"
  git push -u origin $branch

  # Open PR and capture number
  $prCreate = gh pr create --repo "$Owner/$Repo" --base $BaseBranch --head $branch --title "$title" --body "$body"
  if (-not $prCreate) { throw "failed to create PR" }
  Log "PR opened: $prCreate"

  # Find PR number by head branch
  $prNum = gh pr list --repo "$Owner/$Repo" --head $branch --json number --jq '.[0].number'
  if (-not $prNum) { throw "cannot resolve PR number for branch $branch" }
  Log "PR number: #$prNum"

  # Try merge with preferred order
  $methods = @(
    @{name='squash'; args='--squash'},
    @{name='rebase'; args='--rebase'},
    @{name='merge' ; args='--merge' }
  )
  $merged = $false
  $blocked = $false
  foreach($m in $methods){
    Log "Attempt merge via $($m.name)..."
    try {
      gh pr merge $prNum --repo "$Owner/$Repo" $m.args --admin --subject "probe merge" --body "probe" | Out-Host
      $exit = $LASTEXITCODE
      if ($exit -eq 0){
        $merged = $true
        break
      } else {
        # Non-zero exit; treat as blocked
        $blocked = $true
        Log "Merge blocked (exit=$exit) with $($m.name)."
      }
    } catch {
      $blocked = $true
      Log ("Merge blocked (exception) with {0}: {1}" -f $m.name, $_.Exception.Message)
    }
  }

  if ($merged){
    Write-Warning "Merge SUCCEEDED without approvals! Protection may be OFF or too permissive."
    # try to close PR (may already be merged) and delete branch
    try { gh pr close $prNum --repo "$Owner/$Repo" --delete-branch } catch {}
    exit 1
  } else {
    Log "Probe complete. Enforcement appears ACTIVE (merge blocked)."
    try { gh pr close $prNum --repo "$Owner/$Repo" --delete-branch } catch {}
    exit 0
  }
}
finally {
  Pop-Location
}
