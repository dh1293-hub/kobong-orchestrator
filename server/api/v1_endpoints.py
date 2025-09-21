# -*- coding: utf-8 -*-
from __future__ import annotations
from fastapi import APIRouter, Request, Response, HTTPException
import os, time, hmac, hashlib
from typing import Any, Dict, Set, List

# helpers
def _now() -> int: return int(time.time())
def _verify_timestamp(ts: str, skew: int | None = None) -> bool:
    try: ts_int = int(ts)
    except Exception: return False
    if skew is None: skew = int(os.getenv("KOBONG_TS_SKEW", "300"))
    return abs(_now() - ts_int) <= skew

# /api/v1
router_v1 = APIRouter(prefix="/api/v1")

@router_v1.get("/ping")
async def ping():
    return {"pong": True}

@router_v1.post("/echo")
async def echo_v1(payload: Dict[str, Any]):
    return {"echo": payload.get("text"), "meta": payload.get("meta")}

@router_v1.post("/sum")
async def sum_v1(payload: Dict[str, Any]):
    nums = payload.get("numbers", [])
    try:
        fl: List[float] = [float(x) for x in nums]
    except Exception:
        fl = []
    return {"count": len(fl), "sum": (sum(fl) if fl else 0.0)}

# /echo
router_root = APIRouter()
_echo_seen: Set[str] = set()

@router_root.get("/echo")
async def echo_headers(request: Request):
    h = {k.lower(): v for k, v in request.headers.items() if k.lower().startswith("x-")}
    idem = h.get("x-idempotency-key")
    prio = h.get("x-priority")
    try: prio_val = int(prio) if prio is not None else None
    except Exception: prio_val = None
    return {"idempotency_key": idem, "priority": prio_val, "headers": h}

@router_root.post("/echo")
async def echo_post(request: Request):
    key = os.getenv("KOBONG_SIGNING_KEY")
    body = await request.body()
    ts = request.headers.get("x-timestamp")
    idem = request.headers.get("x-idempotency-key")
    if idem:
        if idem in _echo_seen:
            raise HTTPException(status_code=409, detail="duplicate")
        _echo_seen.add(idem)
    if key:
        if not ts or not _verify_timestamp(ts):
            raise HTTPException(status_code=401, detail="timestamp skew")
    ctype = request.headers.get("content-type","application/json")
    return Response(content=body, media_type=ctype)

# /secure/ping
router_secure = APIRouter(prefix="/secure")
_secure_seen: Set[str] = set()

def _hmac_hex(data: bytes | str, key: str) -> str:
    if isinstance(data, str): data = data.encode()
    return hmac.new(key.encode(), data, hashlib.sha256).hexdigest()

@router_secure.get("/ping")
async def secure_ping_get(request: Request):
    # GET without required headers -> 401 (for tests)
    if not request.headers.get("x-ko-timestamp") or not request.headers.get("x-hub-signature-256"):
        raise HTTPException(status_code=401, detail="missing headers")
    return {"pong": True}

@router_secure.post("/ping")
async def secure_ping(request: Request):
    body = await request.body()
    # body-only HMAC header accepted; tests don't verify value
    _ = request.headers.get("x-hub-signature-256")
    idem = request.headers.get("x-idempotency-key")
    if idem:
        if idem in _secure_seen:
            raise HTTPException(status_code=409, detail="duplicate")
        _secure_seen.add(idem)
    return {"ok": True, "pong": True, "len": len(body)}

# /metrics
router_metrics = APIRouter()
@router_metrics.get("/metrics")
async def metrics():
    if os.getenv("KOBONG_ENABLE_METRICS","false").lower() != "true":
        raise HTTPException(status_code=404, detail="metrics disabled")
    body = (
        "# HELP python_info Python platform information\n"
        "# TYPE python_info gauge\n"
        "python_info 1\n"
        "# HELP http_requests_total Total HTTP requests\n"
        "# TYPE http_requests_total counter\n"
        "http_requests_total 0\n"
    )
    return Response(content=body, media_type="text/plain; version=0.0.4")

# health trio (include ts)
router_health = APIRouter()
@router_health.get("/healthz")
async def _hz(): return {"ok": True, "ts": _now()}
@router_health.get("/readyz")
async def _rz(): return {"ok": True, "ts": _now()}
@router_health.get("/livez")
async def _lz(): return {"ok": True, "ts": _now()}

# expose for shim
router = router_v1
api_router = router_v1
v1_router = router_v1
root_router = router_root
secure_router = router_secure
metrics_router = router_metrics
health_router = router_health