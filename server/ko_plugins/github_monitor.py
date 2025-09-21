# coding: utf-8
import asyncio, hmac, hashlib, json, os
from datetime import datetime, timezone
from pathlib import Path
from fastapi import APIRouter, FastAPI, Request, HTTPException
from fastapi.responses import StreamingResponse
from starlette.datastructures import MutableHeaders

router_root = APIRouter()
router_admin = APIRouter(prefix="/admin", tags=["admin"])
router_webhook = APIRouter(tags=["webhook"])
router_sse = APIRouter(tags=["sse"])

@router_root.get("/health")

def health(): return {"ok": True}

class Hub:
    def __init__(self): self.clients: set[asyncio.Queue] = set()
    async def publish(self, payload: dict):
        data = json.dumps(payload, ensure_ascii=False)
        for q in list(self.clients):
            try: q.put_nowait(data)
            except Exception:
                try: self.clients.remove(q)
                except: pass
    async def subscribe(self) -> asyncio.Queue:
        q: asyncio.Queue = asyncio.Queue()
        self.clients.add(q); return q
    async def unsubscribe(self, q: asyncio.Queue): self.clients.discard(q)

hub = Hub()

def repo_root() -> Path:
    here = Path(__file__).resolve()
    for p in [here] + list(here.parents):
        if (p / "server").exists() and (p / ".git").exists(): return p
    return Path(__file__).resolve().parents[1]

def webui_env_path() -> Path: return repo_root() / "webui" / ".env.local"

def atomic_write(path: Path, content: str):
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_name("." + path.name + ".tmp")
    tmp.write_text(content, encoding="utf-8", newline="\n")
    if path.exists():
        bak = path.with_name(path.name + ".bak-" + datetime.now().strftime("%Y%m%d-%H%M%S"))
        bak.write_text(path.read_text(encoding="utf-8"), encoding="utf-8")
    tmp.replace(path)

def merge_env(existing: str, updates: dict[str,str]) -> str:
    lines = existing.splitlines() if existing else []
    out, seen = [], set()
    for ln in lines:
        if not ln.strip() or ln.strip().startswith("#"): out.append(ln); continue
        if "=" in ln:
            k, v = ln.split("=", 1); k2 = k.strip()
            if k2 in updates: out.append(f"{k2}={updates[k2]}"); seen.add(k2)
            else: out.append(ln)
        else: out.append(ln)
    for k, v in updates.items():
        if k not in seen: out.append(f"{k}={v}")
    return "\n".join(out) + "\n"

@router_admin.post("/env/set")
async def admin_env_set(body: dict):
    entries = body.get("entries") or []; updates = {}
    for it in entries:
        k = (it.get("key") or "").strip().upper()
        if not k or any(ch in k for ch in " \t\r\n\"'`"): raise HTTPException(400, f"invalid key: {k!r}")
        v = str(it.get("value") or "").replace("\r\n","\n").replace("\n","")
        updates[k] = v
    if not updates: return {"ok": True, "noop": True}
    p = webui_env_path()
    content = merge_env(p.read_text(encoding="utf-8") if p.exists() else "", updates)
    atomic_write(p, content); return {"ok": True, "path": str(p)}

@router_admin.post("/bridge/toggle")
async def admin_bridge_toggle(body: dict):
    on = bool(body.get("on")); p = webui_env_path()
    content = merge_env(p.read_text(encoding="utf-8") if p.exists() else "", {"KOBONG_BRIDGE_FIRST": "1" if on else "0"})
    atomic_write(p, content); return {"ok": True, "path": str(p), "on": on}

def verify_signature(secret: str, body: bytes, sig256: str) -> bool:
    if not sig256 or not sig256.startswith("sha256="): return False
    mac = hmac.new(secret.encode("utf-8"), msg=body, digestmod=hashlib.sha256).hexdigest()
    return hmac.compare_digest(mac, sig256.split("=",1)[1])

@router_webhook.post("/webhook/github")
async def webhook_github(request: Request):
    secret = os.getenv("KOBONG_WEBHOOK_SECRET","")
    raw = await request.body()
    sig = request.headers.get("X-Hub-Signature-256","")
    if secret and not verify_signature(secret, raw, sig): raise HTTPException(401, "bad signature")
    event = request.headers.get("X-GitHub-Event","")
    payload = await request.json()
    repo = (payload.get("repository") or {}).get("full_name") or ""
    at = datetime.now(timezone.utc).isoformat()
    out = {"type": event, "repo": repo, "at": at}
    if event == "push": out["ref"] = payload.get("ref")
    elif event == "release": out["action"] = payload.get("action"); out["tag"] = (payload.get("release") or {}).get("tag_name")
    elif event == "issues": out["action"] = payload.get("action"); out["number"] = (payload.get("issue") or {}).get("number")
    await hub.publish(out); return {"ok": True}

