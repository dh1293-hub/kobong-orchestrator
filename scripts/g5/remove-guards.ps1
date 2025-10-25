# remove-guards.ps1 — Remove the local hook and advisory workflow
#requires -PSEdition Core
#requires -Version 7.0
param(
  [string]$RepoRoot = "D:\ChatGPT5_AI_Link\dosc\Kobong-Orchestrator-VIP"
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'

$hookPath = Join-Path $RepoRoot ".git\hooks\pre-push"
$wfPath   = Join-Path $RepoRoot ".github\workflows\soft-guard.yml"

if (Test-Path $hookPath) { Remove-Item -LiteralPath $hookPath -Force }
if (Test-Path $wfPath)   { Remove-Item -LiteralPath $wfPath -Force }

Write-Host "Removed (if present):"
Write-Host " - $hookPath"
Write-Host " - $wfPath"
