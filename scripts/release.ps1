Param(
  [ValidateSet("patch","minor","major","pre")]
  [string]$Type = "patch",
  [string]$PreId = "rc"
)
$ErrorActionPreference = "Stop"
function Info($m){ Write-Host $m -ForegroundColor Cyan }
function Warn($m){ Write-Host $m -ForegroundColor DarkYellow }

# --- Repo root 강제 탐지/이동 ---
$repoRoot = (& git rev-parse --show-toplevel) 2>$null
if (-not $repoRoot) { $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path }
Set-Location $repoRoot
Info "RepoRoot = $repoRoot"
Info "PWD      = $((Get-Location).Path)"

if (-not (Test-Path ".\package.json")) { throw "package.json 미존재: $repoRoot 에서 발견되지 않음" }

# 브랜치/상태 검사
$branch = git rev-parse --abbrev-ref HEAD
if ($branch -ne "main") { Warn "현재 브랜치: $branch (main 권장)"; }
$dirty = git status --porcelain
if ($dirty) { throw "작업트리 깨끗하지 않음. 커밋 후 다시 실행하세요." }

# 릴리스 실행
switch ($Type) {
  "pre"   { $cmd = "npm run release:pre -- --prerelease $PreId" }
  default { $cmd = "npm run release:$Type" }
}
Info "실행: $cmd"
Invoke-Expression $cmd

# 태그 확인 및 푸시
$tag = git describe --tags --abbrev=0
Info "생성 태그: $tag"
git push --follow-tags origin main
Info "완료: $tag 푸시 완료."