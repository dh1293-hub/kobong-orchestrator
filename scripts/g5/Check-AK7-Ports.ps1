#requires -PSEdition Core
#requires -Version 7.0
<# 
 AK7 포트 점검 스크립트 (쉘 비종료, 안전)
 - 포트 상태와 /health 결과만 출력합니다.
 - 절대 Exit/Stop 하지 않습니다.
#>
param(
  [switch]$DevOnly,
  [switch]$MockOnly,
  [switch]$NoHealth,
  [string]$Root = 'D:\ChatGPT5_AI_Link\dosc\Kobong-Orchestrator-VIP\AUTO-Kobong-Monitoring'
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Continue'

function Get-Owners([int]$Port) {
  Get-NetTCPConnection -LocalPort $Port -ErrorAction SilentlyContinue |
    Select-Object -ExpandProperty OwningProcess -Unique |
    ForEach-Object { Get-Process -Id $_ -ErrorAction SilentlyContinue }
}

$ports = @()
if (-not $MockOnly) { $ports += 5181 } # DEV
if (-not $DevOnly)  { $ports += 5191 } # MOCK

foreach ($port in $ports) {
  $procs = Get-Owners $port
  if ($procs) {
    Write-Host ("[PORT {0}] LISTEN: PID {1}  PROC {2}" -f $port, ($procs.Id -join ', '), ($procs.ProcessName -join ', ')) -ForegroundColor Cyan
  } else {
    Write-Host ("[PORT {0}] (no listener)" -f $port) -ForegroundColor Yellow
  }

  if (-not $NoHealth) {
    try {
      $health = Invoke-RestMethod -Uri ("http://localhost:{0}/health" -f $port) -TimeoutSec 2 -Method GET
      if ($health.ok -eq $true) { Write-Host "  → /health OK" -ForegroundColor Green }
      else { Write-Host "  → /health NG(JSON mismatch)" -ForegroundColor Red }
    } catch {
      Write-Host ("  → /health NG({0})" -f $_.Exception.Message) -ForegroundColor Red
    }
  }
}
