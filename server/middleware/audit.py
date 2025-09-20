from __future__ import annotations
import json, os, time, uuid
from typing import Any, Iterable
from starlette.requests import Request
from starlette.responses import Response
from starlette.middleware.base import BaseHTTPMiddleware
from ..utils.masking import mask, summarize_body
from ..metrics import hooks

_AUDIT_DIR = os.getenv("KOBONG_AUDIT_DIR", "logs")
_AUDIT_FILE = os.path.join(_AUDIT_DIR, "audit.jsonl")

def _parse_list(envval: str, fallback: Iterable[str]) -> list[str]:
    if not envval: return list(fallback)
    return [x.strip() for x in envval.split(",") if x.strip()]

_HEADER_ALLOW = [h.lower() for h in _parse_list(
    os.getenv("KOBONG_AUDIT_HEADER_WHITELIST","content-type,user-agent,x-request-id,x-forwarded-for,authorization,referer"),
    []
)]
_PREVIEW_BYTES = int(os.getenv("KOBONG_AUDIT_BODY_PREVIEW","512"))

class AuditMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        started = time.time()
        trace_id = request.headers.get("X-Request-Id") or str(uuid.uuid4())
        client_ip = request.headers.get("X-Forwarded-For") or (request.client.host if request.client else None)

        # Body snapshot
        try:
            body_bytes = await request.body()
            async def receive():
                return {"type": "http.request", "body": body_bytes, "more_body": False}
            request._receive = receive  # type: ignore
        except Exception:
            body_bytes = b""

        body_json: Any = None
        if body_bytes:
            try:
                body_json = json.loads(body_bytes.decode("utf-8","ignore"))
            except Exception:
                body_json = None

        headers_filtered = {k:v for k,v in request.headers.items() if k.lower() in _HEADER_ALLOW}

        req_summary = {
            "method": request.method,
            "path": request.url.path,
            "client": client_ip,
            "query": mask(dict(request.query_params)),
            "headers": mask(headers_filtered),
            "body": summarize_body(body_json if body_json is not None else body_bytes[:_PREVIEW_BYTES], max_preview=_PREVIEW_BYTES)
        }

        try:
            response: Response = await call_next(request)
            status = response.status_code
            latency_ms = int((time.time()-started)*1000)
        except Exception as e:
            status = 500
            latency_ms = int((time.time()-started)*1000)
            _write_audit({"ts": time.time(), "traceId": trace_id, "req": req_summary, "res": {"status": status}, "latencyMs": latency_ms, "error": str(e)})
            hooks.emit("http.requests.total", 1, {"path": request.url.path, "status": str(status)})
            hooks.timing("http.requests.latency", latency_ms, {"path": request.url.path,"status": str(status)})
            raise

        _write_audit({"ts": time.time(), "traceId": trace_id, "req": req_summary, "res": {"status": status}, "latencyMs": latency_ms})
        hooks.emit("http.requests.total", 1, {"path": request.url.path, "status": str(status)})
        hooks.timing("http.requests.latency", latency_ms, {"path": request.url.path,"status": str(status)})

        if "x-request-id" not in (k.lower() for k in response.headers.keys()):
            response.headers["X-Request-Id"] = trace_id
        return response

def _write_audit(obj: dict) -> None:
    os.makedirs(_AUDIT_DIR, exist_ok=True)
    with open(_AUDIT_FILE, "a", encoding="utf-8") as f:
        f.write(json.dumps(obj, ensure_ascii=False)+"\n")