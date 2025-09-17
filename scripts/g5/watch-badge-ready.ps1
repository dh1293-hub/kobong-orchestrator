#requires -Version 7.0
param(
  [Parameter(Mandatory=$true)][string]$Tag,
  [switch]$ConfirmApply,
  [string]$Root,
  [int]$BadgeTimeoutSec = 720,
  [int]$WatchIntervalSec = 6
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

function Resolve-RepoRoot {
  param([string]$Root)
  if (-not [string]::IsNullOrWhiteSpace($Root)) { return (Resolve-Path $Root).Path }
  if (-not [string]::IsNullOrWhiteSpace($env:GITHUB_WORKSPACE)) { return $env:GITHUB_WORKSPACE }
  $top = (& git rev-parse --show-toplevel 2>$null)
  if (-not [string]::IsNullOrWhiteSpace($top)) { return $top }
  return (Get-Location).Path
}

$RepoRoot = Resolve-RepoRoot -Root $Root
if ([string]::IsNullOrWhiteSpace($RepoRoot)) { throw "PRECONDITION: RepoRoot resolved empty." }
if (-not (Test-Path $RepoRoot)) { throw "PRECONDITION: RepoRoot not found: $RepoRoot" }
Set-Location $RepoRoot

$OwnerRepo  = 'dh1293-hub/kobong-orchestrator'
$DocsBranch = "docs/readme-badge-$Tag"

# ---- Lock (local) ----
$LockFile = Join-Path $RepoRoot '.gpt5.lock'
if (Test-Path $LockFile) { Write-Error 'CONFLICT: .gpt5.lock exists.'; exit 11 }
"locked $(Get-Date -Format o)" | Out-File $LockFile -NoNewline

$sw=[Diagnostics.Stopwatch]::StartNew()
$trace=[guid]::NewGuid().ToString()
try {
  $deadline = (Get-Date).AddSeconds($BadgeTimeoutSec)
  $okReadme=$false; $okChecks=$false

  while ((Get-Date) -lt $deadline) {
    # 1) docs 브랜치 워크플로 성공 여부
    $runs = gh run list --branch $DocsBranch --limit 10 --json databaseId,status,conclusion,displayTitle 2>$null | ConvertFrom-Json
    $last = $runs | Select-Object -First 1
    if ($last -and $last.status -eq 'completed' -and $last.conclusion -eq 'success') { $okChecks=$true }

    # 2) README@main에 Tag 노출 여부
    $readme = gh api -H "Accept: application/vnd.github.raw" repos/$OwnerRepo/contents/README.md?ref=main 2>$null
    if ($LASTEXITCODE -eq 0 -and $readme -match [regex]::Escape($Tag)) { $okReadme=$true }

    if ($okChecks -and $okReadme) { break }
    Start-Sleep -Seconds $WatchIntervalSec
  }

  if ($ConfirmApply -and (Test-Path 'scripts\g5\pr-badge-dedupe.ps1')) {
    pwsh -File .\scripts\g5\pr-badge-dedupe.ps1 -Tag $Tag -ConfirmApply
  }

  $success = ($okChecks -and $okReadme)
  $outcome = if ($success) {'OK'} else {'TIMEOUT'}
  $level   = if ($success) {'INFO'} else {'WARN'}
  $code    = if ($success) {0} else {12}  # 12=TRANSIENT

  $rec=@{
    timestamp=(Get-Date).ToString('o'); level=$level; traceId=$trace;
    module='release'; action='watch-badge-ready'; inputHash=$Tag; outcome=$outcome;
    durationMs=$sw.ElapsedMilliseconds; errorCode=''; message="checks=$okChecks, readme=$okReadme"
  } | ConvertTo-Json -Compress
  $log=Join-Path $RepoRoot 'logs/apply-log.jsonl'
  New-Item -ItemType Directory -Force -Path (Split-Path $log) | Out-Null
  Add-Content -Path $log -Value $rec
  exit $code
}
catch {
  $err=$_.Exception.Message; $stk=$_.ScriptStackTrace
  $rec=@{timestamp=(Get-Date).ToString('o');level='ERROR';traceId=$trace;module='release';action='watch-badge-ready';inputHash=$Tag;outcome='FAILURE';durationMs=$sw.ElapsedMilliseconds;errorCode=$err;message=$stk} | ConvertTo-Json -Compress
  $log=Join-Path $RepoRoot 'logs/apply-log.jsonl'
  New-Item -ItemType Directory -Force -Path (Split-Path $log) | Out-Null
  Add-Content -Path $log -Value $rec
  exit 13
}
finally {
  Remove-Item -Force $LockFile -ErrorAction SilentlyContinue
}
