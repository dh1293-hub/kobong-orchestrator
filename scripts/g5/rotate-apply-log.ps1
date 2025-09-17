#requires -Version 7.0
param(
  [int]$MaxLines = 50000,
  [int]$MaxBytes = 5MB,
  [string]$Root,
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
Set-Location $RepoRoot

$LockFile = Join-Path $RepoRoot '.gpt5.lock'
if (Test-Path $LockFile) { Write-Error 'CONFLICT: .gpt5.lock exists.'; exit 11 }
"locked $(Get-Date -Format o)" | Out-File $LockFile -NoNewline
$sw=[Diagnostics.Stopwatch]::StartNew()
$trace=[guid]::NewGuid().ToString()

try {
  $log = Join-Path $RepoRoot 'logs\apply-log.jsonl'
  if (-not (Test-Path $log)) { Write-Host "[SKIP] no log file"; exit 0 }

  $fi = Get-Item $log

  # 빠른 라인 카운트(.NET ReadLines) — PowerShell 7 이상
  $lineCount = [int][Linq.Enumerable]::Count([System.IO.File]::ReadLines($log))
  $need = ($fi.Length -gt $MaxBytes) -or ($lineCount -gt $MaxLines)

  if (-not $need) {
    Write-Host "[OK] rotation not needed (size=$($fi.Length) bytes, lines=$lineCount)"
    exit 0
  }

  # 최신 N줄만 보존
  $tail = Get-Content $log -Tail $MaxLines -Encoding utf8
  $tmp2 = "$log.tmp"
  $tail | Out-File -FilePath $tmp2 -Encoding utf8
  $bak  = "$log.bak-$(Get-Date -Format yyyyMMdd-HHmmss)"
  Move-Item -Force $log $bak
  Move-Item -Force $tmp2 $log

  Write-Host "[ROTATE] kept last $MaxLines lines (old → $([System.IO.Path]::GetFileName($bak)))"

  # 기록(회전된 새 로그에 남김)
  $rec=@{timestamp=(Get-Date).ToString('o');level='INFO';traceId=$trace;module='logs';action='rotate-apply-log';inputHash="$MaxLines/$MaxBytes";outcome='APPLIED';durationMs=$sw.ElapsedMilliseconds;errorCode='';message="sizeWas=$($fi.Length) linesWas=$lineCount"} | ConvertTo-Json -Compress
  Add-Content -Path $log -Value $rec
}
catch {
  $err=$_.Exception.Message; $stk=$_.ScriptStackTrace
  $rec=@{timestamp=(Get-Date).ToString('o');level='ERROR';traceId=$trace;module='logs';action='rotate-apply-log';inputHash='';outcome='FAILURE';durationMs=$sw.ElapsedMilliseconds;errorCode=$err;message=$stk} | ConvertTo-Json -Compress
  $log2=Join-Path $RepoRoot 'logs\apply-log.jsonl'
  New-Item -ItemType Directory -Force -Path (Split-Path $log2) | Out-Null
  Add-Content -Path $log2 -Value $rec
  exit 13
}
finally {
  Remove-Item -Force $LockFile -ErrorAction SilentlyContinue
}
