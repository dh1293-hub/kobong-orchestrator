# APPLY IN SHELL
#requires -Version 7.0
param([string]$Pr,[string]$Sha,[switch]$ConfirmApply)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['*:Encoding']='utf8'
$sw=[Diagnostics.Stopwatch]::StartNew()
function K($lvl,$act,$out,$msg,$exit=0){
  $rec=[ordered]@{
    timestamp=(Get-Date).ToString('o'); level=$lvl; traceId=[guid]::NewGuid().ToString();
    module='scripts'; action=$act; outcome=$out; message=$msg; durationMs=$sw.ElapsedMilliseconds
  }|ConvertTo-Json -Compress
  New-Item -ItemType Directory -Force -Path (Join-Path $PSScriptRoot '..\..\logs') | Out-Null
  Add-Content -Path (Join-Path $PSScriptRoot '..\..\logs\ak7.jsonl') -Value $rec
  if($exit -ne 0){ exit $exit }
}
try{
  $mode = ($ConfirmApply ? 'APPLY' : 'DRYRUN')
  K 'INFO'  $MyInvocation.MyCommand.Name $mode "start pr=$Pr sha=$Sha"
  # 실제 작업은 이후 단계에서 채운다. 지금은 배선 확인용.
  Start-Sleep -Milliseconds 150
  K 'INFO'  $MyInvocation.MyCommand.Name 'SUCCESS' 'ok'
  exit 0
}catch{
  K 'ERROR' $MyInvocation.MyCommand.Name 'FAILURE' $_.Exception.Message 13
}
