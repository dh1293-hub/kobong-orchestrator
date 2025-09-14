#requires -Version 7.0
param([string]$Url='http://localhost:8080/health',[int]$TimeoutSec=3)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Net.Http
$hc=[System.Net.Http.HttpClient]::new()
try {
  $cts=[System.Threading.CancellationTokenSource]::new()
  $cts.CancelAfter([TimeSpan]::FromSeconds($TimeoutSec))
  $res=$hc.GetAsync($Url,$cts.Token).GetAwaiter().GetResult()
  $code=[int]$res.StatusCode
  $body=$res.Content.ReadAsStringAsync().Result
  if ($code -eq 200 -and $body -match '"status"\s*:\s*"ok"' -and $body -match '"ready"\s*:\s*true') { exit 0 }
  exit 10
} catch { exit 12 } finally { $hc.Dispose() }