# APPLY IN SHELL
#requires -Version 7.0
param([switch]$ConfirmApply,[string]$Root)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

# RepoRoot
try { $RepoRoot = (& git rev-parse --show-toplevel 2>$null) } catch {}
if (-not $RepoRoot) { if ($Root) { $RepoRoot=$Root } else { $RepoRoot=(Get-Location).Path } }

function Fail([int]$code,[string]$category,[string]$msg){
  Write-Host "[FAIL][$category] $msg" -ForegroundColor Red
  exit $code
}

# Tools
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) { Fail 10 'PRECONDITION' 'GitHub CLI(gh) 필요' }
if (-not (Get-Command git -ErrorAction SilentlyContinue)) { Fail 10 'PRECONDITION' 'git 필요' }

# 깨끗한 작업트리 요구(안전)
$dirty = (& git status --porcelain)
if ($dirty) { Fail 10 'PRECONDITION' '작업트리가 깨끗해야 합니다. (stash/commit 후 재시도)' }

Push-Location $RepoRoot
try {
  $nwo = (& gh repo view --json nameWithOwner -q .nameWithOwner 2>$null)
  if (-not $nwo) {
    $origin = git config --get remote.origin.url
    if ($origin -match '[:\/]([^\/:]+)\/([^\/\.]+)(?:\.git)?$') { $nwo = "$($Matches[1])/$($Matches[2])" }
  }
  if (-not $nwo) { Fail 10 'PRECONDITION' '원격 리포 확인 실패' }
  $owner,$repo = $nwo.Split('/')

  # 유틸
  function Enter-Branch([string]$branch){
    & git fetch origin $branch 2>$null | Out-Null
    $okLocal = (& git rev-parse --verify --quiet $branch 2>$null); $isLocal = ($LASTEXITCODE -eq 0)
    if ($isLocal) { & git switch $branch 2>$null | Out-Null }
    else { & git switch --track $("origin/$branch") 2>$null | Out-Null }
    if ($LASTEXITCODE -ne 0) { & git switch -c $branch 2>$null | Out-Null }
  }

  function Try-MergeMain([string]$branch,[switch]$PreferOurs,[switch]$DoApply){
    Enter-Branch $branch
    & git fetch origin main 2>$null | Out-Null
    if (-not $DoApply) { return @{ ok=$true; note=('PLAN: merge origin/main → {0}{1}' -f $branch,($(if($PreferOurs){' (-X ours)'}else{''}))) } }
    if ($PreferOurs) { & git merge -s recursive -X ours origin/main -m ("merge main → {0} (auto, prefer PR changes)" -f $branch) 2>$null }
    else { & git merge --no-ff --no-edit origin/main 2>$null }
    if ($LASTEXITCODE -ne 0) { & git merge --abort 2>$null | Out-Null; return @{ ok=$false; note='merge conflict' } }
    & git push origin HEAD 2>$null
    return @{ ok=($LASTEXITCODE -eq 0); note='pushed' }
  }

  function Retrigger-Checks([string]$branch,[switch]$DoApply,[string]$why){
    Enter-Branch $branch
    if (-not $DoApply) { return @{ ok=$true; note=('PLAN: empty commit to retrigger checks ({0})' -f $why) } }
    & git commit --allow-empty -m ("chore: retrigger checks (bot) — {0}" -f $why) 2>$null
    & git push origin HEAD 2>$null
    return @{ ok=($LASTEXITCODE -eq 0); note='empty commit pushed' }
  }

  # OPEN PR 나열
  $openJson = & gh pr list --state open --json number,title -q '.' 2>$null
  if (-not $openJson) { Write-Host "No open PRs."; return }
  $open = $openJson | ConvertFrom-Json

  $fixed=@(); $failed=@(); $skipped=@()
  foreach($p in $open){
    $num = [int]$p.number
    $fields='number,title,state,isDraft,mergeStateStatus,reviewDecision,headRefName,headRefOid,baseRefName,url'
    $prJson = & gh pr view $num --json $fields -q . 2>$null
    if (-not $prJson) { $skipped += ("PR #{0}: 조회 실패" -f $num); continue }
    $i = $prJson | ConvertFrom-Json
    $head=$i.headRefName

    # 체크 요약
    $sha=$i.headRefOid
    $checksPass=$true; $whyChecks=''
    if ($sha) {
      $checksJson = & gh api ("repos/{0}/{1}/commits/{2}/check-runs" -f $owner,$repo,$sha) 2>$null
      if ($checksJson) {
        $checks = $checksJson | ConvertFrom-Json
        $tot=[int]$checks.total_count; $ok=0; $bad=0; $pend=0
        foreach($r in $checks.check_runs){
          if ($r.status -eq 'queued' -or $r.status -eq 'in_progress') { $pend++ }
          elseif ($r.conclusion -eq 'success') { $ok++ }
          elseif ($r.conclusion -in 'failure','cancelled','timed_out','action_required') { $bad++ }
        }
        $checksPass = ($tot -eq 0) -or ($bad -eq 0 -and $pend -eq 0)
        if (-not $checksPass) { $whyChecks = ("checks: total={0} ok={1} bad={2} pend={3}" -f $tot,$ok,$bad,$pend) }
      }
    }

    # 상태별 처리
    if ($i.state -ne 'OPEN') { $skipped += ("PR #{0}: 상태={1}" -f $num,$i.state); continue }
    if ($i.isDraft) { $skipped += ("PR #{0}: Draft" -f $num); continue }

    if ($i.mergeStateStatus -eq 'BEHIND') {
      Write-Host ("[BEHIND] PR #{0} → merge main → {1}" -f $num,$head)
      $res = Try-MergeMain -branch $head -DoApply:$ConfirmApply
      if ($res.ok) {
        if ($ConfirmApply) { & gh pr comment $num -b ("🤖 Auto-fix: merged `main` into `{0}` (no conflicts)." -f $head) 2>$null | Out-Null }
        $mode = $ConfirmApply ? 'merged' : 'plan'
        $fixed += ("PR #{0}: BEHIND→{1}" -f $num,$mode)
      } else {
        $failed += ("PR #{0}: BEHIND fix failed ({1})" -f $num,$res.note)
      }
      continue
    }

    if ($i.mergeStateStatus -eq 'DIRTY') {
      Write-Host ("[DIRTY]  PR #{0} → auto-resolve favor PR (-X ours)" -f $num)
      $res = Try-MergeMain -branch $head -PreferOurs -DoApply:$ConfirmApply
      if ($res.ok) {
        if ($ConfirmApply) { & gh pr comment $num -b ("🤖 Auto-resolve: merged `main` into `{0}` with `-X ours` (kept PR changes)." -f $head) 2>$null | Out-Null }
        $mode = $ConfirmApply ? 'auto-resolved' : 'plan'
        $fixed += ("PR #{0}: DIRTY→{1}" -f $num,$mode)
      } else {
        $failed += ("PR #{0}: DIRTY auto-resolve failed" -f $num)
      }
      continue
    }

    if (-not $checksPass) {
      Write-Host ("[CHECKS] PR #{0} → retrigger checks (empty commit)" -f $num)
      $res = Retrigger-Checks -branch $head -DoApply:$ConfirmApply -why $whyChecks
      if ($res.ok) {
        if ($ConfirmApply) { & gh pr comment $num -b ("🤖 Pushed empty commit to retrigger checks. ({0})" -f $whyChecks) 2>$null | Out-Null }
        $mode = $ConfirmApply ? 'retriggered' : 'plan'
        $fixed += ("PR #{0}: checks→{1}" -f $num,$mode)
      } else {
        $failed += ("PR #{0}: checks retrigger failed" -f $num)
      }
      continue
    }

    $skipped += ("PR #{0}: 상태={1} checksPass={2}" -f $num,$i.mergeStateStatus,$checksPass)
  }

  # 요약
  Write-Host "`n== Summary =="
  if ($fixed.Count)  { Write-Host ("Fixed/Planned : {0}" -f ($fixed -join '; ')) }
  if ($failed.Count) { Write-Host ("Failed        : {0}" -f ($failed -join '; ')) }
  if ($skipped.Count){ Write-Host ("Skipped       : {0}" -f ($skipped -join '; ')) }

  # 사후 상태 — 준비 PR 목록
  Write-Host "`n== After-state (open PRs) =="
  & pwsh -NoProfile -ExecutionPolicy Bypass -File "scripts/g5/auto-merge-ready.ps1" -AllOpen 2>$null
}
finally { Pop-Location -ErrorAction SilentlyContinue }