#requires -Version 7.0
<#
 G5/BRIEF — 최근 로그 요약 1줄(또는 자세히)
 - levels/outcomes 집계는 logs/apply-log.jsonl에서
 - lastRun은 out/run-logs/*/run.json에서
 - 동적 속성 할당/카운트 없음 → 모두 문자열 조합으로 안전 출력
#>
param(
  [switch]$OneLine,
  [int]$SinceMinutes = 240
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'

function Get-RepoRoot {
  $here = $PSScriptRoot
  if ([string]::IsNullOrWhiteSpace($here)) { try { $here = Split-Path -Parent $MyInvocation.MyCommand.Path } catch {} }
  if ([string]::IsNullOrWhiteSpace($here)) { $here = (Get-Location).Path }
  $top = $null; try { $top = (git -C $here rev-parse --show-toplevel 2>$null) } catch {}
  if ([string]::IsNullOrWhiteSpace($top)) { try { $top = (Resolve-Path (Join-Path $here '..\..')).Path } catch {} }
  if ([string]::IsNullOrWhiteSpace($top)) { $top = $here }
  return $top
}
function TryParseIso([string]$s){ try { [datetime]::Parse($s) } catch { $null } }
function FirstProp([object]$o,[string[]]$names){
  foreach($n in $names){ if ($o -and $o.PSObject.Properties[$n]) { $v=$o.$n; if ($null -ne $v -and (''+$v)) { return (''+$v) } } }
  ''
}
function Short([string]$s,[int]$n=120){
  if ([string]::IsNullOrWhiteSpace($s)) { return '' }
  $t = ($s -replace '\s+',' ').Trim()
  if ($t.Length -le $n) { $t } else { $t.Substring(0,$n) + '…' }
}

$RepoRoot = Get-RepoRoot
$Jsonl    = Join-Path $RepoRoot 'logs\apply-log.jsonl'
$RunRoot  = Join-Path $RepoRoot 'out\run-logs'

$cut=(Get-Date).AddMinutes(-$SinceMinutes)
$recs=@()
if (Test-Path $Jsonl) {
  foreach($line in (Get-Content -Path $Jsonl)){
    $o=$null; try { $o=$line|ConvertFrom-Json } catch { $o=$null }
    if ($null -eq $o) { continue }
    $tt = if ($o.PSObject.Properties['timestamp']) { TryParseIso (''+$o.timestamp) } else { $null }
    if ($tt -and $tt -lt $cut) { continue }
    $recs+= $o
  }
}

# 집계
$byLevel=@{}; $byOutcome=@{}
$lastErr=$null
foreach($r in $recs){
  $lv=(FirstProp $r @('level')).ToUpperInvariant()
  $oc=(FirstProp $r @('outcome')).ToUpperInvariant()
  if ($lv) { $byLevel[$lv]   = 1 + ($byLevel[$lv]   ?? 0) }
  if ($oc) { $byOutcome[$oc] = 1 + ($byOutcome[$oc] ?? 0) }
  $isErr = ($lv -like '*ERROR*') -or ($oc -like '*FAIL*')
  if ($isErr) { $lastErr = $r }
}

# lastRun
$lastRunStr='none'
if (Test-Path $RunRoot) {
  $dir = Get-ChildItem -Path $RunRoot -Directory | Sort-Object LastWriteTime | Select-Object -Last 1
  if ($dir) {
    $runJson = Join-Path $dir.FullName 'run.json'
    if (Test-Path $runJson) {
      $m = Get-Content -Raw -Path $runJson | ConvertFrom-Json
      $name = (FirstProp $m @('name')); if (-not $name) { $name = Split-Path $dir.FullName -Leaf }
      $exit = try { [int]$m.exit } catch { 0 }
      $outc = if ($exit -eq 0) { 'SUCCESS' } else { 'FAILURE' }
      $errc = try { [int]$m.counts.err } catch { 0 }
      $warn = try { [int]$m.counts.warn } catch { 0 }
      $lastRunStr = ("{0}:{1}/exit={2}/err={3}/warn={4}" -f $name,$outc,$exit,$errc,$warn)
    }
  }
}

# 문자열 조합
$levels = if ($byLevel.Count -gt 0)   { [string]::Join(',', ($byLevel.Keys   | Sort-Object | ForEach-Object { "{0}={1}" -f $_,$byLevel[$_] })) } else { '' }
$outs   = if ($byOutcome.Count -gt 0) { [string]::Join(',', ($byOutcome.Keys | Sort-Object | ForEach-Object { "{0}={1}" -f $_,$byOutcome[$_] })) } else { '' }

$repo = Split-Path $RepoRoot -Leaf
$sha='unknown'; try { $tmp=(git -C $RepoRoot rev-parse --short HEAD 2>$null); if ($tmp){ $sha=$tmp.Trim() } } catch {}
$now=(Get-Date).ToString('yyyy-MM-dd HH:mm:ssK')

# lastErr 요약
$lastErrStr='none'
if ($lastErr) {
  $code = FirstProp $lastErr @('error','errorCode','category','code'); if (-not $code) { $code = 'ERROR' }
  $msg  = FirstProp $lastErr @('message','msg','detail','errorMessage','exception')
  $lastErrStr = ("[{0}] {1}" -f $code,(Short $msg 120))
}

if ($OneLine) {
  $parts=@('G5BRIEF v1', ("repo={0}@{1}" -f $repo,$sha), ("time={0}" -f $now))
  if ($levels) { $parts += ("levels={0}" -f $levels) }
  if ($outs)   { $parts += ("outcomes={0}" -f $outs) }
  $parts += ("lastRun={0}" -f $lastRunStr)
  $parts += ("lastErr={0}" -f $lastErrStr)
  Write-Host ([string]::Join(' | ',$parts))
  exit 0
}

Write-Host "== G5/BRIEF v1 ==" -ForegroundColor Magenta
Write-Host ("repo: {0}@{1} | time: {2} | window: {3}m" -f $repo,$sha,$now,$SinceMinutes)
if ($levels) { Write-Host ("levels:   {0}" -f $levels) }
if ($outs)   { Write-Host ("outcomes: {0}" -f $outs) }
Write-Host ("lastRun: {0}" -f $lastRunStr)
Write-Host ("lastErr: {0}" -f $lastErrStr)