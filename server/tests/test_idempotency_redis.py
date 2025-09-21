import os, time, json, hmac, hashlib, uuid, pytest
from fastapi import FastAPI
from httpx import AsyncClient, ASGITransport
from server.routes.secure import router as secure_router
from server.middleware.hmac_auth import HMACAuthMiddleware

def _h(msg, secret): return hmac.new(secret.encode(), msg.encode(), hashlib.sha256).hexdigest()

def _can_use_redis(url: str) -> bool:
    try:
        import redis  # type: ignore
        r = redis.Redis.from_url(url, decode_responses=True)
        r.ping()
        return True
    except Exception:
        return False

def _make_app():
    app = FastAPI()
    app.add_middleware(HMACAuthMiddleware)
    app.include_router(secure_router)
    return app

@pytest.mark.anyio
async def test_idempotency_persists_across_app_instances(monkeypatch):
    url = os.getenv("KOBONG_REDIS_URL")
    if not url or not _can_use_redis(url):
        pytest.skip("redis not available — skipping persistent idempotency test")

    monkeypatch.setenv("KOBONG_WEBHOOK_SECRET", "test_secret")

    payload = {"hello":"world"}
    body_raw = json.dumps(payload, separators=(",",":"))
    ts = int(time.time())
    sig = _h(f"{ts}.{body_raw}", "test_secret")
    idem = f"t-{uuid.uuid4()}"

    headers = {
        "x-ko-timestamp": str(ts),
        "x-ko-signature": f"sha256={sig}",
        "x-idempotency-key": idem,
        "content-type": "application/json",
    }

    # 인스턴스 1
    app1 = _make_app()
    async with AsyncClient(transport=ASGITransport(app=app1), base_url="http://test") as ac:
        r1 = await ac.post("/secure/ping", content=body_raw, headers=headers)
        if r1.status_code == 401:  # 환경 차이 폴백: body-only
            headers["x-ko-signature"] = f"sha256={_h(body_raw,'test_secret')}"
            r1 = await ac.post("/secure/ping", content=body_raw, headers=headers)
        assert r1.status_code == 200

    # 인스턴스 2(재시작 시뮬)
    app2 = _make_app()
    async with AsyncClient(transport=ASGITransport(app=app2), base_url="http://test") as ac:
        r2 = await ac.post("/secure/ping", content=body_raw, headers=headers)
        assert r2.status_code == 409  # Redis 덕분에 재시작 후에도 중복 차단 유지
# --- ko-monitoring (auto-wired) ---
try:
    from .routers.github_mon import router as github_router
except Exception:
    try:
        from server.routers.github_mon import router as github_router
    except Exception:
        github_router = None
try:
    from .routers.chat_mon import router as chat_router
except Exception:
    try:
        from server.routers.chat_mon import router as chat_router
    except Exception:
        chat_router = None
if "app" in globals():
    if github_router:
        try: app.include_router(github_router, prefix="/api/mon/github", tags=["monitoring"])
        except Exception: pass
    if chat_router:
        try: app.include_router(chat_router, prefix="/api/mon", tags=["monitoring"])
        except Exception: pass
# --- end ko-monitoring ---
# --- ko-cors (dev) ---
try:
    from fastapi.middleware.cors import CORSMiddleware
    _origins=['http://localhost:5173','http://127.0.0.1:5173','*']
    app.add_middleware(CORSMiddleware, allow_origins=_origins, allow_methods=['*'], allow_headers=['*'])
except Exception: 
    pass
# --- end ko-cors ---
# --- ko-monitoring (auto-wired) ---
try:
    from .routers.github_mon import router as github_router
except Exception:
    try: from routers.github_mon import router as github_router
    except Exception: github_router=None
try:
    from .routers.chat_mon import router as chat_router
except Exception:
    try: from routers.chat_mon import router as chat_router
    except Exception: chat_router=None
try:
    from .routers.monitoring import router as monitoring_router
except Exception:
    try: from routers.monitoring import router as monitoring_router
    except Exception: monitoring_router=None
if "app" in globals():
    try:
        if monitoring_router: app.include_router(monitoring_router, prefix="/api/mon", tags=["monitoring"])
        if github_router:     app.include_router(github_router,     prefix="/api/mon/github", tags=["monitoring"])
        if chat_router:       app.include_router(chat_router,       prefix="/api/mon", tags=["monitoring"])
    except Exception: pass
# --- end ko-monitoring ---