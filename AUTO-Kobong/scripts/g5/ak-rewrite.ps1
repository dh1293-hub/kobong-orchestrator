# APPLY IN SHELL
#requires -Version 7.0
param([string]$ExternalId='', [string]$Pr='', [string]$Arg='', [switch]$ConfirmApply)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }
if (-not $ConfirmApply) {
  Write-Host '[DRYRUN] rewrite suggestion prepared'
  if (Get-Command kobong_logger_cli -ErrorAction SilentlyContinue) {
    kobong_logger_cli log --level INFO --module auto-kobong --action ak-rewrite --outcome DRYRUN --message $Arg 2>$null
  }
  exit 0
}
Write-Host '[APPLY] rewrite suggestion applied (demo)'
if (Get-Command kobong_logger_cli -ErrorAction SilentlyContinue) {
  kobong_logger_cli log --level INFO --module auto-kobong --action ak-rewrite --outcome SUCCESS --message $Arg 2>$null
}