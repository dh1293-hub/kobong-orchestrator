# Project Guidelines — GPT‑5 Lead (v0.3‑draft)

> 본 문서는 **GPT‑5 주도, 사람 보조(HITL)** 원칙을 기준으로, 현 프로젝트에 바로 적용 가능한 실행 지침을 제공합니다. 표준 규범은 “Human‑GPT5 Rulebook v1.0”을 상속하고, **프로젝트 특이값/고정 규칙만** 정의합니다.

---

## 0) Intent & Scope
- 목적: 경로/런타임/권한/스크립트/CI/테스트/릴리스 **충돌 제거** 및 **실행 기준 확정**.
- 상속: 안전/에러/버저닝/테스트 원칙은 Rulebook을 준용. 필요한 값만 오버라이드.

## 1) 권한·의사결정 모델 (GPT‑5 주도)
- **기본 흐름:** 사용자(키워드) → **GPT‑5 설계/계획** → Conductor 실행/검증 → 사용자 승인(HITL) → 배포.
- **승인 게이트:** 파괴적/비가역 작업(삭제/배포/시크릿 변경)은 **HITL 승인 필수**.
- **모름 정책:** GPT‑5는 불확실 시 **“Unknown/확실하지 않음”**을 명시하고, 대안/검증 절차 제시.

## 2) 단일 사실의 원천 (SSOT)
- **명세/DSL/스키마**가 사실의 원천. 코드/테스트/문서는 이를 따름.
- 계약 변경은 **SemVer + 마이그레이션 노트 + 계약 테스트**를 동반.

## 3) 실행 환경 (고정 값)
- Repo 호스팅: **GitHub**.
- 런타임: **Python 3.11** (로컬/CI 동일). 3.12 시도는 별도 브랜치에서만.
- 운영체제/CI: **Windows (windows‑latest)** 우선. 필요시 Linux job 추가.

## 4) 경로 지침 (v1.1)
**목표:** 절대경로/개인경로 의존 제거, OS 중립, 재현성/이식성 극대화.

### 4.1 원칙 (확실)
- **Assumptions는 문서 전용**이며, 코드/스크립트/CI에서 **직접 참조 금지**.
- **경로 해석 우선순위:** `CLI 인자 → ENV(HAN_GPT5_ROOT) → git rev-parse → 스크립트 기준 상위(../)`.
- **절대경로 하드코딩 금지**, **chdir로 상태 은닉 금지**. 항상 **합성(join)** 사용.
- **출력/캐시/로그 표준 디렉터리**를 사용하고, 미존재 시 **자동 생성**.
- Windows/Unix **슬래시 자동 정규화** 및 **UTF-8** 고정.

### 4.2 표준 ENV & 디렉터리 (확실)
- `HAN_GPT5_ROOT` : 리포 루트(필수)
- `HAN_GPT5_OUT`  : 산출물(기본: `<root>/out`)
- `HAN_GPT5_TMP`  : 임시(기본: `<root>/.tmp`)
- `HAN_GPT5_LOGS` : 로그(기본: `<root>/logs`)
- `HAN_GPT5_CACHE`: 캐시(기본: `<root>/.cache`)

> Linux/XDG: 미설정 시 `CACHE_DIR=~/.cache/han-gpt5`, `LOGS=~/.local/state/han-gpt5`를 보조로 사용.

### 4.3 해석 알고리즘 (의무 구현, 확실)
의사코드:
```
root = arg.root ?? ENV[HAN_GPT5_ROOT] ?? git_root() ?? norm(path_of(script)/..)
fail_if_not_exists(root)
out  = ENV[HAN_GPT5_OUT]  ?? join(root, 'out')
tmp  = ENV[HAN_GPT5_TMP]  ?? join(root, '.tmp')
logs = ENV[HAN_GPT5_LOGS] ?? join(root, 'logs')
cache= ENV[HAN_GPT5_CACHE]?? join(root, '.cache')
mkdir_p(out, tmp, logs, cache)
```

### 4.4 스크립트 프롤로그 표준 (확실)
**PowerShell**
```powershell
# scripts/_preamble.ps1
$ErrorActionPreference = 'Stop'
function Get-GitRoot { try { git rev-parse --show-toplevel } catch { $null } }
param([string]$Root)
$root = $Root
if (-not $root) { $root = $env:HAN_GPT5_ROOT }
if (-not $root) { $root = Get-GitRoot }
if (-not $root) { $root = (Resolve-Path "$PSScriptRoot/..\").Path }
if (-not (Test-Path $root)) { throw "Invalid root: $root" }
$env:HAN_GPT5_ROOT = $root
$env:HAN_GPT5_OUT  = $env:HAN_GPT5_OUT  ?? (Join-Path $root 'out')
$env:HAN_GPT5_TMP  = $env:HAN_GPT5_TMP  ?? (Join-Path $root '.tmp')
$env:HAN_GPT5_LOGS = $env:HAN_GPT5_LOGS ?? (Join-Path $root 'logs')
$env:HAN_GPT5_CACHE= $env:HAN_GPT5_CACHE?? (Join-Path $root '.cache')
mkdir $env:HAN_GPT5_OUT, $env:HAN_GPT5_TMP, $env:HAN_GPT5_LOGS, $env:HAN_GPT5_CACHE -Force | Out-Null
```
**Bash**
```bash
# scripts/_preamble.sh
set -euo pipefail
root="${1:-${HAN_GPT5_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || dirname "$0")/..}}"
[ -d "$root" ] || { echo "Invalid root: $root"; exit 1; }
export HAN_GPT5_ROOT="$root"
: "${HAN_GPT5_OUT:=$root/out}" "${HAN_GPT5_TMP:=$root/.tmp}"
: "${HAN_GPT5_LOGS:=$root/logs}" "${HAN_GPT5_CACHE:=$root/.cache}"
mkdir -p "$HAN_GPT5_OUT" "$HAN_GPT5_TMP" "$HAN_GPT5_LOGS" "$HAN_GPT5_CACHE"
```

