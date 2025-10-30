# 파일: scripts/g5/housekeeping-smoke.ps1
# 목적: 하우스키핑 스모크(읽기 전용 점검). OK/WARN/FAIL 집계 후 종료코드 반환(0=성공, 1=실패 존재).
# 산출물: 콘솔 표/요약, KLC 1행 로그. -SummaryPath 지정 시 MD 요약 파일 생성.

[CmdletBinding()]
param(
  [switch]$Strict,
  [ValidateRange(0,100)][int]$MinDiskFreePercent = 1,
  [string]$SummaryPath
)

$ErrorActionPreference = 'Stop'
$ProgressPreference    = 'SilentlyContinue'

# SummaryPath에 폴더가 포함되면 미리 생성(운영 안정성)
if ($SummaryPath) {
  try {
    $dir = Split-Path -Parent $SummaryPath
    if ($dir) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
  } catch { }
}

function Invoke-Check {
  param(
    [Parameter(Mandatory)][string]$Name,
    [Parameter(Mandatory)][scriptblock]$Action,
    [string]$OnFail = '',
    [string]$OnWarn = ''
  )
  $sw = [System.Diagnostics.Stopwatch]::StartNew()
  $status  = 'OK'
  $message = ''
  try {
    $r = & $Action
    if ($null -ne $r -and $r -is [hashtable]) {
      if ($r.ContainsKey('Status'))  { $status  = [string]$r.Status }
      if ($r.ContainsKey('Message')) { $message = [string]$r.Message }
    }
  } catch {
    $status  = 'FAIL'
    $message = $_.Exception.Message
    if ($OnFail) { $message = "$message | $OnFail" }
  } finally {
    $sw.Stop()
  }
  [pscustomobject]@{
    Name       = $Name
    Status     = $status
    Message    = $message
    DurationMs = [int]$sw.Elapsed.TotalMilliseconds
  }
}

# ✅ 여기부터 배열 누적 방식으로 변경 ($results += ...)
$results = @()

# 1) PowerShell 7.2+
$results += Invoke-Check -Name 'PowerShell version (>=7.2)' -Action {
  $v = $PSVersionTable.PSVersion
  if ($v.Major -lt 7 -or ($v.Major -eq 7 -and $v.Minor -lt 2)) {
    return @{ Status='FAIL'; Message="pwsh=$v (need >= 7.2)" }
  }
  return @{ Status='OK'; Message="pwsh=$v" }
}

# 2) git
$results += Invoke-Check -Name 'git available' -Action {
  $out = & git --version 2>$null
  if ($LASTEXITCODE -ne 0 -or -not $out) { return @{ Status='FAIL'; Message='git not found' } }
  return @{ Status='OK'; Message=$out.Trim() }
}

# 3) gh (optional)
$results += Invoke-Check -Name 'gh available' -Action {
  $out = & gh --version 2>$null
  if ($LASTEXITCODE -ne 0 -or -not $out) { return @{ Status='WARN'; Message='gh not found (optional)' } }
  return @{ Status='OK'; Message=($out -split "`n")[0].Trim() }
}

# 4) .git 존재(없으면 WARN)
$results += Invoke-Check -Name '.git present' -Action {
  if (Test-Path -LiteralPath '.git') { return @{ Status='OK'; Message='found' } }
  return @{ Status='WARN'; Message='not found (detached or archive checkout?)' }
}

# 5) 필수 디렉터리: .github/workflows
$results += Invoke-Check -Name 'dir: .github/workflows' -Action {
  if (Test-Path -LiteralPath '.github/workflows') { return @{ Status='OK'; Message='exists' } }
  return @{ Status='FAIL'; Message='missing' }
}

# 6) 필수 디렉터리: scripts/g5
$results += Invoke-Check -Name 'dir: scripts/g5' -Action {
  if (Test-Path -LiteralPath 'scripts/g5') { return @{ Status='OK'; Message='exists' } }
  return @{ Status='FAIL'; Message='missing' }
}

# 7) 작업 드라이브 여유 공간(%)
$results += Invoke-Check -Name ("disk free >= {0}%" -f $MinDiskFreePercent) -Action {
  $drive = (Get-Item -LiteralPath '.').PSDrive
  if (-not $drive -or -not $drive.Free -or -not $drive.Used) {
    return @{ Status='WARN'; Message='drive info unavailable' }
  }
  $total = [double]($drive.Free + $drive.Used)
  if ($total -le 0) { return @{ Status='WARN'; Message='invalid total size' } }
  $pct = [math]::Round( ($drive.Free / $total) * 100, 2 )
  if ($pct -lt $MinDiskFreePercent) {
    return @{ Status='WARN'; Message="free=${pct}% (< $MinDiskFreePercent%)" }
  }
  return @{ Status='OK'; Message="free=${pct}%" }
}

# ===== 출력 =====
# 표(가독성)
$results |
  Sort-Object { @{'FAIL'=0; 'WARN'=1; 'OK'=2}[$_.Status] }, Name |
  Format-Table -AutoSize | Out-String | Write-Host

# 집계
$ok    = ($results | Where-Object Status -eq 'OK').Count
$warn  = ($results | Where-Object Status -eq 'WARN').Count
$fail  = ($results | Where-Object Status -eq 'FAIL').Count
$total = $results.Count

# KLC 1행 로그
$sha     = $env:GITHUB_SHA
$runId   = $env:GITHUB_RUN_ID
$attempt = $env:GITHUB_RUN_ATTEMPT
$ts      = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ss.fffK')
$klc = "KLC|housekeeping-smoke|ts=$ts|ok=$ok|warn=$warn|fail=$fail|total=$total|sha=$sha|run=$runId|attempt=$attempt"
Write-Host $klc

# (옵션) 요약 MD
if ($SummaryPath) {
  try {
    "# Housekeeping Smoke" | Out-File $SummaryPath -Encoding UTF8
    "" | Out-File $SummaryPath -Append
    "| Check | Status | Message | Duration(ms) |"  | Out-File $SummaryPath -Append
    "|---|---|---|---:|"                            | Out-File $SummaryPath -Append
    foreach ($r in $results) {
      "| $($r.Name) | $($r.Status) | $($r.Message.Replace('|','\|')) | $([int]$r.DurationMs) |" |
        Out-File $SummaryPath -Append
    }
    "" | Out-File $SummaryPath -Append
    "**Summary**: ok=$ok, warn=$warn, fail=$fail, total=$total" | Out-File $SummaryPath -Append
    "" | Out-File $SummaryPath -Append
    "````" | Out-File $SummaryPath -Append
    $klc   | Out-File $SummaryPath -Append
    "````" | Out-File $SummaryPath -Append
  } catch {
    Write-Warning "Failed to write summary file: $SummaryPath ($($_.Exception.Message))"
  }
}

# 종료코드: 실패>0 또는 Strict 모드에서 경고>0
$exitCode = if ($fail -gt 0) { 1 } elseif ($Strict.IsPresent -and $warn -gt 0) { 1 } else { 0 }
exit $exitCode
