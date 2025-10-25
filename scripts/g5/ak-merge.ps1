#requires -PSEdition Core
#requires -Version 7.0
param([string]$Raw,[string]$Sha,[string]$Pr,[Parameter(ValueFromRemainingArguments=$true)][string[]]$Args)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
if (-not $Pr) { Write-Host "[AK] merge: PR number missing"; exit 0 }
$apply  = $Args -contains '--apply'
$method = 'squash'
for ($i=0; $i -lt $Args.Count; $i++){
  if ($Args[$i] -eq '--method' -and $i+1 -lt $Args.Count) { $method = $Args[$i+1] }
}
Write-Host "## AK Merge"
Write-Host "- pr : $Pr"
Write-Host "- method: $method"
Write-Host "- mode: " + ($apply ? 'APPLY' : 'DRYRUN')
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) { Write-Host "gh not found"; exit 0 }
if ($apply) {
  $flag = switch ($method) { 'merge'{'--merge'} 'rebase'{'--rebase'} default{'--squash'} }
  gh pr merge $Pr $flag --auto
} else {
  Write-Host "[AK] would run: gh pr merge $Pr --$method --auto"
}
Write-Host "[AK] merge done."