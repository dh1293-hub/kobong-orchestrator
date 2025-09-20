from fastapi import APIRouter, Request, BackgroundTasks
from datetime import datetime, timezone
from pathlib import Path
import json, asyncio, uuid

router = APIRouter()

def _jsonl_append(record: dict):
    d = Path("logs/webhook"); d.mkdir(parents=True, exist_ok=True)
    f = d / (datetime.now(timezone.utc).strftime("%Y%m%d") + ".log")
    with f.open("a", encoding="utf-8") as fp:
        fp.write(json.dumps(record, ensure_ascii=False) + "\n")

async def _process_event(payload: dict, attempt: int = 1, max_attempts: int = 3, backoff: float = 0.5):
    try:
        _jsonl_append({"type":"event","ts": datetime.now(timezone.utc).isoformat(), **payload})
    except Exception as e:
        if attempt < max_attempts:
            await asyncio.sleep(backoff*(2**(attempt-1)))
            return await _process_event(payload, attempt+1, max_attempts, backoff)
        _jsonl_append({"type":"error","ts": datetime.now(timezone.utc).isoformat(), "error": str(e), **payload})

@router.post("/webhook", status_code=202)
async def secure_webhook(request: Request, background_tasks: BackgroundTasks):
    body = await request.body()
    event_id = request.headers.get("x-event-id") or str(uuid.uuid4())
    idem = getattr(request.state, "idempotency_key", None)
    backend = getattr(request.state, "idempotency_backend", None)
    payload = {
        "event_id": event_id,
        "received_at": datetime.now(timezone.utc).isoformat(),
        "path": request.url.path,
        "client": getattr(request.client, "host", None),
        "body": body.decode("utf-8", "ignore")
    }
    background_tasks.add_task(_process_event, payload)
    return {"accepted": True, "event_id": event_id, "idempotency_backend": backend}
