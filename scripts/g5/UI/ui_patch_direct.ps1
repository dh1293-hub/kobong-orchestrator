# APPLY IN SHELL
#requires -PSEdition Core
#requires -Version 7.0
param(
  [string]$Repo='D:\\ChatGPT5_AI_Link\\dosc\\kobong-orchestrator-VIP',
  [string]$HtmlRel='Orchestrator-Moniteoling\\webui\\Orchestrator-Moniteoling-Su.html',
  [string]$Frontend='ko-frontend' # nginx:1.27-alpine
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'

$here = Split-Path -Parent $PSCommandPath
$Html = Join-Path $Repo $HtmlRel
if(-not (Test-Path $Html)){ throw "HTML not found: $Html" }

# 현재 ko-frontend NGINX의 정적 문서 루트를 초기화 후 재업로드
Write-Host "[CLEAN] /usr/share/nginx/html on $Frontend"
docker exec $Frontend sh -lc 'rm -rf /usr/share/nginx/html/*'

# 필수 자산 동반 복사 (xterm, css, bridge, img)
$pub = Join-Path (Split-Path $Html) 'public'
if(Test-Path $pub){ docker cp $pub "$Frontend:/usr/share/nginx/html/public" }
docker cp $Html "$Frontend:/usr/share/nginx/html/index.html"

Write-Host "[DONE] UI replaced. → http://localhost:3000/"