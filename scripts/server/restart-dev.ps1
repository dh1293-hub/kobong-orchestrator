#requires -Version 7.0
param([int]$Port=8080,[string]$BindAddress="127.0.0.1",[string]$Root,[switch]$Reload=$true,[switch]$OpenDocs=$false,[switch]$Windowed=$false)
Set-StrictMode -Version Latest
$ErrorActionPreference="Stop"
$RepoRoot = (Resolve-Path (Split-Path -Parent $PSCommandPath)).Path | ForEach-Object { Split-Path -Parent $_ } | ForEach-Object { Split-Path -Parent $_ }
$Stop = Join-Path $RepoRoot "scripts\server\stop-dev.ps1"
$Start= Join-Path $RepoRoot "scripts\server\run-dev.ps1"
& $Stop -Port $Port
Start-Sleep -Milliseconds 300
if ($Windowed) { & $Start -Port $Port -BindAddress $BindAddress -Reload:$Reload -OpenDocs:$OpenDocs }
else { & $Start -Port $Port -BindAddress $BindAddress -Detach -Reload:$Reload -OpenDocs:$OpenDocs }
