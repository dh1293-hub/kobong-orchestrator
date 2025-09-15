#requires -Version 7.0
param([string]$Url='http://localhost:8080/health',[string]$OutDir='docs/badges',[int]$TimeoutSec=10)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'

function New-BadgeSvg {
  param([string]$Label,[string]$Message,[string]$Color='green')
  # 최소형 정적 SVG (shields.io 의존 없이)
  $labelW = [Math]::Max(6,[int]($Label.Length*6.2))
  $msgW   = [Math]::Max(6,[int]($Message.Length*6.2))
  $w = $labelW + $msgW
  $x = $labelW
  $labelTxtX = [int]($labelW/2)
  $msgTxtX   = $labelW + [int]($msgW/2)
  @"
<svg xmlns="http://www.w3.org/2000/svg" width="$w" height="20" role="img" aria-label="$Label: $Message">
  <linearGradient id="s" x2="0" y2="100%">
    <stop offset="0" stop-color="#fff" stop-opacity=".7"/>
    <stop offset=".1" stop-opacity=".1"/>
    <stop offset=".9" stop-opacity=".3"/>
    <stop offset="1" stop-opacity=".5"/>
  </linearGradient>
  <mask id="m"><rect width="$w" height="20" rx="3" fill="#fff"/></mask>
  <g mask="url(#m)">
    <rect width="$labelW" height="20" fill="#555"/>
    <rect x="$x" width="$msgW" height="20" fill="$Color"/>
    <rect width="$w" height="20" fill="url(#s)"/>
  </g>
  <g fill="#fff" text-anchor="middle" font-family="Verdana,Geneva,DejaVu Sans,sans-serif" font-size="11">
    <text x="$labelTxtX" y="15">$Label</text>
    <text x="$msgTxtX"   y="15">$Message</text>
  </g>
</svg>
"@
}

# 1) 로컬 health-server 기동 (Node)
$node = (Get-Command node -ErrorAction Stop).Source
$repo = (git rev-parse --show-toplevel 2>$null) ?? (Get-Location).Path
$server = Join-Path $repo 'scripts/health-server.mjs'
if (-not (Test-Path $server)) { throw "health-server.mjs not found: $server" }

$env:PORT = ( [int]( [uri]$Url ).Port )
if (-not $env:PORT -or $env:PORT -eq 0) { $env:PORT = 8080 }

$proc = Start-Process -FilePath $node -ArgumentList "`"$server`"" -WorkingDirectory $repo -NoNewWindow -PassThru `
        -RedirectStandardOutput (Join-Path $repo 'logs\serve\badge-run.out.log') `
        -RedirectStandardError  (Join-Path $repo 'logs\serve\badge-run.err.log')

# 2) /health 대기
Add-Type -AssemblyName System.Net.Http
$hc=[System.Net.Http.HttpClient]::new()
$ok=$false; $code=0; $body=''; $start=Get-Date
try {
  for($i=0;$i -lt $TimeoutSec;$i++){
    Start-Sleep 1
    try {
      $res=$hc.GetAsync($Url).GetAwaiter().GetResult()
      $code=[int]$res.StatusCode; $body=$res.Content.ReadAsStringAsync().Result
      if ($code -eq 200 -and $body -match '"status"\s*:\s*"ok"' -and $body -match '"ready"\s*:\s*true'){ $ok=$true; break }
    } catch {}
  }
} finally { $hc.Dispose() }

# 3) 배지/리포트 생성
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
$status = if ($ok) { 'up' } else { 'down' }
$color  = if ($ok) { 'green' } else { 'red' }
$svg = New-BadgeSvg -Label 'health' -Message $status -Color $color
$svg | Set-Content -Path (Join-Path $OutDir 'health.svg') -Encoding utf8

# 상태 JSON
$report = [pscustomobject]@{
  timestamp = (Get-Date).ToString('o')
  url       = $Url
  http      = $code
  ok        = $ok
  body      = $body
}
$report | ConvertTo-Json -Depth 5 | Set-Content -Path (Join-Path $OutDir 'status.json') -Encoding utf8

# 4) 서버 정리
try { Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue } catch {}