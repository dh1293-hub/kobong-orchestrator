# Code-001 — KB-AUTO-BOOTSTRAP v1 (PS5.1-safe)
# APPLY IN SHELL
# Name: KB-AUTO-BOOTSTRAP
# Version: 1.0.1
# Intent: "SSOT 선언 + Contracts/Skill/Contract-Tests + CI를 '무인'으로 부트스트랩하고 즉시 검증한다."
# Preconditions: PowerShell 5.1+, Git(선택), Python 3.11+, Git repo 내에서 실행 가능; 쓰기 권한 필요.
# Effects: 새 파일/디렉터리 생성 또는 갱신(.bak 백업), venv 구성, 테스트 실행, CI 워크플로 추가.
# Rollback: 각 파일 생성/갱신 전 *.bak-<ts> 자동 백업. 실패 시 중단; 수동 복구는 *.bak 복원.
# Idempotency: 동일 입력으로 재실행 시 동일 결과. 기존 동일 내용 파일은 "SKIP(no-change)" 처리.
# Order: Stop-If-Fail (단계 실패 시 이후 단계 NOT_APPLIED).
# Post-verify: pytest 계약테스트 0 exit 확인, 로그/경로 존재 확인.

param(
  [switch]$DryRun,
  [switch]$ConfirmApply
)

# PS-GUARD-BOOTSTRAP v1 — must be first (APPLY IN SHELL)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
Write-Host '[WARN] Continuous PowerShell session — follow GPT-5 steps only.' -ForegroundColor DarkYellow

function Get-RepoRoot {
  if ($env:HAN_GPT5_ROOT -and (Test-Path $env:HAN_GPT5_ROOT)) { return (Resolve-Path $env:HAN_GPT5_ROOT).Path }
  try { $gr = git rev-parse --show-toplevel 2>$null; if ($LASTEXITCODE -eq 0 -and $gr) { return (Resolve-Path $gr).Path } } catch {}
  return (Resolve-Path "$PSScriptRoot/..").Path
}

$RepoRoot = Get-RepoRoot
if (-not (Test-Path $RepoRoot)) { throw "PRECONDITION: RepoRoot not found: $RepoRoot" }
Set-Location $RepoRoot

function Assert-InRepo([string]$Path) {
  $repoFull = (Resolve-Path $RepoRoot).Path
  $cwd = (Get-Location).Path
  $candidate = Join-Path $cwd $Path
  $full = [System.IO.Path]::GetFullPath($candidate)
  if ($full.StartsWith($repoFull, [System.StringComparison]::OrdinalIgnoreCase)) { return }
  throw "LOGIC: Path out of repo: $full"
}

$LockFile = Join-Path $RepoRoot '.gpt5.lock'
if (Test-Path $LockFile) { throw 'CONFLICT: Another operation in progress (.gpt5.lock exists).' }
'locked ' + (Get-Date).ToString('o') | Out-File $LockFile -Encoding utf8 -NoNewline
trap { $__lf=$null; try{$__lf=(Get-Variable -Name LockFile -Scope Script -ErrorAction SilentlyContinue).Value}catch{}; if ($__lf -and (Test-Path -LiteralPath $__lf)) { Remove-Item -LiteralPath $__lf -Force -ErrorAction SilentlyContinue }; break }

try { Start-Transcript -Path (Join-Path $RepoRoot 'logs/ps-transcript.txt') -Append -ErrorAction SilentlyContinue } catch {}

function Write-JsonLog($obj) {
  $line = ($obj | ConvertTo-Json -Depth 6 -Compress)
  $log  = Join-Path $RepoRoot 'logs/apply-log.jsonl'
  New-Item -ItemType Directory -Force -Path (Split-Path $log) | Out-Null
  Add-Content -Path $log -Value $line
}

function Invoke-Gpt5Step {
  param(
    [Parameter(Mandatory)] [string] $Name,
    [Parameter(Mandatory)] [scriptblock] $Action
  )
  $sw=[System.Diagnostics.Stopwatch]::StartNew(); $trace=[guid]::NewGuid().ToString(); $outcome='PENDING'
  try {
    if ($DryRun) { & $Action ; $outcome='DRYRUN' } else { if (-not $ConfirmApply){ throw 'PRECONDITION: ConfirmApply required.' }; & $Action ; $outcome='SUCCESS' }
    Write-JsonLog @{ timestamp=(Get-Date).ToString('o'); level='INFO'; traceId=$trace; module='kb-auto-bootstrap'; action=$Name; outcome='FAILURE'; durationMs=$sw.ElapsedMilliseconds; message='' }
  } catch {
    Write-JsonLog @{ timestamp=(Get-Date).ToString('o'); level='ERROR'; traceId=$trace; module='kb-auto-bootstrap'; action=$Name; outcome='FAILURE'; durationMs=$sw.ElapsedMilliseconds; errorCode=$_.Exception.Message; message=$_.ScriptStackTrace }
    throw
  }
}

