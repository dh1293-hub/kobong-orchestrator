#requires -Version 7.0
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$ProgressPreference='SilentlyContinue'
$maxBytes = 5MB
$nul = [char]0
$raw = & git diff --cached --diff-filter=AM --name-only -z
$files = @()
if ($raw) { $files = ($raw -split [string]$nul) | Where-Object { $_ } }

# Block .venv
$bad = $files | Where-Object { $_ -match '(?i)(^|[\\/])\.venv([\\/]|$)' }
if ($bad) {
  Write-Host "[BLOCK] Changes under .venv are not allowed:" -ForegroundColor Red
  $bad | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
  exit 1
}

# Block large files > 5MB
foreach ($f in $files) {
  if (Test-Path -- $f) {
    try {
      $sz = (Get-Item -- $f).Length
      if ($sz -gt $maxBytes) {
        $mb = [math]::Round($sz/1MB,2)
        Write-Host "[BLOCK] Large file (>5MB): $f (${mb} MB)" -ForegroundColor Red
        exit 1
      }
    } catch { }
  }
}
exit 0