# APPLY IN SHELL
#requires -Version 7.0
param([string]$Pr='')
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
Write-Host '[AK] run tests (demo)'
if (Get-Command kobong_logger_cli -ErrorAction SilentlyContinue) {
  kobong_logger_cli log --level INFO --module auto-kobong --action ak-test --outcome SUCCESS --message ("PR="+$Pr) 2>$null
}