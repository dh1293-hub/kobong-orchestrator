# Kobong — GPT‑5 주도형 개발 계획서 (v1.0)

> 목적: 지금까지의 꼬봉(Conductor) 계획을 **GPT‑5 주도형**으로 재정렬하고, GPT‑5가 **꼬봉을 ‘가르칠 수’ 있게**(Teach/Run/Review 루프) 계약/테스트/운영 체계를 확정한다.

---

## 0) TL;DR
- **주도권: GPT‑5** — 사람은 승인/중단/우선순위 결정.
- **학습 가능 꼬봉** — GPT‑5가 *Skill Proposal → Contract Update → Auto‑Scaffold → Contract Tests → Promote* 루프를 돌려 스킬을 추가/개선.
- **Small Batches**(단일 의도), **Contract‑first**, **Traceability**, **Automation‑first** 고정.

---

## 1) 근거/전제
- 기존 반자동 협업 계획의 **역할/아키텍처/DSL/운영 규칙** 유지.
- 표준 운영 지침(계약 관리, 로그/품질 게이트, 단계 게이트) 준수.
- 환경: Windows 11 + PowerShell 7 + Python 3.11 + PySide6, GitHub.

---

## 2) 역할 모델(고정)
| 주체 | 역할 | 책임 |
|---|---|---|
| **GPT‑5** | 주도(설계/계약/테스트/지식 주입) | Skill/DSL 제안·검증·릴리즈 노트·회귀·모니터링 항목 도출 |
| **지휘자(사람)** | 승인·중단·우선순위 | 위험 수용도 설정, 민감 단계 승인, 실패 시 중단·롤백 지시 |
| **Kobong(앱)** | 실행/검증 | Locator/Action/Verify 실행, 로그·스냅샷·리포트, 계약 준수 |
| **AI1/AI2** | 대상 | 화면/브라우저/앱 상호작용 대상 |

---

## 3) GPT‑5 ↔ 꼬봉 **Teach/Run/Review** 루프
1) **Teach (제안)**
   - GPT‑5가 `Skill Proposal` 제출 → 스킬 정의(YAML) + 계약 변경(필요 시) + 테스트 케이스.
2) **Spec (계약 고정)**
   - 계약(JSON Schema) 갱신 — **Minor=Additive Only**; 스텁/모듈 **자동 재생성**.
3) **Scaffold/Implement**
   - 자동생성 코드/어댑터 뼈대 + 최소 구현.
4) **Test & Gate**
   - Contract/Unit/Integration/E2E‑Smoke 통과 → 커버리지/성능 기준 확인.
5) **Release/Promote**
   - 기능 플래그 기본 Off → Canary → Promote.
6) **Review/Learn**
   - 실행 로그·스냅샷 기반 **개선 제안**(GPT‑5) → 다음 배치에 반영.

---

## 4) 아키텍처 & 폴더
- 계층: **UI → App → Domain → Infra** (Ports & Adapters, 단방향 의존)
```
project/
  docs/        (README, ADR, TESTPLAN, LOGGING, MIGRATION, RUNBOOK)
  app/         (use cases, services)
  domain/      (entities, value objects, ports, dsl)
  infra/       (ocr, locator, actions, storage, adapters)
  ui/          (PySide6 UI)
  contracts/   (JSON Schemas: commands, results, skills)
  skills/      (*.skill.yaml — 승급 전/후 디렉토리 분리: staged/, approved/)
  tests/       (unit, contract, integration, e2e-smoke)
  scripts/     (setup-env, run-tests, run-smoke, build, release, rollback)
  logs/        (jsonl; evidence/ 스냅샷)
```

---

## 5) **계약(Contract) 집합** — GPT‑5 학습/주입 경로의 핵심
### 5.1 Commands (실행 명세)
파일: `contracts/kkb.commands.v1.json`
- 핵심 필드(요약):
```json
{
  "$id": "kkb.commands.v1",
  "type": "object",
  "required": ["plan"],
  "properties": {
    "meta": {"type": "object", "properties": {"traceId": {"type": "string"}, "from": {"enum": ["gpt5"]}}},
    "plan": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["step", "actions"],
        "properties": {
          "step": {"type": "integer"},
          "explain": {"type": "string"},
          "actions": {"type": "array", "items": {"$ref": "#/definitions/action"}}
        }
      }
    }
  },
  "definitions": {
    "action": {
      "oneOf": [
        {"title": "LOCATE",  "type": "object", "required": ["LOCATE"],  "properties": {"LOCATE": {"type": "object", "required": ["role","by"], "properties": {"role": {"enum":["ai1","ai2","conductor"]}, "by": {"enum":["text","icon","anchor"]}, "query": {"type":"array","items":{"type":"string"}}, "timeout_ms": {"type":"integer"}}}}},
        {"title": "FOCUS",   "type": "object", "required": ["FOCUS"],   "properties": {"FOCUS": {"type": "object", "properties": {"target": {"type":"string"}}}}},
        {"title": "PASTE",   "type": "object", "required": ["PASTE"],   "properties": {"PASTE": {"type": "object", "required":["text"], "properties": {"text": {"type":"string"}}}}},
        {"title": "PRESS",   "type": "object", "required": ["PRESS"],   "properties": {"PRESS": {"type": "object", "properties": {"keys": {"type":"string"}}}}},
        {"title": "CLICK",   "type": "object", "required": ["CLICK"],   "properties": {"CLICK": {"type": "object", "properties": {"button": {"enum":["left","right"]}, "x": {"type":"number"}, "y": {"type":"number"}}}}},
        {"title": "WAIT",    "type": "object", "required": ["WAIT"],    "properties": {"WAIT": {"type": "object", "properties": {"ms": {"type":"integer"}}}}},
        {"title": "SNAPSHOT","type": "object", "required": ["SNAPSHOT"],"properties": {"SNAPSHOT": {"type": "object", "properties": {"label": {"type":"string"}}}}},
        {"title": "VERIFY",  "type": "object", "required": ["VERIFY"],  "properties": {"VERIFY": {"type": "object", "properties": {"ocr_contains": {"type":"string"}, "text_contains_any": {"type":"array","items":{"type":"string"}}, "timeout_ms": {"type":"integer"}}}}}
      ]
    }
  }
}
```

