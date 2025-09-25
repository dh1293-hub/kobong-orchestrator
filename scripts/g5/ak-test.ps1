#requires -PSEdition Core
#requires -Version 7.0
param(
  [string]$Raw,
  [string]$Sha,
  [string]$Pr,
  [Parameter(ValueFromRemainingArguments=$true)][string[]]$Rest
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'

$fast = $Rest -contains '--fast'

function Step([string]$name,[scriptblock]$code){
  Write-Host "`n### $name"
  try { & $code } catch { Write-Host "[WARN] $name: $($_.Exception.Message)" }
}

Write-Host "## AK Test Runner"
Write-Host "- sha: $Sha"
Write-Host "- pr : $Pr"
Write-Host "- args: $Raw"

# 1) Pester (PowerShell)
Step 'Pester' {
  if (Get-Command Invoke-Pester -ErrorAction SilentlyContinue) {
    Invoke-Pester -CI -Passthru | Out-String | Write-Host
  } else { "Pester not found" }
}

if (-not $fast) {
  # 2) PyTest (Python)
  Step 'PyTest' {
    if (Get-Command python -ErrorAction SilentlyContinue -CommandType Application -ErrorVariable +e -OutVariable +o) {
      if (Get-Command pytest -ErrorAction SilentlyContinue) {
        pytest -q
      } else { "pytest not found" }
    } else { "python not found" }
  }

  # 3) npm test (Node)
  Step 'npm test' {
    if (Get-Command npm -ErrorAction SilentlyContinue -CommandType Application) {
      if (Test-Path package.json) {
        $pkg = Get-Content -Raw package.json | ConvertFrom-Json
        if ($pkg.scripts.PSObject.Properties.Name -contains 'test') { npm test --silent } else { "no test script" }
      } else { "package.json not found" }
    } else { "npm not found" }
  }
}

Write-Host "`n[AK] test completed."