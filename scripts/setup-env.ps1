# scripts/setup-env.ps1 — clean (v2)
param([string]$Python = 'python')
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$RepoRoot = Split-Path -Parent $PSScriptRoot
[Environment]::CurrentDirectory = $RepoRoot

# venv ensure
if (-not (Test-Path '.venv')) { & $Python -m venv .venv }

# choose python
$py = if (Test-Path '.venv\Scripts\python.exe') { '.venv\Scripts\python.exe' }
      elseif (Test-Path '.venv/bin/python')    { '.venv/bin/python' }
      else { $Python }

# deps (quiet)
& $py -m pip install -q -r (Join-Path $RepoRoot 'requirements.contract-tests.txt') --disable-pip-version-check
