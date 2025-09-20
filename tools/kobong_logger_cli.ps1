#requires -Version 7.0
param(
  [Parameter(Position=0)] [ValidateSet('log','xp')] $Command = 'log',
  [string]$level='INFO',
  [string]$module='orchestrator',
  [string]$action='run',
  [string]$outcome='SUCCESS',
  [int]$duration=0,
  [string]$error='',
  [string]$message='',
  # xp options
  [switch]$AddFix,
  [int]$Count=1,
  [int]$Threshold=5,
  [switch]$Show,
  [switch]$Reset
)
Import-Module "$PSScriptRoot/../scripts/lib/kobong-logger.psm1" -Force

switch ($Command) {
  'log' {
    Write-KobongLog -Level $level -Module $module -Action $action -Outcome $outcome -DurationMs $duration -ErrorCode $error -Message $message | Out-Null
    Write-Host "[shim] logged ($level/$outcome) $module::$action - $message"
  }
  'xp' {
    if ($AddFix) { $res = Add-KobongFixExperience -Count $Count -Threshold $Threshold; $res | Format-List | Out-String | Write-Host; break }
    if ($Show)   { Show-KobongExperience | Format-List | Out-String | Write-Host; break }
    if ($Reset)  { Reset-KobongExperience | Format-List | Out-String | Write-Host; break }
    Write-Host "Usage: xp [-AddFix [-Count N] [-Threshold 5]] | -Show | -Reset" -ForegroundColor Yellow
  }
}