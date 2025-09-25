# APPLY IN SHELL
#requires -Version 7.0
param([string]$ExternalId='', [string]$Pr='')
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
Write-Host '[AK] similarity scan (demo)'
if (Get-Command kobong_logger_cli -ErrorAction SilentlyContinue) {
  kobong_logger_cli log --level INFO --module auto-kobong --action ak-scan --outcome SUCCESS --message ("externalId="+$ExternalId) 2>$null
} else {
  $repo=(git rev-parse --show-toplevel 2>$null) ?? (Get-Location).Path
  $rec=@{timestamp=(Get-Date).ToString('o');level='INFO';traceId=[guid]::NewGuid().ToString();
    module='auto-kobong';action='ak-scan';outcome='SUCCESS';errorCode='';message=("externalId="+$ExternalId)} | ConvertTo-Json -Compress
  $log=Join-Path $repo 'logs\apply-log.jsonl'; New-Item -ItemType Directory -Force -Path (Split-Path $log) | Out-Null; Add-Content -Path $log -Value $rec
}