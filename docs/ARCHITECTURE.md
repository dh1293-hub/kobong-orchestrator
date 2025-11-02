# ARCHITECTURE (Unified)

- Orchestrator: 실행 허브 (/health, DRYRUN→APPLY, URS 롤백)
- AUTO-Kobong: 스케줄/운영(야간 집계)
- KLC: 표준 로그(JSONL) 수집/검증/집계(모니터링=야간 요약 1장)
- GitHub App(선택 연결): GPT-5가 읽기/검색/PR 제안(Draft 1개 원칙)

흐름:
요구(이슈) → GPT-5 설계/패치 → Draft PR → Protect/Build-Test →
승인 → Orchestrator 배포 → KLC 로그 → Nightly 요약 → 핫픽스 제안
