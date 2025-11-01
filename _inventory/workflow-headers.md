# Workflow Header Comments

> Generated @ 2025-11-01 18:24:08+00:00 (`.github/workflows only, exclude=inventory-ci.yml`)

## `.github/workflows/ak-apply.yml`

```text
ak-apply.yml — 주석판(가시 영역 기준)  / by GPT‑5
파일: .github/workflows/ak-apply.yml
제목: AK Apply (manual & merge)
목적:
- 수동(workflow_dispatch) 실행으로 AK 계열 작업(rewrite|fix|test)을 돌리고 산출물(로그)을 남김
- PR이 main에 "머지되어 닫힘(closed & merged==true)"일 때 자동 실행
- (선택) workflow_dispatch 실행 시 지정한 PR 번호에 결과 요약 Tail(80줄)을 코멘트로 회신
근거(우리 운영 표준):
- PS7 우선, StrictMode + -ErrorAction Stop (PowerShell7_Guidelines_Kobong_v1.1.md)
- Dry-Run → Apply 2단계 / GOOD 슬롯 롤백(ROLLBACK_POLICY.md, ROLLBACK_POLICY_MANUAL.md)
- KLC 1행 로그( traceId, durationMs, exitCode, anchorHash ) 기본
- 아티팩트/요약 보존, 브랜치 보호·필수 체크와 함께 운용
사용법:
- Actions > AK Apply (manual & merge) > Run workflow
· cmd: rewrite|fix|test (기본 fix)
· ref: 실행 기준 git ref (기본 main)
· pr:  회신할 PR 번호(선택)
· apply: 수동 실행 시 실제 적용(Apply)까지 수행할지 여부 (기본 false=Dry-Run만)
연관 파일/스크립트(예):
- scripts/g5/apply-patches.ps1  # 저장소 스크립트 경로에 맞게 조정 필수
산출물:
- artifacts: ak-apply-logs → .ak-out.txt, logs/ak7.jsonl
- (옵션) PR 코멘트: 마지막 80줄 Tail
```

## `.github/workflows/ak-auto.yml`

```text
=========================================================
파일 용도 : PR 라벨 기반 자동 파일럿
Help → Test → Scan(--all) → Fixloop preview → (조건) Apply
동작 방식 : pull_request_target(labeled/opened/reopened/synchronize),
또는 workflow_dispatch(pr 입력)
연관 파일 : scripts/g5/ak-dispatch.ps1
안전 가드 : - PR 코드는 zipball로 받고, 실행 스크립트는 항상 main에서 하이드레이트
- Apply는 ak:auto-apply 라벨 + OWNER일 때만
산출물    : PR 코멘트(요약), Artifact: ak7-logs (logs/ak7.jsonl)
상태 라벨 : ak:stage:test-ok / ak:stage:scan-ok / ak:stage:preview-ok
=========================================================
```

## `.github/workflows/ak-commands.yml`

```text
=========================================================
파일 용도 : ChatOps 수동 실행기 (/ak ...)
트리거   : PR 코멘트(issue_comment) 또는 Actions 수동(workflow_dispatch)
동작 흐름 : 입력 파싱 → PR 헤드 체크아웃 → scripts/g5 하이드레이트(main) → 디스패치 실행
산출물   : PR 코멘트(시작/요약) + Artifact: logs/ak7.jsonl
주의     : checkout.ref는 1회만 지정, 콜론이 있는 step name은 모두 인용(따옴표)
=========================================================
```

## `.github/workflows/ak-dispatch.yml`

```text
===========================================
파일: .github/workflows/ak-dispatch.yml
목적: 수동(workflow_dispatch)으로 "AK" 명령들을 실행하는 디스패처.
- git 없이(zipball) 로컬 커스텀 액션(.github/actions) 부트스트랩
- zip-fetch 로 원하는 ref(sha) 소스 전개
- scripts/g5/ak-dispatch.ps1 실행(/ak scan|test|rewrite|fix|help)
- 로그 아티팩트 업로드 + (선택) PR 코멘트
운영 강화(축소 없음):
* concurrency 취소, timeout, Job Summary, PR 코멘트 실패 무해화, 전역 pwsh 고정
===========================================
```

## `.github/workflows/ak-exec.yml`

```text
=========================================================
파일 용도 : PR 코멘트의 /ak 명령(또는 수동 입력)으로 단일 단계 실행
동작 방식 : issue_comment(created), 또는 workflow_dispatch(pr/command/rawargs)
연관 파일 : scripts/g5/ak-dispatch.ps1
안전 가드 : - PR 코드는 zipball로 받고, 실행 스크립트는 main에서 하이드레이트
- 명령 파싱은 /ak <cmd> [raw args] 형태
산출물    : PR 코멘트(시작/요약), Artifact: ak7-logs
=========================================================
```

