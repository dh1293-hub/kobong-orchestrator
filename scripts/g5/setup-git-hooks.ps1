#requires -Version 7.0
param()
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
git config core.hooksPath .githooks
Write-Host "[OK] core.hooksPath set to .githooks"