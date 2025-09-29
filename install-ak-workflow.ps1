# APPLY IN SHELL
#requires -PSEdition Core
#requires -Version 7.0
param([switch]$ConfirmApply)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

function Ensure-File([string]$Path,[string]$Content){
  $dir = Split-Path -Parent $Path
  New-Item -ItemType Directory -Force -Path $dir | Out-Null
  if (!(Test-Path $Path) -or ((Get-Content -Raw -LiteralPath $Path) -ne $Content)) {
    $ts = Get-Date -Format 'yyyyMMdd-HHmmss'
    if (Test-Path $Path) { Copy-Item $Path "$Path.bak-$ts" -Force }
    $Content | Out-File -LiteralPath $Path -Encoding utf8
  }
}

# git rev-parse 실패 대비 (?? 연산자 미지원 환경 포함)
$repo = (& git rev-parse --show-toplevel 2>$null)
if ([string]::IsNullOrWhiteSpace($repo)) { $repo = (Get-Location).Path }

$wf = Join-Path $repo ".github/workflows/ak-commands.yml"
$ps = Join-Path $repo "scripts/g5/ak-dispatch.ps1"

# ⬇⬇⬇ 중요: 싱글 쿼от here-string(@'... '@) 사용! 파워셸이 ${{
#           를 변수로 오인하지 않습니다. 백슬래시(\)도 불필요.
$yaml = @'
name: ak-commands
on:
  issue_comment:
    types: [created]
  pull_request_review_comment:
    types: [created]
permissions:
  contents: write
  pull-requests: write
  checks: write
  statuses: write
  issues: write
concurrency:
  group: ak-${{ github.event.pull_request.number || github.event.issue.number || github.run_id }}
  cancel-in-progress: true
jobs:
  run-ak:
    if: contains(github.event.comment.body, '/ak ')
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Parse command
        id: parse
        run: |
          echo "cmd=$(echo '${{ github.event.comment.body }}' | sed -n 's/.*\/ak\s\+\([a-z0-9\-]\+\).*/\1/p')" >> $GITHUB_OUTPUT
      - name: Run KO via PS7
        shell: pwsh
        run: pwsh -NoLogo -NoProfile -File scripts/g5/ak-dispatch.ps1 -Command "${{ steps.parse.outputs.cmd }}" -Sha "${{ github.sha }}" -Pr "${{ github.event.issue.number || github.event.pull_request.number }}"
'@

$dispatcher = @'
# APPLY IN SHELL
#requires -Version 7.0
param(
  [string]$Command,
  [string]$Sha,
  [string]$Pr
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
Write-Host "[AK] command=$Command sha=$Sha pr=$Pr"
# TODO: 여기서 실제 KO 실행/라우팅(스캔/테스트/FixLoop/롤백 등) 호출로 확장
'@

if (-not $ConfirmApply) {
  Write-Host "[PREVIEW] 설치 대상:"
  Write-Host " - $wf"
  Write-Host " - $ps"
  Write-Host "적용하려면: `$env:CONFIRM_APPLY='true'; pwsh -NoProfile -File `"$PSCommandPath`""
  exit 0
}

Ensure-File $wf $yaml
Ensure-File $ps $dispatcher
git add $wf $ps | Out-Null
$st = git status --porcelain
if ([string]::IsNullOrWhiteSpace($st)) {
  Write-Host "[SKIP] 변경 없음 (이미 최신)"
} else {
  git commit -m "ci(ak): install/refresh ak-commands workflow & dispatcher (**good**)" | Out-Null
  git push
}
Write-Host "[OK] 워크플로 준비 완료 → 이슈/PR 코멘트에 '/ak scan'으로 테스트"
