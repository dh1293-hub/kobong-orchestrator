from fastapi.testclient import TestClient
import importlib, os

def test_metrics_enabled(monkeypatch):
    import ko_app.main as m
    monkeypatch.setenv('KOBONG_ENABLE_METRICS','true')
    importlib.reload(m)
    app = m.app
    c = TestClient(app)
    r = c.get('/metrics')
    assert r.status_code == 200
    ct = r.headers.get('content-type','')
    assert 'text/plain' in ct
    body = r.content
    assert b'http_requests_total' in body or b'python_info' in body