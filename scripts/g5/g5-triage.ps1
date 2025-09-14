#requires -Version 7.0
param(
  [int]$SinceMinutes = 240,
  [int]$Top = 5,
  [switch]$OneLine
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$Jsonl    = Join-Path $RepoRoot 'logs\apply-log.jsonl'

function Short([string]$s,[int]$n=160){
  if ($null -eq $s -or $s.Trim().Length -eq 0) { return '' }
  $t = ($s -replace '\s+',' ').Trim()
  if ($t.Length -le $n) { return $t }
  return $t.Substring(0,$n) + '…'
}
function Norm([string]$s){
  if ($null -eq $s) { return '' }
  $t = $s.ToLowerInvariant()
  $t = $t -replace '\b[0-9a-f]{8,}\b','<hex>'
  $t = $t -replace '\d{4}-\d{2}-\d{2}[t\s]\d{2}:\d{2}:\d{2}(\.\d+)?(z|[+\-]\d{2}:\d{2})?','<ts>'
  $t = $t -replace '\s+',' '
  return $t.Trim()
}
function TryParseIso([string]$s){ try { [datetime]::Parse($s) } catch { $null } }
function FirstProp([object]$o,[string[]]$names){
  foreach($n in $names){ if ($o -and $o.PSObject.Properties[$n]) { $v = $o.$n; if ($null -ne $v -and (''+$v).Length -gt 0) { return (''+$v) } } }
  return ''
}

$cut = (Get-Date).AddMinutes(-$SinceMinutes)
$recs = @()
if (Test-Path $Jsonl) {
  foreach($line in (Get-Content -Path $Jsonl)){
    $o = $null; try { $o = $line | ConvertFrom-Json } catch { $o = $null }
    if ($null -eq $o) { continue }
    $tt = if ($o.PSObject.Properties['timestamp']) { TryParseIso (''+$o.timestamp) } else { $null }
    if ($tt -and $tt -lt $cut) { continue }
    $recs += $o
  }
}

$byLevel=@{}; $byOutcome=@{}
$errBuckets=@{}; $lastErr=$null

foreach($r in $recs){
  $lv = (FirstProp $r @('level')).ToUpper()
  $oc = (FirstProp $r @('outcome')).ToUpper()
  if ($lv) { $byLevel[$lv]   = 1 + ($(if ($byLevel.ContainsKey($lv)) { $byLevel[$lv] } else { 0 })) }
  if ($oc) { $byOutcome[$oc] = 1 + ($(if ($byOutcome.ContainsKey($oc)) { $byOutcome[$oc] } else { 0 })) }

  $isErr = ($lv -like '*ERROR*') -or ($oc -like '*FAIL*')
  if (-not $isErr) { continue }

  $lastErr = $r
  $codeRaw = FirstProp $r @('error','errorCode','category','code'); if (-not $codeRaw) { $codeRaw = 'ERROR' }
  $msgRaw  = FirstProp $r @('message','msg','detail','errorMessage','exception')

  $sig  = Norm $msgRaw
  $key  = "$codeRaw :: $sig"
  if (-not $errBuckets.ContainsKey($key)) {
    $errBuckets[$key] = [pscustomobject]@{ key=$key; code=$codeRaw; sig=$sig; n=0; sample=$msgRaw }
  }
  # n은 항상 단일 정수로 보정
  $current = 0
  try { $current = [int]((@($errBuckets[$key].n) | Select-Object -First 1) ?? 0) } catch { $current = 0 }
  $errBuckets[$key].n = $current + 1
  if ($msgRaw) { $errBuckets[$key].sample = $msgRaw }
}

# 정렬 전, n을 확실히 int로 정규화
$norm = foreach($v in $errBuckets.Values){
  $nVal = 0
  try { $nVal = [int]((@($v.n) | Select-Object -First 1) ?? 0) } catch { $nVal = 0 }
  [pscustomobject]@{ code=$v.code; sig=$v.sig; n=$nVal; sample=$v.sample }
}
$topList = $norm | Sort-Object -Property n -Descending | Select-Object -First $Top

$repo = Split-Path $RepoRoot -Leaf
$sha='unknown'; try { $tmp=(git -C $RepoRoot rev-parse --short HEAD 2>$null); if ($tmp){ $sha=$tmp.Trim() } } catch {}
$now=(Get-Date).ToString('yyyy-MM-dd HH:mm:ssK')

if ($OneLine) {
  $arr=@(); foreach($t in $topList){ $arr += ("{0} x{1}" -f $t.code,[int]$t.n) }
  $levels = if ($byLevel.Count -gt 0)   { [string]::Join(',', ($byLevel.Keys   | Sort-Object | ForEach-Object { "{0}={1}" -f $_,$byLevel[$_] })) } else { '' }
  $outs   = if ($byOutcome.Count -gt 0) { [string]::Join(',', ($byOutcome.Keys | Sort-Object | ForEach-Object { "{0}={1}" -f $_,$byOutcome[$_] })) } else { '' }
  $parts=@('G5TRIAGE v1', ("repo={0}@{1}" -f $repo,$sha), ("time={0}" -f $now))
  if ($levels) { $parts += ("levels={0}" -f $levels) }
  if ($outs)   { $parts += ("outcomes={0}" -f $outs) }
  if ($arr.Count -gt 0){ $parts += ("top={0}" -f ([string]::Join('; ',$arr))) } else { $parts += "top=none" }
  if ($lastErr) {
    $lastCode = FirstProp $lastErr @('error','errorCode','category','code'); if (-not $lastCode) { $lastCode='UNKNOWN' }
    $lastMsg  = FirstProp $lastErr @('message','msg','detail','errorMessage','exception')
    $parts += ("lastErr=[{0}] {1}" -f $lastCode, (Short $lastMsg 120))
  } else {
    $parts += "lastErr=none"
  }
  Write-Host ([string]::Join(' | ',$parts))
  exit 0
}

Write-Host "== G5/TRIAGE v1 ==" -ForegroundColor Magenta
Write-Host ("repo: {0}@{1} | time: {2} | window: {3}m" -f $repo,$sha,$now,$SinceMinutes)
if ($byLevel.Count -gt 0)   { Write-Host ("levels:  {0}" -f ([string]::Join(', ', ($byLevel.Keys   | Sort-Object | ForEach-Object { "{0}={1}" -f $_,$byLevel[$_] })))) }
if ($byOutcome.Count -gt 0) { Write-Host ("outcomes: {0}" -f ([string]::Join(', ', ($byOutcome.Keys | Sort-Object | ForEach-Object { "{0}={1}" -f $_,$byOutcome[$_] })))) }
if ($topList.Count -gt 0) {
  Write-Host "Top Errors:"
  foreach($t in $topList){ Write-Host (" - [{0}] x{1} :: {2}" -f $t.code,[int]$t.n,(Short $t.sample 140)) -ForegroundColor DarkYellow }
} else {
  Write-Host "(no errors in window)"
}