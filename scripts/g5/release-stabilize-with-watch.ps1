#requires -Version 7.0
param(
  [string]$Tag,
  [string]$Root,
  [switch]$CreateReleasePage,
  [int]$BadgeTimeoutSec = 900,
  [int]$WatchIntervalSec = 6,
  [switch]$CommentRelease,   # 릴리즈 노트에 결과 추가
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
  if ($top) { return $top }
  return (Get-Location).Path
}
$RepoRoot = Resolve-RepoRoot -Root $Root
Set-Location $RepoRoot

# 락
$LockFile = Join-Path $RepoRoot '.gpt5.lock'
if (Test-Path $LockFile) { Write-Error 'CONFLICT: .gpt5.lock exists.'; exit 11 }
"locked $(Get-Date -Format o)" | Out-File $LockFile -NoNewline
$sw=[Diagnostics.Stopwatch]::StartNew()
$trace=[guid]::NewGuid().ToString()
$log=Join-Path $RepoRoot 'logs\apply-log.jsonl'
New-Item -ItemType Directory -Force -Path (Split-Path $log) | Out-Null

try {
  $env:GIT_PAGER='' ; $env:LESS='-FRX' ; $env:GIT_TERMINAL_PROMPT='0'

  # 1) 최신 태그 감지(미지정 시)
  if ([string]::IsNullOrWhiteSpace($Tag)) {
    $Tag = (git tag --sort=-v:refname | Select-Object -First 1).Trim()
    if (-not $Tag) { throw "No tags found." }
  }

  # 2) 원래 stabilize 실행(있을 때만)
  $st = Join-Path $RepoRoot 'scripts\g5\release-stabilize.ps1'
  if (Test-Path $st) {
    $args=@('-Tag',$Tag)
    if ($CreateReleasePage) { $args += '-CreateReleasePage' }
    if ($ConfirmApply) { $args += '-ConfirmApply' }
    pwsh -File $st @args
  } else {
    Write-Warning "release-stabilize.ps1 not found — skipping stabilize step"
  }

  # 3) 배지 감시(있을 때만)
  $watch = Join-Path $RepoRoot 'scripts\g5\watch-badge-ready.ps1'
  if (Test-Path $watch) {
    $args=@('-Tag',$Tag,'-Root',$RepoRoot,'-BadgeTimeoutSec',$BadgeTimeoutSec,'-WatchIntervalSec',$WatchIntervalSec)
    if ($ConfirmApply) { $args += '-ConfirmApply' }
    $out = pwsh -File $watch @args 2>&1 | Out-String
    Write-Host $out
    $checksOk = [bool]([regex]::IsMatch($out,'checks=True','IgnoreCase'))
    $readmeOk = [bool]([regex]::IsMatch($out,'readme=True','IgnoreCase'))

    # 4) 릴리즈 노트에 결과 추가(옵션)
    if ($CommentRelease) {
      $append = Join-Path $RepoRoot 'scripts\g5\release-append-badge.ps1'
      if (Test-Path $append) {
        pwsh -File $append -Tag $Tag -Root $RepoRoot -WatchOutput $out -ChecksOk $checksOk -ReadmeOk $readmeOk
      }
    }

    $outcome = if ($checksOk -and $readmeOk) { 'OK' } else { 'PARTIAL' }
    $msg = "tag=$Tag; checks=$checksOk; readme=$readmeOk"
  } else {
    $outcome='PARTIAL'; $msg="tag=$Tag; watcher missing"
    Write-Warning "watch-badge-ready.ps1 not found — skipping watch step"
  }

  $rec=@{timestamp=(Get-Date).ToString('o');level='INFO';traceId=$trace;module='release';action='stabilize-with-watch';inputHash=$Tag;outcome=$outcome;durationMs=$sw.ElapsedMilliseconds;errorCode='';message=$msg} | ConvertTo-Json -Compress
  Add-Content -Path $log -Value $rec

  if ($outcome -eq 'OK') { exit 0 } else { exit 12 }
}
catch {
  $err=$_.Exception.Message; $stk=$_.ScriptStackTrace
  $rec=@{timestamp=(Get-Date).ToString('o');level='ERROR';traceId=$trace;module='release';action='stabilize-with-watch';inputHash=$Tag;outcome='FAILURE';durationMs=$sw.ElapsedMilliseconds;errorCode=$err;message=$stk} | ConvertTo-Json -Compress
  Add-Content -Path $log -Value $rec
  exit 13
}
finally {
  Remove-Item -Force $LockFile -ErrorAction SilentlyContinue
}
