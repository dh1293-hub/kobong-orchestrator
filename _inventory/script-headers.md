# Script Header Comments (scripts/g5)

> Generated @ 2025-11-01 18:54:26+00:00 (`scripts/g5/**/*.ps1`, head comments only)

## `scripts/g5/ak-audit.ps1`

```text
requires -PSEdition Core
requires -Version 7.0
```

## `scripts/g5/ak-checks.ps1`

```text
requires -PSEdition Core
requires -Version 7.0
```

## `scripts/g5/ak-dispatch.ps1`

```text
파일: scripts/g5/ak-dispatch.ps1
목적:
AK 디스패처. GitHub Actions에서 수동(workflow_dispatch) 호출로
/ak scan | /ak test | /ak rewrite | /ak fix | /ak help 실행.
- scan    : .github/workflows/*.yml에서 흔한 오류 패턴 탐지(읽기 전용)
- test    : scan과 동일하되 WARN도 실패(엄격 모드)
- rewrite : 안전한 멱등 자동 수선(… 제거, 잘못된 '- permissions|concurrency:' 교정 등)
- fix     : rewrite 후 재스캔, 남은 문제 있으면 실패
산출물:
- 콘솔 요약 + 상세 목록
- _deploy/logs/ak-dispatch-YYYYMMDD_HHMMSS.log (실행 로그)
- KLC 1행 로그: KLC|ak-dispatch|cmd=...|ok=..|warn=..|fail=..|sha=...|run=...|attempt=...
사용:
pwsh -NoProfile -File scripts/g5/ak-dispatch.ps1 -Command help
pwsh -NoProfile -File scripts/g5/ak-dispatch.ps1 -Command scan|rewrite|fix [-Pr 579] [-Sha <sha>]
주의:
- 이 파일에는 diff 표식(+/-/@@/---/+++)이 있으면 안 됩니다. (복붙 시 꼭 확인)
```

## `scripts/g5/ak-fixloop.ps1`

```text
APPLY IN SHELL
requires -Version 7.0
```

## `scripts/g5/ak-fmt.ps1`

```text
requires -PSEdition Core
requires -Version 7.0
```

## `scripts/g5/ak-label.ps1`

```text
requires -PSEdition Core
requires -Version 7.0
```

## `scripts/g5/ak-lint.ps1`

```text
requires -PSEdition Core
requires -Version 7.0
```

## `scripts/g5/ak-merge.ps1`

```text
requires -PSEdition Core
requires -Version 7.0
```

## `scripts/g5/ak-protect.ps1`

```text
requires -PSEdition Core
requires -Version 7.0
```

## `scripts/g5/ak-release.ps1`

```text
requires -PSEdition Core
requires -Version 7.0
```

## `scripts/g5/ak-rerun.ps1`

```text
requires -PSEdition Core
requires -Version 7.0
```

## `scripts/g5/ak-rewrite.ps1`

```text
APPLY IN SHELL
requires -Version 7.0
```

## `scripts/g5/ak-status.ps1`

```text
requires -PSEdition Core
requires -Version 7.0
```

## `scripts/g5/apply-patches.ps1`

