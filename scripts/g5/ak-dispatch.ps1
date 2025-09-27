[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)]
  [ValidateNotNullOrEmpty()]
  [string]$Command,

  [string]$RawArgs = "",
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
  param([Parameter(Mandatory=$true)][ScriptBlock]$Block,[string]$Name)
  $code = 0
  try {
    & $Block
    $code = if ($LASTEXITCODE -is [int]) { $LASTEXITCODE } elseif ($?) { 0 } else { 13 }
  } catch {
    Write-Error $_
    $code = 13
  }
  Write-Klc $Name $code
  exit $code
}

# ----- 간단 인자 파싱(공백 단어 매칭) -----
$Apply   = ($RawArgs -match '(?<!\S)apply(?!\S)')
$Preview = ($RawArgs -match '(?<!\S)preview(?!\S)')
$All     = ($RawArgs -match '(?<!\S)--all(?!\S)')

switch ($Command.ToLowerInvariant()) {
  'help' {
    Write-Host "/ak test | scan [--all] | fixloop preview|apply | rewrite [options]"
    Write-Klc 'help' 0
    exit 0
  }
  'scan' {
    Invoke-Step {
      # 스캔: --all 감지 시 내부 스크립트가 지원하면 전달, 아니면 로깅만
      $args = @()
      if ($All) { $args += '--all' }
      & "$PSScriptRoot/ak-scan.ps1" -ExternalId $ExternalId -Pr $Pr @args
    } 'scan'
  }
  'rewrite' {
    Invoke-Step {
      & "$PSScriptRoot/ak-rewrite.ps1" -ExternalId $ExternalId -Pr $Pr -ConfirmApply:$Apply
    } 'rewrite'
  }
  'fixloop' {
    Invoke-Step {
      # apply면 -ConfirmApply 전달, preview면 Dry-run(스크립트가 지원하지 않아도 안전)
      & "$PSScriptRoot/ak-fixloop.ps1" -Pr $Pr -ConfirmApply:$Apply
      if ($Preview -and -not $Apply) { Write-Host "[info] preview mode requested" }
    } 'fixloop'
  }
  'test' {
    Invoke-Step {
      & "$PSScriptRoot/ak-test.ps1" -Pr $Pr
    } 'test'
  }
  default {
    Write-Host "Unknown command: $Command"
    Write-Klc 'unknown' 10
    exit 10
  }
}
