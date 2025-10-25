15) SECURITY.md 템플릿 (복붙 사용)

아래 전체를 저장소의 루트 / .github/ / docs/ 중 한 곳에 SECURITY.md 파일로 추가하세요.

# Security Policy — kobong-orchestrator & Monitors


## Supported Versions
| Version | Supported |
|--------:|:---------:|
| v1.x | ✅ Full support |
| v0.x | ⚠️ Critical/High security fixes only |
| < v0.1 | ❌ End of life |


> 이 표는 릴리즈 정책에 맞춰 갱신합니다. (예: `v0.1.99` → v1.0 전환 시 업데이트)


## Reporting a Vulnerability
- **공개 이슈 생성 금지.** 아래 비공개 채널을 사용하세요.
- **GitHub Security ↗ “Report a vulnerability”**(권장)
- 또는 이메일: **security@kobong.example** (프로젝트 전용, 임시/예시 주소)
- 포함 정보: 영향 버전/커밋, 재현 절차(PoC), 예상 영향, 로그 일부(민감정보 마스킹), **CVSS v3.1 벡터**(알고 있을 경우), 연락 수단.


## Disclosure & SLA
- **수신 확인**: 48시간 이내(KST)
- **트리아지**: 72시간 이내(심각도/재현성 평가)
- **수정 목표**: Critical 7일 / High 30일 / Medium 90일 / Low Best‑effort
- 적합 시 **GHSA/CVE** 발급 또는 연동, 사전 합의된 시점에 공개 공지(릴리즈 노트·어드바이저리). 공로 표기(요청 시 익명).


## Keys & Secrets (회전 정책)
- 범위: **GitHub App Private Key**, **Webhook Secret**, **Fine‑grained PAT/Actions Token**, 배포용 키(환경변수/시크릿 스토어)
- **정기 로테이션**: 90일(권장), **Grace 7일**. 노출 징후 시 즉시 로테이션·권한 최소화.


## In/Out of Scope
- **In**: `dh1293-hub/kobong-orchestrator` 및 연동 모듈(GHMON/AK7) 코드·워크플로우·릴리즈 산출물
- **Out**: DoS/리소스 고갈, 물리·사회공학, 제3자 서비스 고유 취약점, 이미 알려진 이슈의 중복 제보


## Safe Harbor
- 선의의 연구를 환영합니다. 데이터 유출/사생활 침해 없이, 필요한 최소 범위 내 테스트만 수행해 주세요. 시스템 가용성 저하를 유발하지 말아 주세요.
- 본 정책을 준수한 테스트에 대해서는 법적 조치를 취하지 않습니다.


## Dependencies
- 서드파티 종속 취약점은 **상류(Upstream)에 보고**해 주세요. 이 저장소는 **Dependabot/Advisories** 알림을 추적합니다.
- 이미 수정된 취약점 제보 시, 최신 릴리즈로 재현 가능한지 확인 후 알려 주세요.