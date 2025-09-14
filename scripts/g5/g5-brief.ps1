#requires -Version 7.0
<#
 G5/BRIEF — 콘솔 전달용 초압축 요약(1줄/10줄)
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
  if ([string]::IsNullOrWhiteSpace($s)) { return '' }
  $t = ($s -replace '\s+',' ').Trim()
  if ($t.Length -le $n) { return $t }
  return $t.Substring(0,$n) + '…'
}
function SafeJsonLineParse([string]$line){ try { $line | ConvertFrom-Json } catch { $null } }
function TryParseIso([string]$s){ try { [datetime]::Parse($s) } catch { $null } }
function GetGitSha(){
  try {
    $sha = (git -C $RepoRoot rev-parse --short HEAD 2>$null)
    if (-not $sha) { return 'unknown' }
    return $sha.Trim()
  } catch { 'unknown' }
}
function CountOrZero([string]$p){
  if (Test-Path $p) { (Get-Content $p -ReadCount 2000 | Measure-Object -Line).Lines } else { 0 }
}
function GetLatestRun(){
  if (-not (Test-Path $RunsRoot)) { return $null }
  $dir = Get-ChildItem -Path $RunsRoot -Directory | Sort-Object LastWriteTime | Select-Object -Last 1
  if (-not $dir) { return $null }
  $mPath = Join-Path $dir.FullName 'run.json'
  $man = $null
  if (Test-Path $mPath) { try { $man = Get-Content -Raw -Path $mPath | ConvertFrom-Json } catch {} }
  if ($null -eq $man) {
    $man = [pscustomobject]@{
      name   = (Split-Path $dir.FullName -Leaf)
      target = '(unknown)'; args=''; outcome='(unknown)'; exitCode=0
      counts = @{
        stdout = CountOrZero (Join-Path $dir.FullName 'stdout.log')
        stderr = CountOrZero (Join-Path $dir.FullName 'stderr.log')
        warn   = CountOrZero (Join-Path $dir.FullName 'warn.log')
        info   = CountOrZero (Join-Path $dir.FullName 'info.log')
        verbose= CountOrZero (Join-Path $dir.FullName 'verbose.log')
        debug  = CountOrZero (Join-Path $dir.FullName 'debug.log')
      }
    }
  } else {
    # counts 보정(누락/비정상일 때 로그에서 보강)
    if (-not $man.PSObject.Properties['counts']) {
      $man | Add-Member -NotePropertyName counts -NotePropertyValue (@{})
    }
    foreach($k in 'stdout','stderr','warn','info','verbose','debug'){
      $v = $man.counts.PSObject.Properties[$k]?.Value
      if ($null -eq $v -or $v -isnot [int]) {
        $man.counts.$k = CountOrZero (Join-Path $dir.FullName ("{0}.log" -f $k))
      }
    }
  }
  [pscustomobject]@{ dir=$dir.FullName; man=$man }
}

# 수집 윈도우
$cut = (Get-Date).AddMinutes(-$SinceMinutes)
$records = @()
if (Test-Path $Jsonl) {
  foreach($line in (Get-Content -Path $Jsonl)) {
    $o = SafeJsonLineParse $line
    if ($null -eq $o) { continue }
    $t = if ($o.PSObject.Properties['timestamp']) { TryParseIso $o.timestamp } else { $null }
    if ($t -and $t -lt $cut) { continue }
    $records += $o
  }
}

# 통계
$byLevel = @{}; $byOutcome=@{}
foreach($r in $records){
  $lv = ([string]$r.level).ToUpperInvariant()
  $oc = ([string]$r.outcome).ToUpperInvariant()
  if ($lv) { $byLevel[$lv]   = 1 + ($byLevel[$lv]   ?? 0) }
  if ($oc) { $byOutcome[$oc] = 1 + ($byOutcome[$oc] ?? 0) }
}