```text
=====================================================================
  파일: scripts/g5/apply-patches.ps1
  목적: manifest 기반 패치를 DryRun/Apply로 실행하고
        콘솔·JSONL 로그를 남기는 표준 운용 스크립트
  사용법(로컬):
    # DryRun (종료코드 11)
    pwsh -NoProfile -File scripts/g5/apply-patches.ps1 -DryRun `
      -Root . -Manifest patches/manifest.json `
      -OutText .ak-out.txt -OutJson logs/ak7.jsonl

    # Apply (종료코드 0)
    pwsh -NoProfile -File scripts/g5/apply-patches.ps1 `
      -Root . -Manifest patches/manifest.json `
      -OutText .ak-out.txt -OutJson logs/ak7.jsonl

  CI(GitHub Actions) 자동 보호:
    - CI에서는 .ak-out.txt에 직접 쓰지 않음(콘솔만 출력).
      => 워크플로의 Tee-Object가 파일을 "단독"으로 잡음 → 잠금 충돌 제거.
    - 별도 설정 불필요. (AK_TEE=1 있으면 동일하게 우선 적용)

  종료코드:
    0  = Apply 성공
    11 = DryRun 정상 종료
    1  = 일반 오류

  연관 파일:
    - .github/workflows/ak-apply.yml (이 스크립트를 호출)
    - patches/manifest.json         (패치 정의)
    - logs/ak7.jsonl                (JSON Lines; 분석/보관)

  테스트:
    1) CI에서 재실행 → .ak-out.txt 잠금 오류가 사라져야 함.
    2) 로컬 단독 실행 시 .ak-out.txt/ak7.jsonl 생성 확인.
===================================================================== #>

param(
  [string]$Root = ".",
  [string]$Manifest = "patches/manifest.json",
  [string]$OutText = ".ak-out.txt",
  [string]$OutJson = "logs/ak7.jsonl",
  [switch]$DryRun,
  [switch]$Quiet
)

# ===== 런타임 가드 =====
$ErrorActionPreference = 'Stop'
$PSStyle.OutputRendering = 'Ansi'

# CI 여부 및 OutText 비활성화 플래그(자체 방어)
$IsCI = ($env:GITHUB_ACTIONS -eq 'true')
# 아래 조건 중 하나라도 true면 OutText 파일 기록 금지:
#  - AK_TEE=1 (워크플로가 Tee-Object로 파일 전담)
#  - CI(GitHub Actions)에서 실행
#  - 대상 파일명이 .ak-out.txt (충돌 위험 높은 표준 파일)
$DisableOutText = ($env:AK_TEE -eq '1') -or $IsCI -or ($OutText -match '\.ak-out\.txt$')

# CI 힌트(있으면 로그에 싣기)
$TARGET_CMD = $env:TARGET_CMD
$TARGET_REF = $env:TARGET_REF

# ===== 안전 Append 유틸(파일공유 허용 + 재시도) =====
function Append-SafeLine {
  param([string]$Path, [string]$Line)

  $dir = Split-Path -Parent $Path
  if ($dir) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }

  $enc = [System.Text.UTF8Encoding]::new($false)  # UTF-8 (BOM 없음)
  for ($i=0; $i -lt 20; $i++) {
    try {
      # 공유 모드: ReadWrite → 동시 읽기/쓰기 허용
      $fs = [System.IO.File]::Open($Path,
        [System.IO.FileMode]::Append,
        [System.IO.FileAccess]::Write,
        [System.IO.FileShare]::ReadWrite)
      $sw = [System.IO.StreamWriter]::new($fs, $enc)
      $sw.WriteLine($Line)
      $sw.Dispose(); $fs.Dispose()
      return
    } catch {
      Start-Sleep -Milliseconds (50 * [Math]::Min($i+1,10))
      if ($i -eq 19) { throw }
    }
  }
}

# ===== 로깅 =====
function Write-Text([string]$s) {
  if (-not $Quiet) { Write-Host $s }
  # ⚠️ 충돌 방지: CI / AK_TEE=1 / .ak-out.txt 지정 시 파일 기록 금지
  if ($DisableOutText) { return }
  Append-SafeLine -Path $OutText -Line $s
}

function Write-JsonLog {
  param(
    [string]$Event,
    [string]$Message,
    [int]$ExitCode = 0,
    [hashtable]$Data
  )
  $obj = [pscustomobject]@{
    ts       = (Get-Date -AsUtc -Format o)
    event    = $Event
    message  = $Message
    exitCode = $ExitCode
    data     = $Data
  }
  $line = $obj | ConvertTo-Json -Compress
  # JSONL은 동시 사용률 낮고 충돌 리스크 낮음 → 계속 파일로 남김
  Append-SafeLine -Path $OutJson -Line $line
  if (-not $Quiet) { Write-Host $line }
}

# ===== 보조 유틸 =====
function Read-Json([string]$Path) {
  if (-not (Test-Path -LiteralPath $Path)) { return $null }
  $txt = Get-Content -LiteralPath $Path -Raw -ErrorAction Stop
  if ([string]::IsNullOrWhiteSpace($txt)) { return $null }
  return $txt | ConvertFrom-Json -ErrorAction Stop
}

function Ensure-Dir([string]$Path) {
  if ([string]::IsNullOrWhiteSpace($Path)) { return }
  New-Item -ItemType Directory -Force -Path $Path | Out-Null
}

# ===== 패치 실행기(샘플 오퍼레이션 4종) =====
function Apply-Op {
  param(
    [hashtable]$op,
    [switch]$DryRun
  )
  $type = $op.type
  switch ($type) {
    'touch' {
      $p = Join-Path $Root $op.path
      if ($DryRun) {
        Write-Text "DRYRUN: touch $($op.path)"
      } else {
        Ensure-Dir (Split-Path -Parent $p)
        if (-not (Test-Path -LiteralPath $p)) {
          Set-Content -LiteralPath $p -Value '' -Encoding UTF8
        }
        Write-Text "touch OK: $($op.path)"
      }
    }

    'writeFile' {
      $p = Join-Path $Root $op.path
      $content = [string]$op.content
      if ($DryRun) {
        Write-Text "DRYRUN: writeFile $($op.path) (len=$($content.Length))"
      } else {
        Ensure-Dir (Split-Path -Parent $p)
        Set-Content -LiteralPath $p -Value $content -Encoding UTF8
        Write-Text "writeFile OK: $($op.path)"
      }
    }

    'copy' {
      $src = Join-Path $Root $op.from
      $dst = Join-Path $Root $op.to
      if ($DryRun) {
        Write-Text "DRYRUN: copy $($op.from) -> $($op.to)"
      } else {
        Ensure-Dir (Split-Path -Parent $dst)
        Copy-Item -LiteralPath $src -Destination $dst -Force
        Write-Text "copy OK: $($op.from) -> $($op.to)"
      }
    }

    'replaceText' {
      $p = Join-Path $Root $op.path
      $find = [string]$op.find
      $repl = [string]$op.replace
      $raw  = Get-Content -LiteralPath $p -Raw -Encoding UTF8
      $new  = $raw -replace [regex]::Escape($find), [System.Text.RegularExpressions.MatchEvaluator]{ param($m) $repl }
      if ($DryRun) {
        $changed = [int]($raw -ne $new)
        Write-Text "DRYRUN: replaceText $($op.path) changed=$changed"
      } else {
        Set-Content -LiteralPath $p -Value $new -Encoding UTF8
        Write-Text "replaceText OK: $($op.path)"
      }
    }

    default {
      throw "지원하지 않는 op.type: $type"
    }
  }
}

# ===== 메인 =====
try {
  Write-Text  "== apply-patches.ps1 start (DryRun=$DryRun; CI=$IsCI; AK_TEE=$($env:AK_TEE)) =="
  Write-JsonLog -Event 'start' -Message 'apply-patches start' -Data @{
    root = (Resolve-Path $Root).Path
    manifest = $Manifest
    target_cmd = $TARGET_CMD
    target_ref = $TARGET_REF
    ci = $IsCI
  }

  $mf = Read-Json -Path (Join-Path $Root $Manifest)
  if ($null -eq $mf) {
    Write-Text "manifest not found or empty → skip"
  } else {
    $ops = @()
    if ($mf.PSObject.Properties.Name -contains 'ops') {
      $ops = $mf.ops
    } elseif ($mf -is [System.Collections.IEnumerable]) {
      $ops = $mf
    }
    if ($ops.Count -eq 0) {
      Write-Text "manifest has no ops → nothing to do"
    } else {
      foreach ($op in $ops) {
        Apply-Op -op $op -DryRun:$DryRun
      }
    }
  }

  if ($DryRun) {
    Write-Text   "== DryRun end =="
    Write-JsonLog -Event 'end' -Message 'dryrun ok' -ExitCode 11
    exit 11
  } else {
    Write-Text   "== Apply end =="
    Write-JsonLog -Event 'end' -Message 'apply ok' -ExitCode 0
    exit 0
  }
}
catch {
  $msg = $_.Exception.Message
  Write-Text   "ERROR: $msg"
  Write-JsonLog -Event 'error' -Message $msg -ExitCode 1 -Data @{ stack = "$($_.ScriptStackTrace)" }
  exit 1
}
```

