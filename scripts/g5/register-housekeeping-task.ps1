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

if ($Unregister) {
  if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) {
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
    Write-Host "[OK] unregistered: $TaskName"
  } else {
    Write-Host "[SKIP] task not found: $TaskName"
  }
  exit 0
}

$pwsh = (Get-Command pwsh).Source
$script = Join-Path $Repo 'scripts\g5\housekeeping-weekly.ps1'
if (-not (Test-Path $script)) { throw "housekeeping-weekly.ps1 not found: $script" }

# 인자: repo + ConfirmApply + 로테이션 한계
$argLine = "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$script`" -Root `"$Repo`" -MaxLines $MaxLines -MaxBytes $MaxBytes -ConfirmApply"

$trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek $Day -At ([DateTime]::Parse($At))
$action  = New-ScheduledTaskAction -Execute $pwsh -Argument $argLine
$principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Highest

if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) {
  Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
}

Register-ScheduledTask -TaskName $TaskName -Trigger $trigger -Action $action -Principal $principal `
  -Description "Prune gone branches + rotate logs for kobong-orchestrator (weekly)"

Write-Host "[OK] registered: $TaskName ($Day $At)"
