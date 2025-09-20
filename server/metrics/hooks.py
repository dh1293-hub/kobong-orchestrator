from __future__ import annotations
import json, os, time
from typing import Mapping

_METRICS = os.getenv("KOBONG_METRICS_PATH", os.path.join("logs","metrics.jsonl"))

def _parse_default_labels() -> dict:
    # 우선순위: KOBONG_METRIC_LABELS (csv "k=v,k=v") + KOBONG_ENV + KOBONG_SERVICE
    defaults = {}
    raw = os.getenv("KOBONG_METRIC_LABELS", "")
    for part in (p.strip() for p in raw.split(",") if p.strip()):
        if "=" in part:
            k,v = part.split("=",1)
            defaults[k.strip()] = v.strip()
    if "env" not in defaults and os.getenv("KOBONG_ENV"):
        defaults["env"] = os.getenv("KOBONG_ENV")  # e.g. dev/stage/prod
    if "service" not in defaults and os.getenv("KOBONG_SERVICE"):
        defaults["service"] = os.getenv("KOBONG_SERVICE")
    return defaults

_DEFAULTS = _parse_default_labels()

def _merge_tags(tags: Mapping[str,str]|None) -> dict:
    t = dict(_DEFAULTS)
    if tags:
        t.update({k:str(v) for k,v in tags.items()})
    return t

def emit(name: str, value: float=1.0, tags: Mapping[str,str]|None=None) -> None:
    rec = {"ts": time.time(), "name": name, "value": value, "tags": _merge_tags(tags)}
    _write_line(_METRICS, rec)

def timing(name: str, ms: float, tags: Mapping[str,str]|None=None) -> None:
    emit(name, ms, {"unit":"ms", **(tags or {})})

def _write_line(path: str, obj: dict) -> None:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "a", encoding="utf-8") as f:
        f.write(json.dumps(obj, ensure_ascii=False)+"\n")