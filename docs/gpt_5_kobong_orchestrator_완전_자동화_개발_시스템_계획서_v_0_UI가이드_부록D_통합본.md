# GPT-5 × kobong-orchestrator 완전 자동화 개발 시스템 계획서 (v0.1)

- **작성일**: 2025-09-18 (KST)
- **작성자**: 한민수(@dh1293) / 기획 보조
- **프로젝트 주도자(에이전트)**: GPT-5
- **보조 오케스트레이터**: kobong-orchestrator (이하 **KO**)
- **GitHub ID**: `dh1293-hub`

---

## 1) 목표와 성공 기준
**목표**: GPT-5가 주도권을 가지고 KO를 보조로 활용하여, 계획 수립 → 코딩 → 실행/테스트 → 오류 수습 → 학습 저장까지 **완전 자동화**.

**핵심 성공 지표(KPI)**
- 신규 프로젝트 부팅 시간: 10분 이내 (Kickoff Prompt 1회로 환경/레포 자동 구성)
- 기능 작업 하나(이슈) 처리 사이클: 기획→PR→머지까지 무인(Zero-touch) 성공률 80% 이상
- 오류 재발 방지율: 동일 오류 재발 비율 50%↓ (에러 지식베이스 반영 후)
- 작업 가시성: 커밋/PR/릴리즈 노트 자동화 100%

---

## 2) 역할 정의
### GPT-5 (주도)
- 전체 계획 수립, 세부 설계, 코드 생성, 리팩터링, 테스트 케이스 제안
- KO에 대한 **교수(Teaching) 스크립트** 제공 및 능동 피드백
- GitHub/셸/파일 I/O/문서화/릴리즈까지의 **행동 플로우 결정**

### KO (보조)
- GitHub, 로컬/원격 Shell, 파일 시스템, 비즈니스 규칙, 정책 집행
- **에러 집계/요약/분석**, **경험 저장소(리트로스펙티브 메모리)** 관리
- **프로젝트 스캐너**로 구조/상태 파악, **요약 패킷**을 GPT-5에 공급
- **대화 프로토콜** 관리(Chunking, Viewport/Scroll, Rate-limit 대응)

### 사람(한민수)
- 단일 진행자, 승인/거절 버튼만으로 운영(코딩 지식 불필요)
- 고위험 작업(프로덕션 배포 등) 최종 승인

---

## 3) 시스템 아키텍처 개요
- **Agent Layer**: GPT-5
- **Orchestration Layer**: KO (Python + FastAPI/WebSocket 권장)
- **Execution Layer**: Shell Runner, GitHub App, Repo FS, Test Runner
- **Knowledge Layer**: Error KB + Run Log + Project Index (SQLite/Postgres)
- **Observability**: 이벤트 로그, 트레이스, 메트릭, 아티팩트 보관

```
[User]─(승인 UI)───┐
                   │
               [GPT-5] ⇄ (LLM 프로토콜) ⇄ [KO]
                                      │
         ┌──────────────┬──────────────┴──────────────┐
         │              │                             │
   [GitHub App]   [Shell Runner]                [Scanner/Index]
         │              │                             │
      Repos         Build/Test                    Error KB
```

---

## 4) GPT-5 ⇄ KO 통신 규약 (이미지 제외)
### 4.1 메시지 공통 헤더
```json
{
  "protocol": "ko-v1",
  "tz": "Asia/Seoul",
  "project": "<project_name>",
  "actor": "gpt5 | ko",
  "intent": "plan|code|exec|review|teach|error|scan|git",
  "msg_id": "uuid",
  "corr_id": "uuid-of-conversation",
  "ts": "YYYY-MM-DDTHH:mm:ss+09:00",
  "sensitivity": "low|high"
}
```

### 4.2 대용량/장문 Chunking
- **헤더 필드**: `chunk_idx`, `chunk_total`, `content_sha256`
- **규칙**: 200KB 단위로 분할, KO가 누락 청크 재요청. GPT-5는 전송 완료 후 `complete:true` 신호.

```json
{
  "chunk_idx": 1,
  "chunk_total": 5,
  "content_sha256": "..."
}
```

### 4.3 오류 전달 패킷 (에러 컨텍스트 정리)
```json
{
  "intent": "error",
  "runtime": {
    "cmd": "pytest -q",
    "exit_code": 1,
    "duration_ms": 15234
  },
  "error": {
    "type": "AssertionError",
    "message": "expected 200 got 500",
    "fingerprint": "<hash by stack+msg+file:line>",
    "stack": [
      {"file": "app/api.py", "line": 42, "frame": "..."}
    ]
  },
  "code_context": {
    "files": [
      {"path": "app/api.py", "start": 20, "end": 60}
    ]
  },
  "repro_steps": [
    "poetry run pytest tests/test_api.py::test_ok"
  ]
}
```

### 4.4 “화면 인식”과 스크롤 제어 추상화 (가상 Viewport)
실제 UI 스크래핑 대신, KO가 **가상 화면 모델**을 유지하고 GPT-5에 상태 전달.

