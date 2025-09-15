# APPLY IN SHELL
# Error Trend v1.2 — apply-log.jsonl aggregation (generated: 2025-09-15 02:06:53 +09:00)
#requires -Version 7.0
param([int]$LookbackHours=24,[int]$BucketMinutes=60,[string]$OutDir)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'

function Read-Jsonl($p){ $a=@(); if(-not(Test-Path $p)){return $a}
  Get-Content -Path $p -Encoding utf8 | ForEach-Object {
    if([string]::IsNullOrWhiteSpace($_)){return}
    try{ $a += ($_ | ConvertFrom-Json) } catch {}
  }; return $a
}

$repo = try{ git rev-parse --show-toplevel 2>$null }catch{ (Get-Location).Path }
if(-not $OutDir){ $OutDir = Join-Path $repo 'out/status' }
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

$since=(Get-Date).AddHours(-$LookbackHours)
$all=@( Read-Jsonl (Join-Path $repo 'logs/apply-log.jsonl') | Where-Object {
  $_ -and $_.PSObject -and $_.PSObject.Properties['timestamp'] -and ([datetime]$_.timestamp) -ge $since
})

# 안전 접근(절대 dot 접근 X)
function Get-Prop($o,[string]$name){
  if($o -and $o.PSObject -and $o.PSObject.Properties[$name]){ return $o.PSObject.Properties[$name].Value }
  return $null
}

$total=$all.Count
$succ = @( $all | Where-Object { (Get-Prop $_ 'outcome') -eq 'SUCCESS' } ).Count
$fail = @( $all | Where-Object { (Get-Prop $_ 'outcome') -eq 'FAILURE' } ).Count
$dry  = @( $all | Where-Object { (Get-Prop $_ 'outcome') -eq 'DRYRUN'  } ).Count

$errs = foreach($it in $all){
  $c = [string](Get-Prop $it 'errorCode')
  if(-not [string]::IsNullOrWhiteSpace($c)){ $c }
}
$topErr = @($errs | Group-Object | Sort-Object Count -Descending | Select-Object -First 5 | ForEach-Object { @{ code=$_.Name; count=$_.Count } })

# Buckets
$bucket=@{}
foreach($it in $all){
  try{
    $t=[datetime]$it.timestamp
    $utc=$t.ToUniversalTime()
    $rem = $utc.Minute % [Math]::Max(1,$BucketMinutes)
    $b = $utc.AddMinutes(-$rem).AddSeconds(-$utc.Second).AddMilliseconds(0)
    $k = $b.ToString('yyyy-MM-dd HH:mm')+'Z'
    if(-not $bucket.ContainsKey($k)){ $bucket[$k]=@{total=0;success=0;failure=0;dryrun=0} }
    $o = [string](Get-Prop $it 'outcome')
    $bucket[$k].total++
    switch($o){
      'SUCCESS' { $bucket[$k].success++ }
      'FAILURE' { $bucket[$k].failure++ }
      'DRYRUN'  { $bucket[$k].dryrun++ }
    }
  } catch {}
}
$series = $bucket.Keys | Sort-Object | ForEach-Object { @{ ts=$_; data=$bucket[$_] } }

Clear-Host
Write-Host ("ERROR TREND @ {0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')) -ForegroundColor Cyan
Write-Host ("Range: last {0}h   total={1}  success={2}  failure={3}  dryrun={4}" -f $LookbackHours,$total,$succ,$fail,$dry)
if($topErr.Count -gt 0){
  Write-Host "Top error codes:"; foreach($e in $topErr){ Write-Host ("  - {0}: {1}" -f $e.code,$e.count) }
}else{ Write-Host "Top error codes: <none>" }

$out=@{
  ts=(Get-Date).ToString('o'); lookbackHours=$LookbackHours; bucketMinutes=$BucketMinutes
  total=$total; success=$succ; failure=$fail; dryrun=$dry; topErrors=$topErr; series=$series
}
$ts=Get-Date -Format 'yyyyMMdd-HHmmss'
$tmp=Join-Path $OutDir "error-trend.$ts.json.tmp"
$dst=Join-Path $OutDir "error-trend.$ts.json"
$out | ConvertTo-Json -Depth 6 | Out-File -FilePath $tmp -Encoding utf8 -NoNewline
Move-Item -Force $tmp $dst
Copy-Item -Force $dst (Join-Path $OutDir 'error-trend.latest.json') | Out-Null
Write-Host ("[Saved] {0}" -f $dst)