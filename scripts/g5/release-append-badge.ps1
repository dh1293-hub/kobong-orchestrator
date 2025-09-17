#requires -Version 7.0
param(
  [Parameter(Mandatory=$true)][string]$Tag,
  [string]$Root,
  [string]$WatchOutput,
  [nullable[bool]]$ChecksOk,
  [nullable[bool]]$ReadmeOk
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'

function Resolve-RepoRoot {
  param([string]$Root)
  if (-not [string]::IsNullOrWhiteSpace($Root)) { return (Resolve-Path $Root).Path }
  $top = (& git rev-parse --show-toplevel 2>$null)
  if ($top) { return $top }
  return (Get-Location).Path
}
$RepoRoot = Resolve-RepoRoot -Root $Root
Set-Location $RepoRoot

# owner/repo 추출
$remote = git remote get-url origin
if ($remote -match 'github\.com[:/](.+?)/(.+?)(?:\.git)?$') {
  $owner=$Matches[1]; $repo=$Matches[2]
} else { throw "Cannot parse origin URL: $remote" }

# 기존 노트(body) 읽기
$info = gh release view $Tag --json body 2>$null | ConvertFrom-Json
$body = $info.body ?? ''

# watch 결과 파싱
$checks = $ChecksOk
$readme = $ReadmeOk
if (-not $checks.HasValue -and $WatchOutput) { $checks = [bool]([regex]::IsMatch($WatchOutput,'checks\s*=\s*True','IgnoreCase')) }
if (-not $readme.HasValue -and $WatchOutput) { $readme = [bool]([regex]::IsMatch($WatchOutput,'readme\s*=\s*True','IgnoreCase')) }

$stamp = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss (KST)')
$chk = if ($checks) { '✅' } else { '❌' }
$rdm = if ($readme) { '✅' } else { '❌' }

# <- 여기를 if/else 문으로 수정
if ($WatchOutput) {
  $details = "```
$WatchOutput
```"
} else {
  $details = "_(no details)_"
}

$section = @"
### Badge & Checks — $Tag
- README badge: $rdm
- Required checks: $chk
- Timestamp: $stamp

$details
"@

$newNotes = ($body.TrimEnd() + "`n`n" + $section.Trim() + "`n")

# 임시파일로 안전 편집
$tmp = Join-Path $RepoRoot ('logs\.release-notes-'+$Tag+'.md.tmp')
$newNotes | Out-File -FilePath $tmp -Encoding utf8
gh release edit $Tag --notes-file "$tmp" | Out-Null
Write-Host "[OK] release notes updated for $Tag"
