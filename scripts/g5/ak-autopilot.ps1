# scripts/g5/ak-autopilot.ps1
$ErrorActionPreference = "Continue"
if (-not $env:GH_TOKEN -and $env:GITHUB_TOKEN) { $env:GH_TOKEN = $env:GITHUB_TOKEN }

$pr = (gh pr list --state open --limit 1 --json number --jq '.[0].number' 2>$null)
if (-not $pr) { $pr = "201" }

$cmds = @("scan","test","rewrite","fixloop")
foreach($c in $cmds){
  Write-Host "==> $c (PR $pr)"
  gh workflow run ak-commands.yml -f pr=$pr -f command=$c
}
Write-Host "done."
