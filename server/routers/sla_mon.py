from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import List, Dict, Any
import os, json, time, statistics
from server.routers.chat_mon import _msgs

router = APIRouter()
ROOT = os.path.dirname(os.path.dirname(__file__))
DATA = os.path.join(ROOT, "data", "sla.json")

class TeamIn(BaseModel):
    name: str
    target_ms: int

class UpsertIn(BaseModel):
    teams: List[TeamIn]

def _load()->List[Dict[str,Any]]:
    try:
        with open(DATA,"r",encoding="utf-8") as f: return json.load(f)
    except: return [{"name":"core","target_ms":800},{"name":"platform","target_ms":1000},{"name":"ui","target_ms":900}]

def _save(v):
    os.makedirs(os.path.dirname(DATA), exist_ok=True)
    with open(DATA,"w",encoding="utf-8") as f: json.dump(v,f,ensure_ascii=False,indent=2)

@router.get("/sla/summary")
def summary(hours:int=24):
    cfg=_load()
    now=time.time(); since = now - hours*3600
    out=[]
    for t in cfg:
      name=t["name"]; tgt=int(t.get("target_ms",1000))
      msgs=[m for m in list(_msgs) if m.get("team")==name and m["ts"]>=since]
      lats=[m["latency_ms"] for m in msgs if m.get("latency_ms",0)>0]
      p50=int(statistics.median(lats)) if lats else 0
      p95=int(sorted(lats)[int(len(lats)*0.95)-1]) if lats and len(lats)>=20 else (p50*2 if p50 else 0)
      errs=sum(1 for m in msgs if not m.get("ok",True))
      rate=round((errs/len(msgs)*100.0),1) if msgs else 0.0
      status = "ok" if p95<=tgt else ("warn" if p95<=tgt*1.3 else "err")
      out.append({"name":name,"target_ms":tgt,"p50_ms":p50,"p95_ms":p95,"error_rate":rate,"status":status,"count":len(msgs)})
    return {"items": out}

@router.post("/sla/upsert")
def upsert(body:UpsertIn):
    mp={t.name: t.target_ms for t in body.teams}
    cfg=_load()
    d={c["name"]:c for c in cfg}
    for k,v in mp.items():
        d[k]={"name":k,"target_ms":int(v)}
    _save(list(d.values()))
    return {"ok": True, "teams": list(d.values())}