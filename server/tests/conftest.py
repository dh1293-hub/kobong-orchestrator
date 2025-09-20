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