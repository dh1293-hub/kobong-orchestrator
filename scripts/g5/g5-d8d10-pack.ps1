# g5-d8d10-pack.ps1 — Post-switch 훅 + 강한 Release Gate + 거버넌스(템플릿/Dependabot)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RepoRoot = 'D:\ChatGPT5_AI_Link\dosc\Kobong-Orchestrator-VIP'
$WF       = Join-Path $RepoRoot '.github\workflows'
$GHdir    = Join-Path $RepoRoot '.github'
$Deploy   = Join-Path $RepoRoot 'deploy'
Set-Location $RepoRoot
New-Item -ItemType Directory -Force -Path $WF,$GHdir,$Deploy | Out-Null

# 1) Post-switch 훅(배포 후 서비스/컨테이너 재기동; 안전하게 '있으면 실행'만)
@'
# deploy-postswitch.ps1 — 배포 전환 이후의 훅(선택적)
# - 존재하는 훅만 실행. 실패해도 전체 배포 중단 안 함.
# - 필요 시 아래 블록의 경로/이름만 실제 환경으로 바꾸세요.

Write-Host "[INFO] Post-switch hook 시작" -ForegroundColor Cyan

# (A) Docker Windows 컨테이너 재기동(있으면)
try {
  $names = @('orchmon','ghmon','ak7')  # 컨테이너 이름 예시
  foreach($n in $names){
    $c = (docker ps -a --format '{{.Names}}' | Where-Object { $_ -eq $n })
    if($c){ docker restart $n | Out-Null; Write-Host "[OK] docker restart $n" -ForegroundColor Green }
  }
} catch { Write-Host "[WARN] Docker 재기동 스킵: $($_.Exception.Message)" -ForegroundColor Yellow }

# (B) Windows 서비스 재시작(있으면)
try {
  $svcs = @('Kobong.Orch','Kobong.Ghmon','Kobong.Ak7')
  foreach($s in $svcs){
    if(Get-Service -Name $s -ErrorAction SilentlyContinue){
      Restart-Service -Name $s -Force -ErrorAction Stop
      Write-Host "[OK] service restart $s" -ForegroundColor Green
    }
  }
} catch { Write-Host "[WARN] Service 재시작 스킵: $($_.Exception.Message)" -ForegroundColor Yellow }

# (C) 커스텀 스크립트(있으면)
$custom = @(
  'ops\restart-orch.ps1',
  'ops\restart-ghmon.ps1',
  'ops\restart-ak7.ps1'
)
foreach($p in $custom){
  $abs = Join-Path (Split-Path $PSScriptRoot -Parent) $p
  if(Test-Path $abs){
    try { pwsh -NoProfile -File $abs; Write-Host "[OK] ran $p" -ForegroundColor Green }
    catch { Write-Host "[WARN] $p 실패: $($_.Exception.Message)" -ForegroundColor Yellow }
  }
}

Write-Host "[INFO] Post-switch hook 종료" -ForegroundColor Cyan
'@ | Set-Content "$Deploy\deploy-postswitch.ps1" -Encoding UTF8

# 2) deploy-release.ps1에 Post-switch 훅 호출(멱등) 추가
$dr = "$Deploy\deploy-release.ps1"
if(Test-Path $dr){
  $raw = Get-Content $dr -Raw
  if($raw -notmatch 'deploy-postswitch\.ps1'){
    $hook = @'
# === G5 hook: Post-switch ===
try {
  if ($SwitchNow) {
    $ps = Join-Path $PSScriptRoot 'deploy-postswitch.ps1'
    if (Test-Path $ps) { pwsh -NoProfile -File $ps }
  }
} catch {}
# === G5 hook end ===
'@
    $raw + "`n`n$hook" | Set-Content $dr -Encoding UTF8
  }
}

# 3) 강한 Release Gate (릴리즈 게시 시 정책 점검)
@'
name: Release Gate (strong)
on:
  release:
    types: [published]
