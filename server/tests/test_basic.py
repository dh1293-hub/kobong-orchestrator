import pytest
from httpx import AsyncClient, ASGITransport
from ko_app.main import app

@pytest.mark.asyncio
async def test_ping():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        r = await ac.get("/api/v1/ping")
        assert r.status_code == 200
        assert r.json()["pong"] is True

@pytest.mark.asyncio
async def test_echo():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        r = await ac.post("/api/v1/echo", json={"text": "hello", "meta": {"a":1}})
        assert r.status_code == 200
        j = r.json()
        assert j["echo"] == "hello"
        assert j["meta"]["a"] == 1

@pytest.mark.asyncio
async def test_sum():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        r = await ac.post("/api/v1/sum", json={"numbers":[1,2,3.5]})
        assert r.status_code == 200
        j = r.json()
        assert j["count"] == 3
        assert abs(j["sum"] - 6.5) < 1e-9