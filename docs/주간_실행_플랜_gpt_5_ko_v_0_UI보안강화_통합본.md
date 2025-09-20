# GPT‑5 × kobong‑orchestrator v0.1 — 1주 완전 자동화 개발 플랜

> 목표: **v0.1(Phase‑0) 범위 100% 달성**. 기간: **7일**(KST). 운영 원칙: *GPT‑5 주도 / KO 보조*, PS7 표준·KLC(로거) 우선, Dry‑Run→Apply, 원자적 쓰기 + 백업.

---

## 0) 범위(Scope) & 완료 기준(DoD)
- **대상 범위(Phase‑0)**: KO 스켈레톤(FASTAPI+WS), Shell Runner, GitHub App 연동, ko‑v1 통신 규약(Chunking 포함), Exec & Git 최소 명령, 기본 관측(로그/헬스), 안전모드(Dry‑Run)·위험 명령 차단 리스트.
- **완료 기준(핵심)**
  1. 샘플 레포에 대해 **코드→PR→CI→머지** E2E Dry‑Run 성공(무인)
  2. KO Exec API p95 < 2s(내부망), 실패 시 3회 지수 백오프
  3. 모든 스크립트 PS7 헤더·UTF‑8 LF·표준 종료 코드 준수
  4. 로그/트레이스 **최소 1건** 보존(KLC 또는 JSONL 폴백)
  5. **원자적 쓰기 + .bak‑<ts> 자동 생성**(특히 `experience.json`)

---

## 1) 주간 일정(일자별 체크리스트)
### Day 1 — 킥오프 & 표준 수립
- 레포 정리: `.gitattributes`(LF), `.editorconfig`, PR 템플릿/Issue 템플릿
- 스크립트 표준화: PS7 헤더, StrictMode, ErrorAction Stop, Dry‑Run 스위치
- **KLC 연동 스캐폴드**: `Write-KobongJsonLog`, `Exit-Kobong` 유틸 배치
- GitHub App 초안(권한 최소) 생성, 시크릿 볼트 자리잡기(로컬 mock)
- 아키텍처 ADR/README 스켈레톤 커밋

### Day 2 — KO 서버 스켈레톤
- FastAPI + WebSocket 서버 골격, `/healthz|/readyz|/livez`
- ko‑v1 메시지 스키마 초안(JSONSchema) & 버전 필드(`protocol_version`)
- **Idempotency‑Key** 및 `priority` 필드 수용(큐 설계)
- 단위테스트: 스키마 검증·헬스체크 응답

### Day 3 — Shell Runner(Windows 우선) & Exec
- 안전 리스트/블록 리스트, 타임아웃/워크디렉토리 고정
- Dry‑Run 강제 플래그, 표준 로그(성공/실패) 캡처
- **PS7 래퍼** 제공(명령 → pwsh), JSON 결과 스키마 정의
- 계약(Contract) 테스트: 정상/예외/취소/타임아웃 케이스

### Day 4 — GitHub 연동 & 합성 워크로드
- PR 열기/수정/라벨/체크 대기, 상태 갱신 웹훅(or 폴링)
- 합성 워크로드: README 한 줄 변경 → PR → 체크 통과 시 자동 스쿼시 머지
- **Chunking(200KB)** & 재전송 복원(누락 청크 재요청) 구현

### Day 5 — 관측/로그 & 경험 저장소 하드닝
- KLC 우선 로그 + JSONL 폴백, `traceId/corr_id` 연결
- **`experience.json` 원자쓰기+백업** 모듈 적용(임시→교체 + `.bak-<ts>`)
- 헬스 대시보드(요약 JSON), 합성 PR 크론(10분)

### Day 6 — 보안·승인 게이트(최소구성)
- 위험 명령 차단 리스트 가드 + 수동 승인 토글(2버튼 UI stub)
- 시크릿 어댑터(mock) + 접근 로깅, 관리자 Step‑up 설계 반영(스텁)
- E2E 연습: 실패/롤백/재시도 플로우 검증

### Day 7 — E2E 리허설 & 릴리즈
- 전체 시나리오 무인 실행 리허설(≥2회), 플래키 제거
- 릴리즈 태깅 `v0.1.0`, CHANGELOG 생성, 운영 문서/런북 정리
- 레트로: 리스크/백로그 정리, Phase‑1 선행 과제 도출

---

## 2) 기능 구현 계획(Workstreams → Tasks → AC)
### A. KO 서버(WS/HTTP)
- Tasks: FastAPI 앱, WS 핸들러, ko‑v1 스키마, 헬스엔드포인트
- AC: 스키마 검증 통과, WS 에코/청크 수신·조립 OK, p95 < 2s

