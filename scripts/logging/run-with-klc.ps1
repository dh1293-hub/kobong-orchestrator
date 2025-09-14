#requires -Version 7.0
param(
  [Parameter(Mandatory)]
  [string]$File,
  [string[]]$Args = @(),
  [string]$Name,
  [string]$OutRoot
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

# 대상 스크립트 확인
if (-not (Test-Path $File)) { throw "PRECONDITION: target script not found: $File" }
$Name = if ($Name) { $Name } else { [IO.Path]::GetFileNameWithoutExtension((Split-Path -Leaf $File)) }
$ts   = Get-Date -Format 'yyyyMMdd-HHmmss'
$RunDir = Join-Path $OutRoot ("{0}-{1}" -f $ts,$Name)
New-Item -ItemType Directory -Force -Path $RunDir | Out-Null

# 실행 준비
$stdout = Join-Path $RunDir 'stdout.log'
$stderr = Join-Path $RunDir 'stderr.log'
$runJson= Join-Path $RunDir 'run.json'

# PS7 경로
$pwsh = $env:ProgramW6432; if ($pwsh) { $pwsh = Join-Path $pwsh 'PowerShell\7\pwsh.exe' }
if (-not (Test-Path $pwsh)) { $pwsh = 'pwsh' }

# 대상 실행 (외부 pwsh로 호출 → $LASTEXITCODE 확실)
$arglist = @('-NoProfile','-ExecutionPolicy','Bypass','-File', (Resolve-Path $File).Path)
if ($Args -and $Args.Count -gt 0) { $arglist += $Args }

# 출력 리다이렉션
& $pwsh @arglist 1> $stdout 2> $stderr
$exit = $LASTEXITCODE
if ($null -eq $exit) { $exit = 0 }

# 카운트 계산
function CountOrZero($p){ if (Test-Path $p) { (Get-Content $p -ReadCount 2000 | Measure-Object -Line).Lines } else { 0 } }
$cOut = CountOrZero $stdout
$cErr = CountOrZero $stderr

# run.json 작성
$meta = [pscustomobject]@{
  time    = (Get-Date).ToString('o')
  name    = $Name
  target  = $File
  args    = $Args
  exit    = $exit
  counts  = @{ out=$cOut; err=$cErr; warn=0; info=1; verbose=0; debug=0 }
  dir     = $RunDir
}
$meta | ConvertTo-Json -Depth 5 | Out-File -FilePath $runJson -Encoding utf8

# JSONL 로그 한 줄(요약)
try {
  $jsonl = Join-Path $RepoRoot 'logs\apply-log.jsonl'
  New-Item -ItemType Directory -Force -Path (Split-Path $jsonl) | Out-Null
  $rec = @{
    timestamp = (Get-Date).ToString('o')
    level     = if ($exit -eq 0) { 'INFO' } else { 'ERROR' }
    module    = 'runner'
    action    = 'run-with-klc'
    outcome   = if ($exit -eq 0) { 'SUCCESS' } else { 'FAILURE' }
    message   = "name=$Name exit=$exit out=$cOut err=$cErr"
  } | ConvertTo-Json -Compress
  Add-Content -Path $jsonl -Value $rec
} catch {}

Write-Host ("[OK] Run logs at: {0}" -f $RunDir)

# === G5 AUTO-HOOK (console handoff) ===
try {
  $g5   = Join-Path $RepoRoot 'scripts\g5\g5-brief.ps1'
  if (Test-Path $g5) { & pwsh -NoProfile -ExecutionPolicy Bypass -File $g5 -OneLine }
  $tri  = Join-Path $RepoRoot 'scripts\g5\g5-triage.ps1'
  if (Test-Path $tri) {
    $cErr2 = $cErr
    if ($cErr2 -gt 0) { & pwsh -NoProfile -ExecutionPolicy Bypass -File $tri -OneLine }
  }
} catch {}