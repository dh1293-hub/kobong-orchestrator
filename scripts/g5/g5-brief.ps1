#requires -Version 7.0
<#
 콘솔 전달용 초압축 요약(1줄/10줄)
 소스: logs/apply-log.jsonl, out/run-logs/*/run.json(+로그 카운트 보정)
#>
param(
  [int]$SinceMinutes = 240,
  [switch]$OneLine,
  [int]$MaxLines = 10
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$Jsonl    = Join-Path $RepoRoot 'logs\apply-log.jsonl'
$RunsRoot = Join-Path $RepoRoot 'out\run-logs'

function Short([string]$s,[int]$n=180){
  if ($null -eq $s -or $s.Trim().Length -eq 0) { return '' }
  $t = ($s -replace '\s+',' ').Trim()
  if ($t.Length -le $n) { return $t }
  return $t.Substring(0,$n) + '…'
}
function CountOrZero([string]$p){
  if (Test-Path $p) { (Get-Content $p -ReadCount 2000 | Measure-Object -Line).Lines } else { 0 }
}

# 수집 윈도우
$cut = (Get-Date).AddMinutes(-$SinceMinutes)

# JSONL 읽기
$records = @()
if (Test-Path $Jsonl) {
  foreach($line in (Get-Content -Path $Jsonl)) {
    $o = $null; try { $o = $line | ConvertFrom-Json } catch { $o = $null }
    if ($null -eq $o) { continue }
    $tt = $null
    if ($o.PSObject.Properties['timestamp']) { try { $tt = [datetime]::Parse($o.timestamp) } catch { $tt = $null } }
    if ($tt -and $tt -lt $cut) { continue }
    $records += $o
  }
}

# 통계
$byLevel   = @{} ; $byOutcome = @{}
foreach($r in $records){
  $lv = ([string]$r.level)
  $oc = ([string]$r.outcome)
  if ($lv) { $byLevel[$lv]   = 1 + ($(if ($byLevel.ContainsKey($lv)) { $byLevel[$lv] } else { 0 })) }
  if ($oc) { $byOutcome[$oc] = 1 + ($(if ($byOutcome.ContainsKey($oc)) { $byOutcome[$oc] } else { 0 })) }
}
# 최근 에러/실패
$errRec = $null
foreach($r in $records){
  $isErr = $false
  if ($r.PSObject.Properties['level']   -and (''+ $r.level)   -match 'ERROR') { $isErr = $true }
  if ($r.PSObject.Properties['outcome'] -and (''+ $r.outcome) -match 'FAIL')  { $isErr = $true }
  if ($isErr) { $errRec = $r }
}
$errCode = if ($errRec) { '' + $errRec.error } else { '' }
$errMsg  = if ($errRec) { '' + $errRec.message } else { '' }

# 최신 실행 폴더/매니페스트
$latestDir = $null
if (Test-Path $RunsRoot) {
  $cand = Get-ChildItem -Path $RunsRoot -Directory | Sort-Object LastWriteTime | Select-Object -Last 1
  if ($cand) { $latestDir = $cand.FullName }
}
$lr = $null
if ($latestDir) {
  $mPath = Join-Path $latestDir 'run.json'
  $man = $null; if (Test-Path $mPath) { try { $man = Get-Content -Raw -Path $mPath | ConvertFrom-Json } catch { $man = $null } }
  if ($null -eq $man) {
    $man = [pscustomobject]@{
      name=(Split-Path $latestDir -Leaf); target='(unknown)'; args=''; outcome='(unknown)'; exitCode=0
      counts=@{}
    }
  }
  if (-not $man.PSObject.Properties['counts']) { $man | Add-Member -NotePropertyName counts -NotePropertyValue (@{}) }
  foreach($k in 'stdout','stderr','warn','info','verbose','debug'){
    $vv = $null
    if ($man.counts.PSObject.Properties[$k]) { $vv = $man.counts.$k }
    if ($null -eq $vv -or ($vv -isnot [int])) { $vv = CountOrZero (Join-Path $latestDir ("{0}.log" -f $k)) }
    $man.counts.$k = [int]$vv
  }
  $lr = $man
}

# repo/sha
$repoName = Split-Path $RepoRoot -Leaf
$sha = 'unknown'
try {
  $tmp = (git -C $RepoRoot rev-parse --short HEAD 2>$null)
  if ($tmp) { $sha = $tmp.Trim() }
} catch {}

# 출력 준비
$now = (Get-Date).ToString('yyyy-MM-dd HH:mm:ssK')
if ($OneLine) {
  $parts = New-Object System.Collections.Generic.List[string]
  $parts.Add('G5BRIEF v1')
  $parts.Add(("repo={0}@{1}" -f $repoName,$sha))
  $parts.Add(("time={0}" -f $now))
  if ($byLevel.Count -gt 0) {
    $keys = $byLevel.Keys | Sort-Object
    $arr = @()
    foreach($k in $keys){ $arr += ("{0}={1}" -f $k,$byLevel[$k]) }
    $parts.Add(("levels={0}" -f ([string]::Join(',', $arr))))
  }
  if ($byOutcome.Count -gt 0) {
    $keys = $byOutcome.Keys | Sort-Object
    $arr = @()
    foreach($k in $keys){ $arr += ("{0}={1}" -f $k,$byOutcome[$k]) }
    $parts.Add(("outcomes={0}" -f ([string]::Join(',', $arr))))
  }
  if ($lr) {
    $parts.Add(("lastRun={0}:{1}/exit={2}/err={3}/warn={4}" -f $lr.name,$lr.outcome,$lr.exitCode,[int]$lr.counts.stderr,[int]$lr.counts.warn))
  }
  if ($errRec) { $parts.Add(("lastErr=[{0}] {1}" -f $errCode,(Short $errMsg 140))) } else { $parts.Add("lastErr=none") }
  Write-Host ([string]::Join(' | ', $parts))
  exit 0
}

# Multi-line (최대 $MaxLines)
$lines = New-Object System.Collections.Generic.List[string]
$lines.Add('== G5/BRIEF v1 ==')
$lines.Add(("repo: {0}@{1}  |  time: {2}  |  window: {3}m" -f $repoName,$sha,$now,$SinceMinutes))
if ($byLevel.Count -gt 0) {
  $keys = $byLevel.Keys | Sort-Object; $arr=@(); foreach($k in $keys){ $arr += ("{0}={1}" -f $k,$byLevel[$k]) }
  $lines.Add("levels:  " + ([string]::Join(', ', $arr)))
}
if ($byOutcome.Count -gt 0) {
  $keys = $byOutcome.Keys | Sort-Object; $arr=@(); foreach($k in $keys){ $arr += ("{0}={1}" -f $k,$byOutcome[$k]) }
  $lines.Add("outcomes: " + ([string]::Join(', ', $arr)))
}
if ($lr) {
  $lines.Add(("last-run: {0}  ⇒  {1} (exit={2}, err={3}, warn={4})" -f $lr.name,$lr.outcome,$lr.exitCode,[int]$lr.counts.stderr,[int]$lr.counts.warn))
  $lines.Add(("run-dir:  {0}" -f $latestDir))
}
if ($errRec) { $lines.Add(("last-error: [{0}] {1}" -f $errCode,(Short $errMsg 200))) } else { $lines.Add("last-error: (none)") }
if ($lr -and [int]$lr.counts.stderr -gt 0) {
  $lines.Add(("NEXT: pwsh -File `"{0}`"" -f (Join-Path $PSScriptRoot 'next-stderr.ps1')))
} else {
  $lines.Add("NEXT: OK — continue.")
}
$cap = [Math]::Min($MaxLines, $lines.Count)
$lines[0..($cap-1)] | ForEach-Object { Write-Host $_ }