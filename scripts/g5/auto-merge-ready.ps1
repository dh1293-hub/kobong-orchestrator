# APPLY IN SHELL
#requires -Version 7.0
param(
  [int[]]$PR,
  [switch]$AllOpen,
  [switch]$ConfirmApply,
  [string]$Root
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

# RepoRoot
try { $RepoRoot = (& git rev-parse --show-toplevel 2>$null) } catch {}
if (-not $RepoRoot) { if ($Root) { $RepoRoot=$Root } else { $RepoRoot=(Get-Location).Path } }

function Fail([int]$code,[string]$msg){ Write-Error $msg; exit $code }

# Tools
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) { Fail 10 "GitHub CLI(gh) 필요" }
if (-not (Get-Command git -ErrorAction SilentlyContinue)) { Fail 10 "git 필요" }

Push-Location $RepoRoot
try {
  # Helper: PR 상세 + 체크 수집 + READY 판정
  function Get-PrEval([int]$Num){
    $fields='number,title,state,isDraft,mergeStateStatus,reviewDecision,headRefName,headRefOid,baseRefName,url'
    $prJson = & gh pr view $Num --json $fields -q . 2>$null
    if (-not $prJson) { return $null }
    $i = $prJson | ConvertFrom-Json

    $sha = $i.headRefOid
    if (-not $sha) {
      return [ordered]@{ number=$Num; title=$i.title; url=$i.url; state=$i.state; isDraft=$i.isDraft; headRef=$i.headRefName; baseRef=$i.baseRefName; mergeStateStatus=$i.mergeStateStatus; reviewDecision=$i.reviewDecision; headSha=$null; checks=[ordered]@{total=0;ok=0;bad=0;pending=0;legacy=$null;pass=$false}; ready=$false; reasons=@("head SHA 확인 실패") }
    }

    $ownerRepo = (& gh repo view --json nameWithOwner -q .nameWithOwner)
    $owner,$repo = $ownerRepo.Split('/')

    $checksJson = & gh api "repos/$owner/$repo/commits/$sha/check-runs" 2>$null
    $checks = if ($checksJson) { $checksJson | ConvertFrom-Json } else { $null }

    $legacyJson = & gh api "repos/$owner/$repo/commits/$sha/status" 2>$null
    $legacy = if ($legacyJson) { $legacyJson | ConvertFrom-Json } else { $null }
    $legacyState = $null
    if ($legacy -and $legacy.PSObject.Properties.Name -contains 'state') { $legacyState = $legacy.state }

    $tot=0;$ok=0;$bad=0;$pend=0
    if ($checks -and $checks.check_runs) {
      $tot = [int]$checks.total_count
      foreach ($r in $checks.check_runs) {
        if ($r.status -eq 'queued' -or $r.status -eq 'in_progress') { $pend++ }
        elseif ($r.conclusion -eq 'success') { $ok++ }
        elseif ($r.conclusion -in 'failure','cancelled','timed_out','action_required') { $bad++ }
      }
    }
    $checksPass = $false
    if ($tot -gt 0) { $checksPass = ($bad -eq 0 -and $pend -eq 0) }
    elseif ($null -ne $legacyState) { $checksPass = ($legacyState -eq 'success') }
    else { $checksPass = $true }

    $ready = $true
    $why = New-Object System.Collections.Generic.List[string]
    if ($i.state -ne 'OPEN') { $ready=$false; $why.Add("PR 상태="+$i.state) }
    if ($i.isDraft) { $ready=$false; $why.Add("Draft 상태") }
    if ($i.mergeStateStatus -eq 'BLOCKED') { $ready=$false; $why.Add("브랜치 보호 미충족") }
    if ($i.mergeStateStatus -eq 'DIRTY')   { $ready=$false; $why.Add("충돌(DIRTY)") }
    if ($i.mergeStateStatus -eq 'BEHIND')  { $ready=$false; $why.Add("베이스 대비 뒤처짐") }
    if (-not $checksPass) {
      $ready=$false
      $why.Add(("체크 실패/진행중 (total={0} ok={1} bad={2} pend={3} legacy={4})" -f $tot,$ok,$bad,$pend,$legacyState))
    }
    if ($i.reviewDecision -in 'CHANGES_REQUESTED','REVIEW_REQUIRED') { $ready=$false; $why.Add("리뷰="+$i.reviewDecision) }

    return [ordered]@{
      number=$i.number; title=$i.title; url=$i.url; state=$i.state; isDraft=$i.isDraft
      headRef=$i.headRefName; baseRef=$i.baseRefName; headSha=$sha
      mergeStateStatus=$i.mergeStateStatus; reviewDecision=$i.reviewDecision
      checks=[ordered]@{ total=$tot; ok=$ok; bad=$bad; pending=$pend; legacy=$legacyState; pass=$checksPass }
      ready=$ready; reasons=$why
    }
  }

  # 타깃 PR 집합
  $targets = @()
  if ($PR -and $PR.Count -gt 0) { $targets = $PR }
  elseif ($AllOpen -or -not $PR) {
    $listJson = & gh pr list --state open --json number -q '.[].number' 2>$null
    if ($listJson) { $targets = ($listJson | ConvertFrom-Json) }
  }
  if (-not $targets -or $targets.Count -eq 0) { Write-Host "No target PRs."; exit 0 }

  $readyList=@(); $notReady=@()
  foreach ($n in $targets) {
    $ev = Get-PrEval -Num $n
    if (-not $ev) { Write-Host ("PR #{0}: 조회 실패" -f $n); continue }
    $rText = $ev.ready ? 'READY' : 'NOT_READY'
    Write-Host ("PR #{0} — {1} :: {2}" -f $ev.number,$ev.title,$rText)
    if (-not $ev.ready -and $ev.reasons.Count -gt 0) { Write-Host ("  Why: {0}" -f ($ev.reasons -join '; ')) }
    if ($ev.ready) { $readyList += ,$ev } else { $notReady += ,$ev }
  }

  if ($readyList.Count -gt 0) {
    Write-Host ("READY PRs: {0}" -f (($readyList | ForEach-Object { "#"+$_.number }) -join ', '))
  } else {
    Write-Host "READY PRs: (none)"
  }

  if ($ConfirmApply -and $readyList.Count -gt 0) {
    foreach ($ev in $readyList) {
      Write-Host ("[MERGE] PR #{0} — {1}" -f $ev.number,$ev.title) -ForegroundColor Green
      & gh pr merge $ev.number --squash --delete-branch 2>&1 | Write-Host
    }
  } else {
    $mode = $ConfirmApply ? 'APPLY' : 'DRY-RUN'
    Write-Host ("Mode: {0} (실제 병합은 ConfirmApply 필요)" -f $mode)
  }
}
finally { Pop-Location -ErrorAction SilentlyContinue }