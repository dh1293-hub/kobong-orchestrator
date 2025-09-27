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

Write-Host "## AK Scan Report"
Write-Host "- sha: $Sha"
Write-Host "- pr : $Pr"
Write-Host "- args: $Raw"

function TryStep([string]$title,[scriptblock]$code){
  try {
    Write-Host "`n### $title"
    & $code
  } catch {
    Write-Host "[WARN] $($title): $($_.Exception.Message)"
  }
}

# GitHub CLI 요약(있으면)
TryStep 'GitHub auth' { if (Get-Command gh -ErrorAction SilentlyContinue){ gh auth status } else { "gh not found" } }

# 오픈 PR 요약
TryStep 'Open PRs (top 10)' {
  if (Get-Command gh -ErrorAction SilentlyContinue){
    gh pr list --state open --limit 10 --json number,title,author,updatedAt | ConvertFrom-Json | ForEach-Object {
      Write-Host ("- PR #{0} | {1} | @{2} | {3}" -f $_.number,$_.title,$_.author.login,$_.updatedAt)
    }
  } else { "gh not found" }
}

# 최근 실패/취소 런 요약
TryStep 'Recent failed runs (top 5)' {
  if (Get-Command gh -ErrorAction SilentlyContinue){
    gh run list --limit 20 --json databaseId,conclusion,displayTitle,createdAt | ConvertFrom-Json |
      Where-Object { $_.conclusion -in @('failure','cancelled','timed_out') } |
      Select-Object -First 5 |
      ForEach-Object {
        Write-Host ("- {0} | id={1} | {2}" -f $_.conclusion,$_.databaseId,$_.displayTitle)
      }
  } else { "gh not found" }
}

# Node/Package 상태 힌트
TryStep 'Node workspace hints' {
  if (Test-Path package.json) {
    $pkg = Get-Content -Raw package.json | ConvertFrom-Json
    $hasTest = $pkg.scripts.PSObject.Properties.Name -contains 'test'
    Write-Host ("- package.json present | has test script: {0}" -f $hasTest)
  } else { "package.json not found" }
}

# Python 테스트 폴더 힌트
TryStep 'Python tests hint' {
  if (Test-Path 'tests' -or Test-Path 'pytest.ini') { "- pytest likely available (tests/ or pytest.ini found)" }
  else { "pytest hints not found" }
}

Write-Host "`n[AK] scan completed."