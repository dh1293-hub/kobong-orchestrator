from __future__ import annotations
import json, os
from collections import defaultdict
from typing import Dict, Tuple, Iterable

METRICS_PATH = os.getenv("KOBONG_METRICS_PATH", os.path.join("logs","metrics.jsonl"))
BUCKETS = [5,10,25,50,100,250,500,1000,2500,5000]

def _load() -> Iterable[dict]:
    if not os.path.exists(METRICS_PATH): return []
    with open(METRICS_PATH, "r", encoding="utf-8") as f:
        for line in f:
            line=line.strip()
            if not line: continue
            try: yield json.loads(line)
            except Exception: continue

def _prom_name(name: str) -> str:
    return name.replace(".","_").replace("-","_")

def _esc(s: str) -> str:
    return s.replace("\\","\\\\").replace("\n","\\n").replace('"','\\"')

def _labels(d: Tuple[Tuple[str,str],...], extra: dict|None=None) -> str:
    lab = {k:v for k,v in d}
    if extra: lab.update(extra)
    if not lab: return ""
    inner = ",".join(f'{_esc(k)}="{_esc(str(v))}"' for k,v in sorted(lab.items()))
    return "{"+inner+"}"

def render_prom() -> str:
    counters: Dict[Tuple[str, Tuple[Tuple[str,str],...]], float] = defaultdict(float)
    hists: Dict[Tuple[str, Tuple[Tuple[str,str],...]], Dict[str,float]] = defaultdict(lambda: {**{f'le_{b}':0.0 for b in BUCKETS}, 'le_inf':0.0, '_sum':0.0, '_count':0.0})

    for r in _load():
        name = r.get("name"); val = float(r.get("value", 1.0)); tags = r.get("tags") or {}
        lt = tuple(sorted((str(k),str(v)) for k,v in tags.items()))
        if name == "http.requests.latency":
            ms = val
            hist = hists[(name, lt)]
            for b in BUCKETS:
                if ms <= b: hist[f'le_{b}'] += 1
            hist['le_inf'] += 1
            hist['_sum'] += ms
            hist['_count'] += 1
        else:
            counters[(name, lt)] += val

    out = []
    # counters
    typed = set()
    for (name, lt), v in counters.items():
        m = _prom_name(name)
        if m not in typed:
            out.append(f"# TYPE {m} counter")
            typed.add(m)
        out.append(f"{m}{_labels(lt)} {int(v) if float(v).is_integer() else v}")

    # histograms
    for (name, lt), h in hists.items():
        m = _prom_name(name)
        out.append(f"# TYPE {m} histogram")
        for b in BUCKETS:
            out.append(f"{m}_bucket{_labels(lt, {'le': str(b)})} {int(h[f'le_{b}'])}")
        out.append(f"{m}_bucket{_labels(lt, {'le': '+Inf'})} {int(h['le_inf'])}")
        out.append(f"{m}_sum{_labels(lt)} {h['_sum']}")
        out.append(f"{m}_count{_labels(lt)} {int(h['_count'])}")

    return ("\n".join(out) + "\n") if out else ""