## `.github/workflows/ak-loop.yml`

```text
=========================================================
파일 용도 : 전자동 협업 루프(Closed-Loop) 보강
- PR 라벨 신호를 감지해 다음 단계 ChatOps 명령(/ak ...) 코멘트 자동 발사
동작 방식 : pull_request.labeled 트리거
- PR에 ak:auto-loop 라벨이 있어야 작동
- 추가된 라벨에 따라 다음 명령을 코멘트로 전송
연관 파일 : .github/workflows/ak-commands.yml, ak-auto.yml, ak-apply-gate.yml
안전 가드 : 숨은 토큰으로 중복 방지, OWNER+ak:auto-apply 조합에서만 apply 시도
산출물    : PR 코멘트(자동 발사된 /ak 명령)
=========================================================
```

## `.github/workflows/ak-run.yml`

```text
===========================================
파일: .github/workflows/ak-run.yml
목적: 이슈/PR 댓글에서 "/ak ..." 명령을 감지하여
디스패처 워크플로(ak-dispatch.yml)를 안전하게 호출하는 게이트웨이.
핵심:
- issue_comment(created) 트리거
- 작성자 권한 가드(OWNER/MEMBER/COLLABORATOR만 허용)
- PR인 경우 헤드 SHA/브랜치 추출 → 디스패처에 정확히 전달
- 동시성/취소/타임아웃/권한 최소화/요약/아티팩트
참고:
- 실제 /ak 명령 실행(스캔/수정 등)은 ak-dispatch.yml + scripts/g5/ak-dispatch.ps1에서 수행
===========================================
```

## `.github/workflows/ak-script-headers.yml`

