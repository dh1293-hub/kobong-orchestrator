#requires -Version 7.0
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [Text.Encoding]::UTF8

# 스테이지된 PS1 목록
$files = git diff --cached --name-only --diff-filter=ACM | Where-Object { $_ -like '*.ps1' }
if (-not $files) { exit 0 }

$badHits = @()
foreach ($f in $files) {
  $txt = git show ":$f" 2>$null
  if ($LASTEXITCODE -ne 0) { continue }
  $m1 = [regex]::Matches($txt, '^[ \t]*=\s*Flush-Queue\b.*$', 'Multiline')
  if ($m1.Count -gt 0) {
    foreach ($m in $m1) { $badHits += @{ file=$f; line=$m.Value } }
  }
}
if ($badHits.Count -gt 0) {
  Write-Host "[BLOCK] Invalid 'Flush-Queue' assignment detected:`n" -ForegroundColor Red
  foreach ($h in $badHits) { Write-Host ("  {0}`n    {1}" -f $h.file, $h.line.Trim()) }
  Write-Host "`nFix to: `$null = Flush-Queue ..." -ForegroundColor Yellow
  exit 1
}
exit 0