from fastapi.testclient import TestClient
from server.app import app

def test_health_endpoints():
    client = TestClient(app)
    for path in ("/healthz", "/readyz", "/livez"):
        resp = client.get(path)
        assert resp.status_code == 200
        body = resp.json()
        assert body.get("ok") is True
        assert "ts" in body

def test_echo_headers():
    client = TestClient(app)
    resp = client.get("/echo", headers={"x-idempotency-key": "abc123", "x-priority": "5"})
    assert resp.status_code == 200
    body = resp.json()
    assert body.get("idempotency_key") == "abc123"
    assert str(body.get("priority")) == "5"
