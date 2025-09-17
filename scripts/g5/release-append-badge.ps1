#requires -Version 7.0
param(
  [Parameter(Mandatory=$true)][string]$Tag,
  [string]$Root,
  [string]$WatchOutput,
  [Nullable[bool]]$ChecksOk,
  [Nullable[bool]]$ReadmeOk
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'

$RepoRoot = if ($Root) { (Resolve-Path $Root).Path } else { (git rev-parse --show-toplevel 2>$null) ?? (Get-Location).Path }

$body = gh release view $Tag --json body -q .body 2>$null
if (-not $body) { $body = '' }

$rdm = if ($ReadmeOk -eq $true) { 'OK' } elseif ($ReadmeOk -eq $false) { 'NO' } else { 'UNKNOWN' }
$chk = if ($ChecksOk -eq $true) { 'OK' } elseif ($ChecksOk -eq $false) { 'NO' } else { 'UNKNOWN' }
$stamp = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss K')

if ($WatchOutput) {
  $details = '```' + "`n" + $WatchOutput + "`n" + '```'
} else {
  $details = '_(no details)_'
}

$section = @"
### Badge & Checks - $Tag
- README badge: $rdm
- Required checks: $chk
- Timestamp: $stamp

$details
"@

$newNotes = $body.TrimEnd() + "`n`n" + $section.Trim() + "`n"
$tmp = Join-Path $RepoRoot ("logs/.release-notes-" + $Tag + ".md.tmp")
$newNotes | Out-File -FilePath $tmp -Encoding utf8
gh release edit $Tag --notes-file "$tmp" | Out-Null
Write-Output "[OK] release notes updated for $Tag"