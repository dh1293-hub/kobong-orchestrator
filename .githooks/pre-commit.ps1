#requires -PSEdition Core
#requires -Version 7.0
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

try {
  $repo = (git rev-parse --show-toplevel 2>$null)
  if (-not $repo) { $repo = Split-Path -Parent $PSCommandPath }

  # 스테이지에 올라간 파일 목록 (널 구분자로 안전 처리)
  $raw = & git -C $repo diff --cached --name-only -z 2>$null
  $files = @()
  if ($raw) { $files = ($raw -split "`0") | Where-Object { $_ } }

  # (선택) 간단 경고만, 커밋은 절대 막지 않음
  foreach ($f in $files) {
    if ($f -match '\.ps1$') {
      $full = Join-Path $repo $f
      if (Test-Path -LiteralPath $full) {
        try {
          $null = Get-Content -LiteralPath $full -Raw -Encoding UTF8
        } catch {
          Write-Warning "[pre-commit] 읽기 실패: $f — $($_.Exception.Message)"
        }
      }
    }
  }

  Write-Host "[pre-commit] OK (non-blocking)" -ForegroundColor Green
  exit 0
}
catch {
  Write-Warning "[pre-commit] 훅 오류 발생했지만 커밋은 통과시킵니다: $($_.Exception.Message)"
  exit 0
}
