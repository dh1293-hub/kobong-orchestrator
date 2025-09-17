# APPLY IN SHELL
#requires -Version 7.0
param(
  [switch]$ConfirmApply,
  [string]$Root='.',
  [string]$Version='',                 # e.g. v0.1.11 (비우면 마지막 태그 자동)
  [string]$WorkflowPath='.github/workflows/release-docs.yml'
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

$RepoRoot = (Resolve-Path $Root).Path
Set-Location $RepoRoot
git fetch -p origin --tags | Out-Null

if (-not $Version) {
  $Version = (git tag --list "v*" --sort=-v:refname | Select-Object -First 1)
  if (-not $Version) { throw "No release tag detected" }
}

# 워크플로 ID 해석
$wf = $null
try {
  $wf = (gh api repos/:owner/:repo/actions/workflows | ConvertFrom-Json).workflows | Where-Object { $_.path -eq $WorkflowPath } | Select-Object -First 1
} catch {}
if (-not $wf) { Write-Host "[warn] workflow not found at $WorkflowPath — skipping dispatch" }

# 1) release-docs 트리거
if ($wf -and $ConfirmApply) {
  gh workflow run $wf.id --ref main 2>$null | Out-Null
  Write-Host "[ok] workflow dispatch created for $($wf.name)"
} elseif ($wf) {
  Write-Host "[DRY-RUN] would run workflow id=$($wf.id) --ref main"
}

# 2) 배지 브랜치 PR 처리
$rb = "docs/readme-badge-$Version"
$prNum=$null
$exists = git ls-remote --heads origin $rb
if ($exists) {
  try { $prNum = gh pr list --head $rb --limit 1 --json "number" --jq ".[0].number" 2>$null } catch {}
  if ($ConfirmApply -and -not $prNum) {
    $title="docs(readme): update release badge ($rb)"
    $body ="Automated badge refresh."
    gh pr create -H $rb -B main -t $title -b $body | Write-Host
    try { $prNum = gh pr list --head $rb --limit 1 --json "number" --jq ".[0].number" 2>$null } catch {}
  }
  if ($prNum) {
    if ($ConfirmApply) {
      gh pr merge $prNum --squash --auto 2>$null; if ($LASTEXITCODE -ne 0) { gh pr merge $prNum --squash }
      gh pr checks $prNum --watch
    } else { Write-Host "[DRY-RUN] would merge PR #$prNum (squash)" }
  } else {
    Write-Host "[info] No PR detected for $rb (yet)."
  }
} else {
  Write-Host "[wait] $rb not on origin yet — workflow may still be preparing it."
}

# 3) 검증
git switch main | Out-Null
git pull --ff-only | Out-Null
$okLink = Select-String -Path 'README.md' -Pattern ("releases/tag/{0}" -f $Version) -SimpleMatch -ErrorAction SilentlyContinue
$badEsc = Select-String -Path 'README.md' -Pattern ($Version -replace '\.','\.') -SimpleMatch -ErrorAction SilentlyContinue
if ($okLink) { Write-Host "[OK] README link → releases/tag/$Version" } else { Write-Host "[WAIT] README not yet $Version — rerun later" }
if ($badEsc) { Write-Host "[FAIL] Escaped '$($Version -replace '\.','\.')' still present" } else { Write-Host "[OK] No escaped version remnants" }
$chOK = Select-String -Path 'CHANGELOG.md' -Pattern $Version -SimpleMatch -ErrorAction SilentlyContinue
if ($chOK) { Write-Host "[OK] CHANGELOG mentions $Version" } else { Write-Host "[WARN] CHANGELOG missing $Version" }