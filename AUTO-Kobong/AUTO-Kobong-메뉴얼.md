
# AUTO‑Kobong 메뉴얼 (초보 전자동)
> 마지막 업데이트: 2025-09-28 00:41 (KST 기준 느낌으로 사용)

이 문서는 **완전 초보 기준**으로, 복붙만으로 AUTO‑Kobong을 쓰기 위한 모든 내용을 담았습니다.  
현재 구성은 **DEV(24시간 허용)** 모드이며, `apply`는 **OWNER 전용**입니다.

---

## 0. 한 줄 요약
- 자동 실행: PR 라벨 **`ak:auto`** → Help→Test→Scan→Preview 전자동
- 자동 적용: PR 라벨 **`ak:auto-apply`** → (DEV 24h) OWNER일 때 자동 적용
- 수동 컨트롤: PR 댓글에 `/ak ...` (예: `/ak version`, `/ak test`, `/ak fixloop preview`)
- 버전 확인: `/ak version` → 현재 워크플로 해시/상태 빠르게 확인

---

## 1. 설치 확인 (워크플로 3종)
리포에 아래 3개 파일이 있어야 합니다.
- `.github/workflows/ak-commands.yml` — 댓글 기반 실행
- `.github/workflows/ak-auto.yml` — 라벨 기반 전자동 실행
- `scripts/g5/ak-dispatch.ps1` — 명령 디스패처(PS7)

확인: PR에 `/ak version` 댓글 → 성공 댓글/요약이 뜨면 OK.

---

## 2. 자동 모드(라벨만 달면 끝)
```powershell
$PR=186      # 대상 PR 번호로 바꿔서 사용
gh pr edit $PR --add-label "ak:auto"         # 전자동 Help→Test→Scan→Preview
gh pr edit $PR --add-label "ak:auto-apply"   # (DEV) OWNER이면 자동 적용까지
```
실행 현황은 Actions 탭 또는 PR 하단 요약댓글의 **Run/Checks 링크**로 확인합니다.

중단: 라벨 제거
```powershell
gh pr edit $PR --remove-label "ak:auto-apply" --remove-label "ak:auto"
```

---

## 3. 수동 모드(댓글로 조작)
자주 쓰는 명령:
```
/ak help
/ak version
/ak test
/ak scan --all
/ak fixloop preview    # 항상 초록(안전)
/ak fixloop apply      # OWNER 전용, DEV 24h 허용
```
프리뷰는 항상 **성공(초록)** 으로 처리되어 체크가 깨지지 않습니다.

---

## 4. DEV(24시간) ↔ PROD(야간가드) 모드
- 지금은 **DEV(24h 허용)** 으로 설정됨.  
- 운영 전환 시에는 `ak-commands.yml` / `ak-auto.yml`의 야간가드 스텝을 켜서 **00–07 KST 차단**을 활성화하세요. (완성본 토글 파일은 추후 제공 가능)

---

## 5. 흔한 오류 & 빠른 해결
### A) “could not find any workflows named ak-commands”
```powershell
# 이벤트 기준으로 최근 런 열기(튼튼)
$run = gh run list --event issue_comment --json databaseId -q '.[0].databaseId'
if($run){ gh run view $run --web }

# 파일명으로 찾기
$run = gh run list --workflow "ak-commands.yml" --json databaseId -q '.[0].databaseId'
if($run){ gh run view $run --web }

# 워크플로 ID로 찾기
$wfId = gh workflow list --json name,path,id -q '.[] | select(.path==".github/workflows/ak-commands.yml") | .id'
$run  = gh run list --workflow $wfId --json databaseId -q '.[0].databaseId'
if($run){ gh run view $run --web }
```

### B) “Protected branch update failed (GH006)”
- `main`이 보호됨 → **항상 PR을 통해 변경**해야 합니다.
- 절차: 새 브랜치 푸시 → PR 생성 → **필수 체크** 통과 → 스쿼시 머지.

### C) “exit code 2” 때문에 실패
- 프리뷰는 **무조건 성공 처리**(잡 초록).  
- 비치명 코드(`<10`)는 **정규화**로 성공 처리.

### D) “라벨이 없다”
```powershell
gh label create "ak:auto"          --color "22c55e" --description "자동 실행"        2>$null
gh label create "ak:auto-apply"    --color "ef4444" --description "자동 적용"        2>$null
gh label create "ak:enabled"       --color "0ea5e9" --description "/ak 허용"        2>$null
gh label create "ak:night-override"--color "f59e0b" --description "야간 강제 허용"   2>$null
```

---

## 6. 복구 / 롤백(안전)
- 변경 전 **백업**:  
  ```powershell
  $ts = Get-Date -Format 'yyyyMMdd-HHmmss'
  Copy-Item .github/workflows/ak-commands.yml ".github/workflows/ak-commands.yml.bak-$ts"
  Copy-Item scripts/g5/ak-dispatch.ps1 "scripts/g5/ak-dispatch.ps1.bak-$ts"
  ```
- 문제 발생 시 **되돌리기**: 백업 복원 → PR로 메인 반영.

---

## 7. 단축 명령(선택)
```powershell
$PR=186
function ak { param([Parameter(Mandatory=$true)][string]$Body) gh pr comment $global:PR --body $Body }
function ak:smoke { ak "/ak help"; ak "/ak test"; ak "/ak scan --all"; ak "/ak fixloop preview" }
function ak:ver { ak "/ak version" }
```

---

## 8. 보호(삭제/수정 차단)
1) 워크플로 **Protect Manual** 추가: `.github/workflows/protect-manual.yml` (아래 파일 사용)  
2) **필수 체크**로 등록: GitHub → Settings → Branches → main 보호 규칙에서 _Require status checks_ 에 **Protect Manual** 추가  
3) (선택) CODEOWNERS로 `AUTO-Kobong/` 경로 수정 시 OWNER 리뷰 필수

> UI가 번거로우면, 체크 이름이 반드시 `Protect Manual`로 표시되도록 워크플로를 그대로 써주세요.

---

## 9. 변경 이력 (기능 추가 시 여기에 한 줄씩 누적)
| 일시(KST) | 변경 내용 | 관련 PR/커밋 |
|---|---|---|
| 2025-09-28 00:41 | 초기 작성: DEV 24h, 라벨 전자동, 댓글 수동, 보호 워크플로 가이드 |  |

---

## 부록: 파일 위치
- 메뉴얼: `AUTO-Kobong/AUTO-Kobong-메뉴얼.md` (이 파일)  
- 보호 워크플로: `.github/workflows/protect-manual.yml`

**끝. 복붙만 하세요.**
