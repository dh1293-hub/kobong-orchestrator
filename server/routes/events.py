from __future__ import annotations
from typing import Any, Optional
import json
from fastapi import APIRouter, status, Request, HTTPException
from pydantic import BaseModel
from ..events.dispatcher import dispatch
from ..security.webhook import verify
from ..metrics import hooks

class EventIn(BaseModel):
    type: str
    data: Optional[Any] = None

router = APIRouter(tags=["events"])

@router.post("/events", status_code=status.HTTP_202_ACCEPTED)
async def post_event(request: Request, evt: EventIn):
    body = await request.body()
    ok, code, msg = verify(dict(request.headers), body)
    if not ok:
        hooks.emit("events.rejected", 1, {"reason": msg, "status": str(code)})
        raise HTTPException(status_code=code, detail=msg)

    dispatch({"type": evt.type, "data": evt.data})
    hooks.emit("events.accepted", 1, {"type": (evt.type or "unknown")})
    return {"accepted": True}