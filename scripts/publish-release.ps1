<# PS-17.1 (v3, ASCII-safe) — publish-release.ps1
  Purpose: Create/Update GitHub Release from the latest CHANGELOG section for the current tag.
  Usage:
    .\scripts\publish-release.ps1 -DryRun
    .\scripts\publish-release.ps1
  Req:
    - env GITHUB_TOKEN (repo)
    - git (origin on GitHub)
#>

param(
  [switch]$DryRun,
  [string]$Repo,
  [string]$Token
)

$ErrorActionPreference = 'Stop'
$logDir = "logs"
$logPath = Join-Path $logDir "release.log"
if (!(Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir | Out-Null }

function Say([string]$msg, [string]$level = "INFO") {
  $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
  $line = "$ts [$level] $msg"
  Write-Host $line
  Add-Content -Path $logPath -Value $line
}
function Warn([string]$msg) { Write-Host $msg -ForegroundColor DarkYellow; Say $msg "WARN" }
function Fail([string]$msg) { Write-Host $msg -ForegroundColor Red; Say $msg "ERROR"; exit 1 }

# 1) token
$Token = if ($Token) { $Token } elseif ($env:GITHUB_TOKEN) { $env:GITHUB_TOKEN } else { "" }
if (-not $Token -and -not $DryRun) { Fail "GITHUB_TOKEN missing. Set it and retry." }
elseif (-not $Token -and $DryRun) { Warn "[DryRun] No token — API calls will be skipped." }

# 2) repo (owner/name)
function Get-RepoFromGit {
  try { $url = (git remote get-url origin).Trim() } catch { return $null }
  if ($url -match "github\.com[:/](?<owner>[^/]+)/(?<name>[^\.]+)(\.git)?$") { return "$($Matches.owner)/$($Matches.name)" }
  return $null
}
if (-not $Repo) { $Repo = Get-RepoFromGit }
if (-not $Repo) { Fail "Cannot infer repo from origin. Use -Repo owner/name." }

Say "Repo       : $Repo"
Say "DryRun     : $DryRun"

# 3) tag
function Get-Tag {
  $headTags = git tag --points-at HEAD | Where-Object { $_ -match '^v\d+\.\d+\.\d+$' }
  if ($headTags) { return ($headTags | Sort-Object -Descending | Select-Object -First 1).Trim() }
  return (git describe --tags --abbrev=0).Trim()
}
$tag = Get-Tag
if (-not $tag) { Fail "No version tag found. Create vX.Y.Z first." }
Say "Tag        : $tag"

# 4) changelog section
$changelogPath = "CHANGELOG.md"
if (!(Test-Path $changelogPath)) { Fail "CHANGELOG.md not found." }
$cl = Get-Content $changelogPath -Raw

$ver = $tag.TrimStart('v')
$pattern = "(?ms)^##\s*(?:\[$ver\]|$ver)\b.*?(?=^##\s*|\Z)"
$match = [regex]::Match($cl, $pattern)
if (-not $match.Success) { Fail "CHANGELOG section for version $ver not found." }
$body = $match.Value.Trim()
if ($body -match '^\s*$') { Fail "Extracted release notes are empty." }

Say ("Changelog  : section length {0} chars" -f $body.Length)

# 5) GitHub API
$api = "https://api.github.com"
$headers = @{ "Accept"="application/vnd.github+json"; "User-Agent"="release-notes-script" }
if (-not $DryRun) { $headers["Authorization"] = "Bearer $Token" }

if ($DryRun) {
  Warn "[DryRun] Preview only. No API call."
  Write-Host "---- name ----" -ForegroundColor DarkYellow
  Write-Host $tag
  Write-Host "---- body (preview) ----" -ForegroundColor DarkYellow
  Write-Host $body
  exit 0
}

# existing release?
$release = $null
try {
  $release = Invoke-RestMethod -Method GET -Headers $headers -Uri "$api/repos/$Repo/releases/tags/$tag"
  Say ("Existing   : release_id={0}" -f $release.id)
} catch {
  Say "Existing   : none (will create)"
}

if ($release) {
  $payload = @{ name = $tag; body = $body } | ConvertTo-Json -Depth 5
  $res = Invoke-RestMethod -Method PATCH -Headers $headers -ContentType 'application/json' -Uri "$api/repos/$Repo/releases/$($release.id)" -Body $payload
  Say ("Updated    : {0}" -f $res.html_url)
  Write-Host ("GitHub Release UPDATED: {0}" -f $res.html_url) -ForegroundColor Green
} else {
  $payload = @{ tag_name=$tag; name=$tag; body=$body; draft=$false; prerelease=$false } | ConvertTo-Json -Depth 5
  $res = Invoke-RestMethod -Method POST -Headers $headers -ContentType 'application/json' -Uri "$api/repos/$Repo/releases" -Body $payload
  Say ("Created    : {0}" -f $res.html_url)
  Write-Host ("GitHub Release CREATED: {0}" -f $res.html_url) -ForegroundColor Green
}
