from fastapi import APIRouter, Request, HTTPException
from pydantic import BaseModel, Field
from typing import Optional, Literal, List, Dict, Any
import os, json, time, glob
from datetime import datetime, timezone
from .demo_state import is_demo

router = APIRouter()

DATA_DIR = os.path.join(os.path.dirname(__file__), "..", "data")
os.makedirs(DATA_DIR, exist_ok=True)
FEED = os.path.join(DATA_DIR, "chat_feed.jsonl")
ROTATE_MAX_BYTES = 5_000_000

def _now_iso():
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

def _rotate_and_trim(path: str, keep: int = 30):
    try:
        if os.path.exists(path) and os.path.getsize(path) > ROTATE_MAX_BYTES:
            ts = datetime.now().strftime("%Y%m%d-%H%M%S")
            dst = f"{path}.{ts}"
            os.replace(path, dst)
        patt = f"{path}.20*"
        files = sorted(glob.glob(patt), key=lambda p: os.path.getmtime(p), reverse=True)
        for f in files[keep:]:
            try: os.remove(f)
            except: pass
    except: pass

class ChatItem(BaseModel):
    id: Optional[int] = None
    when_iso: str = Field(default_factory=_now_iso)
    dir: Literal["in","out"]
    source: str = "kobong-orchestrator"
    target: str = "github"
    owner: Optional[str] = None
    repo: Optional[str] = None
    channel: Optional[str] = None   # issue_comment | pr_comment | discussion | workflow | etc
    url: Optional[str] = None
    title: Optional[str] = None
    text: Optional[str] = None
    meta: Optional[Dict[str, Any]] = None

def _append(item: ChatItem) -> ChatItem:
    _rotate_and_trim(FEED, keep=30)
    try:
        next_id = 1
        if os.path.exists(FEED):
            with open(FEED, "rb") as fh:
                try:
                    fh.seek(-20000, os.SEEK_END)  # tail read
                except:
                    fh.seek(0)
                last = None
                for line in fh.readlines():
                    try:
                        obj = json.loads(line.decode("utf-8","ignore"))
                        last = obj
                    except:
                        pass
                if last and isinstance(last.get("id"), int):
                    next_id = int(last["id"]) + 1
        item.id = next_id
        with open(FEED, "a", encoding="utf-8") as fw:
            fw.write(json.dumps(item.dict(), ensure_ascii=False) + "\n")
    except:
        pass
    return item

def _tail(limit: int = 200) -> list:
    out = []
    if not os.path.exists(FEED):
        return out
    with open(FEED, "rb") as fh:
        try:
            fh.seek(-500000, os.SEEK_END)
        except:
            fh.seek(0)
        lines = fh.readlines()[-limit:]
    for ln in lines:
        try:
            out.append(json.loads(ln.decode("utf-8","ignore")))
        except:
            pass
    return out

@router.post("/push")
def push(item: ChatItem):
    try:
        return _append(item)
    except Exception as e:
        raise HTTPException(400, str(e))

@router.get("/list")
def list_chat(limit: int = 200, dir: str = "all", since_id: Optional[int] = None):
    # DEMO fallback: generate items if no feed and demo enabled
    if not os.path.exists(FEED) and is_demo(None):
        import random
        rnd = random.Random(int(time.time())//10)
        items=[]
        for i in range(30):
            d = "out" if i % 2 == 0 else "in"
            items.append({
              "id": i+1,
              "when_iso": _now_iso(),
              "dir": d,
              "source": "kobong-orchestrator" if d=="out" else "github",
              "target": "github" if d=="out" else "kobong-orchestrator",
              "owner": "dh1293-hub",
              "repo": "kobong-orchestrator",
              "channel": rnd.choice(["issue_comment","pr_comment","discussion"]),
              "url": "https://github.com/dh1293-hub/kobong-orchestrator",
              "title": rnd.choice(["feat: release prep","fix: pipeline","docs: update readme"]),
              "text": rnd.choice(["LGTM","Please rebase","CI failed on e2e","Released v1.2.3","Auto-close stale"]),
              "meta": {"demo": True}
            })
        return {"items": items}
    items = _tail(limit=limit)
    if since_id is not None:
        try:
            si = int(since_id)
            items = [x for x in items if (isinstance(x.get("id"), int) and x["id"] > si)]
        except:
            pass
    if dir in ("in","out"):
        items = [x for x in items if x.get("dir")==dir]
    return {"items": items}