#requires -Version 7.0
param([switch]$ConfirmApply,[string]$Root)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

# APPLY IN SHELL
# One-Shot-Setup v1.1 — 상태 준비 + 모니터/CI 실행 준비 (generated: 2025-09-15 01:21:31 +09:00)
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

# 1) 디렉터리/기본 설정
if ($ConfirmApply) {
  pwsh -File "scripts/g5/status-setup.ps1" -ConfirmApply
} else {
  pwsh -File "scripts/g5/status-setup.ps1"
}

# 2) 모니터/CI 스크립트 존재 보장
$files   = @('scripts/g5/monitor-status.ps1','scripts/g5/monitor-logs.ps1','scripts/view-ci-summary.ps1')
$missing = @()
foreach ($f in $files) { if (-not (Test-Path $f)) { $missing += $f } }

if (@($missing).Count -gt 0) {
  Write-Host ("[INFO] Missing scripts: {0}" -f (($missing) -join ', '))
  if (Test-Path 'scripts/g5/installer-v1_3.ps1') {
    pwsh -File "scripts/g5/installer-v1_3.ps1" -ConfirmApply:$ConfirmApply
  } else {
    Write-Host "[WARN] installer-v1_3.ps1 not found. Please run the installer to create missing files."
  }
} else {
  Write-Host "[OK] Monitor/CI scripts already present."
}

# 3) 요약: 쉘/도구/스크립트 상태
pwsh -File "scripts/g5/shell-status.ps1"