import time, hmac, hashlib, json, uuid
import pytest
from httpx import AsyncClient, ASGITransport

def _hmac_hex(msg: str, secret: str) -> str:
    return hmac.new(secret.encode(), msg.encode(), hashlib.sha256).hexdigest()

@pytest.mark.anyio
async def test_secure_ping_401_when_missing_headers(fresh_app):
    async with AsyncClient(transport=ASGITransport(app=fresh_app), base_url="http://test") as ac:
        r = await ac.get("/secure/ping")
        assert r.status_code == 401

@pytest.mark.anyio
async def test_secure_ping_200_with_valid_signature(fresh_app):
    """아이템포턴시 없이 HMAC(body-only)로 200 확인"""
    payload = {"hello":"world"}
    body_raw = json.dumps(payload, separators=(",",":"))
    ts = int(time.time())

    # body-only 서명 → X-Hub-Signature-256 사용
    sig_body = _hmac_hex(body_raw, "test_secret")
    headers = {
        "x-ko-timestamp": str(ts),
        "x-hub-signature-256": f"sha256={sig_body}",
        "content-type": "application/json",
    }
    async with AsyncClient(transport=ASGITransport(app=fresh_app), base_url="http://test") as ac:
        r = await ac.post("/secure/ping", content=body_raw, headers=headers)
        assert r.status_code == 200
        assert r.json().get("pong") is True

@pytest.mark.anyio
async def test_secure_ping_409_on_duplicate_idempotency(fresh_app):
    """같은 키로 2회 호출 시 200 → 409"""
    payload = {"hello":"world"}
    body_raw = json.dumps(payload, separators=(",",":"))
    ts = int(time.time())
    idem = f"t-{uuid.uuid4()}"

    sig_body = _hmac_hex(body_raw, "test_secret")
    headers = {
        "x-ko-timestamp": str(ts),
        "x-hub-signature-256": f"sha256={sig_body}",
        "x-idempotency-key": idem,
        "content-type": "application/json",
    }
    async with AsyncClient(transport=ASGITransport(app=fresh_app), base_url="http://test") as ac:
        r1 = await ac.post("/secure/ping", content=body_raw, headers=headers)
        assert r1.status_code == 200

        r2 = await ac.post("/secure/ping", content=body_raw, headers=headers)
        assert r2.status_code == 409