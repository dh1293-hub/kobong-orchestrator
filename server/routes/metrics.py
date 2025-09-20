from __future__ import annotations
from fastapi import APIRouter, Response
from ..metrics.prom import render_prom

router = APIRouter(tags=["metrics"])

@router.get("/metrics")
def metrics():
    body = render_prom()
    return Response(content=body, media_type="text/plain; version=0.0.4; charset=utf-8")