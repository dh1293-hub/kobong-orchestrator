#requires -PSEdition Core
#requires -Version 7.0
param([string]$Raw,[string]$Sha,[string]$Pr,[Parameter(ValueFromRemainingArguments=$true)][string[]]$Rest)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
function Try([string]$name,[scriptblock]$code){ Write-Host "`n### $name"; try{ & $code }catch{ Write-Host "[WARN] $name: $($_.Exception.Message)" } }
Write-Host "## AK Audit"
Write-Host "- sha: $Sha"; Write-Host "- pr : $Pr"; Write-Host "- args: $Raw"
Try 'npm audit (omit=dev)' {
  if (Get-Command npm -ErrorAction SilentlyContinue) { npm audit --omit=dev || $true } else { "npm not found" }
}
Try 'pip-audit' {
  if (Get-Command pip-audit -ErrorAction SilentlyContinue) { pip-audit || $true } else { "pip-audit not found" }
}
Write-Host "`n[AK] audit completed."