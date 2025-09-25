#requires -PSEdition Core
#requires -Version 7.0
param([string]$Raw,[string]$Sha,[string]$Pr,[Parameter(ValueFromRemainingArguments=$true)][string[]]$Rest)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
function Try([string]$name,[scriptblock]$code){ Write-Host "`n### $name"; try{ & $code }catch{ Write-Host "[WARN] $name: $($_.Exception.Message)" } }
Write-Host "## AK Lint"
Write-Host "- sha: $Sha"; Write-Host "- pr : $Pr"; Write-Host "- args: $Raw"
Try 'PowerShell (PSScriptAnalyzer)' {
  if (Get-Command Invoke-ScriptAnalyzer -ErrorAction SilentlyContinue) {
    Invoke-ScriptAnalyzer -Path . -Recurse -Severity @('Warning','Error') | Format-Table -AutoSize | Out-String | Write-Host
  } else { "PSScriptAnalyzer not found" }
}
Try 'Python (ruff/flake8)' {
  if (Get-Command ruff -ErrorAction SilentlyContinue) { ruff check . } elseif (Get-Command flake8 -ErrorAction SilentlyContinue) { flake8 . } else { "ruff/flake8 not found" }
}
Try 'JavaScript (ESLint)' {
  if (Get-Command npm -ErrorAction SilentlyContinue) {
    $eslint = (Get-Command eslint -ErrorAction SilentlyContinue)
    if (-not $eslint -and (Test-Path "node_modules/.bin/eslint")) { $eslint = "node_modules/.bin/eslint" }
    if ($eslint) { & $eslint . } else { "eslint not found" }
  } else { "npm not found" }
}
Write-Host "`n[AK] lint completed."