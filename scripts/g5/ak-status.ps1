#requires -PSEdition Core
#requires -Version 7.0
param([string]$Raw,[string]$Sha,[string]$Pr,[Parameter(ValueFromRemainingArguments=$true)][string[]]$Rest)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
Write-Host "## AK Status"
Write-Host "- sha: $Sha"; Write-Host "- pr : $Pr"; Write-Host "- args: $Raw"
if (Get-Command gh -ErrorAction SilentlyContinue) {
  Write-Host "`n### Recent runs (top 10)"
  gh run list --limit 10
  if ($Pr) {
    Write-Host "`n### Checks for PR #$Pr"
    gh pr checks $Pr
  }
} else { "gh not found" }
Write-Host "`n[AK] status completed."