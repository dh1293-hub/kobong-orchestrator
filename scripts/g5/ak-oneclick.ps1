
param(
  [Parameter(Mandatory=$true)][int]$Pr,
  [Parameter(Mandatory=$true)][ValidateSet('scan','test','rewrite','fixloop')][string[]]$Commands
)

$ErrorActionPreference = 'Stop'
function Wait-RunId {
  param([int]$tries=60)
  $rid=$null
  1..$tries | ForEach-Object {
    if(-not $rid){
      $rid = gh run list --workflow "ak-commands.yml" -L 20 --json databaseId,event `
        --jq 'map(select(.event=="workflow_dispatch"))|.[0].databaseId'
      Start-Sleep -Seconds 2
    }
  }
  if(-not $rid){ throw "run-id not found" }
  return $rid
}

foreach($cmd in $Commands){
  Write-Host ">>> Dispatch $cmd for PR #$Pr"
  gh workflow run ak-commands.yml -f pr=$Pr -f command=$cmd | Out-Null

  $rid = Wait-RunId
  Write-Host "[run-id] $rid"

  gh run view $rid --log --exit-status

  $dir = Join-Path (Get-Location) "ak-logs-$rid"
  New-Item -ItemType Directory -Force -Path $dir | Out-Null
  gh run download $rid --name ak7-logs -D $dir

  $log = Join-Path $dir 'ak7.jsonl'
  if(Test-Path $log){
    Write-Host "---- tail $log"
    Get-Content $log -Tail 50
  } else {
    Write-Warning "ak7.jsonl not found in $dir"
  }
}
