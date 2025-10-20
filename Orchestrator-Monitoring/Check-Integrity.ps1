param()
$Root = 'D:\ChatGPT5_AI_Link\dosc\Kobong-Orchestrator-VIP\Orchestrator-Monitoring'
$In = Join-Path $Root 'INTEGRITY_BASELINE.json'
if(!(Test-Path $In)){ Write-Error "Baseline not found: $In"; exit 1 }
$base = Get-Content $In -Raw | ConvertFrom-Json
$bad = @()
foreach($b in $base){
if(!(Test-Path $b.path)){ $bad += "MISSING: $($b.path)"; continue }
$cur = (Get-FileHash -Path $b.path -Algorithm SHA256).Hash
if($cur -ne $b.sha256){ $bad += "CHANGED: $($b.path)" }
}
if($bad.Count){
Write-Warning "[ALERT] Integrity changed!"; $bad | ForEach-Object { Write-Host " - $_" -ForegroundColor Red }
exit 2
}else{ Write-Host "[OK] Integrity PASS" }