# SSE (요청 바디 선소진 + 핑)
@router_sse.get("/sse/github")
async def sse_github(request: Request):

    import asyncio, time

    async def event_stream():

        # 첫 하트비트

        yield ":ok\n\n"

        while True:
            yield f"event: heartbeat\ndata: ok\ntime: {int(time.time())}\n\n"

            await asyncio.sleep(15)

    headers = {"Cache-Control":"no-cache","Connection":"keep-alive","X-Accel-Buffering":"no"}

    return StreamingResponse(event_stream(), media_type="text/event-stream", headers=headers)

class ASGICORSMiddleware:
    def __init__(self, app, allow_origins=None, allow_methods=None, allow_headers=None, allow_credentials=False):
        self.app = app
        self.allow_origins = allow_origins or ["*"]
        self.allow_methods = allow_methods or ["*"]
        self.allow_headers = allow_headers or ["*"]
        self.allow_credentials = allow_credentials
    async def __call__(self, scope, receive, send):
        if scope.get("type") != "http": return await self.app(scope, receive, send)
        origin = None
        for k, v in scope.get("headers", []):
            if k == b"origin":
                try: origin = v.decode()
                except: origin = None
                break
        allow_origin = origin if origin else "*"
        if scope.get("method") == "OPTIONS":
            headers = []; mh = MutableHeaders(raw=headers)
            mh.append("access-control-allow-origin", allow_origin)
            mh.append("access-control-allow-credentials", "false" if not self.allow_credentials else "true")
            mh.append("access-control-allow-methods", "*")
            mh.append("access-control-allow-headers", "*")
            mh.append("access-control-max-age", "600")
            await send({"type":"http.response.start","status":204,"headers":headers})
            await send({"type":"http.response.body","body":b""}); return
        async def send_wrapper(message):
            if message["type"] == "http.response.start":
                mh = MutableHeaders(raw=message.setdefault("headers", []))
                mh.append("access-control-allow-origin", allow_origin)
                mh.append("access-control-allow-credentials", "false" if not self.allow_credentials else "true")
                mh.append("access-control-expose-headers", "*")
            await send(message)
        return await self.app(scope, receive, send_wrapper)

# GET/HEAD에서 초기 http.request 1회 흡수
class DrainGetRequestMiddleware:
    def __init__(self, app): self.app = app
    async def __call__(self, scope, receive, send):
        if scope.get("type") != "http" or scope.get("method") not in ("GET","HEAD"):
            return await self.app(scope, receive, send)
        consumed = {"done": False}
        async def recv_wrapper():
            if not consumed["done"]:
                consumed["done"] = True
                msg = await receive()
                if msg.get("type") == "http.request" and not msg.get("more_body") and not msg.get("body"):
                    return await receive()
                return msg
            return await receive()
        return await self.app(scope, recv_wrapper, send)

def mount(app: FastAPI):
    # 가능한 CORS(BaseHTTPMiddleware) 제거
    try:
        from starlette.middleware.cors import CORSMiddleware
        app.user_middleware = [m for m in getattr(app, "user_middleware", []) if getattr(m, "cls", None) is not CORSMiddleware]
    except Exception: pass
    # 미들웨어 순서: Drain → ASGI CORS → existing
    try:
        from starlette.middleware import Middleware
        app.user_middleware = list(getattr(app, "user_middleware", []))
        app.user_middleware.insert(0, Middleware(ASGICORSMiddleware))
        app.user_middleware.insert(0, Middleware(DrainGetRequestMiddleware))
    except Exception:
        app.user_middleware = list(getattr(app, "user_middleware", []))
        app.user_middleware.insert(0, type("MW", (), {"cls": ASGICORSMiddleware, "options": {}})())
        app.user_middleware.insert(0, type("MW", (), {"cls": DrainGetRequestMiddleware, "options": {}})())
    # 라우터 등록 (루트/헬스 포함)
    app.include_router(router_root)
    app.include_router(router_admin)
    app.include_router(router_webhook)
    app.include_router(router_sse)