# 최근 에러/실패
$errRec = $records | Where-Object { $_.level -match 'ERROR' -or $_.outcome -match 'FAIL' } | Select-Object -Last 1
$errCode = if ($errRec) { [string]$errRec.error } else { '' }
$errMsg  = if ($errRec) { [string]$errRec.message } else { '' }

# 최신 실행
$latest = GetLatestRun
$lr = if ($latest) { $latest.man } else { $null }
$lrCounts = if ($lr) { $lr.counts } else { $null }
$lrName   = if ($lr) { $lr.name }   else { '' }
$lrOutcome= if ($lr) { $lr.outcome }else { '' }
$lrExit   = if ($lr) { $lr.exitCode }else { 0 }
$lrErrCnt = [int]($lrCounts?.stderr ?? 0)
$lrWarnCnt= [int]($lrCounts?.warn   ?? 0)

# 출력
$repoName = Split-Path $RepoRoot -Leaf
$sha = GetGitSha()
$now = (Get-Date).ToString('yyyy-MM-dd HH:mm:ssK')

function Print-OneLine {
  $parts = @()
  $parts += 'G5BRIEF v1'
  $parts += ("repo={0}@{1}" -f $repoName,$sha)
  $parts += ("time={0}" -f $now)
  if ($byLevel.Count -gt 0) {
    $lvs = ($byLevel.Keys | Sort-Object | ForEach-Object { "{0}={1}" -f $_,$byLevel[$_] }) -join ','
    $parts += ("levels={0}" -f $lvs)
  }
  if ($byOutcome.Count -gt 0) {
    $ocs = ($byOutcome.Keys | Sort-Object | ForEach-Object { "{0}={1}" -f $_,$byOutcome[$_] }) -join ','
    $parts += ("outcomes={0}" -f $ocs)
  }
  if ($lr) {
    $parts += ("lastRun={0}:{1}/exit={2}/err={3}/warn={4}" -f $lrName,$lrOutcome,$lrExit,$lrErrCnt,$lrWarnCnt)
  }
  if ($errRec) { $parts += ("lastErr=[{0}] {1}" -f $errCode, (Short $errMsg 140)) } else { $parts += "lastErr=none" }
  [string]::Join(' | ',$parts)
}

function Print-Multi([int]$MaxLines){
  $lines = New-Object System.Collections.Generic.List[string]
  $lines.Add('== G5/BRIEF v1 ==')
  $lines.Add( ("repo: {0}@{1}  |  time: {2}  |  window: {3}m" -f $repoName,$sha,$now,$SinceMinutes) )
  if ($byLevel.Count -gt 0)   { $lines.Add("levels:  " + (($byLevel.Keys   | Sort-Object | ForEach-Object { "{0}={1}" -f $_,$byLevel[$_] }) -join ', ')) }
  if ($byOutcome.Count -gt 0) { $lines.Add("outcomes: " + (($byOutcome.Keys | Sort-Object | ForEach-Object { "{0}={1}" -f $_,$byOutcome[$_] }) -join ', ')) }
  if ($lr) {
    $lines.Add(("last-run: {0}  ⇒  {1} (exit={2}, err={3}, warn={4})" -f $lrName,$lrOutcome,$lrExit,$lrErrCnt,$lrWarnCnt))
    $lines.Add(("run-dir:  {0}" -f $latest.dir))
  }
  if ($errRec) { $lines.Add( ("last-error: [{0}] {1}" -f $errCode, (Short $errMsg 200)) ) } else { $lines.Add("last-error: (none)") }
  if ($lrErrCnt -gt 0 -and $latest) {
    $lines.Add( ("NEXT: pwsh -File `"{0}`"" -f (Join-Path $PSScriptRoot 'next-stderr.ps1')) )
  } else {
    $lines.Add( "NEXT: OK — continue." )
  }
  $cap = [Math]::Min($MaxLines, $lines.Count)
  $lines[0..($cap-1)]
}

if ($OneLine) { Write-Host (Print-OneLine) }
else          { Print-Multi -MaxLines $MaxLines | ForEach-Object { Write-Host $_ } }