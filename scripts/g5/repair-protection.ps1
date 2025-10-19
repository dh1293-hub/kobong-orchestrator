# repair-protection.ps1 — ReadOnly/ACL 재적용(PS7)
param(
  [string]$FindingsPath = ".\guard-findings.txt"
)

if (-not (Test-Path $FindingsPath)) { Write-Error "파일 없음: $FindingsPath"; exit 1 }

$targets = Get-Content $FindingsPath -Encoding UTF8 |
  ForEach-Object {
    if ($_ -match 'ReadOnly 누락:\s+(?<p>.+)$') { $Matches['p'] }
    elseif ($_ -match '최근 수정됨.*?:\s+(?<p>.+?)\s+\[') { $Matches['p'] }
  } | Where-Object { $_ } | Sort-Object -Unique

if (-not $targets) { Write-Host "[OK] 복구할 대상 없음"; exit 0 }

foreach ($path in $targets) {
  try {
    if (Test-Path $path -PathType Leaf) {
      attrib +R $path        # ReadOnly 속성 다시 적용
      & icacls $path /grant:r "Users:RX" /c | Out-Null
      Write-Host "[FIX] $path" -ForegroundColor Green
    }
  } catch {
    Write-Warning "복구 실패: $path → $($_.Exception.Message)"
  }
}

Write-Host "[DONE] 보호 재적용 완료" -ForegroundColor Green
