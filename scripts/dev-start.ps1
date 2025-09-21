#requires -Version 7.0
param()
Set-StrictMode -Version Latest
$ErrorActionPreference="Stop"
$PSDefaultParameterValues["*:Encoding"]="utf8"

$RepoRoot=(git rev-parse --show-toplevel 2>$null) ?? (Get-Location).Path
$WebUi   = Join-Path $RepoRoot "webui"

Get-NetTCPConnection -LocalPort 5173 -State Listen -ErrorAction SilentlyContinue |
  Select-Object -Expand OwningProcess -Unique |
  ForEach-Object { Stop-Process -Id $_ -Force -ErrorAction SilentlyContinue }

$cmd = $env:ComSpec; if(-not $cmd){ $cmd="C:\Windows\System32\cmd.exe" }
$npm = (Get-Command npm.cmd -ErrorAction SilentlyContinue)?.Source ?? (Get-Command npm -ErrorAction SilentlyContinue).Source
Start-Process -FilePath $cmd -ArgumentList "/d /c `"$npm`" run dev -- --config vite.config.cjs --port 5173 --strictPort --host" -WorkingDirectory $WebUi
Start-Process "cmd.exe" -ArgumentList "/c start `"`"`" `"http://localhost:5173/github.html`""
