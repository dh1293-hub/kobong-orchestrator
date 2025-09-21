from fastapi import APIRouter
from collections import deque
import time
router = APIRouter()
_msgs = deque(maxlen=1000)
@router.post("/chat/ingest")
def ingest(item:dict):
    m={"ts":time.time(),"role":item.get("role","user"),"text":item.get("text",""),"latency_ms":int(item.get("latency_ms",0)),"ok":bool(item.get("ok",True))}
    _msgs.append(m); return {"ok":True,"size":len(_msgs)}
@router.get("/chat/recent")
def recent(limit:int=20):
    items=list(_msgs)[-limit:][::-1]
    return {"items":[{"id":f"m{i}","ts":time.strftime("%H:%M:%S",time.localtime(x["ts"])),"role":x["role"],"text":x["text"],"ok":x["ok"],"latency_ms":x["latency_ms"]} for i,x in enumerate(items)]}
@router.get("/chat/summary")
def summary():
    now=time.time(); last=[m for m in _msgs if m["ts"]>=now-3600]
    ins=sum(1 for m in last if m["role"]=="user"); outs=sum(1 for m in last if m["role"]=="assistant")
    errs=sum(1 for m in last if not m["ok"]); rate=round((errs/len(last)*100.0),1) if last else 0.0
    lats=sorted([m["latency_ms"] for m in last if m["latency_ms"]>0])
    def pct(p): 
        if not lats: return 0
        k=int(round((p/100.0)*(len(lats)-1))); return lats[k]
    return {"total_in_1h":ins,"total_out_1h":outs,"err_rate":rate,"p50":pct(50),"p95":pct(95)}