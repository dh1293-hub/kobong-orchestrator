from fastapi import APIRouter, Request
from datetime import datetime, timezone

router = APIRouter()

@router.get("/ping")
@router.post("/ping")
async def secure_ping(request: Request):
    return {
        "pong": True,
        "server_time": datetime.now(timezone.utc).isoformat(),
        "idempotency_key": getattr(request.state, "idempotency_key", None),
        "idempotency_backend": getattr(request.state, "idempotency_backend", None),
    }
