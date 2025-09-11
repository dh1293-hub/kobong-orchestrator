# Usage: pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/run-hardening.ps1
$ErrorActionPreference = "Stop"
Set-Location -Path "D:\ChatGPT5_AI_Link\dosc\gpt5-conductor"

Write-Host "`n[1/5] Build" -ForegroundColor Cyan
npm run build

Write-Host "`n[2/5] Baseline run" -ForegroundColor Cyan
node .\dist\app\hardening.js --mode=baseline
$code1 = $LASTEXITCODE
Write-Host "ExitCode(Baseline)=$code1"

Write-Host "`n[3/5] Fault run (pii)" -ForegroundColor Cyan
node .\dist\app\hardening.js --mode=fault --inject=pii
$code2 = $LASTEXITCODE
Write-Host "ExitCode(Fault-PII)=$code2"

Write-Host "`n[4/5] Fault run (crash)" -ForegroundColor Cyan
node .\dist\app\hardening.js --mode=fault --inject=crash
$code3 = $LASTEXITCODE
Write-Host "ExitCode(Fault-Crash)=$code3"

Write-Host "`n[5/5] Tail logs/hardening.log (last 30)" -ForegroundColor Cyan
Get-Content .\logs\hardening.log -Tail 30
