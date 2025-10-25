param(
  [string[]]$Containers = @("orchmon","ghmon","ak7")
)
Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

function Restart-Container($name){
  $have = (docker ps -a --format "{{.Names}}" | Where-Object { $_ -eq $name })
  if(-not $have){ Write-Host "[skip] container not found: $name"; return }
  try{
    docker update --restart unless-stopped $name | Out-Null
    docker stop $name 2>$null | Out-Null
    docker start $name | Out-Null
    Write-Host "[OK] restarted: $name" -ForegroundColor Green
  } catch { Write-Warning "[warn] $name: $($_.Exception.Message)" }
}

foreach($c in $Containers){ Restart-Container $c }