### B. Shell Runner
- Tasks: 명령 스펙(JSON), PS7 래퍼, 안전/블록 리스트, 타임아웃/취소, Dry‑Run
- AC: 정상/에러/타임아웃/취소 4종 계약테스트 통과, 로그 남김

### C. GitHub App/Client
- Tasks: PR/체크 API, 상태 감시, 스쿼시 머지, 보호브랜치 규칙 연동
- AC: 합성 워크로드 PR이 자동 머지, 롤백 스크립트 준비

### D. Observability
- Tasks: KLC 통합, JSONL 폴백, trace/corr_id 연결, 합성 체크 크론
- AC: 모든 액션 최소 1로그, 대시보드 요약 JSON 노출

### E. State & Experience(학습/XP)
- Tasks: `experience.json` **원자적 쓰기 + `.bak-<ts>` 백업**, 불변 스키마, CLI와 연동
- AC: 동시 쓰기 내성, 백업/복구 시뮬레이션 패스

### F. 보안/승인
- Tasks: 위험 명령 차단, 승인 스텁(UI or CLI), 시크릿 접근 로깅
- AC: 차단 규칙 작동, 승인 없이는 위험 명령 미실행

---

## 3) 전(前) 프로젝트 변경/이관 계획(핵심 차이 반영)
- **PS7 강제 & 헤더 표준화**: 모든 스크립트 상단 헤더·StrictMode·UTF‑8 LF 반영, WinPS 호출 제거
- **KLC 우선 로깅**: 기존 산발적 로그 → KLC 표준 + JSONL 폴백으로 일원화
- **표준 종료 코드**: PRECONDITION/CONFLICT/TRANSIENT/LOGIC 적용, 호출부 연쇄 수정
- **원자적 파일 쓰기 규약**: 임시파일→교체 + `.bak-<ts>` 백업(특히 `experience.json`)
- **Dangerous 명령 블록**: 와일드카드 삭제 금지, 경로 샌드박스(RepoRoot 내)
- **GitHub 워크플로 정리**: 보호 브랜치/필수 체크, 스모크/합성 PR 잡 추가

---

## 4) 최종 우선순위(백로그 Top‑10)
1) Shell Runner(PS7) + 안전 가드
2) KO 서버/스키마(ko‑v1) + 헬스
3) GitHub App 연동(합성 PR 자동 머지)
4) Chunking + Idempotency 키
5) KLC 통합 + JSONL 폴백
6) `experience.json` 원자쓰기/백업 하드닝
7) 위험 명령 차단 리스트 + 승인 스텁
8) 합성 체크 크론 + 대시보드 요약 JSON
9) 릴리즈/CHANGELOG 자동화
10) 문서/런북/ADR 정리

---

## 5) 리스크 & 대응
- GitHub API 레이트리밋 → 큐잉+지수 백오프, 합성 잡 간격 조정
- Windows 경로/인코딩 이슈 → PS7 표준·UTF‑8 강제·경로 API 사용
- 파일 동시 쓰기 경쟁 → 락 파일 & 원자 교체, 실패 시 백업 복원
- 자동 머지 오작동 → Dry‑Run 게이트 + 보호브랜치 규칙 + 롤백 스크립트

---

## 6) 산출물(Artifacts)
- 서버: `app/ko_server`(FastAPI/WS)
- 러너: `runner/shell_runner`
- 클라이언트: `clients/github`
- 계약/스키마: `contracts/ko-v1/*.json`
- 스크립트: `scripts/g5/*.ps1`(PS7 표준)
- 문서: `docs/ADR`, `docs/runbook`, `README`(운영·보안·릴리즈)

---

## 7) 체크리스트(릴리즈 전)
- [ ] E2E 합성 시나리오 2회 연속 성공
- [ ] PR/머지/롤백 버튼 동작
- [ ] 로그·헬스·대시보드 확인
- [ ] 위험 명령 차단·승인 가드 확인
- [ ] `experience.json` 백업/복구 리허설 패스

---

## 8) GPT‑5 보충 의견(Addenda)
- ko‑v1 스키마에 `capabilities[]`, `sensitivity`, `idempotency_key`, `priority` 필드 **초기에 포함**(향후 확장 비용 절감)
- 관측은 **OTel 친화적 네이밍**으로 시작해 Phase‑1에 Grafana로 승격 용이화
- 합성 워크로드는 **README 변조** 외에 **라벨 토글**·**코멘트 트리거**도 포함해 경로 다양화
- `experience.json`은 향후 **SQLite**로 이관 준비(마이그레이션 스크립트 초안 동시 제공)
---

