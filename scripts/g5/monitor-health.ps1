#requires -Version 7.0
param(
  [string]$Url = "http://localhost:8080/health",
  [int]$IntervalSec = 5,
  [int]$TimeoutSec = 3,
  [switch]$Once,
  [int]$DurationSec = 0,
  [string]$OutJson
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
function Write-Line([string]$msg,[ConsoleColor]$fg='Gray'){
  $t = (Get-Date).ToString('HH:mm:ss')
  Write-Host "[$t] $msg" -ForegroundColor $fg
}
$stopAt = if ($DurationSec -gt 0) { (Get-Date).AddSeconds($DurationSec) } else { [datetime]::MaxValue }
do {
  try {
    $resp = Invoke-WebRequest -Uri $Url -TimeoutSec $TimeoutSec -UseBasicParsing
    $ok = $resp.StatusCode -ge 200 -and $resp.StatusCode -lt 300
    $json = $null
    try { $json = $resp.Content | ConvertFrom-Json } catch { }
    $status = if ($ok) { '✅ OK' } else { '❌ FAIL' }
    $extra  = if ($json) { ($json | ConvertTo-Json -Compress) } else { ($resp.StatusDescription) }
    Write-Line "$status $Url :: $extra" ($ok ? 'Green' : 'Red')
    if ($OutJson) {
      $obj = [pscustomobject]@{
        timestamp = (Get-Date).ToString('o')
        url = $Url; ok = $ok; status = $resp.StatusCode; body = $resp.Content
      }
      $obj | ConvertTo-Json -Compress | Out-File $OutJson -Encoding utf8
    }
  } catch {
    Write-Line "❌ EXCEPTION $Url :: $($_.Exception.Message)" 'Red'
  }
  if ($Once) { break }
  Start-Sleep -Seconds $IntervalSec
} while ((Get-Date) -lt $stopAt)