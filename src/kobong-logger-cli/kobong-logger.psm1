#requires -Version 7.0
Set-StrictMode -Version Latest

function New-KlcTraceId {
  [CmdletBinding()]
  param([string]$Prefix = "g5")
  $stamp = (Get-Date).ToString("yyyyMMddHHmmss")
  $rand  = ([guid]::NewGuid().ToString("N")).Substring(0,6)
  return "$Prefix-$stamp-$rand"
}

function Get-KlcAnchorHash {
  [CmdletBinding()]
  param(
    [string]$Seed,
    [int]$Take = 12
  )
  $seed2 = if ($env:GITHUB_SHA) { "$Seed`n$($env:GITHUB_SHA)" } else { $Seed }
  $sha = [System.Security.Cryptography.SHA256]::Create()
  $bytes = [Text.Encoding]::UTF8.GetBytes($seed2)
  $hashBytes = $sha.ComputeHash($bytes)
  $hex = foreach($b in $hashBytes){ '{0:x2}' -f $b }
  $hash = -join $hex
  return $hash.Substring(0,[Math]::Min($Take,$hash.Length))
} else { $Seed }
  $sha = [System.Security.Cryptography.SHA256]::Create()
  $bytes = [Text.Encoding]::UTF8.GetBytes($seed2)
  $hash = $sha.ComputeHash($bytes) | ForEach-Object { $_.ToString('x2') } -join ''
  return $hash.Substring(0,[Math]::Min($Take,$hash.Length))
}

function Write-KlcLine {
  <#
    .SYNOPSIS
      KLC 1행을 표준 형식으로 출력합니다.
    .OUTPUTS
      string: "KLC | traceId | durationMs | exitCode | anchorHash | message"
  #>
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$Message,
    [int]$ExitCode = 0,
    [int]$DurationMs = 0,
    [string]$TraceId,
    [string]$AnchorHash
  )
  if (-not $TraceId)   { $TraceId   = New-KlcTraceId }
  if (-not $AnchorHash){ $AnchorHash = Get-KlcAnchorHash -Seed $Message -Take 12 }
  $line = "KLC | $TraceId | $DurationMs | $ExitCode | $AnchorHash | $Message"
  Write-Output $line
}

function Test-KlcSchema {
  [CmdletBinding()]
  param([Parameter(Mandatory)][string]$Line)
  $re = '^[Kk][Ll][Cc]\s\|\s(?<trace>[^|]+)\s\|\s(?<dur>\d+)\s\|\s(?<code>-?\d+)\s\|\s(?<anchor>[0-9a-fA-F]{8,64})\s\|\s(?<msg>.+)$'
  return [bool]([regex]::IsMatch($Line,$re))
}

Export-ModuleMember -Function New-KlcTraceId, Get-KlcAnchorHash, Write-KlcLine, Test-KlcSchema

