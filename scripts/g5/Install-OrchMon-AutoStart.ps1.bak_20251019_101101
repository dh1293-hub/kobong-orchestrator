# --- Install-OrchMon-AutoStart.ps1 (정상/멱등/구버전 호환) ---
[CmdletBinding()]
param(
  # 작업 이름(원하면 바꾸세요)
  [string]$TaskName = "G5-OrchMon-AutoStart",
  # 열어줄 HTML 인덱스 (기본: Orchestrator UI)
  [string]$Index    = "$PSScriptRoot\..\..\Orchestrator-Monitoring\webui\Orchestrator-Monitoring-Su.html",
  # 브라우저 경로 또는 "auto" (자동 탐지: Edge → Chrome 순)
  [string]$Browser  = "C:\Program Files\Google\Chrome\Application\chrome.exe"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Resolve-BrowserPath {
  param([string]$Pref)
  if ($Pref -ne "auto" -and $Pref -ne "") {
    if (Test-Path $Pref) { return (Resolve-Path $Pref).Path }
    throw "지정한 브라우저 실행 파일이 없습니다: $Pref"
  }
 
  # 1) Chrome
  $chr = "$Env:ProgramFiles\Google\Chrome\Application\chrome.exe"
  if (Test-Path $chr) { return $chr }
  $chr = "$Env:ProgramFiles(x86)\Google\Chrome\Application\chrome.exe"
  if (Test-Path $chr) { return $chr }
  throw "브라우저를 찾을 수 없습니다. -Browser 에 실행 파일 경로를 지정하세요."
}

# 경로 정규화
$IndexPath = (Resolve-Path $Index).Path
if (-not (Test-Path $IndexPath)) {
  throw "Index not found: $IndexPath"
}
$BrowserPath = Resolve-BrowserPath -Pref $Browser

Write-Host "Index   : $IndexPath"
Write-Host "Browser : $BrowserPath"

# 이미 같은 이름의 작업이 있으면 제거(멱등)
try {
  Import-Module ScheduledTasks -ErrorAction SilentlyContinue | Out-Null
  try { Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue } catch {}
} catch {
  # 모듈이 없거나 PS7 호환 문제면 무시(아래 schtasks 폴백로 진행)
}

# 작업 스케줄러 등록(우선: ScheduledTasks, 실패 시 schtasks 폴백)
$registered = $false
try {
  if (Get-Command Register-ScheduledTask -ErrorAction SilentlyContinue) {
    $act = New-ScheduledTaskAction -Execute $BrowserPath -Argument "`"$IndexPath`""
    $trg = New-ScheduledTaskTrigger -AtLogOn
    $set = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
    Register-ScheduledTask -TaskName $TaskName -Action $act -Trigger $trg -Settings $set -RunLevel Highest `
      -Description "Launch Orchestrator-Monitoring UI on user logon" | Out-Null
    $registered = $true
  }
} catch {
  # 계속 진행해 폴백 시도
}

if (-not $registered) {
  # schtasks 폴백 (Windows 내장)
  $escapedIdx = $IndexPath.Replace('"','\"')
  $escapedExe = $BrowserPath.Replace('"','\"')
  & schtasks /Create /TN $TaskName /SC ONLOGON /RL HIGHEST /F /TR "`"$escapedExe`" `"$escapedIdx`""
  $registered = $true
}

if ($registered) {
  Write-Host "[OK] Scheduled Task registered: $TaskName" -ForegroundColor Green
  Write-Host "     - 실행 파일: $BrowserPath"
  Write-Host "     - 인덱스   : $IndexPath"
} else {
  throw "오토스타트 작업 등록 실패"
}
