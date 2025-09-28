#requires -Version 7
param(
  [Parameter(Mandatory)][int]$Pr,
  [string[]]$Commands = @('scan','test','rewrite','fixloop')
)

$ErrorActionPreference='Stop'
function Wait-Run([Parameter(Mandatory)][string]$RunId){
  gh run view $RunId --log --exit-status
  $ok=$false
  foreach($i in 1..40){
    try { gh run download $RunId --name ak7-logs | Out-Null; $ok=$true; break } catch { Start-Sleep 3 }
  }
  if(-not $ok){ throw "artifact not available for run $RunId" }
  $log = Get-ChildItem -Recurse -Filter ak7.jsonl | Select-Object -First 1
  if($log){ Get-Content $log.FullName -Tail 30 }
  Remove-Item -Recurse -Force ak7-logs -ErrorAction SilentlyContinue
}

foreach($cmd in $Commands){
  Write-Host "==> $cmd"
  gh workflow run ak-commands.yml -f pr=$Pr -f command=$cmd | Out-Null
  $RunId=$null
  foreach($i in 1..60){
    $RunId = gh run list --workflow ak-commands.yml -L 1 --json databaseId --jq '.[0].databaseId'
    if($RunId){ break } else { Start-Sleep 2 }
  }
  if(-not $RunId){ throw "No run-id for $cmd" }
  Wait-Run $RunId
}
