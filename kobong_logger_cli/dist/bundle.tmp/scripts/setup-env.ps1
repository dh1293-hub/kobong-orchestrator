param([string]$Python = "python")
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
$RepoRoot = Split-Path -Parent $PSScriptRoot
[Environment]::CurrentDirectory = $RepoRoot
if (-not (Test-Path ".venv")) { & $Python -m venv .venv }
$py = if (Test-Path ".venv\Scripts\python.exe") { ".venv\Scripts\python.exe" } elseif (Test-Path ".venv/bin/python") { ".venv/bin/python" } else { $Python }
& $py -m pip install -q -r (Join-Path $RepoRoot "requirements.contract-tests.txt") --disable-pip-version-check
