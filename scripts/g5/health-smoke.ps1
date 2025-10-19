# health-smoke.ps1 — 3모듈 헬스 체크(PS7)
$ports = @(5181,5182,5183)  # AK7, GHMON, ORCHMON
foreach($p in $ports){
  try{
    $u = "http://localhost:$p/health"
    $r = Invoke-RestMethod -Uri $u -TimeoutSec 5 -ErrorAction Stop
    if($r.ok -eq $true){ Write-Host "[OK] $u" -ForegroundColor Green }
    else { Write-Host "[WARN] $u → unexpected" -ForegroundColor Yellow }
  } catch {
    Write-Host "[FAIL] http://localhost:$p/health → $($_.Exception.Message)" -ForegroundColor Red
  }
}
