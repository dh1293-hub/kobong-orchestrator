#requires -Version 7.0
param([string]$RemoteUrl,[string]$Root)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
function Info($m){ Write-Host ("[INFO] {0}" -f $m) -ForegroundColor Cyan }
function Die($c,$m){ throw ("{0}: {1}" -f $c,$m) }
if (-not $Root) { $Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path }
if (-not (Test-Path $Root)) { Die 'PRECONDITION' ("RepoRoot not found: " + $Root) }
if (-not (Test-Path (Join-Path $Root '.git'))) { Die 'PRECONDITION' 'Not a git repo' }
if (git -C $Root status --porcelain) { Die 'PRECONDITION' 'Repo not clean. Commit/Stash first.' }
Set-Location $Root
$ts = Get-Date -Format 'yyyyMMdd-HHmmss'
$branch = "split/kobong_logger_cli-$ts"
Info ("Subtree split → prefix=kobong_logger_cli branch=" + $branch)
git -C $Root subtree split --prefix=kobong_logger_cli -b $branch
if ($LASTEXITCODE -ne 0) { Die 'LOGIC' 'subtree split failed' }
if ($RemoteUrl) {
  $remote = "kb_cli_split_$ts"
  git -C $Root remote add $remote $RemoteUrl
  try { git -C $Root push $remote "$branch:refs/heads/main" } finally { git -C $Root remote remove $remote 2>$null }
  Info ("Pushed '" + $branch + "' → remote main")
} else {
  Info ("Created local branch '" + $branch + "'. Push later as needed.")
}