## `scripts/g5/apply-pending-patches.ps1`

```text
APPLY IN SHELL
requires -Version 7.0
```

## `scripts/g5/auto-fix-open-prs.ps1`

```text
APPLY IN SHELL
requires -Version 7.0
```

## `scripts/g5/auto-merge-ready.ps1`

```text
APPLY IN SHELL
requires -Version 7.0
```

## `scripts/g5/auto-pr-complete.ps1`

```text
APPLY IN SHELL
scripts/g5/auto-pr-complete.ps1 (v1.0.3 — skip self reviewer, no expr-if, expanded vars; token→gh fallback)
requires -Version 7.0
```

## `scripts/g5/autostart-verify.ps1`

```text
autostart-verify.ps1 — 부팅 후 자동 보호/헬스 스모크(+로그)
```

## `scripts/g5/branch-prune-quiet.ps1`

```text
requires -Version 7.0
```

## `scripts/g5/Build-Relations.ps1`

```text
scripts/g5/Build-Relations.ps1
```

## `scripts/g5/Check-AK7-Ports.ps1`

```text
requires -PSEdition Core
requires -Version 7.0
```

## `scripts/g5/Check-AK7.ps1`

```text
requires -Version 7
```

## `scripts/g5/Check-All-DevMock.ps1`

