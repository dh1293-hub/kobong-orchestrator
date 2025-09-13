param()
$ErrorActionPreference = "Stop"
Write-Host "== Smoke (logging) =="
python -m scripts.smoke_log
if ($LASTEXITCODE -ne 0) { Write-Host "Smoke failed" -ForegroundColor Red; exit 4 }
Get-ChildItem logs | Select-Object Name,Length,LastWriteTime | Format-Table -AutoSize
Write-Host "Smoke passed."
exit 0
