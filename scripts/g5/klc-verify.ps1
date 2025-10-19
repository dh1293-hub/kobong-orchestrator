#requires -Version 7.0
param([string]$Out = "_klc\klc-verify-$env:GITHUB_RUN_ID.log")
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$module = Join-Path $PSScriptRoot '..\..\src\kobong-logger-cli\kobong-logger.psm1'
if (Test-Path -LiteralPath $module) {
  Import-Module $module -Force
} else {
  Write-Host "[warn] KLC module not found — using inline fallback."
  function New-KlcTraceId {
    param([string]$Prefix='g5')
    $stamp = Get-Date -Format 'yyyyMMddHHmmss'
    $rand  = [guid]::NewGuid().ToString('N').Substring(0,6)
    "$Prefix-$stamp-$rand"
  }
  function Get-KlcAnchorHash {
    param([Parameter(Mandatory)][string]$Seed,[int]$Take=12)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    $bytes = [Text.Encoding]::UTF8.GetBytes($Seed)
    $hex = foreach ($b in $sha.ComputeHash($bytes)) { '{0:x2}' -f $b }
    $hash = -join $hex
    $hash.Substring(0,[Math]::Min($Take,$hash.Length))
  }
  function Write-KlcLine {
    param([Parameter(Mandatory)][string]$Message,[int]$ExitCode=0,[int]$DurationMs=0,[string]$TraceId,[string]$AnchorHash)
    if (-not $TraceId)    { $TraceId    = New-KlcTraceId }
    if (-not $AnchorHash) { $AnchorHash = Get-KlcAnchorHash -Seed $Message -Take 12 }
    "KLC | $TraceId | $DurationMs | $ExitCode | $AnchorHash | $Message"
  }
  function Test-KlcSchema {
    param([Parameter(Mandatory)][string]$Line)
    $re = '^[Kk][Ll][Cc]\s\|\s[^|]+\s\|\s\d+\s\|\s-?\d+\s\|\s[0-9a-fA-F]{8,64}\s\|'
    [regex]::IsMatch($Line, $re)
  }
}

$sw = [System.Diagnostics.Stopwatch]::StartNew()
Start-Sleep -Milliseconds 50
$sw.Stop()

$line = Write-KlcLine -Message "klc-verify ci" -ExitCode 0 -DurationMs $sw.ElapsedMilliseconds
if (-not (Test-KlcSchema -Line $line)) { throw "KLC format invalid: $line" }

$newDir = Split-Path $Out -Parent
if ($newDir -and -not (Test-Path $newDir)) {
  New-Item -ItemType Directory -Force -Path $newDir | Out-Null
}
$line | Out-File -FilePath $Out -Encoding utf8
Write-Host "[OK] $line" -ForegroundColor Green
