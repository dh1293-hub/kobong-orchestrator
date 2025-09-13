# kobong-logger-auto.ps1 (fixed: parent-dir guard for root files)
# 목적: Kobong Logging Contract Bundle 드랍-인 설치 + 컨트랙트 테스트 자동 실행
# 사용: powershell -ExecutionPolicy Bypass -File .\kobong-logger-auto.ps1  (또는 pwsh -File ...)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$WITH_ACTIONS   = $true     # GitHub Actions 생성 여부
$DO_RENORMALIZE = $true     # .gitattributes 적용 후 EOL 리노멀라이즈

$RepoRoot = (Get-Location).Path
[Environment]::CurrentDirectory = $RepoRoot
Write-Host "[INFO] Target: $RepoRoot" -ForegroundColor Cyan

# 필수 디렉터리
New-Item -ItemType Directory -Force -Path 'infra\logging'            | Out-Null
New-Item -ItemType Directory -Force -Path 'domain\contracts\logging' | Out-Null
New-Item -ItemType Directory -Force -Path 'scripts'                   | Out-Null
New-Item -ItemType Directory -Force -Path 'tests\contract'            | Out-Null
if ($WITH_ACTIONS) { New-Item -ItemType Directory -Force -Path '.github\workflows' | Out-Null }

# ── 안전 파일 쓰기 유틸 (루트 파일 경로 가드 포함) ─────────────────────────────
function Write-Text {
  param(
    [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$Path,
    [Parameter()][AllowEmptyString()][string]$Content,
    [string]$Enc='utf8'
  )
  $dir = Split-Path -Parent -Path $Path
  if ([string]::IsNullOrWhiteSpace($dir)) { $dir = '.' }            # ★ 루트 파일(.gitattributes 등) 가드
  if (-not (Test-Path -LiteralPath $dir)) {
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
  }
  if (Test-Path -LiteralPath $Path) {
    $old = Get-Content -LiteralPath $Path -Raw -ErrorAction SilentlyContinue
    if ($old -eq $Content) { Write-Host "[OK] $Path (no change)" -ForegroundColor DarkYellow; return }
    Copy-Item -LiteralPath $Path -Destination ($Path + '.bak-auto') -Force
    Write-Host "[UPDATE] $Path (backup: $Path.bak-auto)" -ForegroundColor Green
  } else {
    Write-Host "[WROTE] $Path" -ForegroundColor Green
  }
  Set-Content -LiteralPath $Path -Value $Content -Encoding $Enc
}

# .gitattributes
$gitattributes = @'
*           text=auto eol=lf
*.bat       text eol=crlf
*.cmd       text eol=crlf
*.ps1       text eol=lf
*.psm1      text eol=lf
*.psd1      text eol=lf
*.sh        text eol=lf
*.py        text eol=lf
*.ts        text eol=lf
*.tsx       text eol=lf
*.js        text eol=lf
*.jsx       text eol=lf
*.json      text eol=lf
*.yml       text eol=lf
*.yaml      text eol=lf
*.md        text eol=lf
*.toml      text eol=lf
*.ini       text eol=lf
'@
Write-Text '.gitattributes' $gitattributes 'ascii'

# Python 의존성
$req = @'
pytest>=7
pyyaml>=6
jsonschema>=4
'@
Write-Text 'requirements.contract-tests.txt' $req

# infra/logging/json_logger.py (+ 패키지 __init__)
Write-Text 'infra\__init__.py'            "from .logging import *`n"
Write-Text 'infra\logging\__init__.py'    "from .json_logger import JsonLogger`n"
$logger = @'
from __future__ import annotations
from dataclasses import dataclass
from typing import Optional, Dict, Any
from datetime import datetime, timezone
import json, uuid, os, socket, threading, re

def _now():
    return datetime.now(timezone.utc).astimezone()

def _tz_id() -> str:
    return os.getenv("APP_TZ") or os.getenv("TZ") or "Asia/Seoul"

def _app_obj(name_fallback: str, module: Optional[str]) -> Dict[str, Optional[str]]:
    name = module if module is not None else (name_fallback or "kobong-orchestrator")
    ver = os.getenv("APP_VER") or os.getenv("APP_VERSION") or "0.0.0"
    commit = os.getenv("APP_COMMIT") or os.getenv("GIT_COMMIT") or None
    return {"name": name, "ver": ver, "commit": commit}

_STATUS_TO_CODE = {"ok":0,"retry":1,"timeout":2,"assert_fail":3,"cancel":4,"fatal":9}
_CODE_TO_STATUS = {v:k for k,v in _STATUS_TO_CODE.items()}

def _result_obj(result_status: Optional[str], result_code: Optional[int], fallback_ok: bool = True) -> Dict[str, Any]:
    status = (result_status or "").strip().lower() if result_status else None
    code = int(result_code) if result_code is not None else None
    if status and code is None: code = _STATUS_TO_CODE.get(status, 9)
    if code is not None and not status: status = _CODE_TO_STATUS.get(int(code), "fatal")
    if status is None and code is None:
        status = "ok" if fallback_ok else "fatal"
        code = _STATUS_TO_CODE[status]
    return {"status": status, "code": int(code)}

_EMAIL_RE = re.compile(r"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}", re.IGNORECASE)
_SECRET_KV_RE = re.compile(r"(?i)\b(api[_-]?key|apikey|token|secret|password)\b\s*([:=])\s*([^\s,;]+)")
_LONG_TOKEN_RE = re.compile(r"\b[A-Za-z0-9][A-Za-z0-9\-_]{16,}\b")

def _scrub(text: Optional[str]) -> Optional[str]:
    if not text: return text
    t = _EMAIL_RE.sub("[MASKED_EMAIL]", text)
    t = _SECRET_KV_RE.sub(lambda m: f"{m.group(1)}{m.group(2)}[MASKED_TOKEN]", t)
    t = _LONG_TOKEN_RE.sub("[MASKED_TOKEN]", t)
    return t

def _action_obj(step: Optional[int], dsl_id: Optional[str]) -> Dict[str, Optional[str]]:
    try: s = int(step) if step is not None else 0
    except Exception: s = 0
    return {"step": s, "dsl_id": dsl_id}

@dataclass
class JsonLogger:
    app: str = "kobong-orchestrator"
    env: Optional[str] = None

    def make_record(
        self, level: str = "INFO", action: str = "contract-test", message: str = "",
        *, module: Optional[str] = None, action_step: Optional[int] = None, dsl_id: Optional[str] = None,
        result_status: Optional[str] = None, result_code: Optional[int] = None,
        duration_ms: Optional[int] = None, latency_ms: Optional[int] = None,
        env: Optional[str] = None, trace_id: Optional[str] = None,
        extra: Optional[Dict[str, Any]] = None, **kwargs,
    ) -> Dict[str, Any]:
        dt = _now()
        rec: Dict[str, Any] = {
            "timestamp": dt.isoformat(),
            "tz": _tz_id(),
            "level": str(level).upper(),
            "app": _app_obj(self.app, module),
            "env": env if env is not None else (self.env or os.getenv("APP_ENV") or os.getenv("ENV") or os.getenv("NODE_ENV") or "local"),
            "host": socket.gethostname(),
            "pid": os.getpid(),
            "thread": threading.current_thread().name,
            "trace_id": trace_id or str(uuid.uuid4()),
            "action": _action_obj(action_step if action_step is not None else kwargs.get("step"), kwargs.get("dsl_id") if dsl_id is None else dsl_id),
            "result": _result_obj(result_status, result_code),
            "latency_ms": int(latency_ms if latency_ms is not None else (duration_ms if duration_ms is not None else 0)),
            "message": _scrub(message),
        }
        if extra:
            for k, v in extra.items():
                if isinstance(v, str):
                    rec[k] = _scrub(v)
                elif k not in ("app","action","result"):
                    rec[k] = v
        for k, v in kwargs.items():
            if k not in rec and k not in ("app","action","result"):
                rec[k] = _scrub(v) if isinstance(v, str) else v
        return rec

    def log(self, message: str = "", level: str = "INFO", action: str = "contract-test", **kwargs):
        return self.make_record(level=level, action=action, message=message, **kwargs)

    def record(self, *args, **kwargs): return self.make_record(*args, **kwargs)
    def create(self, *args, **kwargs): return self.make_record(*args, **kwargs)
    def to_json(self, **kwargs) -> str:
        return json.dumps(self.make_record(**kwargs), ensure_ascii=False)
'@
Write-Text 'infra\logging\json_logger.py' $logger

# 스키마 + 테스트
$schema = @'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://example.com/logging/v1.schema.json",
  "type": "object",
  "required": ["timestamp","tz","level","app","env","host","pid","thread","trace_id","action","result","latency_ms","message"],
  "properties": {
    "timestamp": { "type": "string" },
    "tz": { "type": "string", "enum": ["Asia/Seoul"] },
    "level": { "type": "string" },
    "app": { "type": "object", "required": ["name","ver"],
      "properties": { "name": { "type": "string" }, "ver": { "type": "string" }, "commit": { "type": ["string","null"] } } },
    "env": { "type": "string" },
    "host": { "type": "string" },
    "pid": { "type": "integer" },
    "thread": { "type": "string" },
    "trace_id": { "type": "string" },
    "action": { "type": "object", "required": ["step"], "properties": { "step": { "type": "integer" }, "dsl_id": { "type": ["string","null"] } } },
    "result": { "type": "object", "required": ["status","code"],
      "properties": { "status": { "type": "string", "enum": ["ok","retry","timeout","assert_fail","cancel","fatal"] },
                      "code":   { "type": "integer", "enum": [0,1,2,3,4,9] } } },
    "latency_ms": { "type": "integer" },
    "message": { "type": "string" }
  },
  "additionalProperties": true
}
'@
Write-Text 'domain\contracts\logging\v1.schema.json' $schema

