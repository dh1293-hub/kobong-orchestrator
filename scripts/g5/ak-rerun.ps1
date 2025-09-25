#requires -PSEdition Core
#requires -Version 7.0
param([string]$Raw,[string]$Sha,[string]$Pr,[Parameter(ValueFromRemainingArguments=$true)][string[]]$Args)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$failedOnly = $Args -contains '--failed-only'
Write-Host "## AK Rerun"
Write-Host "- pr : $Pr"
Write-Host "- failed-only: $failedOnly"
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) { Write-Host "gh not found"; exit 0 }
# 이 PR의 head SHA 기준으로 최근 런 찾기
$branch = gh pr view $Pr --json headRefName --jq .headRefName
$runs = gh run list --branch $branch --json databaseId,headSha,conclusion,displayTitle,workflowName --limit 20 | ConvertFrom-Json
if (-not $runs) { Write-Host "[AK] no runs found for branch=$branch"; exit 0 }
$runs | ForEach-Object {
  if (-not $failedOnly -or ($_.conclusion -in @('failure','cancelled','timed_out'))) {
    Write-Host ("- rerun id={0} title='{1}' concl={2}" -f $_.databaseId, $_.displayTitle, $_.conclusion)
    gh run rerun $_.databaseId | Out-Null
  }
}
Write-Host "[AK] rerun dispatched."