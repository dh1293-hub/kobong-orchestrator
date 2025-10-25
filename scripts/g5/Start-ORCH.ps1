#requires -Version 7
param([switch]$Dev, [switch]$Mock)
$ErrorActionPreference='Stop'

$ROOT='D:\ChatGPT5_AI_Link\dosc\Kobong-Orchestrator-VIP'
$DIR = Join-Path $ROOT 'Orchestrator-Monitoring\containers\orch-shells'
if(!(Test-Path $DIR)){ throw "경로 없음: $DIR" }

$node = (Get-Command node -ErrorAction SilentlyContinue).Source; if(-not $node){ $node='C:\Program Files\nodejs\node.exe' }
if(!(Test-Path $node)){ throw "node 경로 확인 필요: $node" }

$LOG = Join-Path $ROOT 'scripts\g5\logs'; New-Item -ItemType Directory -Force -Path $LOG | Out-Null
$stamp=Get-Date -Format 'yyyyMMdd_HHmmss'

$targets=@()
if($Dev -or (-not $Dev -and -not $Mock)){ $targets += @{ name='ORCH-DEV';  exe='server.js'; port=5183 } }
if($Mock){                                 $targets += @{ name='ORCH-MOCK'; exe='server.js'; port=5193 } }

foreach($t in $targets){
  Get-NetTCPConnection -State Listen -LocalPort $t.port -ErrorAction SilentlyContinue |
    Select -Expand OwningProcess -Unique | % { try{ Stop-Process -Id $_ -Force }catch{} }

  $out=Join-Path $LOG ("{0}_{1}.out.log" -f $t.name,$stamp)
  $err=Join-Path $LOG ("{0}_{1}.err.log" -f $t.name,$stamp)

  Start-Process -FilePath $node `
    -WorkingDirectory $DIR `
    -ArgumentList $t.exe `
    -WindowStyle Hidden `
    -Environment @{ PORT="$($t.port)" } `
    -RedirectStandardOutput $out `
    -RedirectStandardError  $err | Out-Null
}
"✅ ORCH started: " + ($targets | % { "$($_.name)@$_(port)" } | Out-String)
"📜 logs: $LOG"
