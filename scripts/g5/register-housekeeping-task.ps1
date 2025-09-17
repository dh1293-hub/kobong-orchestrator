#requires -Version 7.0
param(
  [switch]$ConfirmApply,
  [string]$Root,
  [string]$TaskName = "Kobong Weekly Housekeeping",
  [ValidatePattern("^\d{2}:\d{2}$")] [string]$At = "03:30",
  [ValidateSet("SUN","MON","TUE","WED","THU","FRI","SAT")] [string]$Day = "SUN"
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

# Repo root
$RepoRoot = if ($Root) { (Resolve-Path -LiteralPath $Root).Path } else { (git rev-parse --show-toplevel 2>$null) ?? (Get-Location).Path }
function Normalize-Path([string]$p){ $n=[IO.Path]::GetFullPath($p) -replace '/','\'; if ($n[-1] -ne '\'){$n}else{$n.TrimEnd('\')} }
$RepoRoot = Normalize-Path $RepoRoot

# Build args
$Pwsh       = (Get-Command pwsh -ErrorAction Stop).Source
$ScriptPath = Join-Path $RepoRoot 'scripts/g5/housekeeping-weekly.ps1'
$ArgLine    = '-NoProfile -ExecutionPolicy Bypass -File "'+$ScriptPath+'" -ConfirmApply -Root "'+$RepoRoot+'"'

# Desired schedule
$hh,$mm = $At.Split(':'); $hour=[int]$hh; $minute=[int]$mm
$runTime = [datetime]::Today.Date.AddHours($hour).AddMinutes($minute)
$dowEnum = switch ($Day.ToUpper()) {
  'SUN' {[System.DayOfWeek]::Sunday}
  'MON' {[System.DayOfWeek]::Monday}
  'TUE' {[System.DayOfWeek]::Tuesday}
  'WED' {[System.DayOfWeek]::Wednesday}
  'THU' {[System.DayOfWeek]::Thursday}
  'FRI' {[System.DayOfWeek]::Friday}
  'SAT' {[System.DayOfWeek]::Saturday}
}

function Get-CurrentPlan([string]$Name){
  Import-Module ScheduledTasks -ErrorAction SilentlyContinue | Out-Null

  # Try 1) ScheduledTasks module
  try{
    $t = Get-ScheduledTask -TaskName $Name -ErrorAction Stop
    $info = Get-ScheduledTaskInfo -TaskName $Name
    $tr = $t.Triggers | Where-Object { $_.TriggerType -eq 'Weekly' } | Select-Object -First 1
    $dayList = @(); $timeVal=$null
    if ($tr) {
      $dayList = @($tr.DaysOfWeek | ForEach-Object { $_.ToString().Substring(0,3).ToUpper() })
      try { $timeVal = [DateTime]::Parse($tr.StartBoundary).TimeOfDay } catch {}
    }
    return [pscustomobject]@{
      Exists=$true; Day=$dayList; Time=$timeVal;
      ActionPath=$t.Actions[0].Execute; ActionArgs=$t.Actions[0].Arguments;
      NextRun=$info.NextRunTime; Source='ScheduledTasks'
    }
  } catch {}

  # Try 2) COM API
  try{
    $svc = New-Object -ComObject 'Schedule.Service'
    $svc.Connect()
    $root = $svc.GetFolder('\')
    $task = $root.GetTasks(1) | Where-Object { $_.Name -eq $Name } | Select-Object -First 1
    if ($task) {
      $def = $task.Definition
      $tr  = @($def.Triggers) | Where-Object { $_.Type -eq 3 } | Select-Object -First 1  # 3=Weekly
      $timeVal=$null; $dayList=@()
      if ($tr) {
        try { $timeVal = ([datetime]$tr.StartBoundary).TimeOfDay } catch {}
        $mask = $tr.DaysOfWeek
        $map=@{1='SUN';2='MON';4='TUE';8='WED';16='THU';32='FRI';64='SAT'}
        foreach($k in $map.Keys){ if(($mask -band $k) -ne 0){ $dayList += $map[$k] } }
      }
      $act = $def.Actions.Item(1)
      return [pscustomobject]@{
        Exists=$true; Day=$dayList; Time=$timeVal;
        ActionPath=$act.Path; ActionArgs=$act.Arguments;
        NextRun=$task.NextRunTime; Source='com'
      }
    }
  } catch {}

  # Try 3) schtasks /XML
  $xmlText = & schtasks.exe /Query /TN $Name /XML 2>$null
  if ($LASTEXITCODE -eq 0 -and $xmlText) {
    try {
      [xml]$x = $xmlText
      $ct = $x.Task.Triggers.CalendarTrigger | Select-Object -First 1
      $timeVal=$null; $dayList=@()
      if ($ct) {
        try { $timeVal = ([datetime]$ct.StartBoundary).TimeOfDay } catch {}
        $daysRoot = $ct.ScheduleByWeek.DaysOfWeek
        if ($daysRoot) { $dayList = @($daysRoot.ChildNodes | ForEach-Object { $_.Name.Substring(0,3).ToUpper() }) }
      }
      $act = $x.Task.Actions.Exec
      return [pscustomobject]@{
        Exists=$true; Day=$dayList; Time=$timeVal;
        ActionPath=$act.Command; ActionArgs=$act.Arguments;
        NextRun=$null; Source='schtasks-xml'
      }
    } catch {}
  }

  return [pscustomobject]@{ Exists=$false; Day=@(); Time=$null; ActionPath=$null; ActionArgs=$null; NextRun=$null; Source='none' }
}

# Read current & compute NOOP
$cur = Get-CurrentPlan -Name $TaskName
$wantedDay3 = $Day.ToUpper()
$wantedTO   = $runTime.TimeOfDay
$curDays    = @($cur.Day)
$dayMatch   = $cur.Exists -and ($curDays -contains $wantedDay3)
$timeMatch  = $cur.Exists -and ($null -ne $cur.Time) -and ($cur.Time -eq $wantedTO)
$noop       = $dayMatch -and $timeMatch

# Preview (safe JSON)
$plan = @{
  task=$TaskName; when="$Day $At"; pwsh=$Pwsh; script=$ScriptPath; args=$ArgLine;
  exists=$cur.Exists; currentDay=$curDays; currentTime=($(if($cur.Time){$cur.Time.ToString()}else{'null'}));
  source=$cur.Source; noop=$noop
} | ConvertTo-Json -Compress
Write-Host $plan

if (-not $ConfirmApply) { return }

# Admin?
$curId    = [Security.Principal.WindowsIdentity]::GetCurrent()
$curPrinc = New-Object Security.Principal.WindowsPrincipal($curId)
$IsAdmin  = $curPrinc.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

Import-Module ScheduledTasks -ErrorAction SilentlyContinue | Out-Null
if ($noop) {
  $log = Join-Path $RepoRoot 'logs/apply-log.jsonl'
  New-Item -ItemType Directory -Force -Path (Split-Path $log) | Out-Null
  $rec = @{timestamp=(Get-Date).ToString('o');level='INFO';traceId=[guid]::NewGuid().ToString();module='register-housekeeping-task';action='register';inputHash='';outcome='NOOP';durationMs=0;errorCode='';message="Task=$TaskName; When=$Day $At; Admin=$IsAdmin"} | ConvertTo-Json -Compress
  Add-Content -Path $log -Value $rec
  return
}

# Register / Update
$action = New-ScheduledTaskAction -Execute $Pwsh -Argument $ArgLine -WorkingDirectory $RepoRoot
$trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek $dowEnum -At $runTime
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
if ($IsAdmin) {
  $principal = New-ScheduledTaskPrincipal -UserId "$env:USERNAME" -RunLevel Highest
} else {
  $principal = New-ScheduledTaskPrincipal -UserId "$env:USERNAME" -LogonType Interactive
}
try { Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue | Out-Null } catch {}
$st = New-ScheduledTask -Action $action -Trigger $trigger -Principal $principal -Settings $settings
Register-ScheduledTask -TaskName $TaskName -InputObject $st | Out-Null

# Log applied
$log = Join-Path $RepoRoot 'logs/apply-log.jsonl'
New-Item -ItemType Directory -Force -Path (Split-Path $log) | Out-Null
$rec2 = @{timestamp=(Get-Date).ToString('o');level='INFO';traceId=[guid]::NewGuid().ToString();module='register-housekeeping-task';action='register';inputHash='';outcome='APPLIED';durationMs=0;errorCode='';message="Task=$TaskName; When=$Day $At; Admin=$IsAdmin"} | ConvertTo-Json -Compress
Add-Content -Path $log -Value $rec2