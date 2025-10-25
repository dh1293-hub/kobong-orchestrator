# APPLY IN SHELL
#requires -PSEdition Core
#requires -Version 7.0
param(
  [string]$Repo='D:\ChatGPT5_AI_Link\dosc\kobong-orchestrator-VIP',
  [int]$Port=5183,
  [string]$Name='orch-shells-win'
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'

# 1) Windows Containers 모드 확인
$info = docker info 2>$null | Out-String
if($info -notmatch 'OSType:\s*windows'){ throw 'Docker is not in Windows Containers mode. Switch via Docker Desktop.' }

# 2) 빌드/기동
$dir = Join-Path $Repo 'containers/orch-shells'
Push-Location $dir
try {
  npm --version 1>$null 2>$null; if($LASTEXITCODE){ Write-Host '[HINT] Node/npm not found (optional for lockfile).' }
  docker build -t $Name -f Dockerfile.windows .
  docker rm -f $Name 2>$null | Out-Null
  docker run --name $Name -p ${Port}:5183 -d $Name
  Write-Host "[OK] Windows shells running → ws://localhost:$Port/api/orchmon/shell"
} finally { Pop-Location }
