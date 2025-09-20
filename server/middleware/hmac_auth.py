import os, time, hmac, hashlib
from starlette.middleware.base import BaseHTTPMiddleware, RequestResponseEndpoint
from starlette.requests import Request
from starlette.responses import JSONResponse

def _try_make_redis(url: str | None):
    if not url: return None
    try:
        import redis  # type: ignore
        c = redis.Redis.from_url(url, decode_responses=True)
        try: c.ping()
        except Exception: return None
        return c
    except Exception:
        return None

class HMACAuthMiddleware(BaseHTTPMiddleware):
    def __init__(self, app, *, secret_env: str = "KOBONG_WEBHOOK_SECRET", skew_seconds: int = 300, redis_url_env: str = "KOBONG_REDIS_URL"):
        super().__init__(app)
        self.secret_env = secret_env
        self.skew = skew_seconds
        self._idem: dict[str,int] = {}
        self._redis = _try_make_redis(os.getenv(redis_url_env))

    async def dispatch(self, request: Request, call_next: RequestResponseEndpoint):
        # 서브앱 전용이라 모든 요청을 보호
        secret = os.getenv(self.secret_env)
        if not secret:
            return JSONResponse({"detail":"hmac secret not configured"}, status_code=500)

        hdr = request.headers
        sig = hdr.get("x-ko-signature") or hdr.get("x-hub-signature-256") or hdr.get("x-signature")
        ts  = hdr.get("x-ko-timestamp") or hdr.get("x-timestamp") or hdr.get("x-request-timestamp")
        idem = hdr.get("x-idempotency-key") or hdr.get("idempotency-key")

        if not sig or not ts:
            return JSONResponse({"detail":"missing signature headers"}, status_code=401)
        try:
            ts_i = int(ts)
        except:
            return JSONResponse({"detail":"invalid timestamp"}, status_code=401)
        now = int(time.time())
        if abs(now - ts_i) > self.skew:
            return JSONResponse({"detail":"timestamp skew too large"}, status_code=401)

        body = await request.body()
        async def _receive():
            return {"type":"http.request","body":body,"more_body":False}
        request._receive = _receive  # type: ignore[attr-defined]

        provided = sig.split("=",1)[-1].strip().lower()
        msg = f"{ts}.{body.decode('utf-8','ignore')}".encode("utf-8")
        exp = hmac.new(secret.encode(), msg, hashlib.sha256).hexdigest()
        alt = hmac.new(secret.encode(), body, hashlib.sha256).hexdigest()
        if not (hmac.compare_digest(provided, exp) or hmac.compare_digest(provided, alt)):
            return JSONResponse({"detail":"invalid signature"}, status_code=401)

        request.state.idempotency_backend = "redis" if self._redis else "memory"
        if idem:
            if self._redis:
                try:
                    ok = self._redis.set(f"idempotency:{idem}","1",nx=True,ex=self.skew)
                    if ok is False:
                        return JSONResponse({"detail":"duplicate request","idempotency_key":idem}, status_code=409)
                except Exception:
                    pass
            else:
                # in-memory guard
                for k,u in list(self._idem.items()):
                    if u <= now: self._idem.pop(k,None)
                if idem in self._idem:
                    return JSONResponse({"detail":"duplicate request","idempotency_key":idem}, status_code=409)
                self._idem[idem] = now + self.skew

        request.state.idempotency_key = idem
        return await call_next(request)
