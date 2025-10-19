# autostart-verify.ps1 — 부팅 후 자동 보호/헬스 스모크(+로그)
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$proj = Split-Path -Parent $root
$logd = Join-Path $proj 'automation_logs'
New-Item -ItemType Directory -Force -Path $logd | Out-Null
$ts = Get-Date -Format "yyyyMMdd_HHmmss"
$log = Join-Path $logd "autostart_$ts.log"
try {
  pwsh -NoProfile -File "$root\install-guards.ps1"   *>> $log
  pwsh -NoProfile -File "$root\verify-protection.ps1" *>> $log
  pwsh -NoProfile -File "$root\health-smoke.ps1"      *>> $log
  Write-Host "[OK] Autostart verify done → $log" -ForegroundColor Green
} catch { Write-Host "[FAIL] Autostart: $($_.Exception.Message)" -ForegroundColor Red }
