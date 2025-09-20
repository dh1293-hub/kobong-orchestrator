#requires -Version 7.0
Import-Module (Join-Path \ '..\lib\keep-open.psm1') -Force
param([switch]$ConfirmApply,[string]$Root)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }
$RepoRoot = if ($Root) { Resolve-Path -LiteralPath $Root } else { (git rev-parse --show-toplevel 2>$null) ?? (Get-Location).Path }
$RepoRoot = $RepoRoot.ToString(); Set-Location -LiteralPath $RepoRoot
$LockFile = Join-Path -Path $RepoRoot -ChildPath '.gpt5.lock'
if (Test-Path -LiteralPath $LockFile) { Write-Error 'CONFLICT: .gpt5.lock exists.'; exit 11 }
"locked $(Get-Date -Format o)" | Out-File -FilePath $LockFile -NoNewline
function Write-Log{ param([ValidateSet('INFO','ERROR')]$Level='INFO',[string]$Action='plans.repair',[ValidateSet('DRYRUN','SUCCESS','FAILURE')]$Outcome='DRYRUN',[string]$Err='',[string]$Msg='')
  $log=Join-Path -Path $RepoRoot -ChildPath 'logs/apply-log.jsonl'
  New-Item -ItemType Directory -Force -Path (Split-Path -Path $log) | Out-Null
  $rec=@{timestamp=(Get-Date).ToString('o');level=$Level;traceId=[guid]::NewGuid().ToString();module='scripts';action=$Action;outcome=$Outcome;errorCode=$Err;message=$Msg} | ConvertTo-Json -Compress
  Add-Content -Path $log -Value $rec
}
function Set-AtomicFile{ param([Parameter(Mandatory)][string]$Path,[Parameter(Mandatory)][string]$Content)
  $full=Join-Path -Path $RepoRoot -ChildPath $Path; $dir=Split-Path -Path $full
  New-Item -ItemType Directory -Force -Path $dir | Out-Null
  $ts=(Get-Date -Format 'yyyyMMdd-HHmmss'); $tmp="$full.tmp-$([guid]::NewGuid().ToString('n'))"
  $utf8=[Text.UTF8Encoding]::new($false); [IO.File]::WriteAllText($tmp,$Content,$utf8)
  if (Test-Path -LiteralPath $full){ Copy-Item -LiteralPath $full -Destination "$full.bak-$ts" -Force }
  Move-Item -LiteralPath $tmp -Destination $full -Force
}
$plan1Name='_retired_plan_A.md'
$plan2Name='_retired_plan_B.md'
$dest1 = Join-Path -Path $RepoRoot -ChildPath ("docs\" + $plan1Name)
$dest2 = Join-Path -Path $RepoRoot -ChildPath ("docs\" + $plan2Name)
$ParentDir = Split-Path -Path $RepoRoot -Parent
$candidates1 = @(
  (Join-Path -Path $RepoRoot  -ChildPath $plan1Name)
  $dest1
  (Join-Path -Path $ParentDir -ChildPath $plan1Name)
) | Where-Object { Test-Path -LiteralPath $_ }
$candidates2 = @(
  (Join-Path -Path $RepoRoot  -ChildPath $plan2Name)
  $dest2
  (Join-Path -Path $ParentDir -ChildPath $plan2Name)
) | Where-Object { Test-Path -LiteralPath $_ }
$src1 = $candidates1 | Select-Object -First 1
$src2 = $candidates2 | Select-Object -First 1
if (-not $ConfirmApply) {
  "== Dry-Run =="; "RepoRoot: $RepoRoot"; "Plan1 src: $src1"; "Plan2 src: $src2"; "Plan1 dst: $dest1"; "Plan2 dst: $dest2"
  "Would ensure docs/ and copy if src is outside."; "Would write .kobong/aliases/plans.json (v2)."
  Write-Log -Outcome 'DRYRUN' -Msg 'preview repair'; Remove-Item -Force $LockFile -ErrorAction SilentlyContinue; exit 0
}
try{
  if (-not $src1) { Write-Log -Level ERROR -Outcome FAILURE -Err 'PRECONDITION' -Msg "missing $plan1Name anywhere"; exit 10 }
  if (-not $src2) { Write-Log -Level ERROR -Outcome FAILURE -Err 'PRECONDITION' -Msg "missing $plan2Name anywhere"; exit 10 }
  New-Item -ItemType Directory -Force -Path (Join-Path -Path $RepoRoot -ChildPath 'docs') | Out-Null
  if ($src1 -ne $dest1) { $c1 = Get-Content -LiteralPath $src1 -Raw -Encoding UTF8; Set-AtomicFile -Path ("docs\" + $plan1Name) -Content $c1 }
  if ($src2 -ne $dest2) { $c2 = Get-Content -LiteralPath $src2 -Raw -Encoding UTF8; Set-AtomicFile -Path ("docs\" + $plan2Name) -Content $c2 }
  $plansObj = [ordered]@{
    alias='계획서'
    files=@($dest1,$dest2)
    by_name=@{ $plan1Name='계획서'; $plan2Name='계획서' }
    group=@{ '계획서'=@($plan1Name,$plan2Name) }
    lastUpdated=(Get-Date).ToString('o')
    version=2
  } | ConvertTo-Json -Depth 6
if ($env:KOBONG_DISABLE_PLANS_ALIAS -ne '1') { Set-AtomicFile -Path '.kobong/aliases/plans.json' -Content $plansObj }
  Write-Log -Outcome 'SUCCESS' -Msg 'plans moved/mapped'
  # Verify
  $ok=$true; function _ok($m){ "[OK]  $m" }; function _ng($m){ "[FAIL] $m"; $script:ok=$false }
  foreach ($p in @($dest1,$dest2)) { if (Test-Path -LiteralPath $p) { _ok "$([IO.Path]::GetFileName($p)) present in repo/docs" } else { _ng "$([IO.Path]::GetFileName($p)) missing in repo/docs" } }
  $j = Get-Content -LiteralPath '.kobong/aliases/plans.json' -Raw | ConvertFrom-Json
  if ($j.PSObject.Properties.Name -contains 'files' -and ($j.files -contains $dest1) -and ($j.files -contains $dest2)) { _ok "plans.json.files ok" } else { _ng "plans.json.files missing item" }
  if ($j.by_name.$plan1Name -eq '계획서' -and $j.by_name.$plan2Name -eq '계획서') { _ok "plans.json.by_name ok" } else { _ng "plans.json.by_name mismatch" }
  if ($j.group.'계획서' -and $j.group.'계획서'.Count -ge 2) { _ok "plans.json.group ok" } else { _ng "plans.json.group missing/short" }
  "`n== SUMMARY =="; if ($ok) { "ALL GREEN ✅ — Day-1로 진행하세요." } else { "SOME CHECKS FAILED ❌ — 위 [FAIL] 먼저 처리" }
} catch { Write-Log -Level 'ERROR' -Outcome 'FAILURE' -Err 'LOGIC' -Msg $_.Exception.Message; exit 13 } finally { Remove-Item -Force $LockFile -ErrorAction SilentlyContinue }

try {
  Import-Module (Join-Path $PSScriptRoot '..\lib\keep-open.psm1') -Force
  Invoke-KeepOpenIfNeeded -Reason '<patched>'
} catch {}