각 스크립트는 **첫 줄**에 이 프롤로그를 `.`(dot-source) 또는 `source`로 포함.

### 4.5 경로 자가진단 (확실)
- `scripts/doctor-paths.(ps1|sh)` 제공: ENV/디렉터리 존재/쓰기권한/슬래시 정규화/UTF-8 체크.
- CI **첫 Job**에서 Doctor 실행 → 실패 시 **즉시 중단**.

## 5) 레이아웃 & 모듈 경계 (Ports & Adapters)
- 폴더: `docs/ app/ domain/ infra/ ui/ tests/ scripts/ .github/`.
- 의존 방향: UI→App→Domain→Infra(ACL 뒤). Domain은 **포트만 의존**.

## 6) 스크립트 정책 (Idempotent · PS‑GUARD)
- 필수 스크립트: `setup‑env / run‑lint / run‑tests / run‑smoke / build / release / rollback` (OS별 확장자).
- 모든 파괴적 스크립트는 **PS‑GUARD‑BOOTSTRAP 헤더** 포함, **Dry‑Run → Confirm‑Apply** 순서.
- 공통 시작: `setup‑env` 호출 → `$env:HAN_GPT5_ROOT` 기준 상대경로 사용.

## 7) CI 파이프라인 (게이트 고정)
- 단계: **build → static‑analysis → tests → e2e‑smoke → artifact(logs) → (main) release‑notes**.
- 로컬과 CI는 **동일 스크립트** 재사용. 실패 시 **즉시 중단(Stop‑If‑Fail)**.

## 8) 테스트·품질 기준 (수치)
- Unit ≥ **85%** (코어 모듈 ≥90%), Branch ≥80%.
- Integration ≥ **75%**; E2E 핵심 시나리오 커버 ≥ **90%**, 성공률 ≥ **95%**.
- 예외/에러 경로 ≥70%; **플래키율 < 2%**. CI 총 소요 **≤ 10분**.

## 9) 로깅·진단 (JSON Lines)
- 공통 필드: `timestamp, level, traceId, module, action, inputHash, outcome, durationMs, errorCode, message` + 운영 필드(앱/버전/커밋/환경/role/step/dsl_id/latency_ms 등).
- **PII 마스킹**, 한 이벤트=한 줄, 키 순서 고정, dev 14d / prod 90d 보존.

## 10) 계약/스키마 거버넌스
- Public DTO/Schema는 **SemVer**. **Minor=additive‑only**(제거/의미 변경 금지).
- `tests/contract`에 **계약 테스트** 유지. UI 독립 검증.

## 11) 실행 프로토콜 (소배치)
- **한 PR = 한 의도**, PR ≤ 300 LOC. 하루 ≥ 1 PR 권장.
- 배치 실행: `Code‑001 → Code‑002 → …` 1번 실패 시 이후 **NOT_APPLIED**, **패치(Code‑001A)** 후 재개.

## 12) 릴리스·롤백
- **SemVer + Conventional Commits + CHANGELOG 자동화**.
- **Feature Flags** 기본 Off → 점진 노출(Canary/Blue‑Green).
- **원클릭 롤백**(불변 아티팩트, 헬스체크 게이트).

## 13) UI/사용성 불변 규칙
- 카드 헤더 규격: `STS | <해상도> | MON n` + 우측 **Role 콤보**.
- **INPUT/BUTTONS/STATUS** 3그룹은 **작게, 1열 수평 고정**. 선택 버튼은 **녹색 토글**.
- ROI 오버레이: **파란 십자(두께 2배)**, Set 시 반투명 어둡게.

## 14) 보안·“Break‑glass”
- **비상 최고권한(아이디 없이 비밀번호만)** 경로는 **기본 비활성**.
- 사용 조건: (1) 운영 중단 위험 (2) 2인 승인(사용자+GPT‑5) (3) 일회성 토큰 (4) 사후 모든 변경 **감사 로그**.

## 15) 커뮤니케이션·프롬프트 규칙
- 형식: **체크리스트/표/코드 우선**, 요약→세부.
- 프롬프트는 **[role][goal][constraints][inputs][output][verify]** 템플릿 사용.
- 근거·참조(링크/로그/스냅샷) **반드시 명시**.

