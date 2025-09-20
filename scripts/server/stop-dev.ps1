#requires -Version 7.0
param([int]$Port=8080,[string]$Root)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'

function Get-RepoRoot([string]$InputRoot){
  if (-not [string]::IsNullOrWhiteSpace($InputRoot)) { return (Resolve-Path -LiteralPath $InputRoot).Path }
  $git = (& git rev-parse --show-toplevel 2>$null)
  if (-not [string]::IsNullOrWhiteSpace($git)) { return (Resolve-Path -LiteralPath $git).Path }
  return (Resolve-Path -LiteralPath (Get-Location).Path).Path
}

$RepoRoot = Get-RepoRoot $Root
$pidFile = Join-Path $RepoRoot "logs\serve\uvicorn-$Port.pid"

function Stop-ByPid([int]$pid){
  try {
    $p = Get-Process -Id $pid -ErrorAction SilentlyContinue
    if ($null -ne $p) {
      try { Stop-Process -Id $pid -ErrorAction SilentlyContinue } catch {}
      Start-Sleep -Milliseconds 400
      $p = Get-Process -Id $pid -ErrorAction SilentlyContinue
      if ($null -ne $p) { try { Stop-Process -Id $pid -Force -ErrorAction SilentlyContinue } catch {} }
      return $true
    }
  } catch {}
  return $false
}

$stopped = $false

# 1) pidfile 우선
if (Test-Path $pidFile) {
  try {
    $pidText = (Get-Content -Raw -LiteralPath $pidFile).Trim()
    $pid = [int]((($pidText -split '\s+') | Select-Object -First 1))
    if (Stop-ByPid $pid) { $stopped = $true }
  } catch {}
  try { Remove-Item -Force $pidFile -ErrorAction SilentlyContinue } catch {}
}

# 2) 폴백: uvicorn --port $Port 검색
if (-not $stopped) {
  try {
    $list = Get-CimInstance Win32_Process | Where-Object {
      ($_.CommandLine -match 'uvicorn') -and ($_.CommandLine -match "--port\s+$Port(\s|$)")
    }
    foreach ($p in $list) { try { Stop-ByPid $p.ProcessId | Out-Null } catch {} }
  } catch {}
}

Write-Host "[stop] requested for uvicorn on port $Port"