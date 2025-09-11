# Logging (JSON Lines)
fields: timestamp, level, traceId, module, action, inputHash, outcome, durationMs, errorCode, message
level default: INFO
PII: mask/hash; rotate size 20MB x10

