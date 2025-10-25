# --- g5-start-servers.ps1 : 로그인 시 서버(컨테이너/로컬) 자동기동(있는 것만) ---
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Continue'

$root = Split-Path -Parent $PSScriptRoot
$logd = Join-Path $root 'automation_logs'
New-Item -ItemType Directory -Force -Path $logd | Out-Null
$log  = Join-Path $logd ("start_servers_" + (Get-Date -Format 'yyyyMMdd_HHmmss') + ".log")

function WriteLog($msg){ $msg | Tee-Object -FilePath $log -Append }

WriteLog "[INFO] start servers begin"

# A) Docker 컨테이너(있으면만)
try{
  if (Get-Command docker -ErrorAction SilentlyContinue) {
    $names = @('orchmon','ghmon','ak7') # 실제 사용 컨테이너명에 맞게 구성됨(없으면 스킵)
    foreach($n in $names){
      $exists = docker ps -a --format '{{.Names}}' | Where-Object { $_ -eq $n }
      if($exists){ docker start $n | Out-Null; WriteLog "[OK] docker start $n" }
    }
    # docker-compose가 있으면 up -d 시도(없으면 스킵)
    $dc = Join-Path $root 'docker-compose.yml'
    if(Test-Path $dc){ docker compose -f $dc up -d | Out-Null; WriteLog "[OK] docker compose up -d" }
  } else { WriteLog "[SKIP] docker not found" }
}catch{ WriteLog "[WARN] docker section: $($_.Exception.Message)" }

# B) 로컬 Node 서버(패키지 있으면만)
$apps = @(
  Join-Path $root 'Orchestrator-Monitoring',
  Join-Path $root 'GitHub-Monitoring',
  Join-Path $root 'AUTO-Kobong-Monitoring'
)
foreach($app in $apps){
  try{
    $pkg = Join-Path $app 'package.json'
    if(Test-Path $pkg){
      $cmd = "npm run start"
      # 새 콘솔로 비동기 실행(사용자 세션)
      Start-Process pwsh -ArgumentList "-NoProfile -WorkingDirectory `"$app`" -Command `"npm ci; $cmd`""
      WriteLog "[OK] node start → $app"
    } else {
      WriteLog "[SKIP] no package.json → $app"
    }
  }catch{ WriteLog "[WARN] node section($app): $($_.Exception.Message)" }
}

WriteLog "[DONE] start servers end"
