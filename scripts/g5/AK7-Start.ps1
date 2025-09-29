param([int]$Port=5192,[string]$UiRoot="")
Set-StrictMode -Version Latest
$ErrorActionPreference="Stop"
$PSDefaultParameterValues['*:Encoding']='utf8'
function Test-AK7([int]$p){ try{ (Invoke-WebRequest -UseBasicParsing -TimeoutSec 3 -Uri ("http://localhost:{0}/health" -f $p)).StatusCode -eq 200 }catch{ $false } }
$here=Split-Path -Parent $MyInvocation.MyCommand.Path
$mock=Join-Path $here "mock-api-ak7.ps1"
$Port=5192
if(-not (Test-AK7 $Port)){ Start-Process pwsh -WindowStyle Minimized -ArgumentList @('-NoLogo','-NoProfile','-ExecutionPolicy','Bypass','-File',$mock,'-Port',$Port.ToString(),'--uiRoot',$UiRoot) -WorkingDirectory $here | Out-Null;
  $dl=(Get-Date).AddSeconds(10); while(-not (Test-AK7 $Port) -and (Get-Date) -lt $dl){ Start-Sleep -Milliseconds 400 } }
# 브라우저는 열지 않음(사용자 요청)