$test = @'
import json
from jsonschema import Draft202012Validator
from infra.logging.json_logger import JsonLogger

def test_log_record_matches_schema():
    jl = JsonLogger(env="dev")
    rec = jl.log(level="INFO", module="unit", action_step=1,
                 message="hello alice@example.com with api_key: XYZ1234567890",
                 result_status="ok", result_code=0)
    with open("domain/contracts/logging/v1.schema.json","r",encoding="utf-8") as f:
        schema = json.load(f)
    Draft202012Validator(schema).validate(rec)
    s = json.dumps(rec, ensure_ascii=False)
    assert "alice@example.com" not in s
    assert "XYZ1234567890" not in s
    assert "[MASKED_EMAIL]" in s
    assert "[MASKED_TOKEN]" in s

def test_required_fields_present():
    rec = JsonLogger().log(message="minimal")
    for k in ["timestamp","tz","level","app","env","host","pid","thread","trace_id","action","result","latency_ms","message"]:
        assert k in rec
'@
Write-Text 'tests\contract\test_logging_contract.py' $test

# 실행 스크립트(PS5.1/7 호환)
$setupEnv = @'
param([string]$Python = 'python')
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$RepoRoot = Split-Path -Parent $PSScriptRoot
[Environment]::CurrentDirectory = $RepoRoot
if (-not (Test-Path ".venv")) { & $Python -m venv .venv }
$py = if (Test-Path ".venv\Scripts\python.exe") { ".venv\Scripts\python.exe" } elseif (Test-Path ".venv/bin/python") { ".venv/bin/python" } else { $Python }
& $py -m pip install -q -r (Join-Path $RepoRoot "requirements.contract-tests.txt") --disable-pip-version-check
'@
Write-Text 'scripts\setup-env.ps1' $setupEnv

