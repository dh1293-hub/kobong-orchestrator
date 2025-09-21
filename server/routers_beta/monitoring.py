from fastapi import APIRouter
import os, time, socket

router = APIRouter()

def _stamp():
    return {"ts": time.time(), "host": socket.gethostname(), "env": os.environ.get("KO_ENV","dev")}

@router.get("/health")
def health():
    return {"ok": True, **_stamp()}

@router.get("/kpis")
def kpis():
    return {"gpt5": {"error_total": 0}, "ko": {"queue_depth": 0}, "ci_pass_rate": 0}
from datetime import datetime, timezone
@router.get("/time")
def time_now():
    now = datetime.now(timezone.utc).astimezone()
    return {
        "server_iso": now.isoformat(),
        "server_epoch_ms": int(now.timestamp()*1000),
        "server_tz": str(now.tzinfo)
    }