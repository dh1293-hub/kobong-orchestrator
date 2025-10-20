
# APPLY IN SHELL
#requires -Version 7.0
param(
  [string]$Repo = 'D:\ChatGPT5_AI_Link\dosc\Kobong-Orchestrator-VIP\GitHub-Monitoring',
  [string]$Name = 'ghmon-ui-win',
  [int]$Port = 5199
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'

$ui = Join-Path $Repo 'containers\GitHub-Mon-ui'
docker build -t $Name -f (Join-Path $ui 'Dockerfile.windows') $ui

docker rm -f $Name 2>$null | Out-Null
docker run --name $Name -p ${Port}:5199 -v "$Repo\webui:C:\app\site" -e ROOT="C:\app\site" -d $Name

Write-Host "[OK] UI http://localhost:$Port/"
