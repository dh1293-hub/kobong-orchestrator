# Action DSL v0.3 (Contract)
- **Version**: 0.3 (requests/responses share the same major/minor)
- **Purpose**: GPT-5 ↔ Conductor 간 실행 가능한 표준 명령/결과 포맷
- **Principles**: Contract-first, additive-only(minor), evidence-first(logging/snapshots)

## Actions (op)
LOCATE, FOCUS, PASTE, TYPE, PRESS, CLICK, DOUBLE, DRAG, SCROLL, WAIT, WAIT_FOR, SNAPSHOT, VERIFY, NAVIGATE

### Common fields
- id (string) – 이전 결과 참조용 핸들(선택)
- timeout_ms (0..600000), retry (0..5), assert (bool)

### Pointer
- 문자열 `"@<id>"` (예: `"@loc_chatbox"`) : 이전 액션 결과를 참조

### Role
- conductor | gpt5 | ai1 | ai2  (step 단위 기본 대상)

## Error Codes (subset)
- DSL_PARSE_ERROR, VALIDATION_ERROR, UNSUPPORTED_ACTION
- LOCATE_TIMEOUT, OCR_FAIL, ACTION_FAIL, VERIFY_FAIL
- RETRY_EXHAUSTED, CANCELLED, PERMISSION_DENIED

## Logging (JSON Lines; required fields)
timestamp, level, traceId, module, action, inputHash, outcome, durationMs, errorCode, message

