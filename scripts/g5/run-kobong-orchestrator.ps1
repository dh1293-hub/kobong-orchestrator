#requires -Version 7.0
param([switch]$ConfirmApply,[string]$Root)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

# APPLY IN SHELL
# Run-Kobong-Orchestrator v1 — 필요시 설치 후 실행 (generated: 2025-09-15 01:15:47 +09:00)
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

# 준비: 디렉터리
pwsh -File "scripts/g5/status-setup.ps1" @(@{ConfirmApply=$ConfirmApply} | ForEach-Object { if ($_.ConfirmApply) { '-ConfirmApply' } })

# 패키지 매니저 선택
$mgr = $null
if (Get-Command pnpm -ErrorAction SilentlyContinue) { $mgr='pnpm' }
elseif (Get-Command npm -ErrorAction SilentlyContinue) { $mgr='npm' }

$pkgJson = Join-Path $Repo 'package.json'
$nodeModules = Join-Path $Repo 'node_modules'

if (Test-Path $pkgJson -and $mgr) {
  if (-not (Test-Path $nodeModules)) {
    if ($ConfirmApply) {
      Write-Host "[Setup] Installing dependencies via $mgr …"
      if ($mgr -eq 'pnpm') { pnpm install } else { npm install }
    } else {
      Write-Host "[DRY-RUN] Would install dependencies via $mgr (set -ConfirmApply to apply)."
    }
  } else {
    Write-Host "[OK] node_modules present."
  }

  # 실행 스크립트 선택
  $startCmd = $null
  try {
    $pkg = Get-Content -Raw -Encoding utf8 $pkgJson | ConvertFrom-Json
    if ($pkg.scripts.start)      { $startCmd = "$mgr run start" }
    elseif ($pkg.scripts.dev)    { $startCmd = "$mgr run dev" }
  } catch {}
  if (-not $startCmd) {
    if (Test-Path 'dist/index.js') { $startCmd = 'node dist/index.js' }
  }

  if ($startCmd) {
    Write-Host "[Run] $startCmd"
    iex $startCmd
  } else {
    Write-Host "[WARN] No start command found. Please add scripts.start or dist/index.js."
  }
} else {
  Write-Host "[WARN] package.json or package manager not found. Skipping run."
}