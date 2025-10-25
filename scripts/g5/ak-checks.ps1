#requires -PSEdition Core
#requires -Version 7.0
param([string]$Raw,[string]$Sha,[string]$Pr)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
Write-Host "## AK Checks"
Write-Host "- pr : $Pr"
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) { Write-Host "gh not found"; exit 0 }
Write-Host "`n### gh pr checks"
gh pr checks $Pr
$branch = gh pr view $Pr --json headRefName --jq .headRefName
Write-Host "`n### Recent runs for $branch (top 5)"
gh run list --branch $branch --limit 5
Write-Host "`n[AK] checks completed."