```text
requires -Version 7
```

## `scripts/g5/Check-ORCH.ps1`

```text
requires -Version 7
```

## `scripts/g5/check-pr-ready.ps1`

```text
APPLY IN SHELL
requires -Version 7.0
```

## `scripts/g5/Clean-AK7-Ports.ps1`

```text
requires -PSEdition Core
requires -Version 7.0
```

## `scripts/g5/doctor.ps1`

```text
APPLY IN SHELL
doctor.ps1 — no pager hang (generated: 2025-09-15 03:28:55 +09:00)
requires -Version 7.0
```

## `scripts/g5/enforcement-check.ps1`

```text
Verify branch protection by creating a temporary PR that should fail to merge (no approvals)
requires -PSEdition Core
requires -Version 7.0
```

## `scripts/g5/enforcement-check.v2.ps1`

```text
Verify branch protection by opening a PR and attempting to merge without approvals.
Chooses an allowed merge method automatically and handles cleanup robustly.
requires -PSEdition Core
requires -Version 7.0
```

## `scripts/g5/enforcement-check.v3.ps1`

```text
Verify branch protection WITHOUT admin bypass (no --admin).
Tries squash -> rebase -> merge; expects failure (block) when approvals required.
requires -PSEdition Core
requires -Version 7.0
```

## `scripts/g5/error-trend.ps1`

```text
APPLY IN SHELL
Error Trend v1.2 — apply-log.jsonl aggregation (generated: 2025-09-15 02:06:53 +09:00)
requires -Version 7.0
```

## `scripts/g5/Extract-ScriptHeaders.v1.0.ps1`

```text
requires -Version 7.0
[목적] scripts/g5/**/*.ps1 의 "머리 주석(파일 시작부)"만 수집해 Markdown으로 정리
[규칙]
- 머리 주석이 없는 스크립트는 제외
- 머리 주석 패턴:
(A) 시작부 연속 '# ...' 라인
(B) 시작부 펜스 블록: 첫 비공백 라인이 ``` 로 시작해 다음 ``` 전까지
(C) PowerShell 블록 주석: 시작부에 오는 <# ... #> (실제 스크립트에서 사용된 유형)
(D) 첫 줄이 shebang('#!')이면 한 줄 스킵 후 (A/B/C) 적용
[산출] ./_inventory/script-headers.md (UTF-8, 덮어쓰기) — 본문은 ```text 코드블록로 통일
[사용]
pwsh -NoProfile -File .\scripts\g5\Extract-ScriptHeaders.v1.0.1.ps1 `
-ScriptsDir "scripts/g5" -Out "./_inventory/script-headers.md"
```

## `scripts/g5/Extract-WorkflowHeaders.ps1`

```text
requires -Version 7.0
```

## `scripts/g5/fetch-quiet.ps1`

```text
requires -Version 7.0
```

## `scripts/g5/finalize-release.ps1`

```text
APPLY IN SHELL
requires -Version 7.0
```

## `scripts/g5/fix-console-now.ps1`

