param()
$Root = 'D:\ChatGPT5_AI_Link\dosc\Kobong-Orchestrator-VIP\Orchestrator-Monitoring'
$Out = Join-Path $Root 'INTEGRITY_BASELINE.json'
$List = @(
'Orchestrator-Monitoring-Su.html',
'public\\xterm\\xterm.js',
'public\\xterm\\xterm.css'
) | ForEach-Object { Join-Path $Root $_ }


$items = foreach($p in $List){
if(Test-Path $p){
$h = (Get-FileHash -Path $p -Algorithm SHA256).Hash
[pscustomobject]@{ path=$p; sha256=$h }
}
}
$items | ConvertTo-Json -Depth 3 | Out-File -Encoding UTF8 $Out
Write-Host "[OK] Baseline → $Out"
