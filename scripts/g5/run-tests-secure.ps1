#requires -Version 7.0
param([string]$Pattern='server/tests/test_secure_ping.py',[switch]$JUnit)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'

$RepoRoot = (& git rev-parse --show-toplevel 2>$null); if (-not $RepoRoot) { $RepoRoot = (Get-Location).Path }
$RepoRoot = [IO.Path]::GetFullPath(($RepoRoot -replace '/', '\')).TrimEnd('\')
Set-Location $RepoRoot

$candidates = @(
  (Join-Path $RepoRoot 'server\.venv\Scripts\python.exe'),
  (Join-Path $RepoRoot 'server\.venv\Scripts\python'),
  (Join-Path $RepoRoot '.venv\Scripts\python.exe'),
  (Join-Path $RepoRoot '.venv\Scripts\python')
) | Where-Object { Test-Path $_ }
$Py = if ($candidates) { $candidates[0] } else { (Get-Command python -ErrorAction Stop).Path }

$RunDir = Join-Path $RepoRoot 'logs\run'
New-Item -ItemType Directory -Force -Path $RunDir | Out-Null
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$logOut = Join-Path $RunDir "pytest-secure-$stamp.out.log"
$logErr = Join-Path $RunDir "pytest-secure-$stamp.err.log"
$junit  = Join-Path $RunDir "pytest-secure-$stamp.junit.xml"

"== pytest run @ $stamp ==" | Tee-Object -FilePath $logOut
$args = @('-m','pytest','-q',$Pattern)
if ($JUnit) { $args = @('-m','pytest','-q','--junitxml',"$junit",$Pattern) }
$out = & $Py @args 2>&1
$code = $LASTEXITCODE
$out | Tee-Object -FilePath $logOut -Append

if ($code -eq 0) {
  Write-Host "`n[GREEN] secure tests PASS ✔ (exit=0)" -ForegroundColor Green
} else {
  $out | Select-String -Pattern "===", "FAILED", "ERROR", "short test summary info" | ForEach-Object { $_.Line } |
    Tee-Object -FilePath $logErr
  Write-Host "`n[RED] secure tests FAIL (exit=$code)" -ForegroundColor Red
  Write-Host "  • stdout: $logOut"
  Write-Host "  • stderr: $logErr"
  if ($JUnit) { Write-Host "  • junit : $junit" }
}