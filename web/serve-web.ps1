# APPLY IN SHELL
#requires -Version 7.0
param([int]$Port=8088,[int]$MaxTry=10)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'

function Test-PortFree([int]$p){
  -not (Get-NetTCPConnection -State Listen -LocalPort $p -ErrorAction SilentlyContinue)
}

# pick port (free) then bind with retry on HttpListener failure
$bind = $Port
for($i=0;$i -lt $MaxTry;$i++){ if (Test-PortFree $bind) { break }; $bind++ }

Add-Type -AssemblyName System.Net.HttpListener
$ln=[System.Net.HttpListener]::new()
for($i=0;$i -lt $MaxTry;$i++){
  try {
    $ln.Prefixes.Clear()
    $ln.Prefixes.Add("http://127.0.0.1:$bind/")
    $ln.Start()
    break
  } catch { $bind++; Start-Sleep -Milliseconds 50 }
}
if (-not $ln.IsListening){ throw "Failed to bind HttpListener after $MaxTry tries." }

Write-Host "[SERVE] http://127.0.0.1:$bind/  (Ctrl+C to stop)"

function Write-Json($ctx, $obj, [int]$code=200){
  $json = ($obj | ConvertTo-Json -Depth 10 -Compress)
  $ctx.Response.StatusCode = $code
  $ctx.Response.Headers['Content-Type'] = 'application/json; charset=utf-8'
  $ctx.Response.Headers['Access-Control-Allow-Origin'] = '*'
  $ctx.Response.Headers['Access-Control-Allow-Headers'] = 'Content-Type, Authorization'
  $bytes=[Text.Encoding]::UTF8.GetBytes($json)
  $ctx.Response.OutputStream.Write($bytes,0,$bytes.Length); $ctx.Response.Close()
}
function Write-Text($ctx, $text, [int]$code=200){
  $ctx.Response.StatusCode = $code
  $ctx.Response.Headers['Content-Type'] = 'text/plain; charset=utf-8'
  $ctx.Response.Headers['Access-Control-Allow-Origin'] = '*'
  $bytes=[Text.Encoding]::UTF8.GetBytes([string]$text)
  $ctx.Response.OutputStream.Write($bytes,0,$bytes.Length); $ctx.Response.Close()
}

$rand = [Random]::new()
try {
  while ($ln.IsListening) {
    $ctx  = $ln.GetContext()
    $path = $ctx.Request.Url.AbsolutePath.TrimEnd('/').ToLowerInvariant()

    if ($ctx.Request.HttpMethod -eq 'OPTIONS') {
      $ctx.Response.Headers['Access-Control-Allow-Origin'] = '*'
      $ctx.Response.Headers['Access-Control-Allow-Methods'] = 'GET, OPTIONS'
      $ctx.Response.Headers['Access-Control-Allow-Headers'] = 'Content-Type, Authorization'
      $ctx.Response.StatusCode = 204; $ctx.Response.Close(); continue
    }

    switch ($path) {
      ''          { Write-Text $ctx "OK" }
      '/health'   { Write-Json $ctx @{ status='ok'; time=(Get-Date).ToString('o') } }
      '/metrics/summary' {
        $t=[DateTimeOffset]::Now.ToUnixTimeSeconds()
        $lat=120 + $rand.Next(-30,40)
        $qps=[Math]::Round(3.0 + ($rand.NextDouble()*1.0),2)
        $back=[Math]::Max(0, 4 + $rand.Next(-2,4))
        $series = 0..29 | ForEach-Object { 120 + $rand.Next(-35,35) }
        Write-Json $ctx @{
          latency_p50=$lat; qps_1m=$qps; queue_backlog=$back;
          health=($(if($lat -lt 180 -and $back -lt 8){'OK'}else{'WARN'}));
          latency_series=$series; ts=$t
        }
      }
      '/github/checks/summary' {
        $t=[DateTimeOffset]::Now.ToUnixTimeSeconds()
        $prs= 4 + $rand.Next(0,3)
        $fail= if($rand.Next(0,10)-gt 7){ 1 } else { 0 }
        $age = $rand.Next(0,90)
        $sr  = 0..29 | ForEach-Object { [Math]::Round(0.92 + ($rand.NextDouble()*0.1 - 0.05),2) }
        Write-Json $ctx @{
          open_prs=$prs; failing_runs=$fail; last_sync_age_sec=$age; success_ratio_series=$sr; ts=$t
        }
      }
      default     { Write-Json $ctx @{ error='not_found'; path=$path } 404 }
    }
  }
}
finally {
  if ($ln.IsListening) { $ln.Stop() }
  $ln.Close()
  Write-Host "[SERVE] stopped."
}
