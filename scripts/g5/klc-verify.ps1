# KLC Verify Smoke — PS7
# 사용: pwsh -NoProfile -File .\scripts\g5\klc-verify.ps1 [-Out _klc\verify.log]
param(
  [string]$Out = "_klc\klc-verify-$([Environment]::GetEnvironmentVariable('GITHUB_RUN_ID'))`.log"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Import-Module "$PSScriptRoot\..\..\src\kobong-logger-cli\kobong-logger.psm1" -Force

# 가벼운 작업(지연 측정)
$sw = [System.Diagnostics.Stopwatch]::StartNew()
Start-Sleep -Milliseconds 50
$sw.Stop()

$line = Write-KlcLine -Message "klc-verify ci" -ExitCode 0 -DurationMs $sw.ElapsedMilliseconds
if (-not (Test-KlcSchema -Line $line)) {
  Write-Error "KLC 형식 위반: $line"
}

# 출력/저장
if (-not (Test-Path -LiteralPath (Split-Path $Out -Parent))) {
  New-Item -ItemType Directory -Force -Path (Split-Path $Out -Parent) | Out-Null
}
$line | Out-File -FilePath $Out -Encoding utf8

Write-Host "[OK] $line" -ForegroundColor Green