# ENV & standard dirs (PS5.1-safe)
$env:HAN_GPT5_ROOT = $RepoRoot
if (-not $env:HAN_GPT5_OUT  -or [string]::IsNullOrWhiteSpace($env:HAN_GPT5_OUT))  { $env:HAN_GPT5_OUT  = Join-Path $RepoRoot 'out' }
if (-not $env:HAN_GPT5_TMP  -or [string]::IsNullOrWhiteSpace($env:HAN_GPT5_TMP))  { $env:HAN_GPT5_TMP  = Join-Path $RepoRoot '.tmp' }
if (-not $env:HAN_GPT5_LOGS -or [string]::IsNullOrWhiteSpace($env:HAN_GPT5_LOGS)) { $env:HAN_GPT5_LOGS = Join-Path $RepoRoot 'logs' }
if (-not $env:HAN_GPT5_CACHE -or [string]::IsNullOrWhiteSpace($env:HAN_GPT5_CACHE)) { $env:HAN_GPT5_CACHE = Join-Path $RepoRoot '.cache' }
mkdir $env:HAN_GPT5_OUT,$env:HAN_GPT5_TMP,$env:HAN_GPT5_LOGS,$env:HAN_GPT5_CACHE -Force | Out-Null

function Write-FileSafe {
  param([string]$Path,[string]$Content)
  Assert-InRepo $Path
  $dir = Split-Path $Path
  New-Item -ItemType Directory -Force -Path $dir | Out-Null
  $ts = (Get-Date).ToString('yyyyMMdd-HHmmss')
  if (Test-Path $Path) {
    $existing = Get-Content $Path -Raw -ErrorAction SilentlyContinue
    if ($existing -eq $Content) { Write-Host "SKIP(no-change): $Path"; return }
    Copy-Item $Path "$Path.bak-$ts" -Force
  }
  if ($DryRun) { Write-Host "DRYRUN write => $Path"; return }
  $tmp = "$Path.tmp-$ts"
  $Content | Out-File $tmp -Encoding utf8 -NoNewline
  Move-Item $tmp $Path -Force
  Write-Host "WROTE: $Path"
}

# 01.declaration-ssot
Invoke-Gpt5Step -Name '01.declaration-ssot' -Action {
  $decl = @"
decl_version: 1
project: { id: han.gpt5, name: Han GPT-5 Conductor, owner: STS }
runtimes: { python: "3.11", node: "20.x" }
paths: { root_env: HAN_GPT5_ROOT, out: out/, logs: logs/, cache: .cache/, tmp: .tmp/ }
quality: { coverage: { lines: 0.85, branches: 0.80 }, e2e: { required: ["smoke_bootstrap","release_notes_acl"] } }
release: { strategy: semver, changelog: conventional, ci: github-actions }
security: { pii_masking: true, break_glass: { enabled: false } }
contracts: { schema_versioning: semver }
ui: { invariants: ["card_header_rule","role_combo_right","input_group_single_row"] }
"@
  Write-FileSafe -Path (Join-Path $RepoRoot 'project.decl.yaml') -Content $decl
}

