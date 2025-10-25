# APPLY IN SHELL
# scripts/g5/run-pr-complete.ps1
#requires -Version 7.0
param([switch]$ConfirmApply=$true,[string]$Root,[string[]]$Reviewers=@())
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
$RepoRoot = (git rev-parse --show-toplevel 2>$null); if(-not $RepoRoot){ $RepoRoot=(Get-Location).Path }
$LogDir   = Join-Path $RepoRoot 'logs\run'
New-Item -ItemType Directory -Force -Path $LogDir | Out-Null
$ts  = Get-Date -Format 'yyyyMMdd-HHmmss'
$log = Join-Path $LogDir ("pr-complete-$ts.log")
$tool = Join-Path $RepoRoot 'scripts\g5\auto-pr-complete.ps1'
$pwsh=(Get-Command pwsh).Source
$args=@('-NoLogo','-NoProfile','-ExecutionPolicy','Bypass','-File',$tool,'-ConfirmApply')
if ($Root){ $args += @('-Root',$Root) }
if ($Reviewers -and $Reviewers.Count -gt 0){ $args += @('-Reviewers'); $args += $Reviewers }
& $pwsh @args *>&1 | Tee-Object -FilePath $log -Append
$code=$LASTEXITCODE
Copy-Item -Force $log (Join-Path $LogDir 'last.log')
Write-Host "`n== Auto-PR 종료코드: $code"
Write-Host "== 로그: $log`n"
try { Start-Process notepad.exe $log } catch {}