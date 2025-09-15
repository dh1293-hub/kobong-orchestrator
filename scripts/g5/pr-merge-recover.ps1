#requires -Version 7.0
param([switch]$ConfirmApply,[string]$Root)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

# pr-merge-recover.ps1 v1.2 — closed PR 대응(merged 판별→reopen→update→checks→merge), 안전 로그/락 포함
#requires -Version 7.0
param(
  [int]$Pr = 29,
  [string]$Repo = "dh1293-hub/kobong-orchestrator",
  [ValidateSet('merge','squash','rebase')][string]$MergeMethod = 'squash',
  [int]$MaxRetries = 4,
  [int]$PollSec = 15,
  [int]$MaxWaitMin = 20,
  [switch]$PruneIfMerged,
  [switch]$ConfirmApply,
  [string]$Root
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

function Write-KLog {
  param([ValidateSet('INFO','ERROR')]$Level='INFO',[string]$Module='pr-merge-recover',[string]$Action='run',[ValidateSet('SUCCESS','FAILURE','DRYRUN')]$Outcome='SUCCESS',[string]$ErrorCode='',[string]$Message='')
  try {
    if (Get-Command kobong_logger_cli -ErrorAction SilentlyContinue) {
      & kobong_logger_cli log --level $Level --module $Module --action $Action --outcome $Outcome --error $ErrorCode --message $Message 2>$null
      return
    }
  } catch {}
  $root = (git rev-parse --show-toplevel 2>$null) ?? (Get-Location).Path
  $log = Join-Path $root 'logs/apply-log.jsonl'
  New-Item -ItemType Directory -Force -Path (Split-Path $log) | Out-Null
  $rec = @{
    timestamp=(Get-Date).ToString('o'); level=$Level; traceId=[guid]::NewGuid().ToString();
    module=$Module; action=$Action; outcome=$Outcome; errorCode=$ErrorCode; message=$Message
  } | ConvertTo-Json -Compress
  Add-Content -Path $log -Value $rec
}
function Exit-Kobong { param([ValidateSet('PRECONDITION','CONFLICT','TRANSIENT','LOGIC','Unknown')]$Category='Unknown',[string]$Message='')
  $code = switch ($Category) {'PRECONDITION'{10} 'CONFLICT'{11} 'TRANSIENT'{12} 'LOGIC'{13} default{1}}
  Write-KLog -Level 'ERROR' -Outcome 'FAILURE' -ErrorCode $Category -Message $Message
  exit $code
}

# Gate-0
$RepoRoot = (git rev-parse --show-toplevel 2>$null) ?? (Get-Location).Path
if (-not $Root) { $Root = $RepoRoot }
if (-not (Test-Path $Root)) { Exit-Kobong PRECONDITION "Root not found: $Root" }
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) { Exit-Kobong PRECONDITION "GitHub CLI (gh) not found" }
if (-not (Get-Command git -ErrorAction SilentlyContinue)) { Exit-Kobong PRECONDITION "git not found" }

$LockFile = Join-Path $Root '.gpt5.lock'
if (Test-Path $LockFile) { Exit-Kobong CONFLICT ".gpt5.lock exists ($LockFile)" }

