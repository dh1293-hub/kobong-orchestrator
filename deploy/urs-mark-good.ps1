param([string]$Base = "D:\ChatGPT5_AI_Link\dosc\Kobong-Orchestrator-VIP\_deploy")
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$CurrLnk = Join-Path $Base "current"
$GoodLnk = Join-Path $Base "good"
if(-not (Test-Path $CurrLnk)){ throw "current 링크가 없습니다.(배포/전환 먼저)" }
$curr = (Get-Item $CurrLnk).Target
if(Test-Path $GoodLnk){ Remove-Item $GoodLnk -Force }
New-Item -ItemType Junction -Path $GoodLnk -Target $curr | Out-Null
Write-Host "[OK] good → $curr"
