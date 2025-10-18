param(
  [ValidateSet("prev","good","tag")][string]$Mode = "prev",
  [string]$Tag,                                   # Mode=tag 일 때 필수
  [string]$Base = "D:\ChatGPT5_AI_Link\dosc\Kobong-Orchestrator-VIP\_deploy"
)
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RelRoot = Join-Path $Base "releases"
$CurrLnk = Join-Path $Base "current"
$PrevLnk = Join-Path $Base "prev"
$GoodLnk = Join-Path $Base "good"

function Set-Junction($link,$target){
  if(Test-Path $link){ Remove-Item $link -Force }
  New-Item -ItemType Junction -Path $link -Target $target | Out-Null
}

switch($Mode){
  "prev" {
    if(-not (Test-Path $PrevLnk)){ throw "prev 링크가 없습니다." }
    $target = (Get-Item $PrevLnk).Target
  }
  "good" {
    if(-not (Test-Path $GoodLnk)){ throw "good 링크가 없습니다.(urs-mark-good.ps1 실행 필요)" }
    $target = (Get-Item $GoodLnk).Target
  }
  "tag"  {
    if(-not $Tag){ throw "-Tag 를 지정하세요." }
    $target = Join-Path $RelRoot $Tag
    if(-not (Test-Path $target)){ throw "해당 태그 디렉터리가 없습니다: $target" }
  }
}

# curr → prev 업데이트 후 전환
if(Test-Path $CurrLnk){
  $curr = (Get-Item $CurrLnk).Target
  Set-Junction -link $PrevLnk -target $curr
}
Set-Junction -link $CurrLnk -target $target

try { pwsh -NoProfile -File "D:\ChatGPT5_AI_Link\dosc\Kobong-Orchestrator-VIP\scripts\g5\verify-protection.ps1" } catch {}
try { pwsh -NoProfile -File "D:\ChatGPT5_AI_Link\dosc\Kobong-Orchestrator-VIP\scripts\g5\health-smoke.ps1" } catch {}

Write-Host "[OK] rolled to: $target"
