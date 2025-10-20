
# APPLY IN SHELL
#requires -Version 7.0
param(
  [string]$Repo = 'D:\ChatGPT5_AI_Link\dosc\Kobong-Orchestrator-VIP\GitHub-Monitoring',
  [string]$Name = 'ghmon-shells-win',
  [int]$Port = 5182
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'

$dir = Join-Path $Repo 'containers\GitHub-Mon-shells'
docker build -t $Name -f (Join-Path $dir 'Dockerfile.windows') $dir

docker rm -f $Name 2>$null | Out-Null
docker run --name $Name -p ${Port}:5182 -d $Name

Invoke-RestMethod "http://localhost:$Port/health" -TimeoutSec 5 | Out-Host
Write-Host "[OK] GHMON shells on :$Port"
