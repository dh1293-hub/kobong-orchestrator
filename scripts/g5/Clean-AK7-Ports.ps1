#requires -PSEdition Core
#requires -Version 7.0
<# 
 AK7 포트 청소 스크립트 (쉘 비종료, 안전)
 - 기본은 Preview(계획만 보여줌). -Force 지정 시에만 종료.
 - 현재 쉘(PID) 및 pwsh/powershell/conhost/explorer는 보호합니다.
#>
param(
  [switch]$DevOnly,
  [switch]$MockOnly,
  [switch]$Force
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Continue'

function Get-Owners([int]$Port) {
  Get-NetTCPConnection -LocalPort $Port -ErrorAction SilentlyContinue |
    Select-Object -ExpandProperty OwningProcess -Unique |
    ForEach-Object { Get-Process -Id $_ -ErrorAction SilentlyContinue }
}

$protected = @('pwsh','powershell','conhost','explorer')
$ports = @()
if (-not $MockOnly) { $ports += 5181 } # DEV
if (-not $DevOnly)  { $ports += 5191 } # MOCK

foreach ($port in $ports) {
  $procs = Get-Owners $port
  if (-not $procs) { Write-Host ("[PORT {0}] 비어 있음(청소 불필요)" -f $port) -ForegroundColor DarkGray; continue }

  foreach ($p in $procs) {
    $skip = ($p.Id -eq $PID) -or ($protected -contains $p.ProcessName)
    if ($skip) {
      Write-Host ("[PORT {0}] 보호 대상 건너뜀 → PID {1} ({2})" -f $port, $p.Id, $p.ProcessName) -ForegroundColor Yellow
      continue
    }
    if ($Force) {
      try { Stop-Process -Id $p.Id -Force -ErrorAction Stop; Write-Host ("[PORT {0}] 종료: PID {1}" -f $port,$p.Id) -ForegroundColor Green }
      catch { Write-Host ("[PORT {0}] 종료 실패 PID {1}: {2}" -f $port,$p.Id,$_.Exception.Message) -ForegroundColor Red }
    } else {
      Write-Host ("[PORT {0}] 종료 대상(미실행): PID {1} ({2})  → -Force 필요" -f $port, $p.Id, $p.ProcessName) -ForegroundColor Cyan
    }
  }
}
