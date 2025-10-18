# Harden a private repo after upgrading to Pro/Team (Branch protection + repo settings)
# DRYRUN by default; add -ConfirmApply to apply.
#requires -PSEdition Core
#requires -Version 7.0
param(
  [string]$Owner = "dh1293-hub",
  [string]$Repo  = "kobong-orchestrator",
  [string]$Branch = "main",
  [switch]$ConfirmApply,
  [switch]$EnableCodeOwners,       # require CODEOWNERS reviews
  [switch]$EnableSignedCommits,    # require signed commits (optional)
  [ValidateSet('squash','rebase','merge','squash+rebase')]
  [string]$MergePolicy = 'squash'  # allowed merge methods
)

Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'

function Write-Plan([string]$m){ Write-Host ">>> $m" }
function Exit-Err([string]$m){ Write-Error $m; exit 1 }

# Preflight
try { $null = gh --version } catch { Exit-Err "gh CLI not found. Install GitHub CLI and run gh auth login." }

$full = "$Owner/$Repo"
Write-Plan "Target: $full ($Branch)"

# Build repo edit args (merge policy + security)
$mergeArgs = @()
switch ($MergePolicy) {
  'squash'        { $mergeArgs += @('--enable-squash-merge','--disable-merge-commits','--disable-rebase-merge') }
  'rebase'        { $mergeArgs += @('--disable-squash-merge','--disable-merge-commits','--enable-rebase-merge') }
  'merge'         { $mergeArgs += @('--disable-squash-merge','--enable-merge-commits','--disable-rebase-merge') }
  'squash+rebase' { $mergeArgs += @('--enable-squash-merge','--disable-merge-commits','--enable-rebase-merge') }
}
$repoEdit = @('repo','edit', $full, '--enable-secret-scanning','--enable-secret-scanning-push-protection') + $mergeArgs

# Branch protection body
$body = @{
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
if ($EnableSignedCommits) {
  $body['required_signatures'] = $true
}
$json = $body | ConvertTo-Json -Depth 8

Write-Plan "Repo edit: gh $($repoEdit -join ' ')"
Write-Plan "Branch protection JSON (PUT /repos/$full/branches/$Branch/protection):"
$json | Write-Host

if (-not $ConfirmApply) { Write-Plan "[DRYRUN] Nothing applied. Re-run with -ConfirmApply to execute."; exit 0 }

# APPLY
# 1) Repo-level settings
gh @repoEdit | Out-Host

# 2) Branch protection
$path = "/repos/$Owner/$Repo/branches/$Branch/protection"
try {
  $json | gh api --method PUT -H "Accept: application/vnd.github+json" $path --input - | Out-Host
} catch {
  if ($_.Exception.Message -match 'Upgrade to GitHub Pro') {
    Exit-Err "API returned plan restriction (need Pro/Team). Confirm upgrade and re-run."
  } else {
    throw
  }
}

Write-Plan "Done. Verify with verify-protection.ps1 or gh api GET."
exit 0