```text
AK • Script Headers → Repo(_inventory) + Wiki   #주석(친절한)
목적: scripts/g5/**/*.ps1 파일들의 "머리 주석"만 수집하여
1) 레포의 _inventory/script-headers.md 로 저장(커밋/푸시)
2) Wiki의 Script-Header-Comments.md 로도 반영(커밋/푸시)
규칙:
- 대상: scripts/g5/**/*.ps1
- 머리 주석 없는 스크립트는 제외
- 머리 주석 패턴: 연속 '#' / 펜스 블록 ```...``` / PowerShell 블록 <#...#>
- 출력은 모두 ```text 코드블록으로 렌더(문자 크기/굵기 통일)
실행 트리거:
- 수동 실행(workflow_dispatch)
- 스크립트/수집기 변경 push 시 자동 실행
권한:
- contents: write (레포/위키 커밋/푸시)
```

## `.github/workflows/ak-selftest.yml`

```text
=========================================================
파일 용도 : scripts/g5/* 변경 시
1) PowerShell 정적 점검(PSScriptAnalyzer)
2) 스모크 실행(ak-dispatch.ps1 -Command help)
동작 방식 : push/pull_request 경로 필터(워크플로 변경 포함) + 수동 실행
연관 파일 : .github/workflows/ak-commands.yml, ak-auto.yml, scripts/g5/ak-dispatch.ps1
안전 가드 : PSGallery 장애 시에도 "문법 분석 폴백"으로 진행(의미있는 실패만 fail)
산출물    : Job Summary/콘솔 로그, artifacts/pssa-findings.txt
=========================================================
```

## `.github/workflows/ak-workflow-headers.yml`

```text
AK • Workflow Headers → Repo(_inventory) + Wiki  #주석(친절한)
목적: .github/workflows의 "머리 주석"만 수집하여
1) 레포의 _inventory/workflow-headers.md 로 저장(커밋/푸시)
2) Wiki의 Workflow-Header-Comments.md 로도 반영(커밋/푸시)
규칙:
- inventory-ci.yml 제외
- 머리 주석 없는 워크플로는 목록에서 제외
- 머리 주석 패턴: 시작부 연속 '#' 또는 시작~끝을 ```로 감싼 펜스 블록
- 출력은 모두 ```text 코드블록으로 렌더(문자 크기/굵기 통일)
실행 트리거:
- 수동 실행(workflow_dispatch)
- 워크플로/YAML/스크립트 변경 push 시 자동 실행
안전장치:
- contents: write 권한 필요
- push 트리거는 .github/workflows/** 와 스크립트만 감지 → _inventory 변경으로 자기재실행 방지
```

## `.github/workflows/ak-workflow-inventory.yml`

```text
AK • Workflow Inventory (frozen rules)
- 목적: 루트 ".github/workflows"의 YML을 스캔해, "주석 제외 + 단일 파일 경로만"을 _inventory/workflows.txt 로 산출
- 규칙: inventory-ci.yml 제외, 파일명 토큰도 해석, 반복 루프 -ScanDepth 지원(기본 1)
- 러너: ubuntu-latest (pwsh 사용) — 로컬과 동일 로직 유지
```

## `.github/workflows/auto-github-release.yml`

```text
파일: .github/workflows/auto-github-release.yml
목적: 태그 push(`v*`) 또는 수동 실행 시 GitHub Release를 자동 생성/갱신하고 릴리스 노트를 자동 생성한다.
핵심:
- generate_release_notes: true (PR/커밋 기반 자동 릴리스 노트)
- 필요 시 산출물(dist/** 등) 첨부
트리거:
- push.tags: v*    # v1.2.3 형식 권장(semver)
- workflow_dispatch(tag 입력 지원)
사용법:
- 태그 배포:  git tag v1.2.3 && git push origin v1.2.3
- 수동 배포:  Actions → 이 워크플로 → Run workflow → tag 입력
권한(최소 권한 원칙):
- permissions.contents: write (Release 작성/갱신에 필요)
보안 가드:
- 포크/외부 이벤트 차단: jobs.if에서 저장소 일치 확인
- 동시 실행 방지: concurrency (동일 태그 중복 배포 차단)
- 태그 유효성 검사: semver(vX.Y.Z[-pre]) 아닌 경우 실패 처리
- checkout 시 persist-credentials: false (토큰 확산 방지)
- (선택) prerelease 자동 판별: 태그에 '-' 포함 시 prerelease=true
산출물/연동:
- GitHub Release(노트/자산)
- (선택) _inventory에 릴리스 리스트를 따로 수집하는 스크립트와 함께 운용
롤백:
- 잘못된 릴리스/태그는 GitHub에서 릴리스 삭제 → 태그 수정 후 재실행
변경 이력(작성자/일시/사유): 
- 2025-11-01: 보안 보강(permissions/concurrency/semver/포크가드), 머리 주석 추가
```

## `.github/workflows/guard-flush-queue.yml`

```text
NO-SHELL
```

## `.github/workflows/housekeeping-smoke.yml`

```text
.github/workflows/housekeeping-smoke.yml
목적: 주간/수동/PR 트리거로 하우스키핑 스모크 실행 → 요약을 PR(또는 고정 이슈)에 코멘트, 아티팩트/Job Summary로도 보존.
```

## `.github/workflows/post-release-canary.yml`

```text
파일: .github/workflows/post-release-canary.yml
목적: 릴리즈(Publish) 직후 또는 외부 배포 신호(repository_dispatch: deploy) 이후
프로덕트 헬스(/health 등)를 빠르게 확인하는 "포스트 릴리즈 카나리".
실패 시 자동으로 Incident 이슈를 생성하여 신속 대응을 유도.
```

## `.github/workflows/psanalyze.yml`

```text
=========================================================
파일 용도 : PowerShell 스크립트 정적 점검(PSScriptAnalyzer) + 폴백(문법 전용)
동작 방식 : PR/수동 실행 시 레포 소스를 Zipball로 받고 scripts/g5 하위 검사
연관 파일 : scripts/g5/*  (ak-selftest.yml의 보조 분석기로 병행 운용)
안전 가드 : Git 미사용(Zipball), PSGallery(v3→v2) 다중 재시도, 갤러리 장애 시 문법 분석 폴백
산출물    : artifacts/pssa-findings.txt
=========================================================
```

## `.github/workflows/wf-allround-tester.yml`

```text
파일: .github/workflows/wf-allround-tester.yml
목적: 저장소 내 워크플로를 전수 수집(인벤토리) → 안전 스모크(Dispatch/PR/댓글) → 결과 요약(MD/CSV/JSON) →
_inventory 반영용 PR 자동생성까지 원샷으로 수행.
트리거:
- 수동: workflow_dispatch (옵션 플래그)
- 자동: .github/workflows/** 변경 시(push/pr) 실행
보안/가드:
- permissions 최소화(필요 범위만 write)
- concurrency 중복 실행 방지
- github-actions[bot] 루프 방지(if)
YAML 작성 규칙:
- 탭(\t) 금지, 들여쓰기는 스페이스 2칸
- 셸 스크립트는 반드시 run: | (블록 스칼라) 사용
- run: | 아래의 #은 PowerShell 주석(실행되지 않음)
```

## `.github/workflows/xp-summary-artifact.yml`

```text
NO-SHELL
```

