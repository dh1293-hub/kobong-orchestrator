#requires -PSEdition Core
#requires -Version 7.0
param([string]$Raw,[string]$Sha,[string]$Pr,[Parameter(ValueFromRemainingArguments=$true)][string[]]$Rest)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
function Try([string]$name,[scriptblock]$code){ Write-Host "`n### $name"; try{ & $code }catch{ Write-Host "[WARN] $name: $($_.Exception.Message)" } }
Write-Host "## AK Format Check"
Write-Host "- sha: $Sha"; Write-Host "- pr : $Pr"; Write-Host "- args: $Raw"
Try 'Prettier --check' {
  if (Get-Command npm -ErrorAction SilentlyContinue) {
    $prettier = (Get-Command prettier -ErrorAction SilentlyContinue)
    if (-not $prettier -and (Test-Path "node_modules/.bin/prettier")) { $prettier = "node_modules/.bin/prettier" }
    if ($prettier) { & $prettier --check . } else { "prettier not found" }
  } else { "npm not found" }
}
Try 'black --check & isort --check-only' {
  $had = $false
  if (Get-Command black -ErrorAction SilentlyContinue) { $had = $true; black --check . || $true } else { "black not found" }
  if (Get-Command isort -ErrorAction SilentlyContinue) { $had = $true; isort --check-only . || $true } else { "isort not found" }
  if (-not $had) { "black/isort not found" }
}
Write-Host "`n[AK] fmt completed."