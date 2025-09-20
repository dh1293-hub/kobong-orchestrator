import json
from jsonschema import validate

def test_ko_v1_schema_valid():
    schema = json.loads(open("server/schemas/ko_v1.json", "r", encoding="utf-8").read())
    msg = {
        "protocol_version": "ko-v1",
        "message_id": "msg-1",
        "idempotency_key": "idem-1",
        "priority": 5,
        "payload": {"op": "noop"}
    }
    validate(instance=msg, schema=schema)