```text
requires -Version 7
```

## `scripts/g5/g5-d11d15-pack.ps1`

```text
g5-d11d15-pack.ps1 — CODEOWNERS + KLC 야간 집계 + 포스트릴리즈 카나리 + 주간 하우스키핑
```

## `scripts/g5/g5-d3d5-pack.ps1`

```text
g5-d3d5-pack.ps1 — 컨테이너/부팅 런북 강화 + 게이트/디스패치 + 가드 (PS7)
```

## `scripts/g5/g5-d6d7-pack.ps1`

```text
g5-d6d7-pack.ps1 — 배포(Deploy)·롤백(URS)·릴리즈 게이트 전자동 (PS7)
```

## `scripts/g5/g5-d8d10-pack.ps1`

```text
g5-d8d10-pack.ps1 — Post-switch 훅 + 강한 Release Gate + 거버넌스(템플릿/Dependabot)
```

## `scripts/g5/g5-start-servers.ps1`

```text
--- g5-start-servers.ps1 : 로그인 시 서버(컨테이너/로컬) 자동기동(있는 것만) ---
```

## `scripts/g5/github-status-export.ps1`

```text
APPLY IN SHELL
scripts/g5/github-status-export.ps1  (v0.3.0 — adds `recent`)
requires -Version 7.0
```

## `scripts/g5/good-list.ps1`

```text
requires -Version 7.0
```

## `scripts/g5/good-restore.ps1`

```text
requires -Version 7.0
```

## `scripts/g5/good-save.ps1`

```text
requires -Version 7.0
```

## `scripts/g5/guard-run.ps1`

```text
APPLY IN SHELL
guard-run.ps1 — safe runner (generated: 2025-09-15 03:20:10 +09:00)
requires -Version 7.0
```

## `scripts/g5/harden-private-pro.ps1`

```text
Harden a private repo after upgrading to Pro/Team (Branch protection + repo settings)
DRYRUN by default; add -ConfirmApply to apply.
requires -PSEdition Core
requires -Version 7.0
```

## `scripts/g5/harden-private-pro.v2.ps1`

```text
Harden a private repo after upgrading to Pro/Team (corrected flags)
- Sets merge methods via REST (PATCH /repos)
- Applies branch protection via REST (PUT /branches/<b>/protection)
DRYRUN by default; add -ConfirmApply to execute.
requires -PSEdition Core
requires -Version 7.0
```

## `scripts/g5/health-smoke.ps1`

```text
health-smoke.ps1 — 3모듈 헬스 체크(PS7)
```

## `scripts/g5/housekeeping-smoke.ps1`

```text
파일: scripts/g5/housekeeping-smoke.ps1
목적: 하우스키핑 스모크(읽기 전용 점검). OK/WARN/FAIL 집계 후 종료코드 반환(0=성공, 1=실패 존재).
산출물: 콘솔 표/요약, KLC 1행 로그. -SummaryPath 지정 시 MD 요약 파일 생성.
```

## `scripts/g5/housekeeping-summarize.ps1`

```text
requires -Version 7.0
```

## `scripts/g5/housekeeping-weekly-run.ps1`

```text
requires -Version 7.0
```

## `scripts/g5/housekeeping-weekly.ps1`

```text
requires -Version 7.0
```

## `scripts/g5/Install-AK7-AutoStart.ps1`

```text
--- Install-AK7-AutoStart.ps1 (정상/멱등) ---
```

## `scripts/g5/install-guards.ps1`

```text
install-guards.ps1 — Unified Guards v1.0  (PS7)
목적: 지정 루트들에 통일된 보호 규칙 적용 (NTFS ACL + ReadOnly)
안전: 기존 ACL 백업 → 적용 → 요약 출력. 파일 손상 없음.
사용: pwsh -NoProfile -File .\install-guards.ps1
```

## `scripts/g5/install-hooks.ps1`

```text
Install local git hooks (pre-push) to block pushes to main
requires -PSEdition Core
requires -Version 7.0
```

## `scripts/g5/inventory.ps1`

```text
Kobong-Orchestrator-VIP — 전수 인벤토리 수집 (PS7) v1.5 Minimal Safe
목적: "파일명과 경로"만 수집 (콘텐츠 미접근, 파일 손상 위험 0)
inventory.ps1
requires -Version 7.0
```

