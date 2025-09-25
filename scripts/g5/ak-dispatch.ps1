#requires -PSEdition Core
#requires -Version 7.0
param([string]$RawComment,[string]$Sha,[string]$Pr,[switch]$ConfirmApply)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RawComment) { Write-Host "[AK] no comment body"; exit 0 }
if ($RawComment -match '/ak\s+([a-z0-9\-]+)(.*)') {
  $cmd  = $matches[1]
  $args = $matches[2].Trim()
  Write-Host "[AK] command=$cmd args='$args' sha=$Sha pr=$Pr (stub ok)"
} else {
  Write-Host "[AK] '/ak' not found in comment"
}
exit 0