import json
from jsonschema import Draft202012Validator

def test_log_record_matches_schema():
    from infra.logging.json_logger import JsonLogger
    jl = JsonLogger(env="dev")
    rec = jl.log(level="INFO", module="unit", action_step=1,
                 message="hello alice@example.com with api_key: XYZ1234567890",
                 result_status="ok", result_code=0)

    with open("domain/contracts/logging/v1.schema.json","r",encoding="utf-8-sig") as f:
        schema = json.load(f)
    Draft202012Validator(schema).validate(rec)

    s = json.dumps(rec, ensure_ascii=False)
    assert "alice@example.com" not in s
    assert "XYZ1234567890" not in s
    assert "[MASKED_EMAIL]" in s
    assert "[MASKED_TOKEN]" in s

def test_required_fields_present():
    from infra.logging.json_logger import JsonLogger
    rec = JsonLogger().log(message="minimal")
    for k in ["timestamp","tz","level","app","env","host","pid","thread",
              "trace_id","action","result","latency_ms","message"]:
        assert k in rec
