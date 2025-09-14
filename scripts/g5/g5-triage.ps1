#requires -Version 7.0
<#
 대량 에러 능동 요약(콘솔 복붙용). 기본: 최근 240분, Top 5.
 - 레벨/아웃컴 집계
 - 오류 시그니처 버킷팅(코드 + 정규화된 메시지)
 - Top-K + 최근 오류 샘플
#>
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

$cut = (Get-Date).AddMinutes(-$SinceMinutes)
$recs = @()
if (Test-Path $Jsonl) {
  foreach($line in (Get-Content -Path $Jsonl)){
    $o = $null; try { $o = $line | ConvertFrom-Json } catch { $o = $null }
    if ($null -eq $o) { continue }
    $tt = $null; if ($o.PSObject.Properties['timestamp']) { try { $tt = [datetime]::Parse($o.timestamp) } catch { $tt = $null } }
    if ($tt -and $tt -lt $cut) { continue }
    $recs += $o
  }
}

$byLevel=@{}; $byOutcome=@{}
$errBuckets=@{}
$lastErr = $null

foreach($r in $recs){
  $lv = '' + $r.level
  $oc = '' + $r.outcome
  if ($lv) { $byLevel[$lv]   = 1 + ($(if ($byLevel.ContainsKey($lv)) { $byLevel[$lv] } else { 0 })) }
  if ($oc) { $byOutcome[$oc] = 1 + ($(if ($byOutcome.ContainsKey($oc)) { $byOutcome[$oc] } else { 0 })) }

  $isErr = $false
  if ($r.PSObject.Properties['level']   -and (''+$r.level)   -match 'ERROR') { $isErr = $true }
  if ($r.PSObject.Properties['outcome'] -and (''+$r.outcome) -match 'FAIL')  { $isErr = $true }
  if (-not $isErr) { continue }

  $lastErr = $r
  $code = ('' + $r.error); if (-not $code) { $code = 'UNKNOWN' }
  $sig  = Norm(('' + $r.message))
  $key  = "$code :: $sig"
  if (-not $errBuckets.ContainsKey($key)) {
    $errBuckets[$key] = [pscustomobject]@{ key=$key; code=$code; sig=$sig; count=0; sample=(''+$r.message) }
  }
  $errBuckets[$key].count++
  $errBuckets[$key].sample = (''+$r.message)
}

# Top-K
$top = $errBuckets.Values | Sort-Object count -Descending | Select-Object -First $Top

$repo = Split-Path $RepoRoot -Leaf
$sha='unknown'; try { $tmp=(git -C $RepoRoot rev-parse --short HEAD 2>$null); if ($tmp){ $sha=$tmp.Trim() } } catch {}
$now=(Get-Date).ToString('yyyy-MM-dd HH:mm:ssK')

if ($OneLine) {
  $arr=@()
  foreach($t in $top){ $arr += ("{0} x{1}" -f $t.code,$t.count) }
  $parts=@(
    'G5TRIAGE v1',
    ("repo={0}@{1}" -f $repo,$sha),
    ("time={0}" -f $now),
    ("levels={0}" -f ([string]::Join(',', ($byLevel.Keys | Sort-Object | ForEach-Object { "{0}={1}" -f $_,$byLevel[$_] })))),
    ("outcomes={0}" -f ([string]::Join(',', ($byOutcome.Keys | Sort-Object | ForEach-Object { "{0}={1}" -f $_,$byOutcome[$_] })))),
    ("top={0}" -f ([string]::Join('; ', $arr))),
    (if ($lastErr) { ("lastErr=[{0}] {1}" -f (''+$lastErr.error), (Short (''+$lastErr.message) 120)) } else { "lastErr=none" })
  )
  Write-Host ([string]::Join(' | ', $parts))
  exit 0
}

Write-Host "== G5/TRIAGE v1 ==" -ForegroundColor Magenta
Write-Host ("repo: {0}@{1} | time: {2} | window: {3}m" -f $repo,$sha,$now,$SinceMinutes)
if ($byLevel.Count -gt 0)   { Write-Host ("levels:  {0}" -f ([string]::Join(', ', ($byLevel.Keys   | Sort-Object | ForEach-Object { "{0}={1}" -f $_,$byLevel[$_] })))) }
if ($byOutcome.Count -gt 0) { Write-Host ("outcomes: {0}" -f ([string]::Join(', ', ($byOutcome.Keys | Sort-Object | ForEach-Object { "{0}={1}" -f $_,$byOutcome[$_] })))) }
if ($top.Count -gt 0) {
  Write-Host "Top Errors:"
  foreach($t in $top){
    Write-Host (" - [{0}] x{1} :: {2}" -f $t.code,$t.count, (Short $t.sample 140)) -ForegroundColor DarkYellow
  }
} else {
  Write-Host "(no errors in window)"
}