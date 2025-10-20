param([int]$Port=5191)
$Base = "http://localhost:$Port"
try{ $Health = Invoke-RestMethod "$Base/health" -TimeoutSec 5;  Write-Host ("$Health: " + (ConvertTo-Json $Health -Compress)) }catch{ Write-Host ("Health ERR: " + $_.Exception.Message) }
try{ $Info   = Invoke-RestMethod "$Base/api/ak7" -TimeoutSec 5; Write-Host ("$Info: "   + (ConvertTo-Json $Info   -Compress)) }catch{ Write-Host ("Info ERR: " + $_.Exception.Message) }
