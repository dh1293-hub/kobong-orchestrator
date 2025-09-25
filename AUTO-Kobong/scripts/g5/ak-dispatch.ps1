# APPLY IN SHELL
#requires -Version 7.0
param(
  [ValidateSet('scan','rewrite','fixloop','test','shell')]
  [string]$Command = 'scan',
  [string]$Sha = '',
  [string]$Pr  = '',
  [string]$Arg = '',
  [switch]$ConfirmApply
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }
if (-not $PSBoundParameters.ContainsKey('Command') -or [string]::IsNullOrWhiteSpace($Command)) { $Command = 'scan' }

function Write-KLC {
  param(
    [ValidateSet('INFO','ERROR')] $Level='INFO',
    [string]$Module='auto-kobong',
    [string]$Action='step',
    [ValidateSet('SUCCESS','FAILURE','DRYRUN')] $Outcome='SUCCESS',
    [string]$ErrorCode='',
    [string]$Message='',
    [int]$DurationMs=0
  )
  try {
    if (Get-Command kobong_logger_cli -ErrorAction SilentlyContinue) {
      & kobong_logger_cli log --level $Level --module $Module --action $Action --outcome $Outcome --error $ErrorCode --message $Message --meta durationMs=$DurationMs 2>$null
      return
    }
  } catch {}
  $repo = (git rev-parse --show-toplevel 2>$null); if (-not $repo) { $repo=(Get-Location).Path }
  $log = Join-Path $repo 'logs\apply-log.jsonl'
  New-Item -ItemType Directory -Force -Path (Split-Path $log) | Out-Null
  $rec=@{timestamp=(Get-Date).ToString('o');level=$Level;traceId=[guid]::NewGuid().ToString();
    module=$Module;action=$Action;outcome=$Outcome;errorCode=$ErrorCode;message=$Message;durationMs=$DurationMs} | ConvertTo-Json -Compress
  Add-Content -Path $log -Value $rec
}

switch ($Command.ToLowerInvariant()) {
  'scan'    { & "$PSScriptRoot\ak-scan.ps1"    -ExternalId "ak-scan@$Sha"    -Pr $Pr }
  'rewrite' { & "$PSScriptRoot\ak-rewrite.ps1" -ExternalId "ak-rewrite@$Sha" -Pr $Pr -Arg $Arg -ConfirmApply:$ConfirmApply }
  'fixloop' { & "$PSScriptRoot\ak-fixloop.ps1" -Pr $Pr -ConfirmApply:$ConfirmApply }
  'test'    { & "$PSScriptRoot\ak-test.ps1"    -Pr $Pr }
  'shell'   { Write-Host '[INFO] shell passthrough (sandboxed log only)'; Write-KLC -Action 'shell' -Outcome 'DRYRUN' -Message $Arg }
  default   { Write-Host "[WARN] Unknown: $Command"; exit 10 }
}