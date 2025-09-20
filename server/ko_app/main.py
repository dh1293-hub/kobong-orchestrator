from fastapi.middleware.cors import CORSMiddleware
from ko_app.middleware import RequestIDMiddleware, APIKeyMiddleware, RateLimitMiddleware
from .routers import basic
from fastapi import FastAPI
from fastapi.responses import JSONResponse
from uuid import uuid4
from datetime import datetime, timezone
import os

app = FastAPI(title="kobong-orchestrator KO", version="0.1.0")


app.add_middleware(RequestIDMiddleware)
import os as _os
_origins = [o.strip() for o in (_os.getenv('KOBONG_CORS_ORIGINS','*').split(',') if _os.getenv('KOBONG_CORS_ORIGINS') else ['*'])]
if _origins == ['*']:
    app.add_middleware(CORSMiddleware, allow_origins=['*'], allow_credentials=True, allow_methods=['*'], allow_headers=['*'])
else:
    app.add_middleware(CORSMiddleware, allow_origins=_origins, allow_credentials=True, allow_methods=['*'], allow_headers=['*'])
app.add_middleware(APIKeyMiddleware)

app.add_middleware(RateLimitMiddleware)
def nowiso():
    return datetime.now(timezone.utc).isoformat()

def j(msg: str, status: str = "ok", http: int = 200):
    return JSONResponse(status_code=http, content={
        "status": status, "traceId": str(uuid4()), "ts": nowiso(), "message": msg
    })

@app.get("/healthz")
async def healthz():
    return j("healthy")

@app.get("/readyz")
async def readyz():
    ready = os.getenv("KO_READY", "1") not in ("0", "false", "False")
    return j("ready" if ready else "not ready", status=("ok" if ready else "degraded"), http=(200 if ready else 503))

@app.get("/livez")
async def livez():
    return j("live")

@app.get("/")
async def root():
    return j("ko up")
app.include_router(basic.router, prefix='/api/v1')

# --- Day-11: metrics wiring (idempotent) ---
try:
    from ko_app.metrics import setup_metrics as _g5_setup_metrics
    _g5_setup_metrics(app)
except Exception as _g5_e:
    pass
