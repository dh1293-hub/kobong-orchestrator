#requires -Version 7.0
Set-StrictMode -Version Latest

function New-KlcTraceId {
  [CmdletBinding()]
  param([string]$Prefix='g5')
  $stamp = Get-Date -Format 'yyyyMMddHHmmss'
  $rand  = [guid]::NewGuid().ToString('N').Substring(0,6)
  "$Prefix-$stamp-$rand"
}

function Get-KlcAnchorHash {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$Seed,
    [int]$Take = 12
  )
  $seed2 = if ($env:GITHUB_SHA) { "$Seed`n$($env:GITHUB_SHA)" } else { $Seed }
  $sha = [System.Security.Cryptography.SHA256]::Create()
  $bytes = [Text.Encoding]::UTF8.GetBytes($seed2)
  $hashBytes = $sha.ComputeHash($bytes)
  $hex = foreach ($b in $hashBytes) { '{0:x2}' -f $b }
  $hash = -join $hex
  $len = [Math]::Min($Take, $hash.Length)
  $hash.Substring(0, $len)
}

function Write-KlcLine {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$Message,
    [int]$ExitCode = 0,
    [int]$DurationMs = 0,
    [string]$TraceId,
    [string]$AnchorHash
  )
  if (-not $TraceId)    { $TraceId    = New-KlcTraceId }
  if (-not $AnchorHash) { $AnchorHash = Get-KlcAnchorHash -Seed $Message -Take 12 }
  "KLC | $TraceId | $DurationMs | $ExitCode | $AnchorHash | $Message"
}

function Test-KlcSchema {
  [CmdletBinding()]
  param([Parameter(Mandatory)][string]$Line)
  $re = '^[Kk][Ll][Cc]\s\|\s[^|]+\s\|\s\d+\s\|\s-?\d+\s\|\s[0-9a-fA-F]{8,64}\s\|'
  [regex]::IsMatch($Line, $re)
}

Export-ModuleMember -Function New-KlcTraceId,Get-KlcAnchorHash,Write-KlcLine,Test-KlcSchema
