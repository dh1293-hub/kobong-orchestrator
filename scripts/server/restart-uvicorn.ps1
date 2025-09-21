# APPLY IN SHELL
#requires -Version 7.0
param([int]$Port = $env:KOBONG_API_PORT ?? 8080, [string]$Bind = '127.0.0.1')
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'

# stop existing uvicorn bound to $Port
$owners = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue | Select-Object -ExpandProperty OwningProcess -Unique
if ($owners) { $owners | ForEach-Object { Stop-Process -Id $_ -Force -ErrorAction SilentlyContinue } }

# pick python
$RepoRoot = (git rev-parse --show-toplevel 2>$null) ?? (Get-Location).Path
$py = Join-Path $RepoRoot 'server\.venv\Scripts\python.exe'
if (-not (Test-Path $py)) { $py = (Get-Command python).Path }

# choose app entry
$appEntry = if (Test-Path (Join-Path $RepoRoot 'server\app_entry.py')) { 'server.app_entry:app' } else { 'server.app:app' }

Start-Process -FilePath $py -ArgumentList @('-m','uvicorn',$appEntry,'--host',$Bind,'--port',"$Port") -WorkingDirectory $RepoRoot | Out-Null