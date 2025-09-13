from __future__ import annotations
import json
import os
import re
import socket
import threading
import time
import uuid
from datetime import datetime
from datetime import timezone

from infra.logging.rotation import rotate_if_needed, cleanup_by_age
from infra.alerts.notify_stub import notify as alert_notify

LOG_PATH = os.path.join("logs", "app.log")
APP_NAME = "conductor"
APP_VER = "0.1.0"

EMAIL_RE = re.compile(r"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}")
TOKEN_RE = re.compile(r"(?:api[_-]?key|token|bearer)[:\s]*[A-Za-z0-9\-_\.]{8,}", re.I)

MAX_BYTES = int(os.getenv("LOG_MAX_BYTES", "5242880"))
BACKUPS   = int(os.getenv("LOG_BACKUPS", "5"))
RET_DAYS  = int(os.getenv("LOG_RETENTION_DAYS", "14"))

def _utc_iso() -> str:
    return datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")

def _mask_pii(text: str) -> str:
    if not text:
        return text
    text = EMAIL_RE.sub("[MASKED_EMAIL]", text)
    text = TOKEN_RE.sub("[MASKED_TOKEN]", text)
    return text

def _ensure_dir(path: str) -> None:
    d = os.path.dirname(path)
    if d and not os.path.exists(d):
        os.makedirs(d, exist_ok=True)

class JsonLogger:
    def __init__(self, env: str = "dev"):
        self.env = env
        self.host = socket.gethostname()

    def log(
        self,
        *,
        level: str = "INFO",
        module: str = "app",
        action_step: int = 0,
        message: str,
        result_status: str = "ok",
        result_code: int = 0,
        role_card: str | None = None,
        role_group: str | None = None,
        trace_id: str | None = None,
        span_id: str | None = None,
        err: dict | None = None,
        extra: dict | None = None,
        snapshot_paths: list[str] | None = None,
        template_match: dict | None = None,
    ) -> dict:
        t0 = time.monotonic()
        record = {
            "timestamp": _utc_iso(),
            "monotonic_ms": round(t0 * 1000, 3),
            "tz": "Asia/Seoul",
            "level": level,
            "app": {"name": APP_NAME, "ver": APP_VER, "commit": None},
            "env": self.env,
            "host": self.host,
            "pid": os.getpid(),
            "thread": threading.current_thread().name,
            "trace_id": trace_id or uuid.uuid4().hex,
            "span_id": span_id,
            "user": None,
            "role": {"card": role_card, "group": role_group},
            "action": {"step": action_step, "dsl_id": None},
            "result": {"status": result_status, "code": result_code},
            "latency_ms": 0,
            "message": _mask_pii(message),
            "snapshot_paths": snapshot_paths or [],
            "ocr_text_hash": None
        }
        if err:
            record["err"] = {
                "type": err.get("type"),
                "msg": _mask_pii(err.get("msg", "")),
                "stack": _mask_pii(err.get("stack", "")),
            }
        if template_match is not None:
            record["template_match"] = template_match
        if extra:
            for k, v in extra.items():
                if k not in record:
                    record[k] = v

        record["latency_ms"] = round((time.monotonic() - t0) * 1000, 3)

        _ensure_dir(LOG_PATH)
        rotate_if_needed(LOG_PATH, MAX_BYTES, BACKUPS)
        cleanup_by_age(LOG_PATH, RET_DAYS)

        with open(LOG_PATH, "a", encoding="utf-8") as f:
            f.write(json.dumps(record, ensure_ascii=False) + "\n")

        if level in ("ERROR", "FATAL"):
            try:
                alert_notify(level, record)
            except Exception:
                pass
        return record
