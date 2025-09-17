#requires -Version 7.0
param(
  [string]$Root,
  [string[]]$TrainArgs,
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

# 별도 래퍼 락(.gpt5.wrapper.lock) — release-train의 .gpt5.lock과 충돌 피함
$WrapLock = Join-Path $RepoRoot '.gpt5.release-train-wrapper.lock'
if (Test-Path $WrapLock) { Write-Error 'CONFLICT: .gpt5.release-train-wrapper.lock exists.'; exit 11 }
"locked $(Get-Date -Format o)" | Out-File $WrapLock -NoNewline

$sw=[Diagnostics.Stopwatch]::StartNew()
$trace=[guid]::NewGuid().ToString()
try {
  # 1) release-train 실행 (인자 그대로 전달)
  $train = Join-Path $RepoRoot 'scripts\g5\release-train.ps1'
  if (-not (Test-Path $train)) { throw "release-train.ps1 not found: $train" }
  $args = @()
  if ($TrainArgs) { $args += $TrainArgs }
  if ($ConfirmApply) { $args += '-ConfirmApply' }
  pwsh -File $train @args

  # 2) 최신 태그 결정
  $tag = (& git describe --tags --abbrev=0 2>$null)
  if ([string]::IsNullOrWhiteSpace($tag)) { throw "No tag found after release-train." }

  # 3) 배지 감시 호출
  $watch = Join-Path $RepoRoot 'scripts\g5\watch-badge-ready.ps1'
  if (-not (Test-Path $watch)) { throw "watch-badge-ready.ps1 not found: $watch" }
  $watchArgs = @('-Tag', $tag, '-Root', $RepoRoot)
  if ($ConfirmApply) { $watchArgs += '-ConfirmApply' }
  pwsh -File $watch @watchArgs

  # 4) 로그
  $rec=@{
    timestamp=(Get-Date).ToString('o'); level='INFO'; traceId=$trace;
    module='release'; action='train+watch'; inputHash=$tag; outcome='OK';
    durationMs=$sw.ElapsedMilliseconds; errorCode=''; message="release-train + watch-badge-ready succeeded"
  } | ConvertTo-Json -Compress
  $log=Join-Path $RepoRoot 'logs\apply-log.jsonl'
  New-Item -ItemType Directory -Force -Path (Split-Path $log) | Out-Null
  Add-Content -Path $log -Value $rec

  exit 0
}
catch {
  $err=$_.Exception.Message; $stk=$_.ScriptStackTrace
  $rec=@{timestamp=(Get-Date).ToString('o');level='ERROR';traceId=$trace;module='release';action='train+watch';inputHash='';outcome='FAILURE';durationMs=$sw.ElapsedMilliseconds;errorCode=$err;message=$stk} | ConvertTo-Json -Compress
  $log=Join-Path $RepoRoot 'logs\apply-log.jsonl'
  New-Item -ItemType Directory -Force -Path (Split-Path $log) | Out-Null
  Add-Content -Path $log -Value $rec
  exit 13
}
finally {
  Remove-Item -Force $WrapLock -ErrorAction SilentlyContinue
}