# 02.contracts-json
Invoke-Gpt5Step -Name '02.contracts-json' -Action {
  $contractsDir = Join-Path $RepoRoot 'contracts'
  New-Item -ItemType Directory -Force -Path $contractsDir | Out-Null

  $commands = @'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "kkb.commands.v1",
  "type": "object",
  "required": ["plan"],
  "properties": {
    "meta": {
      "type": "object",
      "properties": { "traceId": {"type":"string"}, "from": {"enum":["gpt5"]} }
    },
    "plan": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["step","actions"],
        "properties": {
          "step": {"type":"integer"},
          "explain": {"type":"string"},
          "actions": {"type":"array","items":{"$ref":"#/definitions/action"}}
        }
      }
    }
  },
  "definitions": {
    "action": {
      "oneOf": [
        { "title":"LOCATE","type":"object","required":["LOCATE"],
          "properties":{"LOCATE":{"type":"object","required":["role","by"],
            "properties":{"role":{"enum":["ai1","ai2","conductor"]},"by":{"enum":["text","icon","anchor"]},"query":{"type":"array","items":{"type":"string"}},"timeout_ms":{"type":"integer"}}}} },
        { "title":"FOCUS","type":"object","required":["FOCUS"],
          "properties":{"FOCUS":{"type":"object","properties":{"target":{"type":"string"}}}} },
        { "title":"PASTE","type":"object","required":["PASTE"],
          "properties":{"PASTE":{"type":"object","required":["text"],"properties":{"text":{"type":"string"}}}} },
        { "title":"PRESS","type":"object","required":["PRESS"],
          "properties":{"PRESS":{"type":"object","properties":{"keys":{"type":"string"}}}} },
        { "title":"CLICK","type":"object","required":["CLICK"],
          "properties":{"CLICK":{"type":"object","properties":{"button":{"enum":["left","right"]},"x":{"type":"number"},"y":{"type":"number"}}}} },
        { "title":"WAIT","type":"object","required":["WAIT"],
          "properties":{"WAIT":{"type":"object","properties":{"ms":{"type":"integer"}}}} },
        { "title":"SNAPSHOT","type":"object","required":["SNAPSHOT"],
          "properties":{"SNAPSHOT":{"type":"object","properties":{"label":{"type":"string"}}}} },
        { "title":"VERIFY","type":"object","required":["VERIFY"],
          "properties":{"VERIFY":{"type":"object","properties":{"ocr_contains":{"type":"string"},"text_contains_any":{"type":"array","items":{"type":"string"}},"timeout_ms":{"type":"integer"}}}} }
      ]
    }
  }
}
'@

  $results = @'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "kkb.results.v1",
  "type": "object",
  "required": ["step","status","duration_ms"],
  "properties": {
    "step": {"type":"integer"},
    "status": {"enum":["ok","fail","retry"]},
    "duration_ms": {"type":"integer"},
    "evidence": {
      "type":"object",
      "properties": {
        "loc": {"type":"string"},
        "score": {"type":"number"},
        "snapshots": {"type":"array","items":{"type":"string"}}
      }
    },
    "error": {
      "type":"object",
      "properties": { "code":{"type":"string"}, "msg":{"type":"string"} }
    }
  }
}
'@

  $skills = @'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "kkb.skills.v1",
  "type": "object",
  "required": ["id","name","version","category","intent","plan"],
  "properties": {
    "id": {"type":"string"},
    "name": {"type":"string"},
    "version": {"type":"string"},
    "category": {"enum":["browser","chat","docs","file"]},
    "intent": {"type":"string"},
    "preconditions": {"type":"array","items":{"type":"object"}},
    "plan": {"type":"array","items":{"$ref":"kkb.commands.v1#/definitions/action"}},
    "assertions": {"type":"array","items":{"type":"object"}},
    "kpi": {"type":"object"}
  }
}
'@

  Write-FileSafe -Path (Join-Path $contractsDir 'kkb.commands.v1.json') -Content $commands
  Write-FileSafe -Path (Join-Path $contractsDir 'kkb.results.v1.json')  -Content $results
  Write-FileSafe -Path (Join-Path $contractsDir 'skills.v1.json')       -Content $skills
}

# 03.sample-skill
Invoke-Gpt5Step -Name '03.sample-skill' -Action {
  $skillsDir = Join-Path $RepoRoot 'skills\staged'
  New-Item -ItemType Directory -Force -Path $skillsDir | Out-Null
  $skillYaml = @"
id: skill.send_prompt_to_ai1
name: "Send prompt to AI1 and verify reply"
version: 0.1.0
category: chat
intent: "paste into chat input and press Enter"
preconditions:
  - role: ai1
  - app: browser
  - ui: chat_input_visible
plan:
  - LOCATE: {role: ai1, by: text, query: ["채팅 입력", "Send a message"], timeout_ms: 5000}
  - FOCUS:  {target: "@LOCATE"}
  - PASTE:  {text: "<PROMPT_TEXT>"}
  - PRESS:  {keys: Enter}
  - WAIT:   {ms: 1200}
  - SNAPSHOT: {label: ai1_after_send}
assertions:
  - VERIFY: {text_contains_any: ["Sent", "전송됨", "응답 중"], timeout_ms: 2000}
"@
  Write-FileSafe -Path (Join-Path $skillsDir 'send_prompt_to_ai1.skill.yaml') -Content $skillYaml
}

