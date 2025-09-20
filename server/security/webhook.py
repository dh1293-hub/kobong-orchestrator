from __future__ import annotations
import hashlib, hmac, json, os, time, threading
from typing import Tuple, Optional

_SECRET = os.getenv("KOBONG_WEBHOOK_SECRET")
_REQUIRE = os.getenv("KOBONG_EVENTS_REQUIRE_SIGNATURE","0") in ("1","true","TRUE","yes","on")
_SKEW = int(os.getenv("KOBONG_WEBHOOK_TOLERANCE_SEC","300"))
_IDEMP_TTL = int(os.getenv("KOBONG_IDEMP_TTL_SEC","7200"))
_STORE = os.getenv("KOBONG_IDEMP_STORE", os.path.join("logs","idempotency.jsonl"))

_lock = threading.RLock()
_seen: dict[str,float] = {}

def _hexdigest(secret: str, timestamp: str, body: bytes) -> str:
    payload = f"t={timestamp}.{body.decode('utf-8','ignore')}".encode("utf-8")
    return hmac.new(secret.encode("utf-8"), payload, hashlib.sha256).hexdigest()

def _parse_sig(sig: str) -> list[str]:
    # ex) "t=1690000000,v1=abcd,v1=efgh"
    parts = [p.strip() for p in sig.split(",")]
    vals = []
    for p in parts:
        if p.startswith("v1="): vals.append(p[3:])
    if not vals and "=" not in sig:
        vals.append(sig.strip())
    return vals

def _record_idem(key: str, ts: float):
    os.makedirs(os.path.dirname(_STORE), exist_ok=True)
    with _lock:
        _seen[key] = ts
        with open(_STORE, "a", encoding="utf-8") as f:
            f.write(json.dumps({"ts": ts, "key": key})+"\n")
        # prune memory
        now = time.time()
        for k,t in list(_seen.items()):
            if now - t > _IDEMP_TTL:
                _seen.pop(k, None)

def _is_replay(key: Optional[str]) -> bool:
    if not key: return False
    now = time.time()
    with _lock:
        t = _seen.get(key)
        if t and now - t <= _IDEMP_TTL:
            return True
        # light scan store tail (best-effort)
        if os.path.exists(_STORE):
            try:
                with open(_STORE, "rb") as f:
                    f.seek(0, os.SEEK_END)
                    size = f.tell()
                    read = min(size, 128*1024)
                    f.seek(size-read)
                    tail = f.read().decode("utf-8","ignore").splitlines()[-1000:]
                for line in reversed(tail):
                    try:
                        rec = json.loads(line)
                        if rec.get("key")==key and now - float(rec.get("ts",0)) <= _IDEMP_TTL:
                            _seen[key] = float(rec["ts"])
                            return True
                    except Exception:
                        pass
            except Exception:
                pass
    return False

def verify(headers: dict, body: bytes) -> Tuple[bool, int, str]:
    if not _SECRET:
        return (not _REQUIRE, 200, "signature not required")
    ts = headers.get("X-Kobong-Timestamp") or headers.get("X-Signature-Timestamp") or ""
    sig = headers.get("X-Kobong-Signature") or headers.get("X-Signature") or ""
    idem = headers.get("X-Kobong-Idempotency-Key") or headers.get("Idempotency-Key")
    if not ts or not sig:
        return (False, 401, "missing signature headers")
    try:
        ts_i = int(ts)
    except Exception:
        return (False, 400, "invalid timestamp")
    if abs(time.time() - ts_i) > _SKEW:
        return (False, 401, "timestamp skew")
    expected = _hexdigest(_SECRET, ts, body)
    cand = _parse_sig(sig)
    if not any(hmac.compare_digest(expected, c) for c in cand):
        return (False, 401, "bad signature")
    if _is_replay(idem):
        return (False, 409, "replay detected")
    if idem:
        _record_idem(idem, float(ts_i))
    return (True, 200, "ok")