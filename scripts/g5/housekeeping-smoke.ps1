# 파일: scripts/g5/housekeeping-smoke.ps1
# 목적: 하우스키핑 스모크(안전한 읽기 전용 점검). CI에서 빠르게 환경/레포 기본 상태를 확인하고
#       결과(OK/WARN/FAIL)를 집계하여 종료코드로 반환(0=성공, 1=실패 존재).
# 동작:
#   - PowerShell 7 버전, git/gh 존재, Git 레포 여부(.git), 필수 디렉터리(./.github/workflows, ./scripts/g5),
#     작업 드라이브 여유 공간(%) 등을 점검.
#   - 결과 표 출력 + KLC 스타일 1줄 로그(집계) 출력.
#   - 기본적으로 파일은 생성하지 않음(읽기 전용). 필요 시 -SummaryPath로 마크다운 요약을 파일로 저장.
# 연관 파일:
#   - .github/workflows/housekeeping-smoke.yml (이 스크립트를 호출하는 워크플로)
# 산출물:
#   - 콘솔 로그(표/요약), 종료코드(집계 결과 기반)
#   - (옵션) -SummaryPath 지정 시 요약 MD 파일 생성
# 사용법:
#   pwsh -NoProfile -File .\scripts\g5\housekeeping-smoke.ps1
#   pwsh -NoProfile -File .\scripts\g5\housekeeping-smoke.ps1 -Strict
#   pwsh -NoProfile -File .\scripts\g5\housekeeping-smoke.ps1 -SummaryPath housekeeping-summary.md
# 옵션:
#   -Strict                : WARN도 실패로 간주하여 엄격 모드 종료코드 산정
#   -MinDiskFreePercent N  : 여유 공간 경고 임계치(%) (기본 1)
#   -SummaryPath <path>    : 요약을 마크다운 파일로 저장(워크플로에서 사용 가능)
# 테스트:
#   - 로컬/Runner에서 직접 실행 후 종료코드 확인($LASTEXITCODE)
#   - 의도적으로 폴더명을 틀리게 하거나, -MinDiskFreePercent 큰 값으로 WARN/FAIL 재현

[CmdletBinding()]
param(
  [switch]$Strict,
  [int]$MinDiskFreePercent = 1,
  [string]$SummaryPath
)

$ErrorActionPreference = 'Stop'
$ProgressPreference    = 'SilentlyContinue'

