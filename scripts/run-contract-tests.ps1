# scripts/run-contract-tests.ps1 — clean (v2)
# PS-GUARD-BOOTSTRAP v1
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
Write-Host '[WARN] Continuous PowerShell session — follow GPT-5 steps only.' -ForegroundColor DarkYellow

$RepoRoot = Split-Path -Parent $PSScriptRoot
[Environment]::CurrentDirectory = $RepoRoot

# PYTHONPATH ensure (cross-platform separator)
$sep = [System.IO.Path]::PathSeparator
if ([string]::IsNullOrWhiteSpace($env:PYTHONPATH)) {
  $env:PYTHONPATH = $RepoRoot
} else {
  $parts = $env:PYTHONPATH -split [regex]::Escape([string]$sep)
  if ($parts -notcontains $RepoRoot) { $env:PYTHONPATH = "$RepoRoot$sep$($env:PYTHONPATH)" }
}

# optional env setup
if (Test-Path "$PSScriptRoot\setup-env.ps1") { & "$PSScriptRoot\setup-env.ps1" }

# choose python
$py = Join-Path $RepoRoot '.venv\Scripts\python.exe'
if (-not (Test-Path -LiteralPath $py)) { $py = 'python' }

# quick import check (PS-safe inline)
& $py -c "import sys; print('[PY] sys.path0:', sys.path[0]); import infra, infra.logging.json_logger as jl; print('[PY] import infra OK')"

# run tests
& $py -m pytest -q tests/contract
