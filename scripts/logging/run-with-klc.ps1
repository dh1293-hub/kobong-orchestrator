#requires -Version 7.0
param(
  [Parameter(Mandatory)][string]$File,
  [string[]]$Args = @(),
  [string]$Name,
  [string]$OutRoot,
  [int]$TimeoutSec = 300,
  [switch]$KillTree,
  [switch]$NoG5
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

$RepoRoot = Get-RepoRoot
if ([string]::IsNullOrWhiteSpace($OutRoot)) { $OutRoot = Join-Path $RepoRoot 'out\run-logs' }

if (-not (Test-Path $File)) { throw "PRECONDITION: target script not found: $File" }
$Name   = if ($Name) { $Name } else { [IO.Path]::GetFileNameWithoutExtension((Split-Path -Leaf $File)) }
$ts     = Get-Date -Format 'yyyyMMdd-HHmmss'
$RunDir = Join-Path $OutRoot ("{0}-{1}" -f $ts,$Name)
New-Item -ItemType Directory -Force -Path $RunDir | Out-Null

$stdout = Join-Path $RunDir 'stdout.log'
$stderr = Join-Path $RunDir 'stderr.log'
$runJson= Join-Path $RunDir 'run.json'

# pwsh 경로
$pwsh = $env:ProgramW6432; if ($pwsh) { $pwsh = Join-Path $pwsh 'PowerShell\7\pwsh.exe' }
if (-not (Test-Path $pwsh)) { $pwsh = 'pwsh' }

# 인자 문자열(공백 안전 인용)
$scriptPath = (Resolve-Path $File).Path
function Q([string]$s){ if ($s -match '\s' -or $s -match '"') { '"' + ($s -replace '"','\"') + '"' } else { $s } }
$arglist = @('-NoProfile','-ExecutionPolicy','Bypass','-File', $scriptPath) + $Args
$argstr  = ($arglist | ForEach-Object { Q $_ }) -join ' '

# 실행 (비동기) + 타임아웃 감시
$p = Start-Process -FilePath $pwsh -ArgumentList $argstr -RedirectStandardOutput $stdout -RedirectStandardError $stderr -NoNewWindow -PassThru
$exited = $false
try {
  $null = Wait-Process -Id $p.Id -Timeout $TimeoutSec -ErrorAction SilentlyContinue
  $exited = $p.HasExited
} catch { $exited = $false }

if (-not $exited) {
  # 타임아웃: 강제 종료
  if ($KillTree) {
    try { & taskkill /PID $p.Id /T /F | Out-Null } catch {}
  } else {
    try { Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue } catch {}
  }
}

$exit = if ($p.HasExited) { $p.ExitCode } else { 124 }  # 124=timeout convention

function CountOrZero($p){ if (Test-Path $p) { (Get-Content $p -ReadCount 2000 | Measure-Object -Line).Lines } else { 0 } }
$cOut = CountOrZero $stdout
$cErr = CountOrZero $stderr

# run.json
$meta = [pscustomobject]@{
  time    = (Get-Date).ToString('o')
  name    = $Name
  target  = $File
  args    = $Args
  exit    = $exit
  timedOut= (-not $exited)
  counts  = @{ out=$cOut; err=$cErr; warn=0; info=1; verbose=0; debug=0 }
  dir     = $RunDir
}
$meta | ConvertTo-Json -Depth 5 | Out-File -FilePath $runJson -Encoding utf8

# JSONL 요약
try {
  $jsonl = Join-Path $RepoRoot 'logs\apply-log.jsonl'
  New-Item -ItemType Directory -Force -Path (Split-Path $jsonl) | Out-Null
  $outcome = if ($exit -eq 0) { 'SUCCESS' } elseif ($exit -eq 124) { 'FAILURE' } else { 'FAILURE' }
  $lvl = if ($outcome -eq 'SUCCESS') { 'INFO' } else { 'ERROR' }
  $msg = "name=$Name exit=$exit timeout=$(-not $exited) out=$cOut err=$cErr"
  @{timestamp=(Get-Date).ToString('o'); level=$lvl; module='runner'; action='run-with-klc'; outcome=$outcome; message=$msg} |
    ConvertTo-Json -Compress | Add-Content -Path $jsonl
} catch {}

Write-Host ("[OK] Run logs at: {0}" -f $RunDir)

# === G5 AUTO-HOOK (console handoff) ===
if (-not $NoG5) {
  try {
    $g5   = Join-Path $RepoRoot 'scripts\g5\g5-brief.ps1'
    if (Test-Path $g5) { & pwsh -NoProfile -ExecutionPolicy Bypass -File $g5 -OneLine }
    $tri  = Join-Path $RepoRoot 'scripts\g5\g5-triage.ps1'
    if (Test-Path $tri -and $cErr -gt 0) { & pwsh -NoProfile -ExecutionPolicy Bypass -File $tri -OneLine }
  } catch {}
}