```json
{
  "intent": "observe",
  "viewport": {
    "panes": [
      {"id": "log", "type": "text", "content_hash": "...", "scroll": {"offset": 1200, "max": 8400}},
      {"id": "diff", "type": "code", "content_hash": "...", "scroll": {"offset": 0, "max": 2100}}
    ]
  }
}
```
- GPT-5 명령 예: `{"intent":"scroll","target":"log","delta":+800}`
- KO는 오프셋을 적용하고 새 **요약 슬롯(Top-K 요약/키워드/에러 강조)**와 함께 업데이트 전달.

---

## 5) 신규 프로젝트 부팅 절차
### 5.1 Kickoff Prompt(지침) — KO→GPT-5 자동 제출 템플릿
```
[System Charter]
- 역할: 당신은 주도 에이전트(GPT-5)로서 설계/코딩/리뷰/릴리즈를 자동화합니다.
- 보조: kobong-orchestrator(KO)를 Shell/GitHub/스캐너/보안 정책 집행에 활용하세요.
- 시간대: Asia/Seoul, 모든 로그/타임스탬프 KST.
- GitHub ID: dh1293-hub (기본 private repo, GitHub App 권장).
- 파일 경로: 항상 절대경로 또는 repo 루트 기준 명시.
- 셸 정책: 아래 ShellCommandSpec v1 준수.
- 커밋/PR 규칙: 아래 Git 규칙 준수.
- 보안/비밀값: KO 시크릿 볼트에서만 접근, 코드에 하드코딩 금지.
- 출력 형식: 계획→할일목록→명령/코드→검증 방법 순서로 구조화.

[Project Context]
- 문제/요구사항 요약: <KO 스캐너 요약 자동 삽입>
- 기존 코드/디렉토리 구조: <요약>
- 우선순위/리스크: <요약>

[Deliverables]
- 초기 설계안, 작업 분할(issues), 브랜치 전략, 테스트 전략, MVP 목표/검증.
```

### 5.2 KO의 자동 작업
1) Repo 생성 → 브랜치 규칙/PR 템플릿/CODEOWNERS(한민수)
2) 이슈/프로젝트 보드 생성(Backlog/Doing/Review/Done)
3) CI 기본 파이프라인(yaml) 커밋: Lint/Test/SBOM
4) 보호 브랜치(main) + 필수 체크(테스트 통과)
5) 시크릿 초기화: 토큰/서명키/TOTP 시드(볼트)

---

## 6) 코드 헤더/메타데이터 표준
언어 무관 주석 헤더(작성/수정 자동 삽입).
```
# ------------------------------------------------------------
# Module: <파일명>
# Purpose: <이 파일의 목적>
# Author: GPT-5 (operator: han minsu)
# Version: v<semver>
# Created: 2025-09-18 14:07:12 KST
# Updated: 2025-09-18 14:07:12 KST
# Repo: github.com/dh1293-hub/<repo>
# Path: /<repo>/<full/path>
# Dependencies: <주요 의존성>
# Notes: <특이사항>
# ------------------------------------------------------------
```
- 커밋 메시지: `feat(scope): 내용` / `fix(scope): 내용` / `docs:` / `chore:`
- PR 본문 자동 생성: 변경요약, 테스트 결과, 리스크, 롤백 방법

---

## 7) ShellCommandSpec v1 (코딩 효율/안전 규정)
- **해석기**: bash/sh (Linux), PowerShell(Windows 필요 시)
- **기본 옵션**: `set -euo pipefail` / `IFS=$'\n\t'`
- **실행 디렉토리**: repo 루트 고정. `workdir` 필수 명시
- **타임아웃**: 기본 300s, 상향 필요 시 명시
- **출력 포맷**: KO가 stdout/err를 캡처해 **로그+요약** 제공
- **위험 명령 방지 리스트**: `rm -rf /`, 무차별 chown/chmod, 네트워크 광범위 스캔 등
- **Dry-Run 지원**: `--dry-run` 플래그 우선(가능 명령에 한함)
- **재현 가능성**: 환경 변수/버전 고정(`.tool-versions`/`poetry.lock` 등)

명령 요청 JSON 예시:
```json
{
  "intent": "exec",
  "workdir": "/workspace/repo",
  "cmd": ["poetry", "run", "pytest", "-q"],
  "timeout_sec": 600,
  "dry_run": false
}
```

---

## 8) 오류 처리 & 학습 저장소
- **수집**: Exit code, stack, 로그 슬라이스, 주변 코드, 재현 명령
- **정규화**: 에러 유형/모듈/버전/환경으로 태깅, **fingerprint** 생성
- **지식화**: 원인→조치→검증을 카드화. 재발 시 우선 제안
- **피드백 루프**: GPT-5가 **교수 스크립트**로 KO 동작 개선(리트로 메모)
- **저장소**: Error KB (RDB), 내용 검색(키워드/벡터)

카드 스키마:
```json
{
  "fingerprint": "...",
  "cause": "...",
  "fix": "patch or command",
  "tests": ["..."],
  "verified_at": "...",
  "notes": "..."
}
```

---

