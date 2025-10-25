#requires -Version 7
$ErrorActionPreference='Stop'

# 루트/경로
$ROOT = 'D:\ChatGPT5_AI_Link\dosc\Kobong-Orchestrator-VIP'
$AK7  = Join-Path $ROOT 'AUTO-Kobong-Monitoring\containers\ak7-shells'
$ORC  = Join-Path $ROOT 'Orchestrator-Monitoring\containers\orch-shells'
$LOG  = Join-Path $ROOT 'scripts\g5\logs'
New-Item -ItemType Directory -Force -Path $LOG | Out-Null

# Node 경로
$node = (Get-Command node -ErrorAction SilentlyContinue).Source
if(-not $node){ $node = 'C:\Program Files\nodejs\node.exe' }
if(!(Test-Path $node)){ throw "node 경로 확인 필요: $node" }

# 타겟 포트
$targets = @(
  @{ name='AK7-DEV';  dir=$AK7; exe='server.js';     port=5181 },
  @{ name='AK7-MOCK'; dir=$AK7; exe='server-ak7.js'; port=5191 },
  @{ name='ORCH-DEV'; dir=$ORC; exe='server.js';     port=5183 },
  @{ name='ORCH-MOCK';dir=$ORC; exe='server.js';     port=5193 }
)

# 포트 점유 프로세스 정리(해당 포트만)
foreach($t in $targets){
  Get-NetTCPConnection -State Listen -LocalPort $t.port -ErrorAction SilentlyContinue |
    Select-Object -ExpandProperty OwningProcess -Unique |
    ForEach-Object { try{ Stop-Process -Id $_ -Force }catch{} }
}

# 기동
$stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
foreach($t in $targets){
  if(!(Test-Path $t.dir)){ throw "경로 없음: $($t.dir)" }
  $out = Join-Path $LOG ("{0}_{1}.out.log" -f $t.name,$stamp)
  $err = Join-Path $LOG ("{0}_{1}.err.log" -f $t.name,$stamp)

  Start-Process -FilePath $node `
    -WorkingDirectory $t.dir `
    -ArgumentList $t.exe `
    -WindowStyle Hidden `
    -Environment @{ PORT = "$($t.port)" } `
    -RedirectStandardOutput $out `
    -RedirectStandardError  $err | Out-Null
}

"✅ started: 5181(AK7-DEV), 5191(AK7-MOCK), 5183(ORCH-DEV), 5193(ORCH-MOCK)"
"📜 logs: $LOG"
