import os, json, threading, re, time
from datetime import datetime, timezone

ENABLED = os.environ.get("KOBONG_CHAT_MON","1") in ("1","true","yes")
MON_API = (os.environ.get("KOBONG_MON_API") or "http://127.0.0.1:8094").rstrip("/")
GH_RE = re.compile(r"^https?://(api\.)?github\.com", re.I)
_guard = threading.local()

def _now(): return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

def emit_chat(payload: dict):
    try:
        # 재귀 방지
        if getattr(_guard, "emitting", False): return
        _guard.emitting = True
        import httpx
        with httpx.Client(timeout=2.0) as c:
            c.post(MON_API+"/api/mon/chat/push", json=payload, headers={"X-Chat-Emit":"1"})
    except Exception:
        pass
    finally:
        _guard.emitting = False

def _maybe_emit(method: str, url: str, data: bytes|str|None, json_body):
    if not ENABLED: return
    if not GH_RE.match(url): return
    m = method.upper()
    if m not in ("POST","PUT","PATCH"): return
    text = None; title=None; owner=None; repo=None; channel=None; link=None
    try:
        # payload 추출
        if isinstance(json_body, dict):
            title = json_body.get("title")
            text  = json_body.get("body") or json_body.get("comment") or json_body.get("message")
        elif isinstance(data, (bytes,str)):
            s = data.decode("utf-8","ignore") if isinstance(data, bytes) else data
            if '"body"' in s or '"title"' in s:
                try:
                    import json as _j; j=_j.loads(s); title=j.get("title"); text=j.get("body")
                except: pass
        # owner/repo 추출
        m2 = re.search(r"/repos/([^/]+)/([^/]+)/", url)
        if m2: owner, repo = m2.group(1), m2.group(2)
        # channel 추정
        if "/issues/" in url and "/comments" in url: channel="issue_comment"
        elif "/pulls/" in url and "/comments" in url: channel="pr_comment"
        elif "/discussions/" in url: channel="discussion"
        # 링크 후보
        if "github.com" in url: link=url
    except Exception:
        pass
    payload = {
        "dir":"out","source":"kobong-orchestrator","target":"github",
        "when_iso": _now(),"owner":owner,"repo":repo,"channel":channel,"url":link,
        "title": title, "text": text, "meta":{"method":m, "url":url[:160]}
    }
    emit_chat(payload)

# httpx 훅
try:
    import httpx
    _orig_httpx_request = httpx.request
    def _hx_request(method, url, *a, **kw):
        try:
            _maybe_emit(method, url, kw.get("data"), kw.get("json"))
        except Exception:
            pass
        return _orig_httpx_request(method, url, *a, **kw)
    httpx.request = _hx_request

    _orig_client_request = httpx.Client.request
    def _client_request(self, method, url, *a, **kw):
        try:
            _maybe_emit(method, url, kw.get("data"), kw.get("json"))
        except Exception:
            pass
        return _orig_client_request(self, method, url, *a, **kw)
    httpx.Client.request = _client_request
except Exception:
    pass

# requests 훅
try:
    import requests
    _orig_req_request = requests.api.request
    def _rq_request(method, url, **kw):
        try:
            _maybe_emit(method, url, kw.get("data"), kw.get("json"))
        except Exception:
            pass
        return _orig_req_request(method, url, **kw)
    requests.api.request = _rq_request

    _orig_sess_request = requests.Session.request
    def _sess_request(self, method, url, **kw):
        try:
            _maybe_emit(method, url, kw.get("data"), kw.get("json"))
        except Exception:
            pass
        return _orig_sess_request(self, method, url, **kw)
    requests.Session.request = _sess_request
except Exception:
    pass