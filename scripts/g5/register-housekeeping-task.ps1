#requires -Version 7.0
param(
  [switch]$ConfirmApply,
  [string]$Root,
  [string]$TaskName = "Kobong Weekly Housekeeping",
  [ValidatePattern("^\d{2}:\d{2}$")] [string]$At = "03:30",   # HH:mm
  [ValidateSet("SUN","MON","TUE","WED","THU","FRI","SAT")] [string]$Day = "SUN"
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

# Resolve repo root (git → CWD → param)
$RepoRoot = if ($Root) { (Resolve-Path -LiteralPath $Root).Path } else { (git rev-parse --show-toplevel 2>$null) ?? (Get-Location).Path }

# Small helpers
function Normalize-Path([string]$p) {
  $n=[IO.Path]::GetFullPath($p) -replace '/','\'
  if ($n[-1] -ne '\') { return $n } else { return $n.TrimEnd('\') }
}
$RepoRoot = Normalize-Path $RepoRoot

$trace=[guid]::NewGuid().ToString()
$sw=[Diagnostics.Stopwatch]::StartNew()
$LockFile = Join-Path $RepoRoot '.gpt5.lock'

try {
  if (Test-Path $LockFile) { throw 'CONFLICT: .gpt5.lock exists.' }
  "locked $(Get-Date -Format o)" | Out-File $LockFile -Encoding utf8 -NoNewline

  $Pwsh = (Get-Command pwsh -ErrorAction Stop).Source
  $ScriptPath = Join-Path $RepoRoot 'scripts/g5/housekeeping-weekly.ps1'
  $args = @('-NoProfile','-ExecutionPolicy','Bypass','-File',"`"$ScriptPath`"","-ConfirmApply","-Root","`"$RepoRoot`"")
  $ArgLine = $args -join ' '

  # time parse
  $hh,$mm = $At.Split(':'); $hour=[int]$hh; $minute=[int]$mm

  # preview
  $plan = @{
    task=$TaskName; when="$Day $At"; pwsh=$Pwsh; script=$ScriptPath; args=$ArgLine
  } | ConvertTo-Json -Compress
  Write-Host $plan

  if (-not $ConfirmApply) { return }

  # Admin detection → Register-ScheduledTask (Highest) or schtasks fallback
  $IsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

  if ($IsAdmin) {
    $action = New-ScheduledTaskAction -Execute $Pwsh -Argument $ArgLine -WorkingDirectory $RepoRoot
    $trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek $Day -At ([datetime]::Today.Date.AddHours($hour).AddMinutes($minute).TimeOfDay)
    $principal = New-ScheduledTaskPrincipal -UserId "$env:USERNAME" -RunLevel Highest
    $st = New-ScheduledTask -Action $action -Trigger $trigger -Principal $principal
    try { Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue | Out-Null } catch {}
    Register-ScheduledTask -TaskName $TaskName -InputObject $st | Out-Null
  } else {
    # schtasks fallback (user context)
    $dow = $Day.Substring(0,3)      # SUN/MON/...
    & schtasks.exe /Delete /TN "`"$TaskName`"" /F 2>$null | Out-Null
    & schtasks.exe /Create /SC WEEKLY /D $dow /TN "`"$TaskName`"" /TR "`"$Pwsh $ArgLine`"" /ST $At /F | Out-Null
  }

  # log
  $log = Join-Path $RepoRoot 'logs/apply-log.jsonl'
  New-Item -ItemType Directory -Force -Path (Split-Path $log) | Out-Null
  Add-Content -Path $log -Value (@{
    timestamp=(Get-Date).ToString('o');level='INFO';traceId=$trace;
    module='register-housekeeping-task';action='register';
    inputHash='';outcome='APPLIED';durationMs=$sw.ElapsedMilliseconds;errorCode='';
    message="Task=$TaskName; When=$Day $At; Admin=$IsAdmin"
  } | ConvertTo-Json -Compress)
}
catch {
  $err=$_.Exception.Message; $sw.Stop()
  try {
    $log = Join-Path $RepoRoot 'logs/apply-log.jsonl'
    New-Item -ItemType Directory -Force -Path (Split-Path $log) | Out-Null
    Add-Content -Path $log -Value (@{
      timestamp=(Get-Date).ToString('o');level='ERROR';traceId=$trace;
      module='register-housekeeping-task';action='register';
      inputHash='';outcome='FAILURE';durationMs=$sw.ElapsedMilliseconds;errorCode=$err;
      message=$_.ScriptStackTrace
    } | ConvertTo-Json -Compress)
  } catch {}
  throw
}
finally {
  Remove-Item -Force $LockFile -ErrorAction SilentlyContinue
}