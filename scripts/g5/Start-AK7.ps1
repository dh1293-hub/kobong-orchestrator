#requires -PSEdition Core
#requires -Version 7.0
<#
 Start-AK7.fixed.ps1 — AK7 서버 기동 (쉘 비종료, 안전 로깅 분리)
 - 5181(DEV), 5191(MOCK) 기동 후 /health 확인
 - RedirectStandardOutput/RedirectStandardError 서로 다른 파일 사용
 - Node 경로는 $node.Path 사용
 - 완료되면 AUTO-Kobong-Monitoring.html(있으면) 또는 ak7-monitoring.html 열기
#>
param(
  [switch]$DevOnly,
  [switch]$MockOnly,
  [int]$Retries = 20,
  [bool]$OpenUI = $True,
  [string]$Root = 'D:\ChatGPT5_AI_Link\dosc\Kobong-Orchestrator-VIP\AUTO-Kobong-Monitoring'
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Continue'

$serverDir = Join-Path $Root 'containers\ak7-shells'
$serverJs  = Join-Path $serverDir 'server.js'
if (-not (Test-Path $serverJs)) { Write-Host ("[ERR] server.js 없음: {0}" -f $serverJs) -ForegroundColor Red; return }
$node = Get-Command node -ErrorAction SilentlyContinue
if (-not $node) { Write-Host "[ERR] Node 미설치. 설치 후 재시도하세요." -ForegroundColor Red; return }

function Start-One([int]$Port){
  $logDir = Join-Path $Root 'logs'
  New-Item -ItemType Directory -Force -Path $logDir | Out-Null
  $ts   = Get-Date -Format 'yyyyMMdd-HHmmss'
  $logO = Join-Path $logDir ("ak7_start_{0}_{1}.out.log" -f $Port,$ts)
  $logE = Join-Path $logDir ("ak7_start_{0}_{1}.err.log" -f $Port,$ts)
  $args = @("server.js","--port",$Port)

  try {
    $p = Start-Process -FilePath $node.Path -ArgumentList $args -WorkingDirectory $serverDir `
          -PassThru -WindowStyle Hidden -RedirectStandardOutput $logO -RedirectStandardError $logE
    Write-Host ("[PORT {0}] PID {1} 기동, 로그 {2} / {3}" -f $Port, $p.Id, $logO, $logE) -ForegroundColor Cyan
  } catch {
    Write-Host ("[ERR] Start-Process 실패(포트 {0}): {1}" -f $Port, $_.Exception.Message) -ForegroundColor Red
    return
  }

  $ok=$false
  for($i=1; $i -le $Retries; $i++){
    Start-Sleep 1
    try {
      $r = Invoke-RestMethod -Uri ("http://localhost:{0}/health" -f $Port) -TimeoutSec 2
      if ($r.ok -eq $true) { $ok = $true; break }
    } catch {}
  }
  if ($ok) { Write-Host ("[PORT {0}] /health OK" -f $Port) -ForegroundColor Green }
  else     { Write-Host ("[PORT {0}] /health 실패(로그 확인: {1})" -f $Port, $logE) -ForegroundColor Yellow }
}

$ports = @()
if (-not $MockOnly) { $ports += 5181 } # DEV
if (-not $DevOnly)  { $ports += 5191 } # MOCK

foreach($port in $ports){ Start-One $port }

if ($OpenUI) {
  $su = Join-Path $Root 'webui\AUTO-Kobong-Monitoring.html'
  $ak = Join-Path $Root 'webui\ak7-monitoring.html'
  $open = if (Test-Path $su) { $su } elseif (Test-Path $ak) { $ak } else { $null }
  if ($open) {
    Write-Host ("[UI] Opening: {0}" -f $open) -ForegroundColor Magenta
    Start-Process $open | Out-Null
  } else {
    Write-Host "[UI] 열 파일을 찾지 못했습니다 (AUTO-Kobong-Monitoring.html / ak7-monitoring.html)" -ForegroundColor Yellow
  }
}
