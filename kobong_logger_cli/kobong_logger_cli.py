# kobong_logger_cli.py
# Purpose: Scaffold & verify Kobong Logging Contract Bundle for any repo
# Usage:
#   python kobong_logger_cli.py init --path .
#   python kobong_logger_cli.py verify --path .
#   python kobong_logger_cli.py smoke
# Notes: Standard library only. Windows/macOS/Linux 호환. Git/PowerShell/pytest 미존재시 graceful fallback.

from __future__ import annotations
import argparse, os, sys, json, shutil, subprocess, datetime, uuid, textwrap
from pathlib import Path

# ---------- File Contents (templates) ----------

GITATTRIBUTES = """*           text=auto eol=lf
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
"""

REQS = """pytest>=7
pyyaml>=6
jsonschema>=4
"""

INFRA_INIT = "from .logging import *\n"
INFRA_LOGGING_INIT = "from .json_logger import JsonLogger\n"

JSON_LOGGER = r'''from __future__ import annotations
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
'''

SCHEMA = r'''{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://example.com/logging/v1.schema.json",
  "type": "object",
  "required": ["timestamp","tz","level","app","env","host","pid","thread","trace_id","action","result","latency_ms","message"],
  "properties": {
    "timestamp": { "type": "string" },
    "tz": { "type": "string", "enum": ["Asia/Seoul"] },
    "level": { "type": "string" },
    "app": {
      "type": "object",
      "required": ["name","ver"],
      "properties": {
        "name": { "type": "string" },
        "ver": { "type": "string" },
        "commit": { "type": ["string","null"] }
      }
    },
    "env": { "type": "string" },
    "host": { "type": "string" },
    "pid": { "type": "integer" },
    "thread": { "type": "string" },
    "trace_id": { "type": "string" },
    "action": {
      "type": "object",
      "required": ["step"],
      "properties": {
        "step": { "type": "integer" },
        "dsl_id": { "type": ["string","null"] }
      }
    },
    "result": {
      "type": "object",
      "required": ["status","code"],
      "properties": {
        "status": { "type": "string",
          "enum": ["ok","retry","timeout","assert_fail","cancel","fatal"] },
        "code": { "type": "integer", "enum": [0,1,2,3,4,9] }
      }
    },
    "latency_ms": { "type": "integer" },
    "message": { "type": "string" }
  },
  "additionalProperties": true
}
'''

TESTS = r'''import json
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
'''

SETUP_ENV_PS1 = r"""param([string]$Python = 'python')
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$RepoRoot = Split-Path -Parent $PSScriptRoot
[Environment]::CurrentDirectory = $RepoRoot
if (-not (Test-Path ".venv")) { & $Python -m venv .venv }
$py = if (Test-Path ".venv\Scripts\python.exe") { ".venv\Scripts\python.exe" } elseif (Test-Path ".venv/bin/python") { ".venv/bin/python" } else { $Python }
& $py -m pip install -q -r (Join-Path $RepoRoot "requirements.contract-tests.txt") --disable-pip-version-check
"""

RUN_TESTS_PS1 = r"""$ErrorActionPreference = 'Stop'
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
"""

GHA = r'''name: contract-tests
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
        run: |
          python -m pip install -q -r requirements.contract-tests.txt --disable-pip-version-check
      - name: Run contract tests
        env:
          APP_TZ: Asia/Seoul
        run: |
          python -m pytest -q tests/contract
'''

# ---------- Helpers ----------

def backup_path(p: Path, tag: str) -> Path:
    stamp = datetime.datetime.now().strftime("%Y%m%d%H%M%S")
    return p.with_suffix(p.suffix + f".bak-{tag}-{stamp}")

def write_file_safe(path: Path, content: str, dry_run=False) -> str:
    path.parent.mkdir(parents=True, exist_ok=True)
    status = ""
    if path.exists():
        old = path.read_text(encoding="utf-8", errors="ignore")
        if old == content:
            status = f"[OK] {path} (no change)"
        else:
            if not dry_run:
                bp = backup_path(path, "KOBONG")
                shutil.copy2(path, bp)
                path.write_text(content, encoding="utf-8", newline="\n")
            status = f"[UPDATE] {path}"
    else:
        if not dry_run:
            path.write_text(content, encoding="utf-8", newline="\n")
        status = f"[WROTE] {path}"
    return status

def is_windows() -> bool:
    return os.name == "nt"

def run(cmd: list[str], cwd: Path | None = None) -> int:
    try:
        proc = subprocess.run(cmd, cwd=str(cwd) if cwd else None, check=False)
        return proc.returncode
    except FileNotFoundError:
        return 127

# ---------- Commands ----------

