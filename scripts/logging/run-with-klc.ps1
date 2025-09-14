#requires -Version 7.0
param(
  [Parameter(Mandatory)][string]$File,
  [string[]]$Args
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'

function Write-KlcJsonl {
  param([string]$Level,[string]$Action,[string]$Outcome,[string]$Message,[string]$Module='runner',[string]$ErrorCode='')
  $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
  $jsonl = Join-Path $repoRoot 'logs\apply-log.jsonl'
  try {
    if (Get-Command kobong_logger_cli -ErrorAction SilentlyContinue) {
      & kobong_logger_cli log --level $Level --module $Module --action $Action --outcome $Outcome --error $ErrorCode --message $Message
      return
    }
  } catch {}
  $rec = @{ timestamp=(Get-Date).ToString('o'); level=$Level; module=$Module; action=$Action; outcome=$Outcome; error=$ErrorCode; message=$Message; traceId=[guid]::NewGuid().ToString() } | ConvertTo-Json -Compress
  New-Item -ItemType Directory -Force -Path (Split-Path $jsonl) | Out-Null
  Add-Content -Path $jsonl -Value $rec
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$ts   = Get-Date -Format 'yyyyMMdd-HHmmss'
$name = [IO.Path]::GetFileNameWithoutExtension($File)
$runDir = Join-Path $repoRoot ("out\run-logs\{0}-{1}" -f $ts,$name)
New-Item -ItemType Directory -Force -Path $runDir | Out-Null

$stdout   = Join-Path $runDir 'stdout.log'
$stderr   = Join-Path $runDir 'stderr.log'
$warnf    = Join-Path $runDir 'warn.log'
$infof    = Join-Path $runDir 'info.log'
$verbosef = Join-Path $runDir 'verbose.log'
$debugf   = Join-Path $runDir 'debug.log'

$target = (Resolve-Path $File).Path
$startTime = Get-Date
Write-KlcJsonl -Level 'INFO' -Action 'run:start' -Outcome 'PENDING' -Message ("{0} {1}" -f $target, ($Args -join ' '))

# 실행 (가능하면 모든 스트림→파일, 실패 시 stdout/stderr만 폴백)
$fallback = $false
try {
  & $target @Args 1> $stdout 2> $stderr 3> $warnf 4> $verbosef 5> $debugf 6> $infof
} catch {
  $fallback = $true
  try {
    & $target @Args 1> $stdout 2> $stderr
  } catch {
    $_ | Out-String | Set-Content -Path $stderr
  }
}

function CountOrZero($p){ if (Test-Path $p) { (Get-Content $p -ReadCount 1000 | Measure-Object -Line).Lines } else { 0 } }
$cOut = CountOrZero $stdout
$cErr = CountOrZero $stderr
$cWrn = CountOrZero $warnf
$cInf = CountOrZero $infof
$cVer = CountOrZero $verbosef
$cDbg = CountOrZero $debugf

$sampleErr = if (Test-Path $stderr) { (Get-Content $stderr -TotalCount 2) -join ' | ' } else { '' }
$sampleWrn = if (Test-Path $warnf)  { (Get-Content $warnf  -TotalCount 2) -join ' | ' } else { '' }

# ← 여기 핵심: 실패 판정 = "에러 스트림 라인수 > 0"
$exitCode   = if ($cErr -gt 0) { 1 } else { 0 }
$levelEmit  = if ($exitCode -eq 0) { 'INFO' } else { 'ERROR' }
$outcomeEmit= if ($exitCode -eq 0) { 'SUCCESS' } else { 'FAILURE' }
$errCodeEmit= if ($exitCode -eq 0) { '' } else { 'LOGIC' }

$msg = "exit=$exitCode; out=$cOut, warn=$cWrn, err=$cErr, info=$cInf, verbose=$cVer, debug=$cDbg"
if ($sampleErr) { $msg += "; errSample=" + $sampleErr }
if ($sampleWrn) { $msg += "; warnSample=" + $sampleWrn }
if ($fallback)  { $msg += "; fallback=legacy-redirect(1,2)" }

Write-KlcJsonl -Level $levelEmit -Action 'run:end' -Outcome $outcomeEmit -Message $msg -ErrorCode $errCodeEmit

# === manifest & summary ===
$endTime = Get-Date
$manifest = [ordered]@{
  name=$name; target=$target; args=($Args -join ' ');
  start=$startTime.ToString('o'); end=$endTime.ToString('o');
  exitCode=$exitCode; outcome=$outcomeEmit; level=$levelEmit;
  counts=@{ stdout=$cOut; stderr=$cErr; warn=$cWrn; info=$cInf; verbose=$cVer; debug=$cDbg };
  samples=@{ err=$sampleErr; warn=$sampleWrn }
}
$mPath = Join-Path $runDir 'run.json'
($manifest | ConvertTo-Json -Depth 6) | Set-Content -Path $mPath -Encoding utf8

$sumMd = @()
$sumMd += '# Run Summary (' + $name + ')'
$sumMd += ''
$sumMd += '*Dir:* ' + $runDir
$sumMd += '*Target:* ' + $target
$sumMd += '*Args:* ' + ($Args -join ' ')
$sumMd += '*Outcome:* ' + $outcomeEmit + '  (exit=' + $exitCode + ')'
$sumMd += '*Counts:* out=' + $cOut + ', warn=' + $cWrn + ', err=' + $cErr + ', info=' + $cInf + ', verbose=' + $cVer + ', debug=' + $cDbg
if ($sampleErr) { $sumMd += '*ErrSample:* ' + $sampleErr }
if ($sampleWrn) { $sumMd += '*WarnSample:* ' + $sampleWrn }
if ($fallback)  { $sumMd += '*Note:* fallback=legacy-redirect(1,2)' }
$sumPath = Join-Path $runDir 'summary.md'
[System.IO.File]::WriteAllText($sumPath, ([string]::Join("`n",$sumMd) + "`n"), (New-Object System.Text.UTF8Encoding($false)))

Write-Host "[OK] Run logs at: $runDir" -ForegroundColor Green
if ($outcomeEmit -ne 'SUCCESS') { Write-Host "[HINT] Check stderr: $stderr" -ForegroundColor DarkYellow }

# === G5 AUTO-HOOK (console handoff) ===
try {
  $root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
  $g5   = Join-Path $root 'scripts\g5\g5-brief.ps1'
  if (Test-Path $g5) { & pwsh -NoProfile -ExecutionPolicy Bypass -File $g5 -OneLine }
  $tri  = Join-Path $root 'scripts\g5\g5-triage.ps1'
  if (Test-Path $tri) {
    $runs = Join-Path $root 'out\run-logs'
    $dir = Get-ChildItem -Path $runs -Directory | Sort-Object LastWriteTime | Select-Object -Last 1
    if ($dir) {
      $stderr = Join-Path $dir.FullName 'stderr.log'
      $cErr = (Test-Path $stderr) ? ((Get-Content $stderr -ReadCount 2000 | Measure-Object -Line).Lines) : 0
      if ($cErr -gt 0) { & pwsh -NoProfile -ExecutionPolicy Bypass -File $tri -OneLine }
    }
  }
} catch {}