## 9) GitHub 자동 제어 전략 (GPT-5 & KO)
- **GitHub App** 기반 권장(조직/레포 범위 최소 권한), 불가 시 PAT
- **브랜치 전략**: `main` 보호, `feat/*`, `fix/*`, `chore/*`
- **자동화**: 이슈 생성/연결, PR 오픈/수정/머지, 릴리즈 태깅
- **리뷰 정책**: 테스트 통과 + KO 정적 분석 경고 0건이면 자동 승인(옵션)
- **코드 오너**: 한민수(최종 승인자), 필요시 GPT-5 가상 오너 태그
- **KO도 동일 권한**: KO가 독립적으로 PR 복구/롤백, 긴급 패치 가능

---

## 10) 보안 설계 (로그인/최고관리자/정책)
- **로그인**: 일반 로그인(이메일/패스워드 + 2FA 권장)
- **최고 관리자**: 추가 **보안 코드**(사전 등재된 1회성 시드 또는 하드웨어 키)
- **시크릿 관리**: Vault/KMS에 저장, 작업 시 임시 토큰 발급(최소 권한)
- **감사 로그**: 모든 위험 명령/시크릿 접근 기록(불변 저장)
- **의존성 보안**: SCA/SBOM 주기적 생성, 취약점 임계치 초과 시 배포 차단
- **네트워크**: 아웃바운드 도메인 allow-list, 인바운드 방화벽
- **백업/복구**: 일일 스냅샷 + 주간 오프사이트 보관, 복구 리허설 분기 1회

---

## 11) 프로젝트 디렉토리 스캔 & 요약 공유
스캐너 출력 예시(JSON):
```json
{
  "lang_mix": {"python": 72, "ts": 20, "other": 8},
  "deps": ["fastapi@0.115", "pytest@8"],
  "entrypoints": ["app/main.py"],
  "tests": 34,
  "risk": {"long_files": ["app/core.py"], "dup_code": 3},
  "graph": {"modules": 42, "edges": 117},
  "open_issues": ["API timeout", "flaky test"],
  "summary": "API 레이어 결합도 높음, 캐시 미도입"
}
```
KO는 위 요약을 Kickoff/주기 리더보기 형태로 GPT-5에 공급.

---

## 12) 운영 절차 (무인 모드 우선)
1) **계획**: GPT-5가 오늘의 목표/할일/리스크 제시 → KO가 보드/이슈 반영
2) **코딩**: 브랜치 생성→코드/테스트 생성→로컬 테스트→PR
3) **검증**: CI 통과→스테이징 배포(옵션)→자동/샘플 수동 체크
4) **릴리즈**: 태깅/릴리즈 노트 자동화
5) **리트로**: 에러/지연 분석 카드화, KO 기능 개선 티칭

UI는 **승인 버튼 2개**만: [다음 단계 실행] / [중단]

---

## 13) 모니터링 & 로그 표준
- 이벤트 로그 스키마: `ts(KST), actor, intent, target, result, duration_ms`
- 아티팩트: 빌드 산출물, 테스트 리포트, 커버리지, SBOM, 요약 리포트
- 대시보드: 오늘 처리 이슈 수, 실패 건, 평균 리드타임, 핫스팟 파일

---

## 14) 실패/복구 전략
- 실패 감지 → 자동 롤백(PR revert) → 이슈 생성 → 에러 카드 갱신
- 셸 명령 실패 시: 3단계 재시도(지수 백오프) 후 수동 승인 요구
- 컨텍스트 폭주 시: Chunking + 섹션별 요약(맵-리듀스) 재구성

---

## 15) 로드맵
### Phase 0 (1주)
- KO 스켈레톤(FastAPI/WebSocket), Shell Runner, GitHub App 연결
- 통신 프로토콜 ko-v1, Chunking, Exec, Git 최소 명령 구현

### Phase 1 (2주)
- 스캐너 v1, Error KB v1, CI 템플릿 자동화, PR/릴리즈 자동 생성
- 승인지원 UI(2버튼), 기본 보안(로그인+2FA), 감사 로그 v1

### Phase 2 (2주)
- Viewport/Scroll 추상화, 에러 교육 루프(Teaching) 자동화
- 무인 머지 정책(테스트/분석 통과 시), 롤백/재배포 절차 확립

### Phase 3 (지속)
- 성능 최적화, 다언어 코드베이스 지원 확대, 실험적 자율 리팩터링

---

## 16) 리스크 & 대응
- **잘못된 자동 실행**: 위험 명령 차단 리스트+승인 게이트
- **토큰 유출**: 시크릿 볼트/단기 토큰/감사 로그
- **LLM 혼동/루프**: 프로토콜 의도 필드/타임아웃/중단 인터럽트
- **컨텍스트 초과**: Chunking/요약/지식 KB 참조

---

## 17) 부록 A — Git 규칙/PR 템플릿
- 브랜치: `feat/<short>`, `fix/<short>`, `chore/<short>`
- PR 템플릿 섹션: 목적/변경점/테스트/리스크/롤백/체크리스트

---

