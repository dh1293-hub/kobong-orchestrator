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
  param(
    [string]$Level,[string]$Action,[string]$Outcome,[string]$Message,
    [string]$Module='runner',[string]$ErrorCode=''
  )
  $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
  $jsonl = Join-Path $repoRoot 'logs\apply-log.jsonl'
  try {
    if (Get-Command kobong_logger_cli -ErrorAction SilentlyContinue) {
      & kobong_logger_cli log --level $Level --module $Module --action $Action --outcome $Outcome --error $ErrorCode --message $Message
      return
    }
  } catch {}
  $rec = @{
    timestamp=(Get-Date).ToString('o'); level=$Level; module=$Module; action=$Action; outcome=$Outcome; error=$ErrorCode; message=$Message; traceId=[guid]::NewGuid().ToString()
  } | ConvertTo-Json -Compress
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

$exitCode = 0
try {
  # 모든 스트림 분리 캡처 (PS7)
  & $target @Args 1> $stdout 2> $stderr 3> $warnf 4> $verbosef 5> $debugf 6> $infof
  if ($LASTEXITCODE) { $exitCode = $LASTEXITCODE }
} catch {
  $exitCode = 1
  $_ | Out-String | Set-Content -Path $stderr
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

$levelEmit   = $(if ($exitCode -eq 0 -and $cErr -eq 0) { 'INFO' } else { 'ERROR' })
$outcomeEmit = $(if ($exitCode -eq 0 -and $cErr -eq 0) { 'SUCCESS' } else { 'FAILURE' })
$errCodeEmit = $(if ($exitCode -eq 0 -and $cErr -eq 0) { '' } else { 'LOGIC' })

$msg = "exit=$exitCode; out=$cOut, warn=$cWrn, err=$cErr, info=$cInf, verbose=$cVer, debug=$cDbg"
if ($sampleErr) { $msg += "; errSample=" + $sampleErr }
if ($sampleWrn) { $msg += "; warnSample=" + $sampleWrn }

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

# 배열 안에서 if를 쓰지 말고, 조건부 추가는 += 로 분리
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
$sumPath = Join-Path $runDir 'summary.md'
[System.IO.File]::WriteAllText($sumPath, ([string]::Join("`n",$sumMd) + "`n"), (New-Object System.Text.UTF8Encoding($false)))

Write-Host "[OK] Run logs at: $runDir" -ForegroundColor Green
if ($outcomeEmit -ne 'SUCCESS') { Write-Host "[HINT] Check stderr: $stderr" -ForegroundColor DarkYellow }Write-Host "[OK] Run logs at: $runDir" -ForegroundColor Green
if ($outcomeEmit -ne 'SUCCESS') { Write-Host "[HINT] Check stderr: $stderr" -ForegroundColor DarkYellow }