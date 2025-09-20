import os, time, hmac, hashlib, json
from fastapi.testclient import TestClient
from server.app import app

def sign(secret: bytes, method: str, path: str, ts: int, body: bytes) -> str:
    can = f"{method}\n{path}\n{ts}\n".encode("utf-8") + body
    return hmac.new(secret, can, hashlib.sha256).hexdigest()

def test_signature_ok_and_idempotency():
    os.environ["KOBONG_SIGNING_KEY"] = "test-secret"
    client = TestClient(app)
    ts = int(time.time())
    body = json.dumps({"msg":"hi"}).encode()
    sig = sign(b"test-secret","POST","/echo",ts,body)
    h = {"x-timestamp": str(ts), "x-signature": sig, "x-idempotency-key": "idem-1", "content-type":"application/json"}
    r1 = client.post("/echo", data=body, headers=h); assert r1.status_code == 200
    r2 = client.post("/echo", data=body, headers=h); assert r2.status_code == 409

def test_signature_skew_rejected():
    os.environ["KOBONG_SIGNING_KEY"] = "test-secret"
    client = TestClient(app)
    ts = int(time.time()) - 10000
    body = b'{}'
    sig = sign(b"test-secret","POST","/echo",ts,body)
    h = {"x-timestamp": str(ts), "x-signature": sig, "content-type":"application/json"}
    r = client.post("/echo", data=body, headers=h)
    assert r.status_code == 401
