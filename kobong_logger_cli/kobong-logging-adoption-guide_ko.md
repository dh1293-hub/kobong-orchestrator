# 코봉 로깅 컨트랙트 도입 가이드 (v1)

본 문서는 **다른 프로젝트**에서 `kobong-logging` 번들을 손쉽게 적용하고,
컨트랙트 테스트까지 자동화하는 절차를 정리했습니다. 대상 독자는 **개발자 + GPT‑5 보조자**입니다.

---

## 빠른 시작 (요약)

**방법 A — 원클릭 올인원 EXE (권장)**
1. `KobongLoggerSetup.exe` 파일을 **대상 프로젝트 루트**에 복사
2. 더블클릭 실행 (또는)
   ```powershell
   pwsh -NoProfile -ExecutionPolicy Bypass -File .\KobongLoggerSetup.exe
   ```
3. 자동으로 설치 → UTF‑8(no BOM) 정규화 → venv + `pytest` 실행  
   성공 시 `.......` 후 `pytest exit code = 0 (OK)` 표시

**방법 B — 번들 ZIP + 설치 스크립트**
1. (제공됨) `kobong-logging-bundle.zip` 과 `scripts\install-logging-bundle.ps1`
2. 대상 프로젝트 루트에서:
   ```powershell
   pwsh -NoProfile -ExecutionPolicy Bypass `
     -File .\scripts\install-logging-bundle.ps1 `
     -Bundle ".\kobong-logging-bundle.zip" -Target "." `
     -WithActions -Renormalize
   ```
3. 테스트 통과 확인

---

## 번들에 포함되는 것

```
infra/logging/json_logger.py              # Python 로거(PII/Secret 마스킹 포함)
infra/__init__.py
infra/logging/__init__.py
domain/contracts/logging/v1.schema.json   # JSON 스키마(컨트랙트)
tests/contract/test_logging_contract.py   # 컨트랙트 테스트
scripts/setup-env.ps1                     # venv + 의존성 설치
scripts/run-contract-tests.ps1            # 컨트랙트 테스트 실행
requirements.contract-tests.txt           # pytest/jsonschema 등
.gitattributes                            # EOL 정책 (LF 기본)
```

> 모든 텍스트 파일은 **UTF‑8 (no BOM)** 로 기록됩니다.

---

## 실제 앱에서 사용하기 (예시)

```python
# app/service.py
from infra.logging.json_logger import JsonLogger
import json, os

log = JsonLogger(env=os.getenv("APP_ENV", "prod"))

def do_work(user_email: str, token: str):
    rec = log.log(
        level="INFO", module="billing", action_step=2,
        message=f"charge user {user_email} with api_key: {token}",
        result_status="ok", result_code=0
    )
    # JSON Lines로 저장
    with open("logs/app.jsonl", "a", encoding="utf-8") as f:
        f.write(json.dumps(rec, ensure_ascii=False) + "\n")
```

- 이메일/키 등 민감정보는 자동으로 `[MASKED_EMAIL]`, `[MASKED_TOKEN]` 으로 마스킹됩니다.
- `tz`는 기본 `Asia/Seoul`, `app.name/ver/commit`은 환경변수(`APP_VER`, `APP_COMMIT`)로 주입 가능.

---

## 컨트랙트 테스트 수동 실행

```powershell
pwsh -File .\scriptsun-contract-tests.ps1
# 또는
if (Test-Path '.venv\Scripts\python.exe') { $py = '.venv\Scripts\python.exe' } else { $py = 'python' }
& $py -m pytest -q tests/contract
```

성공: `.......` + `2 passed` + `pytest exit code = 0 (OK)`

---

## CI 연동 (GitHub Actions)

옵션 `-WithActions` 로 설치 시 `.github/workflows/contract-tests.yml` 이 생성됩니다.
기본 파이썬 3.11, `APP_TZ=Asia/Seoul`, `pytest -q tests/contract` 실행.

---

## 실행 정책(Execution Policy) 이슈 해결

서명이 없을 때는 아래 중 하나로 실행하세요.

```powershell
# 1) 1회성 우회(권장)
pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\install-logging-bundle.ps1 ...

# 2) 파일 차단 해제 후 실행
Unblock-File -LiteralPath .\scripts\install-logging-bundle.ps1
pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\install-logging-bundle.ps1 ...
```

조직 정책이 `AllSigned`면, 로컬 코드서명 인증서로 서명하여 실행하세요.

---

## 자주 만나는 에러 & 해결법

### 1) `JSONDecodeError: Unexpected UTF-8 BOM`
- 원인: 스키마(`v1.schema.json`)에 **BOM**이 붙은 경우
- 해결:
  ```powershell
  $p = 'domain\contracts\logging1.schema.json'
  $t = Get-Content -LiteralPath $p -Raw
  [IO.File]::WriteAllText($p, $t, (New-Object System.Text.UTF8Encoding($false)))
  ```

### 2) `SecurityError: ... is not digitally signed`
- 실행 정책 우회: `-ExecutionPolicy Bypass` 또는 `Unblock-File` 사용

### 3) PowerShell 5.1에서 작성 파일이 BOM 포함으로 저장됨
- `Set-Content -Encoding utf8`(PS5.1)는 **BOM 포함**
- 항상 아래 방식으로 기록:
  ```powershell
  [IO.File]::WriteAllText($Path, $Content, (New-Object System.Text.UTF8Encoding($false)))
  ```

### 4) IExpress SFX 빌더 오류: *There is no SourceFiles specified...*
- `SED`에 `SourceFiles=SourceFiles` 및 파일 목록 누락
- SED 생성부를 다음과 같이 구성해야 함:
  ```ini
  SourceFiles=SourceFiles
  [SourceFiles]
  SourceFiles0=C:\absolute\path\to\sfx-work
  [SourceFiles0]
  run.cmd=
  install-logging-bundle.auto.ps1=
  kobong-logging-bundle.zip=
  ```

### 5) `.gitattributes`/EOL 경고
- 설치 스크립트가 `git add --renormalize .` 를 수행할 수 있음
- 경고 메시지는 정상적인 리노멀라이즈 과정이며, 커밋으로 마무리

---

## 롤백/삭제

- 파일 삭제: `infra/logging`, `domain/contracts/logging`, `tests/contract`, `scripts/{setup-env,run-contract-tests}.ps1`, `requirements.contract-tests.txt` 및 관련 변경 커밋을 되돌립니다.
- venv 제거(선택): `.venv` 폴더 삭제

---

## GPT‑5에 전달할 안내 멘트(복붙용)

> “프로젝트 루트에 `KobongLoggerSetup.exe`를 놓고 실행해 주세요. 실행 정책 문제는 `-ExecutionPolicy Bypass`로 우회 가능합니다. 완료 후 `scriptsun-contract-tests.ps1`를 한 번 더 실행해 녹색(`2 passed`)인지 확인해 주세요. 만약 BOM 오류가 나오면 스키마 JSON을 UTF‑8(no BOM)으로 재저장하면 됩니다.”

---

## 변경 이력
- v1: 최초 배포 — EXE(원클릭), 번들 ZIP 설치, 테스트/CI, 트러블슈팅 정리.