# 보안·UI 통합 강화 변경 요약 (v0.1 유지, Phase‑0 범위 내)
- **CLI(PS7) 우선** 운용 원칙을 문서에 명시하고, 모든 스크립트는 PS7 헤더·StrictMode·UTF‑8 LF·표준 종료코드 사용을 완료 기준(DoD)에 추가.
- **TUI**는 로그/큐/잡 모니터링과 **저위험 조작(취소/재시도)** 로 한정. 기본 읽기전용, 조작 시 Step‑up 인증 요구(관리자 비밀번호/패스키). 시크릿/PII 미표시.
- **Web GUI**는 **관측·승인·설정** 전용. 2‑버튼 승인 큐(다음 단계/중단) 제공, 인증은 **SSO/OIDC + WebAuthn(패스키)** 를 목표 구성으로 설정(Phase‑0은 스텁/모의). 감사 이벤트는 WORM 성격의 JSONL로 보관.
- 전 구간 **KLC 표준 로그** 우선, 미존재/오류 시 JSONL 폴백. 모든 액션은 최소 1건의 이벤트를 남김.
- 파일 쓰기는 **원자적 교체 + `.bak-<ts>` 백업**을 기본 규약으로 고정(특히 `experience.json`).

# 주간 일정(보안/UI 관점 보강)
## Day 1 — 킥오프 & 표준 수립 (보안 기초 포함)
- PS7 표준 헤더/StrictMode/UTF‑8 LF 보강, `.gitattributes`/`.editorconfig` 반영.
- **KLC 로깅 스캐폴드** 배치(Write‑KobongJsonLog, Exit‑Kobong), JSONL 폴백 확인.
- **UI 정책 선언**: CLI(핵심 오퍼레이션) / TUI(관찰·저위험) / Web GUI(관측·승인·설정).
- GitHub App 최소 권한 초안 + 시크릿 볼트 자리잡기(mock) — 토큰 하드코딩 금지.

수용 기준(추가):  
- 모든 .ps1에 PS7 헤더 존재, 샘플 실행 시 KLC 또는 JSONL에 1건 이상 기록.

## Day 2 — KO 서버 스켈레톤 (관측 훅 삽입)
- `/healthz|/readyz|/livez` 반환에 **traceId/corr_id** 포함, JSON 로그 스키마 초안 적용.
- ko‑v1 스키마에 `idempotency_key`, `priority`, `sensitivity` 필드 예약(스텁).

수용 기준(추가):  
- 헬스 엔드포인트 호출 시 로그 1건 기록(KLC/JSONL).

## Day 3 — Shell Runner & Exec (안전 가드 강화)
- 위험 명령 **블록 리스트**와 **RepoRoot 샌드박스** 강제. Dry‑Run 플래그 기본 ON.
- 결과 스키마에 `exit_code`, `duration_ms`, `bytes` 포함. 실패 시 3회 지수 백오프.

수용 기준(추가):  
- 정상/에러/타임아웃/취소 4종 계약 테스트와 함께 **로그·백업·원자쓰기** 검증.

## Day 4 — GitHub 연동 & 합성 워크로드 (승인 경로 연결)
- PR 오픈 → 체크 → **승인 큐 스텁**(Web GUI or TUI에서 2‑버튼) → 스쿼시 머지.
- 누락 청크 재요청(Chunking 200KB) 및 재전송 시 **Idempotency** 보장.

수용 기준(추가):  
- 합성 PR 흐름에서 각 단계 로그가 traceId로 **단일 타임라인**으로 연결.

## Day 5 — 관측/로그 & 경험 저장소 하드닝 (WORM 지향)
- KLC + JSONL 폴백 이중화, 감사 성격의 이벤트는 **삭제 불가 정책**으로 운용.
- `experience.json` 쓰기는 임시파일→교체 + `.bak-<ts>` 백업. 복구 시나리오 리허설.

수용 기준(추가):  
- 백업 파일 생성 확인, 복구 리허설 패스(문서화).

## Day 6 — 보안·승인 게이트 (최소구성 → 스텁)
- **SSO/OIDC + WebAuthn** 목표 구성 문서화(Phase‑0은 스텁 구현 및 모의 흐름).
- **Step‑up 인증**(권한 상승) 및 **4‑eyes 승인** 정책 정의(실제 체크는 Phase‑1).

수용 기준(추가):  
- 승인 큐 스텁에서 ‘승인/중단’ 이벤트가 로그로 기록되고, 위험 작업은 승인 없이는 차단.

## Day 7 — E2E 리허설 & 릴리즈 (보안 체크 포함)
- 전 경로 **드라이런/E2E 2회** 연속 성공 + 플래키 제거.
- 보안 체크리스트 점검: 시크릿 하드코딩 0, 로그 마스킹 ON, 원자쓰기/백업 준수.

# 완료 기준(DoD) 보강 항목
- [보안] 시크릿은 Vault/KMS 주입만 허용, 코드/레포 내 하드코딩 금지.
- [로그] **최소 1건** 이벤트 보장(KLC 우선, JSONL 폴백). traceId/corr_id 연계.
- [파일] 원자쓰기 + `.bak-<ts>` 백업. 복구 절차 문서화.
- [UI] CLI/TUI/Web 역할 분리 및 승인 큐 스텁 동작(2‑버튼).

