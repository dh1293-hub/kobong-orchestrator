from fastapi import FastAPI, Request
from starlette.middleware.base import BaseHTTPMiddleware, RequestResponseEndpoint
from starlette.responses import JSONResponse
from datetime import datetime, timezone
import os, hmac, hashlib, time

class LocalHMACMiddleware(BaseHTTPMiddleware):
    def __init__(self, app, secret_env="KOBONG_WEBHOOK_SECRET", skew_seconds=300):
        super().__init__(app); self.secret_env=secret_env; self.skew=skew_seconds
    async def dispatch(self, request: Request, call_next: RequestResponseEndpoint):
        secret=os.getenv(self.secret_env) or "dev_secret"
        hdr=request.headers
        sig=hdr.get("x-ko-signature") or hdr.get("x-hub-signature-256") or hdr.get("x-signature")
        ts =hdr.get("x-ko-timestamp") or hdr.get("x-timestamp") or hdr.get("x-request-timestamp")
        if not sig or not ts: return JSONResponse({"detail":"missing signature headers"},401)
        try: ts_i=int(ts)
        except: return JSONResponse({"detail":"invalid timestamp"},401)
        if abs(int(time.time())-ts_i)>self.skew: return JSONResponse({"detail":"timestamp skew too large"},401)
        body=await request.body()
        async def _recv(): return {"type":"http.request","body":body,"more_body":False}
        request._receive=_recv  # type: ignore
        provided=sig.split("=",1)[-1].strip().lower()
        exp=hmac.new(secret.encode(), f"{ts}.{body.decode('utf-8','ignore')}".encode(), hashlib.sha256).hexdigest()
        alt=hmac.new(secret.encode(), body, hashlib.sha256).hexdigest()
        if not (hmac.compare_digest(provided,exp) or hmac.compare_digest(provided,alt)):
            return JSONResponse({"detail":"invalid signature"},401)
        return await call_next(request)

app=FastAPI()

@app.post("/open/echo")
async def open_echo(request: Request):
    body=await request.body()
    return {"path":"/open/echo","body":body.decode("utf-8"),"headers":dict(request.headers)}

secure_app=FastAPI()
secure_app.add_middleware(LocalHMACMiddleware)

@secure_app.get("/ping")
@secure_app.post("/ping")
async def secure_ping(request: Request):
    return {"pong":True,"server_time":datetime.now(timezone.utc).isoformat()}
app.mount("/secure", secure_app)
