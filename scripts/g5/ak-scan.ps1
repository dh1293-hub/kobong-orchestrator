param([string]$Pr,[string]$Sha,[switch]$ConfirmApply)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$PSDefaultParameterValues['*:Encoding'] = 'utf8'
$script:sw = [System.Diagnostics.Stopwatch]::StartNew()

function Get-RepoRoot {
  if ($env:GITHUB_WORKSPACE -and (Test-Path $env:GITHUB_WORKSPACE)) {
    return $env:GITHUB_WORKSPACE
  }
  $d = Resolve-Path $PSScriptRoot
  while ($d -and -not (Test-Path (Join-Path $d '.git'))) {
    $p = Split-Path -Parent $d
    if ($p -eq $d) { break }
    $d = $p
  }
  if (Test-Path (Join-Path $d '.git')) { return $d }
  return (Resolve-Path $PSScriptRoot)
}

function K($lvl,$act,$out,$msg,$exit=0){
  if (-not $script:sw) { $script:sw = [System.Diagnostics.Stopwatch]::StartNew() }
  $ms = if ($script:sw) { $script:sw.ElapsedMilliseconds } else { 0 }

  $rec = [ordered]@{
    timestamp  = (Get-Date).ToString('o')
    level      = $lvl
    traceId    = [guid]::NewGuid().ToString()
    module     = 'scripts'
    action     = $act
    outcome    = $out
    message    = $msg
    durationMs = $ms
  } | ConvertTo-Json -Compress

  $root  = Get-RepoRoot
  $logDir = Join-Path $root 'logs'
  New-Item -ItemType Directory -Force -Path $logDir | Out-Null
  Add-Content -Path (Join-Path $logDir 'ak7.jsonl') -Value $rec
  if ($exit -ne 0) { exit $exit }
}

try {
  $mode = if ($ConfirmApply) { 'APPLY' } else { 'DRYRUN' }
  K 'INFO' 'scan:start' 'ok' "start pr=$Pr sha=$Sha mode=$mode"

  # === 여기에 '스캔' 로직(순수 파일 검사/정적 체크 등)을 넣으세요. Git 호출 금지 ===
  $root = Get-RepoRoot
  if (-not (Test-Path $root)) { K 'ERROR' 'scan:root' 'fail' "repo root not found: $root" 10 }

  Start-Sleep -Milliseconds 120  # 가벼운 스모크 타임
  K 'INFO' 'scan:end' 'SUCCESS' 'ok'
  exit 0
}
catch {
  K 'ERROR' 'scan:exception' 'FAILURE' ($_.Exception.Message) 13
}
