# KLC SPEC

필수 필드: traceId, exitCode, durationMs, anchorHash, component, message
exitCode: 0,10,11,12,13,1
예시(JSONL):
{"traceId":"demo","exitCode":0,"durationMs":1234,"anchorHash":"<sha>","component":"build","message":"ok"}

집계: 매일 00:00 KST(15:00 UTC) → 성공률/실패Top3/지연Top3/다음액션1 → Summary+Artifact(.gz, 보존7~14d)
