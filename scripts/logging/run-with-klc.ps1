#requires -Version 7.0
param(
  [Parameter(Mandatory)][string]$File,
  [Alias("Args")][string[]]$ChildArgs = @(),
  [int]$TimeoutSec = 120,
  [switch]$Quiet
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'

function Log($level,$action,$outcome,$code,$msg) {
  try {
    if (Get-Command kobong_logger_cli -ErrorAction SilentlyContinue) {
      if ($null -eq $code) { $code='' }; if ($null -eq $msg) { $msg='' }
      & kobong_logger_cli log --level $level --module 'runner' --action $action --outcome $outcome --error $code --message $msg 2>$null
      return
    }
  } catch {}
  try {
    $RepoRoot = try { git rev-parse --show-toplevel 2>$null } catch { (Get-Location).Path }
    $log = Join-Path $RepoRoot 'logs/apply-log.jsonl'
    New-Item -ItemType Directory -Force -Path (Split-Path $log) | Out-Null
    $obj=@{timestamp=(Get-Date).ToString('o');level=$level;module='runner';action=$action;outcome=$outcome;errorCode=$code;message=$msg;traceId=[guid]::NewGuid().ToString()}
    Add-Content -Path $log -Value ($obj | ConvertTo-Json -Compress)
  } catch {}
}

$here = Get-Location
$ts   = (Get-Date).ToString('yyyyMMdd-HHmmss')
$outDir = Join-Path $here 'logs/run'
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
$outFile = Join-Path $outDir ("out-$ts.log")
$errFile = Join-Path $outDir ("err-$ts.log")

# 실행 대상/인자 구성 (ps1 → pwsh -File)
$exe = $File
$argList = @()
if ([IO.Path]::GetExtension($File).ToLowerInvariant() -eq '.ps1') {
  $exe = (Get-Command pwsh).Source
  $scriptPath = (Resolve-Path $File).Path
  $argList = @('-NoProfile','-File', $scriptPath) + $ChildArgs
} else {
  $argList = $ChildArgs
}

# Start-Process: -WindowStyle 'Hidden' 유지, -NoNewWindow 제거(충돌 방지)
$psi = @{
  FilePath = $exe
  ArgumentList = $argList
  RedirectStandardOutput = $outFile
  RedirectStandardError  = $errFile
  WorkingDirectory = $here.Path
  WindowStyle = 'Hidden'
  PassThru = $true
}
$proc = Start-Process @psi

$timedOut = $false
if ($TimeoutSec -gt 0) {
  if (-not ($proc.WaitForExit($TimeoutSec * 1000))) {
    $timedOut = $true
    try { Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue } catch {}
  }
} else { $proc.WaitForExit() }

$exit = if ($timedOut) { 124 } else { try { $proc.ExitCode } catch { 1 } }
$outLines = if (Test-Path $outFile) { (Get-Content $outFile).Count } else { 0 }
$errLines = if (Test-Path $errFile) { (Get-Content $errFile).Count } else { 0 }

$summary = "name=$File exit=$exit timeout=$timedOut out=$outLines err=$errLines"
if (-not $Quiet) {
  if (Test-Path $outFile) { Get-Content $outFile | Write-Output }
  if (Test-Path $errFile) { Get-Content $errFile | Write-Error }
  Write-Host "[RUN] $summary"
}

if ($exit -eq 0 -and -not $timedOut) { Log 'INFO' 'run-with-klc' 'SUCCESS' '' $summary }
elseif ($timedOut)                { Log 'ERROR' 'run-with-klc' 'FAILURE' 'TIMEOUT' $summary }
else                              { Log 'ERROR' 'run-with-klc' 'FAILURE' ("EXIT:$exit") $summary }
exit $exit