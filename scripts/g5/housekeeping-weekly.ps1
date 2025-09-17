#requires -Version 7.0
param(
  [string]$Root,
  [int]$MaxLines = 50000,
  [int]$MaxBytes = 5MB,
  [switch]$ConfirmApply
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

function Resolve-RepoRoot {
  param([string]$Root)
  if (-not [string]::IsNullOrWhiteSpace($Root)) { return (Resolve-Path $Root).Path }
  $top = (& git rev-parse --show-toplevel 2>$null)
  if (-not [string]::IsNullOrWhiteSpace($top)) { return $top }
  return (Get-Location).Path
}

$RepoRoot = Resolve-RepoRoot -Root $Root
if ([string]::IsNullOrWhiteSpace($RepoRoot)) { throw "PRECONDITION: RepoRoot resolved empty." }
if (-not (Test-Path $RepoRoot)) { throw "PRECONDITION: RepoRoot not found: $RepoRoot" }
Set-Location $RepoRoot

# wrapper 전용 락(내부 도구들과 충돌 방지)
$WrapLock = Join-Path $RepoRoot '.gpt5.housekeeping.lock'
if (Test-Path $WrapLock) { Write-Error 'CONFLICT: .gpt5.housekeeping.lock exists.'; exit 11 }
"locked $(Get-Date -Format o)" | Out-File $WrapLock -NoNewline

$sw=[Diagnostics.Stopwatch]::StartNew()
$trace=[guid]::NewGuid().ToString()
try {
  $env:GIT_PAGER='' ; $env:LESS='-FRX'

  # 1) 로컬 브랜치 정리(quiet)
  $bp = Join-Path $RepoRoot 'scripts\g5\branch-prune-quiet.ps1'
  if (Test-Path $bp) {
    $args=@()
    if ($ConfirmApply) { $args += '-ConfirmApply' }
    pwsh -File $bp @args
  } else {
    Write-Warning "branch-prune-quiet.ps1 not found — skipping"
  }

  # 2) 로그 로테이션
  $rot = Join-Path $RepoRoot 'scripts\g5\rotate-apply-log.ps1'
  if (Test-Path $rot) {
    $args=@('-MaxLines', $MaxLines, '-MaxBytes', $MaxBytes)
    if ($ConfirmApply) { $args += '-ConfirmApply' }
    pwsh -File $rot @args
  } else {
    Write-Warning "rotate-apply-log.ps1 not found — skipping"
  }

  # 기록
  $rec=@{
    timestamp=(Get-Date).ToString('o'); level='INFO'; traceId=$trace;
    module='ops'; action='housekeeping-weekly'; inputHash="$MaxLines/$MaxBytes";
    outcome='OK'; durationMs=$sw.ElapsedMilliseconds; errorCode='';
    message='branch-prune + log-rotate executed'
  } | ConvertTo-Json -Compress
  $log=Join-Path $RepoRoot 'logs\apply-log.jsonl'
  New-Item -ItemType Directory -Force -Path (Split-Path $log) | Out-Null
  Add-Content -Path $log -Value $rec
  exit 0
}
catch {
  $err=$_.Exception.Message; $stk=$_.ScriptStackTrace
  $rec=@{timestamp=(Get-Date).ToString('o');level='ERROR';traceId=$trace;module='ops';action='housekeeping-weekly';inputHash='';outcome='FAILURE';durationMs=$sw.ElapsedMilliseconds;errorCode=$err;message=$stk} | ConvertTo-Json -Compress
  $log=Join-Path $RepoRoot 'logs\apply-log.jsonl'
  New-Item -ItemType Directory -Force -Path (Split-Path $log) | Out-Null
  Add-Content -Path $log -Value $rec
  exit 13
}
finally {
  Remove-Item -Force $WrapLock -ErrorAction SilentlyContinue
}
