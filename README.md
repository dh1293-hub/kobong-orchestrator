# kobong-orchestrator
- 목표: GPT-5 주도, KO 보조 — v0.1 범위(1주) 자동화
- Day-1: 표준 파일, KLC 로깅 모듈, 템플릿, ADR 초안

## Local Dev (Kobong Server)

- **Start**: Desktop → *Start Kobong Server* (or `scripts/server/run-dev.ps1 -Detach -Reload -Port 8080 -BindAddress 127.0.0.1`)
- **Stop** : Desktop → *Stop Kobong Server* (or `scripts/server/stop-dev.ps1 -Port 8080`)
- **Docs** : http://127.0.0.1:8080/docs
- **Health**: http://127.0.0.1:8080/health → returns `{ status, ts, version, sha }`

> `/health` exposes `version` and `sha`. You can override via env:
> `KOBONG_VERSION`, `KOBONG_COMMIT`.