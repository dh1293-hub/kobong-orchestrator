#requires -Version 7.0
param([int]$Tail=20)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$RunsRoot = Join-Path $RepoRoot 'out\run-logs'
$dir = Get-ChildItem -Path $RunsRoot -Directory | Sort-Object LastWriteTime | Select-Object -Last 1
if (-not $dir) { throw "No run-logs found." }
$stderr = Join-Path $dir.FullName 'stderr.log'
if (-not (Test-Path $stderr)) { Write-Host "(no stderr.log in latest run)"; exit 0 }
Write-Host ("== STDERR tail({0}) :: {1} ==" -f $Tail,$dir.FullName) -ForegroundColor DarkYellow
Get-Content -Path $stderr -Tail $Tail