## `scripts/g5/klc-verify.ps1`

```text
requires -Version 7.0
```

## `scripts/g5/kobong-run.ps1`

```text
APPLY IN SHELL
kobong-run.ps1 — wrapper to guard-run (generated)
requires -Version 7.0
```

## `scripts/g5/make-g5-context.ps1`

```text
requires -Version 7.0
make-g5-context.ps1 — 안정판 v1.1.1 (no-HMAC)
```

## `scripts/g5/make-run-report.ps1`

```text
requires -Version 7.0
```

## `scripts/g5/manifest-prune.ps1`

```text
requires -Version 7.0
```

## `scripts/g5/monitor-health.ps1`

```text
requires -Version 7.0
```

## `scripts/g5/monitor-logs.ps1`

```text
APPLY IN SHELL
Kobong-Orchestrator — Monitor Logs v1.3  (generated: 2025-09-15 00:53:23 +09:00)
requires -Version 7.0
```

## `scripts/g5/monitor-status.ps1`

```text
APPLY IN SHELL
Kobong-Orchestrator — Monitor Status v1.3.2  (generated: KST: 2025-09-15 01:44:06 +09:00)
requires -Version 7.0
```

## `scripts/g5/one-shot-setup.ps1`

```text
APPLY IN SHELL
One-Shot-Setup v1.1 — 상태 준비 + 모니터/CI 실행 준비 (generated: 2025-09-15 01:21:31 +09:00)
requires -Version 7.0
```

## `scripts/g5/ops-menu - 복사본.ps1`

```text
APPLY IN SHELL
Kobong — OPS MENU v1.1  (generated: KST: 2025-09-15 02:30:28 +09:00)
requires -Version 7.0
```

## `scripts/g5/ops-menu.ps1`

```text
APPLY IN SHELL
Kobong — OPS MENU v1.1  (generated: KST: 2025-09-15 02:30:28 +09:00)
requires -Version 7.0
```

## `scripts/g5/Patch-OrchMon-NodePath.ps1`

```text
Patch-OrchMon-NodePath.ps1 — 두 파일의 Get-NodePath를 표준화(ProgramFiles 우선)
```

## `scripts/g5/patches/Install-AK7-AutoStart.ps1`

```text
Install-AK7-AutoStart.ps1
```

## `scripts/g5/ports-clean.ps1`

```text
ports-clean.ps1 — 5181/5182/5183/5191/5193/5199 LISTEN 프로세스 강제 종료(관리자 권한 권장)
```

## `scripts/g5/post-merge-ship.ps1`

```text
requires -Version 7.0
post-merge-ship.ps1 — 안정판 v1.1.1a
```

## `scripts/g5/pr-automerge-watch.ps1`

```text
requires -Version 7.0
```

## `scripts/g5/pr-badge-dedupe.ps1`

```text
requires -Version 7.0
```

## `scripts/g5/pr-rebase-onto-main.ps1`

```text
requires -Version 7.0
```

## `scripts/g5/pr-rerun-checks-and-watch.ps1`

```text
requires -Version 7.0
```

## `scripts/g5/protect-file.ps1`

```text
requires -Version 7.0
```

## `scripts/g5/ps-header-enforcer.ps1`

```text
requires -Version 7.0
```

## `scripts/g5/register-docs-manifest.ps1`

```text
APPLY IN SHELL
requires -Version 7.0
```

## `scripts/g5/register-housekeeping-task.ps1`

```text
requires -Version 7.0
```

## `scripts/g5/register-manifest.ps1`

```text
requires -Version 7.0
```

## `scripts/g5/release-append-badge.ps1`

```text
requires -Version 7.0
```

## `scripts/g5/release-next-patch.ps1`

```text
requires -Version 7.0
```

## `scripts/g5/release-stabilize-with-watch.ps1`

```text
requires -Version 7.0
```

## `scripts/g5/release-stabilize.ps1`

```text
requires -Version 7.0
```

## `scripts/g5/release-train-with-watch.ps1`

```text
requires -Version 7.0
```

## `scripts/g5/release-train.ps1`

