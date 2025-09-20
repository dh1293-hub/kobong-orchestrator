#requires -Version 7.0
param([int]$TimeoutSec=300)
Set-StrictMode -Version Latest
$ErrorActionPreference="Stop"
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$RepoRoot = (git rev-parse --show-toplevel 2>$null); if (-not $RepoRoot) { $RepoRoot = (Get-Location).Path }
$ServerRoot = Join-Path $RepoRoot "server"
$Py = Join-Path $ServerRoot ".venv\Scripts\python.exe"
$Pip = Join-Path $ServerRoot ".venv\Scripts\pip.exe"
& $Pip install -r (Join-Path $ServerRoot "requirements-dev.txt") | Write-Output
$env:PYTHONWARNINGS="ignore"
if (-not $env:KOBONG_VERSION -or $env:KOBONG_VERSION -eq "") { $env:KOBONG_VERSION = "0.1.0" }
$proc = Start-Process -FilePath $Py -ArgumentList "-m","pytest","-q" -WorkingDirectory $ServerRoot -PassThru -NoNewWindow
if (-not $proc.WaitForExit($TimeoutSec*1000)) { $proc | Stop-Process -Force; throw "pytest timeout ${TimeoutSec}s" }
exit $proc.ExitCode