# Verify repo merge policy and branch protection (works pre/post upgrade)
#requires -PSEdition Core
#requires -Version 7.0
param(
  [string]$Owner = "dh1293-hub",
  [string]$Repo  = "kobong-orchestrator",
  [string]$Branch = "main"
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'

$full = "$Owner/$Repo"

Write-Host "== Repo (REST /repos) =="
gh api "/repos/$Owner/$Repo" --jq '{visibility, private, allow_squash_merge, allow_merge_commit, allow_rebase_merge, delete_branch_on_merge, security_and_analysis}'

Write-Host "`n== Branch protection (REST) =="
try {
  gh api "/repos/$Owner/$Repo/branches/$Branch/protection" --jq '{enforce_admins:.enforce_admins.enabled, allow_force_pushes, allow_deletions, required_linear_history, required_conversation_resolution, required_pull_request_reviews}'
} catch {
  Write-Warning "Branch protection GET failed (likely Free plan on private repo): $($_.Exception.Message)"
}

Write-Host "`n== Repo (GraphQL subset via gh repo view) =="
gh repo view $full --json visibility,isPrivate,mergeCommitAllowed,rebaseMergeAllowed,squashMergeAllowed --jq '{visibility, isPrivate, mergeCommitAllowed, rebaseMergeAllowed, squashMergeAllowed}'
