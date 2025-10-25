#requires -PSEdition Core
#requires -Version 7.0
param([string]$Raw,[string]$Sha,[string]$Pr)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) { "gh not found"; exit 0 }
if (-not $Pr) { Write-Host "[AK] protect: PR number missing"; exit 0 }
$info = gh pr view $Pr --json baseRefName --jq .baseRefName
$owner,$repo = $env:GITHUB_REPOSITORY.Split('/')
Write-Host "## AK Protect`n- base: $info"
try {
  $p = gh api "repos/$owner/$repo/branches/$info/protection" | ConvertFrom-Json
  Write-Host "### requirements"
  Write-Host ("- required_status_checks: {0}" -f ($p.required_status_checks.required_contexts -join ', '))
  Write-Host ("- enforce_admins: {0}" -f $p.enforce_admins.enabled)
  Write-Host ("- required_pull_request_reviews: {0}" -f ($p.required_pull_request_reviews -ne $null))
  Write-Host ("- restrictions: {0}" -f ($p.restrictions -ne $null))
} catch {
  Write-Host "[WARN] protection API: $($_.Exception.Message)"
}
Write-Host "[AK] protect done."
