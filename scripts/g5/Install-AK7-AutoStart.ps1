# --- Install-AK7-AutoStart.ps1 (정상/멱등) ---
[CmdletBinding()]
param(
  [string]$TaskName = "G5-AK7-AutoStart",
  # 기본 AK7 UI 진입점(필요시 실제 경로로 맞춰주세요)
  [string]$Index    = "$PSScriptRoot\..\..\AUTO-Kobong-Monitoring\AUTO-Kobong-Monitoring.html",
  # "auto"면 Edge→Chrome 순 자동탐지, 아니면 실행파일 경로 지정
  [string]$Browser  = "C:\Program Files\Google\Chrome\Application\chrome.exe"
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# --- Add: index auto-discovery ---
if(-not (Test-Path $Index)){
  $root = (Resolve-Path "$PSScriptRoot\..\..").Path
  $cand = Get-ChildItem -Path $root -Recurse -File -ErrorAction SilentlyContinue `
          -Include 'AUTO-Kobong-*.html','AK7*.html','*AUTO*Monitoring*.html' |
          Sort-Object FullName | Select-Object -First 1
  if($cand){ $Index = $cand.FullName } else { throw "AUTO-Kobong UI HTML이 보이지 않습니다. -Index로 경로를 지정하세요." }
}


function Resolve-BrowserPath {
  param([string]$Pref)
  if ($Pref -ne "auto" -and $Pref -ne "") {
    if (Test-Path $Pref) { return (Resolve-Path $Pref).Path }
    throw "지정한 브라우저 실행 파일이 없습니다: $Pref"
  }
  $candidates = @(
        "$Env:ProgramFiles\Google\Chrome\Application\chrome.exe",
    "$Env:ProgramFiles(x86)\Google\Chrome\Application\chrome.exe"
  )
  foreach($p in $candidates){ if(Test-Path $p){ return $p } }
  throw "브라우저를 찾을 수 없습니다. -Browser 로 경로를 지정하세요."
}

$IndexPath = (Resolve-Path $Index).Path
if(-not (Test-Path $IndexPath)){ throw "Index not found: $IndexPath" }
$BrowserPath = Resolve-BrowserPath -Pref $Browser

Write-Host "Index   : $IndexPath"
Write-Host "Browser : $BrowserPath"

try {
  Import-Module ScheduledTasks -ErrorAction SilentlyContinue | Out-Null
  try { Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue } catch {}
} catch {}

$ok = $false
try {
  if (Get-Command Register-ScheduledTask -ErrorAction SilentlyContinue) {
    $act = New-ScheduledTaskAction -Execute $BrowserPath -Argument "`"$IndexPath`""
    $trg = New-ScheduledTaskTrigger -AtLogOn
    $set = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
    Register-ScheduledTask -TaskName $TaskName -Action $act -Trigger $trg -Settings $set -RunLevel Highest `
      -Description "Launch AUTO-Kobong UI on user logon" | Out-Null
    $ok = $true
  }
} catch {}

if(-not $ok){
  & schtasks /Create /TN $TaskName /SC ONLOGON /RL HIGHEST /F /TR "`"$BrowserPath`" `"$IndexPath`""
  $ok = $true
}

if($ok){
  Write-Host "[OK] Scheduled Task registered: $TaskName" -ForegroundColor Green
  Write-Host "     - 실행 파일: $BrowserPath"
  Write-Host "     - 인덱스   : $IndexPath"
}else{
  throw "오토스타트 작업 등록 실패"
}
