#requires -PSEdition Core
#requires -Version 7.0
param([string]$Raw,[string]$Sha,[string]$Pr,[Parameter(ValueFromRemainingArguments=$true)][string[]]$Args)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
if (-not $Pr) { Write-Host "[AK] label: PR number missing"; exit 0 }
$apply = $Args -contains '--apply'
$op = if ($Args.Count -gt 0) { $Args[0] } else { '' }
$labels = @()
if ($Args.Count -gt 1) { $labels = $Args[1..($Args.Count-1)] | Where-Object { $_ -notmatch '^--' } }
Write-Host "## AK Label"
Write-Host "- pr : $Pr"
Write-Host "- op : $op"
Write-Host "- labels: $($labels -join ', ')"
Write-Host "- mode: " + ($apply ? 'APPLY' : 'DRYRUN')
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) { Write-Host "gh not found"; exit 0 }
switch ($op) {
  'add' { if ($apply) { gh issue edit $Pr --add-label ($labels -join ',') } }
  'rm'  { if ($apply) { gh issue edit $Pr --remove-label ($labels -join ',') } }
  default { Write-Host "[AK] label usage: /ak label add Foo Bar [--apply] | /ak label rm Foo [--apply]" }
}
Write-Host "[AK] label done."