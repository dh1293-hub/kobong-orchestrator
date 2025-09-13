param([string]$Root)

$ErrorActionPreference = "Stop"

function Get-GitRoot {
  try {
    git rev-parse --show-toplevel 2>$null
  } catch { $null }
}

# 1) 루트 결정(우선순위: 인자 → ENV → Git → 스크립트 상위)
$root = $Root
if (-not $root) { $root = $env:HAN_GPT5_ROOT }
if (-not $root) { $root = Get-GitRoot }
if (-not $root) { $root = (Resolve-Path "$PSScriptRoot/..").Path }

if (-not (Test-Path $root)) { throw "Invalid root: $root" }

# 2) ENV 설정(PS5/PS7 호환)
$env:HAN_GPT5_ROOT = $root
if (-not $env:HAN_GPT5_OUT)   { $env:HAN_GPT5_OUT   = Join-Path $root 'out' }
if (-not $env:HAN_GPT5_TMP)   { $env:HAN_GPT5_TMP   = Join-Path $root '.tmp' }
if (-not $env:HAN_GPT5_LOGS)  { $env:HAN_GPT5_LOGS  = Join-Path $root 'logs' }
if (-not $env:HAN_GPT5_CACHE) { $env:HAN_GPT5_CACHE = Join-Path $root '.cache' }

# 3) 기본 폴더 보장
$dirs = @($env:HAN_GPT5_OUT, $env:HAN_GPT5_TMP, $env:HAN_GPT5_LOGS, $env:HAN_GPT5_CACHE)
foreach ($d in $dirs) { New-Item -ItemType Directory -Force -Path $d | Out-Null }
