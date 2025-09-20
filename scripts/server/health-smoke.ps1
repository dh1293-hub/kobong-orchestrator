#requires -Version 7.0
param([string]$Base='http://127.0.0.1:8000')
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
function Hit([string]$path,[string]$method='GET',[object]$body=$null){
  $u = ($Base.TrimEnd('/')) + $path
  if ($method -eq 'GET') { Invoke-RestMethod -Uri $u -TimeoutSec 3 }
  else { Invoke-RestMethod -Uri $u -Method $method -ContentType 'application/json' -Body ($body|ConvertTo-Json -Compress) -TimeoutSec 3 }
}
$h = Hit '/healthz'; Write-Host ("healthz: " + (ConvertTo-Json $h -Compress))
$r = Hit '/api/v1/ping'; Write-Host ("ping: " + (ConvertTo-Json $r -Compress))
$e = Hit '/api/v1/echo' 'POST' @{text='hello';meta=@{a=1}}; Write-Host ("echo: " + (ConvertTo-Json $e -Compress))
$s = Hit '/api/v1/sum'  'POST' @{numbers=@(1,2,3.5)}; Write-Host ("sum: " + (ConvertTo-Json $s -Compress))