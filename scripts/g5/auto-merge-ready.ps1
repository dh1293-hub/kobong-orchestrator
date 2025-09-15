# APPLY IN SHELL
#requires -Version 7.0
param([switch]$AllOpen,[int[]]$PR,[switch]$ConfirmApply,[switch]$Json)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) { Write-Error "GitHub CLI(gh) 필요"; exit 10 }

# owner/name
$nwo = (& gh repo view --json nameWithOwner -q .nameWithOwner 2>$null)
if (-not $nwo) { Write-Error "gh repo view 실패"; exit 10 }
$owner,$repo = $nwo.Split('/')

# 대상 PR 목록 수집 (항상 배열 보장)
$targets = @()
if ($PR -and $PR.Count -gt 0) { $targets += $PR }
elseif ($AllOpen -or -not $PR) {
  $ls = & gh pr list --state open --json number -q '.[].number' 2>$null
  if ($ls) { $targets += ($ls | ConvertFrom-Json) }
}
$targets = @($targets)  # ← 핵심: 배열로 강제
if ($targets.Count -eq 0) { Write-Host "READY PRs: (none)"; if($Json){'[]'}; exit 0 }

$rows = @()
foreach($n in $targets){
  $raw = & gh pr view $n --json number,title,state,isDraft,mergeStateStatus,reviewDecision,headRefName,headRefOid,baseRefName,url 2>$null
  if (-not $raw) { Write-Host ("PR #{0} — 조회 실패" -f $n); continue }
  $i = $raw | ConvertFrom-Json

  # checks 요약
  $tot=0;$ok=0;$bad=0;$pend=0
  if ($i.headRefOid) {
    try {
      $chk = & gh api ("repos/{0}/{1}/commits/{2}/check-runs" -f $owner,$repo,$i.headRefOid) 2>$null | ConvertFrom-Json
      $tot=[int]$chk.total_count
      foreach($r in $chk.check_runs){
        if ($r.status -eq 'queued' -or $r.status -eq 'in_progress') { $pend++ }
        elseif ($r.conclusion -in 'success','neutral','skipped') { $ok++ }
        elseif ($r.conclusion -in 'failure','timed_out','cancelled','action_required') { $bad++ }
        else { $pend++ }
      }
    } catch {}
  }
  $checksPass = ($tot -eq 0) -or ($bad -eq 0 -and $pend -eq 0)

  $mergeState = ''+$i.mergeStateStatus
  $blocked    = ($mergeState -in 'BLOCKED','DIRTY','BEHIND')
  $reviewBlk  = ($i.reviewDecision -in 'CHANGES_REQUESTED','REVIEW_REQUIRED')
  $ready = ($i.state -eq 'OPEN') -and (-not $i.isDraft) -and (-not $blocked) -and $checksPass -and (-not $reviewBlk)

  $why=@()
  if ($i.state -ne 'OPEN') { $why += ("PR 상태={0}" -f $i.state) }
  if ($i.isDraft) { $why += "Draft" }
  if ($blocked)   { $why += ("상태={0}" -f $mergeState) }
  if (-not $checksPass) { $why += ("체크 실패/진행중 (total={0} ok={1} bad={2} pend={3})" -f $tot,$ok,$bad,$pend) }
  if ($reviewBlk) { $why += ("리뷰={0}" -f $i.reviewDecision) }

  $label = if ($ready) { 'READY' } else { 'NOT_READY' }
  $fg = if ($ready) { 'Green' } else { 'Yellow' }
  Write-Host ("PR #{0} — {1} :: {2}" -f $i.number,$i.title,$label) -ForegroundColor $fg
  if ($why.Count -gt 0) { Write-Host ("  Why: {0}" -f ($why -join '; ')) }

  if ($ready -and $ConfirmApply) {
    & gh pr merge $i.number --squash --delete-branch
  }

  $rows += [pscustomobject]@{
    number=$i.number; title=$i.title; url=$i.url; state=$i.state; isDraft=$i.isDraft
    mergeStateStatus=$mergeState; reviewDecision=$i.reviewDecision
    headRef=$i.headRefName; baseRef=$i.baseRefName; headSha=$i.headRefOid
    checks=[pscustomobject]@{ total=$tot; ok=$ok; bad=$bad; pending=$pend; pass=$checksPass }
    ready=$ready; reasons=$why
  }
}

if ($Json) {
  $rows | ConvertTo-Json -Depth 6
} else {
  $readyNums = ($rows | Where-Object {$_.ready} | Select-Object -ExpandProperty number)
  if ($readyNums) { Write-Host ("READY PRs: {0}" -f ($readyNums -join ', ')) -ForegroundColor Green } else { Write-Host "READY PRs: (none)" }
}