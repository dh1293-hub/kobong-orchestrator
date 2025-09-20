#requires -Version 7.0
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'

function health-status { param([string]$Branch='main')
  $jq = '.[0] | "status=\(.status)  conclusion=\(.conclusion)  url=\(.url)"'
  $out = gh run list --workflow 'Health Monitor' --branch $Branch --limit 1 --json status,conclusion,url --jq $jq 2>$null
  if ($out) { $out } else { Write-Host "No run found on $Branch" -ForegroundColor Yellow }
}
function health-open { param([string]$Branch='main')
  $id = gh run list --workflow 'Health Monitor' --branch $Branch --limit 1 --json databaseId --jq '.[0].databaseId' 2>$null
  if ($id) { gh run view $id --web } else { Write-Host "No run found on $Branch" -ForegroundColor Yellow }
}
function health-log { param([string]$Branch='main')
  $id = gh run list --workflow 'Health Monitor' --branch $Branch --limit 1 --json databaseId --jq '.[0].databaseId' 2>$null
  if ($id) { gh run view $id --log } else { Write-Host "No run found on $Branch" -ForegroundColor Yellow }
}
function health-run { param([string]$Ref='main',[int]$Port=8080)
  gh workflow run '.github/workflows/health-monitor.yml' --ref $Ref -f port=$Port | Out-Null
  Write-Host "Triggered Health Monitor on $Ref (port=$Port)" -ForegroundColor Cyan
}
function health-follow { param([string]$Branch='main',[int]$PollSec=5)
  Write-Host "👀 Following new runs on $Branch (Ctrl+C to stop)" -ForegroundColor Cyan
  $lastId = $null
  while ($true) {
    $id = gh run list --workflow 'Health Monitor' --branch $Branch --limit 1 --json databaseId --jq '.[0].databaseId' 2>$null
    if ($id -and $id -ne $lastId) {
      $lastId = $id
      Write-Host "📜 New run: $id — streaming logs…" -ForegroundColor Yellow
      gh run view $id --log
      Write-Host "— run ended —" -ForegroundColor DarkGray
    }
    Start-Sleep -Seconds $PollSec
  }
}
function health-replay-day { param([string]$Branch='main',[datetime]$Day=(Get-Date).Date.AddDays(-1))
  $since=$Day; $until=$Day.AddDays(1)
  $items = gh run list --workflow 'Health Monitor' --branch $Branch --limit 100 --json databaseId,createdAt,status,conclusion,url | ConvertFrom-Json |
    Where-Object { $_ -and ([datetime]$_.createdAt -ge $since) -and ([datetime]$_.createdAt -lt $until) } | Sort-Object createdAt
  if (-not $items) { Write-Host ("No runs on {0}" -f $Day.ToString('yyyy-MM-dd')) -ForegroundColor Yellow; return }
  foreach ($it in $items) {
    Write-Host ("📆 {0}  {1}/{2}  {3}" -f $it.createdAt,$it.status,$it.conclusion,$it.url) -ForegroundColor Cyan
    gh run view $it.databaseId --log
  }
}
Set-Alias hs  health-status
Set-Alias ho  health-open
Set-Alias hl  health-log
Set-Alias hr  health-run
Set-Alias hf  health-follow
Set-Alias hrd health-replay-day