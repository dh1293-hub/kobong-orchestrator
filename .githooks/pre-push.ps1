#requires -Version 7.0
param()
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
[Console]::OutputEncoding=[Text.Encoding]::UTF8

# 1) Flush-Queue 잘못된 패턴 차단
$bad = git diff --cached --name-only --diff-filter=ACM | Where-Object { $_ -like '*.ps1' } | ForEach-Object {
  $txt = git show ":$_" 2>$null
  if ($LASTEXITCODE -ne 0) { return $null }
  if ($txt -match '^[ \t]*=\s*Flush-Queue\b.*$' -im) { $_ }
} | Where-Object { $_ }

if ($bad) {
  Write-Host "[BLOCK pre-push] Invalid 'Flush-Queue' usage found in:" -ForegroundColor Red
  $bad | ForEach-Object { Write-Host "  - $_" }
  Write-Host "Fix to: `$null = Flush-Queue ..." -ForegroundColor Yellow
  exit 1
}

# 2) PS7 헤더/StrictMode 누락은 경고만
$warn = git diff --cached --name-only --diff-filter=ACM | Where-Object { $_ -like '*.ps1' } | ForEach-Object {
  $txt = git show ":$_"
  [pscustomobject]@{
    File=$_;
    HasReq = ($txt -match '(?m)^\s*#requires\s+-Version\s+7\.0\b');
    HasStrict = ($txt -match '(?m)^\s*Set-StrictMode\s+-Version\s+Latest\b')
  }
}
$warn | Where-Object { -not $_.HasReq -or -not $_.HasStrict } | ForEach-Object {
  if (-not $_.HasReq)   { Write-Host "::warning file=$($_.File)::missing '#requires -Version 7.0'" }
  if (-not $_.HasStrict){ Write-Host "::warning file=$($_.File)::missing 'Set-StrictMode -Version Latest'" }
}

exit 0