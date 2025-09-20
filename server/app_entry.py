from fastapi import FastAPI, Request
from datetime import datetime, timezone
from .routes.diag import router as diag_router
from .middleware.hmac_auth import HMACAuthMiddleware
from .routes.webhook import router as webhook_router

app = FastAPI()
app.include_router(diag_router)

secure_app = FastAPI()
secure_app.add_middleware(HMACAuthMiddleware)

@secure_app.get("/ping")
@secure_app.post("/ping")
async def secure_ping(request: Request):
    return {
        "pong": True,
        "server_time": datetime.now(timezone.utc).isoformat(),
        "idempotency_key": getattr(request.state, "idempotency_key", None),
        "idempotency_backend": getattr(request.state, "idempotency_backend", None),
    }

secure_app.include_router(webhook_router)
app.mount("/secure", secure_app)

# --- GPT-5: audit middleware bootstrap ---
try:
    from .middleware.audit import AuditMiddleware  # type: ignore
    app.add_middleware(AuditMiddleware)
except Exception as _e:
    # fail-safe: do not break app startup
    pass
# --- GPT-5: telemetry routes bootstrap ---
try:
    from .routes import metrics as _g5_metrics  # type: ignore
    from .routes import events as _g5_events    # type: ignore
    app.include_router(_g5_metrics.router)
    app.include_router(_g5_events.router)
except Exception:
    pass