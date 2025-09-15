# APPLY IN SHELL
#requires -Version 7.0
param([int]$PR=21,[switch]$Json,[string]$Root)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'

# RepoRoot
try { $RepoRoot = (& git rev-parse --show-toplevel 2>$null) } catch {}
if (-not $RepoRoot) { if ($Root) { $RepoRoot=$Root } else { $RepoRoot=(Get-Location).Path } }

function Fail([int]$code,[string]$msg){ Write-Error $msg; exit $code }

# Tools
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) { Fail 10 "GitHub CLI(gh) 필요" }
if (-not (Get-Command git -ErrorAction SilentlyContinue)) { Fail 10 "git 필요" }

Push-Location $RepoRoot
try {
  # repo owner/name
  $nwo = (& gh repo view --json nameWithOwner -q .nameWithOwner 2>$null)
  if (-not $nwo) {
    $origin = git config --get remote.origin.url
    if ($origin -match '[:\/]([^\/:]+)\/([^\/\.]+)(?:\.git)?$') { $nwo = "$($Matches[1])/$($Matches[2])" }
  }
  if (-not $nwo) { Fail 10 "원격 리포 확인 실패" }
  $owner,$repo = $nwo.Split('/')

  # PR info
  $fields='number,title,state,isDraft,mergeStateStatus,reviewDecision,headRefName,headRefOid,baseRefName,url'
  $prJson = & gh pr view $PR --json $fields -q . 2>$null
  if (-not $prJson) { Fail 12 "gh pr view 실패" }
  $info = $prJson | ConvertFrom-Json

  $sha = $info.headRefOid
  if (-not $sha) { Fail 12 "head SHA 확인 실패" }

  # checks
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

  # readiness
  $ready = $true
  $why = New-Object System.Collections.Generic.List[string]
  if ($info.state -ne 'OPEN') { $ready=$false; $why.Add("PR 상태="+$info.state) }
  if ($info.isDraft) { $ready=$false; $why.Add("Draft 상태") }
  if ($info.mergeStateStatus -eq 'BLOCKED') { $ready=$false; $why.Add("브랜치 보호 미충족") }
  if ($info.mergeStateStatus -eq 'DIRTY')   { $ready=$false; $why.Add("충돌(DIRTY)") }
  if ($info.mergeStateStatus -eq 'BEHIND')  { $ready=$false; $why.Add("베이스 대비 뒤처짐") }
  if (-not $checksPass) {
    $ready=$false
    $why.Add(("체크 실패/진행중 (total={0} ok={1} bad={2} pend={3} legacy={4})" -f $tot,$ok,$bad,$pend,$legacyState))
  }
  if ($info.reviewDecision -in 'CHANGES_REQUESTED','REVIEW_REQUIRED') { $ready=$false; $why.Add("리뷰="+$info.reviewDecision) }

  # output (← 여기 수정: if를 식으로 쓰지 않음)
  Write-Host ("── PR Merge-Ready Check ─ {0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss K')) -ForegroundColor Cyan
  Write-Host ("Repo   : {0}" -f $nwo)
  Write-Host ("PR     : #{0} — {1}" -f $info.number,$info.title)
  Write-Host ("URL    : {0}" -f $info.url)
  Write-Host ("State  : {0}  Draft: {1}  MergeState: {2}  Review: {3}" -f $info.state,$info.isDraft,$info.mergeStateStatus,$info.reviewDecision)
  Write-Host ("Head/Base: {0} → {1}" -f $info.headRefName,$info.baseRefName)
  Write-Host ("Checks: total={0} ok={1} bad={2} pend={3} legacy={4}" -f $tot,$ok,$bad,$pend,$legacyState)

  if (-not $ready -and $why.Count -gt 0) { Write-Host ("Why   : {0}" -f ($why -join '; ')) }

  $resultText = $ready ? '✅ READY' : '❌ NOT READY'
  Write-Host ("Result: {0}" -f $resultText)

  if ($Json) {
    [ordered]@{
      pr=$PR; title=$info.title; url=$info.url; state=$info.state; isDraft=$info.isDraft
      mergeStateStatus=$info.mergeStateStatus; reviewDecision=$info.reviewDecision
      headRef=$info.headRefName; baseRef=$info.baseRefName; headSha=$sha
      checks=[ordered]@{ total=$tot; ok=$ok; bad=$bad; pending=$pend; legacy=$legacyState; pass=$checksPass }
      ready=$ready; reasons=$why
      timestamp=(Get-Date).ToString('o'); repo=$nwo
    } | ConvertTo-Json -Depth 5 | Write-Output
  }
}
finally { Pop-Location -ErrorAction SilentlyContinue }