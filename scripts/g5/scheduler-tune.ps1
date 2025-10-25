#requires -Version 7.0
param(
  [string]$TaskName = "Kobong Weekly Housekeeping",
  [switch]$StartWhenAvailable,
  [switch]$AllowStartIfOnBatteries,
  [switch]$DontStopIfGoingOnBatteries
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'

Import-Module ScheduledTasks -ErrorAction SilentlyContinue | Out-Null
$t = Get-ScheduledTask -TaskName $TaskName -ErrorAction Stop
$cur = $t.Settings
$plan = @{
  StartWhenAvailableDesired=$StartWhenAvailable.IsPresent
  AllowStartOnBattDesired=$AllowStartIfOnBatteries.IsPresent
  DontStopOnBattDesired=$DontStopIfGoingOnBatteries.IsPresent
  Current=@{
    StartWhenAvailable=$cur.StartWhenAvailable
    DisallowStartIfOnBatteries=$cur.DisallowStartIfOnBatteries
    StopIfGoingOnBatteries=$cur.StopIfGoingOnBatteries
  }
} | ConvertTo-Json -Compress
Write-Host $plan

if (-not ($env:CONFIRM_APPLY -eq 'true')) { return }

$settings = New-ScheduledTaskSettingsSet `
  -StartWhenAvailable:($StartWhenAvailable.IsPresent -or $cur.StartWhenAvailable) `
  -AllowStartIfOnBatteries:($AllowStartIfOnBatteries.IsPresent -or -not $cur.DisallowStartIfOnBatteries) `
  -DontStopIfGoingOnBatteries:($DontStopIfGoingOnBatteries.IsPresent -or -not $cur.StopIfGoingOnBatteries)

Set-ScheduledTask -TaskName $TaskName -Settings $settings
Write-Host "[OK] Settings applied to $TaskName."