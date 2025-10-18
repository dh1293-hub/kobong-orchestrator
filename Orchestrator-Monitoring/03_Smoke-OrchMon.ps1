# 03_Smoke-OrchMon.ps1
param([int]$Port=5193)
$base = "http://localhost:$Port"
$ok=0
try{ (iwr "$base/health" -UseBasicParsing).Content | Write-Host; $ok++ }catch{ Write-Warning "/health FAIL" }
try{ (iwr "$base/api/orchmon" -UseBasicParsing).Content | Write-Host; $ok++ }catch{ Write-Warning "/api/orchmon FAIL" }
try{
  $r = iwr "$base/api/orchmon/timeline" -UseBasicParsing -Headers @{Accept='text/event-stream'} -MaximumRedirection 0 -SkipHttpErrorCheck
  ($r.PSObject.Properties.Name -contains 'StatusCode') ? $r.StatusCode : 200 | Write-Host
  $ok++
}catch{ Write-Warning "/timeline FAIL" }
if($ok -eq 3){ Write-Host "[OK] SMOKE PASS" } else { Write-Warning "[WARN] SMOKE PARTIAL: $ok/3" }
