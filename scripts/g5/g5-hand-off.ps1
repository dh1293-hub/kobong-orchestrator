#requires -Version 7.0
<#
 g5-hand-off — 콘솔 한 번에 GPT-5 전달 패킷 만들기(+클립보드 복사)
 기본: 최근 60분 윈도우, Top=3
#>
param(
  [int]$Window = 60,
  [int]$Top = 3,
  [switch]$NoClipboard
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'

function Get-RepoRoot {
  $here = $PSScriptRoot
  if ([string]::IsNullOrWhiteSpace($here)) {
    try { $here = Split-Path -Parent $MyInvocation.MyCommand.Path -ErrorAction SilentlyContinue } catch {}
  }
  if ([string]::IsNullOrWhiteSpace($here)) { $here = (Get-Location).Path }
  $top = $null
  try { $top = (git -C $here rev-parse --show-toplevel 2>$null) } catch {}
  if ([string]::IsNullOrWhiteSpace($top)) {
    try { $top = (Resolve-Path (Join-Path $here '..\..')).Path } catch {}
  }
  if ([string]::IsNullOrWhiteSpace($top)) { $top = (Get-Location).Path }
  return $top
}

$RepoRoot = Get-RepoRoot
$briefPs1  = Join-Path $PSScriptRoot 'g5-brief.ps1'
$triagePs1 = Join-Path $PSScriptRoot 'g5-triage.ps1'
$recoPs1   = Join-Path $PSScriptRoot 'g5-actions.ps1'

if (-not (Test-Path $briefPs1))  { throw "MISSING: $briefPs1" }
if (-not (Test-Path $triagePs1)) { throw "MISSING: $triagePs1" }
if (-not (Test-Path $recoPs1))   { throw "MISSING: $recoPs1" }

# 1) 브리프(1줄)
$brief = & pwsh -NoProfile -ExecutionPolicy Bypass -File $briefPs1 -OneLine -SinceMinutes $Window

# 2) 트리아지(1줄) — 에러 없는 경우 top=none
$tri   = & pwsh -NoProfile -ExecutionPolicy Bypass -File $triagePs1 -OneLine -SinceMinutes $Window
$hasErr = ($tri -notmatch 'top=none')

# 3) 권고(1줄) — 에러 있을 때만
$reco = ''
if ($hasErr) {
  $reco = & pwsh -NoProfile -ExecutionPolicy Bypass -File $recoPs1 -OneLine -SinceMinutes $Window -Top $Top
}

# 패킷 구성
$lines = @($brief)
if ($hasErr) { $lines += $tri; if ($reco) { $lines += $reco } }
$packet = [string]::Join("`n", $lines)

# 출력
Write-Host "==== G5 HAND-OFF (copy & paste) ====" -ForegroundColor Cyan
$lines | ForEach-Object { Write-Host $_ }

# 클립보드
if (-not $NoClipboard) {
  try { $packet | Set-Clipboard; Write-Host "[OK] Copied to clipboard." -ForegroundColor Green } catch { Write-Warning "Clipboard copy failed: $($_.Exception.Message)" }
}