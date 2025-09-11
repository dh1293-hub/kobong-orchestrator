import json
from pathlib import Path
from jsonschema import Draft202012Validator
from app.orchestrator import ActionOrchestrator, Ports
from domain.ports import Point

ROOT = Path(__file__).resolve().parents[2]
REQ_SCHEMA = json.loads((ROOT / "domain" / "dsl" / "v0_3" / "schema" / "request.schema.json").read_text(encoding="utf-8-sig"))
RES_SCHEMA = json.loads((ROOT / "domain" / "dsl" / "v0_3" / "schema" / "response.schema.json").read_text(encoding="utf-8-sig"))

# --- Fakes ---
class LocatorFake:
    def locate(self, by, query=None, area=None, score_threshold=None, template_id=None):
        return Point(100, 200), {"strategy": by, "score": 0.93}

class UiFake:
    def __init__(self): self.calls = []
    def focus(self, target): self.calls.append(("focus", target))
    def click(self, target, button="left", offset=None): self.calls.append(("click", target, button, offset))
    def double(self, target): self.calls.append(("double", target))
    def drag(self, start, end): self.calls.append(("drag", start, end))
    def scroll(self, amount, axis="vertical"): self.calls.append(("scroll", amount, axis))
    def type_text(self, text): self.calls.append(("type", text))
    def paste(self, text, clear=False): self.calls.append(("paste", text, clear))
    def press(self, keys): self.calls.append(("press", keys))
    def navigate(self, url): self.calls.append(("nav", url))

class OcrFake:
    def read(self, region=None): return "Welcome. Hello from Conductor!"

class SnapshotFake:
    def capture(self, label=None): return f"{(label or 'shot')}.png"

class ClockFake:
    def sleep_ms(self, ms): pass

def _is_valid(schema: dict, data: dict) -> tuple[bool, list[str]]:
    v = Draft202012Validator(schema)
    errs = sorted(v.iter_errors(data), key=lambda e: e.path)
    return (len(errs) == 0, [f"{'/'.join(map(str, e.path))}: {e.message}" for e in errs])

def test_smoke_happy_path():
    plan = {
        "version": "0.3",
        "plan_id": "demo-001",
        "steps": [{
            "step": 10,
            "explain": "AI1 채팅창에 프롬프트 붙여넣고 전송",
            "role": "ai1",
            "actions": [
                {"op": "LOCATE", "id": "loc_chatbox", "by": "text", "query": ["채팅 입력","Send a message"], "timeout_ms": 5000},
                {"op": "FOCUS", "target": "@loc_chatbox"},
                {"op": "PASTE", "text": "Hello from Conductor"},
                {"op": "VERIFY", "ocr_contains": "Hello from Conductor", "timeout_ms": 1500},
                {"op": "PRESS", "keys": "Enter"},
                {"op": "WAIT", "ms": 100},
                {"op": "SNAPSHOT", "label": "ai1_after_send"}
            ]
        }]
    }
    ok, errs = _is_valid(REQ_SCHEMA, plan)
    assert ok, f"request schema invalid: {errs}"

    ports = Ports(locator=LocatorFake(), ui=UiFake(), ocr=OcrFake(), snapshot=SnapshotFake(), clock=ClockFake())
    orch = ActionOrchestrator(ports)
    res = orch.run(plan)

    ok, errs = _is_valid(RES_SCHEMA, res)
    assert ok, f"response schema invalid: {errs}"
    assert res["outcome"] == "ok"
    assert res["steps"][0]["actions"][0]["op"] == "LOCATE"
