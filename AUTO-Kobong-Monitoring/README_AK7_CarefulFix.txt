AK7 Careful Fix – 5193 Cleanup (Safe & Minimal)
=================================================

목표
----
- AK7 페이지에서 남아있는 5193/5183 레거시(ORCHMON용)를 **/api/ak7 범위에서만** 5191/5181로 안전히 정리합니다.
- UI의 Overview/Settings 표시 불일치(DEV 5183, MOCK 5193 표기)를 AK7 기준(5181/5191)으로 자동 교정합니다.
- 다른 기능 영향 최소화를 위해 **보수적 기준**으로만 수정합니다.

사용법
------
1) 서버에서 PowerShell 7로 실행:
   ```powershell
   # DryRun (미적용, 영향도 리포트)
   .\AK7_CarefulFix.ps1 -Root "D:\ChatGPT5_AI_Link\dosc\Kobong-Orchestrator-VIP\AUTO-Kobong-Monitoring\webui" -DryRun

   # 실제 적용
   .\AK7_CarefulFix.ps1 -Root "D:\ChatGPT5_AI_Link\dosc\Kobong-Orchestrator-VIP\AUTO-Kobong-Monitoring\webui"
   ```

2) 적용 후 확인 (브라우저 새로고침)
   - Settings 탭: `AK7_API_BASE`가 `http://localhost:5181/api/ak7` 또는 `http://localhost:5191/api/ak7`인지 확인
   - Overview 카드: "컨테이너(DEV/5181 · MOCK/5191)"로 보정되어 표기되는지 확인
   - Summary 테이블: DEV/5181, MOCK/5191 행과 URL이 맞는지 확인
   - 상단 서비스 행: `data-svc="AK7"` 및 첫 번째 셀 텍스트 `AK7`으로 표기되는지 확인
   - 콘솔: `[AK7] port-rewrite shim active` / `[AK7] DOM-fix applied` 로그 확인

보수적 안전장치
---------------
- **치환 범위 한정**: `/api/ak7` 문자열이 포함된 파일만 대상으로 합니다.
- **포트 교정 제한**: `/api/ak7` 경로에만 5193→5191, 5183→5181 교정. `/api/orchmon` 등 타 서비스는 건드리지 않습니다.
- **UI 보정만 적용**: ORCHMON → AK7 변경은 UI 텍스트/속성에 한정. CSS 클래스(`orch-*`)는 유지하여 스타일 영향 최소화.
- **백업 자동 생성**: 실행 시 `webui_backup_YYYYMMDD_HHMMSS` 폴더로 전체 백업 후 수정합니다.

롤백
----
- 적용 직후 문제가 있으면, 백업 폴더로 원복하면 됩니다.
