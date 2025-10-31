# 파일: scripts/g5/wf-allround-tester.ps1
# 목적: 안전 범위에서 워크플로 스모크 트리거를 발생시킨다(Dispatch/PR/댓글).
# 출력: GITHUB_OUTPUT로 pr_number/branch/ts 반환(후속 집계/정리에서 사용).
# 사용:
#   pwsh -NoProfile -File scripts/g5/wf-allround-tester.ps1 `
#     -Repo owner/repo -TestDispatch:$true -TestPR:$true -TestIssueComment:$true -KeepPr:$false
# 보안:
#   - 포크/외부 저장소 방지: 현재 repo 이름 일치 확인
#   - 샌드박스 브랜치: bot/wf-test-YYYYMMDD-HHMMSS
param(
  [Parameter()][string]$Repo = $env:GITHUB_REPOSITORY,
  [Parameter()][switch]$TestDispatch = $true,
  [Parameter()][switch]$TestPR = $true,
  [Parameter()][switch]$TestIssueComment = $true,
  [Parameter()][switch]$KeepPr = $false
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['*:Encoding']='utf8'

if(-not $Repo){ throw "Repo not specified" }
if($env:GITHUB_REPOSITORY -and $Repo -ne $env:GITHUB_REPOSITORY){
  throw "Repo mismatch: $Repo vs $env:GITHUB_REPOSITORY"
}

# 타임스탬프/샌드박스 브랜치
$ts = Get-Date -Format 'yyyyMMdd-HHmmss'
$branch = "bot/wf-test-$ts"
$GITHUB_OUTPUT ??= "$env:GITHUB_OUTPUT"

# 1) workflow_dispatch 스모크
if($TestDispatch){
  Write-Host "▶ Dispatch-capable workflows"
  # 로컬 인벤토리에서 확인(없으면 GH 목록 조회)
  $wfList = @()
  $invPath = Join-Path (Get-Location) "_inventory/workflows.json"
  if(Test-Path $invPath){
    $wfList = (Get-Content $invPath -Raw | ConvertFrom-Json) | Where-Object {$_.has_workflow_dispatch -eq $true} | Select-Object -ExpandProperty path
  }
  if(-not $wfList -or $wfList.Count -eq 0){
    $wfList = gh api "repos/$Repo/actions/workflows?per_page=100" -q '.workflows[].path'
  }
  foreach($wf in $wfList){
    Write-Host "→ gh workflow run $wf"
    gh workflow run $wf -R $Repo 2>$null | Out-Null
  }
}

# 2) PR 트리거(드래프트) + 댓글(옵션)
[int]$prNumber = 0
if($TestPR -or $TestIssueComment){
  Write-Host "▶ Draft PR for pull_request/issue_comment"
  git config user.name  "wf-allround-bot"
  git config user.email "wf-allround-bot@users.noreply.github.com"
  git checkout -b $branch
  New-Item -ItemType Directory -Force tmp | Out-Null
  "wf-allround ping $ts" | Set-Content tmp/wf-allround-ping.txt
  git add tmp/wf-allround-ping.txt
  git commit -m "[WF-TEST] ping ($ts)"
  git push -u origin $branch

  $base = gh repo view --json defaultBranchRef -q .defaultBranchRef.name
  gh pr create --base $base --head $branch --title "[WF-TEST] $ts" --body "자동 전방위 테스트" --draft
  $prNumber = [int](gh pr view --json number -q .number)
  Write-Host "PR #$prNumber opened (draft)."

  if($TestIssueComment){
    gh pr comment $prNumber --body "/ak help"
    gh pr comment $prNumber --body "/ak"
  }

  if(-not $KeepPr){
    Write-Host "테스트 종료 후 자동 정리 예정(워크플로에서 tidy 단계 수행)."
  }
}

# 3) 출력(후속 잡에서 사용)
"pr_number=$prNumber" >> $GITHUB_OUTPUT
"branch=$branch"      >> $GITHUB_OUTPUT
"ts=$ts"              >> $GITHUB_OUTPUT
Write-Host "[OK] trigger-done → pr=$prNumber, branch=$branch, ts=$ts"
