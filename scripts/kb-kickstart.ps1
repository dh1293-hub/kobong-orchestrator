# Code-001 — KB Kickstart (Paths+Decl+Logs) v1
# APPLY IN SHELL
# Name: KB-Kickstart
# Version: 1.0.0
# Intent: 리포 루트 고정 → 표준 ENV/디렉터리(out/.tmp/logs/.cache) 생성 → project.decl.yaml 부트스트랩
# Preconditions: PowerShell 7(pwsh), 쓰기권한, 올바른 -Root
# Effects: 폴더 생성, 선언 파일 생성(없을 때만), jsonl 로그 남김
# Rollback: 생성된 project.decl.yaml 삭제(필요 시), 생성 폴더 제거 가능(수동). 잠금파일/트랜스크립트는 자동 정리
# Idempotency: 재실행 안전(이미 존재하면 Skip)
# Order: Gate-0 Preflight → Ensure-Dirs → Ensure-Decl → Summary
# Post-verify: [OK] 메시지, 생성 경로/파일 출력

#requires -PSEdition Core
#requires -Version 7.0
Set-StrictMode -Version Latest
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
$PSDefaultParameterValues['*:Encoding']        = 'utf8'
$ErrorActionPreference = 'Stop'

param(
  [string]$Root,
  [switch]$ConfirmApply
)

# ==== PS-GUARD-BOOTSTRAP v1 (필수) ====
if (-not $Root) { $Root = (Get-Location).Path }
if (-not (Test-Path $Root)) { throw "PRECONDITION: RepoRoot not found: $Root" }
$RepoRoot = (Resolve-Path $Root).Path
Set-Location $RepoRoot

