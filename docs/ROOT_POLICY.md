# ROOT POLICY v1

## 디렉터리 구조(루트)
- docs/                 ← 문서(위키 대신)
- .github/workflows/    ← 워크플로 3종(protect, build-test, klc-nightly)
- scripts/g5/           ← 운영 스크립트(PS7 전용)
- _deprecated/          ← 퇴역/백업(자동 이동)
- logs/                 ← KLC 로컬 로그(옵션)
- .kobong/              ← 드라이버/보안/설정(옵션)

## 규칙
- 1 PR 1 목적 + Draft + 친절한 주석(한국어)
- 파일명: kebab-case, 스크립트는 PascalCase.ps1, 워크플로는 kebab.yml
- git 대신 zip-fetch 가능(환경 차/exit 128 회피)
- PS7-first, DRYRUN→APPLY, URS 롤백 스위치(배포)
- KLC 표준 로그 필수 필드: traceId, exitCode, durationMs, anchorHash, component, message
