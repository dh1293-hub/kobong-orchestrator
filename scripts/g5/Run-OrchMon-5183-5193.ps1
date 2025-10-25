[CmdletBinding()]
param(
  [switch]$Clean,   # 포트 청소만
  [switch]$Start,   # 서버 기동만
  [switch]$Open,    # 브라우저 오픈만
  [switch]$All      # 청소→기동→오픈 전체
)

# ==== 경로/설정 ====
$Repo   = 'D:\ChatGPT5_AI_Link\dosc\Kobong-Orchestrator-VIP'
$SrvDir = Join-Path $Repo 'Orchestrator-Monitoring\containers\orch-shells'
$SrvJs  = Join-Path $SrvDir 'server.js'
$Html   = Join-Path $Repo 'Orchestrator-Monitoring\webui\Orchestrator-Monitoring-Su.html'

$P_DEV  = 5183
$P_MOCK = 5193

# ==== 유틸 ====
function Get-NodePath{
  $cands = @(
    (Join-Path $env:ProgramFiles 'nodejs\node.exe'),
    (Join-Path ${env:ProgramFiles(x86)} 'nodejs\node.exe'),
    'node.exe','node'
  )
  foreach($p in $cands){
    $cmd = Get-Command $p -ErrorAction SilentlyContinue
    if($cmd){ return $cmd.Source }
  }
  return $null
}

function Test-PortUsed([int]$Port){
  (Get-NetTCPConnection -ErrorAction SilentlyContinue | Where-Object {
    $_.LocalPort -eq $Port -and $_.State -in 'Listen','Established'
  }).Count -gt 0
}

function Stop-ByPort([int]$Port){
  $pids = Get-NetTCPConnection -ErrorAction SilentlyContinue |
          Where-Object LocalPort -eq $Port |
          Select-Object -ExpandProperty OwningProcess -Unique
  foreach($procId in $pids){
    try{
      Stop-Process -Id $procId -Force -ErrorAction Stop
      Write-Host "[CLEAN] killed PID=$procId on :$Port" -ForegroundColor Yellow
    }catch{
      Write-Host "[CLEAN] kill fail PID=$procId on :$Port -> $($_.Exception.Message)" -ForegroundColor Red
    }
  }
}

function Wait-HttpOK($Url, [int]$TimeoutSec=60){
  $t0 = Get-Date
  do{
    try{
      $r = Invoke-WebRequest -UseBasicParsing -Uri $Url -TimeoutSec 5
      if($r.StatusCode -ge 200 -and $r.StatusCode -lt 300){ return $true }
    }catch{}
    Start-Sleep -Milliseconds 600
  } while((Get-Date) - $t0 -lt ([TimeSpan]::FromSeconds($TimeoutSec)))
  return $false
}

function Start-NodeServer([int]$Port,[string]$Mode){
  if(!(Test-Path -LiteralPath $SrvJs)){ throw "server.js not found: $SrvJs" }
  $node = Get-NodePath
  if(!$node){ throw "Node.exe not found. Install Node LTS to C:\Program Files\nodejs." }

  if(Test-PortUsed $Port){ Stop-ByPort $Port }

  Push-Location $SrvDir
  try{
    $env:PORT = "$Port"
    $env:MODE = $Mode
    $p = Start-Process -FilePath $node -ArgumentList @($SrvJs) -WindowStyle Hidden -PassThru
    Write-Host "[START] $Mode @ :$Port (PID=$($p.Id))" -ForegroundColor Cyan
  }finally{
    Pop-Location
  }
}

function Open-UI([int]$MockPort,[int]$DevPort){
  $h = "http://localhost:$MockPort/health"
  if(Wait-HttpOK $h 30){
    Write-Host "[HEALTH] :$MockPort OK" -ForegroundColor Green
  }else{
    Write-Host "[HEALTH] :$MockPort TIMEOUT (계속 진행)" -ForegroundColor DarkYellow
  }
  Start-Process "http://localhost:$MockPort/health"
  Start-Process "http://localhost:$MockPort/api/orchmon"
  Start-Process $Html
}

# ==== 실행 분기 ====
if(-not ($Clean -or $Start -or $Open -or $All)){ $All = $true }  # 기본은 전체

if($Clean -or $All){
  Write-Host "=== CLEAN :$P_DEV, :$P_MOCK ===" -ForegroundColor Yellow
  if(Test-PortUsed $P_DEV ){ Stop-ByPort $P_DEV  } else { Write-Host "[CLEAN] :$P_DEV free" }
  if(Test-PortUsed $P_MOCK){ Stop-ByPort $P_MOCK } else { Write-Host "[CLEAN] :$P_MOCK free" }
}

if($Start -or $All){
  Write-Host "=== START servers ===" -ForegroundColor Cyan
  try{ Start-NodeServer $P_MOCK 'MOCK' } catch{ Write-Host $_.Exception.Message -ForegroundColor Red }
  try{ Start-NodeServer $P_DEV  'DEV'  } catch{ Write-Host $_.Exception.Message -ForegroundColor DarkYellow }
}

if($Open -or $All){
  Write-Host "=== OPEN Health/API/UI ===" -ForegroundColor Green
  Open-UI $P_MOCK $P_DEV
}

Write-Host "[DONE] Run-OrchMon-5183-5193.ps1 finished."

