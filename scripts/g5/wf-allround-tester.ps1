# scripts/g5/wf-allround-tester.ps1
# 친절한 주석: 목적/전제/정리
# - 전제: gh CLI 로그인(gh auth status), _inventory/workflows.json 존재
# - 전략: dispatch 가능한 워크플로는 즉시 run, PR/issue_comment형은 샌드박스 브랜치에서 DRAFT PR로만
param(
  [string]$Repo = "dh1293-hub/kobong-orchestrator",
  [switch]$TestDispatch = $true,
  [switch]$TestPR = $true,
  [switch]$TestIssueComment = $true
)
Set-StrictMode -Version Latest; $ErrorActionPreference='Stop'
$PSDefaultParameterValues['*:Encoding']='utf8'
$inv = (Get-Content "_inventory/workflows.json" -Raw | ConvertFrom-Json)

# 2.1 workflow_dispatch 전용 스모크
if ($TestDispatch) {
  foreach($wf in $inv | ?{$_.has_workflow_dispatch -eq $true}){
    Write-Host "▶ dispatch: $($wf.file)"
    gh workflow run (Split-Path $wf.file -Leaf) -R $Repo -f dry_run=true -f reason="wf-allround" 2>$null
  }
}

# 2.2 PR 트리거 검증 (샌드박스 브랜치)
$ts = (Get-Date -Format 'yyyyMMdd-HHmmss')
$branch = "wf-allround/$ts"
if ($TestPR -or $TestIssueComment) {
  git switch -c $branch
  New-Item -ItemType Directory -Force tmp|Out-Null
  "wf-allround ping $ts" | Set-Content tmp/wf-allround-ping.txt
  git add tmp/wf-allround-ping.txt
  git commit -m "chore(test): wf-allround ping ($ts)"
  git push -u origin $branch
  gh pr create -R $Repo --title "WF Allround Test $ts" --body "Draft PR for trigger smoke" --draft
}

if ($TestIssueComment) {
  $pr = gh pr list -R $Repo --search "WF Allround Test $ts" --state open --json number | ConvertFrom-Json
  if ($pr[0].number) {
    gh pr comment -R $Repo $pr[0].number --body "/ak help"
  }
}

Write-Host "ℹ️  종료: 테스트 트리거 전송 완료. (결과/아티팩트는 GH Actions 탭에서 확인)"
