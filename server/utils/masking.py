from __future__ import annotations
import re
from typing import Any, Mapping, Sequence

SENSITIVE_KEYS = {"authorization","password","passwd","pwd","secret","token","access_token","refresh_token","api_key","set-cookie","cookie","cookies"}

_email = re.compile(r"([A-Za-z0-9._%+-])([A-Za-z0-9._%+-]*?)@([A-Za-z0-9.-]+\.[A-Za-z]{2,})")
_bearer = re.compile(r"(?i)\bBearer\s+([A-Za-z0-9._-]{6,})")
_hex = re.compile(r"\b([A-Fa-f0-9]{24,64})\b")
_card = re.compile(r"\b(\d{12,19})\b")

def _mask_str(s: str) -> str:
    s = _email.sub(lambda m: f"{m.group(1)}***@{m.group(3)}", s)
    s = _bearer.sub("Bearer ***", s)
    s = _hex.sub(lambda m: m.group(1)[:4]+"***"+m.group(1)[-2:], s)
    s = _card.sub(lambda m: m.group(1)[:6] + "*"*(len(m.group(1))-10) + m.group(1)[-4:], s)
    return s

def mask(value: Any, key_hint: str|None=None, depth: int=0, max_depth: int=6) -> Any:
    if depth>max_depth: return "***"
    if key_hint and key_hint.lower() in SENSITIVE_KEYS: return "***"
    if isinstance(value, str): return _mask_str(value)
    if isinstance(value, Mapping):
        return {k: mask(v, k, depth+1, max_depth) for k,v in value.items()}
    if isinstance(value, Sequence) and not isinstance(value,(bytes,bytearray)):
        return [mask(x, key_hint, depth+1, max_depth) for x in value]
    return value

def summarize_body(body: Any, max_preview: int=512) -> dict:
    try:
        if isinstance(body, Mapping):
            keys = list(body.keys())
            return {"type":"object","keys":keys[:32],"size":len(keys), "preview":str(mask({k:body[k] for k in list(body)[:10]}))[:max_preview]}
        if isinstance(body, Sequence) and not isinstance(body,(bytes,bytearray,str)):
            return {"type":"array","size":len(body), "preview":str(mask(list(body)[:10]))[:max_preview]}
        if isinstance(body, (str, bytes, bytearray)):
            s = body if isinstance(body,str) else body.decode("utf-8","ignore")
            return {"type":"text","bytes":len(s.encode("utf-8")), "preview":_mask_str(s)[:max_preview]}
    except Exception:
        pass
    return {"type":type(body).__name__,"preview":str(body)[:max_preview]}