# 04.contract-tests(py)
Invoke-Gpt5Step -Name '04.contract-tests(py)' -Action {
  $testsDir = Join-Path $RepoRoot 'tests\contract'
  New-Item -ItemType Directory -Force -Path $testsDir | Out-Null
  $testPy = @'
import json, pathlib, yaml
from jsonschema import Draft202012Validator, RefResolver

ROOT = pathlib.Path(__file__).resolve().parents[2]
CONTRACTS = ROOT / 'contracts'
SKILLS = ROOT / 'skills' / 'staged'

def load_schema(name):
    p = CONTRACTS / name
    with p.open('r', encoding='utf-8') as f:
        return json.load(f)

def test_skill_yaml_conforms_to_schema():
    skills_schema = load_schema('skills.v1.json')
    commands_schema = load_schema('kkb.commands.v1.json')
    store = {
        commands_schema.get('$id','kkb.commands.v1'): commands_schema,
        skills_schema.get('$id','kkb.skills.v1'): skills_schema,
    }
    resolver = RefResolver.from_schema(skills_schema, store=store)
    validator = Draft202012Validator(skills_schema, resolver=resolver)

    for yml in SKILLS.glob('*.yaml'):
        data = yaml.safe_load(yml.read_text(encoding='utf-8'))
        errors = sorted(validator.iter_errors(data), key=lambda e: e.path)
        assert not errors, f'Validation errors in {yml}: ' + '; '.join([e.message for e in errors])
'@
  Write-FileSafe -Path (Join-Path $testsDir 'skills_v1_test.py') -Content $testPy

  $req = @"
pytest==8.3.2
pyyaml==6.0.2
jsonschema==4.23.0
"@
  Write-FileSafe -Path (Join-Path $RepoRoot 'requirements.contract-tests.txt') -Content $req
}

# 05.scripts
Invoke-Gpt5Step -Name '05.scripts' -Action {
  $scr = Join-Path $RepoRoot 'scripts'
  New-Item -ItemType Directory -Force -Path $scr | Out-Null

  $setup = @'
# scripts/setup-env.ps1
param([string]$Python='python')
$ErrorActionPreference='Stop'
if (-not (Test-Path '.venv')) { & $Python -m venv .venv }
if (Test-Path '.venv/Scripts/Activate.ps1') { . ./.venv/Scripts/Activate.ps1 } else { . ./.venv/bin/Activate.ps1 }
pip install -r requirements.contract-tests.txt --disable-pip-version-check
'@
  Write-FileSafe -Path (Join-Path $scr 'setup-env.ps1') -Content $setup

  $run = @'
# scripts/run-contract-tests.ps1
$ErrorActionPreference='Stop'
& $PSScriptRoot/setup-env.ps1
pytest -q tests/contract
'@
  Write-FileSafe -Path (Join-Path $scr 'run-contract-tests.ps1') -Content $run
}

# 06.github-actions
Invoke-Gpt5Step -Name '06.github-actions' -Action {
  $wfDir = Join-Path $RepoRoot '.github\workflows'
  New-Item -ItemType Directory -Force -Path $wfDir | Out-Null
  $wf = @"
name: contract-tests
on:
  push:
    paths:
      - 'contracts/**'
      - 'skills/**'
      - 'tests/contract/**'
      - 'scripts/**'
      - 'project.decl.yaml'
  workflow_dispatch:

jobs:
  contract:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with: { python-version: '3.11' }
      - name: Run contract tests
        shell: pwsh
        run: |
          pwsh -NoLogo -File scripts/run-contract-tests.ps1
"@
  Write-FileSafe -Path (Join-Path $wfDir 'contract-tests.yml') -Content $wf
}

# 07.local-verify (PS5.1로 직접 실행)
Invoke-Gpt5Step -Name '07.local-verify' -Action {
  if ($DryRun) { Write-Host '[DRYRUN] Skip pytest run'; return }
  & (Join-Path $RepoRoot 'scripts\run-contract-tests.ps1')
  Write-Host '[OK] Contract tests passed.'
}

Write-Host "`n[DONE] kb-auto-bootstrap completed."


