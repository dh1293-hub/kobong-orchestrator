#requires -Version 7.0
param([int]$TimeoutSec=600)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$RepoRoot = (git rev-parse --show-toplevel 2>$null); if (-not $RepoRoot) { $RepoRoot = (Get-Location).Path }
$ServerRoot = Join-Path $RepoRoot 'server'
$Py = Join-Path $ServerRoot '.venv\Scripts\python.exe'
$Pip = Join-Path $ServerRoot '.venv\Scripts\pip.exe'
$Artifacts = Join-Path $RepoRoot 'artifacts'
New-Item -ItemType Directory -Force -Path $Artifacts | Out-Null
& $Pip install -r (Join-Path $ServerRoot 'requirements.txt') -r (Join-Path $ServerRoot 'requirements-dev.txt') | Write-Output
$proc = Start-Process -FilePath $Py -ArgumentList '-m','pytest','-q','--junitxml', (Join-Path $Artifacts 'junit.xml') -WorkingDirectory $ServerRoot -PassThru -NoNewWindow
if (-not $proc.WaitForExit($TimeoutSec*1000)) { $proc | Stop-Process -Force; throw "pytest timeout ${TimeoutSec}s" }
exit $proc.ExitCode