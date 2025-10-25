#requires -Version 7.0
param([string]$Root='D:\ChatGPT5_AI_Link\dosc\kobong-orchestrator',[int]$PreferredPort=5173)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$WebRoot = Join-Path $Root 'webui\public'
if (!(Test-Path $WebRoot)) { throw "Web root not found: $WebRoot" }

# pick free port
$Port=$null
for($p=$PreferredPort;$p -lt $PreferredPort+50;$p++){
  try{ $tl=[Net.Sockets.TcpListener]::new([Net.IPAddress]::Loopback,$p); $tl.Start(); $tl.Stop(); $Port=$p; break }catch{}
}
if(-not $Port){ throw "No free port near $PreferredPort" }

# mime
$Mime=@{
  '.html'='text/html; charset=utf-8'; '.htm'='text/html; charset=utf-8'
  '.js'='application/javascript; charset=utf-8'; '.mjs'='application/javascript; charset=utf-8'
  '.css'='text/css; charset=utf-8'; '.map'='application/json; charset=utf-8'
  '.json'='application/json; charset=utf-8'; '.txt'='text/plain; charset=utf-8'
  '.svg'='image/svg+xml'; '.png'='image/png'; '.jpg'='image/jpeg'; '.jpeg'='image/jpeg'; '.ico'='image/x-icon'
}
function Get-FallbackMetrics {
@"
build_errors 0
open_prs 0
open_issues 0
latency_ms 842
"@
}
function Get-SafeFullPath([string]$Root,[string]$Rel){
  $joined = (Join-Path -Path $Root -ChildPath $Rel)
  $full   = [IO.Path]::GetFullPath($joined)
  $root   = [IO.Path]::GetFullPath($Root)
  if (-not $full.StartsWith($root,[StringComparison]::OrdinalIgnoreCase)) { return $null }
  return $full
}

$listener=[Net.Sockets.TcpListener]::new([Net.IPAddress]::Loopback,$Port)
$listener.Start()
Write-Host ""
Write-Host "============================================="
Write-Host "[OK] Serving $WebRoot"
Write-Host "[OPEN] http://localhost:$Port/index.html"
Write-Host "[OPEN] http://localhost:$Port/status.html"
Write-Host "=============================================`n"
try { Start-Process "http://localhost:$Port/status.html" | Out-Null } catch {}

try {
  while ($true) {
    $client = $listener.AcceptTcpClient()
    try{
      $stream=$client.GetStream()
      $reader=[IO.StreamReader]::new($stream,[Text.Encoding]::ASCII,$true,1024,$true)
      $writer=[IO.StreamWriter]::new($stream,[Text.Encoding]::ASCII,1024,$true); $writer.NewLine="`r`n"; $writer.AutoFlush=$true
      $reqLine=$reader.ReadLine(); if(-not $reqLine){ continue }
      $parts=$reqLine.Split(' ')
      $method=$parts[0]; $rawUrl=$parts[1]
      while($reader.Peek() -ne -1){ $l=$reader.ReadLine(); if($l -eq ''){ break } }

      try { $uri=[Uri]("http://localhost$rawUrl") } catch { $uri=$null }
      $path = ($uri ? $uri.AbsolutePath : $rawUrl)
      if ([string]::IsNullOrWhiteSpace($path) -or $path -eq '/') { $path='/index.html' }

      if ($path -eq '/metrics') {
        $body=[Text.Encoding]::UTF8.GetBytes((Get-FallbackMetrics))
        $writer.WriteLine('HTTP/1.1 200 OK')
        $writer.WriteLine('Content-Type: text/plain; charset=utf-8')
        $writer.WriteLine('Cache-Control: no-store')
        $writer.WriteLine('Content-Length: ' + $body.Length)
        $writer.WriteLine('Connection: close'); $writer.WriteLine(); $writer.Flush()
        $stream.Write($body,0,$body.Length); continue
      }

      $rel = ($path -replace '^[\\/]+','')
      $full = Get-SafeFullPath -Root $WebRoot -Rel $rel
      if (-not $full -or -not (Test-Path $full)) {
        $msg=[Text.Encoding]::UTF8.GetBytes('{"ok":false,"status":404,"path":"'+$path+'"}')
        $writer.WriteLine('HTTP/1.1 404 Not Found')
        $writer.WriteLine('Content-Type: application/json; charset=utf-8')
        $writer.WriteLine('Content-Length: ' + $msg.Length)
        $writer.WriteLine('Connection: close'); $writer.WriteLine(); $writer.Flush()
        $stream.Write($msg,0,$msg.Length); continue
      }

      $bytes=[IO.File]::ReadAllBytes($full)
      $ext=[IO.Path]::GetExtension($full).ToLowerInvariant()
      $ct=$Mime[$ext]; if(-not $ct){ $ct='application/octet-stream' }
      $writer.WriteLine('HTTP/1.1 200 OK')
      $writer.WriteLine('Content-Type: ' + $ct)
      if ($ext -in @('.html','.js','.css')) { $writer.WriteLine('Cache-Control: no-store') }
      $writer.WriteLine('Content-Length: ' + $bytes.Length)
      $writer.WriteLine('Connection: close'); $writer.WriteLine(); $writer.Flush()
      $stream.Write($bytes,0,$bytes.Length)
    } catch {} finally { try{ $client.Close() }catch{} }
  }
}
finally { try{ $listener.Stop() }catch{} }