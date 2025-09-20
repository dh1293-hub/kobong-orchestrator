#requires -Version 7.0
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
function Write-KobongJsonLog {
  param([ValidateSet('INFO','ERROR')] $Level='INFO',[string]$Module='kobong',[string]$Action='script',
        [ValidateSet('SUCCESS','FAILURE','DRYRUN')] $Outcome='SUCCESS',[string]$ErrorCode='',[string]$Message='')
  try {
    if (Get-Command kobong_logger_cli -ErrorAction SilentlyContinue) {
      & kobong_logger_cli log --level $Level --module $Module --action $Action --outcome $Outcome --error $ErrorCode --message $Message 2>$null
      return
    }
  } catch {}
  $root=(git rev-parse --show-toplevel 2>$null) ?? (Get-Location).Path
  $log=Join-Path $root 'logs/apply-log.jsonl'
  New-Item -ItemType Directory -Force -Path (Split-Path $log) | Out-Null
  $rec=@{timestamp=(Get-Date).ToString('o');level=$Level;traceId=[guid]::NewGuid().ToString();
    module=$Module;action=$Action;outcome=$Outcome;errorCode=$ErrorCode;message=$Message} | ConvertTo-Json -Compress
  Add-Content -Path $log -Value $rec
}
function Exit-Kobong{ param([ValidateSet('PRECONDITION','CONFLICT','TRANSIENT','LOGIC','Unknown')] $Category='Unknown',[string]$Message='')
  $code = switch ($Category){'PRECONDITION'{10} 'CONFLICT'{11} 'TRANSIENT'{12} 'LOGIC'{13} default{1}}
  Write-KobongJsonLog -Level ERROR -Action 'exit' -Outcome FAILURE -ErrorCode $Category -Message $Message
  exit $code
}