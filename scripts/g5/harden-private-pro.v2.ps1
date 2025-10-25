# Harden a private repo after upgrading to Pro/Team (corrected flags)
# - Sets merge methods via REST (PATCH /repos)
# - Applies branch protection via REST (PUT /branches/<b>/protection)
# DRYRUN by default; add -ConfirmApply to execute.
#requires -PSEdition Core
#requires -Version 7.0
param(
  [string]$Owner = "dh1293-hub",
  [string]$Repo  = "kobong-orchestrator",
  [string]$Branch = "main",
  [switch]$ConfirmApply,
  [switch]$EnableCodeOwners,
  [switch]$EnableSignedCommits,
  [ValidateSet('squash','rebase','merge','squash+rebase')]
  [string]$MergePolicy = 'squash'
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'

try { $null = gh --version } catch { throw "gh CLI not found. Run gh auth login." }
$full = "$Owner/$Repo"

# Build merge policy JSON (REST PATCH /repos)
$allow = @{
  allow_squash_merge = $false
  allow_merge_commit = $false
  allow_rebase_merge = $false
  delete_branch_on_merge = $true
}
switch ($MergePolicy) {
  'squash'        { $allow.allow_squash_merge = $true }
  'rebase'        { $allow.allow_rebase_merge = $true }
  'merge'         { $allow.allow_merge_commit = $true }
  'squash+rebase' { $allow.allow_squash_merge = $true; $allow.allow_rebase_merge = $true }
}

# Repo-level security toggles (best-effort; may require paid plan)
$security = @{
  security_and_analysis = @{
    secret_scanning = @{ status = 'enabled' }
    secret_scanning_push_protection = @{ status = 'enabled' }
  }
}

$repoPatch = ($allow + $security) | ConvertTo-Json -Depth 5

# Branch protection JSON
$bp = @{
  required_status_checks = $null
  enforce_admins = $true
  required_pull_request_reviews = @{
    dismiss_stale_reviews = $true
    required_approving_review_count = 1
    require_code_owner_reviews = [bool]$EnableCodeOwners
  }
  restrictions = $null
  allow_force_pushes = $false
  allow_deletions   = $false
  required_linear_history = $true
  required_conversation_resolution = $true
}
if ($EnableSignedCommits) { $bp['required_signatures'] = $true }
$bpJson = $bp | ConvertTo-Json -Depth 8

Write-Host ">>> Target: $full ($Branch)"
Write-Host ">>> Repo PATCH (/repos):"
$repoPatch | Write-Host
Write-Host ">>> Branch protection PUT (/branches/$Branch/protection):"
$bpJson | Write-Host

if (-not $ConfirmApply){ Write-Host "[DRYRUN] Nothing applied."; exit 0 }

# APPLY
# 1) Repo: merge policies + security
try {
  $repoPatch | gh api -X PATCH "/repos/$Owner/$Repo" --input - | Out-Host
} catch {
  Write-Warning "Repo PATCH failed: $($_.Exception.Message)"
}

# 2) Branch protection
try {
  $bpJson | gh api --method PUT -H "Accept: application/vnd.github+json" "/repos/$Owner/$Repo/branches/$Branch/protection" --input - | Out-Host
} catch {
  if ($_.Exception.Message -match 'Upgrade to GitHub Pro') {
    Write-Warning "Branch protection requires Pro/Team. Upgrade then re-run."
  } else {
    throw
  }
}

Write-Host ">>> Done."
exit 0
