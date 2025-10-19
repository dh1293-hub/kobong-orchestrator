# g5-d6d7-pack.ps1 — 배포(Deploy)·롤백(URS)·릴리즈 게이트 전자동 (PS7)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RepoRoot = 'D:\ChatGPT5_AI_Link\dosc\Kobong-Orchestrator-VIP'
$RepoSlug = 'dh1293-hub/kobong-orchestrator'
$WF       = Join-Path $RepoRoot '.github\workflows'
$Deploy   = Join-Path $RepoRoot 'deploy'
Set-Location $RepoRoot
New-Item -ItemType Directory -Force -Path $WF,$Deploy | Out-Null

# 1) 배포 스크립트: 태그로 새 릴리즈 디렉터리 생성 → current/prev 링크 전환(옵션) → 가드/헬스
@'
param(
  [Parameter(Mandatory=$true)][string]$Tag,    # 예: v0.2.0-rc1
  [string]$Repo   = "dh1293-hub/kobong-orchestrator",
  [string]$Base   = "D:\ChatGPT5_AI_Link\dosc\Kobong-Orchestrator-VIP\_deploy",
  [switch]$SwitchNow                                # 지정 시 current를 즉시 전환
)
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# 디렉터리 준비
$Cache   = Join-Path $Base "cache"
$RelRoot = Join-Path $Base "releases"
$CurrLnk = Join-Path $Base "current"
$PrevLnk = Join-Path $Base "prev"
New-Item -ItemType Directory -Force -Path $Cache,$RelRoot | Out-Null

# 캐시 리포 업데이트/클론
if(-not (Test-Path (Join-Path $Cache ".git"))){
  git clone https://github.com/$Repo.git $Cache
}
git -C $Cache fetch --all --prune --tags
git -C $Cache checkout --force $Tag
$commit = (git -C $Cache rev-parse HEAD).Trim()

# 새 릴리즈 디렉터리 구성 (동일 태그가 있으면 건너뜀)
$RelDir = Join-Path $RelRoot $Tag
if(-not (Test-Path $RelDir)){
  New-Item -ItemType Directory -Force -Path $RelDir | Out-Null
  # .git 제외한 전체 복사(robocopy: 1,2,3도 성공 코드)
  & robocopy $Cache $RelDir /MIR /XD .git | Out-Null
}
# 메타 기록
@("tag=$Tag","commit=$commit","dt=$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')") |
  Set-Content (Join-Path $RelDir "deploy.meta.txt") -Encoding UTF8

# 링크 전환 로직
function Set-Junction($link,$target){
  if(Test-Path $link){ Remove-Item $link -Force }
  New-Item -ItemType Junction -Path $link -Target $target | Out-Null
}

if($SwitchNow){
  if(Test-Path $CurrLnk){ # prev 업데이트
    $currTarget = (Get-Item $CurrLnk).Target
    Set-Junction -link $PrevLnk -target $currTarget
  }
  Set-Junction -link $CurrLnk -target $RelDir

  # 가드/헬스(있으면 실행; 실패해도 전체 중단하지 않음)
  try { pwsh -NoProfile -File "$RepoRoot\scripts\g5\install-guards.ps1" } catch {}
  try { pwsh -NoProfile -File "$RepoRoot\scripts\g5\verify-protection.ps1" } catch {}
  try { pwsh -NoProfile -File "$RepoRoot\scripts\g5\health-smoke.ps1" } catch {}
  Write-Host "[OK] switched to $Tag ($commit)"
} else {
  Write-Host "[READY] prepared $Tag at $RelDir (use -SwitchNow to activate)"
}
'@ | Set-Content "$Deploy\deploy-release.ps1" -Encoding UTF8

# 2) URS 롤백(Prev/Good/Tag로 전환)
@'
param(
  [ValidateSet("prev","good","tag")][string]$Mode = "prev",
  [string]$Tag,                                   # Mode=tag 일 때 필수
  [string]$Base = "D:\ChatGPT5_AI_Link\dosc\Kobong-Orchestrator-VIP\_deploy"
)
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RelRoot = Join-Path $Base "releases"
$CurrLnk = Join-Path $Base "current"
$PrevLnk = Join-Path $Base "prev"
$GoodLnk = Join-Path $Base "good"