# 산출물(Artifacts) 추가
- `docs/UI_POLICY.md` — CLI/TUI/Web 원칙·권한·승인 정책 요약(Phase‑0 스텁 범위).
- `contracts/ko-v1/*.json` — `idempotency_key`,`priority`,`sensitivity` 필드 포함 스키마 초안.
- `scripts/lib/kobong-logging.psm1` — KLC 연동 + JSONL 폴백 유틸.
---
## [부록-추가] 모니터링 2원화(Web GUI) 설계 · 반영안  (2025-09-19)
본 문서는 기존 본문을 **유지**하면서, 모니터링을 두 축으로 분리하여 Web GUI 기준으로 재구성/추가한 개정안입니다.  
축 A와 축 B는 서로 독립 배포 가능하지만, 공통 토대(OTel/권한/마스킹/알림 라우팅)를 공유합니다.

### A. 상호작용 모니터링 (Kobong-Orchestrator × GPT-5 × GitHub)
- **목표**: 오케스트레이터가 GPT-5 및 GitHub와 **주고받는 ‘내용’과 메타데이터**를 안전하게 관측.
- **핵심 원칙**: 기본 **민감정보 자동 마스킹**(PII/시크릿/토큰), **목적 제한**, **최소보존**.
- **이벤트 타입**: content.request/content.response(요약·토큰·latency, *본문은 정책 기반 부분 마스킹*), 	ool.use, policy.decision, etry.backoff
- **KPI**: p50/p90/p99 지연, 성공률, 재시도율, 토큰 사용량(입/출), 정책 차단율, 자동진행 비율, 알람 소음지수
- **보존**: 원문 24~72h(마스킹/난독화), 요약·지표 30일, 감사로그 요약본 1년(WORM)

### B. GitHub 전면 모니터링 (Org/Repo/Runner/Actions/보안)
- **범위**: PR/Issue/Actions/러너 상태/웹훅/레이트리밋/Dependabot/Code Scanning/DORA
- **핵심 지표**: PR 대기·리드타임·머지성공률, Actions 통과율/실패 Top-N, flaky 지수, 레이트리밋, 브랜치 보호 위반, 시크릿 유출, 롤백/배포 빈도

### Web GUI 정보구조
- **탭 2개**: Interaction(상호작용) / GitHub(조직 전체)
- **공통 상단 리본**: 오늘 처리량·실패수·평균 리드타임·에러 재발률·최근 배포
- **화면**: (1) Interaction 홈(대화 타임라인·지연/토큰 추세·정책 차단·재시도/백오프), (2) GitHub 홈(PR·Actions·러너·레이트리밋·DORA), (3) Incident 뷰(알림·런북·최근 변경·릴리즈 히트맵)
- **권한**: RBAC(Reader/Operator/Admin), PII 게이트(승인 사용자만 원문 미리보기), 감사추적

### 수집/스키마(요약)
- **OTel 기반** Traces/Metrics/Logs 통합. 공통 라벨: nv, service, route, actor, repo, org, fingerprint
- **메시지 스키마(요약)**:
{"exchange_id":"uuid","when":"2025-09-19T12:34:56Z","role":"user|assistant|system","channel":"orchestrator|github|gpt","masked":true,"hash":"sha256:...","size_tokens":{"in":123,"out":456},"latency_ms":812,"policy":{"decision":"allow","rules":["PII-mask"]}}

### 대시보드·지표(요지)
- Interaction: gpt5_request_latency_seconds, gpt5_token_usage_total{type}, gpt5_error_total{code}
- GitHub: github_pr_open_total, github_merge_lead_time_seconds, ci_pass_rate, laky_test_index
- KO 실행: ko_exec_duration_seconds, ko_queue_depth, ko_exec_success_total, ko_busy_state
- ErrorKB: kb_new_fingerprint_total, kb_recurrence_total, kb_verified_ratio

### 알림 규칙(샘플)
- gpt5_error_total{code=~"5.."} > 5 (5m) → P2, ko_busy_state == 1 for 10m → P2
- github_merge_lead_time_seconds_p95 > 14400 → P3, 동일 fingerprint 24h 재발 → P2

### 구현 로드맵
1) OTel 계측 삽입 → 2) 수집 파이프·마스킹 룰 → 3) GUI 탭 2종 → 4) 합성 체크 → 5) 알림 라우팅/런북 → 6) SLO 대시보드

### 수용 기준(AC)
- 탭별 TTFD < 2s, 24h 쿼리 p95 < 3s, PII 미마스킹 0건, 경고→런북 링크 100%
---
