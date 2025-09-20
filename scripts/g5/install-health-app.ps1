#requires -Version 7.0
param([switch]$Install,[switch]$Uninstall,[string]$RepoRoot,[string]$Branch='main',[int]$PollSec=15,[switch]$ConfirmApply)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply=$true }
if (-not $RepoRoot) { try{$RepoRoot=(git rev-parse --show-toplevel 2>$null)}catch{}; if(-not $RepoRoot){$RepoRoot=(Get-Location).Path} }
$RepoRoot=(Resolve-Path $RepoRoot).Path

$widget = Join-Path $RepoRoot 'scripts/g5/health-widget.ps1'
$taskName = 'Kobong Health Monitor'
$taskPath = '\Kobong\'
$startupDir = [Environment]::GetFolderPath('Startup')
$lnk = Join-Path $startupDir 'Kobong Health Monitor.lnk'

function New-StartupShortcut {
  param([string]$Pwsh,[string]$Widget,[string]$Branch,[int]$PollSec)
  $wsh = New-Object -ComObject WScript.Shell
  $sc = $wsh.CreateShortcut($lnk)
  $sc.TargetPath = $Pwsh
  $sc.Arguments  = "-NoLogo -NoProfile -STA -File `"$Widget`" -Branch $Branch -PollSec $PollSec"
  $sc.WorkingDirectory = $RepoRoot
  $sc.IconLocation = "$Pwsh,0"
  $sc.Save()
}

function Remove-StartupShortcut { if (Test-Path $lnk) { Remove-Item $lnk -Force } }

if ($Install) {
  if (-not $ConfirmApply) { throw "set CONFIRM_APPLY=true or pass -ConfirmApply" }
  $pwsh = (Get-Command pwsh).Source
  $arg  = ("-NoLogo -NoProfile -STA -File `"{0}`" -Branch {1} -PollSec {2}" -f $widget,$Branch,$PollSec)
  $action   = New-ScheduledTaskAction -Execute $pwsh -Argument $arg
  $trigger  = New-ScheduledTaskTrigger -AtLogOn
  $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries

  $principal = $null
  try {
    $principal = New-ScheduledTaskPrincipal -UserId "$env:UserDomain\$env:UserName" -LogonType Interactive -RunLevel Limited
  } catch {
    Write-Warning "Principal create failed, will try without explicit principal: $($_.Exception.Message)"
  }

  $reg=@{ TaskName=$taskName; TaskPath=$taskPath; Action=$action; Trigger=$trigger; Settings=$settings; Force=$true }
  if ($principal) { $reg['Principal']=$principal }

  try {
    Register-ScheduledTask @reg | Out-Null
    Remove-StartupShortcut
    Write-Host "✅ Scheduled Task installed: $taskPath$taskName" -ForegroundColor Green
  } catch {
    Write-Warning "Scheduled Task install failed: $($_.Exception.Message)"
    Write-Host "→ Falling back to Startup shortcut (no admin required)..." -ForegroundColor Yellow
    New-StartupShortcut -Pwsh $pwsh -Widget $widget -Branch $Branch -PollSec $PollSec
    Write-Host "✅ Startup shortcut installed: $lnk" -ForegroundColor Green
  }
}

if ($Uninstall) {
  if (-not $ConfirmApply) { throw "set CONFIRM_APPLY=true or pass -ConfirmApply" }
  try { Unregister-ScheduledTask -TaskName $taskName -TaskPath $taskPath -Confirm:$false -ErrorAction Stop | Out-Null } catch {}
  Remove-StartupShortcut
  Write-Host "✅ Removed autostart (Task & Startup link)" -ForegroundColor Green
}

if (-not $Install -and -not $Uninstall) { Write-Host "Preview. Use -Install or -Uninstall" -ForegroundColor Yellow }