## 18) 부록 B — KO 보안 체크리스트
- 2FA/TOTP, 관리자 추가코드, Vault/KMS, SBOM, SCA, 의존성 핀
- 최소 권한 토큰, 감사 로그 불변 저장(WORM), 주기적 복구 리허설

---

## 19) 부록 C — KO ↔ GPT-5 교육(Teaching) 루프
1) KO가 실패/지연/반복 패턴을 **메타 요약**
2) GPT-5가 KO 운영 규칙/스크립트 개선안 생성
3) KO 정책 업데이트(버전드), A/B 운영 후 승격

---

## 20) 다음 액션(권장)
- Phase 0 작업 이슈 자동 발행
- GitHub App 등록/권한 최소화, 시크릿 볼트 구성
- 샘플 레포 `kobong-lab` 생성 후 E2E Dry-run

---

## 21) GPT-5 ⇄ KO 소통 방식 보완 체크리스트
> 현재 ko-v1 규약으로 충분하되, 아래 항목을 추가하면 신뢰도/운영성이 크게 향상됩니다.

- **스키마 레지스트리/버전링**: `protocol_version`(semver) + 하위호환 필드 허용, `capabilities[]` 네고
- **Idempotency 키**: `idempotency_key` 로 재전송/재실행 안전화 (네트워크 재시도 대비)
- **QoS/우선순위**: `priority: high|normal|low`, KO 큐 분리 및 rate-limit 정책
- **백프레셔**: KO가 `429/BUSY` 응답 시 GPT-5가 지수 백오프/슬로틀링
- **트랜잭션 경계**: `begin/commit/rollback` 의도 지원(예: 여러 git/shell 묶음)
- **관측 필드 표준화**: `duration_ms`, `retries`, `bytes`, `exit_code`, `warnings`
- **보안 레벨**: `sensitivity: low|high|secret` + KO 측 마스킹/레드액션
- **감사 추적성**: `actor_chain`(who-called-what)와 `corr_id`로 분산 트레이싱 연결

---

## 22) 모니터링/관측(Observability) 설계
### 22.1 대시보드 뷰(1~4 Pane 레이아웃)
- **4분할(2×2)**: (A) 사용자 활동, (B) GPT-5 상태, (C) GitHub 상태, (D) KO 상태/에러KB
- **2분할(1×2)**: 상단 종합 KPI, 하단 로그/트레이스 타임라인
- **단일 풀스크린**: 임계 사고 대응(Incident) 뷰 — 실시간 이벤트/알람/런북
- **1~4 Pane 토글**: 키보드 단축키로 신속 전환(예: `1..4`, `g`로 GitHub, `k`로 KO)

### 22.2 공통 KPI(상단 리본)
- 오늘 처리 이슈 수 / 실패 수 / 평균 리드타임 / 에러 재발 비율 / 최근 배포 버전

### 22.3 사용자 모니터링(활동/승인 흐름)
- 클릭수, 승인/거절 수, 대기시간, 취소율, 재시도율, 사용자별 알람 소음(Noise) 지수
- 행동 히트맵(시간대별), ‘승인 없이 자동 진행’ 비율

### 22.4 GPT-5 상태
- 토큰 사용량(입력/출력), 컨텍스트 압력(%)과 Chunk 사용률
- 요청 레이턴시 p50/p90/p99, 오류율(4xx/5xx 등), 리트라이율, 스로틀 이벤트 수
- **품질 시그널**: 테스트 통과 예측 정밀도, 코드 리뷰 자동 승인 대비 실제 이탈률

### 22.5 GitHub 상태
- 대기 PR 수, 평균 PR 리드타임, 머지 성공률, 롤백 횟수
- CI 통과율, flaky 테스트 지수, 릴리즈 빈도/변동성(DORA 메트릭)

### 22.6 KO 상태
- 큐 길이, 실행 슬롯 사용률, 명령 성공률/재시도, 평균 명령 시간
- 시크릿 볼트 접근 이벤트, 실패한 보안검사 수(SCA/SBOM)

### 22.7 에러 경험/학습 데이터
- 신규 에러 fingerprint 수, Top-5 재발 에러, 평균 TTR(해결시간)
- KB 카드 품질 지표(검증됨/미검증, 커버리지), 추천 적용률

### 22.8 SLO/알림 정책(예시)
- **가용성**: KO Exec API 99.9%/월, GitHub 자동 머지 성공률 95%
- **성능**: GPT-5 응답 p95 < 8s, PR 리드타임 중앙값 < 2h
- **품질**: 배포 후 24h 내 에러 재발률 < 1%
- 임계치 초과 시 Slack/이메일/콘솔 배너 + 런북 링크로 에스컬레이션

### 22.9 기술 스택 제안
- **Metrics**: Prometheus → Grafana
- **Traces**: OpenTelemetry → Tempo/Jaeger
- **Logs**: Loki 또는 ELK(OpenSearch)
- **Alerts**: Alertmanager → Slack/Webhook/Email

---

## 23) 헬스체크/하트비트 설계
- **Active health**: `/healthz`, `/readyz`, `/livez` (KO, Scanner, Shell Runner)
- **Synthetic checks**: 샘플 레포에 주기 테스트 커밋/PR로 GitHub/CI 경로 검증
- **GPT-5 합성 프롬프트**: 고정 답안 검증(정확도/지연)을 10분 간격 샘플링

