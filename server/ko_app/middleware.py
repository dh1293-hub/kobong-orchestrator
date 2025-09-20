from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import Response, JSONResponse
import uuid, time, os, threading

class RequestIDMiddleware(BaseHTTPMiddleware):
    def __init__(self, app, header_name: str = "X-Request-ID"):
        super().__init__(app)
        self.header_name = header_name
    async def dispatch(self, request: Request, call_next):
        rid = request.headers.get(self.header_name) or str(uuid.uuid4())
        response: Response = await call_next(request)
        response.headers[self.header_name] = rid
        return response

class APIKeyMiddleware(BaseHTTPMiddleware):
    """
    Require API key for paths under /api/ when KOBONG_REQUIRE_API_KEY=true.
    Accepts:
      - Header: X-API-Key: <key>
      - Header: Authorization: Bearer <key>
      - Query : ?api_key=<key>
    """
    async def dispatch(self, request: Request, call_next):
        try:
            require = os.getenv("KOBONG_REQUIRE_API_KEY","false").lower() in ("1","true","yes","on")
            if not require:
                return await call_next(request)
            path = request.url.path or ""
            if not path.startswith("/api/"):
                return await call_next(request)
            server_key = (os.getenv("KOBONG_API_KEY") or "").strip()
            if not server_key:
                return JSONResponse({"detail":"server missing API key"}, status_code=500)
            provided = request.headers.get("X-API-Key")
            if not provided:
                auth = request.headers.get("Authorization")
                if auth and auth.lower().startswith("bearer "):
                    provided = auth[7:].strip()
            if not provided:
                provided = request.query_params.get("api_key")
            if provided != server_key:
                return JSONResponse({"detail":"invalid or missing api key"}, status_code=401)
            return await call_next(request)
        except Exception as e:
            return JSONResponse({"detail":f"auth error: {e.__class__.__name__}"}, status_code=500)

class RateLimitMiddleware(BaseHTTPMiddleware):
    """
    Simple in-memory token bucket per client IP (best-effort).
    Enable via KOBONG_RATE_LIMIT='<burst>/<seconds>' e.g. '120/60'.
    """
    _lock = threading.Lock()
    _buckets = {}  # key -> (tokens, last_ts)

    def _parse(self):
        cfg = os.getenv("KOBONG_RATE_LIMIT","").strip()
        if not cfg or "/" not in cfg:
            return None
        try:
            burst, secs = cfg.split("/",1)
            return (max(1,int(burst)), max(1,int(secs)))
        except Exception:
            return None

    def _key(self, request: Request):
        ip = request.client.host if request.client else "unknown"
        # path grouping (avoid too granular)
        path = request.url.path or "/"
        group = path.split("/", 3)  # "", "api", "v1", "..."
        if len(group) >= 3:
            pathg = "/".join(group[:3])
        else:
            pathg = path
        return f"{ip}:{pathg}"

    async def dispatch(self, request: Request, call_next):
        cfg = self._parse()
        if not cfg:
            return await call_next(request)
        burst, window = cfg
        now = time.monotonic()
        key = self._key(request)
        with self._lock:
            tokens, last = self._buckets.get(key, (burst, now))
            # refill
            if now > last:
                delta = now - last
                refill = (delta / window) * burst
                tokens = min(burst, tokens + refill)
            allow = tokens >= 1.0
            if allow:
                tokens -= 1.0
            self._buckets[key] = (tokens, now)
        if not allow:
            return JSONResponse({"detail":"rate limit exceeded"}, status_code=429, headers={
                "Retry-After": str(window),
                "X-RateLimit-Limit": str(burst),
                "X-RateLimit-Window": str(window)
            })
        resp: Response = await call_next(request)
        # attach informational headers
        try:
            remaining = int(max(0, tokens))
            resp.headers["X-RateLimit-Remaining"] = str(remaining)
            resp.headers["X-RateLimit-Limit"] = str(burst)
            resp.headers["X-RateLimit-Window"] = str(window)
        except Exception:
            pass
        return resp