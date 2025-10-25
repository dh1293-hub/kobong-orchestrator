
# GitHub Monitoring — Min Pack (DEV 5182, UI 5199)

- UI: `webui/GitHub-Monitoring-Min.html` (정적 파일, 또는 UI 컨테이너 5199로 서빙)
- API/WS MOCK: Windows Containers Node 서버 5182 (`containers/GitHub-Mon-shells`)

## 빠른 시작 (Windows Containers)
1) **UI** (5199):  
```
pwsh -File scripts/g5/ui/deploy-GitHub-Mon-ui.ps1
```
→ http://localhost:5199/

2) **API/WS** (5182):  
```
pwsh -File scripts/g5/shells/run-GitHub-Mon-shells-win.ps1
```
→ 헬스 OK 후, UI에서 **Settings → API Base** 에 `http://localhost:5182/api/ghmon` 입력 → **적용**

3) **오프라인 데모**: UI HTML 상단 스크립트에서 `window.GHMON.FORCE_OFFLINE=true` 설정 시, 서버 없이도 더미 이벤트로 동작.

## 표준/원칙(발췌)
- data-ghmon-* 셀렉터, 8버튼( next/stop/fix-preview/fix-apply/good/rollback/shell-open/logs-export ), /health 게이트, KLC 토스트 4요소(traceId/durationMs/exitCode/anchorHash) 준수.
- DEV=5182 / MOCK=5192 (본 팩은 요청에 따라 UI=5199를 추가).

## 파일 구조
- webui/…: 정적 UI (큰 글씨/고대비/44×44)
- containers/GitHub-Mon-shells: 5182 API/WS
- containers/GitHub-Mon-ui: 5199 정적 UI
- scripts/g5/: 빌드/실행/정지 PowerShell 7 스크립트
- logs/, docs/: 자리표시자

