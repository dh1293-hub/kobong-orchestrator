# deploy-postswitch.ps1 — 배포 전환 이후의 훅(선택적)
# - 존재하는 훅만 실행. 실패해도 전체 배포 중단 안 함.
# - 필요 시 아래 블록의 경로/이름만 실제 환경으로 바꾸세요.

Write-Host "[INFO] Post-switch hook 시작" -ForegroundColor Cyan

# (A) Docker Windows 컨테이너 재기동(있으면)
try {
  $names = @('orchmon','ghmon','ak7')  # 컨테이너 이름 예시
  foreach($n in $names){
    $c = (docker ps -a --format '{{.Names}}' | Where-Object { $_ -eq $n })
    if($c){ docker restart $n | Out-Null; Write-Host "[OK] docker restart $n" -ForegroundColor Green }
  }
} catch { Write-Host "[WARN] Docker 재기동 스킵: $($_.Exception.Message)" -ForegroundColor Yellow }

# (B) Windows 서비스 재시작(있으면)
try {
  $svcs = @('Kobong.Orch','Kobong.Ghmon','Kobong.Ak7')
  foreach($s in $svcs){
    if(Get-Service -Name $s -ErrorAction SilentlyContinue){
      Restart-Service -Name $s -Force -ErrorAction Stop
      Write-Host "[OK] service restart $s" -ForegroundColor Green
    }
  }
} catch { Write-Host "[WARN] Service 재시작 스킵: $($_.Exception.Message)" -ForegroundColor Yellow }

# (C) 커스텀 스크립트(있으면)
$custom = @(
  'ops\restart-orch.ps1',
  'ops\restart-ghmon.ps1',
  'ops\restart-ak7.ps1'
)
foreach($p in $custom){
  $abs = Join-Path (Split-Path $PSScriptRoot -Parent) $p
  if(Test-Path $abs){
    try { pwsh -NoProfile -File $abs; Write-Host "[OK] ran $p" -ForegroundColor Green }
    catch { Write-Host "[WARN] $p 실패: $($_.Exception.Message)" -ForegroundColor Yellow }
  }
}

Write-Host "[INFO] Post-switch hook 종료" -ForegroundColor Cyan
