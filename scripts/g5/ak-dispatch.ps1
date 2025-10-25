# APPLY IN SHELL
#requires -Version 7.0
param([string]$Command,[string]$Sha,[string]$Pr,[switch]$ConfirmApply)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['*:Encoding']='utf8'

function Get-RepoRoot {
  if ($env:GITHUB_WORKSPACE) { return $env:GITHUB_WORKSPACE }
  try {
    $root = (git rev-parse --show-toplevel) 2>$null
    if ($root) { return $root }
  } catch {}
  return (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
}

# KLC 간이 로거 (v1.2 최소 필드)
function Write-KLC([string]$Level='INFO',[string]$Action='dispatch',[string]$Outcome='DRYRUN',[string]$Message='ok',[int]$Exit=0){
  $rec = [ordered]@{
    timestamp = (Get-Date).ToString('o')
    level     = $Level
    traceId   = [guid]::NewGuid().ToString()
    module    = 'scripts'
    action    = $Action
    outcome   = $Outcome
    message   = $Message
  } | ConvertTo-Json -Compress
  $root   = Get-RepoRoot
  $logDir = Join-Path $root 'logs'
  New-Item -ItemType Directory -Force -Path $logDir | Out-Null
  Add-Content -Path (Join-Path $logDir 'ak7.jsonl') -Value $rec
  if($Exit -ne 0){ exit $Exit }
}

switch ($Command) {
  'scan'    { & $PSScriptRoot/ak-scan.ps1    -Pr $Pr -Sha $Sha; break }
  'rewrite' { & $PSScriptRoot/ak-rewrite.ps1 -Pr $Pr -Sha $Sha -ConfirmApply:$ConfirmApply; break }
  'fixloop' { & $PSScriptRoot/ak-fixloop.ps1 -Pr $Pr -Sha $Sha -ConfirmApply:$ConfirmApply; break }
  'test'    { & $PSScriptRoot/ak-test.ps1    -Pr $Pr -Sha $Sha; break }
  default   { Write-KLC 'ERROR' 'dispatch' 'FAILURE' "Unknown: $Command" 13 }
}
Write-KLC 'INFO' 'dispatch' 'SUCCESS' "done:$Command"
exit 0
