[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)]
  [ValidateNotNullOrEmpty()]
  [string]$Command,

  [string]$Sha = "",
  [int]$Pr = 0,
  [string]$ExternalId = "",
  [switch]$ConfirmApply
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$script:startAt = Get-Date

function Write-Klc {
  param([string]$msg, [int]$exit=0)
  $dur = [int](New-TimeSpan -Start $script:startAt -End (Get-Date)).TotalMilliseconds
  Write-Host "[KLC] cmd=$Command pr=$Pr sha=$Sha exit=$exit durationMs=$dur msg=$msg"
}

function Invoke-Step {
  param(
    [Parameter(Mandatory=$true)][ScriptBlock]$Block,
    [string]$Name
  )
  & $Block
  $code = $LASTEXITCODE
  Write-Klc $Name $code
  exit $code
}

switch ($Command.ToLowerInvariant()) {
  'help' {
    Write-Host "/ak test | scan --all | fixloop preview|apply | rewrite"
    Write-Klc 'help' 0
    exit 0
  }
  'scan'    { Invoke-Step { & "$PSScriptRoot/ak-scan.ps1"    -ExternalId $ExternalId -Pr $Pr }                         'scan' }
  'rewrite' { Invoke-Step { & "$PSScriptRoot/ak-rewrite.ps1" -ExternalId $ExternalId -Pr $Pr -ConfirmApply:$ConfirmApply } 'rewrite' }
  'fixloop' { Invoke-Step { & "$PSScriptRoot/ak-fixloop.ps1" -Pr $Pr -ConfirmApply:$ConfirmApply }                     'fixloop' }
  'test'    { Invoke-Step { & "$PSScriptRoot/ak-test.ps1"    -Pr $Pr }                                                 'test' }
  default   {
    Write-Host "Unknown command: $Command"
    Write-Klc 'unknown' 10
    exit 10
  }
}
