#requires -Version 7.0
<#
 G5/BRIEF — 콘솔만으로 GPT-5에 넘길 초압축 요약(1줄/10줄)
 기본 소스: logs/apply-log.jsonl + out/run-logs/*/run.json
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
  $s = $s -replace '\s+',' ' ; if ($s.Length -le $n) { return $s }
  return $s.Substring(0,[Math]::Min($n,[Math]::Max(0,$s.Length))) + '…'
}
function SafeJsonLineParse([string]$line){
  try { return $line | ConvertFrom-Json } catch { return $null }
}
function TryParseIso([string]$s){ try { return [datetime]::Parse($s) } catch { return $null } }
function GetGitSha(){
  try {
    $sha = (git -C $RepoRoot rev-parse --short HEAD 2>$null); if ($LASTEXITCODE -ne 0 -or -not $sha) { return 'unknown' }
    return $sha.Trim()
  } catch { return 'unknown' }
}
function GetLatestRun(){
  if (-not (Test-Path $RunsRoot)) { return $null }
  $dir = Get-ChildItem -Path $RunsRoot -Directory | Sort-Object LastWriteTime | Select-Object -Last 1
  if (-not $dir) { return $null }
  $m = Join-Path $dir.FullName 'run.json'
  $obj = $null
  if (Test-Path $m) { try { $obj = Get-Content -Raw -Path $m | ConvertFrom-Json } catch {} }
  if ($null -eq $obj) {
    # 최소 보정
    $obj = [pscustomobject]@{
      name   = (Split-Path $dir.FullName -Leaf)
      target = '(unknown)'; args=''; outcome='(unknown)'; exitCode=0
      counts = @{
        stdout=(Test-Path (Join-Path $dir.FullName 'stdout.log'))  ? ((Get-Content (Join-Path $dir.FullName 'stdout.log')  -ReadCount 2000 | Measure-Object -Line).Lines) : 0
        stderr=(Test-Path (Join-Path $dir.FullName 'stderr.log'))  ? ((Get-Content (Join-Path $dir.FullName 'stderr.log')  -ReadCount 2000 | Measure-Object -Line).Lines) : 0
        warn  =(Test-Path (Join-Path $dir.FullName 'warn.log'))    ? ((Get-Content (Join-Path $dir.FullName 'warn.log')    -ReadCount 2000 | Measure-Object -Line).Lines) : 0
        info  =(Test-Path (Join-Path $dir.FullName 'info.log'))    ? ((Get-Content (Join-Path $dir.FullName 'info.log')    -ReadCount 2000 | Measure-Object -Line).Lines) : 0
        verbose=(Test-Path (Join-Path $dir.FullName 'verbose.log'))? ((Get-Content (Join-Path $dir.FullName 'verbose.log') -ReadCount 2000 | Measure-Object -Line).Lines) : 0
        debug =(Test-Path (Join-Path $dir.FullName 'debug.log'))   ? ((Get-Content (Join-Path $dir.FullName 'debug.log')   -ReadCount 2000 | Measure-Object -Line).Lines) : 0
      }
    }
  }
  [pscustomobject]@{ dir=$dir.FullName; man=$obj }
}

# 수집: JSONL
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
$byLevel   = @{} ; $byOutcome = @{}
foreach($r in $records){
  $lv = ([string]$r.level).ToUpperInvariant()
  $oc = ([string]$r.outcome).ToUpperInvariant()
  if ($lv) { $byLevel[$lv]   = 1 + ($byLevel[$lv]   ?? 0) }
  if ($oc) { $byOutcome[$oc] = 1 + ($byOutcome[$oc] ?? 0) }
}
# 최근 에러/실패 메시지
$errRec = $records | Where-Object {
  $_.level -match 'ERROR' -or $_.outcome -match 'FAIL'
} | Select-Object -Last 1
$errCode = if ($errRec) { [string]$errRec.error   } else { '' }
$errMsg  = if ($errRec) { [string]$errRec.message } else { '' }

# 최신 실행
$latest = GetLatestRun
$lr = $latest?.man
$lrCounts = $lr?.counts
$lrName = $lr?.name
$lrOutcome = $lr?.outcome
$lrExit = $lr?.exitCode
$lrErrCnt = [int]($lrCounts?.stderr ?? 0)
$lrWarnCnt= [int]($lrCounts?.warn   ?? 0)

# 라인 구성
$repoName = Split-Path $RepoRoot -Leaf
$sha = GetGitSha()
$now = (Get-Date).ToString('yyyy-MM-dd HH:mm:ssK')
function Print-OneLine {
  $parts = @()
  $parts += 'G5BRIEF v1'
  $parts += "repo=$repoName@$sha"
  $parts += "time=$now"
  $lvs = ($byLevel.Keys | Sort-Object | ForEach-Object { "$_=$($byLevel[$_])" }) -join ','
  $ocs = ($byOutcome.Keys | Sort-Object | ForEach-Object { "$_=$($byOutcome[$_])" }) -join ','
  if ($lvs) { $parts += "levels=$lvs" }
  if ($ocs) { $parts += "outcomes=$ocs" }
  if ($lr)  { $parts += "lastRun=$($lrName):$($lrOutcome)/exit=$($lrExit)/err=$lrErrCnt/warn=$lrWarnCnt" }
  if ($errRec) {
    $parts += "lastErr=[$errCode] $(Short $errMsg 140)"
  } else {
    $parts += "lastErr=none"
  }
  ' | '.Join($parts)
}
function Print-Multi {
  $lines = New-Object System.Collections.Generic.List[string]
  $lines.Add('== G5/BRIEF v1 ==')
  $lines.Add(("repo: {0}@{1}  |  time: {2}  |  window: {3}m" -f $repoName,$sha,$now,$SinceMinutes))
  if ($byLevel.Count -gt 0 -or $byOutcome.Count -gt 0) {
    $lvl = ($byLevel.Keys   | Sort-Object | ForEach-Object { "$_=$($byLevel[$_])" }) -join ', '
    $out = ($byOutcome.Keys | Sort-Object | ForEach-Object { "$_=$($byOutcome[$_])" }) -join ', '
    if ($lvl) { $lines.Add("levels:  $lvl") }
    if ($out) { $lines.Add("outcomes: $out") }
  }
  if ($lr) {
    $lines.Add(("last-run: {0}  ⇒  {1} (exit={2}, err={3}, warn={4})" -f $lrName,$lrOutcome,$lrExit,$lrErrCnt,$lrWarnCnt))
    $lines.Add(("run-dir:  {0}" -f $latest.dir))
  }
  if ($errRec) {
    $lines.Add( ("last-error: [{0}] {1}" -f $errCode, (Short $errMsg 200)) )
  } else {
    $lines.Add("last-error: (none)")
  }
  # 다음 액션 가이드(콘솔만으로 복붙)
  if ($lrErrCnt -gt 0) {
    $lines.Add( ("NEXT: Get-Content '{0}' -Tail 20" -f (Join-Path $latest.dir 'stderr.log')) )
  } else {
    $lines.Add( "NEXT: OK — continue." )
  }
  # MaxLines 제한
  $top = [Math]::Min($MaxLines, $lines.Count)
  $lines[0..($top-1)]
}

if ($OneLine) { Write-Host (Print-OneLine) }
else          { Print-Multi | ForEach-Object { Write-Host $_ } }