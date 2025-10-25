# APPLY IN SHELL
#requires -PSEdition Core
#requires -Version 7.0
param([string]$Root = (Split-Path -Parent $MyInvocation.MyCommand.Path))
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repo = Resolve-Path $Root
$pidFile = Join-Path $repo 'logs/ghmon-mock.pid'
if(Test-Path $pidFile){
  $pid = Get-Content $pidFile | Select-Object -First 1
  try { Stop-Process -Id $pid -Force; Write-Host "Stopped GHMON server PID $pid" -ForegroundColor Yellow } catch { Write-Warning $_ }
  Remove-Item $pidFile -Force -ErrorAction SilentlyContinue
}else{
  Write-Warning "PID file not found: $pidFile"
}
