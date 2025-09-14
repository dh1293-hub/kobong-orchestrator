#requires -Version 7.0
param([string]$RunDir)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$Root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$Runs = Join-Path $Root 'out\run-logs'
function Pick-Latest { if ($RunDir) { (Resolve-Path $RunDir).Path } else { Get-ChildItem -Path $Runs -Directory | Sort-Object LastWriteTime | Select-Object -Last 1 -ExpandProperty FullName } }
$dir = Pick-Latest
if (-not $dir) { throw "No run-logs found." }
$m = Join-Path $dir 'run.json'
$stdout = Join-Path $dir 'stdout.log'
$stderr = Join-Path $dir 'stderr.log'
$warnf  = Join-Path $dir 'warn.log'
$infof  = Join-Path $dir 'info.log'
$verf   = Join-Path $dir 'verbose.log'
$dbgf   = Join-Path $dir 'debug.log'
function CountOrZero($p){ if (Test-Path $p) { (Get-Content $p -ReadCount 1000 | Measure-Object -Line).Lines } else { 0 } }
if (Test-Path $m) {
  $man = Get-Content -Raw -Path $m | ConvertFrom-Json
  $name=$man.name; $target=$man.target; $args=$man.args; $outcome=$man.outcome; $exit=$man.exitCode; $c=$man.counts; $errS=$man.samples.err; $wrnS=$man.samples.warn
} else {
  $name = Split-Path $dir -Leaf; $target="(unknown)"; $args=""; $exit=0; $outcome="(unknown)"
  $c = @{
    stdout=(CountOrZero $stdout); stderr=(CountOrZero $stderr); warn=(CountOrZero $warnf);
    info=(CountOrZero $infof); verbose=(CountOrZero $verf); debug=(CountOrZero $dbgf)
  }
  $errS = if (Test-Path $stderr) { (Get-Content $stderr -TotalCount 2) -join ' | ' } else { "" }
  $wrnS = if (Test-Path $warnf)  { (Get-Content $warnf  -TotalCount 2) -join ' | ' } else { "" }
}
Write-Host "== RUN SUMMARY ==" -ForegroundColor Magenta
Write-Host ("Dir: {0}" -f $dir)
Write-Host ("Name: {0}" -f $name)
Write-Host ("Target: {0}" -f $target)
Write-Host ("Args: {0}" -f $args)
Write-Host ("Outcome: {0} (exit={1})" -f $outcome,$exit)
Write-Host ("Counts: out={0}, warn={1}, err={2}, info={3}, verbose={4}, debug={5}" -f $c.stdout,$c.warn,$c.stderr,$c.info,$c.verbose,$c.debug)
if ($errS) { Write-Host ("ErrSample: {0}" -f $errS) -ForegroundColor DarkYellow }
if ($wrnS) { Write-Host ("WarnSample: {0}" -f $wrnS) -ForegroundColor DarkYellow }