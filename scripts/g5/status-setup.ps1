# APPLY IN SHELL
# Status-Setup v1 — logs/out 디렉터리 준비 + git 기본 설정 안내 (generated: 2025-09-15 01:15:47 +09:00)
#requires -Version 7.0
param([switch]$ConfirmApply,[string]$Root)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

function Get-RepoRoot {
  if ($Root -and (Test-Path $Root)) { return (Resolve-Path $Root).Path }
  try { $r = git rev-parse --show-toplevel 2>$null; if ($r) { return $r } } catch {}
  return (Get-Location).Path
}
$Repo = Get-RepoRoot
Set-Location $Repo

$dirs = @('logs','logs/error-reports','out','out/status')
foreach($d in $dirs){ New-Item -ItemType Directory -Force -Path (Join-Path $Repo $d) | Out-Null }

Write-Host "[OK] Folders ready → logs/, logs/error-reports/, out/status/"
if ($ConfirmApply) {
  try {
    git config --local core.autocrlf false 2>$null
    Write-Host "[OK] git core.autocrlf=false (local)"
  } catch { Write-Host "[WARN] git config skipped: $($_.Exception.Message)" }
} else {
  Write-Host "[DRY-RUN] To set git core.autocrlf=false locally, rerun with -ConfirmApply"
}