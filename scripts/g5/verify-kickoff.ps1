#requires -Version 7.0
Import-Module (Join-Path \ '..\lib\keep-open.psm1') -Force
param([string]$Root)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
$RepoRoot = if ($Root) { Resolve-Path -LiteralPath $Root } else { (git rev-parse --show-toplevel 2>$null) ?? (Get-Location).Path }
$RepoRoot = $RepoRoot.ToString(); Set-Location -LiteralPath $RepoRoot
$ok = $true
function _ok($m){ "[OK]  $m" }
function _ng($m){ "[FAIL] $m"; $script:ok=$false }
$plan1='docs/_retired_plan_A.md'
$plan2='docs/_retired_plan_B.md'
(Test-Path -LiteralPath $plan1) ? (_ok "$plan1 exists") : (_ng "$plan1 missing")
(Test-Path -LiteralPath $plan2) ? (_ok "$plan2 exists") : (_ng "$plan2 missing")
if ($env:KOBONG_DISABLE_PLANS_ALIAS -eq '1') { _ok "plans.json check skipped (disabled)" } elseif ($env:KOBONG_DISABLE_PLANS_ALIAS -eq '1') { _ok "plans.json check skipped (disabled)" } elseif (Test-Path -LiteralPath '.kobong/aliases/plans.json') {
  $j = Get-Content -LiteralPath '.kobong/aliases/plans.json' -Raw | ConvertFrom-Json
  if ($j.alias -eq '계획서') { _ok "plans.json alias='계획서'" } else { _ng "plans.json alias mismatch: $($j.alias)" }
  $okFiles = $false
  if ($j.PSObject.Properties.Name -contains 'files') {
    $okFiles = ($j.files -contains (Join-Path -Path $RepoRoot -ChildPath $plan1)) -and ($j.files -contains (Join-Path -Path $RepoRoot -ChildPath $plan2))
  }
  if (-not $okFiles -and $j.PSObject.Properties.Name -contains 'by_name') {
    $okFiles = ($j.by_name.ContainsKey((Split-Path -Leaf $plan1))) -and ($j.by_name.ContainsKey((Split-Path -Leaf $plan2)))
  }
  if ($okFiles) { _ok "plans mapping ok" } else { _ng "plans mapping incomplete" }
} else { _ng ".kobong/aliases/plans.json missing" }
(Test-Path -LiteralPath '.gitattributes') ? (_ok ".gitattributes exists") : (_ng ".gitattributes missing")
(Test-Path -LiteralPath '.editorconfig') ? (_ok ".editorconfig exists") : (_ng ".editorconfig missing")
$log = Join-Path -Path $RepoRoot -ChildPath 'logs/apply-log.jsonl'
if (Test-Path -LiteralPath $log) { _ok "logs present" } else { _ng "logs/apply-log.jsonl missing" }
"`n== SUMMARY =="; if ($ok) { "ALL GREEN ✅ — Day-1로 진행하세요." } else { "SOME CHECKS FAILED ❌ — 위 [FAIL] 먼저 처리" }

try {
  Import-Module (Join-Path $PSScriptRoot '..\lib\keep-open.psm1') -Force
  Invoke-KeepOpenIfNeeded -Reason '<patched>'
} catch {}
