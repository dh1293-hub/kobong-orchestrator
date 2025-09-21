#requires -Version 7.0
param()
Set-StrictMode -Version Latest
$ErrorActionPreference="Stop"
$PSDefaultParameterValues["*:Encoding"]="utf8"

$RepoRoot=(git rev-parse --show-toplevel 2>$null) ?? (Get-Location).Path
$WebUi   = Join-Path $RepoRoot "webui"

$cmd = $env:ComSpec; if(-not $cmd){ $cmd="C:\Windows\System32\cmd.exe" }
$npm = (Get-Command npm.cmd -ErrorAction SilentlyContinue)?.Source ?? (Get-Command npm -ErrorAction SilentlyContinue).Source
Start-Process -FilePath $cmd -ArgumentList "/d /c `"$npm`" run build" -WorkingDirectory $WebUi -Wait
Write-Host "[OK] build → webui\dist" -ForegroundColor Green
