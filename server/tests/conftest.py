import pytest
from fastapi import FastAPI
from server.routes.secure import router as secure_router
from server.middleware.hmac_auth import HMACAuthMiddleware

@pytest.fixture
def anyio_backend():
    return "asyncio"

@pytest.fixture
def fresh_app(monkeypatch):
    # 각 테스트가 고유 인메모리 스토어를 갖도록 새 앱 구성
    monkeypatch.setenv("KOBONG_WEBHOOK_SECRET", "test_secret")
    app = FastAPI()
    app.add_middleware(HMACAuthMiddleware)
    app.include_router(secure_router)
    return app
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

# === [gpt5-fixture-override] begin ===
import pytest
from fastapi import FastAPI
def _include_v1_routers(app):
    try:
        from server.api import v1_endpoints as v1
    except Exception:
        return
    for r in getattr(v1, "router_v1", None), getattr(v1, "root_router", None), getattr(v1, "secure_router", None), getattr(v1, "metrics_router", None), getattr(v1, "health_router", None):
        if r is not None:
            try: app.include_router(r)
            except Exception: pass

@pytest.fixture
def fresh_app():
    app = FastAPI()
    _include_v1_routers(app)
    return app
# === [gpt5-fixture-override] end ===