#requires -Version 7.0
param(
  [switch]$ConfirmApply,
  [string]$Root,
  [string]$TaskName = "Kobong Weekly Housekeeping",
  [ValidatePattern("^\d{2}:\d{2}$")] [string]$At = "03:30",  # HH:mm
  [ValidateSet("SUN","MON","TUE","WED","THU","FRI","SAT")] [string]$Day = "SUN"
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

# Repo root
$RepoRoot = if ($Root) { (Resolve-Path -LiteralPath $Root).Path } else { (git rev-parse --show-toplevel 2>$null) ?? (Get-Location).Path }

function Normalize-Path([string]$p) {
  $n=[IO.Path]::GetFullPath($p) -replace '/','\'
  if ($n[-1] -ne '\') { return $n } else { return $n.TrimEnd('\') }
}
$RepoRoot = Normalize-Path $RepoRoot

# Build args
$Pwsh       = (Get-Command pwsh -ErrorAction Stop).Source
$ScriptPath = Join-Path $RepoRoot 'scripts/g5/housekeeping-weekly.ps1'
$ArgLine    = '-NoProfile -ExecutionPolicy Bypass -File "'+$ScriptPath+'" -ConfirmApply -Root "'+$RepoRoot+'"'

# Convert HH:mm -> DateTime for ScheduledTasks API
$hh,$mm = $At.Split(':'); $hour=[int]$hh; $minute=[int]$mm
$runTime = [datetime]::Today.Date.AddHours($hour).AddMinutes($minute)

# Day to enum
$dowEnum = switch ($Day.ToUpper()) {
  'SUN' {[System.DayOfWeek]::Sunday}
  'MON' {[System.DayOfWeek]::Monday}
  'TUE' {[System.DayOfWeek]::Tuesday}
  'WED' {[System.DayOfWeek]::Wednesday}
  'THU' {[System.DayOfWeek]::Thursday}
  'FRI' {[System.DayOfWeek]::Friday}
  'SAT' {[System.DayOfWeek]::Saturday}
}

# Preview
$plan = @{ task=$TaskName; when="$Day $At"; pwsh=$Pwsh; script=$ScriptPath; args=$ArgLine } | ConvertTo-Json -Compress
Write-Host $plan
if (-not $ConfirmApply) { return }

# Admin?
$curId    = [Security.Principal.WindowsIdentity]::GetCurrent()
$curPrinc = New-Object Security.Principal.WindowsPrincipal($curId)
$IsAdmin  = $curPrinc.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

try {
  Import-Module ScheduledTasks -ErrorAction SilentlyContinue | Out-Null
  $action = New-ScheduledTaskAction -Execute $Pwsh -Argument $ArgLine -WorkingDirectory $RepoRoot
  $trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek $dowEnum -At $runTime
  if ($IsAdmin) {
    $principal = New-ScheduledTaskPrincipal -UserId "$env:USERNAME" -RunLevel Highest
  } else {
    # 비관리자: 암호 없이 현재 세션에서 실행
    $principal = New-ScheduledTaskPrincipal -UserId "$env:USERNAME" -LogonType Interactive
  }
  try { Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue | Out-Null } catch {}
  $settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -AllowStartIfOnBatteries
  $st = New-ScheduledTask -Action $action -Trigger $trigger -Principal $principal -Settings $settings
  Register-ScheduledTask -TaskName $TaskName -InputObject $st | Out-Null
}
catch {
  # Fallback: schtasks (로캘 영향 최소화, 따옴표 엄격)
  $dow3 = $Day.Substring(0,3).ToUpper()
  $tr = '"' + $Pwsh + '" ' + $ArgLine
  schtasks.exe /Delete /TN "$TaskName" /F 2>$null | Out-Null
  $create = @('/Create','/SC','WEEKLY','/D',$dow3,'/TN',"$TaskName",'/TR',$tr,'/ST',$At,'/F')
  if ($IsAdmin) { $create += @('/RL','HIGHEST') } else { $create += @('/RL','LIMITED') }
  $p = Start-Process -FilePath 'schtasks.exe' -ArgumentList $create -NoNewWindow -PassThru -Wait
  if ($p.ExitCode -ne 0) { throw "schtasks /Create failed (exit=$($p.ExitCode))" }
}

# Log
$log = Join-Path $RepoRoot 'logs/apply-log.jsonl'
New-Item -ItemType Directory -Force -Path (Split-Path $log) | Out-Null
Add-Content -Path $log -Value (@{timestamp=(Get-Date).ToString('o');level='INFO';traceId=[guid]::NewGuid().ToString();module='register-housekeeping-task';action='register';inputHash='';outcome='APPLIED';durationMs=0;errorCode='';message="Task=$TaskName; When=$Day $At; Admin=$IsAdmin"} | ConvertTo-Json -Compress)