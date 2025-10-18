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
