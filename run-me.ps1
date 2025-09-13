#requires -PSEdition Core
#requires -Version 7.0
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [Text.UTF8Encoding]::UTF8
[Environment]::CurrentDirectory = (Get-Location).Path

$logDir = Join-Path (Get-Location) 'logs'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
try { Start-Transcript -Path (Join-Path $logDir 'ps-transcript.txt') -Append -ErrorAction SilentlyContinue } catch {}

trap {
  $e = $PSItem
  if (-not $e) { $e = $Error[0] }
  $msg = if ($e) { ($e | Out-String) } else { 'Unknown error' }
  try { $msg | Out-File -LiteralPath (Join-Path $logDir 'last-error.txt') -Encoding utf8 } catch {}
  try { Stop-Transcript | Out-Null } catch {}
  if ($e -and $e.Exception) { Write-Error "[FATAL] $($e.Exception.Message)" } else { Write-Error "[FATAL] Unhandled error" }
  exit 1
}

# === 실제 작업(필요 시 커스터마이즈) ===
if (Test-Path '.\scripts\run-contract-tests.ps1') {
  pwsh -File .\scripts\run-contract-tests.ps1
}

Write-Host "[OK] run-me.ps1 executed under PS $($PSVersionTable.PSVersion)" -ForegroundColor Green

