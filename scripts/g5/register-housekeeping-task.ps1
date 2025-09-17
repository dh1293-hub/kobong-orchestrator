#requires -Version 7.0
param(
  [switch]$ConfirmApply,
  [string]$Root,
  [string]$TaskName = "Kobong Weekly Housekeeping",
  [ValidatePattern("^\d{2}:\d{2}$")] [string]$At = "03:30",   # HH:mm (local)
  [ValidateSet("SUN","MON","TUE","WED","THU","FRI","SAT")] [string]$Day = "SUN"
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

# Resolve repo root (git → CWD → param)
$RepoRoot = if ($Root) { (Resolve-Path -LiteralPath $Root).Path } else { (git rev-parse --show-toplevel 2>$null) ?? (Get-Location).Path }

function Normalize-Path([string]$p) {
  $n=[IO.Path]::GetFullPath($p) -replace '/','\'
  if ($n[-1] -ne '\') { return $n } else { return $n.TrimEnd('\') }
}
$RepoRoot = Normalize-Path $RepoRoot

# Admin check
$IsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# Build action
$Pwsh = (Get-Command pwsh -ErrorAction Stop).Source
$Script = Join-Path $RepoRoot 'scripts/g5/housekeeping-weekly.ps1'
$args = @('-NoProfile','-ExecutionPolicy','Bypass','-File',"`"$Script`"","-ConfirmApply","-Root","`"$RepoRoot`"")
$ArgLine = $args -join ' '

# Parse time
$hh,$mm = $At.Split(':')
$hour=[int]$hh; $minute=[int]$mm

# Preview
$plan = @{
  task=$TaskName; when="$Day $At"; pwsh=$Pwsh; script=$Script; args=$ArgLine; admin=$IsAdmin
} | ConvertTo-Json -Compress
Write-Host $plan

if (-not $ConfirmApply) { return }

try {
  if ($IsAdmin) {
    $action = New-ScheduledTaskAction -Execute $Pwsh -Argument $ArgLine -WorkingDirectory $RepoRoot
    $trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek $Day -At ([datetime]::Today.Date.AddHours($hour).AddMinutes($minute).TimeOfDay)
    $principal = New-ScheduledTaskPrincipal -UserId "$env:USERNAME" -RunLevel Highest
    $st = New-ScheduledTask -Action $action -Trigger $trigger -Principal $principal
    try {
      Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue | Out-Null
    } catch {}
    Register-ScheduledTask -TaskName $TaskName -InputObject $st | Out-Null
  } else {
    # Fallback to schtasks (limited)
    $dow = $Day.Substring(0,3)  # SUN→SUN
    $cmd = 'schtasks.exe'
    $schArgs = @('/Create','/SC','WEEKLY','/D',$dow,'/TN',"`"$TaskName`"","/TR", "`"$Pwsh $ArgLine`"","/ST",$At,'/F')
    # Try remove old
    & schtasks.exe /Delete /TN "`"$TaskName`"" /F 2>$null | Out-Null
    & $cmd $schArgs | Out-Null
  }

  # Log
  $log = Join-Path $RepoRoot 'logs/apply-log.jsonl'
  New-Item -ItemType Directory -Force -Path (Split-Path $log) | Out-Null
  Add-Content -Path $log -Value (@{timestamp=(Get-Date).ToString('o');level='INFO';traceId=[guid]::NewGuid().ToString();module='register-housekeeping-task';action='register';inputHash='';outcome='APPLIED';durationMs=0;errorCode='';message="Task=$TaskName; When=$Day $At; Admin=$IsAdmin"} | ConvertTo-Json -Compress)
}
catch {
  $err=$_.Exception.Message
  $log = Join-Path $RepoRoot 'logs/apply-log.jsonl'
  Add-Content -Path $log -Value (@{timestamp=(Get-Date).ToString('o');level='ERROR';traceId=[guid]::NewGuid().ToString();module='register-housekeeping-task';action='register';inputHash='';outcome='FAILURE';durationMs=0;errorCode=$err;message=$_.ScriptStackTrace} | ConvertTo-Json -Compress)
  throw
}