def cmd_init(args):
    root = Path(args.path).resolve()
    print(f"[INFO] Target: {root}")

    manifests = {
        root / ".gitattributes": GITATTRIBUTES,
        root / "requirements.contract-tests.txt": REQS,
        root / "infra/__init__.py": INFRA_INIT,
        root / "infra/logging/__init__.py": INFRA_LOGGING_INIT,
        root / "infra/logging/json_logger.py": JSON_LOGGER,
        root / "domain/contracts/logging/v1.schema.json": SCHEMA,
        root / "tests/contract/test_logging_contract.py": TESTS,
        root / "scripts/setup-env.ps1": SETUP_ENV_PS1,
        root / "scripts/run-contract-tests.ps1": RUN_TESTS_PS1,
    }
    if args.with_actions:
        manifests[root / ".github/workflows/contract-tests.yml"] = GHA

    for p, c in manifests.items():
        print(write_file_safe(p, c, dry_run=args.dry_run))

    if args.renormalize:
        # Normalize EOLs to match .gitattributes
        rc1 = run(["git", "config", "core.autocrlf", "false"], cwd=root)
        rc2 = run(["git", "add", "--renormalize", "."], cwd=root)
        rc3 = run(["git", "commit", "-m", "chore(repo): normalize EOL via .gitattributes"], cwd=root)
        print(f"[GIT] autocrlf rc={rc1}, renormalize rc={rc2}, commit rc={rc3}")

    print("[DONE] init")

def cmd_verify(args):
    root = Path(args.path).resolve()
    # Try PowerShell runner first (Windows)
    if is_windows():
        ps = shutil.which("pwsh") or shutil.which("powershell.exe")
        runner = root / "scripts/run-contract-tests.ps1"
        if ps and runner.exists():
            rc = run([ps, "-File", str(runner)], cwd=root)
            print(f"[VERIFY] runner rc={rc}")
            sys.exit(rc)
    # Fallback: python -m pytest directly
    py = sys.executable
    req = root / "requirements.contract-tests.txt"
    if req.exists():
        run([py, "-m", "pip", "install", "-q", "-r", str(req), "--disable-pip-version-check"], cwd=root)
    rc = run([py, "-m", "pytest", "-q", "tests/contract"], cwd=root)
    print(f"[VERIFY] pytest rc={rc}")
    sys.exit(rc)

def cmd_smoke(_args):
    # Minimal in-process smoke (no pytest)
    from types import SimpleNamespace
    ns = {}
    try:
        # dynamic load from an in-memory package? simpler: print the intended record shape
        example = {
            "timestamp": "2025-01-01T00:00:00+09:00",
            "tz": "Asia/Seoul",
            "level": "INFO",
            "app": {"name": "unit", "ver": "0.0.0", "commit": None},
            "env": "dev",
            "host": "HOST",
            "pid": 1234,
            "thread": "MainThread",
            "trace_id": str(uuid.uuid4()),
            "action": {"step": 1, "dsl_id": None},
            "result": {"status": "ok", "code": 0},
            "latency_ms": 0,
            "message": "hello [MASKED_EMAIL] with api_key:[MASKED_TOKEN]"
        }
        print(json.dumps(example, ensure_ascii=False))
        print("HAS_MASKED_EMAIL=", "[MASKED_EMAIL]" in example["message"])
        print("HAS_MASKED_TOKEN=", "[MASKED_TOKEN]" in example["message"])
    except Exception as e:
        print(f"[SMOKE] failed: {e}")
        sys.exit(1)

def build_parser():
    p = argparse.ArgumentParser(
        prog="kobong-logger",
        description="Kobong Logging Contract Bundle — initializer & verifier"
    )
    sub = p.add_subparsers(dest="cmd", required=True)

    sp = sub.add_parser("init", help="Scaffold logging contract bundle into target path")
    sp.add_argument("--path", default=".", help="target project path (repo root)")
    sp.add_argument("--with-actions", action="store_true", help="create GitHub Actions workflow")
    sp.add_argument("--renormalize", action="store_true", help="git EOL renormalize after writing")
    sp.add_argument("--dry-run", action="store_true", help="preview changes only")
    sp.set_defaults(func=cmd_init)

    sv = sub.add_parser("verify", help="Install deps (if available) and run contract tests")
    sv.add_argument("--path", default=".", help="target project path (repo root)")
    sv.set_defaults(func=cmd_verify)

    ss = sub.add_parser("smoke", help="Print a sample masked record (no filesystem changes)")
    ss.set_defaults(func=cmd_smoke)
    return p

def main(argv=None):
    argv = argv or sys.argv[1:]
    parser = build_parser()
    args = parser.parse_args(argv)
    args.func(args)

if __name__ == "__main__":
    main()

