#requires -Version 7.0
param()
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
[Console]::OutputEncoding=[Text.Encoding]::UTF8

# Upstream 결정
$upstream = (git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>$null)
if (-not $upstream) { $upstream = "origin/main" }

# 푸시될 커밋들에서 변경된 PS1 파일만
$changed = git diff --name-only --diff-filter=ACM $upstream...HEAD |
  Where-Object { $_ -like '*.ps1' } |
  Where-Object { $_ -notmatch '\\(node_modules|\.githooks)\\' }

$bad = @()
foreach ($f in $changed) {
  $txt = git show "HEAD:$f" 2>$null
  if ($LASTEXITCODE -ne 0) { continue }
  if ($txt -match '(?im)^[ \t]*=\s*Flush-Queue\b.*$') { $bad += $f }
}

if ($bad.Count -gt 0) {
  Write-Host "[BLOCK pre-push] Invalid 'Flush-Queue' usage found in:" -ForegroundColor Red
  $bad | ForEach-Object { Write-Host "  - $_" }
  Write-Host "Fix to: `$null = Flush-Queue ..." -ForegroundColor Yellow
  exit 1
}

# 경고: PS7 헤더/StrictMode 누락
foreach ($f in $changed) {
  $txt = git show "HEAD:$f"
  if ($txt -notmatch '(?m)^\s*#requires\s+-Version\s+7\.0\b') {
    Write-Host "::warning file=$f::missing '#requires -Version 7.0'"
  }
  if ($txt -notmatch '(?m)^\s*Set-StrictMode\s+-Version\s+Latest\b') {
    Write-Host "::warning file=$f::missing 'Set-StrictMode -Version Latest'"
  }
}

exit 0