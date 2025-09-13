# Code-001 — view-ci-summary.ps1 (APPLY IN SHELL)
# Name: CI Summary Viewer v1.1 (shape-safe)
# Intent: 최신 오픈 PR 1건의 체크 상태 요약 — statusCheckRollup의 다양한 스키마 안전 처리
#requires -Version 7.0
param([switch]$ConfirmApply,[string]$Root)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'

function Get-Prop($obj,[string]$name){
  if($null -eq $obj){return $null}
  try { $p=$obj.PSObject.Properties.Match($name); if($p -and $p.Count -gt 0){ return $obj.$name } } catch {}
  try { if($obj -is [System.Collections.IDictionary] -and $obj.Contains($name)){ return $obj[$name] } } catch {}
  return $null
}

if(-not (Get-Command gh -ErrorAction SilentlyContinue)){ throw 'gh CLI not found' }
if(-not (Get-Command git -ErrorAction SilentlyContinue)){ throw 'git not found' }

$repo = $env:GITHUB_REPOSITORY
if(-not $repo){
  $origin = git config --get remote.origin.url
  if(-not $origin){ throw 'git remote.origin.url not found' }
  $repo = ($origin -replace '^https://github.com/','') -replace '\.git$',''
}

$pr = gh pr list -R $repo --state open -L 1 --json number,headRefName | ConvertFrom-Json | Select-Object -First 1
if(-not $pr){ Write-Host "[INFO] 열린 PR 없음. repo=$repo"; exit 0 }

$data = gh pr view -R $repo $pr.number --json url,headRefName,mergeStateStatus,statusCheckRollup | ConvertFrom-Json
Write-Host ("[INFO] PR #{0}  [{1}]  {2}" -f $pr.number, $data.headRefName, $data.url)
Write-Host ("[INFO] Merge State: {0}" -f $data.mergeStateStatus)
Write-Host "----------------------------------------------"

$roll = $data.statusCheckRollup
if(-not $roll){ Write-Host "[WARN] statusCheckRollup가 비었습니다."; exit 0 }

$rows = foreach($it in $roll){
  $name  = Get-Prop $it 'context'; if(-not $name){ $name = Get-Prop $it 'name' }; if(-not $name){ $name = Get-Prop $it '__typename' }
  $state = Get-Prop $it 'state';   if(-not $state){ $state = Get-Prop $it 'conclusion' }; if(-not $state){ $state = Get-Prop $it 'status' }
  if(-not $name -and -not $state){ [pscustomobject]@{ Name='<unknown>'; State=($it | ConvertTo-Json -Compress) } }
  else { [pscustomobject]@{ Name=$name; State=$state } }
}

$rows | Sort-Object Name | Format-Table -AutoSize