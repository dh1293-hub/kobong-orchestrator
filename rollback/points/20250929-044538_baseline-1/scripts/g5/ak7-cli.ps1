param(
  [int]$Port = 5192,
  [ValidateSet("ok","warn","err")][string]$Level = "ok",
  [string]$Toast,
  [ValidateSet("scan","test","fixloop","next","prefs","health")][string]$Action,
  [switch]$RollbackCreate,
  [string]$RollbackName = "good-1",
  [switch]$RollbackRestore,
  [switch]$RollbackPreview
)
Set-StrictMode -Version Latest
$ErrorActionPreference="Stop"
$PSDefaultParameterValues['*:Encoding']='utf8'
function J($o){ $o | ConvertTo-Json -Compress }

# 롤백 유틸 불러오기
. (Join-Path (Split-Path $MyInvocation.MyCommand.Path -Parent) 'ak7-rollback.ps1')

if($RollbackCreate){
  $r = New-AK7RollbackPoint -Name $RollbackName
  $r | ConvertTo-Json -Compress
  exit
}
if($RollbackPreview){
  $r = Restore-AK7RollbackPoint -Name $RollbackName -WhatIf
  $r | ConvertTo-Json -Compress
  exit
}
if($RollbackRestore){
  $r = Restore-AK7RollbackPoint -Name $RollbackName
  $r | ConvertTo-Json -Compress
  exit
}

# 토스트/액션
if($Toast){
  $u="http://localhost:{0}/api/ak7/notify" -f $Port
  try{ Invoke-RestMethod -Method POST -Uri $u -ContentType "application/json" -Body (J @{ level=$Level; msg=$Toast }) }
  catch{ Write-Host (J @{ ok=$false; error="notify_failed"; message=$_.Exception.Message }) }
  exit
}
if($Action){
  switch($Action){
    "health" { Invoke-RestMethod -Uri ("http://localhost:{0}/health" -f $Port); break }
    "prefs"  { Invoke-RestMethod -Uri ("http://localhost:{0}/api/ak7/prefs" -f $Port); break }
    "next"   { Invoke-RestMethod -Method POST -Uri ("http://localhost:{0}/api/ak7/next" -f $Port) -ContentType "application/json" -Body (J @{ts=(Get-Date).ToString("o")}) ; break }
    default  { Invoke-RestMethod -Uri ("http://localhost:{0}/api/ak7/{1}" -f $Port,$Action) ; break }
  }
  exit
}
Write-Host "Usage:
  .\ak7-cli.ps1 -RollbackCreate   [-RollbackName good-1]
  .\ak7-cli.ps1 -RollbackPreview  [-RollbackName good-1]
  .\ak7-cli.ps1 -RollbackRestore  [-RollbackName good-1]
  .\ak7-cli.ps1 -Toast 'msg' [-Level ok|warn|err]
  .\ak7-cli.ps1 -Action scan|test|fixloop|next|prefs|health"