# 내부 유틸: 체크 실행(시간 측정/예외 처리)
function Invoke-Check {
  param(
    [Parameter(Mandatory)][string]$Name,
    [Parameter(Mandatory)][scriptblock]$Action,
    [string]$OnFail    = '',
    [string]$OnWarn    = ''
  )
  $sw = [System.Diagnostics.Stopwatch]::StartNew()
  $status  = 'OK'
  $message = ''
  try {
    $r = & $Action
    if ($null -ne $r -and $r -is [hashtable]) {
      if ($r.ContainsKey('Status')) { $status = [string]$r.Status }
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

$results = New-Object System.Collections.Generic.List[object]

# 1) PowerShell 7 버전 확인(최소 7.2 권장)
$results.Add( Invoke-Check -Name 'PowerShell version (>=7.2)' -Action {
  $v = $PSVersionTable.PSVersion
  if ($v.Major -lt 7 -or ($v.Major -eq 7 -and $v.Minor -lt 2)) {
    return @{ Status='FAIL'; Message="pwsh=$v (need >= 7.2)" }
  }
  return @{ Status='OK'; Message="pwsh=$v" }
})

# 2) git 존재 확인
$results.Add( Invoke-Check -Name 'git available' -Action {
  $out = & git --version 2>$null
  if ($LASTEXITCODE -ne 0 -or -not $out) { return @{ Status='FAIL'; Message='git not found' } }
  return @{ Status='OK'; Message=$out.Trim() }
})

# 3) gh(GitHub CLI) 존재 확인(없으면 WARN)
$results.Add( Invoke-Check -Name 'gh available' -Action {
  $out = & gh --version 2>$null
  if ($LASTEXITCODE -ne 0 -or -not $out) { return @{ Status='WARN'; Message='gh not found (optional)' } }
  return @{ Status='OK'; Message=($out -split "`n")[0].Trim() }
})

# 4) Git 레포 루트(.git) 존재(없으면 WARN: checkout 전략에 따라 없을 수도 있음)
$results.Add( Invoke-Check -Name '.git present' -Action {
  if (Test-Path -LiteralPath '.git') { return @{ Status='OK'; Message='found' } }
  return @{ Status='WARN'; Message='not found (detached or archive checkout?)' }
})

# 5) 필수 디렉터리 존재: .github/workflows
$results.Add( Invoke-Check -Name 'dir: .github/workflows' -Action {
  if (Test-Path -LiteralPath '.github/workflows') { return @{ Status='OK'; Message='exists' } }
  return @{ Status='FAIL'; Message='missing' }
})

# 6) 필수 디렉터리 존재: scripts/g5
$results.Add( Invoke-Check -Name 'dir: scripts/g5' -Action {
  if (Test-Path -LiteralPath 'scripts/g5') { return @{ Status='OK'; Message='exists' } }
  return @{ Status='FAIL'; Message='missing' }
})

# 7) 작업 드라이브 여유 공간(%)
$results.Add( Invoke-Check -Name "disk free >= $MinDiskFreePercent%" -Action {
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
})

# ==== 출력(표/요약) ====
# 테이블 출력
$results | Sort-Object { @{'FAIL'=0; 'WARN'=1; 'OK'=2}[$_.Status] }, Name | Format-Table -AutoSize | Out-String | Write-Host

# 요약 집계
$ok   = ($results | Where-Object Status -eq 'OK').Count
$warn = ($results | Where-Object Status -eq 'WARN').Count
$fail = ($results | Where-Object Status -eq 'FAIL').Count
$total= $results.Count

# KLC 스타일 1행 로그(파이프 구분, CI 상관키 포함)
$sha     = $env:GITHUB_SHA
$runId   = $env:GITHUB_RUN_ID
$attempt = $env:GITHUB_RUN_ATTEMPT
$ts      = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ss.fffK')
$klc = "KLC|housekeeping-smoke|ts=$ts|ok=$ok|warn=$warn|fail=$fail|total=$total|sha=$sha|run=$runId|attempt=$attempt"
Write-Host $klc

# (옵션) 마크다운 요약 파일 저장
if ($SummaryPath) {
  try {
    "# Housekeeping Smoke"       | Out-File $SummaryPath -Encoding UTF8
    ""                           | Out-File $SummaryPath -Append
    "| Check | Status | Message | Duration(ms) |"  | Out-File $SummaryPath -Append
    "|---|---|---|---:|"                            | Out-File $SummaryPath -Append
    foreach ($r in $results) {
      "| $($r.Name) | $($r.Status) | $($r.Message.Replace('|','\|')) | $([int]$r.DurationMs) |" |
        Out-File $SummaryPath -Append
    }
    ""                           | Out-File $SummaryPath -Append
    "**Summary**: ok=$ok, warn=$warn, fail=$fail, total=$total" | Out-File $SummaryPath -Append
    ""                           | Out-File $SummaryPath -Append
    "````"                       | Out-File $SummaryPath -Append
    $klc                          | Out-File $SummaryPath -Append
    "````"                       | Out-File $SummaryPath -Append
  } catch {
    Write-Warning "Failed to write summary file: $SummaryPath ($($_.Exception.Message))"
  }
}

# 종료코드: 실패>0 또는 (Strict 모드에서 경고>0)
$exitCode = if ($fail -gt 0) { 1 } elseif ($Strict.IsPresent -and $warn -gt 0) { 1 } else { 0 }
exit $exitCode
