param(
  [ValidateSet('nightly','manual')] [string]$Mode = 'nightly',
  [string]$Root = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'

# Root 결정 (워크플로 env → 현재 위치)
if ([string]::IsNullOrWhiteSpace($Root)) {
  $Root = $env:SRC_DIR
  if ([string]::IsNullOrWhiteSpace($Root)) { $Root = (Get-Location).Path }
}
$Root = (Resolve-Path $Root).Path

# 출력 경로: <repo>/automation_logs/klc
$logRoot = Join-Path -Path $Root -ChildPath 'automation_logs'
$klcOut  = Join-Path -Path $logRoot -ChildPath 'klc'
New-Item -ItemType Directory -Force -Path $klcOut | Out-Null

# === 실제 집계 로직 자리(필요 시 확장) ===
# 여기서는 “정상 실행”을 최소 1행 로그로 남긴다.
$ts      = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
$traceId = [guid]::NewGuid().ToString('N')
$line    = "$ts | traceId=$traceId | mode=$Mode | exitCode=0 | note=nightly-aggregate"
$line | Out-File -FilePath (Join-Path $klcOut 'klc-nightly.log') -Append

# GitHub Summary에도 한 줄
if ($env:GITHUB_STEP_SUMMARY) {
  "### KLC Nightly Aggregate`n- Mode: $Mode`n- Root: $Root`n- Log: automation_logs/klc/klc-nightly.log" |
    Out-File -FilePath $env:GITHUB_STEP_SUMMARY -Append
}