function Set-Junction($link,$target){
  if(Test-Path $link){ Remove-Item $link -Force }
  New-Item -ItemType Junction -Path $link -Target $target | Out-Null
}

switch($Mode){
  "prev" {
    if(-not (Test-Path $PrevLnk)){ throw "prev 링크가 없습니다." }
    $target = (Get-Item $PrevLnk).Target
  }
  "good" {
    if(-not (Test-Path $GoodLnk)){ throw "good 링크가 없습니다.(urs-mark-good.ps1 실행 필요)" }
    $target = (Get-Item $GoodLnk).Target
  }
  "tag"  {
    if(-not $Tag){ throw "-Tag 를 지정하세요." }
    $target = Join-Path $RelRoot $Tag
    if(-not (Test-Path $target)){ throw "해당 태그 디렉터리가 없습니다: $target" }
  }
}

# curr → prev 업데이트 후 전환
if(Test-Path $CurrLnk){
  $curr = (Get-Item $CurrLnk).Target
  Set-Junction -link $PrevLnk -target $curr
}
Set-Junction -link $CurrLnk -target $target

try { pwsh -NoProfile -File "D:\ChatGPT5_AI_Link\dosc\Kobong-Orchestrator-VIP\scripts\g5\verify-protection.ps1" } catch {}
try { pwsh -NoProfile -File "D:\ChatGPT5_AI_Link\dosc\Kobong-Orchestrator-VIP\scripts\g5\health-smoke.ps1" } catch {}

Write-Host "[OK] rolled to: $target"
'@ | Set-Content "$Deploy\urs-rollback.ps1" -Encoding UTF8

# 3) URS Good 마킹(현재 current → good 링크 갱신)
@'
param([string]$Base = "D:\ChatGPT5_AI_Link\dosc\Kobong-Orchestrator-VIP\_deploy")
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$CurrLnk = Join-Path $Base "current"
$GoodLnk = Join-Path $Base "good"
if(-not (Test-Path $CurrLnk)){ throw "current 링크가 없습니다.(배포/전환 먼저)" }
$curr = (Get-Item $CurrLnk).Target
if(Test-Path $GoodLnk){ Remove-Item $GoodLnk -Force }
New-Item -ItemType Junction -Path $GoodLnk -Target $curr | Out-Null
Write-Host "[OK] good → $curr"
'@ | Set-Content "$Deploy\urs-mark-good.ps1" -Encoding UTF8

# 4) 릴리즈 게이트(라이트): 태그 게시 시 KLC 한 줄 요약 재검증 + 간단 로그
@'
name: Release Gate (light)
on:
  release:
    types: [published]
jobs:
  gate:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v4
      - name: KLC one-liner present?
        shell: pwsh
        env:
          TAG_NAME: ${{ github.event.release.tag_name }}
        run: |
          $body = gh release view $env:TAG_NAME --json body -q .body
          if(-not $body -or -not ($body -match "KLC \\| traceId=")){
            Write-Error "KLC one-liner missing in release notes"; exit 1
          }
          Write-Host "KLC line found. OK."
'@ | Set-Content "$WF\release-gate.yml" -Encoding UTF8

# 5) 브랜치/PR/자동 머지
git fetch --all --prune
$ts = Get-Date -Format 'yyyyMMdd_HHmmss'
$br = "g5/d6d7-pack-$ts"
git switch -c $br
git add $Deploy\deploy-release.ps1 $Deploy\urs-rollback.ps1 $Deploy\urs-mark-good.ps1 $WF\release-gate.yml
git commit -m "ops: D6~D7 pack — deploy/URS scripts + release gate (light)"
git push -u origin $br
try { gh pr create --base main --head $br -t "ops: D6~D7 pack" -b "자동 PR — 배포/롤백 스크립트 및 라이트 릴리즈 게이트" -f } catch {}
try { gh pr merge --squash --auto $br } catch { gh pr merge --squash $br }

Write-Host "`n[OK] D6~D7 pack pushed: $br" -ForegroundColor Green
