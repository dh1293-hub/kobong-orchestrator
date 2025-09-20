from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import Response
from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST
from fastapi import Response as FastResponse
import os, time, threading

_REQ_COUNT = Counter("http_requests_total", "HTTP requests", ["method","path","status"])
_REQ_LAT   = Histogram("http_request_duration_seconds", "Request latency", ["method","path","status"],
                       buckets=[0.005,0.01,0.025,0.05,0.1,0.25,0.5,1,2,5])

def _path_group(path: str) -> str:
    if not path: return "/"
    parts = path.split("/", 3)
    if len(parts) >= 3:
        return "/".join(parts[:3]) or "/"
    return path

class PrometheusMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        start = time.perf_counter()
        method = (request.method or "GET").upper()
        pathg  = _path_group(request.url.path or "/")
        try:
            resp: Response = await call_next(request)
            status = getattr(resp, "status_code", 200)
        except Exception:
            status = 500
            raise
        finally:
            dur = time.perf_counter() - start
            _REQ_COUNT.labels(method=method, path=pathg, status=str(status)).inc()
            _REQ_LAT.labels(method=method, path=pathg, status=str(status)).observe(dur)
        return resp

def setup_metrics(app):
    """
    Enable metrics if KOBONG_ENABLE_METRICS true-ish.
    Adds PrometheusMiddleware and GET /metrics (text/plain; version 0.0.4)
    """
    if getattr(app.state, "metrics_ready", False):
        return app
    if (os.getenv("KOBONG_ENABLE_METRICS","true").lower() not in ("1","true","yes","on")):
        app.state.metrics_ready = True
        return app
    # middleware
    app.add_middleware(PrometheusMiddleware)
    # endpoint (idempotent)
    exists = any(getattr(r, "path", None) == "/metrics" for r in getattr(app, "routes", []))
    if not exists:
        @app.get("/metrics")
        def metrics():
            data = generate_latest()
            return FastResponse(content=data, media_type=CONTENT_TYPE_LATEST)
    app.state.metrics_ready = True
    return app