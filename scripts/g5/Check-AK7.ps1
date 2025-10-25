#requires -Version 7
$ErrorActionPreference='SilentlyContinue'
$ports=@{ 'AK7-DEV'=5181; 'AK7-MOCK'=5191 }

"== /health"
$ports.Keys | % {
  $p=$ports[$_]
  try{ $r=Invoke-WebRequest "http://127.0.0.1:$p/health" -TimeoutSec 3 -UseBasicParsing; "{0,-8} {1} => {2}" -f $_,$p,$r.StatusCode }
  catch{ "{0,-8} {1} => X" -f $_,$p }
}

"== /timeline (SSE 헤더만)"
Add-Type -AssemblyName System.Net.Http
$hc=New-Object System.Net.Http.HttpClient; $hc.Timeout=[TimeSpan]::FromSeconds(2)
$ports.Keys | % {
  $p=$ports[$_]
  try{ $req=New-Object System.Net.Http.HttpRequestMessage 'GET',"http://127.0.0.1:$p/timeline"
       $req.Headers.Accept.ParseAdd('text/event-stream')
       $resp=$hc.SendAsync($req,[System.Net.Http.HttpCompletionOption]::ResponseHeadersRead).Result
       "{0,-8} {1} => {2} {3}" -f $_,$p,[int]$resp.StatusCode,($resp.Content.Headers.ContentType) }
  catch{ "{0,-8} {1} => X" -f $_,$p }
}
$hc.Dispose()
