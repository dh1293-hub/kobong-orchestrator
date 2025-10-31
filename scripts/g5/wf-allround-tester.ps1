# 파일: scripts/g5/wf-allround-tester.ps1
# 목적: 안전 범위에서 등록된 워크플로 스모크 트리거 실행(dispatch/PR/댓글)
# 출력: GitHub Actions step outputs(pr_number/branch/ts) 제공
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

$ts = Get-Date -Format 'yyyyMMdd-HHmmss'
$branch = "bot/wf-test-$ts"
[int]$prNumber = 0

# 1) workflow_dispatch 스모크
if($TestDispatch){
  Write-Host "▶ Dispatch-capable workflows"
  $wfList = @()
  $invPath = Join-Path (Get-Location) "_inventory/workflows.json"
  if(Test-Path $invPath){
    $wfList = (Get-Content $invPath -Raw | ConvertFrom-Json) |
              Where-Object {$_.has_workflow_dispatch -eq $true} |
              Select-Object -ExpandProperty path
  }
  if(-not $wfList -or $wfList.Count -eq 0){
    $wfList = gh api "repos/$Repo/actions/workflows?per_page=100" -q '.workflows[].path'
  }
  foreach($wf in $wfList){
    try {
      Write-Host "→ gh workflow run $wf"
      gh workflow run $wf -R $Repo 2>$null | Out-Null
    } catch {
      Write-Warning "dispatch 실패: $wf ($($_.Exception.Message))"
    }
  }
}

# 2) PR 트리거(드래프트) + 댓글(옵션)
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
    Write-Host "테스트 종료 후 자동 정리 예정(워크플로 tidy 단계)."
  }
}

# 3) GitHub Actions step outputs
$outFile = $env:GITHUB_OUTPUT
if ([string]::IsNullOrEmpty($outFile)) {
  Write-Warning "GITHUB_OUTPUT not set (local run?). Skip step outputs."
} else {
  Add-Content -Path $outFile -Value "pr_number=$prNumber"
  Add-Content -Path $outFile -Value "branch=$branch"
  Add-Content -Path $outFile -Value "ts=$ts"
}
Write-Host "[OK] trigger-done → pr=$prNumber, branch=$branch, ts=$ts"