```text
requires -Version 7.0
```

## `scripts/g5/release-vpatch.ps1`

```text
requires -Version 7.0
```

## `scripts/g5/release-vpatch.safe.ps1`

```text
APPLY IN SHELL
requires -Version 7.0
```

## `scripts/g5/remove-guards.ps1`

```text
remove-guards.ps1 — Remove the local hook and advisory workflow
requires -PSEdition Core
requires -Version 7.0
```

## `scripts/g5/repair-protection.ps1`

```text
repair-protection.ps1 — ReadOnly/ACL 재적용(PS7)
```

## `scripts/g5/rotate-apply-log.ps1`

```text
requires -Version 7.0
```

## `scripts/g5/run-auto-patch-and-verify.ps1`

```text
APPLY IN SHELL
requires -Version 7.0
```

## `scripts/g5/run-github-monitor.ps1`

```text
APPLY IN SHELL
scripts/g5/run-github-monitor.ps1  (v0.2.1 — robust catch, single-quoted heredoc)
requires -Version 7.0
```

## `scripts/g5/run-kobong-logger.ps1`

```text
APPLY IN SHELL
Run-Kobong-Logger v1 — kobong_logger_cli 존재 확인/헬프 (generated: 2025-09-15 01:15:47 +09:00)
requires -Version 7.0
```

## `scripts/g5/run-kobong-orchestrator.ps1`

```text
APPLY IN SHELL
Run-Kobong-Orchestrator v1 — 필요시 설치 후 실행 (generated: 2025-09-15 01:15:47 +09:00)
requires -Version 7.0
```

## `scripts/g5/run-orch-shells-win.ps1`

```text
APPLY IN SHELL
requires -PSEdition Core
requires -Version 7.0
```

## `scripts/g5/run-pr-complete.ps1`

```text
APPLY IN SHELL
scripts/g5/run-pr-complete.ps1
requires -Version 7.0
```

## `scripts/g5/run-public-badge-sync.ps1`

```text
APPLY IN SHELL
scripts/g5/run-public-badge-sync.ps1
requires -Version 7.0
```

## `scripts/g5/run-static-web.ps1`

```text
requires -Version 7.0
```

## `scripts/g5/run-step4-keep.ps1`

```text
APPLY IN SHELL
scripts/g5/run-step4-keep.ps1  (v1.1)
requires -Version 7.0
```

## `scripts/g5/run-watchdog.ps1`

```text
APPLY IN SHELL
scripts/g5/run-watchdog.ps1 (v1.2 — hidden start, export cooldown, local API keepalive)
requires -Version 7.0
```

## `scripts/g5/scheduler-tune.ps1`

```text
requires -Version 7.0
```

## `scripts/g5/serve-public.ps1`

```text
requires -Version 7.0
```

## `scripts/g5/setup-git-hooks.ps1`

```text
requires -Version 7.0
```

## `scripts/g5/shell-status.ps1`

```text
APPLY IN SHELL
Shell-Status v1 — PS/도구 버전·경로·스크립트 존재 확인 (generated: 2025-09-15 01:15:47 +09:00)
requires -Version 7.0
```

## `scripts/g5/shells/Install-AK7-AutoStart.ps1`

```text
Install-AK7-AutoStart.ps1
```

## `scripts/g5/shells/run-orch-host-5188.ps1`

```text
APPLY IN SHELL — ORCHMON Shells host-run on port 5188 (no VS Build Tools)
requires -PSEdition Core
requires -Version 7.0
```

## `scripts/g5/shells/run-orch-shells-host.ps1`

```text
APPLY IN SHELL — 호스트에서 ORCHMON Shells 서버(5183) 기동
requires -PSEdition Core
requires -Version 7.0
```

## `scripts/g5/shells/run-orch-shells-win.ps1`

```text
APPLY IN SHELL
requires -PSEdition Core
requires -Version 7.0
```

## `scripts/g5/shells/stop-orch-shells.ps1`

```text
APPLY IN SHELL
requires -PSEdition Core
requires -Version 7.0
```

## `scripts/g5/smoke-auto-release.ps1`

```text
APPLY IN SHELL
requires -Version 7.0
```

## `scripts/g5/Start-AK7.ps1`