jobs:
  gate:
    runs-on: windows-latest
    permissions:
      contents: read
    steps:
      - uses: actions/checkout@v4
        with:
          ref: ${{ github.event.release.tag_name }}  # 태그 기준으로 검사
      - name: Set up PowerShell 7
        uses: PowerShell/PowerShell@v1
        with: { pwsh-version: "7.4.x" }
      - name: Policy checks
        shell: pwsh
        env:
          GH_TOKEN: ${{ github.token }}
          TAG_NAME: ${{ github.event.release.tag_name }}
        run: |
          # 1) SECURITY.md 존재/비어있지 않은지
          if(-not (Test-Path .\SECURITY.md)){ Write-Error "SECURITY.md missing"; exit 1 }
          if((Get-Content .\SECURITY.md -Raw).Trim().Length -lt 50){ Write-Error "SECURITY.md too small"; exit 1 }

          # 2) 릴리즈 노트에 KLC 1행 존재
          $body = gh release view $env:TAG_NAME --json body -q .body
          if(-not $body -or -not ($body -match "KLC \| traceId=")){ Write-Error "KLC one-liner missing"; exit 1 }

          # 3) 브랜치 보호: strict + reviews>=1 + Required에 'KLC Verify' 포함
          $bp = gh api repos/:owner/:repo/branches/main/protection | ConvertFrom-Json
          if(-not $bp.required_status_checks.strict){ Write-Error "strict=false"; exit 1 }
          if($bp.required_pull_request_reviews.required_approving_review_count -lt 1){ Write-Error "reviews<1"; exit 1 }
          $ctx = @($bp.required_status_checks.contexts)
          if(-not ($ctx -contains 'KLC Verify')){ Write-Error "'KLC Verify' not required"; exit 1 }

          Write-Host "Release gate strong: OK" -ForegroundColor Green
'@ | Set-Content "$WF\release-gate-strong.yml" -Encoding UTF8

# 4) PR 템플릿(체크리스트; §10 AC 반영)
@'
## PR Checklist (운영 게이트)
- [ ] 센티넬+2줄 주입 규칙 유지(정적 HTML 직접편집 금지)
- [ ] `/health` 게이트 OK(위험 버튼 비활성→활성 흐름 확인)
- [ ] KLC 4요소(traceId/durationMs/exitCode/anchorHash) 노출
- [ ] URS 흐름 영향 없음(Deploy/Good/Rollback)
- [ ] Required checks 녹색
- 변경 사유(What/Why)와 영향 범위(Impact)를 아래에 요약:
'@ | Set-Content "$GHdir\pull_request_template.md" -Encoding UTF8

# 5) Dependabot(액션 주 1회 업데이트)
@'
version: 2
updates:
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule: { interval: "weekly", day: "monday", time: "09:00" }
'@ | Set-Content "$GHdir\dependabot.yml" -Encoding UTF8

# 6) 브랜치 생성 → 커밋/푸시 → PR/자동 머지(구 gh 호환)
git fetch --all --prune
$ts = Get-Date -Format 'yyyyMMdd_HHmmss'
$br = "g5/d8d10-pack-$ts"
git switch -c $br
git add $Deploy\deploy-postswitch.ps1 $dr $WF\release-gate-strong.yml $GHdir\pull_request_template.md $GHdir\dependabot.yml
git commit -m "ops(ci): D8~D10 pack — postswitch hook, strong release gate, PR template, dependabot"
git push -u origin $br
try { gh pr create --base main --head $br -t "ops(ci): D8~D10 pack" -b "자동 PR — 배포후 훅·강한 릴리즈 게이트·거버넌스" -f } catch {}
try { gh pr merge --squash --auto $br } catch { gh pr merge --squash $br }

Write-Host "`n[OK] D8~D10 pack pushed: $br" -ForegroundColor Green
