param([switch]$Soft)  # ← 추가: 소프트 모드 스위치

$out = Join-Path (Get-Location) 'guard-findings.txt'

if ($bad.Count) {
  $bad | Sort-Object | Set-Content $out -Encoding UTF8

  if ($Soft) {
    # 소프트 모드: 경고만, 종료코드 0
    Write-Warning "보호 위반 감지(소프트 모드) → $out"
    $global:LASTEXITCODE = 0
    return
  }
  else {
    # 하드 모드(기본): 빨간 메시지 없이 종료코드 2로 실패
    Write-Host "보호 위반 감지 → $out" -ForegroundColor Red
    exit 2
  }
}
else {
  Write-Host "[OK] 보호 상태 양호" -ForegroundColor Green
  exit 0
}