---

## 24) 제어 콘솔 UI(전문가 옵션)
### 24.1 상단 바
- 환경 스위치(dev/stage/prod), 안전모드(읽기전용/드라이런/완전 자동), 속도 슬라이더(QoS)
- 이벤트 배너(알람/변경 공지), 전역 검색(이슈/파일/에러/트레이스)

### 24.2 패널 구성
- **메시지 인스펙터**: GPT-5⇄KO 패킷 실시간 뷰, Diff/Replay, PII 마스킹 토글
- **실행 큐/잡 관리자**: 우선순위 변경, 취소/재시도, 타임아웃/동시성 조절
- **리포지토리 패널**: 브랜치 보호/메타 설정, PR 규칙, 릴리즈 생성/롤백 버튼
- **시크릿 볼트 패널**: 권한 최소화·만료 설정, 사용 이력, 키 회전
- **스캐너/KB 패널**: 구조 그래프, 핫스팟 파일, 에러 카드 편집/승격, 추천 적용
- **실험/혼란(Chaos) 모드**: 제한된 장애 주입으로 복원력 테스트(승인 필요)

### 24.3 고급 설정
- Chunk 크기/요약 전략(맵-리듀스/슬라이딩), 컨텍스트 제한, 코드 생성 정책(보수/공격)
- Shell 안전 리스트/블록 리스트 편집, Dry-run 강제, 리트라이 도표
- Git 전략(스쿼시/리베이스/머지), 자동 리뷰 임계치, 머지 가드 조건 편집

---

## 25) 데이터 보존/프라이버시/보안(모니터링 영역)
- 로그/트레이스 보관 기간: 기본 30일(요약 아카이브 1년), PII 자동 마스킹
- 시크릿 미노출 보장: 콘솔에서 기본 마스킹, 복호화는 권한+2FA 필요
- WORM 스토리지로 감사 로그 불변성 보장, 정기 접근 감사

---

## 26) 런북(Incident Response) 골격
- 탐지 → 분류(P1~P4) → 소유자 지정 → 초기 대응 체크리스트
- 표준 조치(롤백/리트라이/격리) 버튼화, 사후 보고서 자동 템플릿

---

## 27) 다음 단계(모니터링 집중)
- Grafana 프로비저닝 대시보드 JSON 초안 생성
- KO에 OTel 계측(Trace + Metrics + Logs) 삽입
- 합성 PR/프롬프트 잡 크론 구성(10분 간격)


---

## 28) 최고 관리자(슈퍼관리자) 로그인/권한 상승 설계 (권장 구성)
- **ID 공급자(SSO/OIDC)**: Google Workspace/Okta/Azure AD 등 기업 IdP 연동. 관리자 계정은 **조직 2FA 강제**.
- **기본 인증**: **WebAuthn(패스키/보안키)** 필수. SMS/이메일 코드는 관리자 경로에서 미허용.
- **백업 수단**: TOTP(앱 기반) + 1회성 복구 코드(오프라인 보관, 사용 즉시 회수). 
- **네트워크/디바이스 제약**: VPN 또는 고정 IP 허용 목록 + 관리형 디바이스만 콘솔 접근.
- **세션 보안**: 짧은 수명 토큰(Idle 15분/절대 8시간), 권한 상승·설정 변경 시 **재인증(step‑up)** 요구.
- **권한 모델**: 기본 최소권한 + **Just‑In‑Time(JIT) Elevation**(사유/기한 필수, 기본 15분) → 만료 자동 강등.
- **이중 승인(4‑eyes)**: 고위험 작업은 별도 관리자 1인 이상 추가 승인 필요.
- **감사/알림**: 관리자 작업 전부 WORM 저장 + 실시간 알림(Slack/이메일) + 주간 요약 보고.
- **비상(‘break‑glass’) 계정**: 오프라인 보관(금고), 분기별 복구 리허설, 사용 즉시 포렌식/강제 키 회전.
- **오프보딩**: SCIM/IdP 연동으로 계정 비활성화, 패스키·토큰 즉시 폐기, 비밀키 회전.

**고위험 작업 테이블(기본 Step‑up + 4‑eyes 권고)**
| 작업 | Step‑up | 4‑eyes | 추가 정책 |
|---|---|---|---|
| `main` 강제 push/보호 규칙 변경 | 필수 | 필수 | 작업 전 Dry‑Run 증거 첨부 |
| 프로덕션 배포/롤백 | 필수 | 필수 | 변경 세트 해시 고정, 롤백 플랜 포함 |
| 시크릿/키 회전 | 필수 | 권장 | 사용 영향 범위 자동 분석 첨부 |
| Chaos 모드 활성화 | 필수 | 필수 | 시간/범위 제한, 자동 종료 타이머 |
| 감사 설정 변경/삭제 | 필수 | 필수 | 변경 이전 스냅샷 보관 |

