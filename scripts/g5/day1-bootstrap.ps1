#requires -Version 7.0
Import-Module (Join-Path \ '..\lib\keep-open.psm1') -Force
param([switch]$ConfirmApply,[string]$Root)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }
$RepoRoot = if ($Root) { Resolve-Path -LiteralPath $Root } else { (git rev-parse --show-toplevel 2>$null) ?? (Get-Location).Path }
$RepoRoot = $RepoRoot.ToString(); Set-Location -LiteralPath $RepoRoot
$LockFile = Join-Path -Path $RepoRoot -ChildPath '.gpt5.lock'
if (Test-Path -LiteralPath $LockFile) { Write-Error 'CONFLICT: .gpt5.lock exists.'; exit 11 }
"locked $(Get-Date -Format o)" | Out-File -FilePath $LockFile -NoNewline
function Log($Level='INFO',$Action='day1',$Outcome='DRYRUN',$Code='',$Msg=''){
  $log=Join-Path -Path $RepoRoot -ChildPath 'logs/apply-log.jsonl'
  New-Item -ItemType Directory -Force -Path (Split-Path -Path $log) | Out-Null
  $rec=@{timestamp=(Get-Date).ToString('o');level=$Level;traceId=[guid]::NewGuid().ToString();module='scripts';action=$Action;outcome=$Outcome;errorCode=$Code;message=$Msg} | ConvertTo-Json -Compress
  Add-Content -Path $log -Value $rec
}
function Set-AtomicFile([string]$RelPath,[string]$Content){
  $full=Join-Path -Path $RepoRoot -ChildPath $RelPath; $dir=Split-Path -Path $full
  New-Item -ItemType Directory -Force -Path $dir | Out-Null
  $ts=(Get-Date -Format 'yyyyMMdd-HHmmss')
  $tmp="$full.tmp-$([guid]::NewGuid().ToString('n'))"
  $utf8=[Text.UTF8Encoding]::new($false)
  [IO.File]::WriteAllText($tmp,$Content,$utf8)
  if (Test-Path -LiteralPath $full){ Copy-Item -LiteralPath $full -Destination "$full.bak-$ts" -Force }
  Move-Item -LiteralPath $tmp -Destination $full -Force
}
$files=@(
@{path='.gitattributes';content="* text=auto eol=lf`n*.ps1 text eol=lf`n*.cmd text eol=crlf`n"},
@{path='.editorconfig';content=@"
root = true

[*]
end_of_line = lf
charset = utf-8
insert_final_newline = true
trim_trailing_whitespace = true

[*.ps1]
indent_style = space
indent_size = 2
"@},
@{path='scripts/g5/headers/ps7-header.ps1.txt';content=@"
#requires -Version 7.0
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
"@},
@{path='scripts/lib/kobong-logging.psm1';content=@"
#requires -Version 7.0
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
function Write-KobongJsonLog {
  param([ValidateSet('INFO','ERROR')] $Level='INFO',[string]$Module='kobong',[string]$Action='script',
        [ValidateSet('SUCCESS','FAILURE','DRYRUN')] $Outcome='SUCCESS',[string]$ErrorCode='',[string]$Message='')
  try {
    if (Get-Command kobong_logger_cli -ErrorAction SilentlyContinue) {
      & kobong_logger_cli log --level $Level --module $Module --action $Action --outcome $Outcome --error $ErrorCode --message $Message 2>$null
      return
    }
  } catch {}
  $root=(git rev-parse --show-toplevel 2>$null) ?? (Get-Location).Path
  $log=Join-Path $root 'logs/apply-log.jsonl'
  New-Item -ItemType Directory -Force -Path (Split-Path $log) | Out-Null
  $rec=@{timestamp=(Get-Date).ToString('o');level=$Level;traceId=[guid]::NewGuid().ToString();
    module=$Module;action=$Action;outcome=$Outcome;errorCode=$ErrorCode;message=$Message} | ConvertTo-Json -Compress
  Add-Content -Path $log -Value $rec
}
function Exit-Kobong{ param([ValidateSet('PRECONDITION','CONFLICT','TRANSIENT','LOGIC','Unknown')] $Category='Unknown',[string]$Message='')
  $code = switch ($Category){'PRECONDITION'{10} 'CONFLICT'{11} 'TRANSIENT'{12} 'LOGIC'{13} default{1}}
  Write-KobongJsonLog -Level ERROR -Action 'exit' -Outcome FAILURE -ErrorCode $Category -Message $Message
  exit $code
}
"@},
@{path='.github/PULL_REQUEST_TEMPLATE.md';content=@"
## 목적
- 무엇을 왜 변경했나요?

## 변경점
- 요약 목록

## 테스트
- 검증 방법/로그/결과

## 리스크 & 롤백
- 영향/완화책
- 롤백 방법

## 체크리스트
- [ ] PS7 헤더/UTF-8 LF/표준 종료 코드
- [ ] KLC 로그 또는 JSONL 폴백 1건 이상
- [ ] 릴리즈 노트 반영(필요 시)
"@},
@{path='.github/ISSUE_TEMPLATE/bug_report.yml';content=@"
# NO-SHELL
name: Bug report
description: 문제를 신고합니다
labels: [bug]
body:
  - type: textarea
    id: what
    attributes: { label: 무엇이 문제인가요?, placeholder: 재현/기대/실제/로그 }
    validations: { required: true }
"@},
@{path='.github/ISSUE_TEMPLATE/feature_request.yml';content=@"
# NO-SHELL
name: Feature request
description: 새 기능을 제안합니다
labels: [enhancement]
body:
  - type: textarea
    id: why
    attributes: { label: 왜 필요한가요?, placeholder: 배경/목표/KPI }
    validations: { required: true }
"@},
@{path='docs/ADR/0001-architecture-overview.md';content=@"
# ADR-0001: Architecture Overview
- Status: Proposed
- Scope: Phase-0 (KO FastAPI/WS + Shell Runner + GitHub App + ko-v1 최소)
- Decision: 최소 기능 우선(E2E Dry-Run PR), 관측/보안 스텁로 시작
"@},
@{path='docs/GH_APP_SETUP.md';content=@"
# GitHub App 최소 권한(초안)
- Permissions: Contents(R), Pull requests(R/W), Checks(R/W)
- Webhooks: pull_request, check_run, push
- Secret: APP_ID, INSTALLATION_ID, PRIVATE_KEY (Vault/KMS에서 주입)
"@},
@{path='README.md';content=@"
# kobong-orchestrator
- 목표: GPT-5 주도, KO 보조 — v0.1 범위(1주) 자동화
- Day-1: 표준 파일, KLC 로깅 모듈, 템플릿, ADR 초안
"@}
)
if (-not $ConfirmApply) {
  "== Dry-Run Plan =="; $files | ForEach-Object { "{0} → {1} bytes" -f $_.path,([Text.Encoding]::UTF8.GetByteCount($_.content)) }
  Log -Outcome 'DRYRUN' -Msg 'day1 preview'
  Remove-Item -Force $LockFile -ErrorAction SilentlyContinue
  exit 0
}
try{
  foreach($f in $files){ Set-AtomicFile -RelPath $f.path -Content $f.content }
  New-Item -ItemType Directory -Force -Path (Join-Path -Path $RepoRoot -ChildPath 'logs') | Out-Null
  Log -Outcome 'SUCCESS' -Msg 'day1 applied'
  "APPLIED: Day-1 bootstrap complete."
} catch {
  Log -Level 'ERROR' -Outcome 'FAILURE' -Code 'LOGIC' -Msg $_.Exception.Message
  exit 13
} finally {
  Remove-Item -Force $LockFile -ErrorAction SilentlyContinue
}

try {
  Import-Module (Join-Path $PSScriptRoot '..\lib\keep-open.psm1') -Force
  Invoke-KeepOpenIfNeeded -Reason '<patched>'
} catch {}
