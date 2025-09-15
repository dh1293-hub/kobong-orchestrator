# APPLY IN SHELL
#requires -Version 7.0
param([switch]$ConfirmApply)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) { Write-Error "GitHub CLI(gh) 필요"; exit 10 }
if (-not (Get-Command git -ErrorAction SilentlyContinue)) { Write-Error "git 필요"; exit 10 }

# 안전: 작업트리 깨끗해야 적용
$dirty = (& git status --porcelain)
if ($dirty) { Write-Error "작업트리가 깨끗해야 합니다. (stash/commit 후 재시도)"; exit 10 }

# repo
$nwo = & gh repo view --json nameWithOwner -q .nameWithOwner
if (-not $nwo) { Write-Error "원격 리포 확인 실패"; exit 10 }
$owner,$repo = $nwo.Split('/')

function Enter-Branch([string]$branch){
  & git fetch origin $branch 2>$null | Out-Null
  $hasLocal = (& git rev-parse --verify --quiet $branch 2>$null); $isLocal = ($LASTEXITCODE -eq 0)
  if ($isLocal) { & git switch $branch 2>$null | Out-Null }
  else { & git switch --track $("origin/$branch") 2>$null | Out-Null }
  if ($LASTEXITCODE -ne 0) { & git switch -c $branch 2>$null | Out-Null }
}

function Try-MergeMain([string]$branch,[switch]$PreferOurs){
  Enter-Branch $branch
  & git fetch origin main 2>$null | Out-Null
  if ($PreferOurs) { & git merge -s recursive -X ours origin/main -m ("merge main → {0} (auto, prefer PR changes)" -f $branch) 2>$null }
  else { & git merge --no-ff --no-edit origin/main 2>$null }
  if ($LASTEXITCODE -ne 0) { & git merge --abort 2>$null | Out-Null; return $false }
  & git push origin HEAD 2>$null
  return ($LASTEXITCODE -eq 0)
}

function Retrigger-Checks([string]$branch,[string]$why){
  Enter-Branch $branch
  & git commit --allow-empty -m ("chore: retrigger checks (bot) — {0}" -f $why) 2>$null
  & git push origin HEAD 2>$null
  return ($LASTEXITCODE -eq 0)
}

# OPEN PRs
$open = (& gh pr list --state open --json number -q '.[].number' 2>$null)
if (-not $open) { Write-Host "No open PRs."; exit 0 }
$nums = $open | ConvertFrom-Json

foreach($num in $nums){
  $fields='number,title,state,isDraft,mergeStateStatus,reviewDecision,headRefName,headRefOid,baseRefName,url'
  $raw = & gh pr view $num --json $fields -q . 2>$null
  if (-not $raw) { Write-Host ("PR #{0}: 조회 실패" -f $num); continue }
  $i = $raw | ConvertFrom-Json
  $head=$i.headRefName

  # 체크 요약
  $sha=$i.headRefOid
  $checksPass=$true; $whyChecks=''
  if ($sha) {
    $chk = & gh api ("repos/{0}/{1}/commits/{2}/check-runs" -f $owner,$repo,$sha) 2>$null
    if ($chk) {
      $c = $chk | ConvertFrom-Json
      $tot=[int]$c.total_count; $ok=0; $bad=0; $pend=0
      foreach($r in $c.check_runs){
        if ($r.status -eq 'queued' -or $r.status -eq 'in_progress') { $pend++ }
        elseif ($r.conclusion -eq 'success') { $ok++ }
        elseif ($r.conclusion -in 'failure','cancelled','timed_out','action_required') { $bad++ }
      }
      $checksPass = ($tot -eq 0) -or ($bad -eq 0 -and $pend -eq 0)
      if (-not $checksPass) { $whyChecks = ("checks: total={0} ok={1} bad={2} pend={3}" -f $tot,$ok,$bad,$pend) }
    }
  }

  if ($i.state -ne 'OPEN' -or $i.isDraft) { continue }

  switch ($i.mergeStateStatus) {
    'BEHIND' {
      Write-Host ("[BEHIND] PR #{0} → merge main → {1}" -f $num,$head)
      if (-not $ConfirmApply) { Write-Host "  PLAN only (ConfirmApply 필요)"; break }
      $ok = Try-MergeMain -branch $head
      if ($ok) { & gh pr comment $num -b ("🤖 Auto-fix: merged `main` into `{0}` (no conflicts)." -f $head) 2>$null | Out-Null }
      else { & gh pr comment $num -b "🤖 Auto-fix attempt failed: conflicts; manual resolution required." 2>$null | Out-Null }
    }
    'DIRTY' {
      Write-Host ("[DIRTY]  PR #{0} → auto-resolve favor PR (-X ours)" -f $num)
      if (-not $ConfirmApply) { Write-Host "  PLAN only (ConfirmApply 필요)"; break }
      $ok = Try-MergeMain -branch $head -PreferOurs
      if ($ok) { & gh pr comment $num -b ("🤖 Auto-resolve: merged `main` into `{0}` with `-X ours` (kept PR changes)." -f $head) 2>$null | Out-Null }
      else { & gh pr comment $num -b "🤖 Auto-resolve failed: conflicts remained." 2>$null | Out-Null }
    }
    default {
      if (-not $checksPass) {
        Write-Host ("[CHECKS] PR #{0} → retrigger checks (empty commit)" -f $num)
        if ($ConfirmApply) {
          $ok = Retrigger-Checks -branch $head -why $whyChecks
          if ($ok) { & gh pr comment $num -b ("🤖 Pushed empty commit to retrigger checks. ({0})" -f $whyChecks) 2>$null | Out-Null }
        } else {
          Write-Host "  PLAN only (ConfirmApply 필요)"
        }
      }
    }
  }
}