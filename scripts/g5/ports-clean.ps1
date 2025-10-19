# ports-clean.ps1 — 5181/5182/5183/5191/5193/5199 LISTEN 프로세스 강제 종료(관리자 권한 권장)
param([int[]]$Ports=@(5181,5182,5183,5191,5193,5199))
$cons = Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue | Where-Object { $_.LocalPort -in $Ports }
$cons | Sort-Object LocalPort -Unique | ForEach-Object {
  try {
    if ($_.OwningProcess) { Stop-Process -Id $_.OwningProcess -Force -ErrorAction Stop; Write-Host "[KILL] Port $($_.LocalPort) PID=$($_.OwningProcess)" -ForegroundColor Yellow }
  } catch { Write-Warning "Fail kill port $($_.LocalPort): $($_.Exception.Message)" }
}