```text
requires -Version 7
```

## `scripts/g5/Start-All-DevMock.ps1`

```text
requires -Version 7
```

## `scripts/g5/Start-ORCH.ps1`

```text
requires -Version 7
```

## `scripts/g5/status-setup.ps1`

```text
APPLY IN SHELL
Status-Setup v1 — logs/out 디렉터리 준비 + git 기본 설정 안내 (generated: 2025-09-15 01:15:47 +09:00)
requires -Version 7.0
```

## `scripts/g5/Stop-AK7.ps1`

```text
requires -Version 7
```

## `scripts/g5/Stop-All-DevMock.ps1`

```text
requires -Version 7
```

## `scripts/g5/Stop-ORCH.ps1`

```text
requires -Version 7
```

## `scripts/g5/synthetic-pr-workload.ps1`

```text
APPLY IN SHELL
scripts/g5/synthetic-pr-workload.ps1  (v3.1 — default-branch autodetect, non-fatal PR)
requires -Version 7.0
```

## `scripts/g5/Trace-WorkflowRefs.v3.3.ps1`

```text
requires -Version 7.0
```

## `scripts/g5/UI/Install-AK7-AutoStart.ps1`

```text
Install-AK7-AutoStart.ps1
```

## `scripts/g5/UI/run-GHMON.ps1`

```text
APPLY IN SHELL
requires -PSEdition Core
requires -Version 7.0
```

## `scripts/g5/UI/test-GHMON.ps1`

```text
APPLY IN SHELL
requires -PSEdition Core
requires -Version 7.0
```

## `scripts/g5/UI/ui_patch_direct.ps1`

```text
APPLY IN SHELL
requires -PSEdition Core
requires -Version 7.0
```

## `scripts/g5/unprotect-file.ps1`

```text
requires -Version 7.0
```

## `scripts/g5/update-docs-and-inventory.ps1`

```text
requires -Version 7.0
update-docs-and-inventory.ps1 — 안정판 v1.1.1
```

## `scripts/g5/verify-housekeeping.ps1`

```text
requires -Version 7.0
```

## `scripts/g5/verify-protection.v2.ps1`

```text
Verify repo merge policy and branch protection (works pre/post upgrade)
requires -PSEdition Core
requires -Version 7.0
```

## `scripts/g5/watch-badge-ready.ps1`

```text
requires -Version 7.0
```

## `scripts/g5/watch-readme-badge.ps1`

```text
requires -Version 7.0
```

## `scripts/g5/wf-allround-tester.ps1`

```text
파일: scripts/g5/wf-allround-tester.ps1
목적: 안전 범위에서 워크플로 스모크 트리거를 발생시킨다(Dispatch/PR/댓글).
출력: GITHUB_OUTPUT로 pr_number/branch/ts 반환(후속 집계/정리에서 사용).
사용:
pwsh -NoProfile -File scripts/g5/wf-allround-tester.ps1 `
-Repo owner/repo -TestDispatch:$true -TestPR:$true -TestIssueComment:$true -KeepPr:$false
보안:
- 포크/외부 저장소 방지: 현재 repo 이름 일치 확인
- 샌드박스 브랜치: bot/wf-test-YYYYMMDD-HHMMSS
```

## `scripts/g5/wf-inventory.ps1`

```text
파일: scripts/g5/wf-inventory.ps1
목적: 레포의 .github/workflows/*.yml 전수 수집 → _inventory/workflows.csv|json 생성
동작:
(A) 체크아웃된 워크스페이스에서 로컬 우선 스캔
(B) 로컬이 비어있으면 zipball로 폴백(브랜치/태그명 사용 권장; SHA는 404 가능)
사용:
pwsh -NoProfile -File scripts/g5/wf-inventory.ps1 -Repo dh1293-hub/kobong-orchestrator -Ref main
보안:
- GH_TOKEN 있으면 API 헤더로 사용(레이트리밋 완화)
- User-Agent / X-GitHub-Api-Version 명시
산출: _inventory/workflows.csv, _inventory/workflows.json
규칙: #주석(친절한) / 멱등 / 실패 시 원인(로컬 비어있음+zipball 실패) 명확히 출력
```

