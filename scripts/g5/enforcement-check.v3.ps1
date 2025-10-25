# Verify branch protection WITHOUT admin bypass (no --admin).
# Tries squash -> rebase -> merge; expects failure (block) when approvals required.
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
function Log([string]$m){ Write-Host ">>> $m" }

# repo path (flat-aware)
$repoPath = (Test-Path (Join-Path $Root '.git')) ? $Root : (Join-Path (Join-Path (Join-Path $Root 'repos') $Owner) $Repo)
try { $null = git --version } catch { throw "git not found" }
try { $null = gh --version } catch { throw "gh CLI not found" }
if (-not (Test-Path (Join-Path $repoPath '.git'))) { throw "repo not found at $repoPath" }

$ts = (Get-Date).ToString('yyyyMMdd-HHmmss')
$branch  = "probe/enforcement-$ts"
$title   = "[probe] enforcement check $ts"
$body    = "Automated probe to verify branch protection: should be BLOCKED (no approvals)."

$plan = @"
Plan:
 - Create temp branch from $BaseBranch
 - Empty commit, push, open PR
 - Try merge (squash -> rebase -> merge) **without admin bypass**
 - Expect BLOCK. If merged => protection too permissive / admins bypassing.
 - Cleanup: close PR & delete branch
"@

if (-not $ConfirmApply){ Write-Host "[DRYRUN]`n$plan"; exit 0 }

Push-Location $repoPath
try {
  git fetch origin --prune
  git switch $BaseBranch
  git pull --ff-only

  git switch -c $branch
  git commit --allow-empty -m "$title"
  git push -u origin $branch

  $prUrl = gh pr create --repo "$Owner/$Repo" --base $BaseBranch --head $branch --title "$title" --body "$body"
  if (-not $prUrl){ throw "failed to create PR" }
  Log "PR opened: $prUrl"
  $prNum = gh pr list --repo "$Owner/$Repo" --head $branch --json number --jq '.[0].number'
  if (-not $prNum){ throw "cannot resolve PR number" }
  Log "PR number: #$prNum"

  $methods = @(@{name='squash'; args='--squash'}, @{name='rebase'; args='--rebase'}, @{name='merge'; args='--merge'})
  $merged = $false
  $blocked = $false
  foreach($m in $methods){
    Log "Attempt merge via $($m.name) (no admin bypass)..."
    try {
      gh pr merge $prNum --repo "$Owner/$Repo" $m.args --subject "probe merge" --body "probe" | Out-Host
      $exit = $LASTEXITCODE
      if ($exit -eq 0){ $merged = $true; break }
      else { $blocked = $true; Log "Merge blocked (exit=$exit) with $($m.name)" }
    } catch {
      $blocked = $true
      Log "Merge blocked (exception) with $($m.name): $($_.Exception.Message)"
    }
  }

  if ($merged){
    Write-Warning "Merge SUCCEEDED without approvals! Likely 'Include administrators' is OFF or approvals not required."
    try { gh pr close $prNum --repo "$Owner/$Repo" --delete-branch } catch {}
    exit 1
  } else {
    Log "Probe complete. Enforcement appears ACTIVE (merge blocked)."
    try { gh pr close $prNum --repo "$Owner/$Repo" --delete-branch } catch {}
    exit 0
  }
}
finally { Pop-Location }
