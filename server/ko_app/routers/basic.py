from typing import List, Optional, Any, Dict
from fastapi import APIRouter
from pydantic import BaseModel

router = APIRouter(tags=["basic"])

class EchoIn(BaseModel):
    text: str
    meta: Optional[Dict[str, Any]] = None

class SumIn(BaseModel):
    numbers: List[float]

@router.get("/ping")
async def ping():
    return {"pong": True}

@router.post("/echo")
async def echo(body: EchoIn):
    return {"echo": body.text, "meta": body.meta}

@router.post("/sum")
async def sum_numbers(body: SumIn):
    total = sum(body.numbers)
    return {"sum": total, "count": len(body.numbers)}