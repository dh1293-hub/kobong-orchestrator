$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
Write-Host "[WARN] Continuous PowerShell session — follow GPT-5 steps only." -ForegroundColor DarkYellow
$RepoRoot = Split-Path -Parent $PSScriptRoot
[Environment]::CurrentDirectory = $RepoRoot
$sep = [System.IO.Path]::PathSeparator
if ([string]::IsNullOrWhiteSpace($env:PYTHONPATH)) { $env:PYTHONPATH = $RepoRoot } else {
  $parts = $env:PYTHONPATH -split [regex]::Escape([string]$sep)
  if ($parts -notcontains $RepoRoot) { $env:PYTHONPATH = "$RepoRoot$sep$($env:PYTHONPATH)" }
}
if (Test-Path "$PSScriptRoot\setup-env.ps1") { & "$PSScriptRoot\setup-env.ps1" }
if (Test-Path ".venv\Scripts\python.exe") { $py = ".venv\Scripts\python.exe" } else { $py = "python" }
& $py -c "import sys; import infra, infra.logging.json_logger as jl; print('[PY] import infra OK')"
& $py -m pytest -q tests/contract