**예시 구성(YAML)**
```yaml
admin_auth:
  idp: oidc
  webauthn_required: true
  totp_backup: true
  ip_allowlist: ["203.0.113.0/24", "198.51.100.10/32"]
  device_posture: managed_only
  session:
    idle_timeout_min: 15
    absolute_timeout_hours: 8
  elevation:
    jit: true
    default_duration_min: 15
    reason_required: true
  approvals:
    four_eyes:
      enabled: true
      required_actions: ["prod_deploy", "main_protection_change", "audit_policy_change", "chaos_enable"]
  audit:
    worm_storage: true
    realtime_alerts: ["slack", "email"]
```

---

## 29) 모니터링 대시보드 레이아웃 프리셋 & 메트릭 사전
### 29.1 레이아웃 프리셋(1~4 Pane 토글)
- **Ops 4‑Pane(2×2)**: (A) 사용자 활동, (B) GPT‑5 상태, (C) GitHub/CI, (D) KO/에러KB
- **Dev 2‑Pane(상/하)**: 상단 KPI 리본 + 하단 로그/트레이스 타임라인
- **Incident Full**: 알람/Runbook/최근 변경/릴리즈 히트맵 한 화면 집중
- **단축키**: `1..4`(팬 수), `g`(GitHub), `k`(KO), `e`(ErrorKB), `u`(User)

**저장 가능한 레이아웃 스키마(JSON)**
```json
{
  "name": "ops-4pane",
  "panes": [
    {"id":"user","source":"analytics.user","w":6,"h":6},
    {"id":"gpt5","source":"metrics.gpt5","w":6,"h":6},
    {"id":"github","source":"metrics.github","w":6,"h":6},
    {"id":"ko","source":"metrics.ko","w":6,"h":6}
  ]
}
```

### 29.2 메트릭 네이밍(예: Prometheus)
- **GPT‑5**: `gpt5_request_latency_seconds{op}` / `gpt5_token_usage_total{type}` / `gpt5_error_total{code}`
- **GitHub/CI**: `github_pr_open_total` / `github_merge_lead_time_seconds` / `ci_pass_rate` / `flaky_test_index`
- **KO**: `ko_exec_duration_seconds` / `ko_exec_success_total` / `ko_queue_depth` / `ko_busy_state` (0/1)
- **ErrorKB**: `kb_new_fingerprint_total` / `kb_recurrence_total` / `kb_verified_ratio`
- **사용자**: `user_approval_time_seconds` / `auto_progress_ratio` / `alert_noise_index`

### 29.3 알림 규칙(샘플)
- `gpt5_error_total{code=~"5.."} > 5` (5분) → P2
- `github_merge_lead_time_seconds_p95 > 14400` → P3
- `ko_busy_state == 1 for 10m` → P2
- `kb_recurrence_total > 0` for same fingerprint within 24h → P2

---

## 30) 콘솔 UI 전문가 기본값(안전 우선)
- 시작 모드: **읽기전용** → 프로젝트별 화이트리스트로 **드라이런** → 필요시 **완전 자동** 승격
- 코드/명령 실행은 기본 **Dry‑Run** 강제, 위험 명령은 블록 리스트 + 승인 필요
- 자동 머지 조건: 테스트 통과 & 정적분석 경고 0 & 변경 영향 ≤ 임계치
- 컨텍스트 관리: Chunk 200KB, 요약 전략 기본 맵‑리듀스, 초과 시 KO가 분할 재요청
- 저장/복구: 대시보드/레이아웃/알림 프로필은 버전드로 롤백 가능

---

## 31) 통신 규약 충분성 검증 체크(수용 기준)
- **신뢰성**: 재전송 시 **Idempotency**로 중복 실행 없음(테스트 케이스 포함)
- **흐름제어**: KO가 `BUSY/429` 발행 시 GPT‑5가 지수 백오프로 복구
- **보안성**: `sensitivity` 필드에 따른 마스킹/레드액션 동작 검증
- **추적성**: `corr_id`로 Git/Shell/PR/배포 이벤트가 한 타임라인으로 연결됨
- **성능**: p95 왕복 지연 < 2s(사내망), 8s(외부), 1k req/min까지 안정
- **호환성**: `protocol_version`/`capabilities[]` 네고로 점증적 확장 가능

테스트는 합성 워크로드(코드 생성→테스트→PR→머지)로 시나리오별 패스/페일 기준 설정.


---

## 32) 환경/스택 표준 (프로필 통합)
- OS/IDE: **Windows 11 Pro**, VS Code, PowerShell 7
- Python: **3.11 (64-bit)**, venv/pip
- GUI: **PySide6 (Qt)**
- 패키징: **PyInstaller**(exe 배포)
- 데이터/스토리지: SQLite, S3/GCS
- 자동화 도구: GitHub, AWS CLI, OpenCV, Tesseract OCR 5 + pytesseract, mss, pywinauto + uiautomation
- 기본 폴더: `docs/ app/ domain/ infra/ ui/ tests/ scripts/`
- 운영 스크립트(권장): `scripts/dev_setup.ps1`, `run.bat`, `run_ui.bat`, `run_debug.bat`, `check_import.bat`