### 5.2 Results (실행 결과)
파일: `contracts/kkb.results.v1.json`
- 필수: `step`, `status(ok|fail|retry)`, `duration_ms`, `evidence(loc/score/snapshots[])`, `error(code,msg)`.

### 5.3 Skills (학습 가능한 스킬)
파일: `contracts/skills.v1.json`
- 목적: GPT‑5가 제안하는 **스킬팩/루틴**의 **계약화**.
- 최소 필드: `id`, `name`, `version`, `category(browser|chat|docs|file)`, `intent`, `preconditions[]`, `dsl(plan[])`, `assertions[]`, `kpi`.

---

## 6) **스킬 제안(Teach) 포맷**
YAML: `skills/staged/send_prompt_to_ai1.skill.yaml`
```yaml
id: skill.send_prompt_to_ai1
name: "Send prompt to AI1 and verify reply"
version: 0.1.0
category: chat
intent: "paste into chat input and press Enter"
preconditions:
  - role: ai1
  - app: browser
  - ui: chat_input_visible
plan: # commands.v1와 100% 호환
  - step: 10
    explain: "focus input, paste text, send"
    actions:
      - LOCATE: {role: ai1, by: text, query: ["채팅 입력", "Send a message"], timeout_ms: 5000}
      - FOCUS:  {target: "@LOCATE"}
      - PASTE:  {text: "<PROMPT_TEXT>"}
      - PRESS:  {keys: Enter}
      - WAIT:   {ms: 1200}
      - SNAPSHOT: {label: ai1_after_send}
assertions:
  - VERIFY: {text_contains_any: ["Sent", "전송됨", "응답 중"], timeout_ms: 2000}
```

승격 흐름: `staged/…yaml` → **Contract Tests** 통과 → `approved/…yaml` 이동 → 기능 플래그 On.

---

## 7) 테스트 & 게이트
- **계약 테스트**: `tests/contract/skills_v1_test.py` — YAML ↔ JSON Schema 검증, 필수 필드/타입, DSL 호환.
- **단위/통합**: Locator/Action/Verify 모듈에 케이스 추가.
- **E2E‑Smoke**: 핵심 3~5 흐름(프롬프트 전송→응답 회수→요약→재전달) 95%+.
- **커버리지 목표**: Unit ≥85% / E2E 성공률 ≥95%.

---

## 8) 로그/리포트(운영)
- **형식**: JSON Lines (PII 마스킹), `logs/*.jsonl`.
- 공통 필드: `timestamp, level, traceId, module, action, inputHash, outcome, durationMs, errorCode, message`.
- **증적**: `evidence/`에 `s{step}_{role}_{label}.png` 체인 + 탐지 스코어/ROI 기록.
- 리포트: HTML/PDF — 요약/타임라인/KPI(탐지 성공률·재시도율·평균 단계 시간·승인 횟수).

---

## 9) 스크립트(표준)
- `scripts/setup-env.ps1` — 의존성 설치/환경 점검
- `scripts/run-tests.ps1` — 모든 테스트 실행
- `scripts/run-smoke.ps1` — 스모크(3~5 시나리오)
- `scripts/build.ps1` — 패키징/버전 주입
- `scripts/release.ps1` — SemVer bump + 태그 + 릴노트
- `scripts/rollback.ps1` — 원클릭 롤백
> 원칙: 로컬=CI 동일 명령, **Idempotent**, 실패 시 즉시 중단.

---

## 10) 안전장치(HITL)
- 승인 필수 단계: 로그인/결제/업로드/대량 삭제.
- 금칙/허용 도메인·키워드 리스트, **즉시 중지** 핫키(Ctrl+Alt+Esc).
- 마지막 스냅샷 위치로 **롤백/재시작**.

---

## 11) 일정(4~6주)
- **Sprint‑A(1~2주)**: Commands/Results/Skills v1 스키마 고정, 스킬 1종 승인, 스모크 3종.
- **Sprint‑B(3~4주)**: 이미지 매칭 안정화, 로딩 감지, 리포트 v1.
- **Sprint‑C(5주)**: 매크로 녹화→DSL 변환 PoC.
- **Sprint‑D(6주)**: 병렬 큐/충돌방지, KPI 대시보드, 회귀/리플레이.

---

## 12) 성공 기준(DoD)
- Teach/Run/Review 루프 **완주**(스킬 1종 제안→계약→테스트→승격) + E2E 성공률 ≥95%.
- 로그/리포트 자동 집계 + UI 불변규칙 준수(버튼 1열·STS 블루·선택 녹색 등).
- 배치 스크립트 4종 정상 동작, 실행/디버깅/로그 수집 가능.

---

## 13) 오늘 액션(단일 의도)
1. `contracts/kkb.commands.v1.json` / `kkb.results.v1.json` / `skills.v1.json` **초안 추가**.
2. `skills/staged/send_prompt_to_ai1.skill.yaml` **예시 파일 생성**.
3. `tests/contract/skills_v1_test.py`에 **계약 테스트**(필수 필드/타입/액션 타당성) 작성.
4. `scripts/run-tests.ps1`에서 **계약 검사 포함**.

— 끝 —

