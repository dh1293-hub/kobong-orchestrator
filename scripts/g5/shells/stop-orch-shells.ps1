# APPLY IN SHELL
#requires -PSEdition Core
#requires -Version 7.0
param([string]$Name='orch-shells-win')
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'

docker rm -f $Name 2>$null | Out-Null
Write-Host "[OK] stopped $Name"
