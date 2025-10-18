\
# APPLY IN SHELL
#requires -PSEdition Core
#requires -Version 7.0
param(
  [string]$Root = 'D:\ChatGPT5_AI_Link\dosc\kobong-orchestrator-VIP\GitHub-Monitoring',
  [switch]$ConfirmApply
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

$Webui = Join-Path $Root 'webui'
$DestHtml = Join-Path $Webui 'GitHub-Monitoring-Min.html'
$DestCss  = Join-Path $Webui 'public\css\GitHub-Mon.css'
$DestJs   = Join-Path $Webui 'GitHub-Mon-bridge.js'

$Here = Split-Path -Parent $MyInvocation.MyCommand.Path
$SrcRoot = Split-Path -Parent (Split-Path -Parent $Here) # ../../
$SrcWebui = Join-Path $SrcRoot 'webui'
$SrcHtml = Join-Path $SrcWebui 'GitHub-Monitoring-Min.html'
$SrcCss  = Join-Path $SrcWebui 'public\css\GitHub-Mon.css'
$SrcJs   = Join-Path $SrcWebui 'GitHub-Mon-bridge.js'

Write-Host "== GHMON UI 배포(DRYRUN) =="
@($DestHtml,$DestCss,$DestJs) | ForEach-Object { Write-Host "  -> $_" }
if(-not $ConfirmApply){ Write-Host "DRYRUN 완료. 적용하려면:  `$env:CONFIRM_APPLY='true'; pwsh -File scripts/g5/ui/deploy-GitHub-Mon-ui.ps1 -Root '$Root'"; exit 10 }

New-Item -ItemType Directory -Force -Path $Webui, (Split-Path -Parent $DestCss) | Out-Null

$ts = Get-Date -Format 'yyyyMMdd-HHmmss'
foreach($pair in @(@($SrcHtml,$DestHtml),@($SrcCss,$DestCss),@($SrcJs,$DestJs))){
  $src,$dst = $pair[0],$pair[1]
  if(Test-Path $dst){ Copy-Item $dst "$dst.bak-$ts" -Force }
  Copy-Item $src $dst -Force
  Write-Host "[COPIED] $dst"
}

Write-Host "완료. 아래 파일을 브라우저로 여세요:"
Write-Host "  $DestHtml"
exit 0