function Assert-InRepo($Path) {
  $full = (Resolve-Path $Path -ErrorAction SilentlyContinue)?.Path
  if (-not $full) { throw "LOGIC: Path not resolvable: $Path" }
  if (-not $full.StartsWith((Resolve-Path $RepoRoot).Path, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "LOGIC: Path out of repo: $full"
  }
}

$LockFile = Join-Path $RepoRoot '.gpt5.lock'
if (Test-Path $LockFile) { throw 'CONFLICT: Another operation in progress (.gpt5.lock exists).' }
"locked $(Get-Date).ToString('o')" | Out-File $LockFile -Encoding utf8 -NoNewline

trap {
  try {
    if (Test-Path $LockFile) { Remove-Item -Force $LockFile -ErrorAction SilentlyContinue }
  } catch {}
  break
}

try { Start-Transcript -Path (Join-Path $RepoRoot 'logs/ps-transcript.txt') -Append -ErrorAction SilentlyContinue } catch {}

function Write-JsonLog($obj) {
  $line = ($obj | ConvertTo-Json -Depth 6 -Compress)
  $log  = Join-Path $RepoRoot 'logs/apply-log.jsonl'
  New-Item -ItemType Directory -Force -Path (Split-Path $log) | Out-Null
  Add-Content -Path $log -Value $line
}

function Invoke-Gpt5Step {
  param([Parameter(Mandatory)] [string] $Name,[Parameter(Mandatory)] [scriptblock] $Action,[switch] $DryRun,[switch] $ConfirmApply)
  $sw=[System.Diagnostics.Stopwatch]::StartNew(); $trace=[guid]::NewGuid().ToString()
  try {
    if ($DryRun) { & $Action ; $outcome='DRYRUN' } else { if (-not $ConfirmApply){ throw 'PRECONDITION: ConfirmApply required.' }; & $Action ; $outcome='SUCCESS' }
    Write-JsonLog @{ timestamp=(Get-Date).ToString('o'); level='INFO'; traceId=$trace; module='kb-kickstart'; action=$Name; outcome=$outcome; durationMs=$sw.ElapsedMilliseconds; message='' }
  } catch {
    Write-JsonLog @{ timestamp=(Get-Date).ToString('o'); level='ERROR'; traceId=$trace; module='kb-kickstart'; action=$Name; outcome='FAILURE'; durationMs=$sw.ElapsedMilliseconds; errorCode=$_.Exception.Message; message=$_.ScriptStackTrace }
    throw
  }
}

# ==== Gate-0: Preflight ====
Invoke-Gpt5Step -Name 'Gate-0.Preflight' -DryRun:(!$ConfirmApply) -ConfirmApply:$ConfirmApply -Action {
  $v = $PSVersionTable.PSVersion
  if ($v.Major -lt 7) { throw "PRECONDITION: PowerShell 7+ required (current=$v)" }
  # ENV 확정
  $env:HAN_GPT5_ROOT = $RepoRoot
  $env:HAN_GPT5_OUT  = $env:HAN_GPT5_OUT  ?? (Join-Path $RepoRoot 'out')
  $env:HAN_GPT5_TMP  = $env:HAN_GPT5_TMP  ?? (Join-Path $RepoRoot '.tmp')
  $env:HAN_GPT5_LOGS = $env:HAN_GPT5_LOGS ?? (Join-Path $RepoRoot 'logs')
  $env:HAN_GPT5_CACHE= $env:HAN_GPT5_CACHE?? (Join-Path $RepoRoot '.cache')
  '[OK] Preflight — ENV fixed' | Write-Host
}

# ==== Step-1: 표준 디렉터리 생성 ====
Invoke-Gpt5Step -Name 'Ensure-Dirs' -DryRun:(!$ConfirmApply) -ConfirmApply:$ConfirmApply -Action {
  $dirs = @($env:HAN_GPT5_OUT,$env:HAN_GPT5_TMP,$env:HAN_GPT5_LOGS,$env:HAN_GPT5_CACHE)
  foreach($d in $dirs){ Assert-InRepo $d; New-Item -ItemType Directory -Force -Path $d | Out-Null }
  '[OK] Directories — out/.tmp/logs/.cache ready' | Write-Host
}

# ==== Step-2: 선언 파일 생성(없을 때만) ====
Invoke-Gpt5Step -Name 'Ensure-Decl' -DryRun:(!$ConfirmApply) -ConfirmApply:$ConfirmApply -Action {
  $declPath = Join-Path $RepoRoot 'project.decl.yaml'
  Assert-InRepo $declPath
  if (Test-Path $declPath) {
    "[SKIP] project.decl.yaml exists → $declPath" | Write-Host
  } else {
@"
decl_version: 1
project:
  id: han.kobong
  name: Kobong Conductor
  owner: STS
runtimes:
  python: "3.11"
  node: "20.x"
paths:
  root_env: HAN_GPT5_ROOT
  out: out/
  logs: logs/
  cache: .cache/
  tmp: .tmp/
quality:
  coverage: { lines: 0.85, branches: 0.80 }
  e2e: { required: ["smoke_bootstrap", "release_notes_acl"] }
release:
  strategy: semver
  changelog: conventional
  ci: github-actions
security:
  pii_masking: true
  break_glass: { enabled: false }
contracts:
  schema_versioning: semver
ui:
  invariants: ["card_header_rule", "role_combo_right", "input_group_single_row"]
"@ | Out-File $declPath -Encoding utf8 -NoNewline
    "[OK] project.decl.yaml created → $declPath" | Write-Host
  }
}

# ==== Summary ====
$summary = @"
[SUMMARY]
Root : $RepoRoot
OUT  : $env:HAN_GPT5_OUT
TMP  : $env:HAN_GPT5_TMP
LOGS : $env:HAN_GPT5_LOGS
CACHE: $env:HAN_GPT5_CACHE
Decl : $(Join-Path $RepoRoot 'project.decl.yaml')
"@
$summary | Write-Host

# Cleanup
if (Test-Path $LockFile) { Remove-Item -Force $LockFile -ErrorAction SilentlyContinue }
