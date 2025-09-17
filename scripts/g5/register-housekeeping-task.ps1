#requires -Version 7.0
param(
  [string]$Repo = (Get-Location).Path,
  [string]$TaskName = 'Kobong Housekeeping Weekly',
  [ValidateSet('Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday')]
  [string]$Day = 'Sunday',
  [string]$At  = '10:00', # HH:mm (local)
  [int]$MaxLines = 50000,
  [int]$MaxBytes = 5MB,
  [switch]$Unregister
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'

function Get-IsElevated {
  $id=[Security.Principal.WindowsIdentity]::GetCurrent()
  $p = New-Object Security.Principal.WindowsPrincipal($id)
  return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if ($Unregister) {
  $tn = "Kobong\$TaskName"
  if (Get-ScheduledTask -TaskPath '\Kobong\' -TaskName $TaskName -ErrorAction SilentlyContinue) {
    Unregister-ScheduledTask -TaskPath '\Kobong\' -TaskName $TaskName -Confirm:$false
    Write-Host "[OK] unregistered: $tn"
  } else {
    # schtasks 경로까지 병행 제거
    schtasks /Delete /TN "$tn" /F 2>$null | Out-Null
    Write-Host "[SKIP] task not found: $tn"
  }
  exit 0
}

$pwsh = (Get-Command pwsh).Source
$script = Join-Path $Repo 'scripts\g5\housekeeping-weekly.ps1'
if (-not (Test-Path $script)) { throw "housekeeping-weekly.ps1 not found: $script" }

# 인자: repo + ConfirmApply + 로테이션 한계
$argLine = "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$script`" -Root `"$Repo`" -MaxLines $MaxLines -MaxBytes $MaxBytes -ConfirmApply"

# 트리거/액션
$trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek $Day -At ([DateTime]::Parse($At))
$action  = New-ScheduledTaskAction -Execute $pwsh -Argument $argLine

# 권한 자동 감지
$elevated = Get-IsElevated
$runLevel = if ($elevated) { 'Highest' } else { 'Limited' }
$principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel $runLevel

# 먼저 Windows ScheduledTasks로 시도(폴더: \Kobong\)
try {
  if (Get-ScheduledTask -TaskPath '\Kobong\' -TaskName $TaskName -ErrorAction SilentlyContinue) {
    Unregister-ScheduledTask -TaskPath '\Kobong\' -TaskName $TaskName -Confirm:$false
  }
  Register-ScheduledTask -TaskPath '\Kobong\' -TaskName $TaskName -Trigger $trigger -Action $action -Principal $principal `
    -Description "Prune gone branches + rotate logs for kobong-orchestrator (weekly, PS7)" | Out-Null
  Write-Host "[OK] registered via ScheduledTasks: \Kobong\$TaskName ($Day $At, RunLevel=$runLevel)"
}
catch {
  # Access Denied 등일 때 schtasks로 폴백(항상 LIMITED)
  $msg=$_.Exception.Message
  Write-Warning "ScheduledTasks registration failed: $msg — fallback to schtasks"
  $tn = "Kobong\$TaskName"
  $abbr = @{Sunday='SUN';Monday='MON';Tuesday='TUE';Wednesday='WED';Thursday='THU';Friday='FRI';Saturday='SAT'}[$Day]
  $bytes = [int]$MaxBytes
  $tr = 'pwsh -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass ' +
        "-File `"$script`" -Root `"$Repo`" -MaxLines $MaxLines -MaxBytes $bytes -ConfirmApply"
  schtasks /Delete /TN "$tn" /F 2>$null | Out-Null
  schtasks /Create /SC WEEKLY /D $abbr /ST $At /RL LIMITED /TN "$tn" /TR "$tr" /F | Out-Null
  Write-Host "[OK] registered via schtasks: $tn ($Day $At, RL=LIMITED)"
}
