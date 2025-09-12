# scripts/check-release-notes.ps1 — release notes minimal validator (PS only)
#requires -PSEdition Core
#requires -Version 7.0
param([string]$Root = $(Get-Location).Path)

$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
$PSDefaultParameterValues['*:Encoding']        = 'utf8'

$RepoRoot = (Resolve-Path $Root).Path
$LogPath  = Join-Path $RepoRoot 'logs/apply-log.jsonl'
New-Item -ItemType Directory -Force -Path (Split-Path $LogPath) | Out-Null
function Write-JsonLog($o){ Add-Content -Path $LogPath -Value ($o | ConvertTo-Json -Depth 6 -Compress) }

function Validate-ReleaseNotes($obj) {
  if (-not ($obj.version -is [string])) { return 'version must be string (semver)' }
  if ($obj.version -notmatch '^[0-9]+\.[0-9]+\.[0-9]+(-[A-Za-z0-9.]+)?$') { return 'version must follow semver' }
  if (-not ($obj.date -is [string])) { return 'date must be string' }
  if (-not ($obj.changes -is [object[]]) -or $obj.changes.Count -lt 1) { return 'changes must be non-empty array' }
  foreach($c in $obj.changes) {
    if (-not ($c.type -is [string])) { return 'changes[].type must be string' }
    if (-not ($c.description -is [string])) { return 'changes[].description must be string' }
  }
  return $null
}

$sample = Join-Path $RepoRoot 'contracts/v1/samples/release_notes.sample.json'
if (-not (Test-Path $sample)) {
  Write-Host "[FAIL] release_notes.sample.json missing → $sample"
  Write-JsonLog @{ timestamp=(Get-Date).ToString('o'); level='ERROR'; module='release-notes'; action='validate'; outcome='FAIL'; message='sample missing'; path=$sample }
  exit 1
}

try {
  $obj = (Get-Content -LiteralPath $sample -Raw) | ConvertFrom-Json -Depth 50
} catch {
  $msg = "invalid JSON: $($_.Exception.Message)"
  Write-Host "[FAIL] $msg"
  Write-JsonLog @{ timestamp=(Get-Date).ToString('o'); level='ERROR'; module='release-notes'; action='validate'; outcome='FAIL'; message=$msg }
  exit 1
}

$err = Validate-ReleaseNotes $obj
if ($err) {
  Write-Host "[FAIL] release notes validation :: $err"
  Write-JsonLog @{ timestamp=(Get-Date).ToString('o'); level='ERROR'; module='release-notes'; action='validate'; outcome='FAIL'; message=$err }
  exit 1
}

# Optional: CHANGELOG.md sanity hints (WARN only)
$chg = Join-Path $RepoRoot 'CHANGELOG.md'
if (Test-Path $chg) {
  $raw = Get-Content -LiteralPath $chg -Raw
  if ($raw.Length -lt 10) {
    Write-JsonLog @{ timestamp=(Get-Date).ToString('o'); level='WARN'; module='release-notes'; action='changelog'; message='CHANGELOG.md seems too small' }
  }
  if ($obj.version -and ($raw -notmatch [regex]::Escape($obj.version))) {
    Write-JsonLog @{ timestamp=(Get-Date).ToString('o'); level='WARN'; module='release-notes'; action='changelog'; message=("version "+$obj.version+" not found in CHANGELOG.md") }
  }
} else {
  Write-JsonLog @{ timestamp=(Get-Date).ToString('o'); level='WARN'; module='release-notes'; action='changelog'; message='CHANGELOG.md not found (skipping)' }
}

Write-Host "[PASS] release notes OK"
Write-JsonLog @{ timestamp=(Get-Date).ToString('o'); level='INFO'; module='release-notes'; action='validate'; outcome='PASS' }
exit 0