$runner = @'
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
Write-Host '[WARN] Continuous PowerShell session — follow GPT-5 steps only.' -ForegroundColor DarkYellow
$RepoRoot = Split-Path -Parent $PSScriptRoot
[Environment]::CurrentDirectory = $RepoRoot
$sep = [System.IO.Path]::PathSeparator
if ([string]::IsNullOrWhiteSpace($env:PYTHONPATH)) { $env:PYTHONPATH = $RepoRoot } else {
  $parts = $env:PYTHONPATH -split [regex]::Escape([string]$sep)
  if ($parts -notcontains $RepoRoot) { $env:PYTHONPATH = "$RepoRoot$sep$($env:PYTHONPATH)" }
}
if (Test-Path "$PSScriptRoot\setup-env.ps1") { & "$PSScriptRoot\setup-env.ps1" }
if (Test-Path ".venv\Scripts\python.exe") { $py = ".venv\Scripts\python.exe" } else { $py = "python" }
& $py -c "import sys; import infra, infra.logging.json_logger as jl; print('[PY] import infra OK')"
& $py -m pytest -q tests/contract
'@
Write-Text 'scripts\run-contract-tests.ps1' $runner

# GitHub Actions(옵션)
if ($WITH_ACTIONS) {
  $gha = @'
name: contract-tests
on:
  push: { branches: [ main ] }
  pull_request: { branches: [ main ] }
jobs:
  tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with: { python-version: "3.11" }
      - name: Install deps
        run: python -m pip install -q -r requirements.contract-tests.txt --disable-pip-version-check
      - name: Run contract tests
        env:
          APP_TZ: Asia/Seoul
        run: python -m pytest -q tests/contract
'@
  Write-Text '.github\workflows\contract-tests.yml' $gha
}

# EOL 리노멀라이즈(옵션)
if ($DO_RENORMALIZE) {
  try {
    git config core.autocrlf false | Out-Null
    git add --renormalize .        | Out-Null
    git commit -m "chore(repo): normalize EOL via .gitattributes" | Out-Null
    Write-Host "[GIT] EOL renormalize done" -ForegroundColor DarkGray
  } catch { Write-Host "[GIT] renormalize skipped: $($_.Exception.Message)" -ForegroundColor DarkGray }
}

# 컨트랙트 테스트 실행
$ps = (Get-Command pwsh -ErrorAction SilentlyContinue)
if ($ps) { & pwsh -File .\scripts\run-contract-tests.ps1 } else { & powershell.exe -ExecutionPolicy Bypass -File .\scripts\run-contract-tests.ps1 }
$code = $LASTEXITCODE
if ($code -eq 0) { Write-Host "pytest exit code = 0 (OK)" -ForegroundColor Green } else { Write-Host "pytest exit code = $code" -ForegroundColor Red; exit $code }
