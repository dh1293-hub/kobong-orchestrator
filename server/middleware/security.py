import os, time, hmac, hashlib, typing
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import JSONResponse

def _get_secret() -> bytes:
    key = os.getenv("KOBONG_SIGNING_KEY", "devkey")
    return key.encode("utf-8")

def _now() -> float:
    return time.time()

class SigningMiddleware(BaseHTTPMiddleware):
    def __init__(self, app, skew_sec: int = 300):
        super().__init__(app)
        self.skew_sec = int(skew_sec)
        self.secret = _get_secret()

    async def dispatch(self, request: Request, call_next):
        m = request.method.upper()
        if m in ("GET","HEAD","OPTIONS"):
            return await call_next(request)

        sig = request.headers.get("x-signature")
        ts  = request.headers.get("x-timestamp")
        if not sig or not ts:
            return JSONResponse({"detail":"missing signature headers"}, status_code=401)

        try:
            ts_int = int(float(ts))
        except Exception:
            return JSONResponse({"detail":"invalid timestamp"}, status_code=401)

        if abs(_now() - ts_int) > self.skew_sec:
            return JSONResponse({"detail":"timestamp skew too large"}, status_code=401)

        body = await request.body()

        async def receive():
            return {"type":"http.request","body":body,"more_body":False}
        try:
            request._receive = receive  # type: ignore[attr-defined]
        except Exception:
            pass

        canonical = f"{m}\n{request.url.path}\n{ts_int}\n".encode("utf-8") + body
        want = hmac.new(self.secret, canonical, hashlib.sha256).hexdigest()
        if not hmac.compare_digest(want, sig):
            return JSONResponse({"detail":"bad signature"}, status_code=401)

        return await call_next(request)

class IdempotencyMiddleware(BaseHTTPMiddleware):
    _store: typing.Dict[str, float] = {}
    def __init__(self, app, ttl_sec: int = 600):
        super().__init__(app); self.ttl = int(ttl_sec)

    def _prune(self):
        now = _now()
        for k,t in list(self._store.items()):
            if now - t > self.ttl:
                try: del self._store[k]
                except KeyError: pass

    async def dispatch(self, request: Request, call_next):
        m = request.method.upper()
        if m not in ("POST","PUT","PATCH","DELETE"):
            return await call_next(request)

        key = request.headers.get("x-idempotency-key")
        if not key:
            return await call_next(request)

        self._prune()
        if key in self._store:
            return JSONResponse({"detail":"duplicate request","idempotency_key":key}, status_code=409)

        self._store[key] = _now()
        return await call_next(request)
