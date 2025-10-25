# APPLY IN SHELL
# scripts/g5/synthetic-pr-workload.ps1  (v3.1 — default-branch autodetect, non-fatal PR)
#requires -Version 7.0
param(
  [switch]$ConfirmApply,
  [string]$Root,
  [string]$Owner,
  [string]$Repo,
  [string]$TargetFile = "README.md",
  [string]$PrTitle   = "[synthetic] heartbeat from GPT-5",
  [string]$PrBody    = "Automated synthetic workload: append heartbeat line and open PR (squash-ready)."
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

function Write-KLC {
  param([ValidateSet('INFO','ERROR')]$Level='INFO',[string]$Action='step',[ValidateSet('SUCCESS','FAILURE','DRYRUN')]$Outcome='SUCCESS',[string]$ErrorCode='',[string]$Message='')
  try {
    $klc = Get-Command kobong_logger_cli -ErrorAction SilentlyContinue
    if ($klc) { & $klc.Source log --level $Level --module 'step4' --action $Action --outcome $Outcome --error $ErrorCode --message $Message 2>$null; return }
  } catch {}
  $rootPath = $null
  if ($env:HAN_GPT5_ROOT) { $rootPath = $env:HAN_GPT5_ROOT }
  if (-not $rootPath) { try { $rootPath = (git rev-parse --show-toplevel 2>$null) } catch { $rootPath = (Get-Location).Path } }
  $log = Join-Path $rootPath 'logs/apply-log.jsonl'
  New-Item -ItemType Directory -Force -Path (Split-Path $log) | Out-Null
  $rec = @{ timestamp=(Get-Date).ToString('o'); level=$Level; traceId=[guid]::NewGuid().ToString(); module='step4'; action=$Action; outcome=$Outcome; errorCode=$ErrorCode; message=$Message } | ConvertTo-Json -Compress
  Add-Content -Path $log -Value $rec
}
function Exit-Kobong {
  param([ValidateSet('PRECONDITION','CONFLICT','TRANSIENT','LOGIC','Unknown')]$Category='Unknown',[string]$Message='')
  Write-KLC -Level 'ERROR' -Action 'exit' -Outcome 'FAILURE' -ErrorCode $Category -Message $Message
  $code = 1; if ($Category -eq 'PRECONDITION') { $code=10 } elseif ($Category -eq 'CONFLICT') { $code=11 } elseif ($Category -eq 'TRANSIENT') { $code=12 } elseif ($Category -eq 'LOGIC') { $code=13 }
  exit $code
}
function Get-RepoRoot {
  if ($Root) { return (Resolve-Path $Root).Path }
  $rp = (git rev-parse --show-toplevel 2>$null)
  if (-not $rp) { return (Get-Location).Path }
  return $rp
}
function Parse-OwnerRepo {
  param([string]$RepoRoot)
  if ($Owner -and $Repo) { return @{Owner=$Owner; Repo=$Repo} }
  Push-Location $RepoRoot
  try {
    $url = (git remote get-url origin 2>$null)
    if (-not $url) { Exit-Kobong 'PRECONDITION' "git origin remote not found" }
    if ($url -match 'github\.com[:/](?<owner>[^/]+)/(?<name>[^/.]+)') { return @{Owner=$Matches.owner; Repo=$Matches.name} }
    Exit-Kobong 'PRECONDITION' "cannot parse owner/repo from: $url"
  } finally { Pop-Location }
}
function Get-DefaultBranch {
  param([string]$RepoRoot)
  Push-Location $RepoRoot
  try {
    $ref = (& git symbolic-ref refs/remotes/origin/HEAD 2>$null)
    if ($LASTEXITCODE -eq 0 -and $ref -match 'refs/remotes/origin/(.+)$') { return $Matches[1] }
  } finally { Pop-Location }
  return 'main'
}
function Write-Atomic { param([string]$Path,[string]$Content)
  $dir = Split-Path -Parent $Path
  if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
  $ts  = Get-Date -Format 'yyyyMMdd-HHmmss'
  $bak = "$Path.bak-$ts"
  $tmp = Join-Path $dir ('.'+[IO.Path]::GetFileName($Path)+'.tmp')
  if (Test-Path $Path) { Copy-Item -LiteralPath $Path -Destination $bak -Force }
  $Content | Out-File -LiteralPath $tmp -Encoding utf8 -NoNewline
  Move-Item -LiteralPath $tmp -Destination $Path -Force
  return $bak
}
function Invoke-GitHub {
  param([string]$Method,[string]$Path,[object]$Body = $null,[string]$IdemKey = $null)
  $tok = $null; if ($env:GITHUB_TOKEN) { $tok=$env:GITHUB_TOKEN } elseif ($env:GH_TOKEN) { $tok=$env:GH_TOKEN } elseif ($env:GITHUB_PAT) { $tok=$env:GITHUB_PAT }
  if (-not $tok) { Exit-Kobong 'PRECONDITION' "Missing GitHub token (set GITHUB_TOKEN or GH_TOKEN with 'repo' scope)" }
  $uri = "https://api.github.com$Path"
  $hdr = @{ Authorization = "Bearer $tok"; 'User-Agent' = "kobong-step4-script"; Accept = "application/vnd.github+json" }
  if ($IdemKey) { $hdr['Idempotency-Key'] = $IdemKey }
  if ($Body -ne $null) { return Invoke-RestMethod -Method $Method -Uri $uri -Headers $hdr -Body ($Body | ConvertTo-Json -Depth 5) -ContentType 'application/json' -ErrorAction Stop }
  else { return Invoke-RestMethod -Method $Method -Uri $uri -Headers $hdr -ErrorAction Stop }
}

# ── Gate-0 ─────────────────────────────────────────────────────────────────────
$RepoRoot = Get-RepoRoot
$LockFile = Join-Path $RepoRoot '.gpt5.lock'
if (Test-Path $LockFile) { Exit-Kobong 'CONFLICT' "$LockFile exists" }
"locked $(Get-Date -Format o)" | Out-File $LockFile -Encoding utf8 -NoNewline
$sw=[Diagnostics.Stopwatch]::StartNew()
$trace=[guid]::NewGuid().ToString()
$OutcomeMode = 'DRYRUN'; if ($ConfirmApply) { $OutcomeMode = 'SUCCESS' }

$exitCode = 0
try {
  Write-KLC -Action 'preflight' -Outcome $OutcomeMode -Message ("root="+$RepoRoot+"; trace="+$trace)

  $or = Parse-OwnerRepo -RepoRoot $RepoRoot
  $owner=$or.Owner; $repo=$or.Repo
  $base  = Get-DefaultBranch -RepoRoot $RepoRoot
  $branch = "synthetic/gpt5-$([DateTime]::Now.ToString('yyyyMMdd-HHmmss'))"
  $idem   = [guid]::NewGuid().ToString()

  $target = Join-Path $RepoRoot $TargetFile
  $line   = "`n> heartbeat: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss K')  trace:$trace"
  $orig = ''
  if (Test-Path $target) { $orig = Get-Content -LiteralPath $target -Raw -ErrorAction Stop }
  $new  = if ($orig) { $orig + $line } else { "# $repo`n$line" }

  if (-not $ConfirmApply) {
    Write-KLC -Action 'preview' -Outcome 'DRYRUN' -Message ("would append heartbeat to "+$TargetFile+"; branch="+$branch+"; open PR → "+$owner+"/"+$repo)
    Write-Host "`n[PREVIEW] owner/repo : $owner/$repo"
    Write-Host "[PREVIEW] base       : $base"
    Write-Host "[PREVIEW] branch     : $branch"
    Write-Host "[PREVIEW] file       : $TargetFile (+heartbeat)`n"
    return
  }

  $bak = Write-Atomic -Path $target -Content $new
  Write-KLC -Action 'write-atomic' -Outcome 'SUCCESS' -Message ("updated "+$TargetFile+" (bak="+([IO.Path]::GetFileName($bak))+")")

  Push-Location $RepoRoot
  try {
    & git checkout -b $branch | Out-Null
    & git add -- $TargetFile
    & git commit -m "[synthetic] add heartbeat (trace:$trace)" | Out-Null
    & git push -u origin $branch | Out-Null
  } finally { Pop-Location }
  Write-KLC -Action 'git-push' -Outcome 'SUCCESS' -Message ("pushed "+$branch+" → origin (base="+$base+")")

  $prOpened = $false
  $prNumber = $null
  try {
    $pr = Invoke-GitHub -Method 'POST' -Path "/repos/$owner/$repo/pulls" -Body @{
      title = $PrTitle
      head  = $branch
      base  = $base
      body  = $PrBody + "`ntrace: $trace"
      draft = $false
      maintainer_can_modify = $true
    } -IdemKey $idem
    $prNumber = $pr.number
    $prOpened = $true
    Write-KLC -Action 'open-pr' -Outcome 'SUCCESS' -Message ("PR #"+$prNumber+" opened (idem="+$idem+")")
  } catch {
    $url="https://github.com/$owner/$repo/pull/new/$branch"
    Write-KLC -Action 'open-pr' -Outcome 'FAILURE' -ErrorCode 'TRANSIENT' -Message ("PR open via API failed: "+$_.Exception.Message+" — fallback URL "+$url)
    Write-Host "[FALLBACK] Open PR manually: $url"
    try { Start-Process $url } catch {}
    $exitCode = 0  # push 성공이므로 전체 워크로드 성공 처리
  }

  if ($prOpened -and $prNumber) {
    try {
      $merge = Invoke-GitHub -Method 'PUT' -Path "/repos/$owner/$repo/pulls/$prNumber/merge" -Body @{ merge_method='squash'; commit_title=$PrTitle; commit_message="auto-squash (trace:$trace)" }
      if ($merge.merged -eq $true) { Write-KLC -Action 'merge-pr' -Outcome 'SUCCESS' -Message ("PR #"+$prNumber+" merged") }
      else { Write-KLC -Action 'merge-pr' -Outcome 'FAILURE' -ErrorCode 'TRANSIENT' -Message ("merge not allowed yet for PR #"+$prNumber+" (checks?)") }
    } catch {
      Write-KLC -Action 'merge-pr' -Outcome 'FAILURE' -ErrorCode 'TRANSIENT' -Message ("merge attempt failed: " + $_.Exception.Message)
    }
  }

} catch {
  $exitCode = 13
  Write-KLC -Level 'ERROR' -Action 'exception' -Outcome 'FAILURE' -ErrorCode 'LOGIC' -Message $_.Exception.Message
} finally {
  $sw.Stop()
  Write-KLC -Action 'done' -Outcome $OutcomeMode -Message ("elapsed="+$sw.ElapsedMilliseconds+"ms")
  Remove-Item -Force $LockFile -ErrorAction SilentlyContinue
  if ($exitCode -ne 0) { exit $exitCode }
}