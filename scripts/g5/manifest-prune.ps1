#requires -Version 7.0
param(
  [switch]$ConfirmApply,
  [string]$Root="D:\ChatGPT5_AI_Link\dosc\kobong-orchestrator",
  [string[]]$PruneTargets = @(".kobong/ROLLBACK_POLICY.md"),   # <-- 기본값: 정책(지침) 문서만 제거
  [string[]]$PrunePatterns = @(),                               # 예: "docs/*guideline*.md"
  [switch]$RemoveFiles                                           # true면 파일도 휴지통(.trash)으로 이동
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

# Gate-0
$RepoRoot=(Resolve-Path $Root).Path
Set-Location $RepoRoot
$Lock=Join-Path $RepoRoot '.gpt5.manifest-prune.lock'
if (Test-Path $Lock){ Write-Error 'CONFLICT: .gpt5.manifest-prune.lock exists.'; exit 11 }
"locked $(Get-Date -Format o)" | Out-File $Lock -Encoding utf8 -NoNewline
$sw=[Diagnostics.Stopwatch]::StartNew()
$trace=[guid]::NewGuid().ToString()

function Log($m,$lvl='INFO',$code=''){
  $rec=@{timestamp=(Get-Date).ToString('o');level=$lvl;traceId=$trace;module='manifest';action='prune';outcome='';durationMs=$sw.ElapsedMilliseconds;errorCode=$code;message=$m} | ConvertTo-Json -Compress
  $log=Join-Path $RepoRoot 'logs/apply-log.jsonl'
  New-Item -ItemType Directory -Force -Path (Split-Path $log) | Out-Null
  Add-Content -Path $log -Value $rec
}
function Write-Atomic([string]$Path,[string]$Content){
  $dir=Split-Path -Parent $Path
  New-Item -ItemType Directory -Force -Path $dir | Out-Null
  if (Test-Path $Path){ Copy-Item $Path ($Path + ".bak-" + (Get-Date -Format 'yyyyMMdd-HHmmss')) -Force }
  $tmp=Join-Path $dir ('.'+[IO.Path]::GetFileName($Path)+'.tmp')
  [IO.File]::WriteAllText($tmp,$Content,[Text.UTF8Encoding]::new($false))
  Move-Item -Force $tmp $Path
}

$Manifest = Join-Path $RepoRoot 'Rollbackfile.json'
if (-not (Test-Path $Manifest)){ Write-Error "Manifest not found: $Manifest"; exit 10 }
$m = Get-Content $Manifest -Raw -Encoding utf8 | ConvertFrom-Json
$targets = @($m.targets)

# 후보 계산: 정확매치 + 패턴매치
$pruneExact = @()
foreach($t in $PruneTargets){ if ($t){ $pruneExact += ($t -replace '/','\') } }
$prunePattern = @()
foreach($p in $PrunePatterns){ if ($p){ $prunePattern += ($p -replace '/','\') } }

$toRemove = New-Object System.Collections.Generic.List[string]
foreach($t in $targets){
  $tt = ($t -replace '/','\')
  if ($pruneExact -contains $tt) { $toRemove.Add($t); continue }
  $hit=$false
  foreach($pat in $prunePattern){ if ($tt -like $pat){ $hit=$true; break } }
  if ($hit){ $toRemove.Add($t) }
}

# 물리 파일 목록(옵션)
$filesToTrash = @()
foreach($t in $toRemove){
  $p = Join-Path $RepoRoot $t
  if (Test-Path $p){ $filesToTrash += (Resolve-Path $p).Path }
}

# 프리뷰
Write-Host "== Manifest Prune Preview =="
Write-Host ("RepoRoot     : {0}" -f $RepoRoot)
Write-Host ("Manifest     : {0}" -f $Manifest)
Write-Host ("Will remove from targets: {0}" -f ($toRemove -join ', '))
if ($RemoveFiles){
  Write-Host ("Will move files to trash : {0}" -f ($(if($filesToTrash){$filesToTrash -join ', ' } else { '(none)' })))
} else {
  Write-Host "(files will be kept on disk; use -RemoveFiles to trash them)"
}

if (-not $ConfirmApply){
  Write-Host "`n[DRY-RUN] 변경 없음 — 적용하려면 CONFIRM_APPLY=true 로 재실행."
  Log ("dry-run remove=" + ($toRemove -join '; ')) "INFO"
  Remove-Item -Force $Lock -ErrorAction SilentlyContinue
  exit 0
}

# 실제 적용
$remaining = @()
foreach($t in $targets){ if (-not ($toRemove -contains $t)) { $remaining += $t } }
$m.targets = $remaining
$updated = ($m | ConvertTo-Json -Depth 9)
Write-Atomic $Manifest $updated
Log ("manifest pruned: removed=" + ($toRemove -join '; ')) "INFO"

if ($RemoveFiles -and $filesToTrash){
  $trashRoot = Join-Path $RepoRoot ('.trash\manifest-prune-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
  New-Item -ItemType Directory -Force -Path $trashRoot | Out-Null
  foreach($fp in $filesToTrash){
    $rel = $fp.Substring($RepoRoot.Length).TrimStart('\')
    $dest = Join-Path $trashRoot $rel
    New-Item -ItemType Directory -Force -Path (Split-Path $dest -Parent) | Out-Null
    Move-Item -LiteralPath $fp -Destination $dest -Force
  }
  Log ("files moved to trash: " + $trashRoot) "INFO"
  Write-Host "[TRASH] moved files → $trashRoot"
}

Write-Host "[APPLIED] Manifest prune complete."
Remove-Item -Force $Lock -ErrorAction SilentlyContinue