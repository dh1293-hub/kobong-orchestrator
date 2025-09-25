# APPLY IN SHELL
#requires -Version 7.0
param([string]$Pr='', [switch]$ConfirmApply)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }
if (-not $ConfirmApply) {
  Write-Host '[DRYRUN] FixLoop preview ready'
  if (Get-Command kobong_logger_cli -ErrorAction SilentlyContinue) {
    kobong_logger_cli log --level INFO --module auto-kobong --action ak-fixloop --outcome DRYRUN --message 'preview' 2>$null
  }
  exit 0
}
Write-Host '[APPLY] FixLoop patches applied (demo)'
if (Get-Command kobong_logger_cli -ErrorAction SilentlyContinue) {
  kobong_logger_cli log --level INFO --module auto-kobong --action ak-fixloop --outcome SUCCESS --message 'applied' 2>$null
}