"locked $(Get-Date -Format o) pr=$Pr" | Out-File $LockFile -Encoding utf8 -NoNewline
$sw=[Diagnostics.Stopwatch]::StartNew()
try {
  Write-Host "[pr-merge-recover v1.2] $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') KST  PR#$Pr repo=$Repo method=$MergeMethod (dry-run=$(-not $ConfirmApply))"

  function Get-PrRaw { & gh api "repos/$Repo/pulls/$Pr" 2>$null }
  function Get-PrInfo {
    $raw = Get-PrRaw
    if ($LASTEXITCODE -ne 0 -or -not $raw) { return $null }
    $j = $raw | ConvertFrom-Json
    [pscustomobject]@{
      number        = $Pr
      title         = $j.title
      state         = $j.state
      isDraft       = [bool]$j.draft
      mergeState    = $j.mergeable_state
      headRefName   = $j.head.ref
      baseRefName   = $j.base.ref
      headSha       = $j.head.sha
      url           = $j.html_url
    }
  }
  function Test-PrMerged {
    try {
      $resp = & gh api -i "repos/$Repo/pulls/$Pr/merge" 2>$null
      return ($resp -match '^HTTP/1\.[01] 204')
    } catch { return $false }
  }
  function Update-Branch {
    Write-Host "  - Update branch from base → head (server-side)"
    & gh api -X PUT "repos/$Repo/pulls/$Pr/update-branch" -H "Accept: application/vnd.github+json" 1>$null
  }
  function Get-CombinedStatus([string]$sha) {
    try { ((& gh api "repos/$Repo/commits/$sha/status" 2>$null) | ConvertFrom-Json).state ?? 'pending' } catch { 'pending' }
  }
  function Wait-Checks([string]$sha) {
    $deadline = (Get-Date).AddMinutes($MaxWaitMin)
    while ($true) {
      $state = Get-CombinedStatus $sha
      Write-Host ("    · checks={0} sha={1}" -f $state, ($sha ?? '')[0..([math]::Min(6, ($sha ?? '').Length-1))] -join '')
      if ($state -eq 'success') { return $true }
      if ($state -in 'failure','error') { return $false }
      if (Get-Date -gt $deadline) { return $false }
      Start-Sleep -Seconds $PollSec
    }
  }
  function Resolve-HeadSha($prObj) {
    if ($prObj.headSha) { return $prObj.headSha }
    try { git fetch origin $prObj.headRefName --quiet | Out-Null; return (git rev-parse "origin/$($prObj.headRefName)") } catch { return $null }
  }
  function Remove-BranchIfExists([string]$name) {
    try {
      & gh api "repos/$Repo/git/refs/heads/$name" 1>$null 2>$null
      if ($LASTEXITCODE -eq 0) {
        if ($ConfirmApply) {
          Write-Host "  - Deleting remote branch $name"
          & gh api -X DELETE "repos/$Repo/git/refs/heads/$name" 1>$null
        } else {
          Write-Host "  - DRYRUN: would delete remote branch $name"
        }
      }
    } catch {}
    try { git branch -D $name 2>$null | Out-Null } catch {}
  }

  $attempt=0
  $merged=$false
  do {
    $attempt++
$prInfo = Get-PrInfo
    if ($null -eq $pr) { Exit-Kobong TRANSIENT "Failed to fetch PR info (REST)" }
    Write-Host ("[#{0}] {1} — state={2} draft={3} mergeState={4}" -f $prInfo.number, $prInfo.title, $prInfo.state, $prInfo.isDraft, ($prInfo.mergeState ?? '<n/a>'))
    Write-Host ("  head={0} base={1} sha={2}" -f $prInfo.headRefName, $prInfo.baseRefName, ($prInfo.headSha ?? '<n/a>').Substring(0, [Math]::Min(7, ($prInfo.headSha ?? '').Length)))

    if ($prInfo.isDraft) { Exit-Kobong PRECONDITION "PR is draft" }

    if ($prInfo.state -eq 'closed') {
      if (Test-PrMerged) {
        Write-Host "  - Already MERGED ✅"
        if ($PruneIfMerged) { Remove-BranchIfExists $prInfo.headRefName }
        break
      } else {
        if ($ConfirmApply) {
          Write-Host "  - PR is closed but not merged → reopening…"
          & gh pr reopen $Pr --repo $Repo 1>$null
        } else {
          Write-Host "  - DRYRUN: would reopen PR#$($Pr)"
          break
        }
      }
    }

    if ($ConfirmApply) {
      try { Update-Branch } catch { Write-Host "  - update-branch skipped/failed: $($_.Exception.Message)" }
    } else {
      Write-Host "  - DRYRUN: would call update-branch"
      break
    }
$prInfo = Get-PrInfo
    $headSha = Resolve-HeadSha $prInfo
    if (-not $headSha) { Exit-Kobong TRANSIENT "Cannot resolve head SHA" }
    if (-not (Wait-Checks $headSha)) { Exit-Kobong TRANSIENT "Checks are not green (timeout or failure)" }

    $mergeArgs = @('pr','merge',$Pr,'--repo',$Repo,"--$MergeMethod",'--delete-branch')
    Write-Host "  - Merging (attempt $attempt)…"
    $out = & gh @mergeArgs 2>&1
    if ($LASTEXITCODE -eq 0) {
      Write-Host "  - MERGED ✅"
      $merged = $true
      break
    }
    $msg = ($out | Out-String).Trim()
    Write-Host "    merge error: $msg"
    if ($msg -match 'Base branch was modified' -or $msg -match 'update required' -or $msg -match 'not mergeable' -or $msg -match 'fast-forward') {
      Write-Host "    → Base moved or not clean. Will retry after re-update."
    } else {
      Exit-Kobong LOGIC "Merge failed: $msg"
    }
  } while ($attempt -lt $MaxRetries)

  if (-not $merged -and $ConfirmApply -and $prInfo.state -ne 'closed') {
    Exit-Kobong TRANSIENT "Exceeded retries without merge (attempts=$attempt)"
  }

  Write-KLog -Level 'INFO' -Action 'pr-merge' -Outcome ($ConfirmApply ? 'SUCCESS' : 'DRYRUN') -Message "PR#$Pr state=$($prInfo.state)"
  Write-Host "[done] elapsed=$($sw.Elapsed.ToString())"
} catch {
  Write-KLog -Level 'ERROR' -Action 'pr-merge' -Outcome 'FAILURE' -ErrorCode 'Unknown' -Message $_.Exception.Message
  throw
} finally {
  Remove-Item -Force $LockFile -ErrorAction SilentlyContinue
}