## 16) 머지·릴리스 체크리스트
- **Before Commit**: 린트/포맷/단위 테스트 통과, 죽은 코드 제거.
- **Before Merge**: 커버리지·계약·E2E 게이트 통과, 로그/문서/체인지로그 갱신.
- **Before Release**: 릴리스 노트(변화/위험/롤백), 아티팩트 서명, 모니터링 임계치 설정.

## 17) 오픈 이슈/결정
- [ ] Python 3.12 대응 여부 결정(별도 브랜치 검증 후 채택)
- [ ] Linux CI job 추가 필요성 검토
- [ ] 계약 러너 고정(도구 선정)


## 18) 프로젝트 선언 지침 (v1.0)
**목표:** 선언 파일 1개로 런타임/경로/품질/릴리스 규칙을 **단일 사실의 원천(SSOT)** 으로 관리.

### 18.1 파일 & 위치 (확실)
- 파일명: `project.decl.yaml` (리포 루트, 버전 관리 포함)
- 스키마 버전: `decl_version: 1`

### 18.2 최소 스키마 (확실)
```yaml
decl_version: 1
project:
  id: han.gpt5
  name: Han GPT‑5 Conductor
  owner: STS  # 조직/팀 명시
runtimes:
  python: "3.11"
  node: "20.x"   # 확실하지 않음(필요 시)
paths:
  root_env: HAN_GPT5_ROOT
  out: out/
  logs: logs/
  cache: .cache/
  tmp: .tmp/
quality:
  coverage: { lines: 0.85, branches: 0.80 }
  e2e: { required: ["smoke_bootstrap", "release_notes_acl"] }
release:
  strategy: semver
  changelog: conventional
  ci: github-actions
security:
  pii_masking: true
  break_glass: { enabled: false }
contracts:
  schema_versioning: semver
ui:
  invariants: ["card_header_rule", "role_combo_right", "input_group_single_row"]
```

### 18.3 준수 규칙 (확실)
- 스크립트/CI는 **선언 파일만 읽어** 설정을 결정 (Assumptions 무시).
- 선언 변경은 **PR + decl_version 유지/증가**, 위험·마이그레이션 노트 동반.
- CI에 `validate-decl` 스텝을 추가해 **스키마/필수키/경로 가용성** 검사.

### 18.4 검증 유틸 (예시, 확실)
**PowerShell**
```powershell
# scripts/validate-decl.ps1
$ErrorActionPreference='Stop'
$decl = (Get-Content "$env:HAN_GPT5_ROOT/project.decl.yaml" -Raw | ConvertFrom-Yaml)
if ($decl.decl_version -ne 1) { throw 'Unsupported decl_version' }
if (-not $decl.paths.root_env) { throw 'paths.root_env required' }
$rootEnv = [Environment]::GetEnvironmentVariable($decl.paths.root_env)
if (-not $rootEnv) { throw "ENV not set: $($decl.paths.root_env)" }
$paths = @('out','logs','cache','tmp') | ForEach-Object { Join-Path $rootEnv $decl.paths.$_ }
$paths | ForEach-Object { if (!(Test-Path $_)) { New-Item -ItemType Directory -Force -Path $_ | Out-Null } }
Write-Host '[OK] declaration validated'
```
**Bash**
```bash
# scripts/validate-decl.sh
set -euo pipefail
python - <<'PY'
import os,sys,yaml, pathlib
root = os.environ.get('HAN_GPT5_ROOT')
if not root or not pathlib.Path(root).exists():
    sys.exit('HAN_GPT5_ROOT invalid')
with open(os.path.join(root,'project.decl.yaml'), 'r', encoding='utf-8') as f:
    d = yaml.safe_load(f)
assert d.get('decl_version')==1, 'Unsupported decl_version'
for k in ['out','logs','cache','tmp']:
    p = pathlib.Path(root) / d['paths'][k]
    p.mkdir(parents=True, exist_ok=True)
print('[OK] declaration validated')
PY
```

### 18.5 롤아웃 (확실)
1) `project.decl.yaml` 생성 → 2) `validate-decl` 스텝을 CI **첫 Job**에 추가 → 3) 모든 스크립트는 선언 값 우선 사용.

---

### 부록 A) 스크립트 공통 시작 예시
```powershell
# scripts/run-tests.ps1 (예)
$ErrorActionPreference='Stop'
& "$PSScriptRoot/setup-env.ps1"
$ROOT = $env:HAN_GPT5_ROOT
pwsh -NoLogo -File "$ROOT/scripts/_run_tests_core.ps1"
```

### 부록 B) setup‑env.ps1 핵심 규칙
- `.env`(있으면) 로드 → `HAN_GPT5_ROOT` 설정 → git 루트 자동탐지 → 유효성 검사 후 환경변수 확정.

---

**본 문서는 v0.3‑draft입니다. 충돌·누락 사항 제보 시 즉시 반영합니다.**
프로젝트 진행중에 경험(프로그램 버전, 환경, 쉘 환경, 쉘 오류 등등)을 프로젝트에 문서를 만들어, 경험을 습득해 동일 환경 유지, 반복 오류를 방지 한다.