---

## 33) 코드 스타일 & 정적분석 표준
- 포맷/린트: **Black**, **isort**(profile=black), **Ruff**(엄격: F401/F841 등), **mypy(strict)**, **Bandit(선택)**
- 공통 규칙: 들여쓰기 4 spaces, 따옴표 double, 줄 길이 88, EOL LF, UTF-8(BOM 없음)
- import: stdlib > third‑party > first‑party, wildcard 금지, 한 줄 한 import
- 문자열: f-strings 우선, mutable default 금지, absolute imports 권장
- Docstring: PEP 257 + Google‑style
- 네이밍: PascalCase(클래스) / snake_case(함수·변수) / UPPER_CASE(상수)
- logging 우선(printf 지양)
- **pre-commit** 훅에 Black/isort/Ruff/mypy/secret-scan 등록

---

## 34) 브랜치/커밋/버저닝 정책
- 브랜치: `main`(보호), `dev/<issue>`, `release/x.y`, `hotfix/x.y.z`
- 명명: `feat/*`, `fix/*`, `docs/*`, `perf/*`, `refactor/*`, `test/*`, `build/*`, `ci/*`, `chore/*`, `revert/*`
- 커밋: **Conventional Commits**(type/scope/footer) + 이슈ID 태깅(#ID)
- 버전: **SemVer**, 태그 `vX.Y.Z`, 프리릴리스 `-alpha|-beta|-rc`
- 배포: PR + 리뷰 + CI + **스쿼시 머지**, CHANGELOG 자동화

---

## 35) 테스트 전략 & 커버리지 목표
- 우선순위: Unit → Contract(스키마/프로토콜) → Integration → E2E‑Smoke
- 목표: Unit ≥85%(코어 ≥90%), Branch ≥80%, Integration ≥75%
- E2E: 핵심 시나리오 커버 ≥90%, 성공률 ≥95%, UI 자동화 플래키율 <2%
- 예외/에러 경로 ≥70%, 뮤테이션 스코어 ≥60%

---

## 36) 자동화 우선 & CI/CD 파이프라인
- Jobs: lint(Black/isort/Ruff) → typecheck(mypy) → security(Bandit, **secret scan: gitleaks/trufflehog**) → unit/integration → pack(PyInstaller) → e2e‑smoke → release(tag/changelog)
- 시간 목표: CI ≤ 10분, 아이디어→배포 ≤ 2일(리드타임)
- 환경 재현: devcontainer/Makefile/lockfile, 의존성 봇 활성화
- 문서 자동화: 명세/DSL→Docs, 릴리스 노트 생성

---

## 37) 보안/비밀관리
- 규제: PIPA(대한민국), GDPR 고려
- 비밀: **AWS Secrets Manager / SSM Parameter Store**, **KMS**(암호화/키회전), **IAM Role 최소권한(STS)**
- 금지: **.env 하드코딩 금지**(로컬은 1Password·Bitwarden 등), 코드/레포 내 비밀 금지
- 스캔: pre-commit + CI에서 시크릿 스캔, 주기 90일 이하 키 교체 & 비상 폐기 절차
- 환경 분리: prod/stg/dev, 런타임 주입(ENV/IRSA)

---

## 38) 로깅/추적/관측
- 형식: **JSON Lines**, 시간은 **UTC ISO8601 + monotonic_ms**, 별도 `tz:"Asia/Seoul"` 필드
- 공통 필드: app(name, ver, commit), env, host, pid, thread, trace_id, span_id, user, role, action, result(status, code), latency_ms, err(type,msg,stack)
- 민감정보: 자동 마스킹(Email/TOKEN/APIKEY/쿠키), 이미지 원본 비저장(경로+해시), PII 원문 금지
- 회전/보관: size 20MB×10 또는 daily, 보존 dev 14d / prod 90d, 주기적 S3 업로드(+SHA256)
- 크래시: 전역 예외 훅(스택+최근 200줄+환경 요약), 미니덤프 옵션
- 성능: cpu_pct, mem_mb, capture_fps, queue_depth 주기 로깅
- Traceability: 요구↔설계↔코드↔테스트↔배포↔운영 로그 연계(트레이스 매트릭스 자동 생성)

---

## 39) Small Batches 실행 원칙
- PR ≤ **300 LOC** & **≤ 1 기능**, 하루 **1+ PR** 권장, 스쿼시/Trunk 기반
- 배포: Feature Flags, Dark Launch, Canary, Blue‑Green, **원클릭 롤백**
- 테스트: 최소 경로 우선, WIP ≤ 2, 가시성(칸반/흐름지표)

---

## 40) Contract‑first & API/DSL 명세
- 버전 명세: OpenAPI/JSON Schema, SemVer 적용
- 계약 검증: 스키마 린트/밸리데이션, CDC(소비자 주도 테스트)
- 코드 생성: 계약 기반 클라이언트/서버 스텁 자동화
- 변경관리: Deprecation 정책·이관 가이드, 역호환 체크(diff)

---

## 41) Definition of Ready / Done (요약)
### DoR 핵심
- 목표·지표 3~5줄 AC, 범위/제약/외부의존 확정, 인터랙션 초안, 테스트 시나리오 선행, 성능·보안·로그·롤백 계획, 실행 스크립트 재현성, 위험·권한 사전 해결, 최종 승인 라벨(READY)

### DoD 핵심
- 기능 AC 충족(미리보기/ROI/버튼/Role/Save-Load/단축키 등 핵심 UX 정상)
- 안정성·성능 임계 만족(CPU/Mem/지연), 크래시 0, 경고 없음
- 품질 표준 준수(UTF-8, 버전 헤더, 테스트 통과, 린트/포맷 통과, TODO 없음)
- 로그/보안/설정, 스크립트/재현성, 문서/릴리스 노트·스크린샷, 기능 플래그/즉시 롤백 준비

> 전체 상세 체크리스트는 내부 위키/이슈 템플릿에 그대로 반영(자동 생성) 권장

---

## 42) 문서/다이어그램 산출물
- ADR/RFC 사용, **C4/시퀀스/ERD/상태도** 채택
- 결과물 포맷: **Word(docx), PDF** 병행

---

## 43) 롤백·배포 전략(세부)
- **Blue‑Green** 기본 + **Feature Flags** 즉시 Off + **Canary** 단계 도입
- DB: **롤포워드** 전략, PITR 스냅샷 복구 절차 문서화
- 불변 아티팩트/헬스체크 게이트 기반 **원클릭 롤백** 스크립트 제공

# 부록 D — 우리 프로젝트 UI 적용 가이드(권장; 보안/특성 반영)

> 원칙 요약: **PS7-First CLI로 핵심 오퍼레이션**, **TUI로 관찰/저위험 조작**, **Web GUI로 관측·승인·설정(고보안)**.  
> 기본 모드: **읽기전용 → 드라이런 → 완전 자동**. 모든 경로는 **감사 로그(WORM)**와 **승인 게이트** 적용.

## 1) CLI (PS7) — 핵심 오퍼레이션
- **표준/안전**: PS7 헤더·StrictMode·UTF-8 LF·표준 종료코드(10/11/12/13), RepoRoot 샌드박스, 위험 명령 블록리스트, **Dry-Run 기본**, **원자쓰기+`.bak-<ts>` 백업**, 최소 1건 KLC 로그(없으면 JSONL 폴백).
- **보안**: 최소권한 + 임시 토큰(JIT/STS), Vault/KMS **주입형** 시크릿, 콘솔 출력 PII/시크릿 **마스킹 기본 ON**.
- **운영성**: Idempotency 키, 지수 백오프, 실패 시 자동 롤백 스크립트. 더블클릭 실행 환경용 **NoExit 런처/홀드(탐색기 실행 시)**.

## 2) TUI (터미널 UI) — 운영 편의
- **역할**: 실시간 로그/큐/잡 **한 화면 요약**, **취소/재시도** 같은 **저위험 조작** 중심. 상태색/아이콘·키맵 제공.
- **보안**: 기본 **읽기전용**, 조작 기능은 **Step-up 인증** 요구(관리자 패스키/비밀번호). 시크릿 **미표시**, 세션 타임아웃.
- **관측**: 멀티 로그 **스트리밍 테일+검색/필터**, `traceId` 링크로 PR/실행/배포 타임라인 연결.

## 3) Web GUI — 관측/승인/설정
- **역할**: **대시보드**(KPI/헬스/알림), **승인 큐**(2-버튼: [다음 단계]/[중단]), **설정 관리**(안전모드, 우선순위, 큐 제어), 런북/인시던트 뷰.
- **보안(강화)**: **SSO/OIDC + WebAuthn(패스키/보안키) 필수**, 세션 **Idle 15m / Absolute 8h**, **JIT 권한 상승**(사유·기한 필수, 기본 15m) + **4-eyes 승인**(보호규칙/배포/감사설정/Chaos), **IP Allowlist/관리형 디바이스** 제한, **CSRF/CSP/SameSite** 적용, 전 구간 **TLS**, 감사 이벤트 **WORM 보관**, 주간 요약 자동 발송, **Break-glass** 절차 문서화.
- **데이터/프라이버시**: 로그 보존 Dev 14d/Prod 90d(요약 1y), PII 기본 마스킹, 이미지/아티팩트는 **경로+해시** 위주 기록.

## 4) 프로젝트 특성 반영 체크리스트
- **사용자 프로필**: 단일 운영자(초보) — **2-버튼 승인** 중심, 위험 작업은 항상 승격/이중 승인.
- **환경/시간대**: Windows 11 + **PS7 전용**, `Asia/Seoul` 고정(로그/스케줄 일관성).
- **자동화 우선**: CLI→TUI→Web **경량→중량** 단계, 실패 시 **자동 롤백**·가이드.
- **관측 표준**: OTel 네이밍/메트릭, Phase‑1에 Grafana/Tempo 연동 용이화.
- **장애 대비**: 합성 PR/프롬프트 주기 체크, KO Busy(429) 시 GPT‑5 **백오프**·우선순위 큐.
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
