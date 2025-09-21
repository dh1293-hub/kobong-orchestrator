from fastapi import APIRouter, HTTPException
from collections import deque
import time, statistics

router = APIRouter()
_msgs = deque(maxlen=5000)

@router.post("/chat/ingest")
def ingest(item:dict):
    m={
        "ts": time.time(),
        "team": item.get("team") or "core",
        "role": item.get("role","user"),
        "text": item.get("text",""),
        "latency_ms": int(item.get("latency_ms",0)),
        "ok": bool(item.get("ok",True))
    }
    _msgs.append(m)
    return {"ok": True, "size": len(_msgs)}

@router.get("/chat/recent")
def recent(limit:int=20):
    out = list(_msgs)[-max(0,min(1000,limit)):]
    # 형식 축약
    return {"items":[{"id":i,"role":m["role"],"text":m["text"],"ts":time.strftime("%H:%M:%S", time.localtime(m["ts"])), "ok":m["ok"]} for i,m in enumerate(out,1)]}

@router.get("/chat/summary")
def summary():
    now=time.time()
    last=[m for m in _msgs if m["ts"]>=now-3600]
    lats=[m["latency_ms"] for m in last if isinstance(m.get("latency_ms"), (int,float)) and m["latency_ms"]>0]
    p50 = int(statistics.median(lats)) if lats else 0
    p95 = int(sorted(lats)[int(len(lats)*0.95)-1]) if lats and len(lats)>=20 else (p50*2 if p50 else 0)
    errs=sum(1 for m in last if not m.get("ok",True))
    rate=round((errs/len(last)*100.0),1) if last else 0.0
    ins=sum(1 for m in last if m["role"]=="user"); outs=sum(1 for m in last if m["role"]=="assistant")
    return {"total_in_1h":ins,"total_out_1h":outs,"err_rate":rate,"p50":p50,"p95":p95}