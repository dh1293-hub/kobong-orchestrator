#requires -Version 7.0
param()
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'

function Write-KlcLog {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][ValidateSet('TRACE','DEBUG','INFO','WARN','ERROR','FATAL')] [string]$Level,
    [Parameter(Mandatory)] [string]$Module,
    [Parameter(Mandatory)] [string]$Action,
    [Parameter()] [string]$Outcome = '',
    [Parameter()] [string]$Error = '',
    [Parameter()] [string]$Message = ''
  )
  $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
  $jsonl = Join-Path $repoRoot 'logs\apply-log.jsonl'
  try {
    if (Get-Command kobong_logger_cli -ErrorAction SilentlyContinue) {
      & kobong_logger_cli log --level $Level --module $Module --action $Action --outcome $Outcome --error $Error --message $Message
      return
    }
  } catch {}
  $rec = @{
    timestamp=(Get-Date).ToString('o'); level=$Level; module=$Module; action=$Action; outcome=$Outcome; error=$Error; message=$Message;
    traceId=[guid]::NewGuid().ToString()
  } | ConvertTo-Json -Compress
  New-Item -ItemType Directory -Force -Path (Split-Path $jsonl) | Out-Null
  Add-Content -Path $jsonl -Value $rec
}