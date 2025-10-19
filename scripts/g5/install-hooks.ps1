# Install local git hooks (pre-push) to block pushes to main
#requires -PSEdition Core
#requires -Version 7.0
param(
  [string]$Repo = "D:\ChatGPT5_AI_Link\dosc\Kobong-Orchestrator-VIP"
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'

$hookSrc = Join-Path $PSScriptRoot "..\..\hooks\pre-push"
$hookDst = Join-Path $Repo ".git\hooks\pre-push"

if (-not (Test-Path (Join-Path $Repo ".git"))) {
  Write-Error "Not a git repo: $Repo"; exit 1
}

New-Item -ItemType Directory -Force -Path (Split-Path $hookDst) | Out-Null
Copy-Item -LiteralPath $hookSrc -Destination $hookDst -Force

# Ensure executable bit for Git Bash
try {
  & git -C $Repo update-index --chmod=+x ".git/hooks/pre-push" 2>$null
} catch {}
Write-Host "Installed pre-push hook at $hookDst"
exit 0
