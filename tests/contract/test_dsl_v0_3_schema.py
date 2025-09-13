import json
from pathlib import Path
from jsonschema import validate, Draft202012Validator
import pytest

ROOT = Path(__file__).resolve().parents[2]
REQ_SCHEMA = json.loads((ROOT / "domain" / "dsl" / "v0_3" / "schema" / "request.schema.json").read_text(encoding="utf-8-sig"))
RES_SCHEMA = json.loads((ROOT / "domain" / "dsl" / "v0_3" / "schema" / "response.schema.json").read_text(encoding="utf-8-sig"))

def _is_valid(schema: dict, data: dict) -> tuple[bool, list[str]]:
    v = Draft202012Validator(schema)
    errors = sorted(v.iter_errors(data), key=lambda e: e.path)
    return (len(errors) == 0, [f"{'/'.join(map(str, e.path))}: {e.message}" for e in errors])

def test_request_schema_ok():
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
                {"op": "WAIT", "ms": 1200},
                {"op": "SNAPSHOT", "label": "ai1_after_send"}
            ]
        }]
    }
    ok, errs = _is_valid(REQ_SCHEMA, plan)
    assert ok, f"Schema validation failed: {errs}"

def test_request_schema_bad_missing_version():
    bad = { "plan_id": "no-version", "steps": [{"step": 1, "actions": [{"op": "WAIT", "ms": 10}]}] }
    ok, errs = _is_valid(REQ_SCHEMA, bad)
    assert not ok and any("version" in e for e in errs)

def test_response_schema_ok():
    res = {
        "version":"0.3","plan_id":"demo-001","outcome":"ok",
        "steps":[{"step":10,"status":"ok","duration_ms":2000,
                  "actions":[{"op":"LOCATE","id":"loc_chatbox","status":"ok","duration_ms":300,"evidence":{"locate":{"strategy":"text","score":0.93}}},
                             {"op":"FOCUS","status":"ok"},
                             {"op":"PASTE","status":"ok"},
                             {"op":"VERIFY","status":"ok"},
                             {"op":"PRESS","status":"ok"},
                             {"op":"WAIT","status":"ok"},
                             {"op":"SNAPSHOT","status":"ok","evidence":{"snapshots":["ai1_after_send.png"]}}]}]
    }
    ok, errs = _is_valid(RES_SCHEMA, res)
    assert ok, f"Schema validation failed: {errs}"

def test_response_schema_bad_status():
    bad = {"version":"0.3","plan_id":"x","outcome":"ok","steps":[{"step":1,"status":"UNKNOWN","actions":[]}]}
    ok, errs = _is_valid(RES_SCHEMA, bad)
    assert not ok


