# ops/canary-postrelease.ps1 — 릴리즈 직후 카나리 헬스 체크
param(
  [string[]]$Urls = @(
    "http://localhost:5181/health",
    "http://localhost:5182/health",
    "http://localhost:5183/health"
  )
)
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$fail = @()
foreach($u in $Urls){
  try{
    $r = Invoke-RestMethod -Uri $u -Method Get -TimeoutSec 5
    if(-not $r.ok){ throw "ok != true" }
    Write-Host "[OK] $u"
  } catch {
    Write-Host "[FAIL] $u : $($_.Exception.Message)" -ForegroundColor Red
    $fail += $u
  }
}
if($fail.Count -gt 0){
  # 콘솔 실패만 남기고 종료코드 1 → 워크플로우가 이슈 생성
  exit 1
}
