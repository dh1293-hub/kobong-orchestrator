#requires -Version 7
$ErrorActionPreference='SilentlyContinue'

$ports = @{
  'AK7-DEV'  = 5181
  'AK7-MOCK' = 5191
  'ORCH-DEV' = 5183
  'ORCH-MOCK'= 5193
}

"== /health"
foreach($k in $ports.Keys){
  try{
    $r=Invoke-WebRequest -Uri ("http://127.0.0.1:{0}/health" -f $ports[$k]) -TimeoutSec 3 -UseBasicParsing
    "{0,-10} {1} => {2}" -f $k,$ports[$k],$r.StatusCode
  }catch{ "{0,-10} {1} => X" -f $k,$ports[$k] }
}

"== /timeline (SSE 헤더만)"
Add-Type -AssemblyName System.Net.Http
$hc = New-Object System.Net.Http.HttpClient; $hc.Timeout=[TimeSpan]::FromSeconds(2)
foreach($k in $ports.Keys){
  try{
    $u="http://127.0.0.1:{0}/timeline" -f $ports[$k]
    $req=New-Object System.Net.Http.HttpRequestMessage 'GET',$u
    $req.Headers.Accept.ParseAdd('text/event-stream')
    $resp = $hc.SendAsync($req,[System.Net.Http.HttpCompletionOption]::ResponseHeadersRead).Result
    "{0,-10} {1} => {2} {3}" -f $k,$ports[$k],[int]$resp.StatusCode,($resp.Content.Headers.ContentType)
  }catch{ "{0,-10} {1} => X" -f $k,$ports[$k] }
}
$hc.Dispose()
