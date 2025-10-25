# APPLY IN SHELL
# scripts/g5/auto-pr-complete.ps1 (v1.0.3 — skip self reviewer, no expr-if, expanded vars; token→gh fallback)
#requires -Version 7.0
param(
  [switch]$ConfirmApply,
  [string]$Root,
  [string]$Branch,
  [string[]]$Labels=@('synthetic','gpt5','heartbeat'),
  [string[]]$Reviewers=@(),
  [switch]$AutoMergeTry=$true,
  [switch]$DeleteBranchAfterMerge=$true,
  [switch]$MarkGood=$true
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

function Get-RepoRoot {
  if ($Root) { return (Resolve-Path $Root).Path }
  $rp = (git rev-parse --show-toplevel 2>$null)
  if (-not $rp) { return (Get-Location).Path }
  return $rp
}
function Parse-OwnerRepo([string]$RepoRoot){
  Push-Location $RepoRoot
  try {
    $url = (git remote get-url origin 2>$null)
    if (-not $url) { throw 'git origin remote not found' }
    if ($url -match 'github\.com[:/](?<owner>[^/]+)/(?<name>[^/.]+)') { return @{Owner=$Matches.owner; Repo=$Matches.name} }
    throw 'cannot parse owner/repo'
  } finally { Pop-Location }
}
function Get-Branch([string]$RepoRoot,[string]$Branch){
  if ($Branch) { return $Branch }
  Push-Location $RepoRoot; try {
    $b=(git rev-parse --abbrev-ref HEAD 2>$null)
    if (-not $b -or $b -eq '') { throw 'cannot detect current branch' }
    return $b
  } finally { Pop-Location }
}
function Get-DefaultBranch([string]$RepoRoot){
  Push-Location $RepoRoot
  try {
    $ref = (& git symbolic-ref refs/remotes/origin/HEAD 2>$null)
    if ($LASTEXITCODE -eq 0 -and $ref -match 'refs/remotes/origin/(.+)$') { return $Matches[1] }
  } finally { Pop-Location }
  return 'main'
}
function Has-GhAuth {
  $gh=(Get-Command gh -ErrorAction SilentlyContinue)
  if (-not $gh){ return $false }
  try { & $gh.Source auth status 2>$null | Out-Null; return ($LASTEXITCODE -eq 0) } catch { return $false }
}
function Invoke-GHApi([string]$Method,[string]$Path,[object]$Body=$null){
  $gh=(Get-Command gh -ErrorAction SilentlyContinue)
  if (-not $gh){ throw 'gh not found' }
  $args=@('api','-X',$Method,'-H','Accept: application/vnd.github+json', $Path)
  if ($Body -ne $null){
    $json=($Body | ConvertTo-Json -Depth 6)
    $tmp=[IO.Path]::GetTempFileName()
    $json | Out-File -LiteralPath $tmp -Encoding utf8 -NoNewline
    $args += @('--input',$tmp,'-H','Content-Type: application/json')
    try { $out=& $gh.Source @args; Remove-Item $tmp -Force } catch { Remove-Item $tmp -Force; throw }
  } else { $out=& $gh.Source @args }
  if ($LASTEXITCODE -ne 0){ throw 'gh api failed' }
  if ($out){ return $out | ConvertFrom-Json } else { return $null }
}
function Invoke-REST([string]$Method,[string]$Path,[object]$Body=$null){
  $tok=$null; if ($env:GITHUB_TOKEN){$tok=$env:GITHUB_TOKEN} elseif($env:GH_TOKEN){$tok=$env:GH_TOKEN} elseif($env:GITHUB_PAT){$tok=$env:GITHUB_PAT}
  if (-not $tok){ throw 'Missing GitHub token' }
  $uri='https://api.github.com'+$Path
  $hdr=@{ Authorization='Bearer '+$tok; 'User-Agent'='kobong-auto-finalize'; Accept='application/vnd.github+json' }
  if ($Body -ne $null){ return Invoke-RestMethod -Method $Method -Uri $uri -Headers $hdr -Body ($Body|ConvertTo-Json -Depth 6) -ContentType 'application/json' -ErrorAction Stop }
  else { return Invoke-RestMethod -Method $Method -Uri $uri -Headers $hdr -ErrorAction Stop }
}
function Test-TokenBasic {
  try {
    $tok=$null; if ($env:GITHUB_TOKEN){$tok=$env:GITHUB_TOKEN} elseif($env:GH_TOKEN){$tok=$env:GH_TOKEN} elseif($env:GITHUB_PAT){$tok=$env:GITHUB_PAT}
    if (-not $tok){ return @{ ok=$false; reason='missing' } }
    $hdr=@{ Authorization='Bearer '+$tok; 'User-Agent'='kobong-token-check'; Accept='application/vnd.github+json' }
    $u = Invoke-RestMethod -Method GET -Uri 'https://api.github.com/user' -Headers $hdr -ErrorAction Stop
    if ($u.login){ return @{ ok=$true; token=$tok } }
    return @{ ok=$false; reason='unknown' }
  } catch { return @{ ok=$false; reason='invalid'; message=$_.Exception.Message } }
}
function GitHub-Call([string]$Method,[string]$Path,[object]$Body=$null){
  $restTried = $false
  $tt = Test-TokenBasic
  if ($tt.ok){
    $restTried = $true
    try { return Invoke-REST -Method $Method -Path $Path -Body $Body } catch { $restErr = $_.Exception.Message }
  }
  if (Has-GhAuth){
    try { return Invoke-GHApi -Method $Method -Path $Path -Body $Body } catch { $ghErr = $_.Exception.Message }
  }
  if ($restTried){ throw "REST auth failed: $restErr" }
  throw "No auth (token/gh) available"
}

$RepoRoot = Get-RepoRoot
$ownerRepo = Parse-OwnerRepo $RepoRoot
$owner=$ownerRepo.Owner; $repo=$ownerRepo.Repo
$branch = Get-Branch $RepoRoot $Branch
$base   = Get-DefaultBranch $RepoRoot

if (-not $ConfirmApply){
  Write-Host "[PREVIEW] $owner/$repo base:$base branch:$branch"
  Write-Host "  labels   : $($Labels -join ', ')"
  Write-Host "  reviewers: $($Reviewers -join ', ')"
  Write-Host "  actions  : ensure PR → label → comment → reviewers → (auto-merge)"
  return
}

# 1) PR 확보
$pr = $null
try {
  $encodedBranch=[uri]::EscapeDataString($branch)
  $prList = GitHub-Call -Method 'GET' -Path "/repos/$owner/$repo/pulls?head=$owner%3A$encodedBranch&state=open"
  if ($prList){ $pr = $prList | Select-Object -First 1 }
} catch { }
if (-not $pr){
  try {
    $pr = GitHub-Call -Method 'POST' -Path "/repos/$owner/$repo/pulls" -Body @{
      title = "[synthetic] heartbeat from GPT-5"
      head  = $branch
      base  = $base
      body  = "Auto finalize by GPT-5"
      draft = $false
      maintainer_can_modify = $true
    }
  } catch {
    $url="https://github.com/$owner/$repo/pull/new/$branch"
    Write-Host "[FALLBACK] Open PR manually: $url"
    try { Start-Process $url } catch {}
    exit 0
  }
}
$prNum = [int]$pr.number
$prUrl = $pr.html_url
$author = ''
try { $author = $pr.user.login } catch {}

# 2) 라벨
if ($Labels -and $Labels.Count -gt 0){
  try { GitHub-Call -Method 'POST' -Path "/repos/$owner/$repo/issues/$prNum/labels" -Body @{ labels=$Labels } } catch {}
}

# 3) 체크리스트 코멘트 (변수 값 실제 반영)
$body = @"
**Synthetic heartbeat PR**
- Branch: $branch → Base: $base
- Labels: $($Labels -join ', ')
- Reviewers: $($Reviewers -join ', ')

Tasks:
- [ ] Review change (README heartbeat)
- [ ] Approve & merge (squash)
- [ ] Mark as **good** if stable
"@
try { GitHub-Call -Method 'POST' -Path "/repos/$owner/$repo/issues/$prNum/comments" -Body @{ body=$body } } catch {}

# 4) 리뷰어(자기자신 제외 + 중복 제거)
$rv=@()
if ($Reviewers){ $rv = $Reviewers | Where-Object { $_ -and $_ -ne $author } | Select-Object -Unique }
if ($rv.Count -gt 0){
  try { GitHub-Call -Method 'POST' -Path "/repos/$owner/$repo/pulls/$prNum/requested_reviewers" -Body @{ reviewers=$rv } } catch {}
} else {
  Write-Host "[INFO] skip reviewers (empty after removing PR author '$author')."
}

# 5) 자동 머지 (표준 if/else 사용)
if ($AutoMergeTry){
  try {
    $title = "synthetic heartbeat"
    if ($MarkGood) { $title = "**good** synthetic heartbeat" }
    $m = GitHub-Call -Method 'PUT' -Path "/repos/$owner/$repo/pulls/$prNum/merge" -Body @{ merge_method='squash'; commit_title=$title; commit_message='auto-squash by GPT-5' }
    if ($m -and $m.merged -eq $true){
      Write-Host "[OK] merged PR #$prNum"
      if ($DeleteBranchAfterMerge){
        try { & git push origin --delete $branch 2>$null | Out-Null } catch {}
        try { & git branch -D $branch 2>$null | Out-Null } catch {}
      }
    } else {
      Write-Host "[INFO] merge not allowed yet; checks or required reviews pending."
    }
  } catch {
    Write-Host "[INFO] merge attempt failed: $($_.Exception.Message)"
  }
}

Write-Host "PR ready: $prUrl"