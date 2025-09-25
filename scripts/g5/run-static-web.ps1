#requires -Version 7.0
param([string]$Root,[int]$Port=5173)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$WebRoot = Join-Path $Root 'webui\public'
if (-not (Test-Path $WebRoot)) { throw "Web root not found: $WebRoot" }

# 포트 선택(5173 선호, 사용중이면 +1씩)
function Get-FreePort([int]$start){
  for($p=$start;$p -lt $start+50;$p++){
    try {
      $listener=[Net.Sockets.TcpListener]::new([Net.IPAddress]::Loopback,$p)
      $listener.Start(); $listener.Stop(); return $p
    } catch {}
  }
  throw "No free port near $start"
}
$Port = Get-FreePort -start $Port

# MIME 타입
$Mime = @{
  '.html'='text/html; charset=utf-8'; '.htm'='text/html; charset=utf-8'
  '.js'='application/javascript; charset=utf-8'; '.mjs'='application/javascript; charset=utf-8'
  '.css'='text/css; charset=utf-8'; '.map'='application/json; charset=utf-8'
  '.json'='application/json; charset=utf-8'; '.txt'='text/plain; charset=utf-8'
  '.svg'='image/svg+xml'; '.png'='image/png'; '.jpg'='image/jpeg'; '.jpeg'='image/jpeg'; '.ico'='image/x-icon'
}

# 간이 메트릭(폴백용)
function Get-FallbackMetrics {
@"
build_errors 0
open_prs 0
open_issues 0
latency_ms 842
"@
}

$listener=[Net.Sockets.TcpListener]::new([Net.IPAddress]::Loopback,$Port)
$listener.Start()
Write-Host "[OK] Static server on http://localhost:$Port/  (root=$WebRoot)"
try {
  # 기본 브라우저 열기
  try { Start-Process "http://localhost:$Port/status.html" | Out-Null } catch {}
  while ($true) {
    $client = $listener.AcceptTcpClient()
    [void][Threading.ThreadPool]::QueueUserWorkItem({
      param($tuple)
      $client=$tuple[0]; $WebRoot=$tuple[1]; $Mime=$tuple[2]
      try{
        $stream=$client.GetStream()
        $reader=[IO.StreamReader]::new($stream,[Text.Encoding]::ASCII,$true,1024,$true)
        $writer=[IO.StreamWriter]::new($stream,[Text.Encoding]::ASCII,1024,$true); $writer.NewLine="`r`n"; $writer.AutoFlush=$true
        $reqLine=$reader.ReadLine()
        if(-not $reqLine){ return }
        $parts=$reqLine.Split(' ')
        $method=$parts[0]; $url=$parts[1]
        # 헤더 consume
        while($reader.Peek() -ne -1){ $l=$reader.ReadLine(); if($l -eq ''){ break } }
        $path=[uri]::UnescapeDataString($url)
        if ($path -eq '/' -or [string]::IsNullOrWhiteSpace($path)) { $path='/status.html' }
        if ($path -eq '/metrics') {
          $body=[Text.Encoding]::UTF8.GetBytes((Get-FallbackMetrics))
          $writer.WriteLine('HTTP/1.1 200 OK')
          $writer.WriteLine('Content-Type: text/plain; charset=utf-8')
          $writer.WriteLine('Cache-Control: no-store')
          $writer.WriteLine('Content-Length: ' + $body.Length)
          $writer.WriteLine('Connection: close'); $writer.WriteLine(); $writer.Flush()
          $stream.Write($body,0,$body.Length); return
        }
        $safe = $path -replace '^\/*',''
        $full = Join-Path $WebRoot $safe
        $full = [IO.Path]::GetFullPath($full)
        $root = [IO.Path]::GetFullPath($WebRoot)
        if (-not $full.StartsWith($root)) { $full=$null }
        if ($full -and (Test-Path $full)) {
          $bytes=[IO.File]::ReadAllBytes($full)
          $ext=[IO.Path]::GetExtension($full).ToLowerInvariant()
          $ct=$Mime[$ext]; if(-not $ct){ $ct='application/octet-stream' }
          $writer.WriteLine('HTTP/1.1 200 OK')
          $writer.WriteLine('Content-Type: ' + $ct)
          if($ext -eq '.html' -or $ext -eq '.js' -or $ext -eq '.css'){ $writer.WriteLine('Cache-Control: no-store') }
          $writer.WriteLine('Content-Length: ' + $bytes.Length)
          $writer.WriteLine('Connection: close'); $writer.WriteLine(); $writer.Flush()
          $stream.Write($bytes,0,$bytes.Length)
        } else {
          $msg=[Text.Encoding]::UTF8.GetBytes('<h1>404 Not Found</h1>')
          $writer.WriteLine('HTTP/1.1 404 Not Found')
          $writer.WriteLine('Content-Type: text/html; charset=utf-8')
          $writer.WriteLine('Content-Length: ' + $msg.Length)
          $writer.WriteLine('Connection: close'); $writer.WriteLine(); $writer.Flush()
          $stream.Write($msg,0,$msg.Length)
        }
      } catch {
      } finally {
        try{ $client.Close() }catch{}
      }
    }, @($client,$WebRoot,$Mime)) | Out-Null
  }
}
finally { try{ $listener.Stop() }catch{} }