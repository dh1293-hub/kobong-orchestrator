#requires -Version 7.0
param([switch]$ConfirmApply,[string]$Root="D:\ChatGPT5_AI_Link\dosc\kobong-orchestrator")
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

function Get-RepoRoot { param([string]$r) (Resolve-Path $r).Path }
$RepoRoot = Get-RepoRoot $Root
Set-Location $RepoRoot

$LockFile = Join-Path $RepoRoot '.gpt5.lock'
if (Test-Path $LockFile) {
  $age=(Get-Item $LockFile).LastWriteTimeUtc
  if ((Get-Date).ToUniversalTime().AddMinutes(-10) -gt $age) {
    Rename-Item $LockFile ($LockFile + '.bak-' + (Get-Date -Format 'yyyyMMdd-HHmmss')) -Force
  } else { Write-Error 'CONFLICT: .gpt5.lock active.'; exit 11 }
}
"locked $(Get-Date -Format o)" | Out-File $LockFile -Encoding utf8 -NoNewline

$sw=[Diagnostics.Stopwatch]::StartNew()
$trace=[guid]::NewGuid().ToString()
function Log($m,$lvl='INFO',$code=''){
  $rec=@{timestamp=(Get-Date).ToString('o');level=$lvl;traceId=$trace;module='manifest';action='register';outcome='';durationMs=$sw.ElapsedMilliseconds;errorCode=$code;message=$m} | ConvertTo-Json -Compress
  $log=Join-Path $RepoRoot 'logs/apply-log.jsonl'
  New-Item -ItemType Directory -Force -Path (Split-Path $log) | Out-Null
  Add-Content -Path $log -Value $rec
}
function Write-Atomic([string]$Path,[string]$Content){
  $dir=Split-Path -Parent $Path
  New-Item -ItemType Directory -Force -Path $dir | Out-Null
  if (Test-Path $Path){ Copy-Item $Path ($Path + "".bak-"" + (Get-Date -Format 'yyyyMMdd-HHmmss')) -Force }
  $tmp = Join-Path $dir ('.' + [IO.Path]::GetFileName($Path) + '.tmp')
  [IO.File]::WriteAllText($tmp, $Content, [Text.UTF8Encoding]::new($false))
  Move-Item -Force $tmp $Path
}

$ManifestPath = Join-Path $RepoRoot 'Rollbackfile.json'
$PolicyPath   = Join-Path $RepoRoot '.kobong/ROLLBACK_POLICY.md'
$PatchesTxt   = Join-Path $RepoRoot '.kobong/patches.pending.txt'
$ScriptsDir   = Join-Path $RepoRoot 'scripts\g5'
$ApplyPatches = Join-Path $ScriptsDir 'apply-patches.ps1'
$RunReport    = Join-Path $ScriptsDir 'make-run-report.ps1'

$manifestJson = @'
{
  "version": 1,
  "targets": [
    ".kobong/ROLLBACK_POLICY.md",
    "Rollbackfile.json",
    ".kobong/patches.pending.txt",
    "scripts/g5/apply-patches.ps1",
    "scripts/g5/make-run-report.ps1"
  ],
  "retention": { "bak": 30, "goodSlots": 10, "redo": 3, "undo": 3 },
  "exclude": ["**/node_modules/**", "**/.rollbacks/**", "**/.git/**"]
}
'@

$policyMd = @'
# ROLLBACK_POLICY.md (초안)
## GOOD 규칙
- main 브랜치 빌드/기동 확인 후 `good` 슬롯 저장.
- UI/스크립트 변경 시 최소 1개 백업 .bak 유지(자동).

## 롤백 규칙
- 문제가 생기면 최근 `good[-1]` → `good[-10]` 순서로 복원.
- 복원 후 재현 로그 첨부, 원인 파악되면 `redo` 재적용.

## 변경 추적
- logs/apply-log.jsonl 에 모든 적용/실패 기록(UTC+9).
'@

$concat    = ($manifestJson + "`n" + $policyMd)
$bytes     = [Text.Encoding]::UTF8.GetBytes($concat)
$hashBytes = [Security.Cryptography.SHA1]::Create().ComputeHash($bytes)
$inputHash = [Convert]::ToHexString($hashBytes).ToLowerInvariant()

try {
  Write-Host "== Preview =="
  Write-Host ("RepoRoot   : {0}" -f $RepoRoot)
  Write-Host ("Manifest   : {0} (exists={1})" -f $ManifestPath,(Test-Path $ManifestPath))
  Write-Host ("Policy     : {0} (exists={1})" -f $PolicyPath,(Test-Path $PolicyPath))
  Write-Host ("InputHash  : {0}" -f $inputHash)
  if (-not $ConfirmApply) {
    Write-Host "`n[DRY-RUN] 실제 파일 변경 없음 — 적용하려면 CONFIRM_APPLY=true 로 재실행."
    Log "dry-run" "INFO"; exit 0
  }
  New-Item -ItemType Directory -Force -Path (Split-Path $PolicyPath -Parent) | Out-Null
  New-Item -ItemType Directory -Force -Path $ScriptsDir | Out-Null
  if (-not (Test-Path $PolicyPath))   { Write-Atomic $PolicyPath   $policyMd }
  if (-not (Test-Path $ManifestPath)) { Write-Atomic $ManifestPath $manifestJson }
  if (-not (Test-Path $PatchesTxt))   { Write-Atomic $PatchesTxt   "" }
  if (-not (Test-Path $ApplyPatches)) { Write-Atomic $ApplyPatches "#requires -Version 7.0`nparam([string]`$ListPath=`".kobong/patches.pending.txt`")`nWrite-Host `[stub] apply-patches — TODO`n" }
  if (-not (Test-Path $RunReport))    { Write-Atomic $RunReport  "#requires -Version 7.0`nWrite-Host `[stub] make-run-report — TODO`n" }
  Write-Host "[APPLIED] Manifest & Policy 준비 완료."
  Log "applied" "INFO"; exit 0
}
catch { Log $_.Exception.Message "ERROR" "13"; Write-Error $_.Exception.Message; exit 13 }
finally { Remove-Item -Force $LockFile -ErrorAction SilentlyContinue }