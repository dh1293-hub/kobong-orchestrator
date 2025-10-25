#requires -PSEdition Core
#requires -Version 7.0
param([string]$Raw,[string]$Sha,[string]$Pr,[Parameter(ValueFromRemainingArguments=$true)][string[]]$Args)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) { Write-Host "gh not found"; exit 0 }
# 인자 파싱
$apply = $Args -contains '--apply'
$draft = $Args -contains '--draft'
$pre   = $Args -contains '--prerelease'
# 태그
$tag = $null; $notes = $null
foreach ($a in $Args) {
  if ($a -match '^(v?\d+\.\d+\.\d+.*)$') { $tag = $matches[1] }
}
for ($i=0; $i -lt $Args.Count; $i++) {
  if ($Args[$i] -eq '--notes' -and $i+1 -lt $Args.Count) { $notes = $Args[$i+1] }
}
if (-not $tag) { $tag = 'v0.0.0-ak-' + (Get-Date -Format 'yyyyMMdd-HHmmss') }

Write-Host "## AK Release"
Write-Host "- tag : $tag"
Write-Host "- draft: $draft"
Write-Host "- prerelease: $pre"
Write-Host "- mode: " + ($apply ? 'APPLY' : 'DRYRUN')

$flags = @($tag, '--generate-notes')
if ($draft) { $flags += '--draft' }
if ($pre)   { $flags += '--prerelease' }
if ($notes) { $flags += @('--notes', $notes) }

if ($apply) {
  gh release create @flags
} else {
  Write-Host "[AK] would run: gh release create $($flags -join ' ')"
}
Write-Host "[AK] release done."