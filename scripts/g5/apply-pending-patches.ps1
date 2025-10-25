# APPLY IN SHELL
#requires -Version 7.0
param([switch]$ConfirmApply,[string]$Root)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

# ── Gate-0: Repo / Lock ─────────────────────────────────────────────────────────
function Get-RepoRoot {
  try {
    $p = (git rev-parse --show-toplevel 2>$null)
    if ($p) { return (Resolve-Path $p).Path }
  } catch {}
  if ($Root) { return (Resolve-Path $Root).Path }
  return (Get-Location).Path
}
$RepoRoot = Get-RepoRoot
$LockFile = Join-Path $RepoRoot '.gpt5.lock'
if (Test-Path $LockFile) { Write-Error 'CONFLICT: .gpt5.lock exists.'; exit 11 }
"locked $(Get-Date -Format o)" | Out-File $LockFile -Encoding utf8 -NoNewline

$sw=[Diagnostics.Stopwatch]::StartNew()
$trace=[guid]::NewGuid().ToString()
$logPath = Join-Path $RepoRoot 'logs/apply-log.jsonl'
New-Item -ItemType Directory -Force -Path (Split-Path $logPath) | Out-Null

function LogRec([string]$level,[string]$action,[string]$outcome,[string]$msg,[string]$err='') {
  $rec = @{
    timestamp=(Get-Date).ToString('o'); level=$level; traceId=$trace; module='patcher';
    action=$action; inputHash=((Get-Variable -Name patchHash -Scope Global -ValueOnly -ErrorAction SilentlyContinue) ?? ""); outcome=$outcome;
    durationMs=$sw.ElapsedMilliseconds; errorCode=$err; message=$msg
  } | ConvertTo-Json -Compress
  Add-Content -Path $logPath -Value $rec
}

try {
  # ── Preflight: 모듈 로드 & 스모크 ─────────────────────────────────────────────
  $ModPath = Join-Path $RepoRoot 'scripts\lib\kobong-fileio.psm1'
  if (!(Test-Path $ModPath)) {
  Write-Host "[WARN] Missing module → $ModPath (continuing)"
  try { LogRec "WARN" "apply" "SKIPPED" ("missing-module: "+$ModPath) } catch {}
} else {
  try { Import-Module $ModPath -Force } catch { Write-Host ("[WARN] Import-Module failed -> " + $ModPath + ": " + # APPLY IN SHELL
#requires -Version 7.0
param([switch]$ConfirmApply,[string]$Root)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

# ── Gate-0: Repo / Lock ─────────────────────────────────────────────────────────
function Get-RepoRoot {
  try {
    $p = (git rev-parse --show-toplevel 2>$null)
    if ($p) { return (Resolve-Path $p).Path }
  } catch {}
  if ($Root) { return (Resolve-Path $Root).Path }
  return (Get-Location).Path
}
$RepoRoot = Get-RepoRoot
$LockFile = Join-Path $RepoRoot '.gpt5.lock'
if (Test-Path $LockFile) { Write-Error 'CONFLICT: .gpt5.lock exists.'; exit 11 }
"locked $(Get-Date -Format o)" | Out-File $LockFile -Encoding utf8 -NoNewline

$sw=[Diagnostics.Stopwatch]::StartNew()
$trace=[guid]::NewGuid().ToString()
$logPath = Join-Path $RepoRoot 'logs/apply-log.jsonl'
New-Item -ItemType Directory -Force -Path (Split-Path $logPath) | Out-Null

function LogRec([string]$level,[string]$action,[string]$outcome,[string]$msg,[string]$err='') {
  $rec = @{
    timestamp=(Get-Date).ToString('o'); level=$level; traceId=$trace; module='patcher';
    action=$action; inputHash=((Get-Variable -Name patchHash -Scope Global -ValueOnly -ErrorAction SilentlyContinue) ?? ""); outcome=$outcome;
    durationMs=$sw.ElapsedMilliseconds; errorCode=$err; message=$msg
  } | ConvertTo-Json -Compress
  Add-Content -Path $logPath -Value $rec
}

try {
  # ── Preflight: 모듈 로드 & 스모크 ─────────────────────────────────────────────
  $ModPath = Join-Path $RepoRoot 'scripts\lib\kobong-fileio.psm1'
  if (!(Test-Path $ModPath)) {
  Write-Host "[WARN] Missing module → $ModPath (continuing)"
  try { LogRec "WARN" "apply" "SKIPPED" ("missing-module: "+$ModPath) } catch {}
} else {
  try { Import-Module $ModPath -Force } catch { Write-Host "[WARN] Import-Module failed → $ModPath: $(# APPLY IN SHELL
#requires -Version 7.0
param([switch]$ConfirmApply,[string]$Root)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

# ── Gate-0: Repo / Lock ─────────────────────────────────────────────────────────
function Get-RepoRoot {
  try {
    $p = (git rev-parse --show-toplevel 2>$null)
    if ($p) { return (Resolve-Path $p).Path }
  } catch {}
  if ($Root) { return (Resolve-Path $Root).Path }
  return (Get-Location).Path
}
$RepoRoot = Get-RepoRoot
$LockFile = Join-Path $RepoRoot '.gpt5.lock'
if (Test-Path $LockFile) { Write-Error 'CONFLICT: .gpt5.lock exists.'; exit 11 }
"locked $(Get-Date -Format o)" | Out-File $LockFile -Encoding utf8 -NoNewline

$sw=[Diagnostics.Stopwatch]::StartNew()
$trace=[guid]::NewGuid().ToString()
$logPath = Join-Path $RepoRoot 'logs/apply-log.jsonl'
New-Item -ItemType Directory -Force -Path (Split-Path $logPath) | Out-Null

function LogRec([string]$level,[string]$action,[string]$outcome,[string]$msg,[string]$err='') {
  $rec = @{
    timestamp=(Get-Date).ToString('o'); level=$level; traceId=$trace; module='patcher';
    action=$action; inputHash=((Get-Variable -Name patchHash -Scope Global -ValueOnly -ErrorAction SilentlyContinue) ?? ""); outcome=$outcome;
    durationMs=$sw.ElapsedMilliseconds; errorCode=$err; message=$msg
  } | ConvertTo-Json -Compress
  Add-Content -Path $logPath -Value $rec
}

try {
  # ── Preflight: 모듈 로드 & 스모크 ─────────────────────────────────────────────
  $ModPath = Join-Path $RepoRoot 'scripts\lib\kobong-fileio.psm1'
  if (!(Test-Path $ModPath)) { throw "Missing module: $ModPath" }
try { Import-Module $ModPath -Force } catch { Write-Host "[WARN] Import-Module failed → $ModPath: $(# APPLY IN SHELL
#requires -Version 7.0
param([switch]$ConfirmApply,[string]$Root)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

# ── Gate-0: Repo / Lock ─────────────────────────────────────────────────────────
function Get-RepoRoot {
  try {
    $p = (git rev-parse --show-toplevel 2>$null)
    if ($p) { return (Resolve-Path $p).Path }
  } catch {}
  if ($Root) { return (Resolve-Path $Root).Path }
  return (Get-Location).Path
}
$RepoRoot = Get-RepoRoot
$LockFile = Join-Path $RepoRoot '.gpt5.lock'
if (Test-Path $LockFile) { Write-Error 'CONFLICT: .gpt5.lock exists.'; exit 11 }
"locked $(Get-Date -Format o)" | Out-File $LockFile -Encoding utf8 -NoNewline

$sw=[Diagnostics.Stopwatch]::StartNew()
$trace=[guid]::NewGuid().ToString()
$logPath = Join-Path $RepoRoot 'logs/apply-log.jsonl'
New-Item -ItemType Directory -Force -Path (Split-Path $logPath) | Out-Null

function LogRec([string]$level,[string]$action,[string]$outcome,[string]$msg,[string]$err='') {
  $rec = @{
    timestamp=(Get-Date).ToString('o'); level=$level; traceId=$trace; module='patcher';
    action=$action; inputHash=((Get-Variable -Name patchHash -Scope Global -ValueOnly -ErrorAction SilentlyContinue) ?? ""); outcome=$outcome;
    durationMs=$sw.ElapsedMilliseconds; errorCode=$err; message=$msg
  } | ConvertTo-Json -Compress
  Add-Content -Path $logPath -Value $rec
}

try {
  # ── Preflight: 모듈 로드 & 스모크 ─────────────────────────────────────────────
  $ModPath = Join-Path $RepoRoot 'scripts\lib\kobong-fileio.psm1'
  if (!(Test-Path $ModPath)) { throw "Missing module: $ModPath" }
try { Import-Module $ModPath -Force } catch { Write-Host ("[WARN] Import-Module failed -> " + $ModPath + ": " + # APPLY IN SHELL
#requires -Version 7.0
param([switch]$ConfirmApply,[string]$Root)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

# ── Gate-0: Repo / Lock ─────────────────────────────────────────────────────────
function Get-RepoRoot {
  try {
    $p = (git rev-parse --show-toplevel 2>$null)
    if ($p) { return (Resolve-Path $p).Path }
  } catch {}
  if ($Root) { return (Resolve-Path $Root).Path }
  return (Get-Location).Path
}
$RepoRoot = Get-RepoRoot
$LockFile = Join-Path $RepoRoot '.gpt5.lock'
if (Test-Path $LockFile) { Write-Error 'CONFLICT: .gpt5.lock exists.'; exit 11 }
"locked $(Get-Date -Format o)" | Out-File $LockFile -Encoding utf8 -NoNewline

$sw=[Diagnostics.Stopwatch]::StartNew()
$trace=[guid]::NewGuid().ToString()
$logPath = Join-Path $RepoRoot 'logs/apply-log.jsonl'
New-Item -ItemType Directory -Force -Path (Split-Path $logPath) | Out-Null

function LogRec([string]$level,[string]$action,[string]$outcome,[string]$msg,[string]$err='') {
  $rec = @{
    timestamp=(Get-Date).ToString('o'); level=$level; traceId=$trace; module='patcher';
    action=$action; inputHash=((Get-Variable -Name patchHash -Scope Global -ValueOnly -ErrorAction SilentlyContinue) ?? ""); outcome=$outcome;
    durationMs=$sw.ElapsedMilliseconds; errorCode=$err; message=$msg
  } | ConvertTo-Json -Compress
  Add-Content -Path $logPath -Value $rec
}

try {
  # ── Preflight: 모듈 로드 & 스모크 ─────────────────────────────────────────────
  $ModPath = Join-Path $RepoRoot 'scripts\lib\kobong-fileio.psm1'
  if (!(Test-Path $ModPath)) {
  Write-Host "[WARN] Missing module → $ModPath (continuing)"
  try { LogRec "WARN" "apply" "SKIPPED" ("missing-module: "+$ModPath) } catch {}
} else {
  try { Import-Module $ModPath -Force } catch { Write-Host ("[WARN] Import-Module failed -> " + $ModPath + ": " + # APPLY IN SHELL
#requires -Version 7.0
param([switch]$ConfirmApply,[string]$Root)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

# ── Gate-0: Repo / Lock ─────────────────────────────────────────────────────────
function Get-RepoRoot {
  try {
    $p = (git rev-parse --show-toplevel 2>$null)
    if ($p) { return (Resolve-Path $p).Path }
  } catch {}
  if ($Root) { return (Resolve-Path $Root).Path }
  return (Get-Location).Path
}
$RepoRoot = Get-RepoRoot
$LockFile = Join-Path $RepoRoot '.gpt5.lock'
if (Test-Path $LockFile) { Write-Error 'CONFLICT: .gpt5.lock exists.'; exit 11 }
"locked $(Get-Date -Format o)" | Out-File $LockFile -Encoding utf8 -NoNewline

$sw=[Diagnostics.Stopwatch]::StartNew()
$trace=[guid]::NewGuid().ToString()
$logPath = Join-Path $RepoRoot 'logs/apply-log.jsonl'
New-Item -ItemType Directory -Force -Path (Split-Path $logPath) | Out-Null

function LogRec([string]$level,[string]$action,[string]$outcome,[string]$msg,[string]$err='') {
  $rec = @{
    timestamp=(Get-Date).ToString('o'); level=$level; traceId=$trace; module='patcher';
    action=$action; inputHash=((Get-Variable -Name patchHash -Scope Global -ValueOnly -ErrorAction SilentlyContinue) ?? ""); outcome=$outcome;
    durationMs=$sw.ElapsedMilliseconds; errorCode=$err; message=$msg
  } | ConvertTo-Json -Compress
  Add-Content -Path $logPath -Value $rec
}

try {
  # ── Preflight: 모듈 로드 & 스모크 ─────────────────────────────────────────────
  $ModPath = Join-Path $RepoRoot 'scripts\lib\kobong-fileio.psm1'
  if (!(Test-Path $ModPath)) {
  Write-Host "[WARN] Missing module → $ModPath (continuing)"
  try { LogRec "WARN" "apply" "SKIPPED" ("missing-module: "+$ModPath) } catch {}
} else {
  try { Import-Module $ModPath -Force } catch { Write-Host "[WARN] Import-Module failed → $ModPath: $(# APPLY IN SHELL
#requires -Version 7.0
param([switch]$ConfirmApply,[string]$Root)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

# ── Gate-0: Repo / Lock ─────────────────────────────────────────────────────────
function Get-RepoRoot {
  try {
    $p = (git rev-parse --show-toplevel 2>$null)
    if ($p) { return (Resolve-Path $p).Path }
  } catch {}
  if ($Root) { return (Resolve-Path $Root).Path }
  return (Get-Location).Path
}
$RepoRoot = Get-RepoRoot
$LockFile = Join-Path $RepoRoot '.gpt5.lock'
if (Test-Path $LockFile) { Write-Error 'CONFLICT: .gpt5.lock exists.'; exit 11 }
"locked $(Get-Date -Format o)" | Out-File $LockFile -Encoding utf8 -NoNewline

$sw=[Diagnostics.Stopwatch]::StartNew()
$trace=[guid]::NewGuid().ToString()
$logPath = Join-Path $RepoRoot 'logs/apply-log.jsonl'
New-Item -ItemType Directory -Force -Path (Split-Path $logPath) | Out-Null

function LogRec([string]$level,[string]$action,[string]$outcome,[string]$msg,[string]$err='') {
  $rec = @{
    timestamp=(Get-Date).ToString('o'); level=$level; traceId=$trace; module='patcher';
    action=$action; inputHash=((Get-Variable -Name patchHash -Scope Global -ValueOnly -ErrorAction SilentlyContinue) ?? ""); outcome=$outcome;
    durationMs=$sw.ElapsedMilliseconds; errorCode=$err; message=$msg
  } | ConvertTo-Json -Compress
  Add-Content -Path $logPath -Value $rec
}

try {
  # ── Preflight: 모듈 로드 & 스모크 ─────────────────────────────────────────────
  $ModPath = Join-Path $RepoRoot 'scripts\lib\kobong-fileio.psm1'
  if (!(Test-Path $ModPath)) { throw "Missing module: $ModPath" }
try { Import-Module $ModPath -Force } catch { Write-Host "[WARN] Import-Module failed → $ModPath: $(# APPLY IN SHELL
#requires -Version 7.0
param([switch]$ConfirmApply,[string]$Root)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

# ── Gate-0: Repo / Lock ─────────────────────────────────────────────────────────
function Get-RepoRoot {
  try {
    $p = (git rev-parse --show-toplevel 2>$null)
    if ($p) { return (Resolve-Path $p).Path }
  } catch {}
  if ($Root) { return (Resolve-Path $Root).Path }
  return (Get-Location).Path
}
$RepoRoot = Get-RepoRoot
$LockFile = Join-Path $RepoRoot '.gpt5.lock'
if (Test-Path $LockFile) { Write-Error 'CONFLICT: .gpt5.lock exists.'; exit 11 }
"locked $(Get-Date -Format o)" | Out-File $LockFile -Encoding utf8 -NoNewline

$sw=[Diagnostics.Stopwatch]::StartNew()
$trace=[guid]::NewGuid().ToString()
$logPath = Join-Path $RepoRoot 'logs/apply-log.jsonl'
New-Item -ItemType Directory -Force -Path (Split-Path $logPath) | Out-Null

function LogRec([string]$level,[string]$action,[string]$outcome,[string]$msg,[string]$err='') {
  $rec = @{
    timestamp=(Get-Date).ToString('o'); level=$level; traceId=$trace; module='patcher';
    action=$action; inputHash=((Get-Variable -Name patchHash -Scope Global -ValueOnly -ErrorAction SilentlyContinue) ?? ""); outcome=$outcome;
    durationMs=$sw.ElapsedMilliseconds; errorCode=$err; message=$msg
  } | ConvertTo-Json -Compress
  Add-Content -Path $logPath -Value $rec
}

try {
  # ── Preflight: 모듈 로드 & 스모크 ─────────────────────────────────────────────
  $ModPath = Join-Path $RepoRoot 'scripts\lib\kobong-fileio.psm1'
  if (!(Test-Path $ModPath)) { throw "Missing module: $ModPath" }
  Import-Module $ModPath -Force

  # 스모크: 같은 볼륨에 원자 쓰기 → 즉시 삭제
  $smoke = Join-Path $RepoRoot 'webui\public\_klc-smoke.txt'
  $smokeContent = "[klc-smoke] $(Get-Date -Format o)"
  Write-AtomicUtf8 -Path $smoke -Content $smokeContent -Module 'patcher' -Action 'smoke'
  if (Test-Path $smoke) { Remove-Item -LiteralPath $smoke -Force -ErrorAction SilentlyContinue }

  # ── Patch 파일 파싱 ───────────────────────────────────────────────────────────
  $PatchFile = Join-Path $RepoRoot '.kobong\patches.pending.txt'
  if (!(Test-Path $PatchFile)) {
  Write-Host "[SKIP] patches file not found → $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("patches-file-missing: "+$PatchFile) } catch {}
  return
}
  $patchText = Get-Content -LiteralPath $PatchFile -Raw -Encoding UTF8
  $global:patchHash = (Get-FileHash -Algorithm SHA256 -InputStream ([IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes($patchText)))).Hash

  $matches = [regex]::Matches($patchText, '(?ms)#\s*PATCH\s*START\s*(?<body>.*?)#\s*PATCH\s*END')
  if ($matches.Count -eq 0) {
  Write-Host "[SKIP] No PATCH blocks found in $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("no-patch-blocks: "+$PatchFile) } catch {}
  return
}

  $applied = @()
  foreach ($m in $matches) {
    $body = $m.Groups['body'].Value

    $targetRel = [regex]::Match($body, 'TARGET:\s*(?<v>.+)').Groups['v'].Value.Trim()
    $mode      = [regex]::Match($body, 'MODE:\s*(?<v>.+)').Groups['v'].Value.Trim().ToLowerInvariant()
    $find      = [regex]::Match($body, "FIND\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value
    $replace   = [regex]::Match($body, "REPLACE\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value

    if (-not $targetRel) { throw "PATCH missing TARGET" }
    if (-not $mode)      { throw "PATCH missing MODE" }
    if (-not $find)      { throw "PATCH missing FIND" }

    $target = Join-Path $RepoRoot $targetRel
    if (!(Test-Path $target)) {
  Write-Host "[SKIP] TARGET not found → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("target-not-found: "+$targetRel) } catch {}
  continue
}

    $orig = Get-Content -LiteralPath $target -Raw -Encoding UTF8
    $rxOpts = [Text.RegularExpressions.RegexOptions]::Multiline -bor [Text.RegularExpressions.RegexOptions]::Singleline
    $rx = [regex]::new($find, $rxOpts)
    $mt = $rx.Match($orig)
    if (-not $mt.Success) {
  Write-Host "[SKIP] FIND not matched → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("find-not-matched: "+$targetRel) } catch {}
  continue
}

    switch ($mode) {
      'insert-before' {
        $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
      }
      'insert-before' {
  $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
}
'insert-after' {
  $new = $orig.Substring(0, $mt.Index + $mt.Length) + "`n" + $replace + $orig.Substring($mt.Index + $mt.Length)
}
'replace' {
        $new = $rx.Replace($orig, $replace, 1)
      }
      default {
  Write-Host "[SKIP] Unsupported MODE → $mode for $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("unsupported-mode: "+$mode+" for "+$targetRel) } catch {}
  continue
}
    }

    if ($ConfirmApply) {
      $bk = "$target.bak-" + (Get-Date -Format 'yyyyMMdd-HHmmss')
      Copy-Item -LiteralPath $target -Destination $bk -Force
      Write-AtomicUtf8 -Path $target -Content $new -Module 'patcher' -Action ('apply:'+ $mode)
      $applied += $targetRel
    } else {
      Write-Host "[PREVIEW] would patch → $targetRel ($mode)"
    }
  }

  if ($ConfirmApply) {
    LogRec 'INFO' 'apply' 'SUCCESS' ("patched: " + ($applied -join ', '))
  } else {
    LogRec 'INFO' 'preview' 'SUCCESS' ("preview-ok (no writes). blocks="+$matches.Count)
  }

  # ── Gate-3 Verify (경량) ───────────────────────────────────────────────────────
  if ($ConfirmApply) {
    # 핵심 타겟의 구문 일치 재검
    $core = Join-Path $RepoRoot 'scripts\apply_ui_patch.ps1'
    if (Test-Path $core) {
      $c = Get-Content -LiteralPath $core -Raw -Encoding UTF8
      if ($c -notmatch 'ensure valid tmp path .* atomic friendly') {
        Write-Host "[WARN] VERIFY: guard snippet not found in apply_ui_patch.ps1"; try { LogRec "WARN" "verify" "SKIPPED" "guard-missing apply_ui_patch.ps1" } catch {}
      }
    }
  }
}
catch {
  LogRec 'ERROR' 'apply' 'FAILURE' $_.Exception.Message 'LOGIC'
  exit 0
}
finally {
  Remove-Item -Force $LockFile -ErrorAction SilentlyContinue
}
.Exception.Message)" }
  # 스모크: 같은 볼륨에 원자 쓰기 → 즉시 삭제
  $smoke = Join-Path $RepoRoot 'webui\public\_klc-smoke.txt'
  $smokeContent = "[klc-smoke] $(Get-Date -Format o)"
  Write-AtomicUtf8 -Path $smoke -Content $smokeContent -Module 'patcher' -Action 'smoke'
  if (Test-Path $smoke) { Remove-Item -LiteralPath $smoke -Force -ErrorAction SilentlyContinue }

  # ── Patch 파일 파싱 ───────────────────────────────────────────────────────────
  $PatchFile = Join-Path $RepoRoot '.kobong\patches.pending.txt'
  if (!(Test-Path $PatchFile)) {
  Write-Host "[SKIP] patches file not found → $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("patches-file-missing: "+$PatchFile) } catch {}
  return
}
  $patchText = Get-Content -LiteralPath $PatchFile -Raw -Encoding UTF8
  $global:patchHash = (Get-FileHash -Algorithm SHA256 -InputStream ([IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes($patchText)))).Hash

  $matches = [regex]::Matches($patchText, '(?ms)#\s*PATCH\s*START\s*(?<body>.*?)#\s*PATCH\s*END')
  if ($matches.Count -eq 0) {
  Write-Host "[SKIP] No PATCH blocks found in $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("no-patch-blocks: "+$PatchFile) } catch {}
  return
}

  $applied = @()
  foreach ($m in $matches) {
    $body = $m.Groups['body'].Value

    $targetRel = [regex]::Match($body, 'TARGET:\s*(?<v>.+)').Groups['v'].Value.Trim()
    $mode      = [regex]::Match($body, 'MODE:\s*(?<v>.+)').Groups['v'].Value.Trim().ToLowerInvariant()
    $find      = [regex]::Match($body, "FIND\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value
    $replace   = [regex]::Match($body, "REPLACE\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value

    if (-not $targetRel) { throw "PATCH missing TARGET" }
    if (-not $mode)      { throw "PATCH missing MODE" }
    if (-not $find)      { throw "PATCH missing FIND" }

    $target = Join-Path $RepoRoot $targetRel
    if (!(Test-Path $target)) {
  Write-Host "[SKIP] TARGET not found → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("target-not-found: "+$targetRel) } catch {}
  continue
}

    $orig = Get-Content -LiteralPath $target -Raw -Encoding UTF8
    $rxOpts = [Text.RegularExpressions.RegexOptions]::Multiline -bor [Text.RegularExpressions.RegexOptions]::Singleline
    $rx = [regex]::new($find, $rxOpts)
    $mt = $rx.Match($orig)
    if (-not $mt.Success) {
  Write-Host "[SKIP] FIND not matched → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("find-not-matched: "+$targetRel) } catch {}
  continue
}

    switch ($mode) {
      'insert-before' {
        $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
      }
      'insert-before' {
  $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
}
'insert-after' {
  $new = $orig.Substring(0, $mt.Index + $mt.Length) + "`n" + $replace + $orig.Substring($mt.Index + $mt.Length)
}
'replace' {
        $new = $rx.Replace($orig, $replace, 1)
      }
      default {
  Write-Host "[SKIP] Unsupported MODE → $mode for $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("unsupported-mode: "+$mode+" for "+$targetRel) } catch {}
  continue
}
    }

    if ($ConfirmApply) {
      $bk = "$target.bak-" + (Get-Date -Format 'yyyyMMdd-HHmmss')
      Copy-Item -LiteralPath $target -Destination $bk -Force
      Write-AtomicUtf8 -Path $target -Content $new -Module 'patcher' -Action ('apply:'+ $mode)
      $applied += $targetRel
    } else {
      Write-Host "[PREVIEW] would patch → $targetRel ($mode)"
    }
  }

  if ($ConfirmApply) {
    LogRec 'INFO' 'apply' 'SUCCESS' ("patched: " + ($applied -join ', '))
  } else {
    LogRec 'INFO' 'preview' 'SUCCESS' ("preview-ok (no writes). blocks="+$matches.Count)
  }

  # ── Gate-3 Verify (경량) ───────────────────────────────────────────────────────
  if ($ConfirmApply) {
    # 핵심 타겟의 구문 일치 재검
    $core = Join-Path $RepoRoot 'scripts\apply_ui_patch.ps1'
    if (Test-Path $core) {
      $c = Get-Content -LiteralPath $core -Raw -Encoding UTF8
      if ($c -notmatch 'ensure valid tmp path .* atomic friendly') {
        Write-Host "[WARN] VERIFY: guard snippet not found in apply_ui_patch.ps1"; try { LogRec "WARN" "verify" "SKIPPED" "guard-missing apply_ui_patch.ps1" } catch {}
      }
    }
  }
}
catch {
  LogRec 'ERROR' 'apply' 'FAILURE' $_.Exception.Message 'LOGIC'
  exit 0
}
finally {
  Remove-Item -Force $LockFile -ErrorAction SilentlyContinue
}
.Exception.Message)" }
}
try { Import-Module $ModPath -Force } catch { Write-Host "[WARN] Import-Module failed → $ModPath: $(# APPLY IN SHELL
#requires -Version 7.0
param([switch]$ConfirmApply,[string]$Root)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

# ── Gate-0: Repo / Lock ─────────────────────────────────────────────────────────
function Get-RepoRoot {
  try {
    $p = (git rev-parse --show-toplevel 2>$null)
    if ($p) { return (Resolve-Path $p).Path }
  } catch {}
  if ($Root) { return (Resolve-Path $Root).Path }
  return (Get-Location).Path
}
$RepoRoot = Get-RepoRoot
$LockFile = Join-Path $RepoRoot '.gpt5.lock'
if (Test-Path $LockFile) { Write-Error 'CONFLICT: .gpt5.lock exists.'; exit 11 }
"locked $(Get-Date -Format o)" | Out-File $LockFile -Encoding utf8 -NoNewline

$sw=[Diagnostics.Stopwatch]::StartNew()
$trace=[guid]::NewGuid().ToString()
$logPath = Join-Path $RepoRoot 'logs/apply-log.jsonl'
New-Item -ItemType Directory -Force -Path (Split-Path $logPath) | Out-Null

function LogRec([string]$level,[string]$action,[string]$outcome,[string]$msg,[string]$err='') {
  $rec = @{
    timestamp=(Get-Date).ToString('o'); level=$level; traceId=$trace; module='patcher';
    action=$action; inputHash=((Get-Variable -Name patchHash -Scope Global -ValueOnly -ErrorAction SilentlyContinue) ?? ""); outcome=$outcome;
    durationMs=$sw.ElapsedMilliseconds; errorCode=$err; message=$msg
  } | ConvertTo-Json -Compress
  Add-Content -Path $logPath -Value $rec
}

try {
  # ── Preflight: 모듈 로드 & 스모크 ─────────────────────────────────────────────
  $ModPath = Join-Path $RepoRoot 'scripts\lib\kobong-fileio.psm1'
  if (!(Test-Path $ModPath)) {
  Write-Host "[WARN] Missing module → $ModPath (continuing)"
  try { LogRec "WARN" "apply" "SKIPPED" ("missing-module: "+$ModPath) } catch {}
} else {
  try { Import-Module $ModPath -Force } catch { Write-Host "[WARN] Import-Module failed → $ModPath: $(# APPLY IN SHELL
#requires -Version 7.0
param([switch]$ConfirmApply,[string]$Root)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

# ── Gate-0: Repo / Lock ─────────────────────────────────────────────────────────
function Get-RepoRoot {
  try {
    $p = (git rev-parse --show-toplevel 2>$null)
    if ($p) { return (Resolve-Path $p).Path }
  } catch {}
  if ($Root) { return (Resolve-Path $Root).Path }
  return (Get-Location).Path
}
$RepoRoot = Get-RepoRoot
$LockFile = Join-Path $RepoRoot '.gpt5.lock'
if (Test-Path $LockFile) { Write-Error 'CONFLICT: .gpt5.lock exists.'; exit 11 }
"locked $(Get-Date -Format o)" | Out-File $LockFile -Encoding utf8 -NoNewline

$sw=[Diagnostics.Stopwatch]::StartNew()
$trace=[guid]::NewGuid().ToString()
$logPath = Join-Path $RepoRoot 'logs/apply-log.jsonl'
New-Item -ItemType Directory -Force -Path (Split-Path $logPath) | Out-Null

function LogRec([string]$level,[string]$action,[string]$outcome,[string]$msg,[string]$err='') {
  $rec = @{
    timestamp=(Get-Date).ToString('o'); level=$level; traceId=$trace; module='patcher';
    action=$action; inputHash=((Get-Variable -Name patchHash -Scope Global -ValueOnly -ErrorAction SilentlyContinue) ?? ""); outcome=$outcome;
    durationMs=$sw.ElapsedMilliseconds; errorCode=$err; message=$msg
  } | ConvertTo-Json -Compress
  Add-Content -Path $logPath -Value $rec
}

try {
  # ── Preflight: 모듈 로드 & 스모크 ─────────────────────────────────────────────
  $ModPath = Join-Path $RepoRoot 'scripts\lib\kobong-fileio.psm1'
  if (!(Test-Path $ModPath)) { throw "Missing module: $ModPath" }
try { Import-Module $ModPath -Force } catch { Write-Host "[WARN] Import-Module failed → $ModPath: $(# APPLY IN SHELL
#requires -Version 7.0
param([switch]$ConfirmApply,[string]$Root)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

# ── Gate-0: Repo / Lock ─────────────────────────────────────────────────────────
function Get-RepoRoot {
  try {
    $p = (git rev-parse --show-toplevel 2>$null)
    if ($p) { return (Resolve-Path $p).Path }
  } catch {}
  if ($Root) { return (Resolve-Path $Root).Path }
  return (Get-Location).Path
}
$RepoRoot = Get-RepoRoot
$LockFile = Join-Path $RepoRoot '.gpt5.lock'
if (Test-Path $LockFile) { Write-Error 'CONFLICT: .gpt5.lock exists.'; exit 11 }
"locked $(Get-Date -Format o)" | Out-File $LockFile -Encoding utf8 -NoNewline

$sw=[Diagnostics.Stopwatch]::StartNew()
$trace=[guid]::NewGuid().ToString()
$logPath = Join-Path $RepoRoot 'logs/apply-log.jsonl'
New-Item -ItemType Directory -Force -Path (Split-Path $logPath) | Out-Null

function LogRec([string]$level,[string]$action,[string]$outcome,[string]$msg,[string]$err='') {
  $rec = @{
    timestamp=(Get-Date).ToString('o'); level=$level; traceId=$trace; module='patcher';
    action=$action; inputHash=((Get-Variable -Name patchHash -Scope Global -ValueOnly -ErrorAction SilentlyContinue) ?? ""); outcome=$outcome;
    durationMs=$sw.ElapsedMilliseconds; errorCode=$err; message=$msg
  } | ConvertTo-Json -Compress
  Add-Content -Path $logPath -Value $rec
}

try {
  # ── Preflight: 모듈 로드 & 스모크 ─────────────────────────────────────────────
  $ModPath = Join-Path $RepoRoot 'scripts\lib\kobong-fileio.psm1'
  if (!(Test-Path $ModPath)) { throw "Missing module: $ModPath" }
  Import-Module $ModPath -Force

  # 스모크: 같은 볼륨에 원자 쓰기 → 즉시 삭제
  $smoke = Join-Path $RepoRoot 'webui\public\_klc-smoke.txt'
  $smokeContent = "[klc-smoke] $(Get-Date -Format o)"
  Write-AtomicUtf8 -Path $smoke -Content $smokeContent -Module 'patcher' -Action 'smoke'
  if (Test-Path $smoke) { Remove-Item -LiteralPath $smoke -Force -ErrorAction SilentlyContinue }

  # ── Patch 파일 파싱 ───────────────────────────────────────────────────────────
  $PatchFile = Join-Path $RepoRoot '.kobong\patches.pending.txt'
  if (!(Test-Path $PatchFile)) {
  Write-Host "[SKIP] patches file not found → $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("patches-file-missing: "+$PatchFile) } catch {}
  return
}
  $patchText = Get-Content -LiteralPath $PatchFile -Raw -Encoding UTF8
  $global:patchHash = (Get-FileHash -Algorithm SHA256 -InputStream ([IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes($patchText)))).Hash

  $matches = [regex]::Matches($patchText, '(?ms)#\s*PATCH\s*START\s*(?<body>.*?)#\s*PATCH\s*END')
  if ($matches.Count -eq 0) {
  Write-Host "[SKIP] No PATCH blocks found in $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("no-patch-blocks: "+$PatchFile) } catch {}
  return
}

  $applied = @()
  foreach ($m in $matches) {
    $body = $m.Groups['body'].Value

    $targetRel = [regex]::Match($body, 'TARGET:\s*(?<v>.+)').Groups['v'].Value.Trim()
    $mode      = [regex]::Match($body, 'MODE:\s*(?<v>.+)').Groups['v'].Value.Trim().ToLowerInvariant()
    $find      = [regex]::Match($body, "FIND\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value
    $replace   = [regex]::Match($body, "REPLACE\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value

    if (-not $targetRel) { throw "PATCH missing TARGET" }
    if (-not $mode)      { throw "PATCH missing MODE" }
    if (-not $find)      { throw "PATCH missing FIND" }

    $target = Join-Path $RepoRoot $targetRel
    if (!(Test-Path $target)) {
  Write-Host "[SKIP] TARGET not found → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("target-not-found: "+$targetRel) } catch {}
  continue
}

    $orig = Get-Content -LiteralPath $target -Raw -Encoding UTF8
    $rxOpts = [Text.RegularExpressions.RegexOptions]::Multiline -bor [Text.RegularExpressions.RegexOptions]::Singleline
    $rx = [regex]::new($find, $rxOpts)
    $mt = $rx.Match($orig)
    if (-not $mt.Success) {
  Write-Host "[SKIP] FIND not matched → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("find-not-matched: "+$targetRel) } catch {}
  continue
}

    switch ($mode) {
      'insert-before' {
        $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
      }
      'insert-before' {
  $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
}
'insert-after' {
  $new = $orig.Substring(0, $mt.Index + $mt.Length) + "`n" + $replace + $orig.Substring($mt.Index + $mt.Length)
}
'replace' {
        $new = $rx.Replace($orig, $replace, 1)
      }
      default {
  Write-Host "[SKIP] Unsupported MODE → $mode for $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("unsupported-mode: "+$mode+" for "+$targetRel) } catch {}
  continue
}
    }

    if ($ConfirmApply) {
      $bk = "$target.bak-" + (Get-Date -Format 'yyyyMMdd-HHmmss')
      Copy-Item -LiteralPath $target -Destination $bk -Force
      Write-AtomicUtf8 -Path $target -Content $new -Module 'patcher' -Action ('apply:'+ $mode)
      $applied += $targetRel
    } else {
      Write-Host "[PREVIEW] would patch → $targetRel ($mode)"
    }
  }

  if ($ConfirmApply) {
    LogRec 'INFO' 'apply' 'SUCCESS' ("patched: " + ($applied -join ', '))
  } else {
    LogRec 'INFO' 'preview' 'SUCCESS' ("preview-ok (no writes). blocks="+$matches.Count)
  }

  # ── Gate-3 Verify (경량) ───────────────────────────────────────────────────────
  if ($ConfirmApply) {
    # 핵심 타겟의 구문 일치 재검
    $core = Join-Path $RepoRoot 'scripts\apply_ui_patch.ps1'
    if (Test-Path $core) {
      $c = Get-Content -LiteralPath $core -Raw -Encoding UTF8
      if ($c -notmatch 'ensure valid tmp path .* atomic friendly') {
        Write-Host "[WARN] VERIFY: guard snippet not found in apply_ui_patch.ps1"; try { LogRec "WARN" "verify" "SKIPPED" "guard-missing apply_ui_patch.ps1" } catch {}
      }
    }
  }
}
catch {
  LogRec 'ERROR' 'apply' 'FAILURE' $_.Exception.Message 'LOGIC'
  exit 0
}
finally {
  Remove-Item -Force $LockFile -ErrorAction SilentlyContinue
}
.Exception.Message)" }
  # 스모크: 같은 볼륨에 원자 쓰기 → 즉시 삭제
  $smoke = Join-Path $RepoRoot 'webui\public\_klc-smoke.txt'
  $smokeContent = "[klc-smoke] $(Get-Date -Format o)"
  Write-AtomicUtf8 -Path $smoke -Content $smokeContent -Module 'patcher' -Action 'smoke'
  if (Test-Path $smoke) { Remove-Item -LiteralPath $smoke -Force -ErrorAction SilentlyContinue }

  # ── Patch 파일 파싱 ───────────────────────────────────────────────────────────
  $PatchFile = Join-Path $RepoRoot '.kobong\patches.pending.txt'
  if (!(Test-Path $PatchFile)) {
  Write-Host "[SKIP] patches file not found → $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("patches-file-missing: "+$PatchFile) } catch {}
  return
}
  $patchText = Get-Content -LiteralPath $PatchFile -Raw -Encoding UTF8
  $global:patchHash = (Get-FileHash -Algorithm SHA256 -InputStream ([IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes($patchText)))).Hash

  $matches = [regex]::Matches($patchText, '(?ms)#\s*PATCH\s*START\s*(?<body>.*?)#\s*PATCH\s*END')
  if ($matches.Count -eq 0) {
  Write-Host "[SKIP] No PATCH blocks found in $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("no-patch-blocks: "+$PatchFile) } catch {}
  return
}

  $applied = @()
  foreach ($m in $matches) {
    $body = $m.Groups['body'].Value

    $targetRel = [regex]::Match($body, 'TARGET:\s*(?<v>.+)').Groups['v'].Value.Trim()
    $mode      = [regex]::Match($body, 'MODE:\s*(?<v>.+)').Groups['v'].Value.Trim().ToLowerInvariant()
    $find      = [regex]::Match($body, "FIND\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value
    $replace   = [regex]::Match($body, "REPLACE\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value

    if (-not $targetRel) { throw "PATCH missing TARGET" }
    if (-not $mode)      { throw "PATCH missing MODE" }
    if (-not $find)      { throw "PATCH missing FIND" }

    $target = Join-Path $RepoRoot $targetRel
    if (!(Test-Path $target)) {
  Write-Host "[SKIP] TARGET not found → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("target-not-found: "+$targetRel) } catch {}
  continue
}

    $orig = Get-Content -LiteralPath $target -Raw -Encoding UTF8
    $rxOpts = [Text.RegularExpressions.RegexOptions]::Multiline -bor [Text.RegularExpressions.RegexOptions]::Singleline
    $rx = [regex]::new($find, $rxOpts)
    $mt = $rx.Match($orig)
    if (-not $mt.Success) {
  Write-Host "[SKIP] FIND not matched → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("find-not-matched: "+$targetRel) } catch {}
  continue
}

    switch ($mode) {
      'insert-before' {
        $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
      }
      'insert-before' {
  $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
}
'insert-after' {
  $new = $orig.Substring(0, $mt.Index + $mt.Length) + "`n" + $replace + $orig.Substring($mt.Index + $mt.Length)
}
'replace' {
        $new = $rx.Replace($orig, $replace, 1)
      }
      default {
  Write-Host "[SKIP] Unsupported MODE → $mode for $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("unsupported-mode: "+$mode+" for "+$targetRel) } catch {}
  continue
}
    }

    if ($ConfirmApply) {
      $bk = "$target.bak-" + (Get-Date -Format 'yyyyMMdd-HHmmss')
      Copy-Item -LiteralPath $target -Destination $bk -Force
      Write-AtomicUtf8 -Path $target -Content $new -Module 'patcher' -Action ('apply:'+ $mode)
      $applied += $targetRel
    } else {
      Write-Host "[PREVIEW] would patch → $targetRel ($mode)"
    }
  }

  if ($ConfirmApply) {
    LogRec 'INFO' 'apply' 'SUCCESS' ("patched: " + ($applied -join ', '))
  } else {
    LogRec 'INFO' 'preview' 'SUCCESS' ("preview-ok (no writes). blocks="+$matches.Count)
  }

  # ── Gate-3 Verify (경량) ───────────────────────────────────────────────────────
  if ($ConfirmApply) {
    # 핵심 타겟의 구문 일치 재검
    $core = Join-Path $RepoRoot 'scripts\apply_ui_patch.ps1'
    if (Test-Path $core) {
      $c = Get-Content -LiteralPath $core -Raw -Encoding UTF8
      if ($c -notmatch 'ensure valid tmp path .* atomic friendly') {
        Write-Host "[WARN] VERIFY: guard snippet not found in apply_ui_patch.ps1"; try { LogRec "WARN" "verify" "SKIPPED" "guard-missing apply_ui_patch.ps1" } catch {}
      }
    }
  }
}
catch {
  LogRec 'ERROR' 'apply' 'FAILURE' $_.Exception.Message 'LOGIC'
  exit 0
}
finally {
  Remove-Item -Force $LockFile -ErrorAction SilentlyContinue
}
.Exception.Message)" }
}
  Import-Module $ModPath -Force

  # 스모크: 같은 볼륨에 원자 쓰기 → 즉시 삭제
  $smoke = Join-Path $RepoRoot 'webui\public\_klc-smoke.txt'
  $smokeContent = "[klc-smoke] $(Get-Date -Format o)"
  Write-AtomicUtf8 -Path $smoke -Content $smokeContent -Module 'patcher' -Action 'smoke'
  if (Test-Path $smoke) { Remove-Item -LiteralPath $smoke -Force -ErrorAction SilentlyContinue }

  # ── Patch 파일 파싱 ───────────────────────────────────────────────────────────
  $PatchFile = Join-Path $RepoRoot '.kobong\patches.pending.txt'
  if (!(Test-Path $PatchFile)) {
  Write-Host "[SKIP] patches file not found → $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("patches-file-missing: "+$PatchFile) } catch {}
  return
}
  $patchText = Get-Content -LiteralPath $PatchFile -Raw -Encoding UTF8
  $global:patchHash = (Get-FileHash -Algorithm SHA256 -InputStream ([IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes($patchText)))).Hash

  $matches = [regex]::Matches($patchText, '(?ms)#\s*PATCH\s*START\s*(?<body>.*?)#\s*PATCH\s*END')
  if ($matches.Count -eq 0) {
  Write-Host "[SKIP] No PATCH blocks found in $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("no-patch-blocks: "+$PatchFile) } catch {}
  return
}

  $applied = @()
  foreach ($m in $matches) {
    $body = $m.Groups['body'].Value

    $targetRel = [regex]::Match($body, 'TARGET:\s*(?<v>.+)').Groups['v'].Value.Trim()
    $mode      = [regex]::Match($body, 'MODE:\s*(?<v>.+)').Groups['v'].Value.Trim().ToLowerInvariant()
    $find      = [regex]::Match($body, "FIND\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value
    $replace   = [regex]::Match($body, "REPLACE\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value

    if (-not $targetRel) { throw "PATCH missing TARGET" }
    if (-not $mode)      { throw "PATCH missing MODE" }
    if (-not $find)      { throw "PATCH missing FIND" }

    $target = Join-Path $RepoRoot $targetRel
    if (!(Test-Path $target)) {
  Write-Host "[SKIP] TARGET not found → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("target-not-found: "+$targetRel) } catch {}
  continue
}

    $orig = Get-Content -LiteralPath $target -Raw -Encoding UTF8
    $rxOpts = [Text.RegularExpressions.RegexOptions]::Multiline -bor [Text.RegularExpressions.RegexOptions]::Singleline
    $rx = [regex]::new($find, $rxOpts)
    $mt = $rx.Match($orig)
    if (-not $mt.Success) {
  Write-Host "[SKIP] FIND not matched → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("find-not-matched: "+$targetRel) } catch {}
  continue
}

    switch ($mode) {
      'insert-before' {
        $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
      }
      'insert-before' {
  $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
}
'insert-after' {
  $new = $orig.Substring(0, $mt.Index + $mt.Length) + "`n" + $replace + $orig.Substring($mt.Index + $mt.Length)
}
'replace' {
        $new = $rx.Replace($orig, $replace, 1)
      }
      default {
  Write-Host "[SKIP] Unsupported MODE → $mode for $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("unsupported-mode: "+$mode+" for "+$targetRel) } catch {}
  continue
}
    }

    if ($ConfirmApply) {
      $bk = "$target.bak-" + (Get-Date -Format 'yyyyMMdd-HHmmss')
      Copy-Item -LiteralPath $target -Destination $bk -Force
      Write-AtomicUtf8 -Path $target -Content $new -Module 'patcher' -Action ('apply:'+ $mode)
      $applied += $targetRel
    } else {
      Write-Host "[PREVIEW] would patch → $targetRel ($mode)"
    }
  }

  if ($ConfirmApply) {
    LogRec 'INFO' 'apply' 'SUCCESS' ("patched: " + ($applied -join ', '))
  } else {
    LogRec 'INFO' 'preview' 'SUCCESS' ("preview-ok (no writes). blocks="+$matches.Count)
  }

  # ── Gate-3 Verify (경량) ───────────────────────────────────────────────────────
  if ($ConfirmApply) {
    # 핵심 타겟의 구문 일치 재검
    $core = Join-Path $RepoRoot 'scripts\apply_ui_patch.ps1'
    if (Test-Path $core) {
      $c = Get-Content -LiteralPath $core -Raw -Encoding UTF8
      if ($c -notmatch 'ensure valid tmp path .* atomic friendly') {
        Write-Host "[WARN] VERIFY: guard snippet not found in apply_ui_patch.ps1"; try { LogRec "WARN" "verify" "SKIPPED" "guard-missing apply_ui_patch.ps1" } catch {}
      }
    }
  }
}
catch {
  LogRec 'ERROR' 'apply' 'FAILURE' $_.Exception.Message 'LOGIC'
  exit 0
}
finally {
  Remove-Item -Force $LockFile -ErrorAction SilentlyContinue
}
.Exception.Message)" }
  # 스모크: 같은 볼륨에 원자 쓰기 → 즉시 삭제
  $smoke = Join-Path $RepoRoot 'webui\public\_klc-smoke.txt'
  $smokeContent = "[klc-smoke] $(Get-Date -Format o)"
  Write-AtomicUtf8 -Path $smoke -Content $smokeContent -Module 'patcher' -Action 'smoke'
  if (Test-Path $smoke) { Remove-Item -LiteralPath $smoke -Force -ErrorAction SilentlyContinue }

  # ── Patch 파일 파싱 ───────────────────────────────────────────────────────────
  $PatchFile = Join-Path $RepoRoot '.kobong\patches.pending.txt'
  if (!(Test-Path $PatchFile)) {
  Write-Host "[SKIP] patches file not found → $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("patches-file-missing: "+$PatchFile) } catch {}
  return
}
  $patchText = Get-Content -LiteralPath $PatchFile -Raw -Encoding UTF8
  $global:patchHash = (Get-FileHash -Algorithm SHA256 -InputStream ([IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes($patchText)))).Hash

  $matches = [regex]::Matches($patchText, '(?ms)#\s*PATCH\s*START\s*(?<body>.*?)#\s*PATCH\s*END')
  if ($matches.Count -eq 0) {
  Write-Host "[SKIP] No PATCH blocks found in $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("no-patch-blocks: "+$PatchFile) } catch {}
  return
}

  $applied = @()
  foreach ($m in $matches) {
    $body = $m.Groups['body'].Value

    $targetRel = [regex]::Match($body, 'TARGET:\s*(?<v>.+)').Groups['v'].Value.Trim()
    $mode      = [regex]::Match($body, 'MODE:\s*(?<v>.+)').Groups['v'].Value.Trim().ToLowerInvariant()
    $find      = [regex]::Match($body, "FIND\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value
    $replace   = [regex]::Match($body, "REPLACE\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value

    if (-not $targetRel) { throw "PATCH missing TARGET" }
    if (-not $mode)      { throw "PATCH missing MODE" }
    if (-not $find)      { throw "PATCH missing FIND" }

    $target = Join-Path $RepoRoot $targetRel
    if (!(Test-Path $target)) {
  Write-Host "[SKIP] TARGET not found → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("target-not-found: "+$targetRel) } catch {}
  continue
}

    $orig = Get-Content -LiteralPath $target -Raw -Encoding UTF8
    $rxOpts = [Text.RegularExpressions.RegexOptions]::Multiline -bor [Text.RegularExpressions.RegexOptions]::Singleline
    $rx = [regex]::new($find, $rxOpts)
    $mt = $rx.Match($orig)
    if (-not $mt.Success) {
  Write-Host "[SKIP] FIND not matched → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("find-not-matched: "+$targetRel) } catch {}
  continue
}

    switch ($mode) {
      'insert-before' {
        $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
      }
      'insert-before' {
  $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
}
'insert-after' {
  $new = $orig.Substring(0, $mt.Index + $mt.Length) + "`n" + $replace + $orig.Substring($mt.Index + $mt.Length)
}
'replace' {
        $new = $rx.Replace($orig, $replace, 1)
      }
      default {
  Write-Host "[SKIP] Unsupported MODE → $mode for $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("unsupported-mode: "+$mode+" for "+$targetRel) } catch {}
  continue
}
    }

    if ($ConfirmApply) {
      $bk = "$target.bak-" + (Get-Date -Format 'yyyyMMdd-HHmmss')
      Copy-Item -LiteralPath $target -Destination $bk -Force
      Write-AtomicUtf8 -Path $target -Content $new -Module 'patcher' -Action ('apply:'+ $mode)
      $applied += $targetRel
    } else {
      Write-Host "[PREVIEW] would patch → $targetRel ($mode)"
    }
  }

  if ($ConfirmApply) {
    LogRec 'INFO' 'apply' 'SUCCESS' ("patched: " + ($applied -join ', '))
  } else {
    LogRec 'INFO' 'preview' 'SUCCESS' ("preview-ok (no writes). blocks="+$matches.Count)
  }

  # ── Gate-3 Verify (경량) ───────────────────────────────────────────────────────
  if ($ConfirmApply) {
    # 핵심 타겟의 구문 일치 재검
    $core = Join-Path $RepoRoot 'scripts\apply_ui_patch.ps1'
    if (Test-Path $core) {
      $c = Get-Content -LiteralPath $core -Raw -Encoding UTF8
      if ($c -notmatch 'ensure valid tmp path .* atomic friendly') {
        Write-Host "[WARN] VERIFY: guard snippet not found in apply_ui_patch.ps1"; try { LogRec "WARN" "verify" "SKIPPED" "guard-missing apply_ui_patch.ps1" } catch {}
      }
    }
  }
}
catch {
  LogRec 'ERROR' 'apply' 'FAILURE' $_.Exception.Message 'LOGIC'
  exit 0
}
finally {
  Remove-Item -Force $LockFile -ErrorAction SilentlyContinue
}
.Exception.Message) }

# ── Gate-0: Repo / Lock ─────────────────────────────────────────────────────────
function Get-RepoRoot {
  try {
    $p = (git rev-parse --show-toplevel 2>$null)
    if ($p) { return (Resolve-Path $p).Path }
  } catch {}
  if ($Root) { return (Resolve-Path $Root).Path }
  return (Get-Location).Path
}
$RepoRoot = Get-RepoRoot
$LockFile = Join-Path $RepoRoot '.gpt5.lock'
if (Test-Path $LockFile) { Write-Error 'CONFLICT: .gpt5.lock exists.'; exit 11 }
"locked $(Get-Date -Format o)" | Out-File $LockFile -Encoding utf8 -NoNewline

$sw=[Diagnostics.Stopwatch]::StartNew()
$trace=[guid]::NewGuid().ToString()
$logPath = Join-Path $RepoRoot 'logs/apply-log.jsonl'
New-Item -ItemType Directory -Force -Path (Split-Path $logPath) | Out-Null

function LogRec([string]$level,[string]$action,[string]$outcome,[string]$msg,[string]$err='') {
  $rec = @{
    timestamp=(Get-Date).ToString('o'); level=$level; traceId=$trace; module='patcher';
    action=$action; inputHash=((Get-Variable -Name patchHash -Scope Global -ValueOnly -ErrorAction SilentlyContinue) ?? ""); outcome=$outcome;
    durationMs=$sw.ElapsedMilliseconds; errorCode=$err; message=$msg
  } | ConvertTo-Json -Compress
  Add-Content -Path $logPath -Value $rec
}

try {
  # ── Preflight: 모듈 로드 & 스모크 ─────────────────────────────────────────────
  $ModPath = Join-Path $RepoRoot 'scripts\lib\kobong-fileio.psm1'
  if (!(Test-Path $ModPath)) { throw "Missing module: $ModPath" }
try { Import-Module $ModPath -Force } catch { Write-Host "[WARN] Import-Module failed → $ModPath: $(# APPLY IN SHELL
#requires -Version 7.0
param([switch]$ConfirmApply,[string]$Root)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

# ── Gate-0: Repo / Lock ─────────────────────────────────────────────────────────
function Get-RepoRoot {
  try {
    $p = (git rev-parse --show-toplevel 2>$null)
    if ($p) { return (Resolve-Path $p).Path }
  } catch {}
  if ($Root) { return (Resolve-Path $Root).Path }
  return (Get-Location).Path
}
$RepoRoot = Get-RepoRoot
$LockFile = Join-Path $RepoRoot '.gpt5.lock'
if (Test-Path $LockFile) { Write-Error 'CONFLICT: .gpt5.lock exists.'; exit 11 }
"locked $(Get-Date -Format o)" | Out-File $LockFile -Encoding utf8 -NoNewline

$sw=[Diagnostics.Stopwatch]::StartNew()
$trace=[guid]::NewGuid().ToString()
$logPath = Join-Path $RepoRoot 'logs/apply-log.jsonl'
New-Item -ItemType Directory -Force -Path (Split-Path $logPath) | Out-Null

function LogRec([string]$level,[string]$action,[string]$outcome,[string]$msg,[string]$err='') {
  $rec = @{
    timestamp=(Get-Date).ToString('o'); level=$level; traceId=$trace; module='patcher';
    action=$action; inputHash=((Get-Variable -Name patchHash -Scope Global -ValueOnly -ErrorAction SilentlyContinue) ?? ""); outcome=$outcome;
    durationMs=$sw.ElapsedMilliseconds; errorCode=$err; message=$msg
  } | ConvertTo-Json -Compress
  Add-Content -Path $logPath -Value $rec
}

try {
  # ── Preflight: 모듈 로드 & 스모크 ─────────────────────────────────────────────
  $ModPath = Join-Path $RepoRoot 'scripts\lib\kobong-fileio.psm1'
  if (!(Test-Path $ModPath)) { throw "Missing module: $ModPath" }
  Import-Module $ModPath -Force

  # 스모크: 같은 볼륨에 원자 쓰기 → 즉시 삭제
  $smoke = Join-Path $RepoRoot 'webui\public\_klc-smoke.txt'
  $smokeContent = "[klc-smoke] $(Get-Date -Format o)"
  Write-AtomicUtf8 -Path $smoke -Content $smokeContent -Module 'patcher' -Action 'smoke'
  if (Test-Path $smoke) { Remove-Item -LiteralPath $smoke -Force -ErrorAction SilentlyContinue }

  # ── Patch 파일 파싱 ───────────────────────────────────────────────────────────
  $PatchFile = Join-Path $RepoRoot '.kobong\patches.pending.txt'
  if (!(Test-Path $PatchFile)) {
  Write-Host "[SKIP] patches file not found → $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("patches-file-missing: "+$PatchFile) } catch {}
  return
}
  $patchText = Get-Content -LiteralPath $PatchFile -Raw -Encoding UTF8
  $global:patchHash = (Get-FileHash -Algorithm SHA256 -InputStream ([IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes($patchText)))).Hash

  $matches = [regex]::Matches($patchText, '(?ms)#\s*PATCH\s*START\s*(?<body>.*?)#\s*PATCH\s*END')
  if ($matches.Count -eq 0) {
  Write-Host "[SKIP] No PATCH blocks found in $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("no-patch-blocks: "+$PatchFile) } catch {}
  return
}

  $applied = @()
  foreach ($m in $matches) {
    $body = $m.Groups['body'].Value

    $targetRel = [regex]::Match($body, 'TARGET:\s*(?<v>.+)').Groups['v'].Value.Trim()
    $mode      = [regex]::Match($body, 'MODE:\s*(?<v>.+)').Groups['v'].Value.Trim().ToLowerInvariant()
    $find      = [regex]::Match($body, "FIND\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value
    $replace   = [regex]::Match($body, "REPLACE\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value

    if (-not $targetRel) { throw "PATCH missing TARGET" }
    if (-not $mode)      { throw "PATCH missing MODE" }
    if (-not $find)      { throw "PATCH missing FIND" }

    $target = Join-Path $RepoRoot $targetRel
    if (!(Test-Path $target)) {
  Write-Host "[SKIP] TARGET not found → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("target-not-found: "+$targetRel) } catch {}
  continue
}

    $orig = Get-Content -LiteralPath $target -Raw -Encoding UTF8
    $rxOpts = [Text.RegularExpressions.RegexOptions]::Multiline -bor [Text.RegularExpressions.RegexOptions]::Singleline
    $rx = [regex]::new($find, $rxOpts)
    $mt = $rx.Match($orig)
    if (-not $mt.Success) {
  Write-Host "[SKIP] FIND not matched → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("find-not-matched: "+$targetRel) } catch {}
  continue
}

    switch ($mode) {
      'insert-before' {
        $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
      }
      'insert-before' {
  $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
}
'insert-after' {
  $new = $orig.Substring(0, $mt.Index + $mt.Length) + "`n" + $replace + $orig.Substring($mt.Index + $mt.Length)
}
'replace' {
        $new = $rx.Replace($orig, $replace, 1)
      }
      default {
  Write-Host "[SKIP] Unsupported MODE → $mode for $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("unsupported-mode: "+$mode+" for "+$targetRel) } catch {}
  continue
}
    }

    if ($ConfirmApply) {
      $bk = "$target.bak-" + (Get-Date -Format 'yyyyMMdd-HHmmss')
      Copy-Item -LiteralPath $target -Destination $bk -Force
      Write-AtomicUtf8 -Path $target -Content $new -Module 'patcher' -Action ('apply:'+ $mode)
      $applied += $targetRel
    } else {
      Write-Host "[PREVIEW] would patch → $targetRel ($mode)"
    }
  }

  if ($ConfirmApply) {
    LogRec 'INFO' 'apply' 'SUCCESS' ("patched: " + ($applied -join ', '))
  } else {
    LogRec 'INFO' 'preview' 'SUCCESS' ("preview-ok (no writes). blocks="+$matches.Count)
  }

  # ── Gate-3 Verify (경량) ───────────────────────────────────────────────────────
  if ($ConfirmApply) {
    # 핵심 타겟의 구문 일치 재검
    $core = Join-Path $RepoRoot 'scripts\apply_ui_patch.ps1'
    if (Test-Path $core) {
      $c = Get-Content -LiteralPath $core -Raw -Encoding UTF8
      if ($c -notmatch 'ensure valid tmp path .* atomic friendly') {
        Write-Host "[WARN] VERIFY: guard snippet not found in apply_ui_patch.ps1"; try { LogRec "WARN" "verify" "SKIPPED" "guard-missing apply_ui_patch.ps1" } catch {}
      }
    }
  }
}
catch {
  LogRec 'ERROR' 'apply' 'FAILURE' $_.Exception.Message 'LOGIC'
  exit 0
}
finally {
  Remove-Item -Force $LockFile -ErrorAction SilentlyContinue
}
.Exception.Message)" }
  # 스모크: 같은 볼륨에 원자 쓰기 → 즉시 삭제
  $smoke = Join-Path $RepoRoot 'webui\public\_klc-smoke.txt'
  $smokeContent = "[klc-smoke] $(Get-Date -Format o)"
  Write-AtomicUtf8 -Path $smoke -Content $smokeContent -Module 'patcher' -Action 'smoke'
  if (Test-Path $smoke) { Remove-Item -LiteralPath $smoke -Force -ErrorAction SilentlyContinue }

  # ── Patch 파일 파싱 ───────────────────────────────────────────────────────────
  $PatchFile = Join-Path $RepoRoot '.kobong\patches.pending.txt'
  if (!(Test-Path $PatchFile)) {
  Write-Host "[SKIP] patches file not found → $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("patches-file-missing: "+$PatchFile) } catch {}
  return
}
  $patchText = Get-Content -LiteralPath $PatchFile -Raw -Encoding UTF8
  $global:patchHash = (Get-FileHash -Algorithm SHA256 -InputStream ([IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes($patchText)))).Hash

  $matches = [regex]::Matches($patchText, '(?ms)#\s*PATCH\s*START\s*(?<body>.*?)#\s*PATCH\s*END')
  if ($matches.Count -eq 0) {
  Write-Host "[SKIP] No PATCH blocks found in $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("no-patch-blocks: "+$PatchFile) } catch {}
  return
}

  $applied = @()
  foreach ($m in $matches) {
    $body = $m.Groups['body'].Value

    $targetRel = [regex]::Match($body, 'TARGET:\s*(?<v>.+)').Groups['v'].Value.Trim()
    $mode      = [regex]::Match($body, 'MODE:\s*(?<v>.+)').Groups['v'].Value.Trim().ToLowerInvariant()
    $find      = [regex]::Match($body, "FIND\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value
    $replace   = [regex]::Match($body, "REPLACE\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value

    if (-not $targetRel) { throw "PATCH missing TARGET" }
    if (-not $mode)      { throw "PATCH missing MODE" }
    if (-not $find)      { throw "PATCH missing FIND" }

    $target = Join-Path $RepoRoot $targetRel
    if (!(Test-Path $target)) {
  Write-Host "[SKIP] TARGET not found → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("target-not-found: "+$targetRel) } catch {}
  continue
}

    $orig = Get-Content -LiteralPath $target -Raw -Encoding UTF8
    $rxOpts = [Text.RegularExpressions.RegexOptions]::Multiline -bor [Text.RegularExpressions.RegexOptions]::Singleline
    $rx = [regex]::new($find, $rxOpts)
    $mt = $rx.Match($orig)
    if (-not $mt.Success) {
  Write-Host "[SKIP] FIND not matched → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("find-not-matched: "+$targetRel) } catch {}
  continue
}

    switch ($mode) {
      'insert-before' {
        $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
      }
      'insert-before' {
  $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
}
'insert-after' {
  $new = $orig.Substring(0, $mt.Index + $mt.Length) + "`n" + $replace + $orig.Substring($mt.Index + $mt.Length)
}
'replace' {
        $new = $rx.Replace($orig, $replace, 1)
      }
      default {
  Write-Host "[SKIP] Unsupported MODE → $mode for $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("unsupported-mode: "+$mode+" for "+$targetRel) } catch {}
  continue
}
    }

    if ($ConfirmApply) {
      $bk = "$target.bak-" + (Get-Date -Format 'yyyyMMdd-HHmmss')
      Copy-Item -LiteralPath $target -Destination $bk -Force
      Write-AtomicUtf8 -Path $target -Content $new -Module 'patcher' -Action ('apply:'+ $mode)
      $applied += $targetRel
    } else {
      Write-Host "[PREVIEW] would patch → $targetRel ($mode)"
    }
  }

  if ($ConfirmApply) {
    LogRec 'INFO' 'apply' 'SUCCESS' ("patched: " + ($applied -join ', '))
  } else {
    LogRec 'INFO' 'preview' 'SUCCESS' ("preview-ok (no writes). blocks="+$matches.Count)
  }

  # ── Gate-3 Verify (경량) ───────────────────────────────────────────────────────
  if ($ConfirmApply) {
    # 핵심 타겟의 구문 일치 재검
    $core = Join-Path $RepoRoot 'scripts\apply_ui_patch.ps1'
    if (Test-Path $core) {
      $c = Get-Content -LiteralPath $core -Raw -Encoding UTF8
      if ($c -notmatch 'ensure valid tmp path .* atomic friendly') {
        Write-Host "[WARN] VERIFY: guard snippet not found in apply_ui_patch.ps1"; try { LogRec "WARN" "verify" "SKIPPED" "guard-missing apply_ui_patch.ps1" } catch {}
      }
    }
  }
}
catch {
  LogRec 'ERROR' 'apply' 'FAILURE' $_.Exception.Message 'LOGIC'
  exit 0
}
finally {
  Remove-Item -Force $LockFile -ErrorAction SilentlyContinue
}
.Exception.Message)" }
}
try { Import-Module $ModPath -Force } catch { Write-Host "[WARN] Import-Module failed → $ModPath: $(# APPLY IN SHELL
#requires -Version 7.0
param([switch]$ConfirmApply,[string]$Root)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

# ── Gate-0: Repo / Lock ─────────────────────────────────────────────────────────
function Get-RepoRoot {
  try {
    $p = (git rev-parse --show-toplevel 2>$null)
    if ($p) { return (Resolve-Path $p).Path }
  } catch {}
  if ($Root) { return (Resolve-Path $Root).Path }
  return (Get-Location).Path
}
$RepoRoot = Get-RepoRoot
$LockFile = Join-Path $RepoRoot '.gpt5.lock'
if (Test-Path $LockFile) { Write-Error 'CONFLICT: .gpt5.lock exists.'; exit 11 }
"locked $(Get-Date -Format o)" | Out-File $LockFile -Encoding utf8 -NoNewline

$sw=[Diagnostics.Stopwatch]::StartNew()
$trace=[guid]::NewGuid().ToString()
$logPath = Join-Path $RepoRoot 'logs/apply-log.jsonl'
New-Item -ItemType Directory -Force -Path (Split-Path $logPath) | Out-Null

function LogRec([string]$level,[string]$action,[string]$outcome,[string]$msg,[string]$err='') {
  $rec = @{
    timestamp=(Get-Date).ToString('o'); level=$level; traceId=$trace; module='patcher';
    action=$action; inputHash=((Get-Variable -Name patchHash -Scope Global -ValueOnly -ErrorAction SilentlyContinue) ?? ""); outcome=$outcome;
    durationMs=$sw.ElapsedMilliseconds; errorCode=$err; message=$msg
  } | ConvertTo-Json -Compress
  Add-Content -Path $logPath -Value $rec
}

try {
  # ── Preflight: 모듈 로드 & 스모크 ─────────────────────────────────────────────
  $ModPath = Join-Path $RepoRoot 'scripts\lib\kobong-fileio.psm1'
  if (!(Test-Path $ModPath)) {
  Write-Host "[WARN] Missing module → $ModPath (continuing)"
  try { LogRec "WARN" "apply" "SKIPPED" ("missing-module: "+$ModPath) } catch {}
} else {
  try { Import-Module $ModPath -Force } catch { Write-Host "[WARN] Import-Module failed → $ModPath: $(# APPLY IN SHELL
#requires -Version 7.0
param([switch]$ConfirmApply,[string]$Root)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

# ── Gate-0: Repo / Lock ─────────────────────────────────────────────────────────
function Get-RepoRoot {
  try {
    $p = (git rev-parse --show-toplevel 2>$null)
    if ($p) { return (Resolve-Path $p).Path }
  } catch {}
  if ($Root) { return (Resolve-Path $Root).Path }
  return (Get-Location).Path
}
$RepoRoot = Get-RepoRoot
$LockFile = Join-Path $RepoRoot '.gpt5.lock'
if (Test-Path $LockFile) { Write-Error 'CONFLICT: .gpt5.lock exists.'; exit 11 }
"locked $(Get-Date -Format o)" | Out-File $LockFile -Encoding utf8 -NoNewline

$sw=[Diagnostics.Stopwatch]::StartNew()
$trace=[guid]::NewGuid().ToString()
$logPath = Join-Path $RepoRoot 'logs/apply-log.jsonl'
New-Item -ItemType Directory -Force -Path (Split-Path $logPath) | Out-Null

function LogRec([string]$level,[string]$action,[string]$outcome,[string]$msg,[string]$err='') {
  $rec = @{
    timestamp=(Get-Date).ToString('o'); level=$level; traceId=$trace; module='patcher';
    action=$action; inputHash=((Get-Variable -Name patchHash -Scope Global -ValueOnly -ErrorAction SilentlyContinue) ?? ""); outcome=$outcome;
    durationMs=$sw.ElapsedMilliseconds; errorCode=$err; message=$msg
  } | ConvertTo-Json -Compress
  Add-Content -Path $logPath -Value $rec
}

try {
  # ── Preflight: 모듈 로드 & 스모크 ─────────────────────────────────────────────
  $ModPath = Join-Path $RepoRoot 'scripts\lib\kobong-fileio.psm1'
  if (!(Test-Path $ModPath)) { throw "Missing module: $ModPath" }
try { Import-Module $ModPath -Force } catch { Write-Host "[WARN] Import-Module failed → $ModPath: $(# APPLY IN SHELL
#requires -Version 7.0
param([switch]$ConfirmApply,[string]$Root)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

# ── Gate-0: Repo / Lock ─────────────────────────────────────────────────────────
function Get-RepoRoot {
  try {
    $p = (git rev-parse --show-toplevel 2>$null)
    if ($p) { return (Resolve-Path $p).Path }
  } catch {}
  if ($Root) { return (Resolve-Path $Root).Path }
  return (Get-Location).Path
}
$RepoRoot = Get-RepoRoot
$LockFile = Join-Path $RepoRoot '.gpt5.lock'
if (Test-Path $LockFile) { Write-Error 'CONFLICT: .gpt5.lock exists.'; exit 11 }
"locked $(Get-Date -Format o)" | Out-File $LockFile -Encoding utf8 -NoNewline

$sw=[Diagnostics.Stopwatch]::StartNew()
$trace=[guid]::NewGuid().ToString()
$logPath = Join-Path $RepoRoot 'logs/apply-log.jsonl'
New-Item -ItemType Directory -Force -Path (Split-Path $logPath) | Out-Null

function LogRec([string]$level,[string]$action,[string]$outcome,[string]$msg,[string]$err='') {
  $rec = @{
    timestamp=(Get-Date).ToString('o'); level=$level; traceId=$trace; module='patcher';
    action=$action; inputHash=((Get-Variable -Name patchHash -Scope Global -ValueOnly -ErrorAction SilentlyContinue) ?? ""); outcome=$outcome;
    durationMs=$sw.ElapsedMilliseconds; errorCode=$err; message=$msg
  } | ConvertTo-Json -Compress
  Add-Content -Path $logPath -Value $rec
}

try {
  # ── Preflight: 모듈 로드 & 스모크 ─────────────────────────────────────────────
  $ModPath = Join-Path $RepoRoot 'scripts\lib\kobong-fileio.psm1'
  if (!(Test-Path $ModPath)) { throw "Missing module: $ModPath" }
  Import-Module $ModPath -Force

  # 스모크: 같은 볼륨에 원자 쓰기 → 즉시 삭제
  $smoke = Join-Path $RepoRoot 'webui\public\_klc-smoke.txt'
  $smokeContent = "[klc-smoke] $(Get-Date -Format o)"
  Write-AtomicUtf8 -Path $smoke -Content $smokeContent -Module 'patcher' -Action 'smoke'
  if (Test-Path $smoke) { Remove-Item -LiteralPath $smoke -Force -ErrorAction SilentlyContinue }

  # ── Patch 파일 파싱 ───────────────────────────────────────────────────────────
  $PatchFile = Join-Path $RepoRoot '.kobong\patches.pending.txt'
  if (!(Test-Path $PatchFile)) {
  Write-Host "[SKIP] patches file not found → $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("patches-file-missing: "+$PatchFile) } catch {}
  return
}
  $patchText = Get-Content -LiteralPath $PatchFile -Raw -Encoding UTF8
  $global:patchHash = (Get-FileHash -Algorithm SHA256 -InputStream ([IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes($patchText)))).Hash

  $matches = [regex]::Matches($patchText, '(?ms)#\s*PATCH\s*START\s*(?<body>.*?)#\s*PATCH\s*END')
  if ($matches.Count -eq 0) {
  Write-Host "[SKIP] No PATCH blocks found in $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("no-patch-blocks: "+$PatchFile) } catch {}
  return
}

  $applied = @()
  foreach ($m in $matches) {
    $body = $m.Groups['body'].Value

    $targetRel = [regex]::Match($body, 'TARGET:\s*(?<v>.+)').Groups['v'].Value.Trim()
    $mode      = [regex]::Match($body, 'MODE:\s*(?<v>.+)').Groups['v'].Value.Trim().ToLowerInvariant()
    $find      = [regex]::Match($body, "FIND\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value
    $replace   = [regex]::Match($body, "REPLACE\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value

    if (-not $targetRel) { throw "PATCH missing TARGET" }
    if (-not $mode)      { throw "PATCH missing MODE" }
    if (-not $find)      { throw "PATCH missing FIND" }

    $target = Join-Path $RepoRoot $targetRel
    if (!(Test-Path $target)) {
  Write-Host "[SKIP] TARGET not found → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("target-not-found: "+$targetRel) } catch {}
  continue
}

    $orig = Get-Content -LiteralPath $target -Raw -Encoding UTF8
    $rxOpts = [Text.RegularExpressions.RegexOptions]::Multiline -bor [Text.RegularExpressions.RegexOptions]::Singleline
    $rx = [regex]::new($find, $rxOpts)
    $mt = $rx.Match($orig)
    if (-not $mt.Success) {
  Write-Host "[SKIP] FIND not matched → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("find-not-matched: "+$targetRel) } catch {}
  continue
}

    switch ($mode) {
      'insert-before' {
        $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
      }
      'insert-before' {
  $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
}
'insert-after' {
  $new = $orig.Substring(0, $mt.Index + $mt.Length) + "`n" + $replace + $orig.Substring($mt.Index + $mt.Length)
}
'replace' {
        $new = $rx.Replace($orig, $replace, 1)
      }
      default {
  Write-Host "[SKIP] Unsupported MODE → $mode for $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("unsupported-mode: "+$mode+" for "+$targetRel) } catch {}
  continue
}
    }

    if ($ConfirmApply) {
      $bk = "$target.bak-" + (Get-Date -Format 'yyyyMMdd-HHmmss')
      Copy-Item -LiteralPath $target -Destination $bk -Force
      Write-AtomicUtf8 -Path $target -Content $new -Module 'patcher' -Action ('apply:'+ $mode)
      $applied += $targetRel
    } else {
      Write-Host "[PREVIEW] would patch → $targetRel ($mode)"
    }
  }

  if ($ConfirmApply) {
    LogRec 'INFO' 'apply' 'SUCCESS' ("patched: " + ($applied -join ', '))
  } else {
    LogRec 'INFO' 'preview' 'SUCCESS' ("preview-ok (no writes). blocks="+$matches.Count)
  }

  # ── Gate-3 Verify (경량) ───────────────────────────────────────────────────────
  if ($ConfirmApply) {
    # 핵심 타겟의 구문 일치 재검
    $core = Join-Path $RepoRoot 'scripts\apply_ui_patch.ps1'
    if (Test-Path $core) {
      $c = Get-Content -LiteralPath $core -Raw -Encoding UTF8
      if ($c -notmatch 'ensure valid tmp path .* atomic friendly') {
        Write-Host "[WARN] VERIFY: guard snippet not found in apply_ui_patch.ps1"; try { LogRec "WARN" "verify" "SKIPPED" "guard-missing apply_ui_patch.ps1" } catch {}
      }
    }
  }
}
catch {
  LogRec 'ERROR' 'apply' 'FAILURE' $_.Exception.Message 'LOGIC'
  exit 0
}
finally {
  Remove-Item -Force $LockFile -ErrorAction SilentlyContinue
}
.Exception.Message)" }
  # 스모크: 같은 볼륨에 원자 쓰기 → 즉시 삭제
  $smoke = Join-Path $RepoRoot 'webui\public\_klc-smoke.txt'
  $smokeContent = "[klc-smoke] $(Get-Date -Format o)"
  Write-AtomicUtf8 -Path $smoke -Content $smokeContent -Module 'patcher' -Action 'smoke'
  if (Test-Path $smoke) { Remove-Item -LiteralPath $smoke -Force -ErrorAction SilentlyContinue }

  # ── Patch 파일 파싱 ───────────────────────────────────────────────────────────
  $PatchFile = Join-Path $RepoRoot '.kobong\patches.pending.txt'
  if (!(Test-Path $PatchFile)) {
  Write-Host "[SKIP] patches file not found → $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("patches-file-missing: "+$PatchFile) } catch {}
  return
}
  $patchText = Get-Content -LiteralPath $PatchFile -Raw -Encoding UTF8
  $global:patchHash = (Get-FileHash -Algorithm SHA256 -InputStream ([IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes($patchText)))).Hash

  $matches = [regex]::Matches($patchText, '(?ms)#\s*PATCH\s*START\s*(?<body>.*?)#\s*PATCH\s*END')
  if ($matches.Count -eq 0) {
  Write-Host "[SKIP] No PATCH blocks found in $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("no-patch-blocks: "+$PatchFile) } catch {}
  return
}

  $applied = @()
  foreach ($m in $matches) {
    $body = $m.Groups['body'].Value

    $targetRel = [regex]::Match($body, 'TARGET:\s*(?<v>.+)').Groups['v'].Value.Trim()
    $mode      = [regex]::Match($body, 'MODE:\s*(?<v>.+)').Groups['v'].Value.Trim().ToLowerInvariant()
    $find      = [regex]::Match($body, "FIND\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value
    $replace   = [regex]::Match($body, "REPLACE\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value

    if (-not $targetRel) { throw "PATCH missing TARGET" }
    if (-not $mode)      { throw "PATCH missing MODE" }
    if (-not $find)      { throw "PATCH missing FIND" }

    $target = Join-Path $RepoRoot $targetRel
    if (!(Test-Path $target)) {
  Write-Host "[SKIP] TARGET not found → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("target-not-found: "+$targetRel) } catch {}
  continue
}

    $orig = Get-Content -LiteralPath $target -Raw -Encoding UTF8
    $rxOpts = [Text.RegularExpressions.RegexOptions]::Multiline -bor [Text.RegularExpressions.RegexOptions]::Singleline
    $rx = [regex]::new($find, $rxOpts)
    $mt = $rx.Match($orig)
    if (-not $mt.Success) {
  Write-Host "[SKIP] FIND not matched → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("find-not-matched: "+$targetRel) } catch {}
  continue
}

    switch ($mode) {
      'insert-before' {
        $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
      }
      'insert-before' {
  $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
}
'insert-after' {
  $new = $orig.Substring(0, $mt.Index + $mt.Length) + "`n" + $replace + $orig.Substring($mt.Index + $mt.Length)
}
'replace' {
        $new = $rx.Replace($orig, $replace, 1)
      }
      default {
  Write-Host "[SKIP] Unsupported MODE → $mode for $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("unsupported-mode: "+$mode+" for "+$targetRel) } catch {}
  continue
}
    }

    if ($ConfirmApply) {
      $bk = "$target.bak-" + (Get-Date -Format 'yyyyMMdd-HHmmss')
      Copy-Item -LiteralPath $target -Destination $bk -Force
      Write-AtomicUtf8 -Path $target -Content $new -Module 'patcher' -Action ('apply:'+ $mode)
      $applied += $targetRel
    } else {
      Write-Host "[PREVIEW] would patch → $targetRel ($mode)"
    }
  }

  if ($ConfirmApply) {
    LogRec 'INFO' 'apply' 'SUCCESS' ("patched: " + ($applied -join ', '))
  } else {
    LogRec 'INFO' 'preview' 'SUCCESS' ("preview-ok (no writes). blocks="+$matches.Count)
  }

  # ── Gate-3 Verify (경량) ───────────────────────────────────────────────────────
  if ($ConfirmApply) {
    # 핵심 타겟의 구문 일치 재검
    $core = Join-Path $RepoRoot 'scripts\apply_ui_patch.ps1'
    if (Test-Path $core) {
      $c = Get-Content -LiteralPath $core -Raw -Encoding UTF8
      if ($c -notmatch 'ensure valid tmp path .* atomic friendly') {
        Write-Host "[WARN] VERIFY: guard snippet not found in apply_ui_patch.ps1"; try { LogRec "WARN" "verify" "SKIPPED" "guard-missing apply_ui_patch.ps1" } catch {}
      }
    }
  }
}
catch {
  LogRec 'ERROR' 'apply' 'FAILURE' $_.Exception.Message 'LOGIC'
  exit 0
}
finally {
  Remove-Item -Force $LockFile -ErrorAction SilentlyContinue
}
.Exception.Message)" }
}
  Import-Module $ModPath -Force

  # 스모크: 같은 볼륨에 원자 쓰기 → 즉시 삭제
  $smoke = Join-Path $RepoRoot 'webui\public\_klc-smoke.txt'
  $smokeContent = "[klc-smoke] $(Get-Date -Format o)"
  Write-AtomicUtf8 -Path $smoke -Content $smokeContent -Module 'patcher' -Action 'smoke'
  if (Test-Path $smoke) { Remove-Item -LiteralPath $smoke -Force -ErrorAction SilentlyContinue }

  # ── Patch 파일 파싱 ───────────────────────────────────────────────────────────
  $PatchFile = Join-Path $RepoRoot '.kobong\patches.pending.txt'
  if (!(Test-Path $PatchFile)) {
  Write-Host "[SKIP] patches file not found → $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("patches-file-missing: "+$PatchFile) } catch {}
  return
}
  $patchText = Get-Content -LiteralPath $PatchFile -Raw -Encoding UTF8
  $global:patchHash = (Get-FileHash -Algorithm SHA256 -InputStream ([IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes($patchText)))).Hash

  $matches = [regex]::Matches($patchText, '(?ms)#\s*PATCH\s*START\s*(?<body>.*?)#\s*PATCH\s*END')
  if ($matches.Count -eq 0) {
  Write-Host "[SKIP] No PATCH blocks found in $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("no-patch-blocks: "+$PatchFile) } catch {}
  return
}

  $applied = @()
  foreach ($m in $matches) {
    $body = $m.Groups['body'].Value

    $targetRel = [regex]::Match($body, 'TARGET:\s*(?<v>.+)').Groups['v'].Value.Trim()
    $mode      = [regex]::Match($body, 'MODE:\s*(?<v>.+)').Groups['v'].Value.Trim().ToLowerInvariant()
    $find      = [regex]::Match($body, "FIND\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value
    $replace   = [regex]::Match($body, "REPLACE\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value

    if (-not $targetRel) { throw "PATCH missing TARGET" }
    if (-not $mode)      { throw "PATCH missing MODE" }
    if (-not $find)      { throw "PATCH missing FIND" }

    $target = Join-Path $RepoRoot $targetRel
    if (!(Test-Path $target)) {
  Write-Host "[SKIP] TARGET not found → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("target-not-found: "+$targetRel) } catch {}
  continue
}

    $orig = Get-Content -LiteralPath $target -Raw -Encoding UTF8
    $rxOpts = [Text.RegularExpressions.RegexOptions]::Multiline -bor [Text.RegularExpressions.RegexOptions]::Singleline
    $rx = [regex]::new($find, $rxOpts)
    $mt = $rx.Match($orig)
    if (-not $mt.Success) {
  Write-Host "[SKIP] FIND not matched → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("find-not-matched: "+$targetRel) } catch {}
  continue
}

    switch ($mode) {
      'insert-before' {
        $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
      }
      'insert-before' {
  $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
}
'insert-after' {
  $new = $orig.Substring(0, $mt.Index + $mt.Length) + "`n" + $replace + $orig.Substring($mt.Index + $mt.Length)
}
'replace' {
        $new = $rx.Replace($orig, $replace, 1)
      }
      default {
  Write-Host "[SKIP] Unsupported MODE → $mode for $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("unsupported-mode: "+$mode+" for "+$targetRel) } catch {}
  continue
}
    }

    if ($ConfirmApply) {
      $bk = "$target.bak-" + (Get-Date -Format 'yyyyMMdd-HHmmss')
      Copy-Item -LiteralPath $target -Destination $bk -Force
      Write-AtomicUtf8 -Path $target -Content $new -Module 'patcher' -Action ('apply:'+ $mode)
      $applied += $targetRel
    } else {
      Write-Host "[PREVIEW] would patch → $targetRel ($mode)"
    }
  }

  if ($ConfirmApply) {
    LogRec 'INFO' 'apply' 'SUCCESS' ("patched: " + ($applied -join ', '))
  } else {
    LogRec 'INFO' 'preview' 'SUCCESS' ("preview-ok (no writes). blocks="+$matches.Count)
  }

  # ── Gate-3 Verify (경량) ───────────────────────────────────────────────────────
  if ($ConfirmApply) {
    # 핵심 타겟의 구문 일치 재검
    $core = Join-Path $RepoRoot 'scripts\apply_ui_patch.ps1'
    if (Test-Path $core) {
      $c = Get-Content -LiteralPath $core -Raw -Encoding UTF8
      if ($c -notmatch 'ensure valid tmp path .* atomic friendly') {
        Write-Host "[WARN] VERIFY: guard snippet not found in apply_ui_patch.ps1"; try { LogRec "WARN" "verify" "SKIPPED" "guard-missing apply_ui_patch.ps1" } catch {}
      }
    }
  }
}
catch {
  LogRec 'ERROR' 'apply' 'FAILURE' $_.Exception.Message 'LOGIC'
  exit 0
}
finally {
  Remove-Item -Force $LockFile -ErrorAction SilentlyContinue
}
.Exception.Message)" }
  # 스모크: 같은 볼륨에 원자 쓰기 → 즉시 삭제
  $smoke = Join-Path $RepoRoot 'webui\public\_klc-smoke.txt'
  $smokeContent = "[klc-smoke] $(Get-Date -Format o)"
  Write-AtomicUtf8 -Path $smoke -Content $smokeContent -Module 'patcher' -Action 'smoke'
  if (Test-Path $smoke) { Remove-Item -LiteralPath $smoke -Force -ErrorAction SilentlyContinue }

  # ── Patch 파일 파싱 ───────────────────────────────────────────────────────────
  $PatchFile = Join-Path $RepoRoot '.kobong\patches.pending.txt'
  if (!(Test-Path $PatchFile)) {
  Write-Host "[SKIP] patches file not found → $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("patches-file-missing: "+$PatchFile) } catch {}
  return
}
  $patchText = Get-Content -LiteralPath $PatchFile -Raw -Encoding UTF8
  $global:patchHash = (Get-FileHash -Algorithm SHA256 -InputStream ([IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes($patchText)))).Hash

  $matches = [regex]::Matches($patchText, '(?ms)#\s*PATCH\s*START\s*(?<body>.*?)#\s*PATCH\s*END')
  if ($matches.Count -eq 0) {
  Write-Host "[SKIP] No PATCH blocks found in $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("no-patch-blocks: "+$PatchFile) } catch {}
  return
}

  $applied = @()
  foreach ($m in $matches) {
    $body = $m.Groups['body'].Value

    $targetRel = [regex]::Match($body, 'TARGET:\s*(?<v>.+)').Groups['v'].Value.Trim()
    $mode      = [regex]::Match($body, 'MODE:\s*(?<v>.+)').Groups['v'].Value.Trim().ToLowerInvariant()
    $find      = [regex]::Match($body, "FIND\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value
    $replace   = [regex]::Match($body, "REPLACE\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value

    if (-not $targetRel) { throw "PATCH missing TARGET" }
    if (-not $mode)      { throw "PATCH missing MODE" }
    if (-not $find)      { throw "PATCH missing FIND" }

    $target = Join-Path $RepoRoot $targetRel
    if (!(Test-Path $target)) {
  Write-Host "[SKIP] TARGET not found → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("target-not-found: "+$targetRel) } catch {}
  continue
}

    $orig = Get-Content -LiteralPath $target -Raw -Encoding UTF8
    $rxOpts = [Text.RegularExpressions.RegexOptions]::Multiline -bor [Text.RegularExpressions.RegexOptions]::Singleline
    $rx = [regex]::new($find, $rxOpts)
    $mt = $rx.Match($orig)
    if (-not $mt.Success) {
  Write-Host "[SKIP] FIND not matched → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("find-not-matched: "+$targetRel) } catch {}
  continue
}

    switch ($mode) {
      'insert-before' {
        $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
      }
      'insert-before' {
  $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
}
'insert-after' {
  $new = $orig.Substring(0, $mt.Index + $mt.Length) + "`n" + $replace + $orig.Substring($mt.Index + $mt.Length)
}
'replace' {
        $new = $rx.Replace($orig, $replace, 1)
      }
      default {
  Write-Host "[SKIP] Unsupported MODE → $mode for $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("unsupported-mode: "+$mode+" for "+$targetRel) } catch {}
  continue
}
    }

    if ($ConfirmApply) {
      $bk = "$target.bak-" + (Get-Date -Format 'yyyyMMdd-HHmmss')
      Copy-Item -LiteralPath $target -Destination $bk -Force
      Write-AtomicUtf8 -Path $target -Content $new -Module 'patcher' -Action ('apply:'+ $mode)
      $applied += $targetRel
    } else {
      Write-Host "[PREVIEW] would patch → $targetRel ($mode)"
    }
  }

  if ($ConfirmApply) {
    LogRec 'INFO' 'apply' 'SUCCESS' ("patched: " + ($applied -join ', '))
  } else {
    LogRec 'INFO' 'preview' 'SUCCESS' ("preview-ok (no writes). blocks="+$matches.Count)
  }

  # ── Gate-3 Verify (경량) ───────────────────────────────────────────────────────
  if ($ConfirmApply) {
    # 핵심 타겟의 구문 일치 재검
    $core = Join-Path $RepoRoot 'scripts\apply_ui_patch.ps1'
    if (Test-Path $core) {
      $c = Get-Content -LiteralPath $core -Raw -Encoding UTF8
      if ($c -notmatch 'ensure valid tmp path .* atomic friendly') {
        Write-Host "[WARN] VERIFY: guard snippet not found in apply_ui_patch.ps1"; try { LogRec "WARN" "verify" "SKIPPED" "guard-missing apply_ui_patch.ps1" } catch {}
      }
    }
  }
}
catch {
  LogRec 'ERROR' 'apply' 'FAILURE' $_.Exception.Message 'LOGIC'
  exit 0
}
finally {
  Remove-Item -Force $LockFile -ErrorAction SilentlyContinue
}
.Exception.Message) }
  # 스모크: 같은 볼륨에 원자 쓰기 → 즉시 삭제
  $smoke = Join-Path $RepoRoot 'webui\public\_klc-smoke.txt'
  $smokeContent = "[klc-smoke] $(Get-Date -Format o)"
  Write-AtomicUtf8 -Path $smoke -Content $smokeContent -Module 'patcher' -Action 'smoke'
  if (Test-Path $smoke) { Remove-Item -LiteralPath $smoke -Force -ErrorAction SilentlyContinue }

  # ── Patch 파일 파싱 ───────────────────────────────────────────────────────────
  $PatchFile = Join-Path $RepoRoot '.kobong\patches.pending.txt'
  if (!(Test-Path $PatchFile)) {
  Write-Host "[SKIP] patches file not found → $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("patches-file-missing: "+$PatchFile) } catch {}
  return
}
  $patchText = Get-Content -LiteralPath $PatchFile -Raw -Encoding UTF8
  $global:patchHash = (Get-FileHash -Algorithm SHA256 -InputStream ([IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes($patchText)))).Hash

  $matches = [regex]::Matches($patchText, '(?ms)#\s*PATCH\s*START\s*(?<body>.*?)#\s*PATCH\s*END')
  if ($matches.Count -eq 0) {
  Write-Host "[SKIP] No PATCH blocks found in $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("no-patch-blocks: "+$PatchFile) } catch {}
  return
}

  $applied = @()
  foreach ($m in $matches) {
    $body = $m.Groups['body'].Value

    $targetRel = [regex]::Match($body, 'TARGET:\s*(?<v>.+)').Groups['v'].Value.Trim()
    $mode      = [regex]::Match($body, 'MODE:\s*(?<v>.+)').Groups['v'].Value.Trim().ToLowerInvariant()
    $find      = [regex]::Match($body, "FIND\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value
    $replace   = [regex]::Match($body, "REPLACE\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value

    if (-not $targetRel) { throw "PATCH missing TARGET" }
    if (-not $mode)      { throw "PATCH missing MODE" }
    if (-not $find)      { throw "PATCH missing FIND" }

    $target = Join-Path $RepoRoot $targetRel
    if (!(Test-Path $target)) {
  Write-Host "[SKIP] TARGET not found → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("target-not-found: "+$targetRel) } catch {}
  continue
}

    $orig = Get-Content -LiteralPath $target -Raw -Encoding UTF8
    $rxOpts = [Text.RegularExpressions.RegexOptions]::Multiline -bor [Text.RegularExpressions.RegexOptions]::Singleline
    $rx = [regex]::new($find, $rxOpts)
    $mt = $rx.Match($orig)
    if (-not $mt.Success) {
  Write-Host "[SKIP] FIND not matched → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("find-not-matched: "+$targetRel) } catch {}
  continue
}

    switch ($mode) {
      'insert-before' {
        $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
      }
      'insert-before' {
  $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
}
'insert-after' {
  $new = $orig.Substring(0, $mt.Index + $mt.Length) + "`n" + $replace + $orig.Substring($mt.Index + $mt.Length)
}
'replace' {
        $new = $rx.Replace($orig, $replace, 1)
      }
      default {
  Write-Host "[SKIP] Unsupported MODE → $mode for $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("unsupported-mode: "+$mode+" for "+$targetRel) } catch {}
  continue
}
    }

    if ($ConfirmApply) {
      $bk = "$target.bak-" + (Get-Date -Format 'yyyyMMdd-HHmmss')
      Copy-Item -LiteralPath $target -Destination $bk -Force
      Write-AtomicUtf8 -Path $target -Content $new -Module 'patcher' -Action ('apply:'+ $mode)
      $applied += $targetRel
    } else {
      Write-Host "[PREVIEW] would patch → $targetRel ($mode)"
    }
  }

  if ($ConfirmApply) {
    LogRec 'INFO' 'apply' 'SUCCESS' ("patched: " + ($applied -join ', '))
  } else {
    LogRec 'INFO' 'preview' 'SUCCESS' ("preview-ok (no writes). blocks="+$matches.Count)
  }

  # ── Gate-3 Verify (경량) ───────────────────────────────────────────────────────
  if ($ConfirmApply) {
    # 핵심 타겟의 구문 일치 재검
    $core = Join-Path $RepoRoot 'scripts\apply_ui_patch.ps1'
    if (Test-Path $core) {
      $c = Get-Content -LiteralPath $core -Raw -Encoding UTF8
      if ($c -notmatch 'ensure valid tmp path .* atomic friendly') {
        Write-Host "[WARN] VERIFY: guard snippet not found in apply_ui_patch.ps1"; try { LogRec "WARN" "verify" "SKIPPED" "guard-missing apply_ui_patch.ps1" } catch {}
      }
    }
  }
}
catch {
  LogRec 'ERROR' 'apply' 'FAILURE' $_.Exception.Message 'LOGIC'
  exit 0
}
finally {
  Remove-Item -Force $LockFile -ErrorAction SilentlyContinue
}
.Exception.Message)" }
  # 스모크: 같은 볼륨에 원자 쓰기 → 즉시 삭제
  $smoke = Join-Path $RepoRoot 'webui\public\_klc-smoke.txt'
  $smokeContent = "[klc-smoke] $(Get-Date -Format o)"
  Write-AtomicUtf8 -Path $smoke -Content $smokeContent -Module 'patcher' -Action 'smoke'
  if (Test-Path $smoke) { Remove-Item -LiteralPath $smoke -Force -ErrorAction SilentlyContinue }

  # ── Patch 파일 파싱 ───────────────────────────────────────────────────────────
  $PatchFile = Join-Path $RepoRoot '.kobong\patches.pending.txt'
  if (!(Test-Path $PatchFile)) {
  Write-Host "[SKIP] patches file not found → $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("patches-file-missing: "+$PatchFile) } catch {}
  return
}
  $patchText = Get-Content -LiteralPath $PatchFile -Raw -Encoding UTF8
  $global:patchHash = (Get-FileHash -Algorithm SHA256 -InputStream ([IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes($patchText)))).Hash

  $matches = [regex]::Matches($patchText, '(?ms)#\s*PATCH\s*START\s*(?<body>.*?)#\s*PATCH\s*END')
  if ($matches.Count -eq 0) {
  Write-Host "[SKIP] No PATCH blocks found in $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("no-patch-blocks: "+$PatchFile) } catch {}
  return
}

  $applied = @()
  foreach ($m in $matches) {
    $body = $m.Groups['body'].Value

    $targetRel = [regex]::Match($body, 'TARGET:\s*(?<v>.+)').Groups['v'].Value.Trim()
    $mode      = [regex]::Match($body, 'MODE:\s*(?<v>.+)').Groups['v'].Value.Trim().ToLowerInvariant()
    $find      = [regex]::Match($body, "FIND\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value
    $replace   = [regex]::Match($body, "REPLACE\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value

    if (-not $targetRel) { throw "PATCH missing TARGET" }
    if (-not $mode)      { throw "PATCH missing MODE" }
    if (-not $find)      { throw "PATCH missing FIND" }

    $target = Join-Path $RepoRoot $targetRel
    if (!(Test-Path $target)) {
  Write-Host "[SKIP] TARGET not found → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("target-not-found: "+$targetRel) } catch {}
  continue
}

    $orig = Get-Content -LiteralPath $target -Raw -Encoding UTF8
    $rxOpts = [Text.RegularExpressions.RegexOptions]::Multiline -bor [Text.RegularExpressions.RegexOptions]::Singleline
    $rx = [regex]::new($find, $rxOpts)
    $mt = $rx.Match($orig)
    if (-not $mt.Success) {
  Write-Host "[SKIP] FIND not matched → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("find-not-matched: "+$targetRel) } catch {}
  continue
}

    switch ($mode) {
      'insert-before' {
        $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
      }
      'insert-before' {
  $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
}
'insert-after' {
  $new = $orig.Substring(0, $mt.Index + $mt.Length) + "`n" + $replace + $orig.Substring($mt.Index + $mt.Length)
}
'replace' {
        $new = $rx.Replace($orig, $replace, 1)
      }
      default {
  Write-Host "[SKIP] Unsupported MODE → $mode for $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("unsupported-mode: "+$mode+" for "+$targetRel) } catch {}
  continue
}
    }

    if ($ConfirmApply) {
      $bk = "$target.bak-" + (Get-Date -Format 'yyyyMMdd-HHmmss')
      Copy-Item -LiteralPath $target -Destination $bk -Force
      Write-AtomicUtf8 -Path $target -Content $new -Module 'patcher' -Action ('apply:'+ $mode)
      $applied += $targetRel
    } else {
      Write-Host "[PREVIEW] would patch → $targetRel ($mode)"
    }
  }

  if ($ConfirmApply) {
    LogRec 'INFO' 'apply' 'SUCCESS' ("patched: " + ($applied -join ', '))
  } else {
    LogRec 'INFO' 'preview' 'SUCCESS' ("preview-ok (no writes). blocks="+$matches.Count)
  }

  # ── Gate-3 Verify (경량) ───────────────────────────────────────────────────────
  if ($ConfirmApply) {
    # 핵심 타겟의 구문 일치 재검
    $core = Join-Path $RepoRoot 'scripts\apply_ui_patch.ps1'
    if (Test-Path $core) {
      $c = Get-Content -LiteralPath $core -Raw -Encoding UTF8
      if ($c -notmatch 'ensure valid tmp path .* atomic friendly') {
        Write-Host "[WARN] VERIFY: guard snippet not found in apply_ui_patch.ps1"; try { LogRec "WARN" "verify" "SKIPPED" "guard-missing apply_ui_patch.ps1" } catch {}
      }
    }
  }
}
catch {
  LogRec 'ERROR' 'apply' 'FAILURE' $_.Exception.Message 'LOGIC'
  exit 0
}
finally {
  Remove-Item -Force $LockFile -ErrorAction SilentlyContinue
}
.Exception.Message)" }
}
try { Import-Module $ModPath -Force } catch { Write-Host "[WARN] Import-Module failed → $ModPath: $(# APPLY IN SHELL
#requires -Version 7.0
param([switch]$ConfirmApply,[string]$Root)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

# ── Gate-0: Repo / Lock ─────────────────────────────────────────────────────────
function Get-RepoRoot {
  try {
    $p = (git rev-parse --show-toplevel 2>$null)
    if ($p) { return (Resolve-Path $p).Path }
  } catch {}
  if ($Root) { return (Resolve-Path $Root).Path }
  return (Get-Location).Path
}
$RepoRoot = Get-RepoRoot
$LockFile = Join-Path $RepoRoot '.gpt5.lock'
if (Test-Path $LockFile) { Write-Error 'CONFLICT: .gpt5.lock exists.'; exit 11 }
"locked $(Get-Date -Format o)" | Out-File $LockFile -Encoding utf8 -NoNewline

$sw=[Diagnostics.Stopwatch]::StartNew()
$trace=[guid]::NewGuid().ToString()
$logPath = Join-Path $RepoRoot 'logs/apply-log.jsonl'
New-Item -ItemType Directory -Force -Path (Split-Path $logPath) | Out-Null

function LogRec([string]$level,[string]$action,[string]$outcome,[string]$msg,[string]$err='') {
  $rec = @{
    timestamp=(Get-Date).ToString('o'); level=$level; traceId=$trace; module='patcher';
    action=$action; inputHash=((Get-Variable -Name patchHash -Scope Global -ValueOnly -ErrorAction SilentlyContinue) ?? ""); outcome=$outcome;
    durationMs=$sw.ElapsedMilliseconds; errorCode=$err; message=$msg
  } | ConvertTo-Json -Compress
  Add-Content -Path $logPath -Value $rec
}

try {
  # ── Preflight: 모듈 로드 & 스모크 ─────────────────────────────────────────────
  $ModPath = Join-Path $RepoRoot 'scripts\lib\kobong-fileio.psm1'
  if (!(Test-Path $ModPath)) {
  Write-Host "[WARN] Missing module → $ModPath (continuing)"
  try { LogRec "WARN" "apply" "SKIPPED" ("missing-module: "+$ModPath) } catch {}
} else {
  try { Import-Module $ModPath -Force } catch { Write-Host "[WARN] Import-Module failed → $ModPath: $(# APPLY IN SHELL
#requires -Version 7.0
param([switch]$ConfirmApply,[string]$Root)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

# ── Gate-0: Repo / Lock ─────────────────────────────────────────────────────────
function Get-RepoRoot {
  try {
    $p = (git rev-parse --show-toplevel 2>$null)
    if ($p) { return (Resolve-Path $p).Path }
  } catch {}
  if ($Root) { return (Resolve-Path $Root).Path }
  return (Get-Location).Path
}
$RepoRoot = Get-RepoRoot
$LockFile = Join-Path $RepoRoot '.gpt5.lock'
if (Test-Path $LockFile) { Write-Error 'CONFLICT: .gpt5.lock exists.'; exit 11 }
"locked $(Get-Date -Format o)" | Out-File $LockFile -Encoding utf8 -NoNewline

$sw=[Diagnostics.Stopwatch]::StartNew()
$trace=[guid]::NewGuid().ToString()
$logPath = Join-Path $RepoRoot 'logs/apply-log.jsonl'
New-Item -ItemType Directory -Force -Path (Split-Path $logPath) | Out-Null

function LogRec([string]$level,[string]$action,[string]$outcome,[string]$msg,[string]$err='') {
  $rec = @{
    timestamp=(Get-Date).ToString('o'); level=$level; traceId=$trace; module='patcher';
    action=$action; inputHash=((Get-Variable -Name patchHash -Scope Global -ValueOnly -ErrorAction SilentlyContinue) ?? ""); outcome=$outcome;
    durationMs=$sw.ElapsedMilliseconds; errorCode=$err; message=$msg
  } | ConvertTo-Json -Compress
  Add-Content -Path $logPath -Value $rec
}

try {
  # ── Preflight: 모듈 로드 & 스모크 ─────────────────────────────────────────────
  $ModPath = Join-Path $RepoRoot 'scripts\lib\kobong-fileio.psm1'
  if (!(Test-Path $ModPath)) { throw "Missing module: $ModPath" }
try { Import-Module $ModPath -Force } catch { Write-Host "[WARN] Import-Module failed → $ModPath: $(# APPLY IN SHELL
#requires -Version 7.0
param([switch]$ConfirmApply,[string]$Root)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

# ── Gate-0: Repo / Lock ─────────────────────────────────────────────────────────
function Get-RepoRoot {
  try {
    $p = (git rev-parse --show-toplevel 2>$null)
    if ($p) { return (Resolve-Path $p).Path }
  } catch {}
  if ($Root) { return (Resolve-Path $Root).Path }
  return (Get-Location).Path
}
$RepoRoot = Get-RepoRoot
$LockFile = Join-Path $RepoRoot '.gpt5.lock'
if (Test-Path $LockFile) { Write-Error 'CONFLICT: .gpt5.lock exists.'; exit 11 }
"locked $(Get-Date -Format o)" | Out-File $LockFile -Encoding utf8 -NoNewline

$sw=[Diagnostics.Stopwatch]::StartNew()
$trace=[guid]::NewGuid().ToString()
$logPath = Join-Path $RepoRoot 'logs/apply-log.jsonl'
New-Item -ItemType Directory -Force -Path (Split-Path $logPath) | Out-Null

function LogRec([string]$level,[string]$action,[string]$outcome,[string]$msg,[string]$err='') {
  $rec = @{
    timestamp=(Get-Date).ToString('o'); level=$level; traceId=$trace; module='patcher';
    action=$action; inputHash=((Get-Variable -Name patchHash -Scope Global -ValueOnly -ErrorAction SilentlyContinue) ?? ""); outcome=$outcome;
    durationMs=$sw.ElapsedMilliseconds; errorCode=$err; message=$msg
  } | ConvertTo-Json -Compress
  Add-Content -Path $logPath -Value $rec
}

try {
  # ── Preflight: 모듈 로드 & 스모크 ─────────────────────────────────────────────
  $ModPath = Join-Path $RepoRoot 'scripts\lib\kobong-fileio.psm1'
  if (!(Test-Path $ModPath)) { throw "Missing module: $ModPath" }
try { Import-Module $ModPath -Force } catch { Write-Host ("[WARN] Import-Module failed -> " + $ModPath + ": " + # APPLY IN SHELL
#requires -Version 7.0
param([switch]$ConfirmApply,[string]$Root)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

# ── Gate-0: Repo / Lock ─────────────────────────────────────────────────────────
function Get-RepoRoot {
  try {
    $p = (git rev-parse --show-toplevel 2>$null)
    if ($p) { return (Resolve-Path $p).Path }
  } catch {}
  if ($Root) { return (Resolve-Path $Root).Path }
  return (Get-Location).Path
}
$RepoRoot = Get-RepoRoot
$LockFile = Join-Path $RepoRoot '.gpt5.lock'
if (Test-Path $LockFile) { Write-Error 'CONFLICT: .gpt5.lock exists.'; exit 11 }
"locked $(Get-Date -Format o)" | Out-File $LockFile -Encoding utf8 -NoNewline

$sw=[Diagnostics.Stopwatch]::StartNew()
$trace=[guid]::NewGuid().ToString()
$logPath = Join-Path $RepoRoot 'logs/apply-log.jsonl'
New-Item -ItemType Directory -Force -Path (Split-Path $logPath) | Out-Null

function LogRec([string]$level,[string]$action,[string]$outcome,[string]$msg,[string]$err='') {
  $rec = @{
    timestamp=(Get-Date).ToString('o'); level=$level; traceId=$trace; module='patcher';
    action=$action; inputHash=((Get-Variable -Name patchHash -Scope Global -ValueOnly -ErrorAction SilentlyContinue) ?? ""); outcome=$outcome;
    durationMs=$sw.ElapsedMilliseconds; errorCode=$err; message=$msg
  } | ConvertTo-Json -Compress
  Add-Content -Path $logPath -Value $rec
}

try {
  # ── Preflight: 모듈 로드 & 스모크 ─────────────────────────────────────────────
  $ModPath = Join-Path $RepoRoot 'scripts\lib\kobong-fileio.psm1'
  if (!(Test-Path $ModPath)) {
  Write-Host "[WARN] Missing module → $ModPath (continuing)"
  try { LogRec "WARN" "apply" "SKIPPED" ("missing-module: "+$ModPath) } catch {}
} else {
  try { Import-Module $ModPath -Force } catch { Write-Host ("[WARN] Import-Module failed -> " + $ModPath + ": " + # APPLY IN SHELL
#requires -Version 7.0
param([switch]$ConfirmApply,[string]$Root)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

# ── Gate-0: Repo / Lock ─────────────────────────────────────────────────────────
function Get-RepoRoot {
  try {
    $p = (git rev-parse --show-toplevel 2>$null)
    if ($p) { return (Resolve-Path $p).Path }
  } catch {}
  if ($Root) { return (Resolve-Path $Root).Path }
  return (Get-Location).Path
}
$RepoRoot = Get-RepoRoot
$LockFile = Join-Path $RepoRoot '.gpt5.lock'
if (Test-Path $LockFile) { Write-Error 'CONFLICT: .gpt5.lock exists.'; exit 11 }
"locked $(Get-Date -Format o)" | Out-File $LockFile -Encoding utf8 -NoNewline

$sw=[Diagnostics.Stopwatch]::StartNew()
$trace=[guid]::NewGuid().ToString()
$logPath = Join-Path $RepoRoot 'logs/apply-log.jsonl'
New-Item -ItemType Directory -Force -Path (Split-Path $logPath) | Out-Null

function LogRec([string]$level,[string]$action,[string]$outcome,[string]$msg,[string]$err='') {
  $rec = @{
    timestamp=(Get-Date).ToString('o'); level=$level; traceId=$trace; module='patcher';
    action=$action; inputHash=((Get-Variable -Name patchHash -Scope Global -ValueOnly -ErrorAction SilentlyContinue) ?? ""); outcome=$outcome;
    durationMs=$sw.ElapsedMilliseconds; errorCode=$err; message=$msg
  } | ConvertTo-Json -Compress
  Add-Content -Path $logPath -Value $rec
}

try {
  # ── Preflight: 모듈 로드 & 스모크 ─────────────────────────────────────────────
  $ModPath = Join-Path $RepoRoot 'scripts\lib\kobong-fileio.psm1'
  if (!(Test-Path $ModPath)) {
  Write-Host "[WARN] Missing module → $ModPath (continuing)"
  try { LogRec "WARN" "apply" "SKIPPED" ("missing-module: "+$ModPath) } catch {}
} else {
  try { Import-Module $ModPath -Force } catch { Write-Host "[WARN] Import-Module failed → $ModPath: $(# APPLY IN SHELL
#requires -Version 7.0
param([switch]$ConfirmApply,[string]$Root)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

# ── Gate-0: Repo / Lock ─────────────────────────────────────────────────────────
function Get-RepoRoot {
  try {
    $p = (git rev-parse --show-toplevel 2>$null)
    if ($p) { return (Resolve-Path $p).Path }
  } catch {}
  if ($Root) { return (Resolve-Path $Root).Path }
  return (Get-Location).Path
}
$RepoRoot = Get-RepoRoot
$LockFile = Join-Path $RepoRoot '.gpt5.lock'
if (Test-Path $LockFile) { Write-Error 'CONFLICT: .gpt5.lock exists.'; exit 11 }
"locked $(Get-Date -Format o)" | Out-File $LockFile -Encoding utf8 -NoNewline

$sw=[Diagnostics.Stopwatch]::StartNew()
$trace=[guid]::NewGuid().ToString()
$logPath = Join-Path $RepoRoot 'logs/apply-log.jsonl'
New-Item -ItemType Directory -Force -Path (Split-Path $logPath) | Out-Null

function LogRec([string]$level,[string]$action,[string]$outcome,[string]$msg,[string]$err='') {
  $rec = @{
    timestamp=(Get-Date).ToString('o'); level=$level; traceId=$trace; module='patcher';
    action=$action; inputHash=((Get-Variable -Name patchHash -Scope Global -ValueOnly -ErrorAction SilentlyContinue) ?? ""); outcome=$outcome;
    durationMs=$sw.ElapsedMilliseconds; errorCode=$err; message=$msg
  } | ConvertTo-Json -Compress
  Add-Content -Path $logPath -Value $rec
}

try {
  # ── Preflight: 모듈 로드 & 스모크 ─────────────────────────────────────────────
  $ModPath = Join-Path $RepoRoot 'scripts\lib\kobong-fileio.psm1'
  if (!(Test-Path $ModPath)) { throw "Missing module: $ModPath" }
try { Import-Module $ModPath -Force } catch { Write-Host "[WARN] Import-Module failed → $ModPath: $(# APPLY IN SHELL
#requires -Version 7.0
param([switch]$ConfirmApply,[string]$Root)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

# ── Gate-0: Repo / Lock ─────────────────────────────────────────────────────────
function Get-RepoRoot {
  try {
    $p = (git rev-parse --show-toplevel 2>$null)
    if ($p) { return (Resolve-Path $p).Path }
  } catch {}
  if ($Root) { return (Resolve-Path $Root).Path }
  return (Get-Location).Path
}
$RepoRoot = Get-RepoRoot
$LockFile = Join-Path $RepoRoot '.gpt5.lock'
if (Test-Path $LockFile) { Write-Error 'CONFLICT: .gpt5.lock exists.'; exit 11 }
"locked $(Get-Date -Format o)" | Out-File $LockFile -Encoding utf8 -NoNewline

$sw=[Diagnostics.Stopwatch]::StartNew()
$trace=[guid]::NewGuid().ToString()
$logPath = Join-Path $RepoRoot 'logs/apply-log.jsonl'
New-Item -ItemType Directory -Force -Path (Split-Path $logPath) | Out-Null

function LogRec([string]$level,[string]$action,[string]$outcome,[string]$msg,[string]$err='') {
  $rec = @{
    timestamp=(Get-Date).ToString('o'); level=$level; traceId=$trace; module='patcher';
    action=$action; inputHash=((Get-Variable -Name patchHash -Scope Global -ValueOnly -ErrorAction SilentlyContinue) ?? ""); outcome=$outcome;
    durationMs=$sw.ElapsedMilliseconds; errorCode=$err; message=$msg
  } | ConvertTo-Json -Compress
  Add-Content -Path $logPath -Value $rec
}

try {
  # ── Preflight: 모듈 로드 & 스모크 ─────────────────────────────────────────────
  $ModPath = Join-Path $RepoRoot 'scripts\lib\kobong-fileio.psm1'
  if (!(Test-Path $ModPath)) { throw "Missing module: $ModPath" }
  Import-Module $ModPath -Force

  # 스모크: 같은 볼륨에 원자 쓰기 → 즉시 삭제
  $smoke = Join-Path $RepoRoot 'webui\public\_klc-smoke.txt'
  $smokeContent = "[klc-smoke] $(Get-Date -Format o)"
  Write-AtomicUtf8 -Path $smoke -Content $smokeContent -Module 'patcher' -Action 'smoke'
  if (Test-Path $smoke) { Remove-Item -LiteralPath $smoke -Force -ErrorAction SilentlyContinue }

  # ── Patch 파일 파싱 ───────────────────────────────────────────────────────────
  $PatchFile = Join-Path $RepoRoot '.kobong\patches.pending.txt'
  if (!(Test-Path $PatchFile)) {
  Write-Host "[SKIP] patches file not found → $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("patches-file-missing: "+$PatchFile) } catch {}
  return
}
  $patchText = Get-Content -LiteralPath $PatchFile -Raw -Encoding UTF8
  $global:patchHash = (Get-FileHash -Algorithm SHA256 -InputStream ([IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes($patchText)))).Hash

  $matches = [regex]::Matches($patchText, '(?ms)#\s*PATCH\s*START\s*(?<body>.*?)#\s*PATCH\s*END')
  if ($matches.Count -eq 0) {
  Write-Host "[SKIP] No PATCH blocks found in $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("no-patch-blocks: "+$PatchFile) } catch {}
  return
}

  $applied = @()
  foreach ($m in $matches) {
    $body = $m.Groups['body'].Value

    $targetRel = [regex]::Match($body, 'TARGET:\s*(?<v>.+)').Groups['v'].Value.Trim()
    $mode      = [regex]::Match($body, 'MODE:\s*(?<v>.+)').Groups['v'].Value.Trim().ToLowerInvariant()
    $find      = [regex]::Match($body, "FIND\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value
    $replace   = [regex]::Match($body, "REPLACE\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value

    if (-not $targetRel) { throw "PATCH missing TARGET" }
    if (-not $mode)      { throw "PATCH missing MODE" }
    if (-not $find)      { throw "PATCH missing FIND" }

    $target = Join-Path $RepoRoot $targetRel
    if (!(Test-Path $target)) {
  Write-Host "[SKIP] TARGET not found → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("target-not-found: "+$targetRel) } catch {}
  continue
}

    $orig = Get-Content -LiteralPath $target -Raw -Encoding UTF8
    $rxOpts = [Text.RegularExpressions.RegexOptions]::Multiline -bor [Text.RegularExpressions.RegexOptions]::Singleline
    $rx = [regex]::new($find, $rxOpts)
    $mt = $rx.Match($orig)
    if (-not $mt.Success) {
  Write-Host "[SKIP] FIND not matched → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("find-not-matched: "+$targetRel) } catch {}
  continue
}

    switch ($mode) {
      'insert-before' {
        $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
      }
      'insert-before' {
  $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
}
'insert-after' {
  $new = $orig.Substring(0, $mt.Index + $mt.Length) + "`n" + $replace + $orig.Substring($mt.Index + $mt.Length)
}
'replace' {
        $new = $rx.Replace($orig, $replace, 1)
      }
      default {
  Write-Host "[SKIP] Unsupported MODE → $mode for $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("unsupported-mode: "+$mode+" for "+$targetRel) } catch {}
  continue
}
    }

    if ($ConfirmApply) {
      $bk = "$target.bak-" + (Get-Date -Format 'yyyyMMdd-HHmmss')
      Copy-Item -LiteralPath $target -Destination $bk -Force
      Write-AtomicUtf8 -Path $target -Content $new -Module 'patcher' -Action ('apply:'+ $mode)
      $applied += $targetRel
    } else {
      Write-Host "[PREVIEW] would patch → $targetRel ($mode)"
    }
  }

  if ($ConfirmApply) {
    LogRec 'INFO' 'apply' 'SUCCESS' ("patched: " + ($applied -join ', '))
  } else {
    LogRec 'INFO' 'preview' 'SUCCESS' ("preview-ok (no writes). blocks="+$matches.Count)
  }

  # ── Gate-3 Verify (경량) ───────────────────────────────────────────────────────
  if ($ConfirmApply) {
    # 핵심 타겟의 구문 일치 재검
    $core = Join-Path $RepoRoot 'scripts\apply_ui_patch.ps1'
    if (Test-Path $core) {
      $c = Get-Content -LiteralPath $core -Raw -Encoding UTF8
      if ($c -notmatch 'ensure valid tmp path .* atomic friendly') {
        Write-Host "[WARN] VERIFY: guard snippet not found in apply_ui_patch.ps1"; try { LogRec "WARN" "verify" "SKIPPED" "guard-missing apply_ui_patch.ps1" } catch {}
      }
    }
  }
}
catch {
  LogRec 'ERROR' 'apply' 'FAILURE' $_.Exception.Message 'LOGIC'
  exit 0
}
finally {
  Remove-Item -Force $LockFile -ErrorAction SilentlyContinue
}
.Exception.Message)" }
  # 스모크: 같은 볼륨에 원자 쓰기 → 즉시 삭제
  $smoke = Join-Path $RepoRoot 'webui\public\_klc-smoke.txt'
  $smokeContent = "[klc-smoke] $(Get-Date -Format o)"
  Write-AtomicUtf8 -Path $smoke -Content $smokeContent -Module 'patcher' -Action 'smoke'
  if (Test-Path $smoke) { Remove-Item -LiteralPath $smoke -Force -ErrorAction SilentlyContinue }

  # ── Patch 파일 파싱 ───────────────────────────────────────────────────────────
  $PatchFile = Join-Path $RepoRoot '.kobong\patches.pending.txt'
  if (!(Test-Path $PatchFile)) {
  Write-Host "[SKIP] patches file not found → $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("patches-file-missing: "+$PatchFile) } catch {}
  return
}
  $patchText = Get-Content -LiteralPath $PatchFile -Raw -Encoding UTF8
  $global:patchHash = (Get-FileHash -Algorithm SHA256 -InputStream ([IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes($patchText)))).Hash

  $matches = [regex]::Matches($patchText, '(?ms)#\s*PATCH\s*START\s*(?<body>.*?)#\s*PATCH\s*END')
  if ($matches.Count -eq 0) {
  Write-Host "[SKIP] No PATCH blocks found in $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("no-patch-blocks: "+$PatchFile) } catch {}
  return
}

  $applied = @()
  foreach ($m in $matches) {
    $body = $m.Groups['body'].Value

    $targetRel = [regex]::Match($body, 'TARGET:\s*(?<v>.+)').Groups['v'].Value.Trim()
    $mode      = [regex]::Match($body, 'MODE:\s*(?<v>.+)').Groups['v'].Value.Trim().ToLowerInvariant()
    $find      = [regex]::Match($body, "FIND\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value
    $replace   = [regex]::Match($body, "REPLACE\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value

    if (-not $targetRel) { throw "PATCH missing TARGET" }
    if (-not $mode)      { throw "PATCH missing MODE" }
    if (-not $find)      { throw "PATCH missing FIND" }

    $target = Join-Path $RepoRoot $targetRel
    if (!(Test-Path $target)) {
  Write-Host "[SKIP] TARGET not found → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("target-not-found: "+$targetRel) } catch {}
  continue
}

    $orig = Get-Content -LiteralPath $target -Raw -Encoding UTF8
    $rxOpts = [Text.RegularExpressions.RegexOptions]::Multiline -bor [Text.RegularExpressions.RegexOptions]::Singleline
    $rx = [regex]::new($find, $rxOpts)
    $mt = $rx.Match($orig)
    if (-not $mt.Success) {
  Write-Host "[SKIP] FIND not matched → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("find-not-matched: "+$targetRel) } catch {}
  continue
}

    switch ($mode) {
      'insert-before' {
        $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
      }
      'insert-before' {
  $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
}
'insert-after' {
  $new = $orig.Substring(0, $mt.Index + $mt.Length) + "`n" + $replace + $orig.Substring($mt.Index + $mt.Length)
}
'replace' {
        $new = $rx.Replace($orig, $replace, 1)
      }
      default {
  Write-Host "[SKIP] Unsupported MODE → $mode for $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("unsupported-mode: "+$mode+" for "+$targetRel) } catch {}
  continue
}
    }

    if ($ConfirmApply) {
      $bk = "$target.bak-" + (Get-Date -Format 'yyyyMMdd-HHmmss')
      Copy-Item -LiteralPath $target -Destination $bk -Force
      Write-AtomicUtf8 -Path $target -Content $new -Module 'patcher' -Action ('apply:'+ $mode)
      $applied += $targetRel
    } else {
      Write-Host "[PREVIEW] would patch → $targetRel ($mode)"
    }
  }

  if ($ConfirmApply) {
    LogRec 'INFO' 'apply' 'SUCCESS' ("patched: " + ($applied -join ', '))
  } else {
    LogRec 'INFO' 'preview' 'SUCCESS' ("preview-ok (no writes). blocks="+$matches.Count)
  }

  # ── Gate-3 Verify (경량) ───────────────────────────────────────────────────────
  if ($ConfirmApply) {
    # 핵심 타겟의 구문 일치 재검
    $core = Join-Path $RepoRoot 'scripts\apply_ui_patch.ps1'
    if (Test-Path $core) {
      $c = Get-Content -LiteralPath $core -Raw -Encoding UTF8
      if ($c -notmatch 'ensure valid tmp path .* atomic friendly') {
        Write-Host "[WARN] VERIFY: guard snippet not found in apply_ui_patch.ps1"; try { LogRec "WARN" "verify" "SKIPPED" "guard-missing apply_ui_patch.ps1" } catch {}
      }
    }
  }
}
catch {
  LogRec 'ERROR' 'apply' 'FAILURE' $_.Exception.Message 'LOGIC'
  exit 0
}
finally {
  Remove-Item -Force $LockFile -ErrorAction SilentlyContinue
}
.Exception.Message)" }
}
try { Import-Module $ModPath -Force } catch { Write-Host "[WARN] Import-Module failed → $ModPath: $(# APPLY IN SHELL
#requires -Version 7.0
param([switch]$ConfirmApply,[string]$Root)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

# ── Gate-0: Repo / Lock ─────────────────────────────────────────────────────────
function Get-RepoRoot {
  try {
    $p = (git rev-parse --show-toplevel 2>$null)
    if ($p) { return (Resolve-Path $p).Path }
  } catch {}
  if ($Root) { return (Resolve-Path $Root).Path }
  return (Get-Location).Path
}
$RepoRoot = Get-RepoRoot
$LockFile = Join-Path $RepoRoot '.gpt5.lock'
if (Test-Path $LockFile) { Write-Error 'CONFLICT: .gpt5.lock exists.'; exit 11 }
"locked $(Get-Date -Format o)" | Out-File $LockFile -Encoding utf8 -NoNewline

$sw=[Diagnostics.Stopwatch]::StartNew()
$trace=[guid]::NewGuid().ToString()
$logPath = Join-Path $RepoRoot 'logs/apply-log.jsonl'
New-Item -ItemType Directory -Force -Path (Split-Path $logPath) | Out-Null

function LogRec([string]$level,[string]$action,[string]$outcome,[string]$msg,[string]$err='') {
  $rec = @{
    timestamp=(Get-Date).ToString('o'); level=$level; traceId=$trace; module='patcher';
    action=$action; inputHash=((Get-Variable -Name patchHash -Scope Global -ValueOnly -ErrorAction SilentlyContinue) ?? ""); outcome=$outcome;
    durationMs=$sw.ElapsedMilliseconds; errorCode=$err; message=$msg
  } | ConvertTo-Json -Compress
  Add-Content -Path $logPath -Value $rec
}

try {
  # ── Preflight: 모듈 로드 & 스모크 ─────────────────────────────────────────────
  $ModPath = Join-Path $RepoRoot 'scripts\lib\kobong-fileio.psm1'
  if (!(Test-Path $ModPath)) {
  Write-Host "[WARN] Missing module → $ModPath (continuing)"
  try { LogRec "WARN" "apply" "SKIPPED" ("missing-module: "+$ModPath) } catch {}
} else {
  try { Import-Module $ModPath -Force } catch { Write-Host "[WARN] Import-Module failed → $ModPath: $(# APPLY IN SHELL
#requires -Version 7.0
param([switch]$ConfirmApply,[string]$Root)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

# ── Gate-0: Repo / Lock ─────────────────────────────────────────────────────────
function Get-RepoRoot {
  try {
    $p = (git rev-parse --show-toplevel 2>$null)
    if ($p) { return (Resolve-Path $p).Path }
  } catch {}
  if ($Root) { return (Resolve-Path $Root).Path }
  return (Get-Location).Path
}
$RepoRoot = Get-RepoRoot
$LockFile = Join-Path $RepoRoot '.gpt5.lock'
if (Test-Path $LockFile) { Write-Error 'CONFLICT: .gpt5.lock exists.'; exit 11 }
"locked $(Get-Date -Format o)" | Out-File $LockFile -Encoding utf8 -NoNewline

$sw=[Diagnostics.Stopwatch]::StartNew()
$trace=[guid]::NewGuid().ToString()
$logPath = Join-Path $RepoRoot 'logs/apply-log.jsonl'
New-Item -ItemType Directory -Force -Path (Split-Path $logPath) | Out-Null

function LogRec([string]$level,[string]$action,[string]$outcome,[string]$msg,[string]$err='') {
  $rec = @{
    timestamp=(Get-Date).ToString('o'); level=$level; traceId=$trace; module='patcher';
    action=$action; inputHash=((Get-Variable -Name patchHash -Scope Global -ValueOnly -ErrorAction SilentlyContinue) ?? ""); outcome=$outcome;
    durationMs=$sw.ElapsedMilliseconds; errorCode=$err; message=$msg
  } | ConvertTo-Json -Compress
  Add-Content -Path $logPath -Value $rec
}

try {
  # ── Preflight: 모듈 로드 & 스모크 ─────────────────────────────────────────────
  $ModPath = Join-Path $RepoRoot 'scripts\lib\kobong-fileio.psm1'
  if (!(Test-Path $ModPath)) { throw "Missing module: $ModPath" }
try { Import-Module $ModPath -Force } catch { Write-Host "[WARN] Import-Module failed → $ModPath: $(# APPLY IN SHELL
#requires -Version 7.0
param([switch]$ConfirmApply,[string]$Root)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

# ── Gate-0: Repo / Lock ─────────────────────────────────────────────────────────
function Get-RepoRoot {
  try {
    $p = (git rev-parse --show-toplevel 2>$null)
    if ($p) { return (Resolve-Path $p).Path }
  } catch {}
  if ($Root) { return (Resolve-Path $Root).Path }
  return (Get-Location).Path
}
$RepoRoot = Get-RepoRoot
$LockFile = Join-Path $RepoRoot '.gpt5.lock'
if (Test-Path $LockFile) { Write-Error 'CONFLICT: .gpt5.lock exists.'; exit 11 }
"locked $(Get-Date -Format o)" | Out-File $LockFile -Encoding utf8 -NoNewline

$sw=[Diagnostics.Stopwatch]::StartNew()
$trace=[guid]::NewGuid().ToString()
$logPath = Join-Path $RepoRoot 'logs/apply-log.jsonl'
New-Item -ItemType Directory -Force -Path (Split-Path $logPath) | Out-Null

function LogRec([string]$level,[string]$action,[string]$outcome,[string]$msg,[string]$err='') {
  $rec = @{
    timestamp=(Get-Date).ToString('o'); level=$level; traceId=$trace; module='patcher';
    action=$action; inputHash=((Get-Variable -Name patchHash -Scope Global -ValueOnly -ErrorAction SilentlyContinue) ?? ""); outcome=$outcome;
    durationMs=$sw.ElapsedMilliseconds; errorCode=$err; message=$msg
  } | ConvertTo-Json -Compress
  Add-Content -Path $logPath -Value $rec
}

try {
  # ── Preflight: 모듈 로드 & 스모크 ─────────────────────────────────────────────
  $ModPath = Join-Path $RepoRoot 'scripts\lib\kobong-fileio.psm1'
  if (!(Test-Path $ModPath)) { throw "Missing module: $ModPath" }
  Import-Module $ModPath -Force

  # 스모크: 같은 볼륨에 원자 쓰기 → 즉시 삭제
  $smoke = Join-Path $RepoRoot 'webui\public\_klc-smoke.txt'
  $smokeContent = "[klc-smoke] $(Get-Date -Format o)"
  Write-AtomicUtf8 -Path $smoke -Content $smokeContent -Module 'patcher' -Action 'smoke'
  if (Test-Path $smoke) { Remove-Item -LiteralPath $smoke -Force -ErrorAction SilentlyContinue }

  # ── Patch 파일 파싱 ───────────────────────────────────────────────────────────
  $PatchFile = Join-Path $RepoRoot '.kobong\patches.pending.txt'
  if (!(Test-Path $PatchFile)) {
  Write-Host "[SKIP] patches file not found → $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("patches-file-missing: "+$PatchFile) } catch {}
  return
}
  $patchText = Get-Content -LiteralPath $PatchFile -Raw -Encoding UTF8
  $global:patchHash = (Get-FileHash -Algorithm SHA256 -InputStream ([IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes($patchText)))).Hash

  $matches = [regex]::Matches($patchText, '(?ms)#\s*PATCH\s*START\s*(?<body>.*?)#\s*PATCH\s*END')
  if ($matches.Count -eq 0) {
  Write-Host "[SKIP] No PATCH blocks found in $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("no-patch-blocks: "+$PatchFile) } catch {}
  return
}

  $applied = @()
  foreach ($m in $matches) {
    $body = $m.Groups['body'].Value

    $targetRel = [regex]::Match($body, 'TARGET:\s*(?<v>.+)').Groups['v'].Value.Trim()
    $mode      = [regex]::Match($body, 'MODE:\s*(?<v>.+)').Groups['v'].Value.Trim().ToLowerInvariant()
    $find      = [regex]::Match($body, "FIND\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value
    $replace   = [regex]::Match($body, "REPLACE\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value

    if (-not $targetRel) { throw "PATCH missing TARGET" }
    if (-not $mode)      { throw "PATCH missing MODE" }
    if (-not $find)      { throw "PATCH missing FIND" }

    $target = Join-Path $RepoRoot $targetRel
    if (!(Test-Path $target)) {
  Write-Host "[SKIP] TARGET not found → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("target-not-found: "+$targetRel) } catch {}
  continue
}

    $orig = Get-Content -LiteralPath $target -Raw -Encoding UTF8
    $rxOpts = [Text.RegularExpressions.RegexOptions]::Multiline -bor [Text.RegularExpressions.RegexOptions]::Singleline
    $rx = [regex]::new($find, $rxOpts)
    $mt = $rx.Match($orig)
    if (-not $mt.Success) {
  Write-Host "[SKIP] FIND not matched → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("find-not-matched: "+$targetRel) } catch {}
  continue
}

    switch ($mode) {
      'insert-before' {
        $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
      }
      'insert-before' {
  $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
}
'insert-after' {
  $new = $orig.Substring(0, $mt.Index + $mt.Length) + "`n" + $replace + $orig.Substring($mt.Index + $mt.Length)
}
'replace' {
        $new = $rx.Replace($orig, $replace, 1)
      }
      default {
  Write-Host "[SKIP] Unsupported MODE → $mode for $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("unsupported-mode: "+$mode+" for "+$targetRel) } catch {}
  continue
}
    }

    if ($ConfirmApply) {
      $bk = "$target.bak-" + (Get-Date -Format 'yyyyMMdd-HHmmss')
      Copy-Item -LiteralPath $target -Destination $bk -Force
      Write-AtomicUtf8 -Path $target -Content $new -Module 'patcher' -Action ('apply:'+ $mode)
      $applied += $targetRel
    } else {
      Write-Host "[PREVIEW] would patch → $targetRel ($mode)"
    }
  }

  if ($ConfirmApply) {
    LogRec 'INFO' 'apply' 'SUCCESS' ("patched: " + ($applied -join ', '))
  } else {
    LogRec 'INFO' 'preview' 'SUCCESS' ("preview-ok (no writes). blocks="+$matches.Count)
  }

  # ── Gate-3 Verify (경량) ───────────────────────────────────────────────────────
  if ($ConfirmApply) {
    # 핵심 타겟의 구문 일치 재검
    $core = Join-Path $RepoRoot 'scripts\apply_ui_patch.ps1'
    if (Test-Path $core) {
      $c = Get-Content -LiteralPath $core -Raw -Encoding UTF8
      if ($c -notmatch 'ensure valid tmp path .* atomic friendly') {
        Write-Host "[WARN] VERIFY: guard snippet not found in apply_ui_patch.ps1"; try { LogRec "WARN" "verify" "SKIPPED" "guard-missing apply_ui_patch.ps1" } catch {}
      }
    }
  }
}
catch {
  LogRec 'ERROR' 'apply' 'FAILURE' $_.Exception.Message 'LOGIC'
  exit 0
}
finally {
  Remove-Item -Force $LockFile -ErrorAction SilentlyContinue
}
.Exception.Message)" }
  # 스모크: 같은 볼륨에 원자 쓰기 → 즉시 삭제
  $smoke = Join-Path $RepoRoot 'webui\public\_klc-smoke.txt'
  $smokeContent = "[klc-smoke] $(Get-Date -Format o)"
  Write-AtomicUtf8 -Path $smoke -Content $smokeContent -Module 'patcher' -Action 'smoke'
  if (Test-Path $smoke) { Remove-Item -LiteralPath $smoke -Force -ErrorAction SilentlyContinue }

  # ── Patch 파일 파싱 ───────────────────────────────────────────────────────────
  $PatchFile = Join-Path $RepoRoot '.kobong\patches.pending.txt'
  if (!(Test-Path $PatchFile)) {
  Write-Host "[SKIP] patches file not found → $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("patches-file-missing: "+$PatchFile) } catch {}
  return
}
  $patchText = Get-Content -LiteralPath $PatchFile -Raw -Encoding UTF8
  $global:patchHash = (Get-FileHash -Algorithm SHA256 -InputStream ([IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes($patchText)))).Hash

  $matches = [regex]::Matches($patchText, '(?ms)#\s*PATCH\s*START\s*(?<body>.*?)#\s*PATCH\s*END')
  if ($matches.Count -eq 0) {
  Write-Host "[SKIP] No PATCH blocks found in $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("no-patch-blocks: "+$PatchFile) } catch {}
  return
}

  $applied = @()
  foreach ($m in $matches) {
    $body = $m.Groups['body'].Value

    $targetRel = [regex]::Match($body, 'TARGET:\s*(?<v>.+)').Groups['v'].Value.Trim()
    $mode      = [regex]::Match($body, 'MODE:\s*(?<v>.+)').Groups['v'].Value.Trim().ToLowerInvariant()
    $find      = [regex]::Match($body, "FIND\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value
    $replace   = [regex]::Match($body, "REPLACE\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value

    if (-not $targetRel) { throw "PATCH missing TARGET" }
    if (-not $mode)      { throw "PATCH missing MODE" }
    if (-not $find)      { throw "PATCH missing FIND" }

    $target = Join-Path $RepoRoot $targetRel
    if (!(Test-Path $target)) {
  Write-Host "[SKIP] TARGET not found → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("target-not-found: "+$targetRel) } catch {}
  continue
}

    $orig = Get-Content -LiteralPath $target -Raw -Encoding UTF8
    $rxOpts = [Text.RegularExpressions.RegexOptions]::Multiline -bor [Text.RegularExpressions.RegexOptions]::Singleline
    $rx = [regex]::new($find, $rxOpts)
    $mt = $rx.Match($orig)
    if (-not $mt.Success) {
  Write-Host "[SKIP] FIND not matched → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("find-not-matched: "+$targetRel) } catch {}
  continue
}

    switch ($mode) {
      'insert-before' {
        $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
      }
      'insert-before' {
  $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
}
'insert-after' {
  $new = $orig.Substring(0, $mt.Index + $mt.Length) + "`n" + $replace + $orig.Substring($mt.Index + $mt.Length)
}
'replace' {
        $new = $rx.Replace($orig, $replace, 1)
      }
      default {
  Write-Host "[SKIP] Unsupported MODE → $mode for $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("unsupported-mode: "+$mode+" for "+$targetRel) } catch {}
  continue
}
    }

    if ($ConfirmApply) {
      $bk = "$target.bak-" + (Get-Date -Format 'yyyyMMdd-HHmmss')
      Copy-Item -LiteralPath $target -Destination $bk -Force
      Write-AtomicUtf8 -Path $target -Content $new -Module 'patcher' -Action ('apply:'+ $mode)
      $applied += $targetRel
    } else {
      Write-Host "[PREVIEW] would patch → $targetRel ($mode)"
    }
  }

  if ($ConfirmApply) {
    LogRec 'INFO' 'apply' 'SUCCESS' ("patched: " + ($applied -join ', '))
  } else {
    LogRec 'INFO' 'preview' 'SUCCESS' ("preview-ok (no writes). blocks="+$matches.Count)
  }

  # ── Gate-3 Verify (경량) ───────────────────────────────────────────────────────
  if ($ConfirmApply) {
    # 핵심 타겟의 구문 일치 재검
    $core = Join-Path $RepoRoot 'scripts\apply_ui_patch.ps1'
    if (Test-Path $core) {
      $c = Get-Content -LiteralPath $core -Raw -Encoding UTF8
      if ($c -notmatch 'ensure valid tmp path .* atomic friendly') {
        Write-Host "[WARN] VERIFY: guard snippet not found in apply_ui_patch.ps1"; try { LogRec "WARN" "verify" "SKIPPED" "guard-missing apply_ui_patch.ps1" } catch {}
      }
    }
  }
}
catch {
  LogRec 'ERROR' 'apply' 'FAILURE' $_.Exception.Message 'LOGIC'
  exit 0
}
finally {
  Remove-Item -Force $LockFile -ErrorAction SilentlyContinue
}
.Exception.Message)" }
}
  Import-Module $ModPath -Force

  # 스모크: 같은 볼륨에 원자 쓰기 → 즉시 삭제
  $smoke = Join-Path $RepoRoot 'webui\public\_klc-smoke.txt'
  $smokeContent = "[klc-smoke] $(Get-Date -Format o)"
  Write-AtomicUtf8 -Path $smoke -Content $smokeContent -Module 'patcher' -Action 'smoke'
  if (Test-Path $smoke) { Remove-Item -LiteralPath $smoke -Force -ErrorAction SilentlyContinue }

  # ── Patch 파일 파싱 ───────────────────────────────────────────────────────────
  $PatchFile = Join-Path $RepoRoot '.kobong\patches.pending.txt'
  if (!(Test-Path $PatchFile)) {
  Write-Host "[SKIP] patches file not found → $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("patches-file-missing: "+$PatchFile) } catch {}
  return
}
  $patchText = Get-Content -LiteralPath $PatchFile -Raw -Encoding UTF8
  $global:patchHash = (Get-FileHash -Algorithm SHA256 -InputStream ([IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes($patchText)))).Hash

  $matches = [regex]::Matches($patchText, '(?ms)#\s*PATCH\s*START\s*(?<body>.*?)#\s*PATCH\s*END')
  if ($matches.Count -eq 0) {
  Write-Host "[SKIP] No PATCH blocks found in $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("no-patch-blocks: "+$PatchFile) } catch {}
  return
}

  $applied = @()
  foreach ($m in $matches) {
    $body = $m.Groups['body'].Value

    $targetRel = [regex]::Match($body, 'TARGET:\s*(?<v>.+)').Groups['v'].Value.Trim()
    $mode      = [regex]::Match($body, 'MODE:\s*(?<v>.+)').Groups['v'].Value.Trim().ToLowerInvariant()
    $find      = [regex]::Match($body, "FIND\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value
    $replace   = [regex]::Match($body, "REPLACE\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value

    if (-not $targetRel) { throw "PATCH missing TARGET" }
    if (-not $mode)      { throw "PATCH missing MODE" }
    if (-not $find)      { throw "PATCH missing FIND" }

    $target = Join-Path $RepoRoot $targetRel
    if (!(Test-Path $target)) {
  Write-Host "[SKIP] TARGET not found → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("target-not-found: "+$targetRel) } catch {}
  continue
}

    $orig = Get-Content -LiteralPath $target -Raw -Encoding UTF8
    $rxOpts = [Text.RegularExpressions.RegexOptions]::Multiline -bor [Text.RegularExpressions.RegexOptions]::Singleline
    $rx = [regex]::new($find, $rxOpts)
    $mt = $rx.Match($orig)
    if (-not $mt.Success) {
  Write-Host "[SKIP] FIND not matched → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("find-not-matched: "+$targetRel) } catch {}
  continue
}

    switch ($mode) {
      'insert-before' {
        $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
      }
      'insert-before' {
  $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
}
'insert-after' {
  $new = $orig.Substring(0, $mt.Index + $mt.Length) + "`n" + $replace + $orig.Substring($mt.Index + $mt.Length)
}
'replace' {
        $new = $rx.Replace($orig, $replace, 1)
      }
      default {
  Write-Host "[SKIP] Unsupported MODE → $mode for $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("unsupported-mode: "+$mode+" for "+$targetRel) } catch {}
  continue
}
    }

    if ($ConfirmApply) {
      $bk = "$target.bak-" + (Get-Date -Format 'yyyyMMdd-HHmmss')
      Copy-Item -LiteralPath $target -Destination $bk -Force
      Write-AtomicUtf8 -Path $target -Content $new -Module 'patcher' -Action ('apply:'+ $mode)
      $applied += $targetRel
    } else {
      Write-Host "[PREVIEW] would patch → $targetRel ($mode)"
    }
  }

  if ($ConfirmApply) {
    LogRec 'INFO' 'apply' 'SUCCESS' ("patched: " + ($applied -join ', '))
  } else {
    LogRec 'INFO' 'preview' 'SUCCESS' ("preview-ok (no writes). blocks="+$matches.Count)
  }

  # ── Gate-3 Verify (경량) ───────────────────────────────────────────────────────
  if ($ConfirmApply) {
    # 핵심 타겟의 구문 일치 재검
    $core = Join-Path $RepoRoot 'scripts\apply_ui_patch.ps1'
    if (Test-Path $core) {
      $c = Get-Content -LiteralPath $core -Raw -Encoding UTF8
      if ($c -notmatch 'ensure valid tmp path .* atomic friendly') {
        Write-Host "[WARN] VERIFY: guard snippet not found in apply_ui_patch.ps1"; try { LogRec "WARN" "verify" "SKIPPED" "guard-missing apply_ui_patch.ps1" } catch {}
      }
    }
  }
}
catch {
  LogRec 'ERROR' 'apply' 'FAILURE' $_.Exception.Message 'LOGIC'
  exit 0
}
finally {
  Remove-Item -Force $LockFile -ErrorAction SilentlyContinue
}
.Exception.Message)" }
  # 스모크: 같은 볼륨에 원자 쓰기 → 즉시 삭제
  $smoke = Join-Path $RepoRoot 'webui\public\_klc-smoke.txt'
  $smokeContent = "[klc-smoke] $(Get-Date -Format o)"
  Write-AtomicUtf8 -Path $smoke -Content $smokeContent -Module 'patcher' -Action 'smoke'
  if (Test-Path $smoke) { Remove-Item -LiteralPath $smoke -Force -ErrorAction SilentlyContinue }

  # ── Patch 파일 파싱 ───────────────────────────────────────────────────────────
  $PatchFile = Join-Path $RepoRoot '.kobong\patches.pending.txt'
  if (!(Test-Path $PatchFile)) {
  Write-Host "[SKIP] patches file not found → $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("patches-file-missing: "+$PatchFile) } catch {}
  return
}
  $patchText = Get-Content -LiteralPath $PatchFile -Raw -Encoding UTF8
  $global:patchHash = (Get-FileHash -Algorithm SHA256 -InputStream ([IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes($patchText)))).Hash

  $matches = [regex]::Matches($patchText, '(?ms)#\s*PATCH\s*START\s*(?<body>.*?)#\s*PATCH\s*END')
  if ($matches.Count -eq 0) {
  Write-Host "[SKIP] No PATCH blocks found in $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("no-patch-blocks: "+$PatchFile) } catch {}
  return
}

  $applied = @()
  foreach ($m in $matches) {
    $body = $m.Groups['body'].Value

    $targetRel = [regex]::Match($body, 'TARGET:\s*(?<v>.+)').Groups['v'].Value.Trim()
    $mode      = [regex]::Match($body, 'MODE:\s*(?<v>.+)').Groups['v'].Value.Trim().ToLowerInvariant()
    $find      = [regex]::Match($body, "FIND\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value
    $replace   = [regex]::Match($body, "REPLACE\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value

    if (-not $targetRel) { throw "PATCH missing TARGET" }
    if (-not $mode)      { throw "PATCH missing MODE" }
    if (-not $find)      { throw "PATCH missing FIND" }

    $target = Join-Path $RepoRoot $targetRel
    if (!(Test-Path $target)) {
  Write-Host "[SKIP] TARGET not found → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("target-not-found: "+$targetRel) } catch {}
  continue
}

    $orig = Get-Content -LiteralPath $target -Raw -Encoding UTF8
    $rxOpts = [Text.RegularExpressions.RegexOptions]::Multiline -bor [Text.RegularExpressions.RegexOptions]::Singleline
    $rx = [regex]::new($find, $rxOpts)
    $mt = $rx.Match($orig)
    if (-not $mt.Success) {
  Write-Host "[SKIP] FIND not matched → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("find-not-matched: "+$targetRel) } catch {}
  continue
}

    switch ($mode) {
      'insert-before' {
        $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
      }
      'insert-before' {
  $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
}
'insert-after' {
  $new = $orig.Substring(0, $mt.Index + $mt.Length) + "`n" + $replace + $orig.Substring($mt.Index + $mt.Length)
}
'replace' {
        $new = $rx.Replace($orig, $replace, 1)
      }
      default {
  Write-Host "[SKIP] Unsupported MODE → $mode for $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("unsupported-mode: "+$mode+" for "+$targetRel) } catch {}
  continue
}
    }

    if ($ConfirmApply) {
      $bk = "$target.bak-" + (Get-Date -Format 'yyyyMMdd-HHmmss')
      Copy-Item -LiteralPath $target -Destination $bk -Force
      Write-AtomicUtf8 -Path $target -Content $new -Module 'patcher' -Action ('apply:'+ $mode)
      $applied += $targetRel
    } else {
      Write-Host "[PREVIEW] would patch → $targetRel ($mode)"
    }
  }

  if ($ConfirmApply) {
    LogRec 'INFO' 'apply' 'SUCCESS' ("patched: " + ($applied -join ', '))
  } else {
    LogRec 'INFO' 'preview' 'SUCCESS' ("preview-ok (no writes). blocks="+$matches.Count)
  }

  # ── Gate-3 Verify (경량) ───────────────────────────────────────────────────────
  if ($ConfirmApply) {
    # 핵심 타겟의 구문 일치 재검
    $core = Join-Path $RepoRoot 'scripts\apply_ui_patch.ps1'
    if (Test-Path $core) {
      $c = Get-Content -LiteralPath $core -Raw -Encoding UTF8
      if ($c -notmatch 'ensure valid tmp path .* atomic friendly') {
        Write-Host "[WARN] VERIFY: guard snippet not found in apply_ui_patch.ps1"; try { LogRec "WARN" "verify" "SKIPPED" "guard-missing apply_ui_patch.ps1" } catch {}
      }
    }
  }
}
catch {
  LogRec 'ERROR' 'apply' 'FAILURE' $_.Exception.Message 'LOGIC'
  exit 0
}
finally {
  Remove-Item -Force $LockFile -ErrorAction SilentlyContinue
}
.Exception.Message) }

# ── Gate-0: Repo / Lock ─────────────────────────────────────────────────────────
function Get-RepoRoot {
  try {
    $p = (git rev-parse --show-toplevel 2>$null)
    if ($p) { return (Resolve-Path $p).Path }
  } catch {}
  if ($Root) { return (Resolve-Path $Root).Path }
  return (Get-Location).Path
}
$RepoRoot = Get-RepoRoot
$LockFile = Join-Path $RepoRoot '.gpt5.lock'
if (Test-Path $LockFile) { Write-Error 'CONFLICT: .gpt5.lock exists.'; exit 11 }
"locked $(Get-Date -Format o)" | Out-File $LockFile -Encoding utf8 -NoNewline

$sw=[Diagnostics.Stopwatch]::StartNew()
$trace=[guid]::NewGuid().ToString()
$logPath = Join-Path $RepoRoot 'logs/apply-log.jsonl'
New-Item -ItemType Directory -Force -Path (Split-Path $logPath) | Out-Null

function LogRec([string]$level,[string]$action,[string]$outcome,[string]$msg,[string]$err='') {
  $rec = @{
    timestamp=(Get-Date).ToString('o'); level=$level; traceId=$trace; module='patcher';
    action=$action; inputHash=((Get-Variable -Name patchHash -Scope Global -ValueOnly -ErrorAction SilentlyContinue) ?? ""); outcome=$outcome;
    durationMs=$sw.ElapsedMilliseconds; errorCode=$err; message=$msg
  } | ConvertTo-Json -Compress
  Add-Content -Path $logPath -Value $rec
}

try {
  # ── Preflight: 모듈 로드 & 스모크 ─────────────────────────────────────────────
  $ModPath = Join-Path $RepoRoot 'scripts\lib\kobong-fileio.psm1'
  if (!(Test-Path $ModPath)) { throw "Missing module: $ModPath" }
try { Import-Module $ModPath -Force } catch { Write-Host "[WARN] Import-Module failed → $ModPath: $(# APPLY IN SHELL
#requires -Version 7.0
param([switch]$ConfirmApply,[string]$Root)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

# ── Gate-0: Repo / Lock ─────────────────────────────────────────────────────────
function Get-RepoRoot {
  try {
    $p = (git rev-parse --show-toplevel 2>$null)
    if ($p) { return (Resolve-Path $p).Path }
  } catch {}
  if ($Root) { return (Resolve-Path $Root).Path }
  return (Get-Location).Path
}
$RepoRoot = Get-RepoRoot
$LockFile = Join-Path $RepoRoot '.gpt5.lock'
if (Test-Path $LockFile) { Write-Error 'CONFLICT: .gpt5.lock exists.'; exit 11 }
"locked $(Get-Date -Format o)" | Out-File $LockFile -Encoding utf8 -NoNewline

$sw=[Diagnostics.Stopwatch]::StartNew()
$trace=[guid]::NewGuid().ToString()
$logPath = Join-Path $RepoRoot 'logs/apply-log.jsonl'
New-Item -ItemType Directory -Force -Path (Split-Path $logPath) | Out-Null

function LogRec([string]$level,[string]$action,[string]$outcome,[string]$msg,[string]$err='') {
  $rec = @{
    timestamp=(Get-Date).ToString('o'); level=$level; traceId=$trace; module='patcher';
    action=$action; inputHash=((Get-Variable -Name patchHash -Scope Global -ValueOnly -ErrorAction SilentlyContinue) ?? ""); outcome=$outcome;
    durationMs=$sw.ElapsedMilliseconds; errorCode=$err; message=$msg
  } | ConvertTo-Json -Compress
  Add-Content -Path $logPath -Value $rec
}

try {
  # ── Preflight: 모듈 로드 & 스모크 ─────────────────────────────────────────────
  $ModPath = Join-Path $RepoRoot 'scripts\lib\kobong-fileio.psm1'
  if (!(Test-Path $ModPath)) { throw "Missing module: $ModPath" }
  Import-Module $ModPath -Force

  # 스모크: 같은 볼륨에 원자 쓰기 → 즉시 삭제
  $smoke = Join-Path $RepoRoot 'webui\public\_klc-smoke.txt'
  $smokeContent = "[klc-smoke] $(Get-Date -Format o)"
  Write-AtomicUtf8 -Path $smoke -Content $smokeContent -Module 'patcher' -Action 'smoke'
  if (Test-Path $smoke) { Remove-Item -LiteralPath $smoke -Force -ErrorAction SilentlyContinue }

  # ── Patch 파일 파싱 ───────────────────────────────────────────────────────────
  $PatchFile = Join-Path $RepoRoot '.kobong\patches.pending.txt'
  if (!(Test-Path $PatchFile)) {
  Write-Host "[SKIP] patches file not found → $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("patches-file-missing: "+$PatchFile) } catch {}
  return
}
  $patchText = Get-Content -LiteralPath $PatchFile -Raw -Encoding UTF8
  $global:patchHash = (Get-FileHash -Algorithm SHA256 -InputStream ([IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes($patchText)))).Hash

  $matches = [regex]::Matches($patchText, '(?ms)#\s*PATCH\s*START\s*(?<body>.*?)#\s*PATCH\s*END')
  if ($matches.Count -eq 0) {
  Write-Host "[SKIP] No PATCH blocks found in $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("no-patch-blocks: "+$PatchFile) } catch {}
  return
}

  $applied = @()
  foreach ($m in $matches) {
    $body = $m.Groups['body'].Value

    $targetRel = [regex]::Match($body, 'TARGET:\s*(?<v>.+)').Groups['v'].Value.Trim()
    $mode      = [regex]::Match($body, 'MODE:\s*(?<v>.+)').Groups['v'].Value.Trim().ToLowerInvariant()
    $find      = [regex]::Match($body, "FIND\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value
    $replace   = [regex]::Match($body, "REPLACE\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value

    if (-not $targetRel) { throw "PATCH missing TARGET" }
    if (-not $mode)      { throw "PATCH missing MODE" }
    if (-not $find)      { throw "PATCH missing FIND" }

    $target = Join-Path $RepoRoot $targetRel
    if (!(Test-Path $target)) {
  Write-Host "[SKIP] TARGET not found → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("target-not-found: "+$targetRel) } catch {}
  continue
}

    $orig = Get-Content -LiteralPath $target -Raw -Encoding UTF8
    $rxOpts = [Text.RegularExpressions.RegexOptions]::Multiline -bor [Text.RegularExpressions.RegexOptions]::Singleline
    $rx = [regex]::new($find, $rxOpts)
    $mt = $rx.Match($orig)
    if (-not $mt.Success) {
  Write-Host "[SKIP] FIND not matched → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("find-not-matched: "+$targetRel) } catch {}
  continue
}

    switch ($mode) {
      'insert-before' {
        $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
      }
      'insert-before' {
  $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
}
'insert-after' {
  $new = $orig.Substring(0, $mt.Index + $mt.Length) + "`n" + $replace + $orig.Substring($mt.Index + $mt.Length)
}
'replace' {
        $new = $rx.Replace($orig, $replace, 1)
      }
      default {
  Write-Host "[SKIP] Unsupported MODE → $mode for $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("unsupported-mode: "+$mode+" for "+$targetRel) } catch {}
  continue
}
    }

    if ($ConfirmApply) {
      $bk = "$target.bak-" + (Get-Date -Format 'yyyyMMdd-HHmmss')
      Copy-Item -LiteralPath $target -Destination $bk -Force
      Write-AtomicUtf8 -Path $target -Content $new -Module 'patcher' -Action ('apply:'+ $mode)
      $applied += $targetRel
    } else {
      Write-Host "[PREVIEW] would patch → $targetRel ($mode)"
    }
  }

  if ($ConfirmApply) {
    LogRec 'INFO' 'apply' 'SUCCESS' ("patched: " + ($applied -join ', '))
  } else {
    LogRec 'INFO' 'preview' 'SUCCESS' ("preview-ok (no writes). blocks="+$matches.Count)
  }

  # ── Gate-3 Verify (경량) ───────────────────────────────────────────────────────
  if ($ConfirmApply) {
    # 핵심 타겟의 구문 일치 재검
    $core = Join-Path $RepoRoot 'scripts\apply_ui_patch.ps1'
    if (Test-Path $core) {
      $c = Get-Content -LiteralPath $core -Raw -Encoding UTF8
      if ($c -notmatch 'ensure valid tmp path .* atomic friendly') {
        Write-Host "[WARN] VERIFY: guard snippet not found in apply_ui_patch.ps1"; try { LogRec "WARN" "verify" "SKIPPED" "guard-missing apply_ui_patch.ps1" } catch {}
      }
    }
  }
}
catch {
  LogRec 'ERROR' 'apply' 'FAILURE' $_.Exception.Message 'LOGIC'
  exit 0
}
finally {
  Remove-Item -Force $LockFile -ErrorAction SilentlyContinue
}
.Exception.Message)" }
  # 스모크: 같은 볼륨에 원자 쓰기 → 즉시 삭제
  $smoke = Join-Path $RepoRoot 'webui\public\_klc-smoke.txt'
  $smokeContent = "[klc-smoke] $(Get-Date -Format o)"
  Write-AtomicUtf8 -Path $smoke -Content $smokeContent -Module 'patcher' -Action 'smoke'
  if (Test-Path $smoke) { Remove-Item -LiteralPath $smoke -Force -ErrorAction SilentlyContinue }

  # ── Patch 파일 파싱 ───────────────────────────────────────────────────────────
  $PatchFile = Join-Path $RepoRoot '.kobong\patches.pending.txt'
  if (!(Test-Path $PatchFile)) {
  Write-Host "[SKIP] patches file not found → $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("patches-file-missing: "+$PatchFile) } catch {}
  return
}
  $patchText = Get-Content -LiteralPath $PatchFile -Raw -Encoding UTF8
  $global:patchHash = (Get-FileHash -Algorithm SHA256 -InputStream ([IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes($patchText)))).Hash

  $matches = [regex]::Matches($patchText, '(?ms)#\s*PATCH\s*START\s*(?<body>.*?)#\s*PATCH\s*END')
  if ($matches.Count -eq 0) {
  Write-Host "[SKIP] No PATCH blocks found in $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("no-patch-blocks: "+$PatchFile) } catch {}
  return
}

  $applied = @()
  foreach ($m in $matches) {
    $body = $m.Groups['body'].Value

    $targetRel = [regex]::Match($body, 'TARGET:\s*(?<v>.+)').Groups['v'].Value.Trim()
    $mode      = [regex]::Match($body, 'MODE:\s*(?<v>.+)').Groups['v'].Value.Trim().ToLowerInvariant()
    $find      = [regex]::Match($body, "FIND\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value
    $replace   = [regex]::Match($body, "REPLACE\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value

    if (-not $targetRel) { throw "PATCH missing TARGET" }
    if (-not $mode)      { throw "PATCH missing MODE" }
    if (-not $find)      { throw "PATCH missing FIND" }

    $target = Join-Path $RepoRoot $targetRel
    if (!(Test-Path $target)) {
  Write-Host "[SKIP] TARGET not found → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("target-not-found: "+$targetRel) } catch {}
  continue
}

    $orig = Get-Content -LiteralPath $target -Raw -Encoding UTF8
    $rxOpts = [Text.RegularExpressions.RegexOptions]::Multiline -bor [Text.RegularExpressions.RegexOptions]::Singleline
    $rx = [regex]::new($find, $rxOpts)
    $mt = $rx.Match($orig)
    if (-not $mt.Success) {
  Write-Host "[SKIP] FIND not matched → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("find-not-matched: "+$targetRel) } catch {}
  continue
}

    switch ($mode) {
      'insert-before' {
        $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
      }
      'insert-before' {
  $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
}
'insert-after' {
  $new = $orig.Substring(0, $mt.Index + $mt.Length) + "`n" + $replace + $orig.Substring($mt.Index + $mt.Length)
}
'replace' {
        $new = $rx.Replace($orig, $replace, 1)
      }
      default {
  Write-Host "[SKIP] Unsupported MODE → $mode for $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("unsupported-mode: "+$mode+" for "+$targetRel) } catch {}
  continue
}
    }

    if ($ConfirmApply) {
      $bk = "$target.bak-" + (Get-Date -Format 'yyyyMMdd-HHmmss')
      Copy-Item -LiteralPath $target -Destination $bk -Force
      Write-AtomicUtf8 -Path $target -Content $new -Module 'patcher' -Action ('apply:'+ $mode)
      $applied += $targetRel
    } else {
      Write-Host "[PREVIEW] would patch → $targetRel ($mode)"
    }
  }

  if ($ConfirmApply) {
    LogRec 'INFO' 'apply' 'SUCCESS' ("patched: " + ($applied -join ', '))
  } else {
    LogRec 'INFO' 'preview' 'SUCCESS' ("preview-ok (no writes). blocks="+$matches.Count)
  }

  # ── Gate-3 Verify (경량) ───────────────────────────────────────────────────────
  if ($ConfirmApply) {
    # 핵심 타겟의 구문 일치 재검
    $core = Join-Path $RepoRoot 'scripts\apply_ui_patch.ps1'
    if (Test-Path $core) {
      $c = Get-Content -LiteralPath $core -Raw -Encoding UTF8
      if ($c -notmatch 'ensure valid tmp path .* atomic friendly') {
        Write-Host "[WARN] VERIFY: guard snippet not found in apply_ui_patch.ps1"; try { LogRec "WARN" "verify" "SKIPPED" "guard-missing apply_ui_patch.ps1" } catch {}
      }
    }
  }
}
catch {
  LogRec 'ERROR' 'apply' 'FAILURE' $_.Exception.Message 'LOGIC'
  exit 0
}
finally {
  Remove-Item -Force $LockFile -ErrorAction SilentlyContinue
}
.Exception.Message)" }
}
try { Import-Module $ModPath -Force } catch { Write-Host "[WARN] Import-Module failed → $ModPath: $(# APPLY IN SHELL
#requires -Version 7.0
param([switch]$ConfirmApply,[string]$Root)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

# ── Gate-0: Repo / Lock ─────────────────────────────────────────────────────────
function Get-RepoRoot {
  try {
    $p = (git rev-parse --show-toplevel 2>$null)
    if ($p) { return (Resolve-Path $p).Path }
  } catch {}
  if ($Root) { return (Resolve-Path $Root).Path }
  return (Get-Location).Path
}
$RepoRoot = Get-RepoRoot
$LockFile = Join-Path $RepoRoot '.gpt5.lock'
if (Test-Path $LockFile) { Write-Error 'CONFLICT: .gpt5.lock exists.'; exit 11 }
"locked $(Get-Date -Format o)" | Out-File $LockFile -Encoding utf8 -NoNewline

$sw=[Diagnostics.Stopwatch]::StartNew()
$trace=[guid]::NewGuid().ToString()
$logPath = Join-Path $RepoRoot 'logs/apply-log.jsonl'
New-Item -ItemType Directory -Force -Path (Split-Path $logPath) | Out-Null

function LogRec([string]$level,[string]$action,[string]$outcome,[string]$msg,[string]$err='') {
  $rec = @{
    timestamp=(Get-Date).ToString('o'); level=$level; traceId=$trace; module='patcher';
    action=$action; inputHash=((Get-Variable -Name patchHash -Scope Global -ValueOnly -ErrorAction SilentlyContinue) ?? ""); outcome=$outcome;
    durationMs=$sw.ElapsedMilliseconds; errorCode=$err; message=$msg
  } | ConvertTo-Json -Compress
  Add-Content -Path $logPath -Value $rec
}

try {
  # ── Preflight: 모듈 로드 & 스모크 ─────────────────────────────────────────────
  $ModPath = Join-Path $RepoRoot 'scripts\lib\kobong-fileio.psm1'
  if (!(Test-Path $ModPath)) {
  Write-Host "[WARN] Missing module → $ModPath (continuing)"
  try { LogRec "WARN" "apply" "SKIPPED" ("missing-module: "+$ModPath) } catch {}
} else {
  try { Import-Module $ModPath -Force } catch { Write-Host "[WARN] Import-Module failed → $ModPath: $(# APPLY IN SHELL
#requires -Version 7.0
param([switch]$ConfirmApply,[string]$Root)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

# ── Gate-0: Repo / Lock ─────────────────────────────────────────────────────────
function Get-RepoRoot {
  try {
    $p = (git rev-parse --show-toplevel 2>$null)
    if ($p) { return (Resolve-Path $p).Path }
  } catch {}
  if ($Root) { return (Resolve-Path $Root).Path }
  return (Get-Location).Path
}
$RepoRoot = Get-RepoRoot
$LockFile = Join-Path $RepoRoot '.gpt5.lock'
if (Test-Path $LockFile) { Write-Error 'CONFLICT: .gpt5.lock exists.'; exit 11 }
"locked $(Get-Date -Format o)" | Out-File $LockFile -Encoding utf8 -NoNewline

$sw=[Diagnostics.Stopwatch]::StartNew()
$trace=[guid]::NewGuid().ToString()
$logPath = Join-Path $RepoRoot 'logs/apply-log.jsonl'
New-Item -ItemType Directory -Force -Path (Split-Path $logPath) | Out-Null

function LogRec([string]$level,[string]$action,[string]$outcome,[string]$msg,[string]$err='') {
  $rec = @{
    timestamp=(Get-Date).ToString('o'); level=$level; traceId=$trace; module='patcher';
    action=$action; inputHash=((Get-Variable -Name patchHash -Scope Global -ValueOnly -ErrorAction SilentlyContinue) ?? ""); outcome=$outcome;
    durationMs=$sw.ElapsedMilliseconds; errorCode=$err; message=$msg
  } | ConvertTo-Json -Compress
  Add-Content -Path $logPath -Value $rec
}

try {
  # ── Preflight: 모듈 로드 & 스모크 ─────────────────────────────────────────────
  $ModPath = Join-Path $RepoRoot 'scripts\lib\kobong-fileio.psm1'
  if (!(Test-Path $ModPath)) { throw "Missing module: $ModPath" }
try { Import-Module $ModPath -Force } catch { Write-Host "[WARN] Import-Module failed → $ModPath: $(# APPLY IN SHELL
#requires -Version 7.0
param([switch]$ConfirmApply,[string]$Root)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

# ── Gate-0: Repo / Lock ─────────────────────────────────────────────────────────
function Get-RepoRoot {
  try {
    $p = (git rev-parse --show-toplevel 2>$null)
    if ($p) { return (Resolve-Path $p).Path }
  } catch {}
  if ($Root) { return (Resolve-Path $Root).Path }
  return (Get-Location).Path
}
$RepoRoot = Get-RepoRoot
$LockFile = Join-Path $RepoRoot '.gpt5.lock'
if (Test-Path $LockFile) { Write-Error 'CONFLICT: .gpt5.lock exists.'; exit 11 }
"locked $(Get-Date -Format o)" | Out-File $LockFile -Encoding utf8 -NoNewline

$sw=[Diagnostics.Stopwatch]::StartNew()
$trace=[guid]::NewGuid().ToString()
$logPath = Join-Path $RepoRoot 'logs/apply-log.jsonl'
New-Item -ItemType Directory -Force -Path (Split-Path $logPath) | Out-Null

function LogRec([string]$level,[string]$action,[string]$outcome,[string]$msg,[string]$err='') {
  $rec = @{
    timestamp=(Get-Date).ToString('o'); level=$level; traceId=$trace; module='patcher';
    action=$action; inputHash=((Get-Variable -Name patchHash -Scope Global -ValueOnly -ErrorAction SilentlyContinue) ?? ""); outcome=$outcome;
    durationMs=$sw.ElapsedMilliseconds; errorCode=$err; message=$msg
  } | ConvertTo-Json -Compress
  Add-Content -Path $logPath -Value $rec
}

try {
  # ── Preflight: 모듈 로드 & 스모크 ─────────────────────────────────────────────
  $ModPath = Join-Path $RepoRoot 'scripts\lib\kobong-fileio.psm1'
  if (!(Test-Path $ModPath)) { throw "Missing module: $ModPath" }
  Import-Module $ModPath -Force

  # 스모크: 같은 볼륨에 원자 쓰기 → 즉시 삭제
  $smoke = Join-Path $RepoRoot 'webui\public\_klc-smoke.txt'
  $smokeContent = "[klc-smoke] $(Get-Date -Format o)"
  Write-AtomicUtf8 -Path $smoke -Content $smokeContent -Module 'patcher' -Action 'smoke'
  if (Test-Path $smoke) { Remove-Item -LiteralPath $smoke -Force -ErrorAction SilentlyContinue }

  # ── Patch 파일 파싱 ───────────────────────────────────────────────────────────
  $PatchFile = Join-Path $RepoRoot '.kobong\patches.pending.txt'
  if (!(Test-Path $PatchFile)) {
  Write-Host "[SKIP] patches file not found → $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("patches-file-missing: "+$PatchFile) } catch {}
  return
}
  $patchText = Get-Content -LiteralPath $PatchFile -Raw -Encoding UTF8
  $global:patchHash = (Get-FileHash -Algorithm SHA256 -InputStream ([IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes($patchText)))).Hash

  $matches = [regex]::Matches($patchText, '(?ms)#\s*PATCH\s*START\s*(?<body>.*?)#\s*PATCH\s*END')
  if ($matches.Count -eq 0) {
  Write-Host "[SKIP] No PATCH blocks found in $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("no-patch-blocks: "+$PatchFile) } catch {}
  return
}

  $applied = @()
  foreach ($m in $matches) {
    $body = $m.Groups['body'].Value

    $targetRel = [regex]::Match($body, 'TARGET:\s*(?<v>.+)').Groups['v'].Value.Trim()
    $mode      = [regex]::Match($body, 'MODE:\s*(?<v>.+)').Groups['v'].Value.Trim().ToLowerInvariant()
    $find      = [regex]::Match($body, "FIND\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value
    $replace   = [regex]::Match($body, "REPLACE\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value

    if (-not $targetRel) { throw "PATCH missing TARGET" }
    if (-not $mode)      { throw "PATCH missing MODE" }
    if (-not $find)      { throw "PATCH missing FIND" }

    $target = Join-Path $RepoRoot $targetRel
    if (!(Test-Path $target)) {
  Write-Host "[SKIP] TARGET not found → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("target-not-found: "+$targetRel) } catch {}
  continue
}

    $orig = Get-Content -LiteralPath $target -Raw -Encoding UTF8
    $rxOpts = [Text.RegularExpressions.RegexOptions]::Multiline -bor [Text.RegularExpressions.RegexOptions]::Singleline
    $rx = [regex]::new($find, $rxOpts)
    $mt = $rx.Match($orig)
    if (-not $mt.Success) {
  Write-Host "[SKIP] FIND not matched → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("find-not-matched: "+$targetRel) } catch {}
  continue
}

    switch ($mode) {
      'insert-before' {
        $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
      }
      'insert-before' {
  $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
}
'insert-after' {
  $new = $orig.Substring(0, $mt.Index + $mt.Length) + "`n" + $replace + $orig.Substring($mt.Index + $mt.Length)
}
'replace' {
        $new = $rx.Replace($orig, $replace, 1)
      }
      default {
  Write-Host "[SKIP] Unsupported MODE → $mode for $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("unsupported-mode: "+$mode+" for "+$targetRel) } catch {}
  continue
}
    }

    if ($ConfirmApply) {
      $bk = "$target.bak-" + (Get-Date -Format 'yyyyMMdd-HHmmss')
      Copy-Item -LiteralPath $target -Destination $bk -Force
      Write-AtomicUtf8 -Path $target -Content $new -Module 'patcher' -Action ('apply:'+ $mode)
      $applied += $targetRel
    } else {
      Write-Host "[PREVIEW] would patch → $targetRel ($mode)"
    }
  }

  if ($ConfirmApply) {
    LogRec 'INFO' 'apply' 'SUCCESS' ("patched: " + ($applied -join ', '))
  } else {
    LogRec 'INFO' 'preview' 'SUCCESS' ("preview-ok (no writes). blocks="+$matches.Count)
  }

  # ── Gate-3 Verify (경량) ───────────────────────────────────────────────────────
  if ($ConfirmApply) {
    # 핵심 타겟의 구문 일치 재검
    $core = Join-Path $RepoRoot 'scripts\apply_ui_patch.ps1'
    if (Test-Path $core) {
      $c = Get-Content -LiteralPath $core -Raw -Encoding UTF8
      if ($c -notmatch 'ensure valid tmp path .* atomic friendly') {
        Write-Host "[WARN] VERIFY: guard snippet not found in apply_ui_patch.ps1"; try { LogRec "WARN" "verify" "SKIPPED" "guard-missing apply_ui_patch.ps1" } catch {}
      }
    }
  }
}
catch {
  LogRec 'ERROR' 'apply' 'FAILURE' $_.Exception.Message 'LOGIC'
  exit 0
}
finally {
  Remove-Item -Force $LockFile -ErrorAction SilentlyContinue
}
.Exception.Message)" }
  # 스모크: 같은 볼륨에 원자 쓰기 → 즉시 삭제
  $smoke = Join-Path $RepoRoot 'webui\public\_klc-smoke.txt'
  $smokeContent = "[klc-smoke] $(Get-Date -Format o)"
  Write-AtomicUtf8 -Path $smoke -Content $smokeContent -Module 'patcher' -Action 'smoke'
  if (Test-Path $smoke) { Remove-Item -LiteralPath $smoke -Force -ErrorAction SilentlyContinue }

  # ── Patch 파일 파싱 ───────────────────────────────────────────────────────────
  $PatchFile = Join-Path $RepoRoot '.kobong\patches.pending.txt'
  if (!(Test-Path $PatchFile)) {
  Write-Host "[SKIP] patches file not found → $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("patches-file-missing: "+$PatchFile) } catch {}
  return
}
  $patchText = Get-Content -LiteralPath $PatchFile -Raw -Encoding UTF8
  $global:patchHash = (Get-FileHash -Algorithm SHA256 -InputStream ([IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes($patchText)))).Hash

  $matches = [regex]::Matches($patchText, '(?ms)#\s*PATCH\s*START\s*(?<body>.*?)#\s*PATCH\s*END')
  if ($matches.Count -eq 0) {
  Write-Host "[SKIP] No PATCH blocks found in $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("no-patch-blocks: "+$PatchFile) } catch {}
  return
}

  $applied = @()
  foreach ($m in $matches) {
    $body = $m.Groups['body'].Value

    $targetRel = [regex]::Match($body, 'TARGET:\s*(?<v>.+)').Groups['v'].Value.Trim()
    $mode      = [regex]::Match($body, 'MODE:\s*(?<v>.+)').Groups['v'].Value.Trim().ToLowerInvariant()
    $find      = [regex]::Match($body, "FIND\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value
    $replace   = [regex]::Match($body, "REPLACE\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value

    if (-not $targetRel) { throw "PATCH missing TARGET" }
    if (-not $mode)      { throw "PATCH missing MODE" }
    if (-not $find)      { throw "PATCH missing FIND" }

    $target = Join-Path $RepoRoot $targetRel
    if (!(Test-Path $target)) {
  Write-Host "[SKIP] TARGET not found → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("target-not-found: "+$targetRel) } catch {}
  continue
}

    $orig = Get-Content -LiteralPath $target -Raw -Encoding UTF8
    $rxOpts = [Text.RegularExpressions.RegexOptions]::Multiline -bor [Text.RegularExpressions.RegexOptions]::Singleline
    $rx = [regex]::new($find, $rxOpts)
    $mt = $rx.Match($orig)
    if (-not $mt.Success) {
  Write-Host "[SKIP] FIND not matched → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("find-not-matched: "+$targetRel) } catch {}
  continue
}

    switch ($mode) {
      'insert-before' {
        $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
      }
      'insert-before' {
  $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
}
'insert-after' {
  $new = $orig.Substring(0, $mt.Index + $mt.Length) + "`n" + $replace + $orig.Substring($mt.Index + $mt.Length)
}
'replace' {
        $new = $rx.Replace($orig, $replace, 1)
      }
      default {
  Write-Host "[SKIP] Unsupported MODE → $mode for $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("unsupported-mode: "+$mode+" for "+$targetRel) } catch {}
  continue
}
    }

    if ($ConfirmApply) {
      $bk = "$target.bak-" + (Get-Date -Format 'yyyyMMdd-HHmmss')
      Copy-Item -LiteralPath $target -Destination $bk -Force
      Write-AtomicUtf8 -Path $target -Content $new -Module 'patcher' -Action ('apply:'+ $mode)
      $applied += $targetRel
    } else {
      Write-Host "[PREVIEW] would patch → $targetRel ($mode)"
    }
  }

  if ($ConfirmApply) {
    LogRec 'INFO' 'apply' 'SUCCESS' ("patched: " + ($applied -join ', '))
  } else {
    LogRec 'INFO' 'preview' 'SUCCESS' ("preview-ok (no writes). blocks="+$matches.Count)
  }

  # ── Gate-3 Verify (경량) ───────────────────────────────────────────────────────
  if ($ConfirmApply) {
    # 핵심 타겟의 구문 일치 재검
    $core = Join-Path $RepoRoot 'scripts\apply_ui_patch.ps1'
    if (Test-Path $core) {
      $c = Get-Content -LiteralPath $core -Raw -Encoding UTF8
      if ($c -notmatch 'ensure valid tmp path .* atomic friendly') {
        Write-Host "[WARN] VERIFY: guard snippet not found in apply_ui_patch.ps1"; try { LogRec "WARN" "verify" "SKIPPED" "guard-missing apply_ui_patch.ps1" } catch {}
      }
    }
  }
}
catch {
  LogRec 'ERROR' 'apply' 'FAILURE' $_.Exception.Message 'LOGIC'
  exit 0
}
finally {
  Remove-Item -Force $LockFile -ErrorAction SilentlyContinue
}
.Exception.Message)" }
}
  Import-Module $ModPath -Force

  # 스모크: 같은 볼륨에 원자 쓰기 → 즉시 삭제
  $smoke = Join-Path $RepoRoot 'webui\public\_klc-smoke.txt'
  $smokeContent = "[klc-smoke] $(Get-Date -Format o)"
  Write-AtomicUtf8 -Path $smoke -Content $smokeContent -Module 'patcher' -Action 'smoke'
  if (Test-Path $smoke) { Remove-Item -LiteralPath $smoke -Force -ErrorAction SilentlyContinue }

  # ── Patch 파일 파싱 ───────────────────────────────────────────────────────────
  $PatchFile = Join-Path $RepoRoot '.kobong\patches.pending.txt'
  if (!(Test-Path $PatchFile)) {
  Write-Host "[SKIP] patches file not found → $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("patches-file-missing: "+$PatchFile) } catch {}
  return
}
  $patchText = Get-Content -LiteralPath $PatchFile -Raw -Encoding UTF8
  $global:patchHash = (Get-FileHash -Algorithm SHA256 -InputStream ([IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes($patchText)))).Hash

  $matches = [regex]::Matches($patchText, '(?ms)#\s*PATCH\s*START\s*(?<body>.*?)#\s*PATCH\s*END')
  if ($matches.Count -eq 0) {
  Write-Host "[SKIP] No PATCH blocks found in $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("no-patch-blocks: "+$PatchFile) } catch {}
  return
}

  $applied = @()
  foreach ($m in $matches) {
    $body = $m.Groups['body'].Value

    $targetRel = [regex]::Match($body, 'TARGET:\s*(?<v>.+)').Groups['v'].Value.Trim()
    $mode      = [regex]::Match($body, 'MODE:\s*(?<v>.+)').Groups['v'].Value.Trim().ToLowerInvariant()
    $find      = [regex]::Match($body, "FIND\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value
    $replace   = [regex]::Match($body, "REPLACE\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value

    if (-not $targetRel) { throw "PATCH missing TARGET" }
    if (-not $mode)      { throw "PATCH missing MODE" }
    if (-not $find)      { throw "PATCH missing FIND" }

    $target = Join-Path $RepoRoot $targetRel
    if (!(Test-Path $target)) {
  Write-Host "[SKIP] TARGET not found → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("target-not-found: "+$targetRel) } catch {}
  continue
}

    $orig = Get-Content -LiteralPath $target -Raw -Encoding UTF8
    $rxOpts = [Text.RegularExpressions.RegexOptions]::Multiline -bor [Text.RegularExpressions.RegexOptions]::Singleline
    $rx = [regex]::new($find, $rxOpts)
    $mt = $rx.Match($orig)
    if (-not $mt.Success) {
  Write-Host "[SKIP] FIND not matched → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("find-not-matched: "+$targetRel) } catch {}
  continue
}

    switch ($mode) {
      'insert-before' {
        $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
      }
      'insert-before' {
  $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
}
'insert-after' {
  $new = $orig.Substring(0, $mt.Index + $mt.Length) + "`n" + $replace + $orig.Substring($mt.Index + $mt.Length)
}
'replace' {
        $new = $rx.Replace($orig, $replace, 1)
      }
      default {
  Write-Host "[SKIP] Unsupported MODE → $mode for $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("unsupported-mode: "+$mode+" for "+$targetRel) } catch {}
  continue
}
    }

    if ($ConfirmApply) {
      $bk = "$target.bak-" + (Get-Date -Format 'yyyyMMdd-HHmmss')
      Copy-Item -LiteralPath $target -Destination $bk -Force
      Write-AtomicUtf8 -Path $target -Content $new -Module 'patcher' -Action ('apply:'+ $mode)
      $applied += $targetRel
    } else {
      Write-Host "[PREVIEW] would patch → $targetRel ($mode)"
    }
  }

  if ($ConfirmApply) {
    LogRec 'INFO' 'apply' 'SUCCESS' ("patched: " + ($applied -join ', '))
  } else {
    LogRec 'INFO' 'preview' 'SUCCESS' ("preview-ok (no writes). blocks="+$matches.Count)
  }

  # ── Gate-3 Verify (경량) ───────────────────────────────────────────────────────
  if ($ConfirmApply) {
    # 핵심 타겟의 구문 일치 재검
    $core = Join-Path $RepoRoot 'scripts\apply_ui_patch.ps1'
    if (Test-Path $core) {
      $c = Get-Content -LiteralPath $core -Raw -Encoding UTF8
      if ($c -notmatch 'ensure valid tmp path .* atomic friendly') {
        Write-Host "[WARN] VERIFY: guard snippet not found in apply_ui_patch.ps1"; try { LogRec "WARN" "verify" "SKIPPED" "guard-missing apply_ui_patch.ps1" } catch {}
      }
    }
  }
}
catch {
  LogRec 'ERROR' 'apply' 'FAILURE' $_.Exception.Message 'LOGIC'
  exit 0
}
finally {
  Remove-Item -Force $LockFile -ErrorAction SilentlyContinue
}
.Exception.Message)" }
  # 스모크: 같은 볼륨에 원자 쓰기 → 즉시 삭제
  $smoke = Join-Path $RepoRoot 'webui\public\_klc-smoke.txt'
  $smokeContent = "[klc-smoke] $(Get-Date -Format o)"
  Write-AtomicUtf8 -Path $smoke -Content $smokeContent -Module 'patcher' -Action 'smoke'
  if (Test-Path $smoke) { Remove-Item -LiteralPath $smoke -Force -ErrorAction SilentlyContinue }

  # ── Patch 파일 파싱 ───────────────────────────────────────────────────────────
  $PatchFile = Join-Path $RepoRoot '.kobong\patches.pending.txt'
  if (!(Test-Path $PatchFile)) {
  Write-Host "[SKIP] patches file not found → $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("patches-file-missing: "+$PatchFile) } catch {}
  return
}
  $patchText = Get-Content -LiteralPath $PatchFile -Raw -Encoding UTF8
  $global:patchHash = (Get-FileHash -Algorithm SHA256 -InputStream ([IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes($patchText)))).Hash

  $matches = [regex]::Matches($patchText, '(?ms)#\s*PATCH\s*START\s*(?<body>.*?)#\s*PATCH\s*END')
  if ($matches.Count -eq 0) {
  Write-Host "[SKIP] No PATCH blocks found in $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("no-patch-blocks: "+$PatchFile) } catch {}
  return
}

  $applied = @()
  foreach ($m in $matches) {
    $body = $m.Groups['body'].Value

    $targetRel = [regex]::Match($body, 'TARGET:\s*(?<v>.+)').Groups['v'].Value.Trim()
    $mode      = [regex]::Match($body, 'MODE:\s*(?<v>.+)').Groups['v'].Value.Trim().ToLowerInvariant()
    $find      = [regex]::Match($body, "FIND\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value
    $replace   = [regex]::Match($body, "REPLACE\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value

    if (-not $targetRel) { throw "PATCH missing TARGET" }
    if (-not $mode)      { throw "PATCH missing MODE" }
    if (-not $find)      { throw "PATCH missing FIND" }

    $target = Join-Path $RepoRoot $targetRel
    if (!(Test-Path $target)) {
  Write-Host "[SKIP] TARGET not found → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("target-not-found: "+$targetRel) } catch {}
  continue
}

    $orig = Get-Content -LiteralPath $target -Raw -Encoding UTF8
    $rxOpts = [Text.RegularExpressions.RegexOptions]::Multiline -bor [Text.RegularExpressions.RegexOptions]::Singleline
    $rx = [regex]::new($find, $rxOpts)
    $mt = $rx.Match($orig)
    if (-not $mt.Success) {
  Write-Host "[SKIP] FIND not matched → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("find-not-matched: "+$targetRel) } catch {}
  continue
}

    switch ($mode) {
      'insert-before' {
        $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
      }
      'insert-before' {
  $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
}
'insert-after' {
  $new = $orig.Substring(0, $mt.Index + $mt.Length) + "`n" + $replace + $orig.Substring($mt.Index + $mt.Length)
}
'replace' {
        $new = $rx.Replace($orig, $replace, 1)
      }
      default {
  Write-Host "[SKIP] Unsupported MODE → $mode for $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("unsupported-mode: "+$mode+" for "+$targetRel) } catch {}
  continue
}
    }

    if ($ConfirmApply) {
      $bk = "$target.bak-" + (Get-Date -Format 'yyyyMMdd-HHmmss')
      Copy-Item -LiteralPath $target -Destination $bk -Force
      Write-AtomicUtf8 -Path $target -Content $new -Module 'patcher' -Action ('apply:'+ $mode)
      $applied += $targetRel
    } else {
      Write-Host "[PREVIEW] would patch → $targetRel ($mode)"
    }
  }

  if ($ConfirmApply) {
    LogRec 'INFO' 'apply' 'SUCCESS' ("patched: " + ($applied -join ', '))
  } else {
    LogRec 'INFO' 'preview' 'SUCCESS' ("preview-ok (no writes). blocks="+$matches.Count)
  }

  # ── Gate-3 Verify (경량) ───────────────────────────────────────────────────────
  if ($ConfirmApply) {
    # 핵심 타겟의 구문 일치 재검
    $core = Join-Path $RepoRoot 'scripts\apply_ui_patch.ps1'
    if (Test-Path $core) {
      $c = Get-Content -LiteralPath $core -Raw -Encoding UTF8
      if ($c -notmatch 'ensure valid tmp path .* atomic friendly') {
        Write-Host "[WARN] VERIFY: guard snippet not found in apply_ui_patch.ps1"; try { LogRec "WARN" "verify" "SKIPPED" "guard-missing apply_ui_patch.ps1" } catch {}
      }
    }
  }
}
catch {
  LogRec 'ERROR' 'apply' 'FAILURE' $_.Exception.Message 'LOGIC'
  exit 0
}
finally {
  Remove-Item -Force $LockFile -ErrorAction SilentlyContinue
}
.Exception.Message) }
  # 스모크: 같은 볼륨에 원자 쓰기 → 즉시 삭제
  $smoke = Join-Path $RepoRoot 'webui\public\_klc-smoke.txt'
  $smokeContent = "[klc-smoke] $(Get-Date -Format o)"
  Write-AtomicUtf8 -Path $smoke -Content $smokeContent -Module 'patcher' -Action 'smoke'
  if (Test-Path $smoke) { Remove-Item -LiteralPath $smoke -Force -ErrorAction SilentlyContinue }

  # ── Patch 파일 파싱 ───────────────────────────────────────────────────────────
  $PatchFile = Join-Path $RepoRoot '.kobong\patches.pending.txt'
  if (!(Test-Path $PatchFile)) {
  Write-Host "[SKIP] patches file not found → $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("patches-file-missing: "+$PatchFile) } catch {}
  return
}
  $patchText = Get-Content -LiteralPath $PatchFile -Raw -Encoding UTF8
  $global:patchHash = (Get-FileHash -Algorithm SHA256 -InputStream ([IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes($patchText)))).Hash

  $matches = [regex]::Matches($patchText, '(?ms)#\s*PATCH\s*START\s*(?<body>.*?)#\s*PATCH\s*END')
  if ($matches.Count -eq 0) {
  Write-Host "[SKIP] No PATCH blocks found in $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("no-patch-blocks: "+$PatchFile) } catch {}
  return
}

  $applied = @()
  foreach ($m in $matches) {
    $body = $m.Groups['body'].Value

    $targetRel = [regex]::Match($body, 'TARGET:\s*(?<v>.+)').Groups['v'].Value.Trim()
    $mode      = [regex]::Match($body, 'MODE:\s*(?<v>.+)').Groups['v'].Value.Trim().ToLowerInvariant()
    $find      = [regex]::Match($body, "FIND\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value
    $replace   = [regex]::Match($body, "REPLACE\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value

    if (-not $targetRel) { throw "PATCH missing TARGET" }
    if (-not $mode)      { throw "PATCH missing MODE" }
    if (-not $find)      { throw "PATCH missing FIND" }

    $target = Join-Path $RepoRoot $targetRel
    if (!(Test-Path $target)) {
  Write-Host "[SKIP] TARGET not found → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("target-not-found: "+$targetRel) } catch {}
  continue
}

    $orig = Get-Content -LiteralPath $target -Raw -Encoding UTF8
    $rxOpts = [Text.RegularExpressions.RegexOptions]::Multiline -bor [Text.RegularExpressions.RegexOptions]::Singleline
    $rx = [regex]::new($find, $rxOpts)
    $mt = $rx.Match($orig)
    if (-not $mt.Success) {
  Write-Host "[SKIP] FIND not matched → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("find-not-matched: "+$targetRel) } catch {}
  continue
}

    switch ($mode) {
      'insert-before' {
        $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
      }
      'insert-before' {
  $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
}
'insert-after' {
  $new = $orig.Substring(0, $mt.Index + $mt.Length) + "`n" + $replace + $orig.Substring($mt.Index + $mt.Length)
}
'replace' {
        $new = $rx.Replace($orig, $replace, 1)
      }
      default {
  Write-Host "[SKIP] Unsupported MODE → $mode for $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("unsupported-mode: "+$mode+" for "+$targetRel) } catch {}
  continue
}
    }

    if ($ConfirmApply) {
      $bk = "$target.bak-" + (Get-Date -Format 'yyyyMMdd-HHmmss')
      Copy-Item -LiteralPath $target -Destination $bk -Force
      Write-AtomicUtf8 -Path $target -Content $new -Module 'patcher' -Action ('apply:'+ $mode)
      $applied += $targetRel
    } else {
      Write-Host "[PREVIEW] would patch → $targetRel ($mode)"
    }
  }

  if ($ConfirmApply) {
    LogRec 'INFO' 'apply' 'SUCCESS' ("patched: " + ($applied -join ', '))
  } else {
    LogRec 'INFO' 'preview' 'SUCCESS' ("preview-ok (no writes). blocks="+$matches.Count)
  }

  # ── Gate-3 Verify (경량) ───────────────────────────────────────────────────────
  if ($ConfirmApply) {
    # 핵심 타겟의 구문 일치 재검
    $core = Join-Path $RepoRoot 'scripts\apply_ui_patch.ps1'
    if (Test-Path $core) {
      $c = Get-Content -LiteralPath $core -Raw -Encoding UTF8
      if ($c -notmatch 'ensure valid tmp path .* atomic friendly') {
        Write-Host "[WARN] VERIFY: guard snippet not found in apply_ui_patch.ps1"; try { LogRec "WARN" "verify" "SKIPPED" "guard-missing apply_ui_patch.ps1" } catch {}
      }
    }
  }
}
catch {
  LogRec 'ERROR' 'apply' 'FAILURE' $_.Exception.Message 'LOGIC'
  exit 0
}
finally {
  Remove-Item -Force $LockFile -ErrorAction SilentlyContinue
}
.Exception.Message)" }
  # 스모크: 같은 볼륨에 원자 쓰기 → 즉시 삭제
  $smoke = Join-Path $RepoRoot 'webui\public\_klc-smoke.txt'
  $smokeContent = "[klc-smoke] $(Get-Date -Format o)"
  Write-AtomicUtf8 -Path $smoke -Content $smokeContent -Module 'patcher' -Action 'smoke'
  if (Test-Path $smoke) { Remove-Item -LiteralPath $smoke -Force -ErrorAction SilentlyContinue }

  # ── Patch 파일 파싱 ───────────────────────────────────────────────────────────
  $PatchFile = Join-Path $RepoRoot '.kobong\patches.pending.txt'
  if (!(Test-Path $PatchFile)) {
  Write-Host "[SKIP] patches file not found → $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("patches-file-missing: "+$PatchFile) } catch {}
  return
}
  $patchText = Get-Content -LiteralPath $PatchFile -Raw -Encoding UTF8
  $global:patchHash = (Get-FileHash -Algorithm SHA256 -InputStream ([IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes($patchText)))).Hash

  $matches = [regex]::Matches($patchText, '(?ms)#\s*PATCH\s*START\s*(?<body>.*?)#\s*PATCH\s*END')
  if ($matches.Count -eq 0) {
  Write-Host "[SKIP] No PATCH blocks found in $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("no-patch-blocks: "+$PatchFile) } catch {}
  return
}

  $applied = @()
  foreach ($m in $matches) {
    $body = $m.Groups['body'].Value

    $targetRel = [regex]::Match($body, 'TARGET:\s*(?<v>.+)').Groups['v'].Value.Trim()
    $mode      = [regex]::Match($body, 'MODE:\s*(?<v>.+)').Groups['v'].Value.Trim().ToLowerInvariant()
    $find      = [regex]::Match($body, "FIND\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value
    $replace   = [regex]::Match($body, "REPLACE\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value

    if (-not $targetRel) { throw "PATCH missing TARGET" }
    if (-not $mode)      { throw "PATCH missing MODE" }
    if (-not $find)      { throw "PATCH missing FIND" }

    $target = Join-Path $RepoRoot $targetRel
    if (!(Test-Path $target)) {
  Write-Host "[SKIP] TARGET not found → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("target-not-found: "+$targetRel) } catch {}
  continue
}

    $orig = Get-Content -LiteralPath $target -Raw -Encoding UTF8
    $rxOpts = [Text.RegularExpressions.RegexOptions]::Multiline -bor [Text.RegularExpressions.RegexOptions]::Singleline
    $rx = [regex]::new($find, $rxOpts)
    $mt = $rx.Match($orig)
    if (-not $mt.Success) {
  Write-Host "[SKIP] FIND not matched → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("find-not-matched: "+$targetRel) } catch {}
  continue
}

    switch ($mode) {
      'insert-before' {
        $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
      }
      'insert-before' {
  $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
}
'insert-after' {
  $new = $orig.Substring(0, $mt.Index + $mt.Length) + "`n" + $replace + $orig.Substring($mt.Index + $mt.Length)
}
'replace' {
        $new = $rx.Replace($orig, $replace, 1)
      }
      default {
  Write-Host "[SKIP] Unsupported MODE → $mode for $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("unsupported-mode: "+$mode+" for "+$targetRel) } catch {}
  continue
}
    }

    if ($ConfirmApply) {
      $bk = "$target.bak-" + (Get-Date -Format 'yyyyMMdd-HHmmss')
      Copy-Item -LiteralPath $target -Destination $bk -Force
      Write-AtomicUtf8 -Path $target -Content $new -Module 'patcher' -Action ('apply:'+ $mode)
      $applied += $targetRel
    } else {
      Write-Host "[PREVIEW] would patch → $targetRel ($mode)"
    }
  }

  if ($ConfirmApply) {
    LogRec 'INFO' 'apply' 'SUCCESS' ("patched: " + ($applied -join ', '))
  } else {
    LogRec 'INFO' 'preview' 'SUCCESS' ("preview-ok (no writes). blocks="+$matches.Count)
  }

  # ── Gate-3 Verify (경량) ───────────────────────────────────────────────────────
  if ($ConfirmApply) {
    # 핵심 타겟의 구문 일치 재검
    $core = Join-Path $RepoRoot 'scripts\apply_ui_patch.ps1'
    if (Test-Path $core) {
      $c = Get-Content -LiteralPath $core -Raw -Encoding UTF8
      if ($c -notmatch 'ensure valid tmp path .* atomic friendly') {
        Write-Host "[WARN] VERIFY: guard snippet not found in apply_ui_patch.ps1"; try { LogRec "WARN" "verify" "SKIPPED" "guard-missing apply_ui_patch.ps1" } catch {}
      }
    }
  }
}
catch {
  LogRec 'ERROR' 'apply' 'FAILURE' $_.Exception.Message 'LOGIC'
  exit 0
}
finally {
  Remove-Item -Force $LockFile -ErrorAction SilentlyContinue
}
.Exception.Message)" }
}
try { Import-Module $ModPath -Force } catch { Write-Host ("[WARN] Import-Module failed -> " + $ModPath + ": " + # APPLY IN SHELL
#requires -Version 7.0
param([switch]$ConfirmApply,[string]$Root)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

# ── Gate-0: Repo / Lock ─────────────────────────────────────────────────────────
function Get-RepoRoot {
  try {
    $p = (git rev-parse --show-toplevel 2>$null)
    if ($p) { return (Resolve-Path $p).Path }
  } catch {}
  if ($Root) { return (Resolve-Path $Root).Path }
  return (Get-Location).Path
}
$RepoRoot = Get-RepoRoot
$LockFile = Join-Path $RepoRoot '.gpt5.lock'
if (Test-Path $LockFile) { Write-Error 'CONFLICT: .gpt5.lock exists.'; exit 11 }
"locked $(Get-Date -Format o)" | Out-File $LockFile -Encoding utf8 -NoNewline

$sw=[Diagnostics.Stopwatch]::StartNew()
$trace=[guid]::NewGuid().ToString()
$logPath = Join-Path $RepoRoot 'logs/apply-log.jsonl'
New-Item -ItemType Directory -Force -Path (Split-Path $logPath) | Out-Null

function LogRec([string]$level,[string]$action,[string]$outcome,[string]$msg,[string]$err='') {
  $rec = @{
    timestamp=(Get-Date).ToString('o'); level=$level; traceId=$trace; module='patcher';
    action=$action; inputHash=((Get-Variable -Name patchHash -Scope Global -ValueOnly -ErrorAction SilentlyContinue) ?? ""); outcome=$outcome;
    durationMs=$sw.ElapsedMilliseconds; errorCode=$err; message=$msg
  } | ConvertTo-Json -Compress
  Add-Content -Path $logPath -Value $rec
}

try {
  # ── Preflight: 모듈 로드 & 스모크 ─────────────────────────────────────────────
  $ModPath = Join-Path $RepoRoot 'scripts\lib\kobong-fileio.psm1'
  if (!(Test-Path $ModPath)) {
  Write-Host "[WARN] Missing module → $ModPath (continuing)"
  try { LogRec "WARN" "apply" "SKIPPED" ("missing-module: "+$ModPath) } catch {}
} else {
  try { Import-Module $ModPath -Force } catch { Write-Host ("[WARN] Import-Module failed -> " + $ModPath + ": " + # APPLY IN SHELL
#requires -Version 7.0
param([switch]$ConfirmApply,[string]$Root)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

# ── Gate-0: Repo / Lock ─────────────────────────────────────────────────────────
function Get-RepoRoot {
  try {
    $p = (git rev-parse --show-toplevel 2>$null)
    if ($p) { return (Resolve-Path $p).Path }
  } catch {}
  if ($Root) { return (Resolve-Path $Root).Path }
  return (Get-Location).Path
}
$RepoRoot = Get-RepoRoot
$LockFile = Join-Path $RepoRoot '.gpt5.lock'
if (Test-Path $LockFile) { Write-Error 'CONFLICT: .gpt5.lock exists.'; exit 11 }
"locked $(Get-Date -Format o)" | Out-File $LockFile -Encoding utf8 -NoNewline

$sw=[Diagnostics.Stopwatch]::StartNew()
$trace=[guid]::NewGuid().ToString()
$logPath = Join-Path $RepoRoot 'logs/apply-log.jsonl'
New-Item -ItemType Directory -Force -Path (Split-Path $logPath) | Out-Null

function LogRec([string]$level,[string]$action,[string]$outcome,[string]$msg,[string]$err='') {
  $rec = @{
    timestamp=(Get-Date).ToString('o'); level=$level; traceId=$trace; module='patcher';
    action=$action; inputHash=((Get-Variable -Name patchHash -Scope Global -ValueOnly -ErrorAction SilentlyContinue) ?? ""); outcome=$outcome;
    durationMs=$sw.ElapsedMilliseconds; errorCode=$err; message=$msg
  } | ConvertTo-Json -Compress
  Add-Content -Path $logPath -Value $rec
}

try {
  # ── Preflight: 모듈 로드 & 스모크 ─────────────────────────────────────────────
  $ModPath = Join-Path $RepoRoot 'scripts\lib\kobong-fileio.psm1'
  if (!(Test-Path $ModPath)) {
  Write-Host "[WARN] Missing module → $ModPath (continuing)"
  try { LogRec "WARN" "apply" "SKIPPED" ("missing-module: "+$ModPath) } catch {}
} else {
  try { Import-Module $ModPath -Force } catch { Write-Host "[WARN] Import-Module failed → $ModPath: $(# APPLY IN SHELL
#requires -Version 7.0
param([switch]$ConfirmApply,[string]$Root)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

# ── Gate-0: Repo / Lock ─────────────────────────────────────────────────────────
function Get-RepoRoot {
  try {
    $p = (git rev-parse --show-toplevel 2>$null)
    if ($p) { return (Resolve-Path $p).Path }
  } catch {}
  if ($Root) { return (Resolve-Path $Root).Path }
  return (Get-Location).Path
}
$RepoRoot = Get-RepoRoot
$LockFile = Join-Path $RepoRoot '.gpt5.lock'
if (Test-Path $LockFile) { Write-Error 'CONFLICT: .gpt5.lock exists.'; exit 11 }
"locked $(Get-Date -Format o)" | Out-File $LockFile -Encoding utf8 -NoNewline

$sw=[Diagnostics.Stopwatch]::StartNew()
$trace=[guid]::NewGuid().ToString()
$logPath = Join-Path $RepoRoot 'logs/apply-log.jsonl'
New-Item -ItemType Directory -Force -Path (Split-Path $logPath) | Out-Null

function LogRec([string]$level,[string]$action,[string]$outcome,[string]$msg,[string]$err='') {
  $rec = @{
    timestamp=(Get-Date).ToString('o'); level=$level; traceId=$trace; module='patcher';
    action=$action; inputHash=((Get-Variable -Name patchHash -Scope Global -ValueOnly -ErrorAction SilentlyContinue) ?? ""); outcome=$outcome;
    durationMs=$sw.ElapsedMilliseconds; errorCode=$err; message=$msg
  } | ConvertTo-Json -Compress
  Add-Content -Path $logPath -Value $rec
}

try {
  # ── Preflight: 모듈 로드 & 스모크 ─────────────────────────────────────────────
  $ModPath = Join-Path $RepoRoot 'scripts\lib\kobong-fileio.psm1'
  if (!(Test-Path $ModPath)) { throw "Missing module: $ModPath" }
try { Import-Module $ModPath -Force } catch { Write-Host "[WARN] Import-Module failed → $ModPath: $(# APPLY IN SHELL
#requires -Version 7.0
param([switch]$ConfirmApply,[string]$Root)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

# ── Gate-0: Repo / Lock ─────────────────────────────────────────────────────────
function Get-RepoRoot {
  try {
    $p = (git rev-parse --show-toplevel 2>$null)
    if ($p) { return (Resolve-Path $p).Path }
  } catch {}
  if ($Root) { return (Resolve-Path $Root).Path }
  return (Get-Location).Path
}
$RepoRoot = Get-RepoRoot
$LockFile = Join-Path $RepoRoot '.gpt5.lock'
if (Test-Path $LockFile) { Write-Error 'CONFLICT: .gpt5.lock exists.'; exit 11 }
"locked $(Get-Date -Format o)" | Out-File $LockFile -Encoding utf8 -NoNewline

$sw=[Diagnostics.Stopwatch]::StartNew()
$trace=[guid]::NewGuid().ToString()
$logPath = Join-Path $RepoRoot 'logs/apply-log.jsonl'
New-Item -ItemType Directory -Force -Path (Split-Path $logPath) | Out-Null

function LogRec([string]$level,[string]$action,[string]$outcome,[string]$msg,[string]$err='') {
  $rec = @{
    timestamp=(Get-Date).ToString('o'); level=$level; traceId=$trace; module='patcher';
    action=$action; inputHash=((Get-Variable -Name patchHash -Scope Global -ValueOnly -ErrorAction SilentlyContinue) ?? ""); outcome=$outcome;
    durationMs=$sw.ElapsedMilliseconds; errorCode=$err; message=$msg
  } | ConvertTo-Json -Compress
  Add-Content -Path $logPath -Value $rec
}

try {
  # ── Preflight: 모듈 로드 & 스모크 ─────────────────────────────────────────────
  $ModPath = Join-Path $RepoRoot 'scripts\lib\kobong-fileio.psm1'
  if (!(Test-Path $ModPath)) { throw "Missing module: $ModPath" }
  Import-Module $ModPath -Force

  # 스모크: 같은 볼륨에 원자 쓰기 → 즉시 삭제
  $smoke = Join-Path $RepoRoot 'webui\public\_klc-smoke.txt'
  $smokeContent = "[klc-smoke] $(Get-Date -Format o)"
  Write-AtomicUtf8 -Path $smoke -Content $smokeContent -Module 'patcher' -Action 'smoke'
  if (Test-Path $smoke) { Remove-Item -LiteralPath $smoke -Force -ErrorAction SilentlyContinue }

  # ── Patch 파일 파싱 ───────────────────────────────────────────────────────────
  $PatchFile = Join-Path $RepoRoot '.kobong\patches.pending.txt'
  if (!(Test-Path $PatchFile)) {
  Write-Host "[SKIP] patches file not found → $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("patches-file-missing: "+$PatchFile) } catch {}
  return
}
  $patchText = Get-Content -LiteralPath $PatchFile -Raw -Encoding UTF8
  $global:patchHash = (Get-FileHash -Algorithm SHA256 -InputStream ([IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes($patchText)))).Hash

  $matches = [regex]::Matches($patchText, '(?ms)#\s*PATCH\s*START\s*(?<body>.*?)#\s*PATCH\s*END')
  if ($matches.Count -eq 0) {
  Write-Host "[SKIP] No PATCH blocks found in $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("no-patch-blocks: "+$PatchFile) } catch {}
  return
}

  $applied = @()
  foreach ($m in $matches) {
    $body = $m.Groups['body'].Value

    $targetRel = [regex]::Match($body, 'TARGET:\s*(?<v>.+)').Groups['v'].Value.Trim()
    $mode      = [regex]::Match($body, 'MODE:\s*(?<v>.+)').Groups['v'].Value.Trim().ToLowerInvariant()
    $find      = [regex]::Match($body, "FIND\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value
    $replace   = [regex]::Match($body, "REPLACE\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value

    if (-not $targetRel) { throw "PATCH missing TARGET" }
    if (-not $mode)      { throw "PATCH missing MODE" }
    if (-not $find)      { throw "PATCH missing FIND" }

    $target = Join-Path $RepoRoot $targetRel
    if (!(Test-Path $target)) {
  Write-Host "[SKIP] TARGET not found → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("target-not-found: "+$targetRel) } catch {}
  continue
}

    $orig = Get-Content -LiteralPath $target -Raw -Encoding UTF8
    $rxOpts = [Text.RegularExpressions.RegexOptions]::Multiline -bor [Text.RegularExpressions.RegexOptions]::Singleline
    $rx = [regex]::new($find, $rxOpts)
    $mt = $rx.Match($orig)
    if (-not $mt.Success) {
  Write-Host "[SKIP] FIND not matched → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("find-not-matched: "+$targetRel) } catch {}
  continue
}

    switch ($mode) {
      'insert-before' {
        $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
      }
      'insert-before' {
  $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
}
'insert-after' {
  $new = $orig.Substring(0, $mt.Index + $mt.Length) + "`n" + $replace + $orig.Substring($mt.Index + $mt.Length)
}
'replace' {
        $new = $rx.Replace($orig, $replace, 1)
      }
      default {
  Write-Host "[SKIP] Unsupported MODE → $mode for $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("unsupported-mode: "+$mode+" for "+$targetRel) } catch {}
  continue
}
    }

    if ($ConfirmApply) {
      $bk = "$target.bak-" + (Get-Date -Format 'yyyyMMdd-HHmmss')
      Copy-Item -LiteralPath $target -Destination $bk -Force
      Write-AtomicUtf8 -Path $target -Content $new -Module 'patcher' -Action ('apply:'+ $mode)
      $applied += $targetRel
    } else {
      Write-Host "[PREVIEW] would patch → $targetRel ($mode)"
    }
  }

  if ($ConfirmApply) {
    LogRec 'INFO' 'apply' 'SUCCESS' ("patched: " + ($applied -join ', '))
  } else {
    LogRec 'INFO' 'preview' 'SUCCESS' ("preview-ok (no writes). blocks="+$matches.Count)
  }

  # ── Gate-3 Verify (경량) ───────────────────────────────────────────────────────
  if ($ConfirmApply) {
    # 핵심 타겟의 구문 일치 재검
    $core = Join-Path $RepoRoot 'scripts\apply_ui_patch.ps1'
    if (Test-Path $core) {
      $c = Get-Content -LiteralPath $core -Raw -Encoding UTF8
      if ($c -notmatch 'ensure valid tmp path .* atomic friendly') {
        Write-Host "[WARN] VERIFY: guard snippet not found in apply_ui_patch.ps1"; try { LogRec "WARN" "verify" "SKIPPED" "guard-missing apply_ui_patch.ps1" } catch {}
      }
    }
  }
}
catch {
  LogRec 'ERROR' 'apply' 'FAILURE' $_.Exception.Message 'LOGIC'
  exit 0
}
finally {
  Remove-Item -Force $LockFile -ErrorAction SilentlyContinue
}
.Exception.Message)" }
  # 스모크: 같은 볼륨에 원자 쓰기 → 즉시 삭제
  $smoke = Join-Path $RepoRoot 'webui\public\_klc-smoke.txt'
  $smokeContent = "[klc-smoke] $(Get-Date -Format o)"
  Write-AtomicUtf8 -Path $smoke -Content $smokeContent -Module 'patcher' -Action 'smoke'
  if (Test-Path $smoke) { Remove-Item -LiteralPath $smoke -Force -ErrorAction SilentlyContinue }

  # ── Patch 파일 파싱 ───────────────────────────────────────────────────────────
  $PatchFile = Join-Path $RepoRoot '.kobong\patches.pending.txt'
  if (!(Test-Path $PatchFile)) {
  Write-Host "[SKIP] patches file not found → $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("patches-file-missing: "+$PatchFile) } catch {}
  return
}
  $patchText = Get-Content -LiteralPath $PatchFile -Raw -Encoding UTF8
  $global:patchHash = (Get-FileHash -Algorithm SHA256 -InputStream ([IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes($patchText)))).Hash

  $matches = [regex]::Matches($patchText, '(?ms)#\s*PATCH\s*START\s*(?<body>.*?)#\s*PATCH\s*END')
  if ($matches.Count -eq 0) {
  Write-Host "[SKIP] No PATCH blocks found in $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("no-patch-blocks: "+$PatchFile) } catch {}
  return
}

  $applied = @()
  foreach ($m in $matches) {
    $body = $m.Groups['body'].Value

    $targetRel = [regex]::Match($body, 'TARGET:\s*(?<v>.+)').Groups['v'].Value.Trim()
    $mode      = [regex]::Match($body, 'MODE:\s*(?<v>.+)').Groups['v'].Value.Trim().ToLowerInvariant()
    $find      = [regex]::Match($body, "FIND\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value
    $replace   = [regex]::Match($body, "REPLACE\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value

    if (-not $targetRel) { throw "PATCH missing TARGET" }
    if (-not $mode)      { throw "PATCH missing MODE" }
    if (-not $find)      { throw "PATCH missing FIND" }

    $target = Join-Path $RepoRoot $targetRel
    if (!(Test-Path $target)) {
  Write-Host "[SKIP] TARGET not found → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("target-not-found: "+$targetRel) } catch {}
  continue
}

    $orig = Get-Content -LiteralPath $target -Raw -Encoding UTF8
    $rxOpts = [Text.RegularExpressions.RegexOptions]::Multiline -bor [Text.RegularExpressions.RegexOptions]::Singleline
    $rx = [regex]::new($find, $rxOpts)
    $mt = $rx.Match($orig)
    if (-not $mt.Success) {
  Write-Host "[SKIP] FIND not matched → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("find-not-matched: "+$targetRel) } catch {}
  continue
}

    switch ($mode) {
      'insert-before' {
        $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
      }
      'insert-before' {
  $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
}
'insert-after' {
  $new = $orig.Substring(0, $mt.Index + $mt.Length) + "`n" + $replace + $orig.Substring($mt.Index + $mt.Length)
}
'replace' {
        $new = $rx.Replace($orig, $replace, 1)
      }
      default {
  Write-Host "[SKIP] Unsupported MODE → $mode for $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("unsupported-mode: "+$mode+" for "+$targetRel) } catch {}
  continue
}
    }

    if ($ConfirmApply) {
      $bk = "$target.bak-" + (Get-Date -Format 'yyyyMMdd-HHmmss')
      Copy-Item -LiteralPath $target -Destination $bk -Force
      Write-AtomicUtf8 -Path $target -Content $new -Module 'patcher' -Action ('apply:'+ $mode)
      $applied += $targetRel
    } else {
      Write-Host "[PREVIEW] would patch → $targetRel ($mode)"
    }
  }

  if ($ConfirmApply) {
    LogRec 'INFO' 'apply' 'SUCCESS' ("patched: " + ($applied -join ', '))
  } else {
    LogRec 'INFO' 'preview' 'SUCCESS' ("preview-ok (no writes). blocks="+$matches.Count)
  }

  # ── Gate-3 Verify (경량) ───────────────────────────────────────────────────────
  if ($ConfirmApply) {
    # 핵심 타겟의 구문 일치 재검
    $core = Join-Path $RepoRoot 'scripts\apply_ui_patch.ps1'
    if (Test-Path $core) {
      $c = Get-Content -LiteralPath $core -Raw -Encoding UTF8
      if ($c -notmatch 'ensure valid tmp path .* atomic friendly') {
        Write-Host "[WARN] VERIFY: guard snippet not found in apply_ui_patch.ps1"; try { LogRec "WARN" "verify" "SKIPPED" "guard-missing apply_ui_patch.ps1" } catch {}
      }
    }
  }
}
catch {
  LogRec 'ERROR' 'apply' 'FAILURE' $_.Exception.Message 'LOGIC'
  exit 0
}
finally {
  Remove-Item -Force $LockFile -ErrorAction SilentlyContinue
}
.Exception.Message)" }
}
try { Import-Module $ModPath -Force } catch { Write-Host "[WARN] Import-Module failed → $ModPath: $(# APPLY IN SHELL
#requires -Version 7.0
param([switch]$ConfirmApply,[string]$Root)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

# ── Gate-0: Repo / Lock ─────────────────────────────────────────────────────────
function Get-RepoRoot {
  try {
    $p = (git rev-parse --show-toplevel 2>$null)
    if ($p) { return (Resolve-Path $p).Path }
  } catch {}
  if ($Root) { return (Resolve-Path $Root).Path }
  return (Get-Location).Path
}
$RepoRoot = Get-RepoRoot
$LockFile = Join-Path $RepoRoot '.gpt5.lock'
if (Test-Path $LockFile) { Write-Error 'CONFLICT: .gpt5.lock exists.'; exit 11 }
"locked $(Get-Date -Format o)" | Out-File $LockFile -Encoding utf8 -NoNewline

$sw=[Diagnostics.Stopwatch]::StartNew()
$trace=[guid]::NewGuid().ToString()
$logPath = Join-Path $RepoRoot 'logs/apply-log.jsonl'
New-Item -ItemType Directory -Force -Path (Split-Path $logPath) | Out-Null

function LogRec([string]$level,[string]$action,[string]$outcome,[string]$msg,[string]$err='') {
  $rec = @{
    timestamp=(Get-Date).ToString('o'); level=$level; traceId=$trace; module='patcher';
    action=$action; inputHash=((Get-Variable -Name patchHash -Scope Global -ValueOnly -ErrorAction SilentlyContinue) ?? ""); outcome=$outcome;
    durationMs=$sw.ElapsedMilliseconds; errorCode=$err; message=$msg
  } | ConvertTo-Json -Compress
  Add-Content -Path $logPath -Value $rec
}

try {
  # ── Preflight: 모듈 로드 & 스모크 ─────────────────────────────────────────────
  $ModPath = Join-Path $RepoRoot 'scripts\lib\kobong-fileio.psm1'
  if (!(Test-Path $ModPath)) {
  Write-Host "[WARN] Missing module → $ModPath (continuing)"
  try { LogRec "WARN" "apply" "SKIPPED" ("missing-module: "+$ModPath) } catch {}
} else {
  try { Import-Module $ModPath -Force } catch { Write-Host "[WARN] Import-Module failed → $ModPath: $(# APPLY IN SHELL
#requires -Version 7.0
param([switch]$ConfirmApply,[string]$Root)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

# ── Gate-0: Repo / Lock ─────────────────────────────────────────────────────────
function Get-RepoRoot {
  try {
    $p = (git rev-parse --show-toplevel 2>$null)
    if ($p) { return (Resolve-Path $p).Path }
  } catch {}
  if ($Root) { return (Resolve-Path $Root).Path }
  return (Get-Location).Path
}
$RepoRoot = Get-RepoRoot
$LockFile = Join-Path $RepoRoot '.gpt5.lock'
if (Test-Path $LockFile) { Write-Error 'CONFLICT: .gpt5.lock exists.'; exit 11 }
"locked $(Get-Date -Format o)" | Out-File $LockFile -Encoding utf8 -NoNewline

$sw=[Diagnostics.Stopwatch]::StartNew()
$trace=[guid]::NewGuid().ToString()
$logPath = Join-Path $RepoRoot 'logs/apply-log.jsonl'
New-Item -ItemType Directory -Force -Path (Split-Path $logPath) | Out-Null

function LogRec([string]$level,[string]$action,[string]$outcome,[string]$msg,[string]$err='') {
  $rec = @{
    timestamp=(Get-Date).ToString('o'); level=$level; traceId=$trace; module='patcher';
    action=$action; inputHash=((Get-Variable -Name patchHash -Scope Global -ValueOnly -ErrorAction SilentlyContinue) ?? ""); outcome=$outcome;
    durationMs=$sw.ElapsedMilliseconds; errorCode=$err; message=$msg
  } | ConvertTo-Json -Compress
  Add-Content -Path $logPath -Value $rec
}

try {
  # ── Preflight: 모듈 로드 & 스모크 ─────────────────────────────────────────────
  $ModPath = Join-Path $RepoRoot 'scripts\lib\kobong-fileio.psm1'
  if (!(Test-Path $ModPath)) { throw "Missing module: $ModPath" }
try { Import-Module $ModPath -Force } catch { Write-Host "[WARN] Import-Module failed → $ModPath: $(# APPLY IN SHELL
#requires -Version 7.0
param([switch]$ConfirmApply,[string]$Root)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

# ── Gate-0: Repo / Lock ─────────────────────────────────────────────────────────
function Get-RepoRoot {
  try {
    $p = (git rev-parse --show-toplevel 2>$null)
    if ($p) { return (Resolve-Path $p).Path }
  } catch {}
  if ($Root) { return (Resolve-Path $Root).Path }
  return (Get-Location).Path
}
$RepoRoot = Get-RepoRoot
$LockFile = Join-Path $RepoRoot '.gpt5.lock'
if (Test-Path $LockFile) { Write-Error 'CONFLICT: .gpt5.lock exists.'; exit 11 }
"locked $(Get-Date -Format o)" | Out-File $LockFile -Encoding utf8 -NoNewline

$sw=[Diagnostics.Stopwatch]::StartNew()
$trace=[guid]::NewGuid().ToString()
$logPath = Join-Path $RepoRoot 'logs/apply-log.jsonl'
New-Item -ItemType Directory -Force -Path (Split-Path $logPath) | Out-Null

function LogRec([string]$level,[string]$action,[string]$outcome,[string]$msg,[string]$err='') {
  $rec = @{
    timestamp=(Get-Date).ToString('o'); level=$level; traceId=$trace; module='patcher';
    action=$action; inputHash=((Get-Variable -Name patchHash -Scope Global -ValueOnly -ErrorAction SilentlyContinue) ?? ""); outcome=$outcome;
    durationMs=$sw.ElapsedMilliseconds; errorCode=$err; message=$msg
  } | ConvertTo-Json -Compress
  Add-Content -Path $logPath -Value $rec
}

try {
  # ── Preflight: 모듈 로드 & 스모크 ─────────────────────────────────────────────
  $ModPath = Join-Path $RepoRoot 'scripts\lib\kobong-fileio.psm1'
  if (!(Test-Path $ModPath)) { throw "Missing module: $ModPath" }
  Import-Module $ModPath -Force

  # 스모크: 같은 볼륨에 원자 쓰기 → 즉시 삭제
  $smoke = Join-Path $RepoRoot 'webui\public\_klc-smoke.txt'
  $smokeContent = "[klc-smoke] $(Get-Date -Format o)"
  Write-AtomicUtf8 -Path $smoke -Content $smokeContent -Module 'patcher' -Action 'smoke'
  if (Test-Path $smoke) { Remove-Item -LiteralPath $smoke -Force -ErrorAction SilentlyContinue }

  # ── Patch 파일 파싱 ───────────────────────────────────────────────────────────
  $PatchFile = Join-Path $RepoRoot '.kobong\patches.pending.txt'
  if (!(Test-Path $PatchFile)) {
  Write-Host "[SKIP] patches file not found → $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("patches-file-missing: "+$PatchFile) } catch {}
  return
}
  $patchText = Get-Content -LiteralPath $PatchFile -Raw -Encoding UTF8
  $global:patchHash = (Get-FileHash -Algorithm SHA256 -InputStream ([IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes($patchText)))).Hash

  $matches = [regex]::Matches($patchText, '(?ms)#\s*PATCH\s*START\s*(?<body>.*?)#\s*PATCH\s*END')
  if ($matches.Count -eq 0) {
  Write-Host "[SKIP] No PATCH blocks found in $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("no-patch-blocks: "+$PatchFile) } catch {}
  return
}

  $applied = @()
  foreach ($m in $matches) {
    $body = $m.Groups['body'].Value

    $targetRel = [regex]::Match($body, 'TARGET:\s*(?<v>.+)').Groups['v'].Value.Trim()
    $mode      = [regex]::Match($body, 'MODE:\s*(?<v>.+)').Groups['v'].Value.Trim().ToLowerInvariant()
    $find      = [regex]::Match($body, "FIND\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value
    $replace   = [regex]::Match($body, "REPLACE\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value

    if (-not $targetRel) { throw "PATCH missing TARGET" }
    if (-not $mode)      { throw "PATCH missing MODE" }
    if (-not $find)      { throw "PATCH missing FIND" }

    $target = Join-Path $RepoRoot $targetRel
    if (!(Test-Path $target)) {
  Write-Host "[SKIP] TARGET not found → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("target-not-found: "+$targetRel) } catch {}
  continue
}

    $orig = Get-Content -LiteralPath $target -Raw -Encoding UTF8
    $rxOpts = [Text.RegularExpressions.RegexOptions]::Multiline -bor [Text.RegularExpressions.RegexOptions]::Singleline
    $rx = [regex]::new($find, $rxOpts)
    $mt = $rx.Match($orig)
    if (-not $mt.Success) {
  Write-Host "[SKIP] FIND not matched → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("find-not-matched: "+$targetRel) } catch {}
  continue
}

    switch ($mode) {
      'insert-before' {
        $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
      }
      'insert-before' {
  $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
}
'insert-after' {
  $new = $orig.Substring(0, $mt.Index + $mt.Length) + "`n" + $replace + $orig.Substring($mt.Index + $mt.Length)
}
'replace' {
        $new = $rx.Replace($orig, $replace, 1)
      }
      default {
  Write-Host "[SKIP] Unsupported MODE → $mode for $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("unsupported-mode: "+$mode+" for "+$targetRel) } catch {}
  continue
}
    }

    if ($ConfirmApply) {
      $bk = "$target.bak-" + (Get-Date -Format 'yyyyMMdd-HHmmss')
      Copy-Item -LiteralPath $target -Destination $bk -Force
      Write-AtomicUtf8 -Path $target -Content $new -Module 'patcher' -Action ('apply:'+ $mode)
      $applied += $targetRel
    } else {
      Write-Host "[PREVIEW] would patch → $targetRel ($mode)"
    }
  }

  if ($ConfirmApply) {
    LogRec 'INFO' 'apply' 'SUCCESS' ("patched: " + ($applied -join ', '))
  } else {
    LogRec 'INFO' 'preview' 'SUCCESS' ("preview-ok (no writes). blocks="+$matches.Count)
  }

  # ── Gate-3 Verify (경량) ───────────────────────────────────────────────────────
  if ($ConfirmApply) {
    # 핵심 타겟의 구문 일치 재검
    $core = Join-Path $RepoRoot 'scripts\apply_ui_patch.ps1'
    if (Test-Path $core) {
      $c = Get-Content -LiteralPath $core -Raw -Encoding UTF8
      if ($c -notmatch 'ensure valid tmp path .* atomic friendly') {
        Write-Host "[WARN] VERIFY: guard snippet not found in apply_ui_patch.ps1"; try { LogRec "WARN" "verify" "SKIPPED" "guard-missing apply_ui_patch.ps1" } catch {}
      }
    }
  }
}
catch {
  LogRec 'ERROR' 'apply' 'FAILURE' $_.Exception.Message 'LOGIC'
  exit 0
}
finally {
  Remove-Item -Force $LockFile -ErrorAction SilentlyContinue
}
.Exception.Message)" }
  # 스모크: 같은 볼륨에 원자 쓰기 → 즉시 삭제
  $smoke = Join-Path $RepoRoot 'webui\public\_klc-smoke.txt'
  $smokeContent = "[klc-smoke] $(Get-Date -Format o)"
  Write-AtomicUtf8 -Path $smoke -Content $smokeContent -Module 'patcher' -Action 'smoke'
  if (Test-Path $smoke) { Remove-Item -LiteralPath $smoke -Force -ErrorAction SilentlyContinue }

  # ── Patch 파일 파싱 ───────────────────────────────────────────────────────────
  $PatchFile = Join-Path $RepoRoot '.kobong\patches.pending.txt'
  if (!(Test-Path $PatchFile)) {
  Write-Host "[SKIP] patches file not found → $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("patches-file-missing: "+$PatchFile) } catch {}
  return
}
  $patchText = Get-Content -LiteralPath $PatchFile -Raw -Encoding UTF8
  $global:patchHash = (Get-FileHash -Algorithm SHA256 -InputStream ([IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes($patchText)))).Hash

  $matches = [regex]::Matches($patchText, '(?ms)#\s*PATCH\s*START\s*(?<body>.*?)#\s*PATCH\s*END')
  if ($matches.Count -eq 0) {
  Write-Host "[SKIP] No PATCH blocks found in $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("no-patch-blocks: "+$PatchFile) } catch {}
  return
}

  $applied = @()
  foreach ($m in $matches) {
    $body = $m.Groups['body'].Value

    $targetRel = [regex]::Match($body, 'TARGET:\s*(?<v>.+)').Groups['v'].Value.Trim()
    $mode      = [regex]::Match($body, 'MODE:\s*(?<v>.+)').Groups['v'].Value.Trim().ToLowerInvariant()
    $find      = [regex]::Match($body, "FIND\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value
    $replace   = [regex]::Match($body, "REPLACE\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value

    if (-not $targetRel) { throw "PATCH missing TARGET" }
    if (-not $mode)      { throw "PATCH missing MODE" }
    if (-not $find)      { throw "PATCH missing FIND" }

    $target = Join-Path $RepoRoot $targetRel
    if (!(Test-Path $target)) {
  Write-Host "[SKIP] TARGET not found → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("target-not-found: "+$targetRel) } catch {}
  continue
}

    $orig = Get-Content -LiteralPath $target -Raw -Encoding UTF8
    $rxOpts = [Text.RegularExpressions.RegexOptions]::Multiline -bor [Text.RegularExpressions.RegexOptions]::Singleline
    $rx = [regex]::new($find, $rxOpts)
    $mt = $rx.Match($orig)
    if (-not $mt.Success) {
  Write-Host "[SKIP] FIND not matched → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("find-not-matched: "+$targetRel) } catch {}
  continue
}

    switch ($mode) {
      'insert-before' {
        $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
      }
      'insert-before' {
  $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
}
'insert-after' {
  $new = $orig.Substring(0, $mt.Index + $mt.Length) + "`n" + $replace + $orig.Substring($mt.Index + $mt.Length)
}
'replace' {
        $new = $rx.Replace($orig, $replace, 1)
      }
      default {
  Write-Host "[SKIP] Unsupported MODE → $mode for $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("unsupported-mode: "+$mode+" for "+$targetRel) } catch {}
  continue
}
    }

    if ($ConfirmApply) {
      $bk = "$target.bak-" + (Get-Date -Format 'yyyyMMdd-HHmmss')
      Copy-Item -LiteralPath $target -Destination $bk -Force
      Write-AtomicUtf8 -Path $target -Content $new -Module 'patcher' -Action ('apply:'+ $mode)
      $applied += $targetRel
    } else {
      Write-Host "[PREVIEW] would patch → $targetRel ($mode)"
    }
  }

  if ($ConfirmApply) {
    LogRec 'INFO' 'apply' 'SUCCESS' ("patched: " + ($applied -join ', '))
  } else {
    LogRec 'INFO' 'preview' 'SUCCESS' ("preview-ok (no writes). blocks="+$matches.Count)
  }

  # ── Gate-3 Verify (경량) ───────────────────────────────────────────────────────
  if ($ConfirmApply) {
    # 핵심 타겟의 구문 일치 재검
    $core = Join-Path $RepoRoot 'scripts\apply_ui_patch.ps1'
    if (Test-Path $core) {
      $c = Get-Content -LiteralPath $core -Raw -Encoding UTF8
      if ($c -notmatch 'ensure valid tmp path .* atomic friendly') {
        Write-Host "[WARN] VERIFY: guard snippet not found in apply_ui_patch.ps1"; try { LogRec "WARN" "verify" "SKIPPED" "guard-missing apply_ui_patch.ps1" } catch {}
      }
    }
  }
}
catch {
  LogRec 'ERROR' 'apply' 'FAILURE' $_.Exception.Message 'LOGIC'
  exit 0
}
finally {
  Remove-Item -Force $LockFile -ErrorAction SilentlyContinue
}
.Exception.Message)" }
}
  Import-Module $ModPath -Force

  # 스모크: 같은 볼륨에 원자 쓰기 → 즉시 삭제
  $smoke = Join-Path $RepoRoot 'webui\public\_klc-smoke.txt'
  $smokeContent = "[klc-smoke] $(Get-Date -Format o)"
  Write-AtomicUtf8 -Path $smoke -Content $smokeContent -Module 'patcher' -Action 'smoke'
  if (Test-Path $smoke) { Remove-Item -LiteralPath $smoke -Force -ErrorAction SilentlyContinue }

  # ── Patch 파일 파싱 ───────────────────────────────────────────────────────────
  $PatchFile = Join-Path $RepoRoot '.kobong\patches.pending.txt'
  if (!(Test-Path $PatchFile)) {
  Write-Host "[SKIP] patches file not found → $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("patches-file-missing: "+$PatchFile) } catch {}
  return
}
  $patchText = Get-Content -LiteralPath $PatchFile -Raw -Encoding UTF8
  $global:patchHash = (Get-FileHash -Algorithm SHA256 -InputStream ([IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes($patchText)))).Hash

  $matches = [regex]::Matches($patchText, '(?ms)#\s*PATCH\s*START\s*(?<body>.*?)#\s*PATCH\s*END')
  if ($matches.Count -eq 0) {
  Write-Host "[SKIP] No PATCH blocks found in $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("no-patch-blocks: "+$PatchFile) } catch {}
  return
}

  $applied = @()
  foreach ($m in $matches) {
    $body = $m.Groups['body'].Value

    $targetRel = [regex]::Match($body, 'TARGET:\s*(?<v>.+)').Groups['v'].Value.Trim()
    $mode      = [regex]::Match($body, 'MODE:\s*(?<v>.+)').Groups['v'].Value.Trim().ToLowerInvariant()
    $find      = [regex]::Match($body, "FIND\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value
    $replace   = [regex]::Match($body, "REPLACE\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value

    if (-not $targetRel) { throw "PATCH missing TARGET" }
    if (-not $mode)      { throw "PATCH missing MODE" }
    if (-not $find)      { throw "PATCH missing FIND" }

    $target = Join-Path $RepoRoot $targetRel
    if (!(Test-Path $target)) {
  Write-Host "[SKIP] TARGET not found → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("target-not-found: "+$targetRel) } catch {}
  continue
}

    $orig = Get-Content -LiteralPath $target -Raw -Encoding UTF8
    $rxOpts = [Text.RegularExpressions.RegexOptions]::Multiline -bor [Text.RegularExpressions.RegexOptions]::Singleline
    $rx = [regex]::new($find, $rxOpts)
    $mt = $rx.Match($orig)
    if (-not $mt.Success) {
  Write-Host "[SKIP] FIND not matched → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("find-not-matched: "+$targetRel) } catch {}
  continue
}

    switch ($mode) {
      'insert-before' {
        $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
      }
      'insert-before' {
  $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
}
'insert-after' {
  $new = $orig.Substring(0, $mt.Index + $mt.Length) + "`n" + $replace + $orig.Substring($mt.Index + $mt.Length)
}
'replace' {
        $new = $rx.Replace($orig, $replace, 1)
      }
      default {
  Write-Host "[SKIP] Unsupported MODE → $mode for $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("unsupported-mode: "+$mode+" for "+$targetRel) } catch {}
  continue
}
    }

    if ($ConfirmApply) {
      $bk = "$target.bak-" + (Get-Date -Format 'yyyyMMdd-HHmmss')
      Copy-Item -LiteralPath $target -Destination $bk -Force
      Write-AtomicUtf8 -Path $target -Content $new -Module 'patcher' -Action ('apply:'+ $mode)
      $applied += $targetRel
    } else {
      Write-Host "[PREVIEW] would patch → $targetRel ($mode)"
    }
  }

  if ($ConfirmApply) {
    LogRec 'INFO' 'apply' 'SUCCESS' ("patched: " + ($applied -join ', '))
  } else {
    LogRec 'INFO' 'preview' 'SUCCESS' ("preview-ok (no writes). blocks="+$matches.Count)
  }

  # ── Gate-3 Verify (경량) ───────────────────────────────────────────────────────
  if ($ConfirmApply) {
    # 핵심 타겟의 구문 일치 재검
    $core = Join-Path $RepoRoot 'scripts\apply_ui_patch.ps1'
    if (Test-Path $core) {
      $c = Get-Content -LiteralPath $core -Raw -Encoding UTF8
      if ($c -notmatch 'ensure valid tmp path .* atomic friendly') {
        Write-Host "[WARN] VERIFY: guard snippet not found in apply_ui_patch.ps1"; try { LogRec "WARN" "verify" "SKIPPED" "guard-missing apply_ui_patch.ps1" } catch {}
      }
    }
  }
}
catch {
  LogRec 'ERROR' 'apply' 'FAILURE' $_.Exception.Message 'LOGIC'
  exit 0
}
finally {
  Remove-Item -Force $LockFile -ErrorAction SilentlyContinue
}
.Exception.Message)" }
  # 스모크: 같은 볼륨에 원자 쓰기 → 즉시 삭제
  $smoke = Join-Path $RepoRoot 'webui\public\_klc-smoke.txt'
  $smokeContent = "[klc-smoke] $(Get-Date -Format o)"
  Write-AtomicUtf8 -Path $smoke -Content $smokeContent -Module 'patcher' -Action 'smoke'
  if (Test-Path $smoke) { Remove-Item -LiteralPath $smoke -Force -ErrorAction SilentlyContinue }

  # ── Patch 파일 파싱 ───────────────────────────────────────────────────────────
  $PatchFile = Join-Path $RepoRoot '.kobong\patches.pending.txt'
  if (!(Test-Path $PatchFile)) {
  Write-Host "[SKIP] patches file not found → $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("patches-file-missing: "+$PatchFile) } catch {}
  return
}
  $patchText = Get-Content -LiteralPath $PatchFile -Raw -Encoding UTF8
  $global:patchHash = (Get-FileHash -Algorithm SHA256 -InputStream ([IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes($patchText)))).Hash

  $matches = [regex]::Matches($patchText, '(?ms)#\s*PATCH\s*START\s*(?<body>.*?)#\s*PATCH\s*END')
  if ($matches.Count -eq 0) {
  Write-Host "[SKIP] No PATCH blocks found in $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("no-patch-blocks: "+$PatchFile) } catch {}
  return
}

  $applied = @()
  foreach ($m in $matches) {
    $body = $m.Groups['body'].Value

    $targetRel = [regex]::Match($body, 'TARGET:\s*(?<v>.+)').Groups['v'].Value.Trim()
    $mode      = [regex]::Match($body, 'MODE:\s*(?<v>.+)').Groups['v'].Value.Trim().ToLowerInvariant()
    $find      = [regex]::Match($body, "FIND\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value
    $replace   = [regex]::Match($body, "REPLACE\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value

    if (-not $targetRel) { throw "PATCH missing TARGET" }
    if (-not $mode)      { throw "PATCH missing MODE" }
    if (-not $find)      { throw "PATCH missing FIND" }

    $target = Join-Path $RepoRoot $targetRel
    if (!(Test-Path $target)) {
  Write-Host "[SKIP] TARGET not found → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("target-not-found: "+$targetRel) } catch {}
  continue
}

    $orig = Get-Content -LiteralPath $target -Raw -Encoding UTF8
    $rxOpts = [Text.RegularExpressions.RegexOptions]::Multiline -bor [Text.RegularExpressions.RegexOptions]::Singleline
    $rx = [regex]::new($find, $rxOpts)
    $mt = $rx.Match($orig)
    if (-not $mt.Success) {
  Write-Host "[SKIP] FIND not matched → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("find-not-matched: "+$targetRel) } catch {}
  continue
}

    switch ($mode) {
      'insert-before' {
        $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
      }
      'insert-before' {
  $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
}
'insert-after' {
  $new = $orig.Substring(0, $mt.Index + $mt.Length) + "`n" + $replace + $orig.Substring($mt.Index + $mt.Length)
}
'replace' {
        $new = $rx.Replace($orig, $replace, 1)
      }
      default {
  Write-Host "[SKIP] Unsupported MODE → $mode for $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("unsupported-mode: "+$mode+" for "+$targetRel) } catch {}
  continue
}
    }

    if ($ConfirmApply) {
      $bk = "$target.bak-" + (Get-Date -Format 'yyyyMMdd-HHmmss')
      Copy-Item -LiteralPath $target -Destination $bk -Force
      Write-AtomicUtf8 -Path $target -Content $new -Module 'patcher' -Action ('apply:'+ $mode)
      $applied += $targetRel
    } else {
      Write-Host "[PREVIEW] would patch → $targetRel ($mode)"
    }
  }

  if ($ConfirmApply) {
    LogRec 'INFO' 'apply' 'SUCCESS' ("patched: " + ($applied -join ', '))
  } else {
    LogRec 'INFO' 'preview' 'SUCCESS' ("preview-ok (no writes). blocks="+$matches.Count)
  }

  # ── Gate-3 Verify (경량) ───────────────────────────────────────────────────────
  if ($ConfirmApply) {
    # 핵심 타겟의 구문 일치 재검
    $core = Join-Path $RepoRoot 'scripts\apply_ui_patch.ps1'
    if (Test-Path $core) {
      $c = Get-Content -LiteralPath $core -Raw -Encoding UTF8
      if ($c -notmatch 'ensure valid tmp path .* atomic friendly') {
        Write-Host "[WARN] VERIFY: guard snippet not found in apply_ui_patch.ps1"; try { LogRec "WARN" "verify" "SKIPPED" "guard-missing apply_ui_patch.ps1" } catch {}
      }
    }
  }
}
catch {
  LogRec 'ERROR' 'apply' 'FAILURE' $_.Exception.Message 'LOGIC'
  exit 0
}
finally {
  Remove-Item -Force $LockFile -ErrorAction SilentlyContinue
}
.Exception.Message) }

# ── Gate-0: Repo / Lock ─────────────────────────────────────────────────────────
function Get-RepoRoot {
  try {
    $p = (git rev-parse --show-toplevel 2>$null)
    if ($p) { return (Resolve-Path $p).Path }
  } catch {}
  if ($Root) { return (Resolve-Path $Root).Path }
  return (Get-Location).Path
}
$RepoRoot = Get-RepoRoot
$LockFile = Join-Path $RepoRoot '.gpt5.lock'
if (Test-Path $LockFile) { Write-Error 'CONFLICT: .gpt5.lock exists.'; exit 11 }
"locked $(Get-Date -Format o)" | Out-File $LockFile -Encoding utf8 -NoNewline

$sw=[Diagnostics.Stopwatch]::StartNew()
$trace=[guid]::NewGuid().ToString()
$logPath = Join-Path $RepoRoot 'logs/apply-log.jsonl'
New-Item -ItemType Directory -Force -Path (Split-Path $logPath) | Out-Null

function LogRec([string]$level,[string]$action,[string]$outcome,[string]$msg,[string]$err='') {
  $rec = @{
    timestamp=(Get-Date).ToString('o'); level=$level; traceId=$trace; module='patcher';
    action=$action; inputHash=((Get-Variable -Name patchHash -Scope Global -ValueOnly -ErrorAction SilentlyContinue) ?? ""); outcome=$outcome;
    durationMs=$sw.ElapsedMilliseconds; errorCode=$err; message=$msg
  } | ConvertTo-Json -Compress
  Add-Content -Path $logPath -Value $rec
}

try {
  # ── Preflight: 모듈 로드 & 스모크 ─────────────────────────────────────────────
  $ModPath = Join-Path $RepoRoot 'scripts\lib\kobong-fileio.psm1'
  if (!(Test-Path $ModPath)) { throw "Missing module: $ModPath" }
try { Import-Module $ModPath -Force } catch { Write-Host "[WARN] Import-Module failed → $ModPath: $(# APPLY IN SHELL
#requires -Version 7.0
param([switch]$ConfirmApply,[string]$Root)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

# ── Gate-0: Repo / Lock ─────────────────────────────────────────────────────────
function Get-RepoRoot {
  try {
    $p = (git rev-parse --show-toplevel 2>$null)
    if ($p) { return (Resolve-Path $p).Path }
  } catch {}
  if ($Root) { return (Resolve-Path $Root).Path }
  return (Get-Location).Path
}
$RepoRoot = Get-RepoRoot
$LockFile = Join-Path $RepoRoot '.gpt5.lock'
if (Test-Path $LockFile) { Write-Error 'CONFLICT: .gpt5.lock exists.'; exit 11 }
"locked $(Get-Date -Format o)" | Out-File $LockFile -Encoding utf8 -NoNewline

$sw=[Diagnostics.Stopwatch]::StartNew()
$trace=[guid]::NewGuid().ToString()
$logPath = Join-Path $RepoRoot 'logs/apply-log.jsonl'
New-Item -ItemType Directory -Force -Path (Split-Path $logPath) | Out-Null

function LogRec([string]$level,[string]$action,[string]$outcome,[string]$msg,[string]$err='') {
  $rec = @{
    timestamp=(Get-Date).ToString('o'); level=$level; traceId=$trace; module='patcher';
    action=$action; inputHash=((Get-Variable -Name patchHash -Scope Global -ValueOnly -ErrorAction SilentlyContinue) ?? ""); outcome=$outcome;
    durationMs=$sw.ElapsedMilliseconds; errorCode=$err; message=$msg
  } | ConvertTo-Json -Compress
  Add-Content -Path $logPath -Value $rec
}

try {
  # ── Preflight: 모듈 로드 & 스모크 ─────────────────────────────────────────────
  $ModPath = Join-Path $RepoRoot 'scripts\lib\kobong-fileio.psm1'
  if (!(Test-Path $ModPath)) { throw "Missing module: $ModPath" }
  Import-Module $ModPath -Force

  # 스모크: 같은 볼륨에 원자 쓰기 → 즉시 삭제
  $smoke = Join-Path $RepoRoot 'webui\public\_klc-smoke.txt'
  $smokeContent = "[klc-smoke] $(Get-Date -Format o)"
  Write-AtomicUtf8 -Path $smoke -Content $smokeContent -Module 'patcher' -Action 'smoke'
  if (Test-Path $smoke) { Remove-Item -LiteralPath $smoke -Force -ErrorAction SilentlyContinue }

  # ── Patch 파일 파싱 ───────────────────────────────────────────────────────────
  $PatchFile = Join-Path $RepoRoot '.kobong\patches.pending.txt'
  if (!(Test-Path $PatchFile)) {
  Write-Host "[SKIP] patches file not found → $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("patches-file-missing: "+$PatchFile) } catch {}
  return
}
  $patchText = Get-Content -LiteralPath $PatchFile -Raw -Encoding UTF8
  $global:patchHash = (Get-FileHash -Algorithm SHA256 -InputStream ([IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes($patchText)))).Hash

  $matches = [regex]::Matches($patchText, '(?ms)#\s*PATCH\s*START\s*(?<body>.*?)#\s*PATCH\s*END')
  if ($matches.Count -eq 0) {
  Write-Host "[SKIP] No PATCH blocks found in $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("no-patch-blocks: "+$PatchFile) } catch {}
  return
}

  $applied = @()
  foreach ($m in $matches) {
    $body = $m.Groups['body'].Value

    $targetRel = [regex]::Match($body, 'TARGET:\s*(?<v>.+)').Groups['v'].Value.Trim()
    $mode      = [regex]::Match($body, 'MODE:\s*(?<v>.+)').Groups['v'].Value.Trim().ToLowerInvariant()
    $find      = [regex]::Match($body, "FIND\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value
    $replace   = [regex]::Match($body, "REPLACE\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value

    if (-not $targetRel) { throw "PATCH missing TARGET" }
    if (-not $mode)      { throw "PATCH missing MODE" }
    if (-not $find)      { throw "PATCH missing FIND" }

    $target = Join-Path $RepoRoot $targetRel
    if (!(Test-Path $target)) {
  Write-Host "[SKIP] TARGET not found → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("target-not-found: "+$targetRel) } catch {}
  continue
}

    $orig = Get-Content -LiteralPath $target -Raw -Encoding UTF8
    $rxOpts = [Text.RegularExpressions.RegexOptions]::Multiline -bor [Text.RegularExpressions.RegexOptions]::Singleline
    $rx = [regex]::new($find, $rxOpts)
    $mt = $rx.Match($orig)
    if (-not $mt.Success) {
  Write-Host "[SKIP] FIND not matched → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("find-not-matched: "+$targetRel) } catch {}
  continue
}

    switch ($mode) {
      'insert-before' {
        $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
      }
      'insert-before' {
  $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
}
'insert-after' {
  $new = $orig.Substring(0, $mt.Index + $mt.Length) + "`n" + $replace + $orig.Substring($mt.Index + $mt.Length)
}
'replace' {
        $new = $rx.Replace($orig, $replace, 1)
      }
      default {
  Write-Host "[SKIP] Unsupported MODE → $mode for $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("unsupported-mode: "+$mode+" for "+$targetRel) } catch {}
  continue
}
    }

    if ($ConfirmApply) {
      $bk = "$target.bak-" + (Get-Date -Format 'yyyyMMdd-HHmmss')
      Copy-Item -LiteralPath $target -Destination $bk -Force
      Write-AtomicUtf8 -Path $target -Content $new -Module 'patcher' -Action ('apply:'+ $mode)
      $applied += $targetRel
    } else {
      Write-Host "[PREVIEW] would patch → $targetRel ($mode)"
    }
  }

  if ($ConfirmApply) {
    LogRec 'INFO' 'apply' 'SUCCESS' ("patched: " + ($applied -join ', '))
  } else {
    LogRec 'INFO' 'preview' 'SUCCESS' ("preview-ok (no writes). blocks="+$matches.Count)
  }

  # ── Gate-3 Verify (경량) ───────────────────────────────────────────────────────
  if ($ConfirmApply) {
    # 핵심 타겟의 구문 일치 재검
    $core = Join-Path $RepoRoot 'scripts\apply_ui_patch.ps1'
    if (Test-Path $core) {
      $c = Get-Content -LiteralPath $core -Raw -Encoding UTF8
      if ($c -notmatch 'ensure valid tmp path .* atomic friendly') {
        Write-Host "[WARN] VERIFY: guard snippet not found in apply_ui_patch.ps1"; try { LogRec "WARN" "verify" "SKIPPED" "guard-missing apply_ui_patch.ps1" } catch {}
      }
    }
  }
}
catch {
  LogRec 'ERROR' 'apply' 'FAILURE' $_.Exception.Message 'LOGIC'
  exit 0
}
finally {
  Remove-Item -Force $LockFile -ErrorAction SilentlyContinue
}
.Exception.Message)" }
  # 스모크: 같은 볼륨에 원자 쓰기 → 즉시 삭제
  $smoke = Join-Path $RepoRoot 'webui\public\_klc-smoke.txt'
  $smokeContent = "[klc-smoke] $(Get-Date -Format o)"
  Write-AtomicUtf8 -Path $smoke -Content $smokeContent -Module 'patcher' -Action 'smoke'
  if (Test-Path $smoke) { Remove-Item -LiteralPath $smoke -Force -ErrorAction SilentlyContinue }

  # ── Patch 파일 파싱 ───────────────────────────────────────────────────────────
  $PatchFile = Join-Path $RepoRoot '.kobong\patches.pending.txt'
  if (!(Test-Path $PatchFile)) {
  Write-Host "[SKIP] patches file not found → $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("patches-file-missing: "+$PatchFile) } catch {}
  return
}
  $patchText = Get-Content -LiteralPath $PatchFile -Raw -Encoding UTF8
  $global:patchHash = (Get-FileHash -Algorithm SHA256 -InputStream ([IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes($patchText)))).Hash

  $matches = [regex]::Matches($patchText, '(?ms)#\s*PATCH\s*START\s*(?<body>.*?)#\s*PATCH\s*END')
  if ($matches.Count -eq 0) {
  Write-Host "[SKIP] No PATCH blocks found in $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("no-patch-blocks: "+$PatchFile) } catch {}
  return
}

  $applied = @()
  foreach ($m in $matches) {
    $body = $m.Groups['body'].Value

    $targetRel = [regex]::Match($body, 'TARGET:\s*(?<v>.+)').Groups['v'].Value.Trim()
    $mode      = [regex]::Match($body, 'MODE:\s*(?<v>.+)').Groups['v'].Value.Trim().ToLowerInvariant()
    $find      = [regex]::Match($body, "FIND\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value
    $replace   = [regex]::Match($body, "REPLACE\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value

    if (-not $targetRel) { throw "PATCH missing TARGET" }
    if (-not $mode)      { throw "PATCH missing MODE" }
    if (-not $find)      { throw "PATCH missing FIND" }

    $target = Join-Path $RepoRoot $targetRel
    if (!(Test-Path $target)) {
  Write-Host "[SKIP] TARGET not found → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("target-not-found: "+$targetRel) } catch {}
  continue
}

    $orig = Get-Content -LiteralPath $target -Raw -Encoding UTF8
    $rxOpts = [Text.RegularExpressions.RegexOptions]::Multiline -bor [Text.RegularExpressions.RegexOptions]::Singleline
    $rx = [regex]::new($find, $rxOpts)
    $mt = $rx.Match($orig)
    if (-not $mt.Success) {
  Write-Host "[SKIP] FIND not matched → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("find-not-matched: "+$targetRel) } catch {}
  continue
}

    switch ($mode) {
      'insert-before' {
        $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
      }
      'insert-before' {
  $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
}
'insert-after' {
  $new = $orig.Substring(0, $mt.Index + $mt.Length) + "`n" + $replace + $orig.Substring($mt.Index + $mt.Length)
}
'replace' {
        $new = $rx.Replace($orig, $replace, 1)
      }
      default {
  Write-Host "[SKIP] Unsupported MODE → $mode for $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("unsupported-mode: "+$mode+" for "+$targetRel) } catch {}
  continue
}
    }

    if ($ConfirmApply) {
      $bk = "$target.bak-" + (Get-Date -Format 'yyyyMMdd-HHmmss')
      Copy-Item -LiteralPath $target -Destination $bk -Force
      Write-AtomicUtf8 -Path $target -Content $new -Module 'patcher' -Action ('apply:'+ $mode)
      $applied += $targetRel
    } else {
      Write-Host "[PREVIEW] would patch → $targetRel ($mode)"
    }
  }

  if ($ConfirmApply) {
    LogRec 'INFO' 'apply' 'SUCCESS' ("patched: " + ($applied -join ', '))
  } else {
    LogRec 'INFO' 'preview' 'SUCCESS' ("preview-ok (no writes). blocks="+$matches.Count)
  }

  # ── Gate-3 Verify (경량) ───────────────────────────────────────────────────────
  if ($ConfirmApply) {
    # 핵심 타겟의 구문 일치 재검
    $core = Join-Path $RepoRoot 'scripts\apply_ui_patch.ps1'
    if (Test-Path $core) {
      $c = Get-Content -LiteralPath $core -Raw -Encoding UTF8
      if ($c -notmatch 'ensure valid tmp path .* atomic friendly') {
        Write-Host "[WARN] VERIFY: guard snippet not found in apply_ui_patch.ps1"; try { LogRec "WARN" "verify" "SKIPPED" "guard-missing apply_ui_patch.ps1" } catch {}
      }
    }
  }
}
catch {
  LogRec 'ERROR' 'apply' 'FAILURE' $_.Exception.Message 'LOGIC'
  exit 0
}
finally {
  Remove-Item -Force $LockFile -ErrorAction SilentlyContinue
}
.Exception.Message)" }
}
try { Import-Module $ModPath -Force } catch { Write-Host "[WARN] Import-Module failed → $ModPath: $(# APPLY IN SHELL
#requires -Version 7.0
param([switch]$ConfirmApply,[string]$Root)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

# ── Gate-0: Repo / Lock ─────────────────────────────────────────────────────────
function Get-RepoRoot {
  try {
    $p = (git rev-parse --show-toplevel 2>$null)
    if ($p) { return (Resolve-Path $p).Path }
  } catch {}
  if ($Root) { return (Resolve-Path $Root).Path }
  return (Get-Location).Path
}
$RepoRoot = Get-RepoRoot
$LockFile = Join-Path $RepoRoot '.gpt5.lock'
if (Test-Path $LockFile) { Write-Error 'CONFLICT: .gpt5.lock exists.'; exit 11 }
"locked $(Get-Date -Format o)" | Out-File $LockFile -Encoding utf8 -NoNewline

$sw=[Diagnostics.Stopwatch]::StartNew()
$trace=[guid]::NewGuid().ToString()
$logPath = Join-Path $RepoRoot 'logs/apply-log.jsonl'
New-Item -ItemType Directory -Force -Path (Split-Path $logPath) | Out-Null

function LogRec([string]$level,[string]$action,[string]$outcome,[string]$msg,[string]$err='') {
  $rec = @{
    timestamp=(Get-Date).ToString('o'); level=$level; traceId=$trace; module='patcher';
    action=$action; inputHash=((Get-Variable -Name patchHash -Scope Global -ValueOnly -ErrorAction SilentlyContinue) ?? ""); outcome=$outcome;
    durationMs=$sw.ElapsedMilliseconds; errorCode=$err; message=$msg
  } | ConvertTo-Json -Compress
  Add-Content -Path $logPath -Value $rec
}

try {
  # ── Preflight: 모듈 로드 & 스모크 ─────────────────────────────────────────────
  $ModPath = Join-Path $RepoRoot 'scripts\lib\kobong-fileio.psm1'
  if (!(Test-Path $ModPath)) {
  Write-Host "[WARN] Missing module → $ModPath (continuing)"
  try { LogRec "WARN" "apply" "SKIPPED" ("missing-module: "+$ModPath) } catch {}
} else {
  try { Import-Module $ModPath -Force } catch { Write-Host "[WARN] Import-Module failed → $ModPath: $(# APPLY IN SHELL
#requires -Version 7.0
param([switch]$ConfirmApply,[string]$Root)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

# ── Gate-0: Repo / Lock ─────────────────────────────────────────────────────────
function Get-RepoRoot {
  try {
    $p = (git rev-parse --show-toplevel 2>$null)
    if ($p) { return (Resolve-Path $p).Path }
  } catch {}
  if ($Root) { return (Resolve-Path $Root).Path }
  return (Get-Location).Path
}
$RepoRoot = Get-RepoRoot
$LockFile = Join-Path $RepoRoot '.gpt5.lock'
if (Test-Path $LockFile) { Write-Error 'CONFLICT: .gpt5.lock exists.'; exit 11 }
"locked $(Get-Date -Format o)" | Out-File $LockFile -Encoding utf8 -NoNewline

$sw=[Diagnostics.Stopwatch]::StartNew()
$trace=[guid]::NewGuid().ToString()
$logPath = Join-Path $RepoRoot 'logs/apply-log.jsonl'
New-Item -ItemType Directory -Force -Path (Split-Path $logPath) | Out-Null

function LogRec([string]$level,[string]$action,[string]$outcome,[string]$msg,[string]$err='') {
  $rec = @{
    timestamp=(Get-Date).ToString('o'); level=$level; traceId=$trace; module='patcher';
    action=$action; inputHash=((Get-Variable -Name patchHash -Scope Global -ValueOnly -ErrorAction SilentlyContinue) ?? ""); outcome=$outcome;
    durationMs=$sw.ElapsedMilliseconds; errorCode=$err; message=$msg
  } | ConvertTo-Json -Compress
  Add-Content -Path $logPath -Value $rec
}

try {
  # ── Preflight: 모듈 로드 & 스모크 ─────────────────────────────────────────────
  $ModPath = Join-Path $RepoRoot 'scripts\lib\kobong-fileio.psm1'
  if (!(Test-Path $ModPath)) { throw "Missing module: $ModPath" }
try { Import-Module $ModPath -Force } catch { Write-Host "[WARN] Import-Module failed → $ModPath: $(# APPLY IN SHELL
#requires -Version 7.0
param([switch]$ConfirmApply,[string]$Root)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

# ── Gate-0: Repo / Lock ─────────────────────────────────────────────────────────
function Get-RepoRoot {
  try {
    $p = (git rev-parse --show-toplevel 2>$null)
    if ($p) { return (Resolve-Path $p).Path }
  } catch {}
  if ($Root) { return (Resolve-Path $Root).Path }
  return (Get-Location).Path
}
$RepoRoot = Get-RepoRoot
$LockFile = Join-Path $RepoRoot '.gpt5.lock'
if (Test-Path $LockFile) { Write-Error 'CONFLICT: .gpt5.lock exists.'; exit 11 }
"locked $(Get-Date -Format o)" | Out-File $LockFile -Encoding utf8 -NoNewline

$sw=[Diagnostics.Stopwatch]::StartNew()
$trace=[guid]::NewGuid().ToString()
$logPath = Join-Path $RepoRoot 'logs/apply-log.jsonl'
New-Item -ItemType Directory -Force -Path (Split-Path $logPath) | Out-Null

function LogRec([string]$level,[string]$action,[string]$outcome,[string]$msg,[string]$err='') {
  $rec = @{
    timestamp=(Get-Date).ToString('o'); level=$level; traceId=$trace; module='patcher';
    action=$action; inputHash=((Get-Variable -Name patchHash -Scope Global -ValueOnly -ErrorAction SilentlyContinue) ?? ""); outcome=$outcome;
    durationMs=$sw.ElapsedMilliseconds; errorCode=$err; message=$msg
  } | ConvertTo-Json -Compress
  Add-Content -Path $logPath -Value $rec
}

try {
  # ── Preflight: 모듈 로드 & 스모크 ─────────────────────────────────────────────
  $ModPath = Join-Path $RepoRoot 'scripts\lib\kobong-fileio.psm1'
  if (!(Test-Path $ModPath)) { throw "Missing module: $ModPath" }
  Import-Module $ModPath -Force

  # 스모크: 같은 볼륨에 원자 쓰기 → 즉시 삭제
  $smoke = Join-Path $RepoRoot 'webui\public\_klc-smoke.txt'
  $smokeContent = "[klc-smoke] $(Get-Date -Format o)"
  Write-AtomicUtf8 -Path $smoke -Content $smokeContent -Module 'patcher' -Action 'smoke'
  if (Test-Path $smoke) { Remove-Item -LiteralPath $smoke -Force -ErrorAction SilentlyContinue }

  # ── Patch 파일 파싱 ───────────────────────────────────────────────────────────
  $PatchFile = Join-Path $RepoRoot '.kobong\patches.pending.txt'
  if (!(Test-Path $PatchFile)) {
  Write-Host "[SKIP] patches file not found → $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("patches-file-missing: "+$PatchFile) } catch {}
  return
}
  $patchText = Get-Content -LiteralPath $PatchFile -Raw -Encoding UTF8
  $global:patchHash = (Get-FileHash -Algorithm SHA256 -InputStream ([IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes($patchText)))).Hash

  $matches = [regex]::Matches($patchText, '(?ms)#\s*PATCH\s*START\s*(?<body>.*?)#\s*PATCH\s*END')
  if ($matches.Count -eq 0) {
  Write-Host "[SKIP] No PATCH blocks found in $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("no-patch-blocks: "+$PatchFile) } catch {}
  return
}

  $applied = @()
  foreach ($m in $matches) {
    $body = $m.Groups['body'].Value

    $targetRel = [regex]::Match($body, 'TARGET:\s*(?<v>.+)').Groups['v'].Value.Trim()
    $mode      = [regex]::Match($body, 'MODE:\s*(?<v>.+)').Groups['v'].Value.Trim().ToLowerInvariant()
    $find      = [regex]::Match($body, "FIND\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value
    $replace   = [regex]::Match($body, "REPLACE\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value

    if (-not $targetRel) { throw "PATCH missing TARGET" }
    if (-not $mode)      { throw "PATCH missing MODE" }
    if (-not $find)      { throw "PATCH missing FIND" }

    $target = Join-Path $RepoRoot $targetRel
    if (!(Test-Path $target)) {
  Write-Host "[SKIP] TARGET not found → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("target-not-found: "+$targetRel) } catch {}
  continue
}

    $orig = Get-Content -LiteralPath $target -Raw -Encoding UTF8
    $rxOpts = [Text.RegularExpressions.RegexOptions]::Multiline -bor [Text.RegularExpressions.RegexOptions]::Singleline
    $rx = [regex]::new($find, $rxOpts)
    $mt = $rx.Match($orig)
    if (-not $mt.Success) {
  Write-Host "[SKIP] FIND not matched → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("find-not-matched: "+$targetRel) } catch {}
  continue
}

    switch ($mode) {
      'insert-before' {
        $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
      }
      'insert-before' {
  $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
}
'insert-after' {
  $new = $orig.Substring(0, $mt.Index + $mt.Length) + "`n" + $replace + $orig.Substring($mt.Index + $mt.Length)
}
'replace' {
        $new = $rx.Replace($orig, $replace, 1)
      }
      default {
  Write-Host "[SKIP] Unsupported MODE → $mode for $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("unsupported-mode: "+$mode+" for "+$targetRel) } catch {}
  continue
}
    }

    if ($ConfirmApply) {
      $bk = "$target.bak-" + (Get-Date -Format 'yyyyMMdd-HHmmss')
      Copy-Item -LiteralPath $target -Destination $bk -Force
      Write-AtomicUtf8 -Path $target -Content $new -Module 'patcher' -Action ('apply:'+ $mode)
      $applied += $targetRel
    } else {
      Write-Host "[PREVIEW] would patch → $targetRel ($mode)"
    }
  }

  if ($ConfirmApply) {
    LogRec 'INFO' 'apply' 'SUCCESS' ("patched: " + ($applied -join ', '))
  } else {
    LogRec 'INFO' 'preview' 'SUCCESS' ("preview-ok (no writes). blocks="+$matches.Count)
  }

  # ── Gate-3 Verify (경량) ───────────────────────────────────────────────────────
  if ($ConfirmApply) {
    # 핵심 타겟의 구문 일치 재검
    $core = Join-Path $RepoRoot 'scripts\apply_ui_patch.ps1'
    if (Test-Path $core) {
      $c = Get-Content -LiteralPath $core -Raw -Encoding UTF8
      if ($c -notmatch 'ensure valid tmp path .* atomic friendly') {
        Write-Host "[WARN] VERIFY: guard snippet not found in apply_ui_patch.ps1"; try { LogRec "WARN" "verify" "SKIPPED" "guard-missing apply_ui_patch.ps1" } catch {}
      }
    }
  }
}
catch {
  LogRec 'ERROR' 'apply' 'FAILURE' $_.Exception.Message 'LOGIC'
  exit 0
}
finally {
  Remove-Item -Force $LockFile -ErrorAction SilentlyContinue
}
.Exception.Message)" }
  # 스모크: 같은 볼륨에 원자 쓰기 → 즉시 삭제
  $smoke = Join-Path $RepoRoot 'webui\public\_klc-smoke.txt'
  $smokeContent = "[klc-smoke] $(Get-Date -Format o)"
  Write-AtomicUtf8 -Path $smoke -Content $smokeContent -Module 'patcher' -Action 'smoke'
  if (Test-Path $smoke) { Remove-Item -LiteralPath $smoke -Force -ErrorAction SilentlyContinue }

  # ── Patch 파일 파싱 ───────────────────────────────────────────────────────────
  $PatchFile = Join-Path $RepoRoot '.kobong\patches.pending.txt'
  if (!(Test-Path $PatchFile)) {
  Write-Host "[SKIP] patches file not found → $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("patches-file-missing: "+$PatchFile) } catch {}
  return
}
  $patchText = Get-Content -LiteralPath $PatchFile -Raw -Encoding UTF8
  $global:patchHash = (Get-FileHash -Algorithm SHA256 -InputStream ([IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes($patchText)))).Hash

  $matches = [regex]::Matches($patchText, '(?ms)#\s*PATCH\s*START\s*(?<body>.*?)#\s*PATCH\s*END')
  if ($matches.Count -eq 0) {
  Write-Host "[SKIP] No PATCH blocks found in $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("no-patch-blocks: "+$PatchFile) } catch {}
  return
}

  $applied = @()
  foreach ($m in $matches) {
    $body = $m.Groups['body'].Value

    $targetRel = [regex]::Match($body, 'TARGET:\s*(?<v>.+)').Groups['v'].Value.Trim()
    $mode      = [regex]::Match($body, 'MODE:\s*(?<v>.+)').Groups['v'].Value.Trim().ToLowerInvariant()
    $find      = [regex]::Match($body, "FIND\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value
    $replace   = [regex]::Match($body, "REPLACE\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value

    if (-not $targetRel) { throw "PATCH missing TARGET" }
    if (-not $mode)      { throw "PATCH missing MODE" }
    if (-not $find)      { throw "PATCH missing FIND" }

    $target = Join-Path $RepoRoot $targetRel
    if (!(Test-Path $target)) {
  Write-Host "[SKIP] TARGET not found → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("target-not-found: "+$targetRel) } catch {}
  continue
}

    $orig = Get-Content -LiteralPath $target -Raw -Encoding UTF8
    $rxOpts = [Text.RegularExpressions.RegexOptions]::Multiline -bor [Text.RegularExpressions.RegexOptions]::Singleline
    $rx = [regex]::new($find, $rxOpts)
    $mt = $rx.Match($orig)
    if (-not $mt.Success) {
  Write-Host "[SKIP] FIND not matched → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("find-not-matched: "+$targetRel) } catch {}
  continue
}

    switch ($mode) {
      'insert-before' {
        $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
      }
      'insert-before' {
  $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
}
'insert-after' {
  $new = $orig.Substring(0, $mt.Index + $mt.Length) + "`n" + $replace + $orig.Substring($mt.Index + $mt.Length)
}
'replace' {
        $new = $rx.Replace($orig, $replace, 1)
      }
      default {
  Write-Host "[SKIP] Unsupported MODE → $mode for $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("unsupported-mode: "+$mode+" for "+$targetRel) } catch {}
  continue
}
    }

    if ($ConfirmApply) {
      $bk = "$target.bak-" + (Get-Date -Format 'yyyyMMdd-HHmmss')
      Copy-Item -LiteralPath $target -Destination $bk -Force
      Write-AtomicUtf8 -Path $target -Content $new -Module 'patcher' -Action ('apply:'+ $mode)
      $applied += $targetRel
    } else {
      Write-Host "[PREVIEW] would patch → $targetRel ($mode)"
    }
  }

  if ($ConfirmApply) {
    LogRec 'INFO' 'apply' 'SUCCESS' ("patched: " + ($applied -join ', '))
  } else {
    LogRec 'INFO' 'preview' 'SUCCESS' ("preview-ok (no writes). blocks="+$matches.Count)
  }

  # ── Gate-3 Verify (경량) ───────────────────────────────────────────────────────
  if ($ConfirmApply) {
    # 핵심 타겟의 구문 일치 재검
    $core = Join-Path $RepoRoot 'scripts\apply_ui_patch.ps1'
    if (Test-Path $core) {
      $c = Get-Content -LiteralPath $core -Raw -Encoding UTF8
      if ($c -notmatch 'ensure valid tmp path .* atomic friendly') {
        Write-Host "[WARN] VERIFY: guard snippet not found in apply_ui_patch.ps1"; try { LogRec "WARN" "verify" "SKIPPED" "guard-missing apply_ui_patch.ps1" } catch {}
      }
    }
  }
}
catch {
  LogRec 'ERROR' 'apply' 'FAILURE' $_.Exception.Message 'LOGIC'
  exit 0
}
finally {
  Remove-Item -Force $LockFile -ErrorAction SilentlyContinue
}
.Exception.Message)" }
}
  Import-Module $ModPath -Force

  # 스모크: 같은 볼륨에 원자 쓰기 → 즉시 삭제
  $smoke = Join-Path $RepoRoot 'webui\public\_klc-smoke.txt'
  $smokeContent = "[klc-smoke] $(Get-Date -Format o)"
  Write-AtomicUtf8 -Path $smoke -Content $smokeContent -Module 'patcher' -Action 'smoke'
  if (Test-Path $smoke) { Remove-Item -LiteralPath $smoke -Force -ErrorAction SilentlyContinue }

  # ── Patch 파일 파싱 ───────────────────────────────────────────────────────────
  $PatchFile = Join-Path $RepoRoot '.kobong\patches.pending.txt'
  if (!(Test-Path $PatchFile)) {
  Write-Host "[SKIP] patches file not found → $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("patches-file-missing: "+$PatchFile) } catch {}
  return
}
  $patchText = Get-Content -LiteralPath $PatchFile -Raw -Encoding UTF8
  $global:patchHash = (Get-FileHash -Algorithm SHA256 -InputStream ([IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes($patchText)))).Hash

  $matches = [regex]::Matches($patchText, '(?ms)#\s*PATCH\s*START\s*(?<body>.*?)#\s*PATCH\s*END')
  if ($matches.Count -eq 0) {
  Write-Host "[SKIP] No PATCH blocks found in $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("no-patch-blocks: "+$PatchFile) } catch {}
  return
}

  $applied = @()
  foreach ($m in $matches) {
    $body = $m.Groups['body'].Value

    $targetRel = [regex]::Match($body, 'TARGET:\s*(?<v>.+)').Groups['v'].Value.Trim()
    $mode      = [regex]::Match($body, 'MODE:\s*(?<v>.+)').Groups['v'].Value.Trim().ToLowerInvariant()
    $find      = [regex]::Match($body, "FIND\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value
    $replace   = [regex]::Match($body, "REPLACE\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value

    if (-not $targetRel) { throw "PATCH missing TARGET" }
    if (-not $mode)      { throw "PATCH missing MODE" }
    if (-not $find)      { throw "PATCH missing FIND" }

    $target = Join-Path $RepoRoot $targetRel
    if (!(Test-Path $target)) {
  Write-Host "[SKIP] TARGET not found → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("target-not-found: "+$targetRel) } catch {}
  continue
}

    $orig = Get-Content -LiteralPath $target -Raw -Encoding UTF8
    $rxOpts = [Text.RegularExpressions.RegexOptions]::Multiline -bor [Text.RegularExpressions.RegexOptions]::Singleline
    $rx = [regex]::new($find, $rxOpts)
    $mt = $rx.Match($orig)
    if (-not $mt.Success) {
  Write-Host "[SKIP] FIND not matched → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("find-not-matched: "+$targetRel) } catch {}
  continue
}

    switch ($mode) {
      'insert-before' {
        $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
      }
      'insert-before' {
  $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
}
'insert-after' {
  $new = $orig.Substring(0, $mt.Index + $mt.Length) + "`n" + $replace + $orig.Substring($mt.Index + $mt.Length)
}
'replace' {
        $new = $rx.Replace($orig, $replace, 1)
      }
      default {
  Write-Host "[SKIP] Unsupported MODE → $mode for $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("unsupported-mode: "+$mode+" for "+$targetRel) } catch {}
  continue
}
    }

    if ($ConfirmApply) {
      $bk = "$target.bak-" + (Get-Date -Format 'yyyyMMdd-HHmmss')
      Copy-Item -LiteralPath $target -Destination $bk -Force
      Write-AtomicUtf8 -Path $target -Content $new -Module 'patcher' -Action ('apply:'+ $mode)
      $applied += $targetRel
    } else {
      Write-Host "[PREVIEW] would patch → $targetRel ($mode)"
    }
  }

  if ($ConfirmApply) {
    LogRec 'INFO' 'apply' 'SUCCESS' ("patched: " + ($applied -join ', '))
  } else {
    LogRec 'INFO' 'preview' 'SUCCESS' ("preview-ok (no writes). blocks="+$matches.Count)
  }

  # ── Gate-3 Verify (경량) ───────────────────────────────────────────────────────
  if ($ConfirmApply) {
    # 핵심 타겟의 구문 일치 재검
    $core = Join-Path $RepoRoot 'scripts\apply_ui_patch.ps1'
    if (Test-Path $core) {
      $c = Get-Content -LiteralPath $core -Raw -Encoding UTF8
      if ($c -notmatch 'ensure valid tmp path .* atomic friendly') {
        Write-Host "[WARN] VERIFY: guard snippet not found in apply_ui_patch.ps1"; try { LogRec "WARN" "verify" "SKIPPED" "guard-missing apply_ui_patch.ps1" } catch {}
      }
    }
  }
}
catch {
  LogRec 'ERROR' 'apply' 'FAILURE' $_.Exception.Message 'LOGIC'
  exit 0
}
finally {
  Remove-Item -Force $LockFile -ErrorAction SilentlyContinue
}
.Exception.Message)" }
  # 스모크: 같은 볼륨에 원자 쓰기 → 즉시 삭제
  $smoke = Join-Path $RepoRoot 'webui\public\_klc-smoke.txt'
  $smokeContent = "[klc-smoke] $(Get-Date -Format o)"
  Write-AtomicUtf8 -Path $smoke -Content $smokeContent -Module 'patcher' -Action 'smoke'
  if (Test-Path $smoke) { Remove-Item -LiteralPath $smoke -Force -ErrorAction SilentlyContinue }

  # ── Patch 파일 파싱 ───────────────────────────────────────────────────────────
  $PatchFile = Join-Path $RepoRoot '.kobong\patches.pending.txt'
  if (!(Test-Path $PatchFile)) {
  Write-Host "[SKIP] patches file not found → $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("patches-file-missing: "+$PatchFile) } catch {}
  return
}
  $patchText = Get-Content -LiteralPath $PatchFile -Raw -Encoding UTF8
  $global:patchHash = (Get-FileHash -Algorithm SHA256 -InputStream ([IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes($patchText)))).Hash

  $matches = [regex]::Matches($patchText, '(?ms)#\s*PATCH\s*START\s*(?<body>.*?)#\s*PATCH\s*END')
  if ($matches.Count -eq 0) {
  Write-Host "[SKIP] No PATCH blocks found in $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("no-patch-blocks: "+$PatchFile) } catch {}
  return
}

  $applied = @()
  foreach ($m in $matches) {
    $body = $m.Groups['body'].Value

    $targetRel = [regex]::Match($body, 'TARGET:\s*(?<v>.+)').Groups['v'].Value.Trim()
    $mode      = [regex]::Match($body, 'MODE:\s*(?<v>.+)').Groups['v'].Value.Trim().ToLowerInvariant()
    $find      = [regex]::Match($body, "FIND\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value
    $replace   = [regex]::Match($body, "REPLACE\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value

    if (-not $targetRel) { throw "PATCH missing TARGET" }
    if (-not $mode)      { throw "PATCH missing MODE" }
    if (-not $find)      { throw "PATCH missing FIND" }

    $target = Join-Path $RepoRoot $targetRel
    if (!(Test-Path $target)) {
  Write-Host "[SKIP] TARGET not found → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("target-not-found: "+$targetRel) } catch {}
  continue
}

    $orig = Get-Content -LiteralPath $target -Raw -Encoding UTF8
    $rxOpts = [Text.RegularExpressions.RegexOptions]::Multiline -bor [Text.RegularExpressions.RegexOptions]::Singleline
    $rx = [regex]::new($find, $rxOpts)
    $mt = $rx.Match($orig)
    if (-not $mt.Success) {
  Write-Host "[SKIP] FIND not matched → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("find-not-matched: "+$targetRel) } catch {}
  continue
}

    switch ($mode) {
      'insert-before' {
        $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
      }
      'insert-before' {
  $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
}
'insert-after' {
  $new = $orig.Substring(0, $mt.Index + $mt.Length) + "`n" + $replace + $orig.Substring($mt.Index + $mt.Length)
}
'replace' {
        $new = $rx.Replace($orig, $replace, 1)
      }
      default {
  Write-Host "[SKIP] Unsupported MODE → $mode for $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("unsupported-mode: "+$mode+" for "+$targetRel) } catch {}
  continue
}
    }

    if ($ConfirmApply) {
      $bk = "$target.bak-" + (Get-Date -Format 'yyyyMMdd-HHmmss')
      Copy-Item -LiteralPath $target -Destination $bk -Force
      Write-AtomicUtf8 -Path $target -Content $new -Module 'patcher' -Action ('apply:'+ $mode)
      $applied += $targetRel
    } else {
      Write-Host "[PREVIEW] would patch → $targetRel ($mode)"
    }
  }

  if ($ConfirmApply) {
    LogRec 'INFO' 'apply' 'SUCCESS' ("patched: " + ($applied -join ', '))
  } else {
    LogRec 'INFO' 'preview' 'SUCCESS' ("preview-ok (no writes). blocks="+$matches.Count)
  }

  # ── Gate-3 Verify (경량) ───────────────────────────────────────────────────────
  if ($ConfirmApply) {
    # 핵심 타겟의 구문 일치 재검
    $core = Join-Path $RepoRoot 'scripts\apply_ui_patch.ps1'
    if (Test-Path $core) {
      $c = Get-Content -LiteralPath $core -Raw -Encoding UTF8
      if ($c -notmatch 'ensure valid tmp path .* atomic friendly') {
        Write-Host "[WARN] VERIFY: guard snippet not found in apply_ui_patch.ps1"; try { LogRec "WARN" "verify" "SKIPPED" "guard-missing apply_ui_patch.ps1" } catch {}
      }
    }
  }
}
catch {
  LogRec 'ERROR' 'apply' 'FAILURE' $_.Exception.Message 'LOGIC'
  exit 0
}
finally {
  Remove-Item -Force $LockFile -ErrorAction SilentlyContinue
}
.Exception.Message) }
  # 스모크: 같은 볼륨에 원자 쓰기 → 즉시 삭제
  $smoke = Join-Path $RepoRoot 'webui\public\_klc-smoke.txt'
  $smokeContent = "[klc-smoke] $(Get-Date -Format o)"
  Write-AtomicUtf8 -Path $smoke -Content $smokeContent -Module 'patcher' -Action 'smoke'
  if (Test-Path $smoke) { Remove-Item -LiteralPath $smoke -Force -ErrorAction SilentlyContinue }

  # ── Patch 파일 파싱 ───────────────────────────────────────────────────────────
  $PatchFile = Join-Path $RepoRoot '.kobong\patches.pending.txt'
  if (!(Test-Path $PatchFile)) {
  Write-Host "[SKIP] patches file not found → $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("patches-file-missing: "+$PatchFile) } catch {}
  return
}
  $patchText = Get-Content -LiteralPath $PatchFile -Raw -Encoding UTF8
  $global:patchHash = (Get-FileHash -Algorithm SHA256 -InputStream ([IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes($patchText)))).Hash

  $matches = [regex]::Matches($patchText, '(?ms)#\s*PATCH\s*START\s*(?<body>.*?)#\s*PATCH\s*END')
  if ($matches.Count -eq 0) {
  Write-Host "[SKIP] No PATCH blocks found in $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("no-patch-blocks: "+$PatchFile) } catch {}
  return
}

  $applied = @()
  foreach ($m in $matches) {
    $body = $m.Groups['body'].Value

    $targetRel = [regex]::Match($body, 'TARGET:\s*(?<v>.+)').Groups['v'].Value.Trim()
    $mode      = [regex]::Match($body, 'MODE:\s*(?<v>.+)').Groups['v'].Value.Trim().ToLowerInvariant()
    $find      = [regex]::Match($body, "FIND\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value
    $replace   = [regex]::Match($body, "REPLACE\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value

    if (-not $targetRel) { throw "PATCH missing TARGET" }
    if (-not $mode)      { throw "PATCH missing MODE" }
    if (-not $find)      { throw "PATCH missing FIND" }

    $target = Join-Path $RepoRoot $targetRel
    if (!(Test-Path $target)) {
  Write-Host "[SKIP] TARGET not found → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("target-not-found: "+$targetRel) } catch {}
  continue
}

    $orig = Get-Content -LiteralPath $target -Raw -Encoding UTF8
    $rxOpts = [Text.RegularExpressions.RegexOptions]::Multiline -bor [Text.RegularExpressions.RegexOptions]::Singleline
    $rx = [regex]::new($find, $rxOpts)
    $mt = $rx.Match($orig)
    if (-not $mt.Success) {
  Write-Host "[SKIP] FIND not matched → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("find-not-matched: "+$targetRel) } catch {}
  continue
}

    switch ($mode) {
      'insert-before' {
        $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
      }
      'insert-before' {
  $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
}
'insert-after' {
  $new = $orig.Substring(0, $mt.Index + $mt.Length) + "`n" + $replace + $orig.Substring($mt.Index + $mt.Length)
}
'replace' {
        $new = $rx.Replace($orig, $replace, 1)
      }
      default {
  Write-Host "[SKIP] Unsupported MODE → $mode for $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("unsupported-mode: "+$mode+" for "+$targetRel) } catch {}
  continue
}
    }

    if ($ConfirmApply) {
      $bk = "$target.bak-" + (Get-Date -Format 'yyyyMMdd-HHmmss')
      Copy-Item -LiteralPath $target -Destination $bk -Force
      Write-AtomicUtf8 -Path $target -Content $new -Module 'patcher' -Action ('apply:'+ $mode)
      $applied += $targetRel
    } else {
      Write-Host "[PREVIEW] would patch → $targetRel ($mode)"
    }
  }

  if ($ConfirmApply) {
    LogRec 'INFO' 'apply' 'SUCCESS' ("patched: " + ($applied -join ', '))
  } else {
    LogRec 'INFO' 'preview' 'SUCCESS' ("preview-ok (no writes). blocks="+$matches.Count)
  }

  # ── Gate-3 Verify (경량) ───────────────────────────────────────────────────────
  if ($ConfirmApply) {
    # 핵심 타겟의 구문 일치 재검
    $core = Join-Path $RepoRoot 'scripts\apply_ui_patch.ps1'
    if (Test-Path $core) {
      $c = Get-Content -LiteralPath $core -Raw -Encoding UTF8
      if ($c -notmatch 'ensure valid tmp path .* atomic friendly') {
        Write-Host "[WARN] VERIFY: guard snippet not found in apply_ui_patch.ps1"; try { LogRec "WARN" "verify" "SKIPPED" "guard-missing apply_ui_patch.ps1" } catch {}
      }
    }
  }
}
catch {
  LogRec 'ERROR' 'apply' 'FAILURE' $_.Exception.Message 'LOGIC'
  exit 0
}
finally {
  Remove-Item -Force $LockFile -ErrorAction SilentlyContinue
}
.Exception.Message)" }
  # 스모크: 같은 볼륨에 원자 쓰기 → 즉시 삭제
  $smoke = Join-Path $RepoRoot 'webui\public\_klc-smoke.txt'
  $smokeContent = "[klc-smoke] $(Get-Date -Format o)"
  Write-AtomicUtf8 -Path $smoke -Content $smokeContent -Module 'patcher' -Action 'smoke'
  if (Test-Path $smoke) { Remove-Item -LiteralPath $smoke -Force -ErrorAction SilentlyContinue }

  # ── Patch 파일 파싱 ───────────────────────────────────────────────────────────
  $PatchFile = Join-Path $RepoRoot '.kobong\patches.pending.txt'
  if (!(Test-Path $PatchFile)) {
  Write-Host "[SKIP] patches file not found → $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("patches-file-missing: "+$PatchFile) } catch {}
  return
}
  $patchText = Get-Content -LiteralPath $PatchFile -Raw -Encoding UTF8
  $global:patchHash = (Get-FileHash -Algorithm SHA256 -InputStream ([IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes($patchText)))).Hash

  $matches = [regex]::Matches($patchText, '(?ms)#\s*PATCH\s*START\s*(?<body>.*?)#\s*PATCH\s*END')
  if ($matches.Count -eq 0) {
  Write-Host "[SKIP] No PATCH blocks found in $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("no-patch-blocks: "+$PatchFile) } catch {}
  return
}

  $applied = @()
  foreach ($m in $matches) {
    $body = $m.Groups['body'].Value

    $targetRel = [regex]::Match($body, 'TARGET:\s*(?<v>.+)').Groups['v'].Value.Trim()
    $mode      = [regex]::Match($body, 'MODE:\s*(?<v>.+)').Groups['v'].Value.Trim().ToLowerInvariant()
    $find      = [regex]::Match($body, "FIND\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value
    $replace   = [regex]::Match($body, "REPLACE\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value

    if (-not $targetRel) { throw "PATCH missing TARGET" }
    if (-not $mode)      { throw "PATCH missing MODE" }
    if (-not $find)      { throw "PATCH missing FIND" }

    $target = Join-Path $RepoRoot $targetRel
    if (!(Test-Path $target)) {
  Write-Host "[SKIP] TARGET not found → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("target-not-found: "+$targetRel) } catch {}
  continue
}

    $orig = Get-Content -LiteralPath $target -Raw -Encoding UTF8
    $rxOpts = [Text.RegularExpressions.RegexOptions]::Multiline -bor [Text.RegularExpressions.RegexOptions]::Singleline
    $rx = [regex]::new($find, $rxOpts)
    $mt = $rx.Match($orig)
    if (-not $mt.Success) {
  Write-Host "[SKIP] FIND not matched → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("find-not-matched: "+$targetRel) } catch {}
  continue
}

    switch ($mode) {
      'insert-before' {
        $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
      }
      'insert-before' {
  $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
}
'insert-after' {
  $new = $orig.Substring(0, $mt.Index + $mt.Length) + "`n" + $replace + $orig.Substring($mt.Index + $mt.Length)
}
'replace' {
        $new = $rx.Replace($orig, $replace, 1)
      }
      default {
  Write-Host "[SKIP] Unsupported MODE → $mode for $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("unsupported-mode: "+$mode+" for "+$targetRel) } catch {}
  continue
}
    }

    if ($ConfirmApply) {
      $bk = "$target.bak-" + (Get-Date -Format 'yyyyMMdd-HHmmss')
      Copy-Item -LiteralPath $target -Destination $bk -Force
      Write-AtomicUtf8 -Path $target -Content $new -Module 'patcher' -Action ('apply:'+ $mode)
      $applied += $targetRel
    } else {
      Write-Host "[PREVIEW] would patch → $targetRel ($mode)"
    }
  }

  if ($ConfirmApply) {
    LogRec 'INFO' 'apply' 'SUCCESS' ("patched: " + ($applied -join ', '))
  } else {
    LogRec 'INFO' 'preview' 'SUCCESS' ("preview-ok (no writes). blocks="+$matches.Count)
  }

  # ── Gate-3 Verify (경량) ───────────────────────────────────────────────────────
  if ($ConfirmApply) {
    # 핵심 타겟의 구문 일치 재검
    $core = Join-Path $RepoRoot 'scripts\apply_ui_patch.ps1'
    if (Test-Path $core) {
      $c = Get-Content -LiteralPath $core -Raw -Encoding UTF8
      if ($c -notmatch 'ensure valid tmp path .* atomic friendly') {
        Write-Host "[WARN] VERIFY: guard snippet not found in apply_ui_patch.ps1"; try { LogRec "WARN" "verify" "SKIPPED" "guard-missing apply_ui_patch.ps1" } catch {}
      }
    }
  }
}
catch {
  LogRec 'ERROR' 'apply' 'FAILURE' $_.Exception.Message 'LOGIC'
  exit 0
}
finally {
  Remove-Item -Force $LockFile -ErrorAction SilentlyContinue
}
.Exception.Message) }

# ── Gate-0: Repo / Lock ─────────────────────────────────────────────────────────
function Get-RepoRoot {
  try {
    $p = (git rev-parse --show-toplevel 2>$null)
    if ($p) { return (Resolve-Path $p).Path }
  } catch {}
  if ($Root) { return (Resolve-Path $Root).Path }
  return (Get-Location).Path
}
$RepoRoot = Get-RepoRoot
$LockFile = Join-Path $RepoRoot '.gpt5.lock'
if (Test-Path $LockFile) { Write-Error 'CONFLICT: .gpt5.lock exists.'; exit 11 }
"locked $(Get-Date -Format o)" | Out-File $LockFile -Encoding utf8 -NoNewline

$sw=[Diagnostics.Stopwatch]::StartNew()
$trace=[guid]::NewGuid().ToString()
$logPath = Join-Path $RepoRoot 'logs/apply-log.jsonl'
New-Item -ItemType Directory -Force -Path (Split-Path $logPath) | Out-Null

function LogRec([string]$level,[string]$action,[string]$outcome,[string]$msg,[string]$err='') {
  $rec = @{
    timestamp=(Get-Date).ToString('o'); level=$level; traceId=$trace; module='patcher';
    action=$action; inputHash=((Get-Variable -Name patchHash -Scope Global -ValueOnly -ErrorAction SilentlyContinue) ?? ""); outcome=$outcome;
    durationMs=$sw.ElapsedMilliseconds; errorCode=$err; message=$msg
  } | ConvertTo-Json -Compress
  Add-Content -Path $logPath -Value $rec
}

try {
  # ── Preflight: 모듈 로드 & 스모크 ─────────────────────────────────────────────
  $ModPath = Join-Path $RepoRoot 'scripts\lib\kobong-fileio.psm1'
  if (!(Test-Path $ModPath)) { throw "Missing module: $ModPath" }
try { Import-Module $ModPath -Force } catch { Write-Host "[WARN] Import-Module failed → $ModPath: $(# APPLY IN SHELL
#requires -Version 7.0
param([switch]$ConfirmApply,[string]$Root)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

# ── Gate-0: Repo / Lock ─────────────────────────────────────────────────────────
function Get-RepoRoot {
  try {
    $p = (git rev-parse --show-toplevel 2>$null)
    if ($p) { return (Resolve-Path $p).Path }
  } catch {}
  if ($Root) { return (Resolve-Path $Root).Path }
  return (Get-Location).Path
}
$RepoRoot = Get-RepoRoot
$LockFile = Join-Path $RepoRoot '.gpt5.lock'
if (Test-Path $LockFile) { Write-Error 'CONFLICT: .gpt5.lock exists.'; exit 11 }
"locked $(Get-Date -Format o)" | Out-File $LockFile -Encoding utf8 -NoNewline

$sw=[Diagnostics.Stopwatch]::StartNew()
$trace=[guid]::NewGuid().ToString()
$logPath = Join-Path $RepoRoot 'logs/apply-log.jsonl'
New-Item -ItemType Directory -Force -Path (Split-Path $logPath) | Out-Null

function LogRec([string]$level,[string]$action,[string]$outcome,[string]$msg,[string]$err='') {
  $rec = @{
    timestamp=(Get-Date).ToString('o'); level=$level; traceId=$trace; module='patcher';
    action=$action; inputHash=((Get-Variable -Name patchHash -Scope Global -ValueOnly -ErrorAction SilentlyContinue) ?? ""); outcome=$outcome;
    durationMs=$sw.ElapsedMilliseconds; errorCode=$err; message=$msg
  } | ConvertTo-Json -Compress
  Add-Content -Path $logPath -Value $rec
}

try {
  # ── Preflight: 모듈 로드 & 스모크 ─────────────────────────────────────────────
  $ModPath = Join-Path $RepoRoot 'scripts\lib\kobong-fileio.psm1'
  if (!(Test-Path $ModPath)) { throw "Missing module: $ModPath" }
try { Import-Module $ModPath -Force } catch { Write-Host ("[WARN] Import-Module failed -> " + $ModPath + ": " + # APPLY IN SHELL
#requires -Version 7.0
param([switch]$ConfirmApply,[string]$Root)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

# ── Gate-0: Repo / Lock ─────────────────────────────────────────────────────────
function Get-RepoRoot {
  try {
    $p = (git rev-parse --show-toplevel 2>$null)
    if ($p) { return (Resolve-Path $p).Path }
  } catch {}
  if ($Root) { return (Resolve-Path $Root).Path }
  return (Get-Location).Path
}
$RepoRoot = Get-RepoRoot
$LockFile = Join-Path $RepoRoot '.gpt5.lock'
if (Test-Path $LockFile) { Write-Error 'CONFLICT: .gpt5.lock exists.'; exit 11 }
"locked $(Get-Date -Format o)" | Out-File $LockFile -Encoding utf8 -NoNewline

$sw=[Diagnostics.Stopwatch]::StartNew()
$trace=[guid]::NewGuid().ToString()
$logPath = Join-Path $RepoRoot 'logs/apply-log.jsonl'
New-Item -ItemType Directory -Force -Path (Split-Path $logPath) | Out-Null

function LogRec([string]$level,[string]$action,[string]$outcome,[string]$msg,[string]$err='') {
  $rec = @{
    timestamp=(Get-Date).ToString('o'); level=$level; traceId=$trace; module='patcher';
    action=$action; inputHash=((Get-Variable -Name patchHash -Scope Global -ValueOnly -ErrorAction SilentlyContinue) ?? ""); outcome=$outcome;
    durationMs=$sw.ElapsedMilliseconds; errorCode=$err; message=$msg
  } | ConvertTo-Json -Compress
  Add-Content -Path $logPath -Value $rec
}

try {
  # ── Preflight: 모듈 로드 & 스모크 ─────────────────────────────────────────────
  $ModPath = Join-Path $RepoRoot 'scripts\lib\kobong-fileio.psm1'
  if (!(Test-Path $ModPath)) {
  Write-Host "[WARN] Missing module → $ModPath (continuing)"
  try { LogRec "WARN" "apply" "SKIPPED" ("missing-module: "+$ModPath) } catch {}
} else {
  try { Import-Module $ModPath -Force } catch { Write-Host ("[WARN] Import-Module failed -> " + $ModPath + ": " + # APPLY IN SHELL
#requires -Version 7.0
param([switch]$ConfirmApply,[string]$Root)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

# ── Gate-0: Repo / Lock ─────────────────────────────────────────────────────────
function Get-RepoRoot {
  try {
    $p = (git rev-parse --show-toplevel 2>$null)
    if ($p) { return (Resolve-Path $p).Path }
  } catch {}
  if ($Root) { return (Resolve-Path $Root).Path }
  return (Get-Location).Path
}
$RepoRoot = Get-RepoRoot
$LockFile = Join-Path $RepoRoot '.gpt5.lock'
if (Test-Path $LockFile) { Write-Error 'CONFLICT: .gpt5.lock exists.'; exit 11 }
"locked $(Get-Date -Format o)" | Out-File $LockFile -Encoding utf8 -NoNewline

$sw=[Diagnostics.Stopwatch]::StartNew()
$trace=[guid]::NewGuid().ToString()
$logPath = Join-Path $RepoRoot 'logs/apply-log.jsonl'
New-Item -ItemType Directory -Force -Path (Split-Path $logPath) | Out-Null

function LogRec([string]$level,[string]$action,[string]$outcome,[string]$msg,[string]$err='') {
  $rec = @{
    timestamp=(Get-Date).ToString('o'); level=$level; traceId=$trace; module='patcher';
    action=$action; inputHash=((Get-Variable -Name patchHash -Scope Global -ValueOnly -ErrorAction SilentlyContinue) ?? ""); outcome=$outcome;
    durationMs=$sw.ElapsedMilliseconds; errorCode=$err; message=$msg
  } | ConvertTo-Json -Compress
  Add-Content -Path $logPath -Value $rec
}

try {
  # ── Preflight: 모듈 로드 & 스모크 ─────────────────────────────────────────────
  $ModPath = Join-Path $RepoRoot 'scripts\lib\kobong-fileio.psm1'
  if (!(Test-Path $ModPath)) {
  Write-Host "[WARN] Missing module → $ModPath (continuing)"
  try { LogRec "WARN" "apply" "SKIPPED" ("missing-module: "+$ModPath) } catch {}
} else {
  try { Import-Module $ModPath -Force } catch { Write-Host "[WARN] Import-Module failed → $ModPath: $(# APPLY IN SHELL
#requires -Version 7.0
param([switch]$ConfirmApply,[string]$Root)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

# ── Gate-0: Repo / Lock ─────────────────────────────────────────────────────────
function Get-RepoRoot {
  try {
    $p = (git rev-parse --show-toplevel 2>$null)
    if ($p) { return (Resolve-Path $p).Path }
  } catch {}
  if ($Root) { return (Resolve-Path $Root).Path }
  return (Get-Location).Path
}
$RepoRoot = Get-RepoRoot
$LockFile = Join-Path $RepoRoot '.gpt5.lock'
if (Test-Path $LockFile) { Write-Error 'CONFLICT: .gpt5.lock exists.'; exit 11 }
"locked $(Get-Date -Format o)" | Out-File $LockFile -Encoding utf8 -NoNewline

$sw=[Diagnostics.Stopwatch]::StartNew()
$trace=[guid]::NewGuid().ToString()
$logPath = Join-Path $RepoRoot 'logs/apply-log.jsonl'
New-Item -ItemType Directory -Force -Path (Split-Path $logPath) | Out-Null

function LogRec([string]$level,[string]$action,[string]$outcome,[string]$msg,[string]$err='') {
  $rec = @{
    timestamp=(Get-Date).ToString('o'); level=$level; traceId=$trace; module='patcher';
    action=$action; inputHash=((Get-Variable -Name patchHash -Scope Global -ValueOnly -ErrorAction SilentlyContinue) ?? ""); outcome=$outcome;
    durationMs=$sw.ElapsedMilliseconds; errorCode=$err; message=$msg
  } | ConvertTo-Json -Compress
  Add-Content -Path $logPath -Value $rec
}

try {
  # ── Preflight: 모듈 로드 & 스모크 ─────────────────────────────────────────────
  $ModPath = Join-Path $RepoRoot 'scripts\lib\kobong-fileio.psm1'
  if (!(Test-Path $ModPath)) { throw "Missing module: $ModPath" }
try { Import-Module $ModPath -Force } catch { Write-Host "[WARN] Import-Module failed → $ModPath: $(# APPLY IN SHELL
#requires -Version 7.0
param([switch]$ConfirmApply,[string]$Root)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

# ── Gate-0: Repo / Lock ─────────────────────────────────────────────────────────
function Get-RepoRoot {
  try {
    $p = (git rev-parse --show-toplevel 2>$null)
    if ($p) { return (Resolve-Path $p).Path }
  } catch {}
  if ($Root) { return (Resolve-Path $Root).Path }
  return (Get-Location).Path
}
$RepoRoot = Get-RepoRoot
$LockFile = Join-Path $RepoRoot '.gpt5.lock'
if (Test-Path $LockFile) { Write-Error 'CONFLICT: .gpt5.lock exists.'; exit 11 }
"locked $(Get-Date -Format o)" | Out-File $LockFile -Encoding utf8 -NoNewline

$sw=[Diagnostics.Stopwatch]::StartNew()
$trace=[guid]::NewGuid().ToString()
$logPath = Join-Path $RepoRoot 'logs/apply-log.jsonl'
New-Item -ItemType Directory -Force -Path (Split-Path $logPath) | Out-Null

function LogRec([string]$level,[string]$action,[string]$outcome,[string]$msg,[string]$err='') {
  $rec = @{
    timestamp=(Get-Date).ToString('o'); level=$level; traceId=$trace; module='patcher';
    action=$action; inputHash=((Get-Variable -Name patchHash -Scope Global -ValueOnly -ErrorAction SilentlyContinue) ?? ""); outcome=$outcome;
    durationMs=$sw.ElapsedMilliseconds; errorCode=$err; message=$msg
  } | ConvertTo-Json -Compress
  Add-Content -Path $logPath -Value $rec
}

try {
  # ── Preflight: 모듈 로드 & 스모크 ─────────────────────────────────────────────
  $ModPath = Join-Path $RepoRoot 'scripts\lib\kobong-fileio.psm1'
  if (!(Test-Path $ModPath)) { throw "Missing module: $ModPath" }
  Import-Module $ModPath -Force

  # 스모크: 같은 볼륨에 원자 쓰기 → 즉시 삭제
  $smoke = Join-Path $RepoRoot 'webui\public\_klc-smoke.txt'
  $smokeContent = "[klc-smoke] $(Get-Date -Format o)"
  Write-AtomicUtf8 -Path $smoke -Content $smokeContent -Module 'patcher' -Action 'smoke'
  if (Test-Path $smoke) { Remove-Item -LiteralPath $smoke -Force -ErrorAction SilentlyContinue }

  # ── Patch 파일 파싱 ───────────────────────────────────────────────────────────
  $PatchFile = Join-Path $RepoRoot '.kobong\patches.pending.txt'
  if (!(Test-Path $PatchFile)) {
  Write-Host "[SKIP] patches file not found → $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("patches-file-missing: "+$PatchFile) } catch {}
  return
}
  $patchText = Get-Content -LiteralPath $PatchFile -Raw -Encoding UTF8
  $global:patchHash = (Get-FileHash -Algorithm SHA256 -InputStream ([IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes($patchText)))).Hash

  $matches = [regex]::Matches($patchText, '(?ms)#\s*PATCH\s*START\s*(?<body>.*?)#\s*PATCH\s*END')
  if ($matches.Count -eq 0) {
  Write-Host "[SKIP] No PATCH blocks found in $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("no-patch-blocks: "+$PatchFile) } catch {}
  return
}

  $applied = @()
  foreach ($m in $matches) {
    $body = $m.Groups['body'].Value

    $targetRel = [regex]::Match($body, 'TARGET:\s*(?<v>.+)').Groups['v'].Value.Trim()
    $mode      = [regex]::Match($body, 'MODE:\s*(?<v>.+)').Groups['v'].Value.Trim().ToLowerInvariant()
    $find      = [regex]::Match($body, "FIND\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value
    $replace   = [regex]::Match($body, "REPLACE\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value

    if (-not $targetRel) { throw "PATCH missing TARGET" }
    if (-not $mode)      { throw "PATCH missing MODE" }
    if (-not $find)      { throw "PATCH missing FIND" }

    $target = Join-Path $RepoRoot $targetRel
    if (!(Test-Path $target)) {
  Write-Host "[SKIP] TARGET not found → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("target-not-found: "+$targetRel) } catch {}
  continue
}

    $orig = Get-Content -LiteralPath $target -Raw -Encoding UTF8
    $rxOpts = [Text.RegularExpressions.RegexOptions]::Multiline -bor [Text.RegularExpressions.RegexOptions]::Singleline
    $rx = [regex]::new($find, $rxOpts)
    $mt = $rx.Match($orig)
    if (-not $mt.Success) {
  Write-Host "[SKIP] FIND not matched → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("find-not-matched: "+$targetRel) } catch {}
  continue
}

    switch ($mode) {
      'insert-before' {
        $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
      }
      'insert-before' {
  $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
}
'insert-after' {
  $new = $orig.Substring(0, $mt.Index + $mt.Length) + "`n" + $replace + $orig.Substring($mt.Index + $mt.Length)
}
'replace' {
        $new = $rx.Replace($orig, $replace, 1)
      }
      default {
  Write-Host "[SKIP] Unsupported MODE → $mode for $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("unsupported-mode: "+$mode+" for "+$targetRel) } catch {}
  continue
}
    }

    if ($ConfirmApply) {
      $bk = "$target.bak-" + (Get-Date -Format 'yyyyMMdd-HHmmss')
      Copy-Item -LiteralPath $target -Destination $bk -Force
      Write-AtomicUtf8 -Path $target -Content $new -Module 'patcher' -Action ('apply:'+ $mode)
      $applied += $targetRel
    } else {
      Write-Host "[PREVIEW] would patch → $targetRel ($mode)"
    }
  }

  if ($ConfirmApply) {
    LogRec 'INFO' 'apply' 'SUCCESS' ("patched: " + ($applied -join ', '))
  } else {
    LogRec 'INFO' 'preview' 'SUCCESS' ("preview-ok (no writes). blocks="+$matches.Count)
  }

  # ── Gate-3 Verify (경량) ───────────────────────────────────────────────────────
  if ($ConfirmApply) {
    # 핵심 타겟의 구문 일치 재검
    $core = Join-Path $RepoRoot 'scripts\apply_ui_patch.ps1'
    if (Test-Path $core) {
      $c = Get-Content -LiteralPath $core -Raw -Encoding UTF8
      if ($c -notmatch 'ensure valid tmp path .* atomic friendly') {
        Write-Host "[WARN] VERIFY: guard snippet not found in apply_ui_patch.ps1"; try { LogRec "WARN" "verify" "SKIPPED" "guard-missing apply_ui_patch.ps1" } catch {}
      }
    }
  }
}
catch {
  LogRec 'ERROR' 'apply' 'FAILURE' $_.Exception.Message 'LOGIC'
  exit 0
}
finally {
  Remove-Item -Force $LockFile -ErrorAction SilentlyContinue
}
.Exception.Message)" }
  # 스모크: 같은 볼륨에 원자 쓰기 → 즉시 삭제
  $smoke = Join-Path $RepoRoot 'webui\public\_klc-smoke.txt'
  $smokeContent = "[klc-smoke] $(Get-Date -Format o)"
  Write-AtomicUtf8 -Path $smoke -Content $smokeContent -Module 'patcher' -Action 'smoke'
  if (Test-Path $smoke) { Remove-Item -LiteralPath $smoke -Force -ErrorAction SilentlyContinue }

  # ── Patch 파일 파싱 ───────────────────────────────────────────────────────────
  $PatchFile = Join-Path $RepoRoot '.kobong\patches.pending.txt'
  if (!(Test-Path $PatchFile)) {
  Write-Host "[SKIP] patches file not found → $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("patches-file-missing: "+$PatchFile) } catch {}
  return
}
  $patchText = Get-Content -LiteralPath $PatchFile -Raw -Encoding UTF8
  $global:patchHash = (Get-FileHash -Algorithm SHA256 -InputStream ([IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes($patchText)))).Hash

  $matches = [regex]::Matches($patchText, '(?ms)#\s*PATCH\s*START\s*(?<body>.*?)#\s*PATCH\s*END')
  if ($matches.Count -eq 0) {
  Write-Host "[SKIP] No PATCH blocks found in $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("no-patch-blocks: "+$PatchFile) } catch {}
  return
}

  $applied = @()
  foreach ($m in $matches) {
    $body = $m.Groups['body'].Value

    $targetRel = [regex]::Match($body, 'TARGET:\s*(?<v>.+)').Groups['v'].Value.Trim()
    $mode      = [regex]::Match($body, 'MODE:\s*(?<v>.+)').Groups['v'].Value.Trim().ToLowerInvariant()
    $find      = [regex]::Match($body, "FIND\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value
    $replace   = [regex]::Match($body, "REPLACE\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value

    if (-not $targetRel) { throw "PATCH missing TARGET" }
    if (-not $mode)      { throw "PATCH missing MODE" }
    if (-not $find)      { throw "PATCH missing FIND" }

    $target = Join-Path $RepoRoot $targetRel
    if (!(Test-Path $target)) {
  Write-Host "[SKIP] TARGET not found → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("target-not-found: "+$targetRel) } catch {}
  continue
}

    $orig = Get-Content -LiteralPath $target -Raw -Encoding UTF8
    $rxOpts = [Text.RegularExpressions.RegexOptions]::Multiline -bor [Text.RegularExpressions.RegexOptions]::Singleline
    $rx = [regex]::new($find, $rxOpts)
    $mt = $rx.Match($orig)
    if (-not $mt.Success) {
  Write-Host "[SKIP] FIND not matched → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("find-not-matched: "+$targetRel) } catch {}
  continue
}

    switch ($mode) {
      'insert-before' {
        $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
      }
      'insert-before' {
  $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
}
'insert-after' {
  $new = $orig.Substring(0, $mt.Index + $mt.Length) + "`n" + $replace + $orig.Substring($mt.Index + $mt.Length)
}
'replace' {
        $new = $rx.Replace($orig, $replace, 1)
      }
      default {
  Write-Host "[SKIP] Unsupported MODE → $mode for $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("unsupported-mode: "+$mode+" for "+$targetRel) } catch {}
  continue
}
    }

    if ($ConfirmApply) {
      $bk = "$target.bak-" + (Get-Date -Format 'yyyyMMdd-HHmmss')
      Copy-Item -LiteralPath $target -Destination $bk -Force
      Write-AtomicUtf8 -Path $target -Content $new -Module 'patcher' -Action ('apply:'+ $mode)
      $applied += $targetRel
    } else {
      Write-Host "[PREVIEW] would patch → $targetRel ($mode)"
    }
  }

  if ($ConfirmApply) {
    LogRec 'INFO' 'apply' 'SUCCESS' ("patched: " + ($applied -join ', '))
  } else {
    LogRec 'INFO' 'preview' 'SUCCESS' ("preview-ok (no writes). blocks="+$matches.Count)
  }

  # ── Gate-3 Verify (경량) ───────────────────────────────────────────────────────
  if ($ConfirmApply) {
    # 핵심 타겟의 구문 일치 재검
    $core = Join-Path $RepoRoot 'scripts\apply_ui_patch.ps1'
    if (Test-Path $core) {
      $c = Get-Content -LiteralPath $core -Raw -Encoding UTF8
      if ($c -notmatch 'ensure valid tmp path .* atomic friendly') {
        Write-Host "[WARN] VERIFY: guard snippet not found in apply_ui_patch.ps1"; try { LogRec "WARN" "verify" "SKIPPED" "guard-missing apply_ui_patch.ps1" } catch {}
      }
    }
  }
}
catch {
  LogRec 'ERROR' 'apply' 'FAILURE' $_.Exception.Message 'LOGIC'
  exit 0
}
finally {
  Remove-Item -Force $LockFile -ErrorAction SilentlyContinue
}
.Exception.Message)" }
}
try { Import-Module $ModPath -Force } catch { Write-Host "[WARN] Import-Module failed → $ModPath: $(# APPLY IN SHELL
#requires -Version 7.0
param([switch]$ConfirmApply,[string]$Root)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

# ── Gate-0: Repo / Lock ─────────────────────────────────────────────────────────
function Get-RepoRoot {
  try {
    $p = (git rev-parse --show-toplevel 2>$null)
    if ($p) { return (Resolve-Path $p).Path }
  } catch {}
  if ($Root) { return (Resolve-Path $Root).Path }
  return (Get-Location).Path
}
$RepoRoot = Get-RepoRoot
$LockFile = Join-Path $RepoRoot '.gpt5.lock'
if (Test-Path $LockFile) { Write-Error 'CONFLICT: .gpt5.lock exists.'; exit 11 }
"locked $(Get-Date -Format o)" | Out-File $LockFile -Encoding utf8 -NoNewline

$sw=[Diagnostics.Stopwatch]::StartNew()
$trace=[guid]::NewGuid().ToString()
$logPath = Join-Path $RepoRoot 'logs/apply-log.jsonl'
New-Item -ItemType Directory -Force -Path (Split-Path $logPath) | Out-Null

function LogRec([string]$level,[string]$action,[string]$outcome,[string]$msg,[string]$err='') {
  $rec = @{
    timestamp=(Get-Date).ToString('o'); level=$level; traceId=$trace; module='patcher';
    action=$action; inputHash=((Get-Variable -Name patchHash -Scope Global -ValueOnly -ErrorAction SilentlyContinue) ?? ""); outcome=$outcome;
    durationMs=$sw.ElapsedMilliseconds; errorCode=$err; message=$msg
  } | ConvertTo-Json -Compress
  Add-Content -Path $logPath -Value $rec
}

try {
  # ── Preflight: 모듈 로드 & 스모크 ─────────────────────────────────────────────
  $ModPath = Join-Path $RepoRoot 'scripts\lib\kobong-fileio.psm1'
  if (!(Test-Path $ModPath)) {
  Write-Host "[WARN] Missing module → $ModPath (continuing)"
  try { LogRec "WARN" "apply" "SKIPPED" ("missing-module: "+$ModPath) } catch {}
} else {
  try { Import-Module $ModPath -Force } catch { Write-Host "[WARN] Import-Module failed → $ModPath: $(# APPLY IN SHELL
#requires -Version 7.0
param([switch]$ConfirmApply,[string]$Root)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

# ── Gate-0: Repo / Lock ─────────────────────────────────────────────────────────
function Get-RepoRoot {
  try {
    $p = (git rev-parse --show-toplevel 2>$null)
    if ($p) { return (Resolve-Path $p).Path }
  } catch {}
  if ($Root) { return (Resolve-Path $Root).Path }
  return (Get-Location).Path
}
$RepoRoot = Get-RepoRoot
$LockFile = Join-Path $RepoRoot '.gpt5.lock'
if (Test-Path $LockFile) { Write-Error 'CONFLICT: .gpt5.lock exists.'; exit 11 }
"locked $(Get-Date -Format o)" | Out-File $LockFile -Encoding utf8 -NoNewline

$sw=[Diagnostics.Stopwatch]::StartNew()
$trace=[guid]::NewGuid().ToString()
$logPath = Join-Path $RepoRoot 'logs/apply-log.jsonl'
New-Item -ItemType Directory -Force -Path (Split-Path $logPath) | Out-Null

function LogRec([string]$level,[string]$action,[string]$outcome,[string]$msg,[string]$err='') {
  $rec = @{
    timestamp=(Get-Date).ToString('o'); level=$level; traceId=$trace; module='patcher';
    action=$action; inputHash=((Get-Variable -Name patchHash -Scope Global -ValueOnly -ErrorAction SilentlyContinue) ?? ""); outcome=$outcome;
    durationMs=$sw.ElapsedMilliseconds; errorCode=$err; message=$msg
  } | ConvertTo-Json -Compress
  Add-Content -Path $logPath -Value $rec
}

try {
  # ── Preflight: 모듈 로드 & 스모크 ─────────────────────────────────────────────
  $ModPath = Join-Path $RepoRoot 'scripts\lib\kobong-fileio.psm1'
  if (!(Test-Path $ModPath)) { throw "Missing module: $ModPath" }
try { Import-Module $ModPath -Force } catch { Write-Host "[WARN] Import-Module failed → $ModPath: $(# APPLY IN SHELL
#requires -Version 7.0
param([switch]$ConfirmApply,[string]$Root)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

# ── Gate-0: Repo / Lock ─────────────────────────────────────────────────────────
function Get-RepoRoot {
  try {
    $p = (git rev-parse --show-toplevel 2>$null)
    if ($p) { return (Resolve-Path $p).Path }
  } catch {}
  if ($Root) { return (Resolve-Path $Root).Path }
  return (Get-Location).Path
}
$RepoRoot = Get-RepoRoot
$LockFile = Join-Path $RepoRoot '.gpt5.lock'
if (Test-Path $LockFile) { Write-Error 'CONFLICT: .gpt5.lock exists.'; exit 11 }
"locked $(Get-Date -Format o)" | Out-File $LockFile -Encoding utf8 -NoNewline

$sw=[Diagnostics.Stopwatch]::StartNew()
$trace=[guid]::NewGuid().ToString()
$logPath = Join-Path $RepoRoot 'logs/apply-log.jsonl'
New-Item -ItemType Directory -Force -Path (Split-Path $logPath) | Out-Null

function LogRec([string]$level,[string]$action,[string]$outcome,[string]$msg,[string]$err='') {
  $rec = @{
    timestamp=(Get-Date).ToString('o'); level=$level; traceId=$trace; module='patcher';
    action=$action; inputHash=((Get-Variable -Name patchHash -Scope Global -ValueOnly -ErrorAction SilentlyContinue) ?? ""); outcome=$outcome;
    durationMs=$sw.ElapsedMilliseconds; errorCode=$err; message=$msg
  } | ConvertTo-Json -Compress
  Add-Content -Path $logPath -Value $rec
}

try {
  # ── Preflight: 모듈 로드 & 스모크 ─────────────────────────────────────────────
  $ModPath = Join-Path $RepoRoot 'scripts\lib\kobong-fileio.psm1'
  if (!(Test-Path $ModPath)) { throw "Missing module: $ModPath" }
  Import-Module $ModPath -Force

  # 스모크: 같은 볼륨에 원자 쓰기 → 즉시 삭제
  $smoke = Join-Path $RepoRoot 'webui\public\_klc-smoke.txt'
  $smokeContent = "[klc-smoke] $(Get-Date -Format o)"
  Write-AtomicUtf8 -Path $smoke -Content $smokeContent -Module 'patcher' -Action 'smoke'
  if (Test-Path $smoke) { Remove-Item -LiteralPath $smoke -Force -ErrorAction SilentlyContinue }

  # ── Patch 파일 파싱 ───────────────────────────────────────────────────────────
  $PatchFile = Join-Path $RepoRoot '.kobong\patches.pending.txt'
  if (!(Test-Path $PatchFile)) {
  Write-Host "[SKIP] patches file not found → $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("patches-file-missing: "+$PatchFile) } catch {}
  return
}
  $patchText = Get-Content -LiteralPath $PatchFile -Raw -Encoding UTF8
  $global:patchHash = (Get-FileHash -Algorithm SHA256 -InputStream ([IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes($patchText)))).Hash

  $matches = [regex]::Matches($patchText, '(?ms)#\s*PATCH\s*START\s*(?<body>.*?)#\s*PATCH\s*END')
  if ($matches.Count -eq 0) {
  Write-Host "[SKIP] No PATCH blocks found in $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("no-patch-blocks: "+$PatchFile) } catch {}
  return
}

  $applied = @()
  foreach ($m in $matches) {
    $body = $m.Groups['body'].Value

    $targetRel = [regex]::Match($body, 'TARGET:\s*(?<v>.+)').Groups['v'].Value.Trim()
    $mode      = [regex]::Match($body, 'MODE:\s*(?<v>.+)').Groups['v'].Value.Trim().ToLowerInvariant()
    $find      = [regex]::Match($body, "FIND\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value
    $replace   = [regex]::Match($body, "REPLACE\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value

    if (-not $targetRel) { throw "PATCH missing TARGET" }
    if (-not $mode)      { throw "PATCH missing MODE" }
    if (-not $find)      { throw "PATCH missing FIND" }

    $target = Join-Path $RepoRoot $targetRel
    if (!(Test-Path $target)) {
  Write-Host "[SKIP] TARGET not found → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("target-not-found: "+$targetRel) } catch {}
  continue
}

    $orig = Get-Content -LiteralPath $target -Raw -Encoding UTF8
    $rxOpts = [Text.RegularExpressions.RegexOptions]::Multiline -bor [Text.RegularExpressions.RegexOptions]::Singleline
    $rx = [regex]::new($find, $rxOpts)
    $mt = $rx.Match($orig)
    if (-not $mt.Success) {
  Write-Host "[SKIP] FIND not matched → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("find-not-matched: "+$targetRel) } catch {}
  continue
}

    switch ($mode) {
      'insert-before' {
        $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
      }
      'insert-before' {
  $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
}
'insert-after' {
  $new = $orig.Substring(0, $mt.Index + $mt.Length) + "`n" + $replace + $orig.Substring($mt.Index + $mt.Length)
}
'replace' {
        $new = $rx.Replace($orig, $replace, 1)
      }
      default {
  Write-Host "[SKIP] Unsupported MODE → $mode for $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("unsupported-mode: "+$mode+" for "+$targetRel) } catch {}
  continue
}
    }

    if ($ConfirmApply) {
      $bk = "$target.bak-" + (Get-Date -Format 'yyyyMMdd-HHmmss')
      Copy-Item -LiteralPath $target -Destination $bk -Force
      Write-AtomicUtf8 -Path $target -Content $new -Module 'patcher' -Action ('apply:'+ $mode)
      $applied += $targetRel
    } else {
      Write-Host "[PREVIEW] would patch → $targetRel ($mode)"
    }
  }

  if ($ConfirmApply) {
    LogRec 'INFO' 'apply' 'SUCCESS' ("patched: " + ($applied -join ', '))
  } else {
    LogRec 'INFO' 'preview' 'SUCCESS' ("preview-ok (no writes). blocks="+$matches.Count)
  }

  # ── Gate-3 Verify (경량) ───────────────────────────────────────────────────────
  if ($ConfirmApply) {
    # 핵심 타겟의 구문 일치 재검
    $core = Join-Path $RepoRoot 'scripts\apply_ui_patch.ps1'
    if (Test-Path $core) {
      $c = Get-Content -LiteralPath $core -Raw -Encoding UTF8
      if ($c -notmatch 'ensure valid tmp path .* atomic friendly') {
        Write-Host "[WARN] VERIFY: guard snippet not found in apply_ui_patch.ps1"; try { LogRec "WARN" "verify" "SKIPPED" "guard-missing apply_ui_patch.ps1" } catch {}
      }
    }
  }
}
catch {
  LogRec 'ERROR' 'apply' 'FAILURE' $_.Exception.Message 'LOGIC'
  exit 0
}
finally {
  Remove-Item -Force $LockFile -ErrorAction SilentlyContinue
}
.Exception.Message)" }
  # 스모크: 같은 볼륨에 원자 쓰기 → 즉시 삭제
  $smoke = Join-Path $RepoRoot 'webui\public\_klc-smoke.txt'
  $smokeContent = "[klc-smoke] $(Get-Date -Format o)"
  Write-AtomicUtf8 -Path $smoke -Content $smokeContent -Module 'patcher' -Action 'smoke'
  if (Test-Path $smoke) { Remove-Item -LiteralPath $smoke -Force -ErrorAction SilentlyContinue }

  # ── Patch 파일 파싱 ───────────────────────────────────────────────────────────
  $PatchFile = Join-Path $RepoRoot '.kobong\patches.pending.txt'
  if (!(Test-Path $PatchFile)) {
  Write-Host "[SKIP] patches file not found → $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("patches-file-missing: "+$PatchFile) } catch {}
  return
}
  $patchText = Get-Content -LiteralPath $PatchFile -Raw -Encoding UTF8
  $global:patchHash = (Get-FileHash -Algorithm SHA256 -InputStream ([IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes($patchText)))).Hash

  $matches = [regex]::Matches($patchText, '(?ms)#\s*PATCH\s*START\s*(?<body>.*?)#\s*PATCH\s*END')
  if ($matches.Count -eq 0) {
  Write-Host "[SKIP] No PATCH blocks found in $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("no-patch-blocks: "+$PatchFile) } catch {}
  return
}

  $applied = @()
  foreach ($m in $matches) {
    $body = $m.Groups['body'].Value

    $targetRel = [regex]::Match($body, 'TARGET:\s*(?<v>.+)').Groups['v'].Value.Trim()
    $mode      = [regex]::Match($body, 'MODE:\s*(?<v>.+)').Groups['v'].Value.Trim().ToLowerInvariant()
    $find      = [regex]::Match($body, "FIND\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value
    $replace   = [regex]::Match($body, "REPLACE\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value

    if (-not $targetRel) { throw "PATCH missing TARGET" }
    if (-not $mode)      { throw "PATCH missing MODE" }
    if (-not $find)      { throw "PATCH missing FIND" }

    $target = Join-Path $RepoRoot $targetRel
    if (!(Test-Path $target)) {
  Write-Host "[SKIP] TARGET not found → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("target-not-found: "+$targetRel) } catch {}
  continue
}

    $orig = Get-Content -LiteralPath $target -Raw -Encoding UTF8
    $rxOpts = [Text.RegularExpressions.RegexOptions]::Multiline -bor [Text.RegularExpressions.RegexOptions]::Singleline
    $rx = [regex]::new($find, $rxOpts)
    $mt = $rx.Match($orig)
    if (-not $mt.Success) {
  Write-Host "[SKIP] FIND not matched → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("find-not-matched: "+$targetRel) } catch {}
  continue
}

    switch ($mode) {
      'insert-before' {
        $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
      }
      'insert-before' {
  $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
}
'insert-after' {
  $new = $orig.Substring(0, $mt.Index + $mt.Length) + "`n" + $replace + $orig.Substring($mt.Index + $mt.Length)
}
'replace' {
        $new = $rx.Replace($orig, $replace, 1)
      }
      default {
  Write-Host "[SKIP] Unsupported MODE → $mode for $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("unsupported-mode: "+$mode+" for "+$targetRel) } catch {}
  continue
}
    }

    if ($ConfirmApply) {
      $bk = "$target.bak-" + (Get-Date -Format 'yyyyMMdd-HHmmss')
      Copy-Item -LiteralPath $target -Destination $bk -Force
      Write-AtomicUtf8 -Path $target -Content $new -Module 'patcher' -Action ('apply:'+ $mode)
      $applied += $targetRel
    } else {
      Write-Host "[PREVIEW] would patch → $targetRel ($mode)"
    }
  }

  if ($ConfirmApply) {
    LogRec 'INFO' 'apply' 'SUCCESS' ("patched: " + ($applied -join ', '))
  } else {
    LogRec 'INFO' 'preview' 'SUCCESS' ("preview-ok (no writes). blocks="+$matches.Count)
  }

  # ── Gate-3 Verify (경량) ───────────────────────────────────────────────────────
  if ($ConfirmApply) {
    # 핵심 타겟의 구문 일치 재검
    $core = Join-Path $RepoRoot 'scripts\apply_ui_patch.ps1'
    if (Test-Path $core) {
      $c = Get-Content -LiteralPath $core -Raw -Encoding UTF8
      if ($c -notmatch 'ensure valid tmp path .* atomic friendly') {
        Write-Host "[WARN] VERIFY: guard snippet not found in apply_ui_patch.ps1"; try { LogRec "WARN" "verify" "SKIPPED" "guard-missing apply_ui_patch.ps1" } catch {}
      }
    }
  }
}
catch {
  LogRec 'ERROR' 'apply' 'FAILURE' $_.Exception.Message 'LOGIC'
  exit 0
}
finally {
  Remove-Item -Force $LockFile -ErrorAction SilentlyContinue
}
.Exception.Message)" }
}
  Import-Module $ModPath -Force

  # 스모크: 같은 볼륨에 원자 쓰기 → 즉시 삭제
  $smoke = Join-Path $RepoRoot 'webui\public\_klc-smoke.txt'
  $smokeContent = "[klc-smoke] $(Get-Date -Format o)"
  Write-AtomicUtf8 -Path $smoke -Content $smokeContent -Module 'patcher' -Action 'smoke'
  if (Test-Path $smoke) { Remove-Item -LiteralPath $smoke -Force -ErrorAction SilentlyContinue }

  # ── Patch 파일 파싱 ───────────────────────────────────────────────────────────
  $PatchFile = Join-Path $RepoRoot '.kobong\patches.pending.txt'
  if (!(Test-Path $PatchFile)) {
  Write-Host "[SKIP] patches file not found → $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("patches-file-missing: "+$PatchFile) } catch {}
  return
}
  $patchText = Get-Content -LiteralPath $PatchFile -Raw -Encoding UTF8
  $global:patchHash = (Get-FileHash -Algorithm SHA256 -InputStream ([IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes($patchText)))).Hash

  $matches = [regex]::Matches($patchText, '(?ms)#\s*PATCH\s*START\s*(?<body>.*?)#\s*PATCH\s*END')
  if ($matches.Count -eq 0) {
  Write-Host "[SKIP] No PATCH blocks found in $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("no-patch-blocks: "+$PatchFile) } catch {}
  return
}

  $applied = @()
  foreach ($m in $matches) {
    $body = $m.Groups['body'].Value

    $targetRel = [regex]::Match($body, 'TARGET:\s*(?<v>.+)').Groups['v'].Value.Trim()
    $mode      = [regex]::Match($body, 'MODE:\s*(?<v>.+)').Groups['v'].Value.Trim().ToLowerInvariant()
    $find      = [regex]::Match($body, "FIND\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value
    $replace   = [regex]::Match($body, "REPLACE\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value

    if (-not $targetRel) { throw "PATCH missing TARGET" }
    if (-not $mode)      { throw "PATCH missing MODE" }
    if (-not $find)      { throw "PATCH missing FIND" }

    $target = Join-Path $RepoRoot $targetRel
    if (!(Test-Path $target)) {
  Write-Host "[SKIP] TARGET not found → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("target-not-found: "+$targetRel) } catch {}
  continue
}

    $orig = Get-Content -LiteralPath $target -Raw -Encoding UTF8
    $rxOpts = [Text.RegularExpressions.RegexOptions]::Multiline -bor [Text.RegularExpressions.RegexOptions]::Singleline
    $rx = [regex]::new($find, $rxOpts)
    $mt = $rx.Match($orig)
    if (-not $mt.Success) {
  Write-Host "[SKIP] FIND not matched → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("find-not-matched: "+$targetRel) } catch {}
  continue
}

    switch ($mode) {
      'insert-before' {
        $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
      }
      'insert-before' {
  $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
}
'insert-after' {
  $new = $orig.Substring(0, $mt.Index + $mt.Length) + "`n" + $replace + $orig.Substring($mt.Index + $mt.Length)
}
'replace' {
        $new = $rx.Replace($orig, $replace, 1)
      }
      default {
  Write-Host "[SKIP] Unsupported MODE → $mode for $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("unsupported-mode: "+$mode+" for "+$targetRel) } catch {}
  continue
}
    }

    if ($ConfirmApply) {
      $bk = "$target.bak-" + (Get-Date -Format 'yyyyMMdd-HHmmss')
      Copy-Item -LiteralPath $target -Destination $bk -Force
      Write-AtomicUtf8 -Path $target -Content $new -Module 'patcher' -Action ('apply:'+ $mode)
      $applied += $targetRel
    } else {
      Write-Host "[PREVIEW] would patch → $targetRel ($mode)"
    }
  }

  if ($ConfirmApply) {
    LogRec 'INFO' 'apply' 'SUCCESS' ("patched: " + ($applied -join ', '))
  } else {
    LogRec 'INFO' 'preview' 'SUCCESS' ("preview-ok (no writes). blocks="+$matches.Count)
  }

  # ── Gate-3 Verify (경량) ───────────────────────────────────────────────────────
  if ($ConfirmApply) {
    # 핵심 타겟의 구문 일치 재검
    $core = Join-Path $RepoRoot 'scripts\apply_ui_patch.ps1'
    if (Test-Path $core) {
      $c = Get-Content -LiteralPath $core -Raw -Encoding UTF8
      if ($c -notmatch 'ensure valid tmp path .* atomic friendly') {
        Write-Host "[WARN] VERIFY: guard snippet not found in apply_ui_patch.ps1"; try { LogRec "WARN" "verify" "SKIPPED" "guard-missing apply_ui_patch.ps1" } catch {}
      }
    }
  }
}
catch {
  LogRec 'ERROR' 'apply' 'FAILURE' $_.Exception.Message 'LOGIC'
  exit 0
}
finally {
  Remove-Item -Force $LockFile -ErrorAction SilentlyContinue
}
.Exception.Message)" }
  # 스모크: 같은 볼륨에 원자 쓰기 → 즉시 삭제
  $smoke = Join-Path $RepoRoot 'webui\public\_klc-smoke.txt'
  $smokeContent = "[klc-smoke] $(Get-Date -Format o)"
  Write-AtomicUtf8 -Path $smoke -Content $smokeContent -Module 'patcher' -Action 'smoke'
  if (Test-Path $smoke) { Remove-Item -LiteralPath $smoke -Force -ErrorAction SilentlyContinue }

  # ── Patch 파일 파싱 ───────────────────────────────────────────────────────────
  $PatchFile = Join-Path $RepoRoot '.kobong\patches.pending.txt'
  if (!(Test-Path $PatchFile)) {
  Write-Host "[SKIP] patches file not found → $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("patches-file-missing: "+$PatchFile) } catch {}
  return
}
  $patchText = Get-Content -LiteralPath $PatchFile -Raw -Encoding UTF8
  $global:patchHash = (Get-FileHash -Algorithm SHA256 -InputStream ([IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes($patchText)))).Hash

  $matches = [regex]::Matches($patchText, '(?ms)#\s*PATCH\s*START\s*(?<body>.*?)#\s*PATCH\s*END')
  if ($matches.Count -eq 0) {
  Write-Host "[SKIP] No PATCH blocks found in $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("no-patch-blocks: "+$PatchFile) } catch {}
  return
}

  $applied = @()
  foreach ($m in $matches) {
    $body = $m.Groups['body'].Value

    $targetRel = [regex]::Match($body, 'TARGET:\s*(?<v>.+)').Groups['v'].Value.Trim()
    $mode      = [regex]::Match($body, 'MODE:\s*(?<v>.+)').Groups['v'].Value.Trim().ToLowerInvariant()
    $find      = [regex]::Match($body, "FIND\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value
    $replace   = [regex]::Match($body, "REPLACE\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value

    if (-not $targetRel) { throw "PATCH missing TARGET" }
    if (-not $mode)      { throw "PATCH missing MODE" }
    if (-not $find)      { throw "PATCH missing FIND" }

    $target = Join-Path $RepoRoot $targetRel
    if (!(Test-Path $target)) {
  Write-Host "[SKIP] TARGET not found → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("target-not-found: "+$targetRel) } catch {}
  continue
}

    $orig = Get-Content -LiteralPath $target -Raw -Encoding UTF8
    $rxOpts = [Text.RegularExpressions.RegexOptions]::Multiline -bor [Text.RegularExpressions.RegexOptions]::Singleline
    $rx = [regex]::new($find, $rxOpts)
    $mt = $rx.Match($orig)
    if (-not $mt.Success) {
  Write-Host "[SKIP] FIND not matched → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("find-not-matched: "+$targetRel) } catch {}
  continue
}

    switch ($mode) {
      'insert-before' {
        $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
      }
      'insert-before' {
  $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
}
'insert-after' {
  $new = $orig.Substring(0, $mt.Index + $mt.Length) + "`n" + $replace + $orig.Substring($mt.Index + $mt.Length)
}
'replace' {
        $new = $rx.Replace($orig, $replace, 1)
      }
      default {
  Write-Host "[SKIP] Unsupported MODE → $mode for $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("unsupported-mode: "+$mode+" for "+$targetRel) } catch {}
  continue
}
    }

    if ($ConfirmApply) {
      $bk = "$target.bak-" + (Get-Date -Format 'yyyyMMdd-HHmmss')
      Copy-Item -LiteralPath $target -Destination $bk -Force
      Write-AtomicUtf8 -Path $target -Content $new -Module 'patcher' -Action ('apply:'+ $mode)
      $applied += $targetRel
    } else {
      Write-Host "[PREVIEW] would patch → $targetRel ($mode)"
    }
  }

  if ($ConfirmApply) {
    LogRec 'INFO' 'apply' 'SUCCESS' ("patched: " + ($applied -join ', '))
  } else {
    LogRec 'INFO' 'preview' 'SUCCESS' ("preview-ok (no writes). blocks="+$matches.Count)
  }

  # ── Gate-3 Verify (경량) ───────────────────────────────────────────────────────
  if ($ConfirmApply) {
    # 핵심 타겟의 구문 일치 재검
    $core = Join-Path $RepoRoot 'scripts\apply_ui_patch.ps1'
    if (Test-Path $core) {
      $c = Get-Content -LiteralPath $core -Raw -Encoding UTF8
      if ($c -notmatch 'ensure valid tmp path .* atomic friendly') {
        Write-Host "[WARN] VERIFY: guard snippet not found in apply_ui_patch.ps1"; try { LogRec "WARN" "verify" "SKIPPED" "guard-missing apply_ui_patch.ps1" } catch {}
      }
    }
  }
}
catch {
  LogRec 'ERROR' 'apply' 'FAILURE' $_.Exception.Message 'LOGIC'
  exit 0
}
finally {
  Remove-Item -Force $LockFile -ErrorAction SilentlyContinue
}
.Exception.Message) }

# ── Gate-0: Repo / Lock ─────────────────────────────────────────────────────────
function Get-RepoRoot {
  try {
    $p = (git rev-parse --show-toplevel 2>$null)
    if ($p) { return (Resolve-Path $p).Path }
  } catch {}
  if ($Root) { return (Resolve-Path $Root).Path }
  return (Get-Location).Path
}
$RepoRoot = Get-RepoRoot
$LockFile = Join-Path $RepoRoot '.gpt5.lock'
if (Test-Path $LockFile) { Write-Error 'CONFLICT: .gpt5.lock exists.'; exit 11 }
"locked $(Get-Date -Format o)" | Out-File $LockFile -Encoding utf8 -NoNewline

$sw=[Diagnostics.Stopwatch]::StartNew()
$trace=[guid]::NewGuid().ToString()
$logPath = Join-Path $RepoRoot 'logs/apply-log.jsonl'
New-Item -ItemType Directory -Force -Path (Split-Path $logPath) | Out-Null

function LogRec([string]$level,[string]$action,[string]$outcome,[string]$msg,[string]$err='') {
  $rec = @{
    timestamp=(Get-Date).ToString('o'); level=$level; traceId=$trace; module='patcher';
    action=$action; inputHash=((Get-Variable -Name patchHash -Scope Global -ValueOnly -ErrorAction SilentlyContinue) ?? ""); outcome=$outcome;
    durationMs=$sw.ElapsedMilliseconds; errorCode=$err; message=$msg
  } | ConvertTo-Json -Compress
  Add-Content -Path $logPath -Value $rec
}

try {
  # ── Preflight: 모듈 로드 & 스모크 ─────────────────────────────────────────────
  $ModPath = Join-Path $RepoRoot 'scripts\lib\kobong-fileio.psm1'
  if (!(Test-Path $ModPath)) { throw "Missing module: $ModPath" }
try { Import-Module $ModPath -Force } catch { Write-Host "[WARN] Import-Module failed → $ModPath: $(# APPLY IN SHELL
#requires -Version 7.0
param([switch]$ConfirmApply,[string]$Root)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

# ── Gate-0: Repo / Lock ─────────────────────────────────────────────────────────
function Get-RepoRoot {
  try {
    $p = (git rev-parse --show-toplevel 2>$null)
    if ($p) { return (Resolve-Path $p).Path }
  } catch {}
  if ($Root) { return (Resolve-Path $Root).Path }
  return (Get-Location).Path
}
$RepoRoot = Get-RepoRoot
$LockFile = Join-Path $RepoRoot '.gpt5.lock'
if (Test-Path $LockFile) { Write-Error 'CONFLICT: .gpt5.lock exists.'; exit 11 }
"locked $(Get-Date -Format o)" | Out-File $LockFile -Encoding utf8 -NoNewline

$sw=[Diagnostics.Stopwatch]::StartNew()
$trace=[guid]::NewGuid().ToString()
$logPath = Join-Path $RepoRoot 'logs/apply-log.jsonl'
New-Item -ItemType Directory -Force -Path (Split-Path $logPath) | Out-Null

function LogRec([string]$level,[string]$action,[string]$outcome,[string]$msg,[string]$err='') {
  $rec = @{
    timestamp=(Get-Date).ToString('o'); level=$level; traceId=$trace; module='patcher';
    action=$action; inputHash=((Get-Variable -Name patchHash -Scope Global -ValueOnly -ErrorAction SilentlyContinue) ?? ""); outcome=$outcome;
    durationMs=$sw.ElapsedMilliseconds; errorCode=$err; message=$msg
  } | ConvertTo-Json -Compress
  Add-Content -Path $logPath -Value $rec
}

try {
  # ── Preflight: 모듈 로드 & 스모크 ─────────────────────────────────────────────
  $ModPath = Join-Path $RepoRoot 'scripts\lib\kobong-fileio.psm1'
  if (!(Test-Path $ModPath)) { throw "Missing module: $ModPath" }
  Import-Module $ModPath -Force

  # 스모크: 같은 볼륨에 원자 쓰기 → 즉시 삭제
  $smoke = Join-Path $RepoRoot 'webui\public\_klc-smoke.txt'
  $smokeContent = "[klc-smoke] $(Get-Date -Format o)"
  Write-AtomicUtf8 -Path $smoke -Content $smokeContent -Module 'patcher' -Action 'smoke'
  if (Test-Path $smoke) { Remove-Item -LiteralPath $smoke -Force -ErrorAction SilentlyContinue }

  # ── Patch 파일 파싱 ───────────────────────────────────────────────────────────
  $PatchFile = Join-Path $RepoRoot '.kobong\patches.pending.txt'
  if (!(Test-Path $PatchFile)) {
  Write-Host "[SKIP] patches file not found → $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("patches-file-missing: "+$PatchFile) } catch {}
  return
}
  $patchText = Get-Content -LiteralPath $PatchFile -Raw -Encoding UTF8
  $global:patchHash = (Get-FileHash -Algorithm SHA256 -InputStream ([IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes($patchText)))).Hash

  $matches = [regex]::Matches($patchText, '(?ms)#\s*PATCH\s*START\s*(?<body>.*?)#\s*PATCH\s*END')
  if ($matches.Count -eq 0) {
  Write-Host "[SKIP] No PATCH blocks found in $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("no-patch-blocks: "+$PatchFile) } catch {}
  return
}

  $applied = @()
  foreach ($m in $matches) {
    $body = $m.Groups['body'].Value

    $targetRel = [regex]::Match($body, 'TARGET:\s*(?<v>.+)').Groups['v'].Value.Trim()
    $mode      = [regex]::Match($body, 'MODE:\s*(?<v>.+)').Groups['v'].Value.Trim().ToLowerInvariant()
    $find      = [regex]::Match($body, "FIND\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value
    $replace   = [regex]::Match($body, "REPLACE\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value

    if (-not $targetRel) { throw "PATCH missing TARGET" }
    if (-not $mode)      { throw "PATCH missing MODE" }
    if (-not $find)      { throw "PATCH missing FIND" }

    $target = Join-Path $RepoRoot $targetRel
    if (!(Test-Path $target)) {
  Write-Host "[SKIP] TARGET not found → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("target-not-found: "+$targetRel) } catch {}
  continue
}

    $orig = Get-Content -LiteralPath $target -Raw -Encoding UTF8
    $rxOpts = [Text.RegularExpressions.RegexOptions]::Multiline -bor [Text.RegularExpressions.RegexOptions]::Singleline
    $rx = [regex]::new($find, $rxOpts)
    $mt = $rx.Match($orig)
    if (-not $mt.Success) {
  Write-Host "[SKIP] FIND not matched → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("find-not-matched: "+$targetRel) } catch {}
  continue
}

    switch ($mode) {
      'insert-before' {
        $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
      }
      'insert-before' {
  $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
}
'insert-after' {
  $new = $orig.Substring(0, $mt.Index + $mt.Length) + "`n" + $replace + $orig.Substring($mt.Index + $mt.Length)
}
'replace' {
        $new = $rx.Replace($orig, $replace, 1)
      }
      default {
  Write-Host "[SKIP] Unsupported MODE → $mode for $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("unsupported-mode: "+$mode+" for "+$targetRel) } catch {}
  continue
}
    }

    if ($ConfirmApply) {
      $bk = "$target.bak-" + (Get-Date -Format 'yyyyMMdd-HHmmss')
      Copy-Item -LiteralPath $target -Destination $bk -Force
      Write-AtomicUtf8 -Path $target -Content $new -Module 'patcher' -Action ('apply:'+ $mode)
      $applied += $targetRel
    } else {
      Write-Host "[PREVIEW] would patch → $targetRel ($mode)"
    }
  }

  if ($ConfirmApply) {
    LogRec 'INFO' 'apply' 'SUCCESS' ("patched: " + ($applied -join ', '))
  } else {
    LogRec 'INFO' 'preview' 'SUCCESS' ("preview-ok (no writes). blocks="+$matches.Count)
  }

  # ── Gate-3 Verify (경량) ───────────────────────────────────────────────────────
  if ($ConfirmApply) {
    # 핵심 타겟의 구문 일치 재검
    $core = Join-Path $RepoRoot 'scripts\apply_ui_patch.ps1'
    if (Test-Path $core) {
      $c = Get-Content -LiteralPath $core -Raw -Encoding UTF8
      if ($c -notmatch 'ensure valid tmp path .* atomic friendly') {
        Write-Host "[WARN] VERIFY: guard snippet not found in apply_ui_patch.ps1"; try { LogRec "WARN" "verify" "SKIPPED" "guard-missing apply_ui_patch.ps1" } catch {}
      }
    }
  }
}
catch {
  LogRec 'ERROR' 'apply' 'FAILURE' $_.Exception.Message 'LOGIC'
  exit 0
}
finally {
  Remove-Item -Force $LockFile -ErrorAction SilentlyContinue
}
.Exception.Message)" }
  # 스모크: 같은 볼륨에 원자 쓰기 → 즉시 삭제
  $smoke = Join-Path $RepoRoot 'webui\public\_klc-smoke.txt'
  $smokeContent = "[klc-smoke] $(Get-Date -Format o)"
  Write-AtomicUtf8 -Path $smoke -Content $smokeContent -Module 'patcher' -Action 'smoke'
  if (Test-Path $smoke) { Remove-Item -LiteralPath $smoke -Force -ErrorAction SilentlyContinue }

  # ── Patch 파일 파싱 ───────────────────────────────────────────────────────────
  $PatchFile = Join-Path $RepoRoot '.kobong\patches.pending.txt'
  if (!(Test-Path $PatchFile)) {
  Write-Host "[SKIP] patches file not found → $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("patches-file-missing: "+$PatchFile) } catch {}
  return
}
  $patchText = Get-Content -LiteralPath $PatchFile -Raw -Encoding UTF8
  $global:patchHash = (Get-FileHash -Algorithm SHA256 -InputStream ([IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes($patchText)))).Hash

  $matches = [regex]::Matches($patchText, '(?ms)#\s*PATCH\s*START\s*(?<body>.*?)#\s*PATCH\s*END')
  if ($matches.Count -eq 0) {
  Write-Host "[SKIP] No PATCH blocks found in $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("no-patch-blocks: "+$PatchFile) } catch {}
  return
}

  $applied = @()
  foreach ($m in $matches) {
    $body = $m.Groups['body'].Value

    $targetRel = [regex]::Match($body, 'TARGET:\s*(?<v>.+)').Groups['v'].Value.Trim()
    $mode      = [regex]::Match($body, 'MODE:\s*(?<v>.+)').Groups['v'].Value.Trim().ToLowerInvariant()
    $find      = [regex]::Match($body, "FIND\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value
    $replace   = [regex]::Match($body, "REPLACE\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value

    if (-not $targetRel) { throw "PATCH missing TARGET" }
    if (-not $mode)      { throw "PATCH missing MODE" }
    if (-not $find)      { throw "PATCH missing FIND" }

    $target = Join-Path $RepoRoot $targetRel
    if (!(Test-Path $target)) {
  Write-Host "[SKIP] TARGET not found → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("target-not-found: "+$targetRel) } catch {}
  continue
}

    $orig = Get-Content -LiteralPath $target -Raw -Encoding UTF8
    $rxOpts = [Text.RegularExpressions.RegexOptions]::Multiline -bor [Text.RegularExpressions.RegexOptions]::Singleline
    $rx = [regex]::new($find, $rxOpts)
    $mt = $rx.Match($orig)
    if (-not $mt.Success) {
  Write-Host "[SKIP] FIND not matched → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("find-not-matched: "+$targetRel) } catch {}
  continue
}

    switch ($mode) {
      'insert-before' {
        $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
      }
      'insert-before' {
  $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
}
'insert-after' {
  $new = $orig.Substring(0, $mt.Index + $mt.Length) + "`n" + $replace + $orig.Substring($mt.Index + $mt.Length)
}
'replace' {
        $new = $rx.Replace($orig, $replace, 1)
      }
      default {
  Write-Host "[SKIP] Unsupported MODE → $mode for $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("unsupported-mode: "+$mode+" for "+$targetRel) } catch {}
  continue
}
    }

    if ($ConfirmApply) {
      $bk = "$target.bak-" + (Get-Date -Format 'yyyyMMdd-HHmmss')
      Copy-Item -LiteralPath $target -Destination $bk -Force
      Write-AtomicUtf8 -Path $target -Content $new -Module 'patcher' -Action ('apply:'+ $mode)
      $applied += $targetRel
    } else {
      Write-Host "[PREVIEW] would patch → $targetRel ($mode)"
    }
  }

  if ($ConfirmApply) {
    LogRec 'INFO' 'apply' 'SUCCESS' ("patched: " + ($applied -join ', '))
  } else {
    LogRec 'INFO' 'preview' 'SUCCESS' ("preview-ok (no writes). blocks="+$matches.Count)
  }

  # ── Gate-3 Verify (경량) ───────────────────────────────────────────────────────
  if ($ConfirmApply) {
    # 핵심 타겟의 구문 일치 재검
    $core = Join-Path $RepoRoot 'scripts\apply_ui_patch.ps1'
    if (Test-Path $core) {
      $c = Get-Content -LiteralPath $core -Raw -Encoding UTF8
      if ($c -notmatch 'ensure valid tmp path .* atomic friendly') {
        Write-Host "[WARN] VERIFY: guard snippet not found in apply_ui_patch.ps1"; try { LogRec "WARN" "verify" "SKIPPED" "guard-missing apply_ui_patch.ps1" } catch {}
      }
    }
  }
}
catch {
  LogRec 'ERROR' 'apply' 'FAILURE' $_.Exception.Message 'LOGIC'
  exit 0
}
finally {
  Remove-Item -Force $LockFile -ErrorAction SilentlyContinue
}
.Exception.Message)" }
}
try { Import-Module $ModPath -Force } catch { Write-Host "[WARN] Import-Module failed → $ModPath: $(# APPLY IN SHELL
#requires -Version 7.0
param([switch]$ConfirmApply,[string]$Root)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

# ── Gate-0: Repo / Lock ─────────────────────────────────────────────────────────
function Get-RepoRoot {
  try {
    $p = (git rev-parse --show-toplevel 2>$null)
    if ($p) { return (Resolve-Path $p).Path }
  } catch {}
  if ($Root) { return (Resolve-Path $Root).Path }
  return (Get-Location).Path
}
$RepoRoot = Get-RepoRoot
$LockFile = Join-Path $RepoRoot '.gpt5.lock'
if (Test-Path $LockFile) { Write-Error 'CONFLICT: .gpt5.lock exists.'; exit 11 }
"locked $(Get-Date -Format o)" | Out-File $LockFile -Encoding utf8 -NoNewline

$sw=[Diagnostics.Stopwatch]::StartNew()
$trace=[guid]::NewGuid().ToString()
$logPath = Join-Path $RepoRoot 'logs/apply-log.jsonl'
New-Item -ItemType Directory -Force -Path (Split-Path $logPath) | Out-Null

function LogRec([string]$level,[string]$action,[string]$outcome,[string]$msg,[string]$err='') {
  $rec = @{
    timestamp=(Get-Date).ToString('o'); level=$level; traceId=$trace; module='patcher';
    action=$action; inputHash=((Get-Variable -Name patchHash -Scope Global -ValueOnly -ErrorAction SilentlyContinue) ?? ""); outcome=$outcome;
    durationMs=$sw.ElapsedMilliseconds; errorCode=$err; message=$msg
  } | ConvertTo-Json -Compress
  Add-Content -Path $logPath -Value $rec
}

try {
  # ── Preflight: 모듈 로드 & 스모크 ─────────────────────────────────────────────
  $ModPath = Join-Path $RepoRoot 'scripts\lib\kobong-fileio.psm1'
  if (!(Test-Path $ModPath)) {
  Write-Host "[WARN] Missing module → $ModPath (continuing)"
  try { LogRec "WARN" "apply" "SKIPPED" ("missing-module: "+$ModPath) } catch {}
} else {
  try { Import-Module $ModPath -Force } catch { Write-Host "[WARN] Import-Module failed → $ModPath: $(# APPLY IN SHELL
#requires -Version 7.0
param([switch]$ConfirmApply,[string]$Root)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

# ── Gate-0: Repo / Lock ─────────────────────────────────────────────────────────
function Get-RepoRoot {
  try {
    $p = (git rev-parse --show-toplevel 2>$null)
    if ($p) { return (Resolve-Path $p).Path }
  } catch {}
  if ($Root) { return (Resolve-Path $Root).Path }
  return (Get-Location).Path
}
$RepoRoot = Get-RepoRoot
$LockFile = Join-Path $RepoRoot '.gpt5.lock'
if (Test-Path $LockFile) { Write-Error 'CONFLICT: .gpt5.lock exists.'; exit 11 }
"locked $(Get-Date -Format o)" | Out-File $LockFile -Encoding utf8 -NoNewline

$sw=[Diagnostics.Stopwatch]::StartNew()
$trace=[guid]::NewGuid().ToString()
$logPath = Join-Path $RepoRoot 'logs/apply-log.jsonl'
New-Item -ItemType Directory -Force -Path (Split-Path $logPath) | Out-Null

function LogRec([string]$level,[string]$action,[string]$outcome,[string]$msg,[string]$err='') {
  $rec = @{
    timestamp=(Get-Date).ToString('o'); level=$level; traceId=$trace; module='patcher';
    action=$action; inputHash=((Get-Variable -Name patchHash -Scope Global -ValueOnly -ErrorAction SilentlyContinue) ?? ""); outcome=$outcome;
    durationMs=$sw.ElapsedMilliseconds; errorCode=$err; message=$msg
  } | ConvertTo-Json -Compress
  Add-Content -Path $logPath -Value $rec
}

try {
  # ── Preflight: 모듈 로드 & 스모크 ─────────────────────────────────────────────
  $ModPath = Join-Path $RepoRoot 'scripts\lib\kobong-fileio.psm1'
  if (!(Test-Path $ModPath)) { throw "Missing module: $ModPath" }
try { Import-Module $ModPath -Force } catch { Write-Host "[WARN] Import-Module failed → $ModPath: $(# APPLY IN SHELL
#requires -Version 7.0
param([switch]$ConfirmApply,[string]$Root)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

# ── Gate-0: Repo / Lock ─────────────────────────────────────────────────────────
function Get-RepoRoot {
  try {
    $p = (git rev-parse --show-toplevel 2>$null)
    if ($p) { return (Resolve-Path $p).Path }
  } catch {}
  if ($Root) { return (Resolve-Path $Root).Path }
  return (Get-Location).Path
}
$RepoRoot = Get-RepoRoot
$LockFile = Join-Path $RepoRoot '.gpt5.lock'
if (Test-Path $LockFile) { Write-Error 'CONFLICT: .gpt5.lock exists.'; exit 11 }
"locked $(Get-Date -Format o)" | Out-File $LockFile -Encoding utf8 -NoNewline

$sw=[Diagnostics.Stopwatch]::StartNew()
$trace=[guid]::NewGuid().ToString()
$logPath = Join-Path $RepoRoot 'logs/apply-log.jsonl'
New-Item -ItemType Directory -Force -Path (Split-Path $logPath) | Out-Null

function LogRec([string]$level,[string]$action,[string]$outcome,[string]$msg,[string]$err='') {
  $rec = @{
    timestamp=(Get-Date).ToString('o'); level=$level; traceId=$trace; module='patcher';
    action=$action; inputHash=((Get-Variable -Name patchHash -Scope Global -ValueOnly -ErrorAction SilentlyContinue) ?? ""); outcome=$outcome;
    durationMs=$sw.ElapsedMilliseconds; errorCode=$err; message=$msg
  } | ConvertTo-Json -Compress
  Add-Content -Path $logPath -Value $rec
}

try {
  # ── Preflight: 모듈 로드 & 스모크 ─────────────────────────────────────────────
  $ModPath = Join-Path $RepoRoot 'scripts\lib\kobong-fileio.psm1'
  if (!(Test-Path $ModPath)) { throw "Missing module: $ModPath" }
  Import-Module $ModPath -Force

  # 스모크: 같은 볼륨에 원자 쓰기 → 즉시 삭제
  $smoke = Join-Path $RepoRoot 'webui\public\_klc-smoke.txt'
  $smokeContent = "[klc-smoke] $(Get-Date -Format o)"
  Write-AtomicUtf8 -Path $smoke -Content $smokeContent -Module 'patcher' -Action 'smoke'
  if (Test-Path $smoke) { Remove-Item -LiteralPath $smoke -Force -ErrorAction SilentlyContinue }

  # ── Patch 파일 파싱 ───────────────────────────────────────────────────────────
  $PatchFile = Join-Path $RepoRoot '.kobong\patches.pending.txt'
  if (!(Test-Path $PatchFile)) {
  Write-Host "[SKIP] patches file not found → $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("patches-file-missing: "+$PatchFile) } catch {}
  return
}
  $patchText = Get-Content -LiteralPath $PatchFile -Raw -Encoding UTF8
  $global:patchHash = (Get-FileHash -Algorithm SHA256 -InputStream ([IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes($patchText)))).Hash

  $matches = [regex]::Matches($patchText, '(?ms)#\s*PATCH\s*START\s*(?<body>.*?)#\s*PATCH\s*END')
  if ($matches.Count -eq 0) {
  Write-Host "[SKIP] No PATCH blocks found in $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("no-patch-blocks: "+$PatchFile) } catch {}
  return
}

  $applied = @()
  foreach ($m in $matches) {
    $body = $m.Groups['body'].Value

    $targetRel = [regex]::Match($body, 'TARGET:\s*(?<v>.+)').Groups['v'].Value.Trim()
    $mode      = [regex]::Match($body, 'MODE:\s*(?<v>.+)').Groups['v'].Value.Trim().ToLowerInvariant()
    $find      = [regex]::Match($body, "FIND\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value
    $replace   = [regex]::Match($body, "REPLACE\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value

    if (-not $targetRel) { throw "PATCH missing TARGET" }
    if (-not $mode)      { throw "PATCH missing MODE" }
    if (-not $find)      { throw "PATCH missing FIND" }

    $target = Join-Path $RepoRoot $targetRel
    if (!(Test-Path $target)) {
  Write-Host "[SKIP] TARGET not found → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("target-not-found: "+$targetRel) } catch {}
  continue
}

    $orig = Get-Content -LiteralPath $target -Raw -Encoding UTF8
    $rxOpts = [Text.RegularExpressions.RegexOptions]::Multiline -bor [Text.RegularExpressions.RegexOptions]::Singleline
    $rx = [regex]::new($find, $rxOpts)
    $mt = $rx.Match($orig)
    if (-not $mt.Success) {
  Write-Host "[SKIP] FIND not matched → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("find-not-matched: "+$targetRel) } catch {}
  continue
}

    switch ($mode) {
      'insert-before' {
        $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
      }
      'insert-before' {
  $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
}
'insert-after' {
  $new = $orig.Substring(0, $mt.Index + $mt.Length) + "`n" + $replace + $orig.Substring($mt.Index + $mt.Length)
}
'replace' {
        $new = $rx.Replace($orig, $replace, 1)
      }
      default {
  Write-Host "[SKIP] Unsupported MODE → $mode for $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("unsupported-mode: "+$mode+" for "+$targetRel) } catch {}
  continue
}
    }

    if ($ConfirmApply) {
      $bk = "$target.bak-" + (Get-Date -Format 'yyyyMMdd-HHmmss')
      Copy-Item -LiteralPath $target -Destination $bk -Force
      Write-AtomicUtf8 -Path $target -Content $new -Module 'patcher' -Action ('apply:'+ $mode)
      $applied += $targetRel
    } else {
      Write-Host "[PREVIEW] would patch → $targetRel ($mode)"
    }
  }

  if ($ConfirmApply) {
    LogRec 'INFO' 'apply' 'SUCCESS' ("patched: " + ($applied -join ', '))
  } else {
    LogRec 'INFO' 'preview' 'SUCCESS' ("preview-ok (no writes). blocks="+$matches.Count)
  }

  # ── Gate-3 Verify (경량) ───────────────────────────────────────────────────────
  if ($ConfirmApply) {
    # 핵심 타겟의 구문 일치 재검
    $core = Join-Path $RepoRoot 'scripts\apply_ui_patch.ps1'
    if (Test-Path $core) {
      $c = Get-Content -LiteralPath $core -Raw -Encoding UTF8
      if ($c -notmatch 'ensure valid tmp path .* atomic friendly') {
        Write-Host "[WARN] VERIFY: guard snippet not found in apply_ui_patch.ps1"; try { LogRec "WARN" "verify" "SKIPPED" "guard-missing apply_ui_patch.ps1" } catch {}
      }
    }
  }
}
catch {
  LogRec 'ERROR' 'apply' 'FAILURE' $_.Exception.Message 'LOGIC'
  exit 0
}
finally {
  Remove-Item -Force $LockFile -ErrorAction SilentlyContinue
}
.Exception.Message)" }
  # 스모크: 같은 볼륨에 원자 쓰기 → 즉시 삭제
  $smoke = Join-Path $RepoRoot 'webui\public\_klc-smoke.txt'
  $smokeContent = "[klc-smoke] $(Get-Date -Format o)"
  Write-AtomicUtf8 -Path $smoke -Content $smokeContent -Module 'patcher' -Action 'smoke'
  if (Test-Path $smoke) { Remove-Item -LiteralPath $smoke -Force -ErrorAction SilentlyContinue }

  # ── Patch 파일 파싱 ───────────────────────────────────────────────────────────
  $PatchFile = Join-Path $RepoRoot '.kobong\patches.pending.txt'
  if (!(Test-Path $PatchFile)) {
  Write-Host "[SKIP] patches file not found → $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("patches-file-missing: "+$PatchFile) } catch {}
  return
}
  $patchText = Get-Content -LiteralPath $PatchFile -Raw -Encoding UTF8
  $global:patchHash = (Get-FileHash -Algorithm SHA256 -InputStream ([IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes($patchText)))).Hash

  $matches = [regex]::Matches($patchText, '(?ms)#\s*PATCH\s*START\s*(?<body>.*?)#\s*PATCH\s*END')
  if ($matches.Count -eq 0) {
  Write-Host "[SKIP] No PATCH blocks found in $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("no-patch-blocks: "+$PatchFile) } catch {}
  return
}

  $applied = @()
  foreach ($m in $matches) {
    $body = $m.Groups['body'].Value

    $targetRel = [regex]::Match($body, 'TARGET:\s*(?<v>.+)').Groups['v'].Value.Trim()
    $mode      = [regex]::Match($body, 'MODE:\s*(?<v>.+)').Groups['v'].Value.Trim().ToLowerInvariant()
    $find      = [regex]::Match($body, "FIND\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value
    $replace   = [regex]::Match($body, "REPLACE\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value

    if (-not $targetRel) { throw "PATCH missing TARGET" }
    if (-not $mode)      { throw "PATCH missing MODE" }
    if (-not $find)      { throw "PATCH missing FIND" }

    $target = Join-Path $RepoRoot $targetRel
    if (!(Test-Path $target)) {
  Write-Host "[SKIP] TARGET not found → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("target-not-found: "+$targetRel) } catch {}
  continue
}

    $orig = Get-Content -LiteralPath $target -Raw -Encoding UTF8
    $rxOpts = [Text.RegularExpressions.RegexOptions]::Multiline -bor [Text.RegularExpressions.RegexOptions]::Singleline
    $rx = [regex]::new($find, $rxOpts)
    $mt = $rx.Match($orig)
    if (-not $mt.Success) {
  Write-Host "[SKIP] FIND not matched → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("find-not-matched: "+$targetRel) } catch {}
  continue
}

    switch ($mode) {
      'insert-before' {
        $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
      }
      'insert-before' {
  $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
}
'insert-after' {
  $new = $orig.Substring(0, $mt.Index + $mt.Length) + "`n" + $replace + $orig.Substring($mt.Index + $mt.Length)
}
'replace' {
        $new = $rx.Replace($orig, $replace, 1)
      }
      default {
  Write-Host "[SKIP] Unsupported MODE → $mode for $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("unsupported-mode: "+$mode+" for "+$targetRel) } catch {}
  continue
}
    }

    if ($ConfirmApply) {
      $bk = "$target.bak-" + (Get-Date -Format 'yyyyMMdd-HHmmss')
      Copy-Item -LiteralPath $target -Destination $bk -Force
      Write-AtomicUtf8 -Path $target -Content $new -Module 'patcher' -Action ('apply:'+ $mode)
      $applied += $targetRel
    } else {
      Write-Host "[PREVIEW] would patch → $targetRel ($mode)"
    }
  }

  if ($ConfirmApply) {
    LogRec 'INFO' 'apply' 'SUCCESS' ("patched: " + ($applied -join ', '))
  } else {
    LogRec 'INFO' 'preview' 'SUCCESS' ("preview-ok (no writes). blocks="+$matches.Count)
  }

  # ── Gate-3 Verify (경량) ───────────────────────────────────────────────────────
  if ($ConfirmApply) {
    # 핵심 타겟의 구문 일치 재검
    $core = Join-Path $RepoRoot 'scripts\apply_ui_patch.ps1'
    if (Test-Path $core) {
      $c = Get-Content -LiteralPath $core -Raw -Encoding UTF8
      if ($c -notmatch 'ensure valid tmp path .* atomic friendly') {
        Write-Host "[WARN] VERIFY: guard snippet not found in apply_ui_patch.ps1"; try { LogRec "WARN" "verify" "SKIPPED" "guard-missing apply_ui_patch.ps1" } catch {}
      }
    }
  }
}
catch {
  LogRec 'ERROR' 'apply' 'FAILURE' $_.Exception.Message 'LOGIC'
  exit 0
}
finally {
  Remove-Item -Force $LockFile -ErrorAction SilentlyContinue
}
.Exception.Message)" }
}
  Import-Module $ModPath -Force

  # 스모크: 같은 볼륨에 원자 쓰기 → 즉시 삭제
  $smoke = Join-Path $RepoRoot 'webui\public\_klc-smoke.txt'
  $smokeContent = "[klc-smoke] $(Get-Date -Format o)"
  Write-AtomicUtf8 -Path $smoke -Content $smokeContent -Module 'patcher' -Action 'smoke'
  if (Test-Path $smoke) { Remove-Item -LiteralPath $smoke -Force -ErrorAction SilentlyContinue }

  # ── Patch 파일 파싱 ───────────────────────────────────────────────────────────
  $PatchFile = Join-Path $RepoRoot '.kobong\patches.pending.txt'
  if (!(Test-Path $PatchFile)) {
  Write-Host "[SKIP] patches file not found → $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("patches-file-missing: "+$PatchFile) } catch {}
  return
}
  $patchText = Get-Content -LiteralPath $PatchFile -Raw -Encoding UTF8
  $global:patchHash = (Get-FileHash -Algorithm SHA256 -InputStream ([IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes($patchText)))).Hash

  $matches = [regex]::Matches($patchText, '(?ms)#\s*PATCH\s*START\s*(?<body>.*?)#\s*PATCH\s*END')
  if ($matches.Count -eq 0) {
  Write-Host "[SKIP] No PATCH blocks found in $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("no-patch-blocks: "+$PatchFile) } catch {}
  return
}

  $applied = @()
  foreach ($m in $matches) {
    $body = $m.Groups['body'].Value

    $targetRel = [regex]::Match($body, 'TARGET:\s*(?<v>.+)').Groups['v'].Value.Trim()
    $mode      = [regex]::Match($body, 'MODE:\s*(?<v>.+)').Groups['v'].Value.Trim().ToLowerInvariant()
    $find      = [regex]::Match($body, "FIND\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value
    $replace   = [regex]::Match($body, "REPLACE\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value

    if (-not $targetRel) { throw "PATCH missing TARGET" }
    if (-not $mode)      { throw "PATCH missing MODE" }
    if (-not $find)      { throw "PATCH missing FIND" }

    $target = Join-Path $RepoRoot $targetRel
    if (!(Test-Path $target)) {
  Write-Host "[SKIP] TARGET not found → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("target-not-found: "+$targetRel) } catch {}
  continue
}

    $orig = Get-Content -LiteralPath $target -Raw -Encoding UTF8
    $rxOpts = [Text.RegularExpressions.RegexOptions]::Multiline -bor [Text.RegularExpressions.RegexOptions]::Singleline
    $rx = [regex]::new($find, $rxOpts)
    $mt = $rx.Match($orig)
    if (-not $mt.Success) {
  Write-Host "[SKIP] FIND not matched → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("find-not-matched: "+$targetRel) } catch {}
  continue
}

    switch ($mode) {
      'insert-before' {
        $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
      }
      'insert-before' {
  $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
}
'insert-after' {
  $new = $orig.Substring(0, $mt.Index + $mt.Length) + "`n" + $replace + $orig.Substring($mt.Index + $mt.Length)
}
'replace' {
        $new = $rx.Replace($orig, $replace, 1)
      }
      default {
  Write-Host "[SKIP] Unsupported MODE → $mode for $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("unsupported-mode: "+$mode+" for "+$targetRel) } catch {}
  continue
}
    }

    if ($ConfirmApply) {
      $bk = "$target.bak-" + (Get-Date -Format 'yyyyMMdd-HHmmss')
      Copy-Item -LiteralPath $target -Destination $bk -Force
      Write-AtomicUtf8 -Path $target -Content $new -Module 'patcher' -Action ('apply:'+ $mode)
      $applied += $targetRel
    } else {
      Write-Host "[PREVIEW] would patch → $targetRel ($mode)"
    }
  }

  if ($ConfirmApply) {
    LogRec 'INFO' 'apply' 'SUCCESS' ("patched: " + ($applied -join ', '))
  } else {
    LogRec 'INFO' 'preview' 'SUCCESS' ("preview-ok (no writes). blocks="+$matches.Count)
  }

  # ── Gate-3 Verify (경량) ───────────────────────────────────────────────────────
  if ($ConfirmApply) {
    # 핵심 타겟의 구문 일치 재검
    $core = Join-Path $RepoRoot 'scripts\apply_ui_patch.ps1'
    if (Test-Path $core) {
      $c = Get-Content -LiteralPath $core -Raw -Encoding UTF8
      if ($c -notmatch 'ensure valid tmp path .* atomic friendly') {
        Write-Host "[WARN] VERIFY: guard snippet not found in apply_ui_patch.ps1"; try { LogRec "WARN" "verify" "SKIPPED" "guard-missing apply_ui_patch.ps1" } catch {}
      }
    }
  }
}
catch {
  LogRec 'ERROR' 'apply' 'FAILURE' $_.Exception.Message 'LOGIC'
  exit 0
}
finally {
  Remove-Item -Force $LockFile -ErrorAction SilentlyContinue
}
.Exception.Message)" }
  # 스모크: 같은 볼륨에 원자 쓰기 → 즉시 삭제
  $smoke = Join-Path $RepoRoot 'webui\public\_klc-smoke.txt'
  $smokeContent = "[klc-smoke] $(Get-Date -Format o)"
  Write-AtomicUtf8 -Path $smoke -Content $smokeContent -Module 'patcher' -Action 'smoke'
  if (Test-Path $smoke) { Remove-Item -LiteralPath $smoke -Force -ErrorAction SilentlyContinue }

  # ── Patch 파일 파싱 ───────────────────────────────────────────────────────────
  $PatchFile = Join-Path $RepoRoot '.kobong\patches.pending.txt'
  if (!(Test-Path $PatchFile)) {
  Write-Host "[SKIP] patches file not found → $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("patches-file-missing: "+$PatchFile) } catch {}
  return
}
  $patchText = Get-Content -LiteralPath $PatchFile -Raw -Encoding UTF8
  $global:patchHash = (Get-FileHash -Algorithm SHA256 -InputStream ([IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes($patchText)))).Hash

  $matches = [regex]::Matches($patchText, '(?ms)#\s*PATCH\s*START\s*(?<body>.*?)#\s*PATCH\s*END')
  if ($matches.Count -eq 0) {
  Write-Host "[SKIP] No PATCH blocks found in $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("no-patch-blocks: "+$PatchFile) } catch {}
  return
}

  $applied = @()
  foreach ($m in $matches) {
    $body = $m.Groups['body'].Value

    $targetRel = [regex]::Match($body, 'TARGET:\s*(?<v>.+)').Groups['v'].Value.Trim()
    $mode      = [regex]::Match($body, 'MODE:\s*(?<v>.+)').Groups['v'].Value.Trim().ToLowerInvariant()
    $find      = [regex]::Match($body, "FIND\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value
    $replace   = [regex]::Match($body, "REPLACE\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value

    if (-not $targetRel) { throw "PATCH missing TARGET" }
    if (-not $mode)      { throw "PATCH missing MODE" }
    if (-not $find)      { throw "PATCH missing FIND" }

    $target = Join-Path $RepoRoot $targetRel
    if (!(Test-Path $target)) {
  Write-Host "[SKIP] TARGET not found → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("target-not-found: "+$targetRel) } catch {}
  continue
}

    $orig = Get-Content -LiteralPath $target -Raw -Encoding UTF8
    $rxOpts = [Text.RegularExpressions.RegexOptions]::Multiline -bor [Text.RegularExpressions.RegexOptions]::Singleline
    $rx = [regex]::new($find, $rxOpts)
    $mt = $rx.Match($orig)
    if (-not $mt.Success) {
  Write-Host "[SKIP] FIND not matched → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("find-not-matched: "+$targetRel) } catch {}
  continue
}

    switch ($mode) {
      'insert-before' {
        $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
      }
      'insert-before' {
  $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
}
'insert-after' {
  $new = $orig.Substring(0, $mt.Index + $mt.Length) + "`n" + $replace + $orig.Substring($mt.Index + $mt.Length)
}
'replace' {
        $new = $rx.Replace($orig, $replace, 1)
      }
      default {
  Write-Host "[SKIP] Unsupported MODE → $mode for $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("unsupported-mode: "+$mode+" for "+$targetRel) } catch {}
  continue
}
    }

    if ($ConfirmApply) {
      $bk = "$target.bak-" + (Get-Date -Format 'yyyyMMdd-HHmmss')
      Copy-Item -LiteralPath $target -Destination $bk -Force
      Write-AtomicUtf8 -Path $target -Content $new -Module 'patcher' -Action ('apply:'+ $mode)
      $applied += $targetRel
    } else {
      Write-Host "[PREVIEW] would patch → $targetRel ($mode)"
    }
  }

  if ($ConfirmApply) {
    LogRec 'INFO' 'apply' 'SUCCESS' ("patched: " + ($applied -join ', '))
  } else {
    LogRec 'INFO' 'preview' 'SUCCESS' ("preview-ok (no writes). blocks="+$matches.Count)
  }

  # ── Gate-3 Verify (경량) ───────────────────────────────────────────────────────
  if ($ConfirmApply) {
    # 핵심 타겟의 구문 일치 재검
    $core = Join-Path $RepoRoot 'scripts\apply_ui_patch.ps1'
    if (Test-Path $core) {
      $c = Get-Content -LiteralPath $core -Raw -Encoding UTF8
      if ($c -notmatch 'ensure valid tmp path .* atomic friendly') {
        Write-Host "[WARN] VERIFY: guard snippet not found in apply_ui_patch.ps1"; try { LogRec "WARN" "verify" "SKIPPED" "guard-missing apply_ui_patch.ps1" } catch {}
      }
    }
  }
}
catch {
  LogRec 'ERROR' 'apply' 'FAILURE' $_.Exception.Message 'LOGIC'
  exit 0
}
finally {
  Remove-Item -Force $LockFile -ErrorAction SilentlyContinue
}
.Exception.Message) }
  # 스모크: 같은 볼륨에 원자 쓰기 → 즉시 삭제
  $smoke = Join-Path $RepoRoot 'webui\public\_klc-smoke.txt'
  $smokeContent = "[klc-smoke] $(Get-Date -Format o)"
  Write-AtomicUtf8 -Path $smoke -Content $smokeContent -Module 'patcher' -Action 'smoke'
  if (Test-Path $smoke) { Remove-Item -LiteralPath $smoke -Force -ErrorAction SilentlyContinue }

  # ── Patch 파일 파싱 ───────────────────────────────────────────────────────────
  $PatchFile = Join-Path $RepoRoot '.kobong\patches.pending.txt'
  if (!(Test-Path $PatchFile)) {
  Write-Host "[SKIP] patches file not found → $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("patches-file-missing: "+$PatchFile) } catch {}
  return
}
  $patchText = Get-Content -LiteralPath $PatchFile -Raw -Encoding UTF8
  $global:patchHash = (Get-FileHash -Algorithm SHA256 -InputStream ([IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes($patchText)))).Hash

  $matches = [regex]::Matches($patchText, '(?ms)#\s*PATCH\s*START\s*(?<body>.*?)#\s*PATCH\s*END')
  if ($matches.Count -eq 0) {
  Write-Host "[SKIP] No PATCH blocks found in $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("no-patch-blocks: "+$PatchFile) } catch {}
  return
}

  $applied = @()
  foreach ($m in $matches) {
    $body = $m.Groups['body'].Value

    $targetRel = [regex]::Match($body, 'TARGET:\s*(?<v>.+)').Groups['v'].Value.Trim()
    $mode      = [regex]::Match($body, 'MODE:\s*(?<v>.+)').Groups['v'].Value.Trim().ToLowerInvariant()
    $find      = [regex]::Match($body, "FIND\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value
    $replace   = [regex]::Match($body, "REPLACE\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value

    if (-not $targetRel) { throw "PATCH missing TARGET" }
    if (-not $mode)      { throw "PATCH missing MODE" }
    if (-not $find)      { throw "PATCH missing FIND" }

    $target = Join-Path $RepoRoot $targetRel
    if (!(Test-Path $target)) {
  Write-Host "[SKIP] TARGET not found → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("target-not-found: "+$targetRel) } catch {}
  continue
}

    $orig = Get-Content -LiteralPath $target -Raw -Encoding UTF8
    $rxOpts = [Text.RegularExpressions.RegexOptions]::Multiline -bor [Text.RegularExpressions.RegexOptions]::Singleline
    $rx = [regex]::new($find, $rxOpts)
    $mt = $rx.Match($orig)
    if (-not $mt.Success) {
  Write-Host "[SKIP] FIND not matched → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("find-not-matched: "+$targetRel) } catch {}
  continue
}

    switch ($mode) {
      'insert-before' {
        $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
      }
      'insert-before' {
  $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
}
'insert-after' {
  $new = $orig.Substring(0, $mt.Index + $mt.Length) + "`n" + $replace + $orig.Substring($mt.Index + $mt.Length)
}
'replace' {
        $new = $rx.Replace($orig, $replace, 1)
      }
      default {
  Write-Host "[SKIP] Unsupported MODE → $mode for $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("unsupported-mode: "+$mode+" for "+$targetRel) } catch {}
  continue
}
    }

    if ($ConfirmApply) {
      $bk = "$target.bak-" + (Get-Date -Format 'yyyyMMdd-HHmmss')
      Copy-Item -LiteralPath $target -Destination $bk -Force
      Write-AtomicUtf8 -Path $target -Content $new -Module 'patcher' -Action ('apply:'+ $mode)
      $applied += $targetRel
    } else {
      Write-Host "[PREVIEW] would patch → $targetRel ($mode)"
    }
  }

  if ($ConfirmApply) {
    LogRec 'INFO' 'apply' 'SUCCESS' ("patched: " + ($applied -join ', '))
  } else {
    LogRec 'INFO' 'preview' 'SUCCESS' ("preview-ok (no writes). blocks="+$matches.Count)
  }

  # ── Gate-3 Verify (경량) ───────────────────────────────────────────────────────
  if ($ConfirmApply) {
    # 핵심 타겟의 구문 일치 재검
    $core = Join-Path $RepoRoot 'scripts\apply_ui_patch.ps1'
    if (Test-Path $core) {
      $c = Get-Content -LiteralPath $core -Raw -Encoding UTF8
      if ($c -notmatch 'ensure valid tmp path .* atomic friendly') {
        Write-Host "[WARN] VERIFY: guard snippet not found in apply_ui_patch.ps1"; try { LogRec "WARN" "verify" "SKIPPED" "guard-missing apply_ui_patch.ps1" } catch {}
      }
    }
  }
}
catch {
  LogRec 'ERROR' 'apply' 'FAILURE' $_.Exception.Message 'LOGIC'
  exit 0
}
finally {
  Remove-Item -Force $LockFile -ErrorAction SilentlyContinue
}
.Exception.Message)" }
  # 스모크: 같은 볼륨에 원자 쓰기 → 즉시 삭제
  $smoke = Join-Path $RepoRoot 'webui\public\_klc-smoke.txt'
  $smokeContent = "[klc-smoke] $(Get-Date -Format o)"
  Write-AtomicUtf8 -Path $smoke -Content $smokeContent -Module 'patcher' -Action 'smoke'
  if (Test-Path $smoke) { Remove-Item -LiteralPath $smoke -Force -ErrorAction SilentlyContinue }

  # ── Patch 파일 파싱 ───────────────────────────────────────────────────────────
  $PatchFile = Join-Path $RepoRoot '.kobong\patches.pending.txt'
  if (!(Test-Path $PatchFile)) {
  Write-Host "[SKIP] patches file not found → $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("patches-file-missing: "+$PatchFile) } catch {}
  return
}
  $patchText = Get-Content -LiteralPath $PatchFile -Raw -Encoding UTF8
  $global:patchHash = (Get-FileHash -Algorithm SHA256 -InputStream ([IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes($patchText)))).Hash

  $matches = [regex]::Matches($patchText, '(?ms)#\s*PATCH\s*START\s*(?<body>.*?)#\s*PATCH\s*END')
  if ($matches.Count -eq 0) {
  Write-Host "[SKIP] No PATCH blocks found in $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("no-patch-blocks: "+$PatchFile) } catch {}
  return
}

  $applied = @()
  foreach ($m in $matches) {
    $body = $m.Groups['body'].Value

    $targetRel = [regex]::Match($body, 'TARGET:\s*(?<v>.+)').Groups['v'].Value.Trim()
    $mode      = [regex]::Match($body, 'MODE:\s*(?<v>.+)').Groups['v'].Value.Trim().ToLowerInvariant()
    $find      = [regex]::Match($body, "FIND\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value
    $replace   = [regex]::Match($body, "REPLACE\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value

    if (-not $targetRel) { throw "PATCH missing TARGET" }
    if (-not $mode)      { throw "PATCH missing MODE" }
    if (-not $find)      { throw "PATCH missing FIND" }

    $target = Join-Path $RepoRoot $targetRel
    if (!(Test-Path $target)) {
  Write-Host "[SKIP] TARGET not found → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("target-not-found: "+$targetRel) } catch {}
  continue
}

    $orig = Get-Content -LiteralPath $target -Raw -Encoding UTF8
    $rxOpts = [Text.RegularExpressions.RegexOptions]::Multiline -bor [Text.RegularExpressions.RegexOptions]::Singleline
    $rx = [regex]::new($find, $rxOpts)
    $mt = $rx.Match($orig)
    if (-not $mt.Success) {
  Write-Host "[SKIP] FIND not matched → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("find-not-matched: "+$targetRel) } catch {}
  continue
}

    switch ($mode) {
      'insert-before' {
        $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
      }
      'insert-before' {
  $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
}
'insert-after' {
  $new = $orig.Substring(0, $mt.Index + $mt.Length) + "`n" + $replace + $orig.Substring($mt.Index + $mt.Length)
}
'replace' {
        $new = $rx.Replace($orig, $replace, 1)
      }
      default {
  Write-Host "[SKIP] Unsupported MODE → $mode for $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("unsupported-mode: "+$mode+" for "+$targetRel) } catch {}
  continue
}
    }

    if ($ConfirmApply) {
      $bk = "$target.bak-" + (Get-Date -Format 'yyyyMMdd-HHmmss')
      Copy-Item -LiteralPath $target -Destination $bk -Force
      Write-AtomicUtf8 -Path $target -Content $new -Module 'patcher' -Action ('apply:'+ $mode)
      $applied += $targetRel
    } else {
      Write-Host "[PREVIEW] would patch → $targetRel ($mode)"
    }
  }

  if ($ConfirmApply) {
    LogRec 'INFO' 'apply' 'SUCCESS' ("patched: " + ($applied -join ', '))
  } else {
    LogRec 'INFO' 'preview' 'SUCCESS' ("preview-ok (no writes). blocks="+$matches.Count)
  }

  # ── Gate-3 Verify (경량) ───────────────────────────────────────────────────────
  if ($ConfirmApply) {
    # 핵심 타겟의 구문 일치 재검
    $core = Join-Path $RepoRoot 'scripts\apply_ui_patch.ps1'
    if (Test-Path $core) {
      $c = Get-Content -LiteralPath $core -Raw -Encoding UTF8
      if ($c -notmatch 'ensure valid tmp path .* atomic friendly') {
        Write-Host "[WARN] VERIFY: guard snippet not found in apply_ui_patch.ps1"; try { LogRec "WARN" "verify" "SKIPPED" "guard-missing apply_ui_patch.ps1" } catch {}
      }
    }
  }
}
catch {
  LogRec 'ERROR' 'apply' 'FAILURE' $_.Exception.Message 'LOGIC'
  exit 0
}
finally {
  Remove-Item -Force $LockFile -ErrorAction SilentlyContinue
}
.Exception.Message)" }
}
try { Import-Module $ModPath -Force } catch { Write-Host "[WARN] Import-Module failed → $ModPath: $(# APPLY IN SHELL
#requires -Version 7.0
param([switch]$ConfirmApply,[string]$Root)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

# ── Gate-0: Repo / Lock ─────────────────────────────────────────────────────────
function Get-RepoRoot {
  try {
    $p = (git rev-parse --show-toplevel 2>$null)
    if ($p) { return (Resolve-Path $p).Path }
  } catch {}
  if ($Root) { return (Resolve-Path $Root).Path }
  return (Get-Location).Path
}
$RepoRoot = Get-RepoRoot
$LockFile = Join-Path $RepoRoot '.gpt5.lock'
if (Test-Path $LockFile) { Write-Error 'CONFLICT: .gpt5.lock exists.'; exit 11 }
"locked $(Get-Date -Format o)" | Out-File $LockFile -Encoding utf8 -NoNewline

$sw=[Diagnostics.Stopwatch]::StartNew()
$trace=[guid]::NewGuid().ToString()
$logPath = Join-Path $RepoRoot 'logs/apply-log.jsonl'
New-Item -ItemType Directory -Force -Path (Split-Path $logPath) | Out-Null

function LogRec([string]$level,[string]$action,[string]$outcome,[string]$msg,[string]$err='') {
  $rec = @{
    timestamp=(Get-Date).ToString('o'); level=$level; traceId=$trace; module='patcher';
    action=$action; inputHash=((Get-Variable -Name patchHash -Scope Global -ValueOnly -ErrorAction SilentlyContinue) ?? ""); outcome=$outcome;
    durationMs=$sw.ElapsedMilliseconds; errorCode=$err; message=$msg
  } | ConvertTo-Json -Compress
  Add-Content -Path $logPath -Value $rec
}

try {
  # ── Preflight: 모듈 로드 & 스모크 ─────────────────────────────────────────────
  $ModPath = Join-Path $RepoRoot 'scripts\lib\kobong-fileio.psm1'
  if (!(Test-Path $ModPath)) {
  Write-Host "[WARN] Missing module → $ModPath (continuing)"
  try { LogRec "WARN" "apply" "SKIPPED" ("missing-module: "+$ModPath) } catch {}
} else {
  try { Import-Module $ModPath -Force } catch { Write-Host "[WARN] Import-Module failed → $ModPath: $(# APPLY IN SHELL
#requires -Version 7.0
param([switch]$ConfirmApply,[string]$Root)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

# ── Gate-0: Repo / Lock ─────────────────────────────────────────────────────────
function Get-RepoRoot {
  try {
    $p = (git rev-parse --show-toplevel 2>$null)
    if ($p) { return (Resolve-Path $p).Path }
  } catch {}
  if ($Root) { return (Resolve-Path $Root).Path }
  return (Get-Location).Path
}
$RepoRoot = Get-RepoRoot
$LockFile = Join-Path $RepoRoot '.gpt5.lock'
if (Test-Path $LockFile) { Write-Error 'CONFLICT: .gpt5.lock exists.'; exit 11 }
"locked $(Get-Date -Format o)" | Out-File $LockFile -Encoding utf8 -NoNewline

$sw=[Diagnostics.Stopwatch]::StartNew()
$trace=[guid]::NewGuid().ToString()
$logPath = Join-Path $RepoRoot 'logs/apply-log.jsonl'
New-Item -ItemType Directory -Force -Path (Split-Path $logPath) | Out-Null

function LogRec([string]$level,[string]$action,[string]$outcome,[string]$msg,[string]$err='') {
  $rec = @{
    timestamp=(Get-Date).ToString('o'); level=$level; traceId=$trace; module='patcher';
    action=$action; inputHash=((Get-Variable -Name patchHash -Scope Global -ValueOnly -ErrorAction SilentlyContinue) ?? ""); outcome=$outcome;
    durationMs=$sw.ElapsedMilliseconds; errorCode=$err; message=$msg
  } | ConvertTo-Json -Compress
  Add-Content -Path $logPath -Value $rec
}

try {
  # ── Preflight: 모듈 로드 & 스모크 ─────────────────────────────────────────────
  $ModPath = Join-Path $RepoRoot 'scripts\lib\kobong-fileio.psm1'
  if (!(Test-Path $ModPath)) { throw "Missing module: $ModPath" }
try { Import-Module $ModPath -Force } catch { Write-Host "[WARN] Import-Module failed → $ModPath: $(# APPLY IN SHELL
#requires -Version 7.0
param([switch]$ConfirmApply,[string]$Root)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

# ── Gate-0: Repo / Lock ─────────────────────────────────────────────────────────
function Get-RepoRoot {
  try {
    $p = (git rev-parse --show-toplevel 2>$null)
    if ($p) { return (Resolve-Path $p).Path }
  } catch {}
  if ($Root) { return (Resolve-Path $Root).Path }
  return (Get-Location).Path
}
$RepoRoot = Get-RepoRoot
$LockFile = Join-Path $RepoRoot '.gpt5.lock'
if (Test-Path $LockFile) { Write-Error 'CONFLICT: .gpt5.lock exists.'; exit 11 }
"locked $(Get-Date -Format o)" | Out-File $LockFile -Encoding utf8 -NoNewline

$sw=[Diagnostics.Stopwatch]::StartNew()
$trace=[guid]::NewGuid().ToString()
$logPath = Join-Path $RepoRoot 'logs/apply-log.jsonl'
New-Item -ItemType Directory -Force -Path (Split-Path $logPath) | Out-Null

function LogRec([string]$level,[string]$action,[string]$outcome,[string]$msg,[string]$err='') {
  $rec = @{
    timestamp=(Get-Date).ToString('o'); level=$level; traceId=$trace; module='patcher';
    action=$action; inputHash=((Get-Variable -Name patchHash -Scope Global -ValueOnly -ErrorAction SilentlyContinue) ?? ""); outcome=$outcome;
    durationMs=$sw.ElapsedMilliseconds; errorCode=$err; message=$msg
  } | ConvertTo-Json -Compress
  Add-Content -Path $logPath -Value $rec
}

try {
  # ── Preflight: 모듈 로드 & 스모크 ─────────────────────────────────────────────
  $ModPath = Join-Path $RepoRoot 'scripts\lib\kobong-fileio.psm1'
  if (!(Test-Path $ModPath)) { throw "Missing module: $ModPath" }
try { Import-Module $ModPath -Force } catch { Write-Host ("[WARN] Import-Module failed -> " + $ModPath + ": " + # APPLY IN SHELL
#requires -Version 7.0
param([switch]$ConfirmApply,[string]$Root)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

# ── Gate-0: Repo / Lock ─────────────────────────────────────────────────────────
function Get-RepoRoot {
  try {
    $p = (git rev-parse --show-toplevel 2>$null)
    if ($p) { return (Resolve-Path $p).Path }
  } catch {}
  if ($Root) { return (Resolve-Path $Root).Path }
  return (Get-Location).Path
}
$RepoRoot = Get-RepoRoot
$LockFile = Join-Path $RepoRoot '.gpt5.lock'
if (Test-Path $LockFile) { Write-Error 'CONFLICT: .gpt5.lock exists.'; exit 11 }
"locked $(Get-Date -Format o)" | Out-File $LockFile -Encoding utf8 -NoNewline

$sw=[Diagnostics.Stopwatch]::StartNew()
$trace=[guid]::NewGuid().ToString()
$logPath = Join-Path $RepoRoot 'logs/apply-log.jsonl'
New-Item -ItemType Directory -Force -Path (Split-Path $logPath) | Out-Null

function LogRec([string]$level,[string]$action,[string]$outcome,[string]$msg,[string]$err='') {
  $rec = @{
    timestamp=(Get-Date).ToString('o'); level=$level; traceId=$trace; module='patcher';
    action=$action; inputHash=((Get-Variable -Name patchHash -Scope Global -ValueOnly -ErrorAction SilentlyContinue) ?? ""); outcome=$outcome;
    durationMs=$sw.ElapsedMilliseconds; errorCode=$err; message=$msg
  } | ConvertTo-Json -Compress
  Add-Content -Path $logPath -Value $rec
}

try {
  # ── Preflight: 모듈 로드 & 스모크 ─────────────────────────────────────────────
  $ModPath = Join-Path $RepoRoot 'scripts\lib\kobong-fileio.psm1'
  if (!(Test-Path $ModPath)) {
  Write-Host "[WARN] Missing module → $ModPath (continuing)"
  try { LogRec "WARN" "apply" "SKIPPED" ("missing-module: "+$ModPath) } catch {}
} else {
  try { Import-Module $ModPath -Force } catch { Write-Host ("[WARN] Import-Module failed -> " + $ModPath + ": " + # APPLY IN SHELL
#requires -Version 7.0
param([switch]$ConfirmApply,[string]$Root)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

# ── Gate-0: Repo / Lock ─────────────────────────────────────────────────────────
function Get-RepoRoot {
  try {
    $p = (git rev-parse --show-toplevel 2>$null)
    if ($p) { return (Resolve-Path $p).Path }
  } catch {}
  if ($Root) { return (Resolve-Path $Root).Path }
  return (Get-Location).Path
}
$RepoRoot = Get-RepoRoot
$LockFile = Join-Path $RepoRoot '.gpt5.lock'
if (Test-Path $LockFile) { Write-Error 'CONFLICT: .gpt5.lock exists.'; exit 11 }
"locked $(Get-Date -Format o)" | Out-File $LockFile -Encoding utf8 -NoNewline

$sw=[Diagnostics.Stopwatch]::StartNew()
$trace=[guid]::NewGuid().ToString()
$logPath = Join-Path $RepoRoot 'logs/apply-log.jsonl'
New-Item -ItemType Directory -Force -Path (Split-Path $logPath) | Out-Null

function LogRec([string]$level,[string]$action,[string]$outcome,[string]$msg,[string]$err='') {
  $rec = @{
    timestamp=(Get-Date).ToString('o'); level=$level; traceId=$trace; module='patcher';
    action=$action; inputHash=((Get-Variable -Name patchHash -Scope Global -ValueOnly -ErrorAction SilentlyContinue) ?? ""); outcome=$outcome;
    durationMs=$sw.ElapsedMilliseconds; errorCode=$err; message=$msg
  } | ConvertTo-Json -Compress
  Add-Content -Path $logPath -Value $rec
}

try {
  # ── Preflight: 모듈 로드 & 스모크 ─────────────────────────────────────────────
  $ModPath = Join-Path $RepoRoot 'scripts\lib\kobong-fileio.psm1'
  if (!(Test-Path $ModPath)) {
  Write-Host "[WARN] Missing module → $ModPath (continuing)"
  try { LogRec "WARN" "apply" "SKIPPED" ("missing-module: "+$ModPath) } catch {}
} else {
  try { Import-Module $ModPath -Force } catch { Write-Host "[WARN] Import-Module failed → $ModPath: $(# APPLY IN SHELL
#requires -Version 7.0
param([switch]$ConfirmApply,[string]$Root)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

# ── Gate-0: Repo / Lock ─────────────────────────────────────────────────────────
function Get-RepoRoot {
  try {
    $p = (git rev-parse --show-toplevel 2>$null)
    if ($p) { return (Resolve-Path $p).Path }
  } catch {}
  if ($Root) { return (Resolve-Path $Root).Path }
  return (Get-Location).Path
}
$RepoRoot = Get-RepoRoot
$LockFile = Join-Path $RepoRoot '.gpt5.lock'
if (Test-Path $LockFile) { Write-Error 'CONFLICT: .gpt5.lock exists.'; exit 11 }
"locked $(Get-Date -Format o)" | Out-File $LockFile -Encoding utf8 -NoNewline

$sw=[Diagnostics.Stopwatch]::StartNew()
$trace=[guid]::NewGuid().ToString()
$logPath = Join-Path $RepoRoot 'logs/apply-log.jsonl'
New-Item -ItemType Directory -Force -Path (Split-Path $logPath) | Out-Null

function LogRec([string]$level,[string]$action,[string]$outcome,[string]$msg,[string]$err='') {
  $rec = @{
    timestamp=(Get-Date).ToString('o'); level=$level; traceId=$trace; module='patcher';
    action=$action; inputHash=((Get-Variable -Name patchHash -Scope Global -ValueOnly -ErrorAction SilentlyContinue) ?? ""); outcome=$outcome;
    durationMs=$sw.ElapsedMilliseconds; errorCode=$err; message=$msg
  } | ConvertTo-Json -Compress
  Add-Content -Path $logPath -Value $rec
}

try {
  # ── Preflight: 모듈 로드 & 스모크 ─────────────────────────────────────────────
  $ModPath = Join-Path $RepoRoot 'scripts\lib\kobong-fileio.psm1'
  if (!(Test-Path $ModPath)) { throw "Missing module: $ModPath" }
try { Import-Module $ModPath -Force } catch { Write-Host "[WARN] Import-Module failed → $ModPath: $(# APPLY IN SHELL
#requires -Version 7.0
param([switch]$ConfirmApply,[string]$Root)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

# ── Gate-0: Repo / Lock ─────────────────────────────────────────────────────────
function Get-RepoRoot {
  try {
    $p = (git rev-parse --show-toplevel 2>$null)
    if ($p) { return (Resolve-Path $p).Path }
  } catch {}
  if ($Root) { return (Resolve-Path $Root).Path }
  return (Get-Location).Path
}
$RepoRoot = Get-RepoRoot
$LockFile = Join-Path $RepoRoot '.gpt5.lock'
if (Test-Path $LockFile) { Write-Error 'CONFLICT: .gpt5.lock exists.'; exit 11 }
"locked $(Get-Date -Format o)" | Out-File $LockFile -Encoding utf8 -NoNewline

$sw=[Diagnostics.Stopwatch]::StartNew()
$trace=[guid]::NewGuid().ToString()
$logPath = Join-Path $RepoRoot 'logs/apply-log.jsonl'
New-Item -ItemType Directory -Force -Path (Split-Path $logPath) | Out-Null

function LogRec([string]$level,[string]$action,[string]$outcome,[string]$msg,[string]$err='') {
  $rec = @{
    timestamp=(Get-Date).ToString('o'); level=$level; traceId=$trace; module='patcher';
    action=$action; inputHash=((Get-Variable -Name patchHash -Scope Global -ValueOnly -ErrorAction SilentlyContinue) ?? ""); outcome=$outcome;
    durationMs=$sw.ElapsedMilliseconds; errorCode=$err; message=$msg
  } | ConvertTo-Json -Compress
  Add-Content -Path $logPath -Value $rec
}

try {
  # ── Preflight: 모듈 로드 & 스모크 ─────────────────────────────────────────────
  $ModPath = Join-Path $RepoRoot 'scripts\lib\kobong-fileio.psm1'
  if (!(Test-Path $ModPath)) { throw "Missing module: $ModPath" }
  Import-Module $ModPath -Force

  # 스모크: 같은 볼륨에 원자 쓰기 → 즉시 삭제
  $smoke = Join-Path $RepoRoot 'webui\public\_klc-smoke.txt'
  $smokeContent = "[klc-smoke] $(Get-Date -Format o)"
  Write-AtomicUtf8 -Path $smoke -Content $smokeContent -Module 'patcher' -Action 'smoke'
  if (Test-Path $smoke) { Remove-Item -LiteralPath $smoke -Force -ErrorAction SilentlyContinue }

  # ── Patch 파일 파싱 ───────────────────────────────────────────────────────────
  $PatchFile = Join-Path $RepoRoot '.kobong\patches.pending.txt'
  if (!(Test-Path $PatchFile)) {
  Write-Host "[SKIP] patches file not found → $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("patches-file-missing: "+$PatchFile) } catch {}
  return
}
  $patchText = Get-Content -LiteralPath $PatchFile -Raw -Encoding UTF8
  $global:patchHash = (Get-FileHash -Algorithm SHA256 -InputStream ([IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes($patchText)))).Hash

  $matches = [regex]::Matches($patchText, '(?ms)#\s*PATCH\s*START\s*(?<body>.*?)#\s*PATCH\s*END')
  if ($matches.Count -eq 0) {
  Write-Host "[SKIP] No PATCH blocks found in $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("no-patch-blocks: "+$PatchFile) } catch {}
  return
}

  $applied = @()
  foreach ($m in $matches) {
    $body = $m.Groups['body'].Value

    $targetRel = [regex]::Match($body, 'TARGET:\s*(?<v>.+)').Groups['v'].Value.Trim()
    $mode      = [regex]::Match($body, 'MODE:\s*(?<v>.+)').Groups['v'].Value.Trim().ToLowerInvariant()
    $find      = [regex]::Match($body, "FIND\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value
    $replace   = [regex]::Match($body, "REPLACE\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value

    if (-not $targetRel) { throw "PATCH missing TARGET" }
    if (-not $mode)      { throw "PATCH missing MODE" }
    if (-not $find)      { throw "PATCH missing FIND" }

    $target = Join-Path $RepoRoot $targetRel
    if (!(Test-Path $target)) {
  Write-Host "[SKIP] TARGET not found → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("target-not-found: "+$targetRel) } catch {}
  continue
}

    $orig = Get-Content -LiteralPath $target -Raw -Encoding UTF8
    $rxOpts = [Text.RegularExpressions.RegexOptions]::Multiline -bor [Text.RegularExpressions.RegexOptions]::Singleline
    $rx = [regex]::new($find, $rxOpts)
    $mt = $rx.Match($orig)
    if (-not $mt.Success) {
  Write-Host "[SKIP] FIND not matched → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("find-not-matched: "+$targetRel) } catch {}
  continue
}

    switch ($mode) {
      'insert-before' {
        $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
      }
      'insert-before' {
  $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
}
'insert-after' {
  $new = $orig.Substring(0, $mt.Index + $mt.Length) + "`n" + $replace + $orig.Substring($mt.Index + $mt.Length)
}
'replace' {
        $new = $rx.Replace($orig, $replace, 1)
      }
      default {
  Write-Host "[SKIP] Unsupported MODE → $mode for $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("unsupported-mode: "+$mode+" for "+$targetRel) } catch {}
  continue
}
    }

    if ($ConfirmApply) {
      $bk = "$target.bak-" + (Get-Date -Format 'yyyyMMdd-HHmmss')
      Copy-Item -LiteralPath $target -Destination $bk -Force
      Write-AtomicUtf8 -Path $target -Content $new -Module 'patcher' -Action ('apply:'+ $mode)
      $applied += $targetRel
    } else {
      Write-Host "[PREVIEW] would patch → $targetRel ($mode)"
    }
  }

  if ($ConfirmApply) {
    LogRec 'INFO' 'apply' 'SUCCESS' ("patched: " + ($applied -join ', '))
  } else {
    LogRec 'INFO' 'preview' 'SUCCESS' ("preview-ok (no writes). blocks="+$matches.Count)
  }

  # ── Gate-3 Verify (경량) ───────────────────────────────────────────────────────
  if ($ConfirmApply) {
    # 핵심 타겟의 구문 일치 재검
    $core = Join-Path $RepoRoot 'scripts\apply_ui_patch.ps1'
    if (Test-Path $core) {
      $c = Get-Content -LiteralPath $core -Raw -Encoding UTF8
      if ($c -notmatch 'ensure valid tmp path .* atomic friendly') {
        Write-Host "[WARN] VERIFY: guard snippet not found in apply_ui_patch.ps1"; try { LogRec "WARN" "verify" "SKIPPED" "guard-missing apply_ui_patch.ps1" } catch {}
      }
    }
  }
}
catch {
  LogRec 'ERROR' 'apply' 'FAILURE' $_.Exception.Message 'LOGIC'
  exit 0
}
finally {
  Remove-Item -Force $LockFile -ErrorAction SilentlyContinue
}
.Exception.Message)" }
  # 스모크: 같은 볼륨에 원자 쓰기 → 즉시 삭제
  $smoke = Join-Path $RepoRoot 'webui\public\_klc-smoke.txt'
  $smokeContent = "[klc-smoke] $(Get-Date -Format o)"
  Write-AtomicUtf8 -Path $smoke -Content $smokeContent -Module 'patcher' -Action 'smoke'
  if (Test-Path $smoke) { Remove-Item -LiteralPath $smoke -Force -ErrorAction SilentlyContinue }

  # ── Patch 파일 파싱 ───────────────────────────────────────────────────────────
  $PatchFile = Join-Path $RepoRoot '.kobong\patches.pending.txt'
  if (!(Test-Path $PatchFile)) {
  Write-Host "[SKIP] patches file not found → $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("patches-file-missing: "+$PatchFile) } catch {}
  return
}
  $patchText = Get-Content -LiteralPath $PatchFile -Raw -Encoding UTF8
  $global:patchHash = (Get-FileHash -Algorithm SHA256 -InputStream ([IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes($patchText)))).Hash

  $matches = [regex]::Matches($patchText, '(?ms)#\s*PATCH\s*START\s*(?<body>.*?)#\s*PATCH\s*END')
  if ($matches.Count -eq 0) {
  Write-Host "[SKIP] No PATCH blocks found in $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("no-patch-blocks: "+$PatchFile) } catch {}
  return
}

  $applied = @()
  foreach ($m in $matches) {
    $body = $m.Groups['body'].Value

    $targetRel = [regex]::Match($body, 'TARGET:\s*(?<v>.+)').Groups['v'].Value.Trim()
    $mode      = [regex]::Match($body, 'MODE:\s*(?<v>.+)').Groups['v'].Value.Trim().ToLowerInvariant()
    $find      = [regex]::Match($body, "FIND\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value
    $replace   = [regex]::Match($body, "REPLACE\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value

    if (-not $targetRel) { throw "PATCH missing TARGET" }
    if (-not $mode)      { throw "PATCH missing MODE" }
    if (-not $find)      { throw "PATCH missing FIND" }

    $target = Join-Path $RepoRoot $targetRel
    if (!(Test-Path $target)) {
  Write-Host "[SKIP] TARGET not found → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("target-not-found: "+$targetRel) } catch {}
  continue
}

    $orig = Get-Content -LiteralPath $target -Raw -Encoding UTF8
    $rxOpts = [Text.RegularExpressions.RegexOptions]::Multiline -bor [Text.RegularExpressions.RegexOptions]::Singleline
    $rx = [regex]::new($find, $rxOpts)
    $mt = $rx.Match($orig)
    if (-not $mt.Success) {
  Write-Host "[SKIP] FIND not matched → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("find-not-matched: "+$targetRel) } catch {}
  continue
}

    switch ($mode) {
      'insert-before' {
        $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
      }
      'insert-before' {
  $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
}
'insert-after' {
  $new = $orig.Substring(0, $mt.Index + $mt.Length) + "`n" + $replace + $orig.Substring($mt.Index + $mt.Length)
}
'replace' {
        $new = $rx.Replace($orig, $replace, 1)
      }
      default {
  Write-Host "[SKIP] Unsupported MODE → $mode for $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("unsupported-mode: "+$mode+" for "+$targetRel) } catch {}
  continue
}
    }

    if ($ConfirmApply) {
      $bk = "$target.bak-" + (Get-Date -Format 'yyyyMMdd-HHmmss')
      Copy-Item -LiteralPath $target -Destination $bk -Force
      Write-AtomicUtf8 -Path $target -Content $new -Module 'patcher' -Action ('apply:'+ $mode)
      $applied += $targetRel
    } else {
      Write-Host "[PREVIEW] would patch → $targetRel ($mode)"
    }
  }

  if ($ConfirmApply) {
    LogRec 'INFO' 'apply' 'SUCCESS' ("patched: " + ($applied -join ', '))
  } else {
    LogRec 'INFO' 'preview' 'SUCCESS' ("preview-ok (no writes). blocks="+$matches.Count)
  }

  # ── Gate-3 Verify (경량) ───────────────────────────────────────────────────────
  if ($ConfirmApply) {
    # 핵심 타겟의 구문 일치 재검
    $core = Join-Path $RepoRoot 'scripts\apply_ui_patch.ps1'
    if (Test-Path $core) {
      $c = Get-Content -LiteralPath $core -Raw -Encoding UTF8
      if ($c -notmatch 'ensure valid tmp path .* atomic friendly') {
        Write-Host "[WARN] VERIFY: guard snippet not found in apply_ui_patch.ps1"; try { LogRec "WARN" "verify" "SKIPPED" "guard-missing apply_ui_patch.ps1" } catch {}
      }
    }
  }
}
catch {
  LogRec 'ERROR' 'apply' 'FAILURE' $_.Exception.Message 'LOGIC'
  exit 0
}
finally {
  Remove-Item -Force $LockFile -ErrorAction SilentlyContinue
}
.Exception.Message)" }
}
try { Import-Module $ModPath -Force } catch { Write-Host "[WARN] Import-Module failed → $ModPath: $(# APPLY IN SHELL
#requires -Version 7.0
param([switch]$ConfirmApply,[string]$Root)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

# ── Gate-0: Repo / Lock ─────────────────────────────────────────────────────────
function Get-RepoRoot {
  try {
    $p = (git rev-parse --show-toplevel 2>$null)
    if ($p) { return (Resolve-Path $p).Path }
  } catch {}
  if ($Root) { return (Resolve-Path $Root).Path }
  return (Get-Location).Path
}
$RepoRoot = Get-RepoRoot
$LockFile = Join-Path $RepoRoot '.gpt5.lock'
if (Test-Path $LockFile) { Write-Error 'CONFLICT: .gpt5.lock exists.'; exit 11 }
"locked $(Get-Date -Format o)" | Out-File $LockFile -Encoding utf8 -NoNewline

$sw=[Diagnostics.Stopwatch]::StartNew()
$trace=[guid]::NewGuid().ToString()
$logPath = Join-Path $RepoRoot 'logs/apply-log.jsonl'
New-Item -ItemType Directory -Force -Path (Split-Path $logPath) | Out-Null

function LogRec([string]$level,[string]$action,[string]$outcome,[string]$msg,[string]$err='') {
  $rec = @{
    timestamp=(Get-Date).ToString('o'); level=$level; traceId=$trace; module='patcher';
    action=$action; inputHash=((Get-Variable -Name patchHash -Scope Global -ValueOnly -ErrorAction SilentlyContinue) ?? ""); outcome=$outcome;
    durationMs=$sw.ElapsedMilliseconds; errorCode=$err; message=$msg
  } | ConvertTo-Json -Compress
  Add-Content -Path $logPath -Value $rec
}

try {
  # ── Preflight: 모듈 로드 & 스모크 ─────────────────────────────────────────────
  $ModPath = Join-Path $RepoRoot 'scripts\lib\kobong-fileio.psm1'
  if (!(Test-Path $ModPath)) {
  Write-Host "[WARN] Missing module → $ModPath (continuing)"
  try { LogRec "WARN" "apply" "SKIPPED" ("missing-module: "+$ModPath) } catch {}
} else {
  try { Import-Module $ModPath -Force } catch { Write-Host "[WARN] Import-Module failed → $ModPath: $(# APPLY IN SHELL
#requires -Version 7.0
param([switch]$ConfirmApply,[string]$Root)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

# ── Gate-0: Repo / Lock ─────────────────────────────────────────────────────────
function Get-RepoRoot {
  try {
    $p = (git rev-parse --show-toplevel 2>$null)
    if ($p) { return (Resolve-Path $p).Path }
  } catch {}
  if ($Root) { return (Resolve-Path $Root).Path }
  return (Get-Location).Path
}
$RepoRoot = Get-RepoRoot
$LockFile = Join-Path $RepoRoot '.gpt5.lock'
if (Test-Path $LockFile) { Write-Error 'CONFLICT: .gpt5.lock exists.'; exit 11 }
"locked $(Get-Date -Format o)" | Out-File $LockFile -Encoding utf8 -NoNewline

$sw=[Diagnostics.Stopwatch]::StartNew()
$trace=[guid]::NewGuid().ToString()
$logPath = Join-Path $RepoRoot 'logs/apply-log.jsonl'
New-Item -ItemType Directory -Force -Path (Split-Path $logPath) | Out-Null

function LogRec([string]$level,[string]$action,[string]$outcome,[string]$msg,[string]$err='') {
  $rec = @{
    timestamp=(Get-Date).ToString('o'); level=$level; traceId=$trace; module='patcher';
    action=$action; inputHash=((Get-Variable -Name patchHash -Scope Global -ValueOnly -ErrorAction SilentlyContinue) ?? ""); outcome=$outcome;
    durationMs=$sw.ElapsedMilliseconds; errorCode=$err; message=$msg
  } | ConvertTo-Json -Compress
  Add-Content -Path $logPath -Value $rec
}

try {
  # ── Preflight: 모듈 로드 & 스모크 ─────────────────────────────────────────────
  $ModPath = Join-Path $RepoRoot 'scripts\lib\kobong-fileio.psm1'
  if (!(Test-Path $ModPath)) { throw "Missing module: $ModPath" }
try { Import-Module $ModPath -Force } catch { Write-Host "[WARN] Import-Module failed → $ModPath: $(# APPLY IN SHELL
#requires -Version 7.0
param([switch]$ConfirmApply,[string]$Root)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

# ── Gate-0: Repo / Lock ─────────────────────────────────────────────────────────
function Get-RepoRoot {
  try {
    $p = (git rev-parse --show-toplevel 2>$null)
    if ($p) { return (Resolve-Path $p).Path }
  } catch {}
  if ($Root) { return (Resolve-Path $Root).Path }
  return (Get-Location).Path
}
$RepoRoot = Get-RepoRoot
$LockFile = Join-Path $RepoRoot '.gpt5.lock'
if (Test-Path $LockFile) { Write-Error 'CONFLICT: .gpt5.lock exists.'; exit 11 }
"locked $(Get-Date -Format o)" | Out-File $LockFile -Encoding utf8 -NoNewline

$sw=[Diagnostics.Stopwatch]::StartNew()
$trace=[guid]::NewGuid().ToString()
$logPath = Join-Path $RepoRoot 'logs/apply-log.jsonl'
New-Item -ItemType Directory -Force -Path (Split-Path $logPath) | Out-Null

function LogRec([string]$level,[string]$action,[string]$outcome,[string]$msg,[string]$err='') {
  $rec = @{
    timestamp=(Get-Date).ToString('o'); level=$level; traceId=$trace; module='patcher';
    action=$action; inputHash=((Get-Variable -Name patchHash -Scope Global -ValueOnly -ErrorAction SilentlyContinue) ?? ""); outcome=$outcome;
    durationMs=$sw.ElapsedMilliseconds; errorCode=$err; message=$msg
  } | ConvertTo-Json -Compress
  Add-Content -Path $logPath -Value $rec
}

try {
  # ── Preflight: 모듈 로드 & 스모크 ─────────────────────────────────────────────
  $ModPath = Join-Path $RepoRoot 'scripts\lib\kobong-fileio.psm1'
  if (!(Test-Path $ModPath)) { throw "Missing module: $ModPath" }
  Import-Module $ModPath -Force

  # 스모크: 같은 볼륨에 원자 쓰기 → 즉시 삭제
  $smoke = Join-Path $RepoRoot 'webui\public\_klc-smoke.txt'
  $smokeContent = "[klc-smoke] $(Get-Date -Format o)"
  Write-AtomicUtf8 -Path $smoke -Content $smokeContent -Module 'patcher' -Action 'smoke'
  if (Test-Path $smoke) { Remove-Item -LiteralPath $smoke -Force -ErrorAction SilentlyContinue }

  # ── Patch 파일 파싱 ───────────────────────────────────────────────────────────
  $PatchFile = Join-Path $RepoRoot '.kobong\patches.pending.txt'
  if (!(Test-Path $PatchFile)) {
  Write-Host "[SKIP] patches file not found → $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("patches-file-missing: "+$PatchFile) } catch {}
  return
}
  $patchText = Get-Content -LiteralPath $PatchFile -Raw -Encoding UTF8
  $global:patchHash = (Get-FileHash -Algorithm SHA256 -InputStream ([IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes($patchText)))).Hash

  $matches = [regex]::Matches($patchText, '(?ms)#\s*PATCH\s*START\s*(?<body>.*?)#\s*PATCH\s*END')
  if ($matches.Count -eq 0) {
  Write-Host "[SKIP] No PATCH blocks found in $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("no-patch-blocks: "+$PatchFile) } catch {}
  return
}

  $applied = @()
  foreach ($m in $matches) {
    $body = $m.Groups['body'].Value

    $targetRel = [regex]::Match($body, 'TARGET:\s*(?<v>.+)').Groups['v'].Value.Trim()
    $mode      = [regex]::Match($body, 'MODE:\s*(?<v>.+)').Groups['v'].Value.Trim().ToLowerInvariant()
    $find      = [regex]::Match($body, "FIND\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value
    $replace   = [regex]::Match($body, "REPLACE\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value

    if (-not $targetRel) { throw "PATCH missing TARGET" }
    if (-not $mode)      { throw "PATCH missing MODE" }
    if (-not $find)      { throw "PATCH missing FIND" }

    $target = Join-Path $RepoRoot $targetRel
    if (!(Test-Path $target)) {
  Write-Host "[SKIP] TARGET not found → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("target-not-found: "+$targetRel) } catch {}
  continue
}

    $orig = Get-Content -LiteralPath $target -Raw -Encoding UTF8
    $rxOpts = [Text.RegularExpressions.RegexOptions]::Multiline -bor [Text.RegularExpressions.RegexOptions]::Singleline
    $rx = [regex]::new($find, $rxOpts)
    $mt = $rx.Match($orig)
    if (-not $mt.Success) {
  Write-Host "[SKIP] FIND not matched → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("find-not-matched: "+$targetRel) } catch {}
  continue
}

    switch ($mode) {
      'insert-before' {
        $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
      }
      'insert-before' {
  $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
}
'insert-after' {
  $new = $orig.Substring(0, $mt.Index + $mt.Length) + "`n" + $replace + $orig.Substring($mt.Index + $mt.Length)
}
'replace' {
        $new = $rx.Replace($orig, $replace, 1)
      }
      default {
  Write-Host "[SKIP] Unsupported MODE → $mode for $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("unsupported-mode: "+$mode+" for "+$targetRel) } catch {}
  continue
}
    }

    if ($ConfirmApply) {
      $bk = "$target.bak-" + (Get-Date -Format 'yyyyMMdd-HHmmss')
      Copy-Item -LiteralPath $target -Destination $bk -Force
      Write-AtomicUtf8 -Path $target -Content $new -Module 'patcher' -Action ('apply:'+ $mode)
      $applied += $targetRel
    } else {
      Write-Host "[PREVIEW] would patch → $targetRel ($mode)"
    }
  }

  if ($ConfirmApply) {
    LogRec 'INFO' 'apply' 'SUCCESS' ("patched: " + ($applied -join ', '))
  } else {
    LogRec 'INFO' 'preview' 'SUCCESS' ("preview-ok (no writes). blocks="+$matches.Count)
  }

  # ── Gate-3 Verify (경량) ───────────────────────────────────────────────────────
  if ($ConfirmApply) {
    # 핵심 타겟의 구문 일치 재검
    $core = Join-Path $RepoRoot 'scripts\apply_ui_patch.ps1'
    if (Test-Path $core) {
      $c = Get-Content -LiteralPath $core -Raw -Encoding UTF8
      if ($c -notmatch 'ensure valid tmp path .* atomic friendly') {
        Write-Host "[WARN] VERIFY: guard snippet not found in apply_ui_patch.ps1"; try { LogRec "WARN" "verify" "SKIPPED" "guard-missing apply_ui_patch.ps1" } catch {}
      }
    }
  }
}
catch {
  LogRec 'ERROR' 'apply' 'FAILURE' $_.Exception.Message 'LOGIC'
  exit 0
}
finally {
  Remove-Item -Force $LockFile -ErrorAction SilentlyContinue
}
.Exception.Message)" }
  # 스모크: 같은 볼륨에 원자 쓰기 → 즉시 삭제
  $smoke = Join-Path $RepoRoot 'webui\public\_klc-smoke.txt'
  $smokeContent = "[klc-smoke] $(Get-Date -Format o)"
  Write-AtomicUtf8 -Path $smoke -Content $smokeContent -Module 'patcher' -Action 'smoke'
  if (Test-Path $smoke) { Remove-Item -LiteralPath $smoke -Force -ErrorAction SilentlyContinue }

  # ── Patch 파일 파싱 ───────────────────────────────────────────────────────────
  $PatchFile = Join-Path $RepoRoot '.kobong\patches.pending.txt'
  if (!(Test-Path $PatchFile)) {
  Write-Host "[SKIP] patches file not found → $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("patches-file-missing: "+$PatchFile) } catch {}
  return
}
  $patchText = Get-Content -LiteralPath $PatchFile -Raw -Encoding UTF8
  $global:patchHash = (Get-FileHash -Algorithm SHA256 -InputStream ([IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes($patchText)))).Hash

  $matches = [regex]::Matches($patchText, '(?ms)#\s*PATCH\s*START\s*(?<body>.*?)#\s*PATCH\s*END')
  if ($matches.Count -eq 0) {
  Write-Host "[SKIP] No PATCH blocks found in $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("no-patch-blocks: "+$PatchFile) } catch {}
  return
}

  $applied = @()
  foreach ($m in $matches) {
    $body = $m.Groups['body'].Value

    $targetRel = [regex]::Match($body, 'TARGET:\s*(?<v>.+)').Groups['v'].Value.Trim()
    $mode      = [regex]::Match($body, 'MODE:\s*(?<v>.+)').Groups['v'].Value.Trim().ToLowerInvariant()
    $find      = [regex]::Match($body, "FIND\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value
    $replace   = [regex]::Match($body, "REPLACE\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value

    if (-not $targetRel) { throw "PATCH missing TARGET" }
    if (-not $mode)      { throw "PATCH missing MODE" }
    if (-not $find)      { throw "PATCH missing FIND" }

    $target = Join-Path $RepoRoot $targetRel
    if (!(Test-Path $target)) {
  Write-Host "[SKIP] TARGET not found → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("target-not-found: "+$targetRel) } catch {}
  continue
}

    $orig = Get-Content -LiteralPath $target -Raw -Encoding UTF8
    $rxOpts = [Text.RegularExpressions.RegexOptions]::Multiline -bor [Text.RegularExpressions.RegexOptions]::Singleline
    $rx = [regex]::new($find, $rxOpts)
    $mt = $rx.Match($orig)
    if (-not $mt.Success) {
  Write-Host "[SKIP] FIND not matched → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("find-not-matched: "+$targetRel) } catch {}
  continue
}

    switch ($mode) {
      'insert-before' {
        $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
      }
      'insert-before' {
  $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
}
'insert-after' {
  $new = $orig.Substring(0, $mt.Index + $mt.Length) + "`n" + $replace + $orig.Substring($mt.Index + $mt.Length)
}
'replace' {
        $new = $rx.Replace($orig, $replace, 1)
      }
      default {
  Write-Host "[SKIP] Unsupported MODE → $mode for $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("unsupported-mode: "+$mode+" for "+$targetRel) } catch {}
  continue
}
    }

    if ($ConfirmApply) {
      $bk = "$target.bak-" + (Get-Date -Format 'yyyyMMdd-HHmmss')
      Copy-Item -LiteralPath $target -Destination $bk -Force
      Write-AtomicUtf8 -Path $target -Content $new -Module 'patcher' -Action ('apply:'+ $mode)
      $applied += $targetRel
    } else {
      Write-Host "[PREVIEW] would patch → $targetRel ($mode)"
    }
  }

  if ($ConfirmApply) {
    LogRec 'INFO' 'apply' 'SUCCESS' ("patched: " + ($applied -join ', '))
  } else {
    LogRec 'INFO' 'preview' 'SUCCESS' ("preview-ok (no writes). blocks="+$matches.Count)
  }

  # ── Gate-3 Verify (경량) ───────────────────────────────────────────────────────
  if ($ConfirmApply) {
    # 핵심 타겟의 구문 일치 재검
    $core = Join-Path $RepoRoot 'scripts\apply_ui_patch.ps1'
    if (Test-Path $core) {
      $c = Get-Content -LiteralPath $core -Raw -Encoding UTF8
      if ($c -notmatch 'ensure valid tmp path .* atomic friendly') {
        Write-Host "[WARN] VERIFY: guard snippet not found in apply_ui_patch.ps1"; try { LogRec "WARN" "verify" "SKIPPED" "guard-missing apply_ui_patch.ps1" } catch {}
      }
    }
  }
}
catch {
  LogRec 'ERROR' 'apply' 'FAILURE' $_.Exception.Message 'LOGIC'
  exit 0
}
finally {
  Remove-Item -Force $LockFile -ErrorAction SilentlyContinue
}
.Exception.Message)" }
}
  Import-Module $ModPath -Force

  # 스모크: 같은 볼륨에 원자 쓰기 → 즉시 삭제
  $smoke = Join-Path $RepoRoot 'webui\public\_klc-smoke.txt'
  $smokeContent = "[klc-smoke] $(Get-Date -Format o)"
  Write-AtomicUtf8 -Path $smoke -Content $smokeContent -Module 'patcher' -Action 'smoke'
  if (Test-Path $smoke) { Remove-Item -LiteralPath $smoke -Force -ErrorAction SilentlyContinue }

  # ── Patch 파일 파싱 ───────────────────────────────────────────────────────────
  $PatchFile = Join-Path $RepoRoot '.kobong\patches.pending.txt'
  if (!(Test-Path $PatchFile)) {
  Write-Host "[SKIP] patches file not found → $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("patches-file-missing: "+$PatchFile) } catch {}
  return
}
  $patchText = Get-Content -LiteralPath $PatchFile -Raw -Encoding UTF8
  $global:patchHash = (Get-FileHash -Algorithm SHA256 -InputStream ([IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes($patchText)))).Hash

  $matches = [regex]::Matches($patchText, '(?ms)#\s*PATCH\s*START\s*(?<body>.*?)#\s*PATCH\s*END')
  if ($matches.Count -eq 0) {
  Write-Host "[SKIP] No PATCH blocks found in $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("no-patch-blocks: "+$PatchFile) } catch {}
  return
}

  $applied = @()
  foreach ($m in $matches) {
    $body = $m.Groups['body'].Value

    $targetRel = [regex]::Match($body, 'TARGET:\s*(?<v>.+)').Groups['v'].Value.Trim()
    $mode      = [regex]::Match($body, 'MODE:\s*(?<v>.+)').Groups['v'].Value.Trim().ToLowerInvariant()
    $find      = [regex]::Match($body, "FIND\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value
    $replace   = [regex]::Match($body, "REPLACE\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value

    if (-not $targetRel) { throw "PATCH missing TARGET" }
    if (-not $mode)      { throw "PATCH missing MODE" }
    if (-not $find)      { throw "PATCH missing FIND" }

    $target = Join-Path $RepoRoot $targetRel
    if (!(Test-Path $target)) {
  Write-Host "[SKIP] TARGET not found → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("target-not-found: "+$targetRel) } catch {}
  continue
}

    $orig = Get-Content -LiteralPath $target -Raw -Encoding UTF8
    $rxOpts = [Text.RegularExpressions.RegexOptions]::Multiline -bor [Text.RegularExpressions.RegexOptions]::Singleline
    $rx = [regex]::new($find, $rxOpts)
    $mt = $rx.Match($orig)
    if (-not $mt.Success) {
  Write-Host "[SKIP] FIND not matched → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("find-not-matched: "+$targetRel) } catch {}
  continue
}

    switch ($mode) {
      'insert-before' {
        $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
      }
      'insert-before' {
  $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
}
'insert-after' {
  $new = $orig.Substring(0, $mt.Index + $mt.Length) + "`n" + $replace + $orig.Substring($mt.Index + $mt.Length)
}
'replace' {
        $new = $rx.Replace($orig, $replace, 1)
      }
      default {
  Write-Host "[SKIP] Unsupported MODE → $mode for $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("unsupported-mode: "+$mode+" for "+$targetRel) } catch {}
  continue
}
    }

    if ($ConfirmApply) {
      $bk = "$target.bak-" + (Get-Date -Format 'yyyyMMdd-HHmmss')
      Copy-Item -LiteralPath $target -Destination $bk -Force
      Write-AtomicUtf8 -Path $target -Content $new -Module 'patcher' -Action ('apply:'+ $mode)
      $applied += $targetRel
    } else {
      Write-Host "[PREVIEW] would patch → $targetRel ($mode)"
    }
  }

  if ($ConfirmApply) {
    LogRec 'INFO' 'apply' 'SUCCESS' ("patched: " + ($applied -join ', '))
  } else {
    LogRec 'INFO' 'preview' 'SUCCESS' ("preview-ok (no writes). blocks="+$matches.Count)
  }

  # ── Gate-3 Verify (경량) ───────────────────────────────────────────────────────
  if ($ConfirmApply) {
    # 핵심 타겟의 구문 일치 재검
    $core = Join-Path $RepoRoot 'scripts\apply_ui_patch.ps1'
    if (Test-Path $core) {
      $c = Get-Content -LiteralPath $core -Raw -Encoding UTF8
      if ($c -notmatch 'ensure valid tmp path .* atomic friendly') {
        Write-Host "[WARN] VERIFY: guard snippet not found in apply_ui_patch.ps1"; try { LogRec "WARN" "verify" "SKIPPED" "guard-missing apply_ui_patch.ps1" } catch {}
      }
    }
  }
}
catch {
  LogRec 'ERROR' 'apply' 'FAILURE' $_.Exception.Message 'LOGIC'
  exit 0
}
finally {
  Remove-Item -Force $LockFile -ErrorAction SilentlyContinue
}
.Exception.Message)" }
  # 스모크: 같은 볼륨에 원자 쓰기 → 즉시 삭제
  $smoke = Join-Path $RepoRoot 'webui\public\_klc-smoke.txt'
  $smokeContent = "[klc-smoke] $(Get-Date -Format o)"
  Write-AtomicUtf8 -Path $smoke -Content $smokeContent -Module 'patcher' -Action 'smoke'
  if (Test-Path $smoke) { Remove-Item -LiteralPath $smoke -Force -ErrorAction SilentlyContinue }

  # ── Patch 파일 파싱 ───────────────────────────────────────────────────────────
  $PatchFile = Join-Path $RepoRoot '.kobong\patches.pending.txt'
  if (!(Test-Path $PatchFile)) {
  Write-Host "[SKIP] patches file not found → $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("patches-file-missing: "+$PatchFile) } catch {}
  return
}
  $patchText = Get-Content -LiteralPath $PatchFile -Raw -Encoding UTF8
  $global:patchHash = (Get-FileHash -Algorithm SHA256 -InputStream ([IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes($patchText)))).Hash

  $matches = [regex]::Matches($patchText, '(?ms)#\s*PATCH\s*START\s*(?<body>.*?)#\s*PATCH\s*END')
  if ($matches.Count -eq 0) {
  Write-Host "[SKIP] No PATCH blocks found in $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("no-patch-blocks: "+$PatchFile) } catch {}
  return
}

  $applied = @()
  foreach ($m in $matches) {
    $body = $m.Groups['body'].Value

    $targetRel = [regex]::Match($body, 'TARGET:\s*(?<v>.+)').Groups['v'].Value.Trim()
    $mode      = [regex]::Match($body, 'MODE:\s*(?<v>.+)').Groups['v'].Value.Trim().ToLowerInvariant()
    $find      = [regex]::Match($body, "FIND\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value
    $replace   = [regex]::Match($body, "REPLACE\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value

    if (-not $targetRel) { throw "PATCH missing TARGET" }
    if (-not $mode)      { throw "PATCH missing MODE" }
    if (-not $find)      { throw "PATCH missing FIND" }

    $target = Join-Path $RepoRoot $targetRel
    if (!(Test-Path $target)) {
  Write-Host "[SKIP] TARGET not found → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("target-not-found: "+$targetRel) } catch {}
  continue
}

    $orig = Get-Content -LiteralPath $target -Raw -Encoding UTF8
    $rxOpts = [Text.RegularExpressions.RegexOptions]::Multiline -bor [Text.RegularExpressions.RegexOptions]::Singleline
    $rx = [regex]::new($find, $rxOpts)
    $mt = $rx.Match($orig)
    if (-not $mt.Success) {
  Write-Host "[SKIP] FIND not matched → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("find-not-matched: "+$targetRel) } catch {}
  continue
}

    switch ($mode) {
      'insert-before' {
        $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
      }
      'insert-before' {
  $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
}
'insert-after' {
  $new = $orig.Substring(0, $mt.Index + $mt.Length) + "`n" + $replace + $orig.Substring($mt.Index + $mt.Length)
}
'replace' {
        $new = $rx.Replace($orig, $replace, 1)
      }
      default {
  Write-Host "[SKIP] Unsupported MODE → $mode for $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("unsupported-mode: "+$mode+" for "+$targetRel) } catch {}
  continue
}
    }

    if ($ConfirmApply) {
      $bk = "$target.bak-" + (Get-Date -Format 'yyyyMMdd-HHmmss')
      Copy-Item -LiteralPath $target -Destination $bk -Force
      Write-AtomicUtf8 -Path $target -Content $new -Module 'patcher' -Action ('apply:'+ $mode)
      $applied += $targetRel
    } else {
      Write-Host "[PREVIEW] would patch → $targetRel ($mode)"
    }
  }

  if ($ConfirmApply) {
    LogRec 'INFO' 'apply' 'SUCCESS' ("patched: " + ($applied -join ', '))
  } else {
    LogRec 'INFO' 'preview' 'SUCCESS' ("preview-ok (no writes). blocks="+$matches.Count)
  }

  # ── Gate-3 Verify (경량) ───────────────────────────────────────────────────────
  if ($ConfirmApply) {
    # 핵심 타겟의 구문 일치 재검
    $core = Join-Path $RepoRoot 'scripts\apply_ui_patch.ps1'
    if (Test-Path $core) {
      $c = Get-Content -LiteralPath $core -Raw -Encoding UTF8
      if ($c -notmatch 'ensure valid tmp path .* atomic friendly') {
        Write-Host "[WARN] VERIFY: guard snippet not found in apply_ui_patch.ps1"; try { LogRec "WARN" "verify" "SKIPPED" "guard-missing apply_ui_patch.ps1" } catch {}
      }
    }
  }
}
catch {
  LogRec 'ERROR' 'apply' 'FAILURE' $_.Exception.Message 'LOGIC'
  exit 0
}
finally {
  Remove-Item -Force $LockFile -ErrorAction SilentlyContinue
}
.Exception.Message) }

# ── Gate-0: Repo / Lock ─────────────────────────────────────────────────────────
function Get-RepoRoot {
  try {
    $p = (git rev-parse --show-toplevel 2>$null)
    if ($p) { return (Resolve-Path $p).Path }
  } catch {}
  if ($Root) { return (Resolve-Path $Root).Path }
  return (Get-Location).Path
}
$RepoRoot = Get-RepoRoot
$LockFile = Join-Path $RepoRoot '.gpt5.lock'
if (Test-Path $LockFile) { Write-Error 'CONFLICT: .gpt5.lock exists.'; exit 11 }
"locked $(Get-Date -Format o)" | Out-File $LockFile -Encoding utf8 -NoNewline

$sw=[Diagnostics.Stopwatch]::StartNew()
$trace=[guid]::NewGuid().ToString()
$logPath = Join-Path $RepoRoot 'logs/apply-log.jsonl'
New-Item -ItemType Directory -Force -Path (Split-Path $logPath) | Out-Null

function LogRec([string]$level,[string]$action,[string]$outcome,[string]$msg,[string]$err='') {
  $rec = @{
    timestamp=(Get-Date).ToString('o'); level=$level; traceId=$trace; module='patcher';
    action=$action; inputHash=((Get-Variable -Name patchHash -Scope Global -ValueOnly -ErrorAction SilentlyContinue) ?? ""); outcome=$outcome;
    durationMs=$sw.ElapsedMilliseconds; errorCode=$err; message=$msg
  } | ConvertTo-Json -Compress
  Add-Content -Path $logPath -Value $rec
}

try {
  # ── Preflight: 모듈 로드 & 스모크 ─────────────────────────────────────────────
  $ModPath = Join-Path $RepoRoot 'scripts\lib\kobong-fileio.psm1'
  if (!(Test-Path $ModPath)) { throw "Missing module: $ModPath" }
try { Import-Module $ModPath -Force } catch { Write-Host "[WARN] Import-Module failed → $ModPath: $(# APPLY IN SHELL
#requires -Version 7.0
param([switch]$ConfirmApply,[string]$Root)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

# ── Gate-0: Repo / Lock ─────────────────────────────────────────────────────────
function Get-RepoRoot {
  try {
    $p = (git rev-parse --show-toplevel 2>$null)
    if ($p) { return (Resolve-Path $p).Path }
  } catch {}
  if ($Root) { return (Resolve-Path $Root).Path }
  return (Get-Location).Path
}
$RepoRoot = Get-RepoRoot
$LockFile = Join-Path $RepoRoot '.gpt5.lock'
if (Test-Path $LockFile) { Write-Error 'CONFLICT: .gpt5.lock exists.'; exit 11 }
"locked $(Get-Date -Format o)" | Out-File $LockFile -Encoding utf8 -NoNewline

$sw=[Diagnostics.Stopwatch]::StartNew()
$trace=[guid]::NewGuid().ToString()
$logPath = Join-Path $RepoRoot 'logs/apply-log.jsonl'
New-Item -ItemType Directory -Force -Path (Split-Path $logPath) | Out-Null

function LogRec([string]$level,[string]$action,[string]$outcome,[string]$msg,[string]$err='') {
  $rec = @{
    timestamp=(Get-Date).ToString('o'); level=$level; traceId=$trace; module='patcher';
    action=$action; inputHash=((Get-Variable -Name patchHash -Scope Global -ValueOnly -ErrorAction SilentlyContinue) ?? ""); outcome=$outcome;
    durationMs=$sw.ElapsedMilliseconds; errorCode=$err; message=$msg
  } | ConvertTo-Json -Compress
  Add-Content -Path $logPath -Value $rec
}

try {
  # ── Preflight: 모듈 로드 & 스모크 ─────────────────────────────────────────────
  $ModPath = Join-Path $RepoRoot 'scripts\lib\kobong-fileio.psm1'
  if (!(Test-Path $ModPath)) { throw "Missing module: $ModPath" }
  Import-Module $ModPath -Force

  # 스모크: 같은 볼륨에 원자 쓰기 → 즉시 삭제
  $smoke = Join-Path $RepoRoot 'webui\public\_klc-smoke.txt'
  $smokeContent = "[klc-smoke] $(Get-Date -Format o)"
  Write-AtomicUtf8 -Path $smoke -Content $smokeContent -Module 'patcher' -Action 'smoke'
  if (Test-Path $smoke) { Remove-Item -LiteralPath $smoke -Force -ErrorAction SilentlyContinue }

  # ── Patch 파일 파싱 ───────────────────────────────────────────────────────────
  $PatchFile = Join-Path $RepoRoot '.kobong\patches.pending.txt'
  if (!(Test-Path $PatchFile)) {
  Write-Host "[SKIP] patches file not found → $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("patches-file-missing: "+$PatchFile) } catch {}
  return
}
  $patchText = Get-Content -LiteralPath $PatchFile -Raw -Encoding UTF8
  $global:patchHash = (Get-FileHash -Algorithm SHA256 -InputStream ([IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes($patchText)))).Hash

  $matches = [regex]::Matches($patchText, '(?ms)#\s*PATCH\s*START\s*(?<body>.*?)#\s*PATCH\s*END')
  if ($matches.Count -eq 0) {
  Write-Host "[SKIP] No PATCH blocks found in $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("no-patch-blocks: "+$PatchFile) } catch {}
  return
}

  $applied = @()
  foreach ($m in $matches) {
    $body = $m.Groups['body'].Value

    $targetRel = [regex]::Match($body, 'TARGET:\s*(?<v>.+)').Groups['v'].Value.Trim()
    $mode      = [regex]::Match($body, 'MODE:\s*(?<v>.+)').Groups['v'].Value.Trim().ToLowerInvariant()
    $find      = [regex]::Match($body, "FIND\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value
    $replace   = [regex]::Match($body, "REPLACE\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value

    if (-not $targetRel) { throw "PATCH missing TARGET" }
    if (-not $mode)      { throw "PATCH missing MODE" }
    if (-not $find)      { throw "PATCH missing FIND" }

    $target = Join-Path $RepoRoot $targetRel
    if (!(Test-Path $target)) {
  Write-Host "[SKIP] TARGET not found → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("target-not-found: "+$targetRel) } catch {}
  continue
}

    $orig = Get-Content -LiteralPath $target -Raw -Encoding UTF8
    $rxOpts = [Text.RegularExpressions.RegexOptions]::Multiline -bor [Text.RegularExpressions.RegexOptions]::Singleline
    $rx = [regex]::new($find, $rxOpts)
    $mt = $rx.Match($orig)
    if (-not $mt.Success) {
  Write-Host "[SKIP] FIND not matched → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("find-not-matched: "+$targetRel) } catch {}
  continue
}

    switch ($mode) {
      'insert-before' {
        $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
      }
      'insert-before' {
  $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
}
'insert-after' {
  $new = $orig.Substring(0, $mt.Index + $mt.Length) + "`n" + $replace + $orig.Substring($mt.Index + $mt.Length)
}
'replace' {
        $new = $rx.Replace($orig, $replace, 1)
      }
      default {
  Write-Host "[SKIP] Unsupported MODE → $mode for $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("unsupported-mode: "+$mode+" for "+$targetRel) } catch {}
  continue
}
    }

    if ($ConfirmApply) {
      $bk = "$target.bak-" + (Get-Date -Format 'yyyyMMdd-HHmmss')
      Copy-Item -LiteralPath $target -Destination $bk -Force
      Write-AtomicUtf8 -Path $target -Content $new -Module 'patcher' -Action ('apply:'+ $mode)
      $applied += $targetRel
    } else {
      Write-Host "[PREVIEW] would patch → $targetRel ($mode)"
    }
  }

  if ($ConfirmApply) {
    LogRec 'INFO' 'apply' 'SUCCESS' ("patched: " + ($applied -join ', '))
  } else {
    LogRec 'INFO' 'preview' 'SUCCESS' ("preview-ok (no writes). blocks="+$matches.Count)
  }

  # ── Gate-3 Verify (경량) ───────────────────────────────────────────────────────
  if ($ConfirmApply) {
    # 핵심 타겟의 구문 일치 재검
    $core = Join-Path $RepoRoot 'scripts\apply_ui_patch.ps1'
    if (Test-Path $core) {
      $c = Get-Content -LiteralPath $core -Raw -Encoding UTF8
      if ($c -notmatch 'ensure valid tmp path .* atomic friendly') {
        Write-Host "[WARN] VERIFY: guard snippet not found in apply_ui_patch.ps1"; try { LogRec "WARN" "verify" "SKIPPED" "guard-missing apply_ui_patch.ps1" } catch {}
      }
    }
  }
}
catch {
  LogRec 'ERROR' 'apply' 'FAILURE' $_.Exception.Message 'LOGIC'
  exit 0
}
finally {
  Remove-Item -Force $LockFile -ErrorAction SilentlyContinue
}
.Exception.Message)" }
  # 스모크: 같은 볼륨에 원자 쓰기 → 즉시 삭제
  $smoke = Join-Path $RepoRoot 'webui\public\_klc-smoke.txt'
  $smokeContent = "[klc-smoke] $(Get-Date -Format o)"
  Write-AtomicUtf8 -Path $smoke -Content $smokeContent -Module 'patcher' -Action 'smoke'
  if (Test-Path $smoke) { Remove-Item -LiteralPath $smoke -Force -ErrorAction SilentlyContinue }

  # ── Patch 파일 파싱 ───────────────────────────────────────────────────────────
  $PatchFile = Join-Path $RepoRoot '.kobong\patches.pending.txt'
  if (!(Test-Path $PatchFile)) {
  Write-Host "[SKIP] patches file not found → $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("patches-file-missing: "+$PatchFile) } catch {}
  return
}
  $patchText = Get-Content -LiteralPath $PatchFile -Raw -Encoding UTF8
  $global:patchHash = (Get-FileHash -Algorithm SHA256 -InputStream ([IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes($patchText)))).Hash

  $matches = [regex]::Matches($patchText, '(?ms)#\s*PATCH\s*START\s*(?<body>.*?)#\s*PATCH\s*END')
  if ($matches.Count -eq 0) {
  Write-Host "[SKIP] No PATCH blocks found in $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("no-patch-blocks: "+$PatchFile) } catch {}
  return
}

  $applied = @()
  foreach ($m in $matches) {
    $body = $m.Groups['body'].Value

    $targetRel = [regex]::Match($body, 'TARGET:\s*(?<v>.+)').Groups['v'].Value.Trim()
    $mode      = [regex]::Match($body, 'MODE:\s*(?<v>.+)').Groups['v'].Value.Trim().ToLowerInvariant()
    $find      = [regex]::Match($body, "FIND\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value
    $replace   = [regex]::Match($body, "REPLACE\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value

    if (-not $targetRel) { throw "PATCH missing TARGET" }
    if (-not $mode)      { throw "PATCH missing MODE" }
    if (-not $find)      { throw "PATCH missing FIND" }

    $target = Join-Path $RepoRoot $targetRel
    if (!(Test-Path $target)) {
  Write-Host "[SKIP] TARGET not found → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("target-not-found: "+$targetRel) } catch {}
  continue
}

    $orig = Get-Content -LiteralPath $target -Raw -Encoding UTF8
    $rxOpts = [Text.RegularExpressions.RegexOptions]::Multiline -bor [Text.RegularExpressions.RegexOptions]::Singleline
    $rx = [regex]::new($find, $rxOpts)
    $mt = $rx.Match($orig)
    if (-not $mt.Success) {
  Write-Host "[SKIP] FIND not matched → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("find-not-matched: "+$targetRel) } catch {}
  continue
}

    switch ($mode) {
      'insert-before' {
        $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
      }
      'insert-before' {
  $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
}
'insert-after' {
  $new = $orig.Substring(0, $mt.Index + $mt.Length) + "`n" + $replace + $orig.Substring($mt.Index + $mt.Length)
}
'replace' {
        $new = $rx.Replace($orig, $replace, 1)
      }
      default {
  Write-Host "[SKIP] Unsupported MODE → $mode for $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("unsupported-mode: "+$mode+" for "+$targetRel) } catch {}
  continue
}
    }

    if ($ConfirmApply) {
      $bk = "$target.bak-" + (Get-Date -Format 'yyyyMMdd-HHmmss')
      Copy-Item -LiteralPath $target -Destination $bk -Force
      Write-AtomicUtf8 -Path $target -Content $new -Module 'patcher' -Action ('apply:'+ $mode)
      $applied += $targetRel
    } else {
      Write-Host "[PREVIEW] would patch → $targetRel ($mode)"
    }
  }

  if ($ConfirmApply) {
    LogRec 'INFO' 'apply' 'SUCCESS' ("patched: " + ($applied -join ', '))
  } else {
    LogRec 'INFO' 'preview' 'SUCCESS' ("preview-ok (no writes). blocks="+$matches.Count)
  }

  # ── Gate-3 Verify (경량) ───────────────────────────────────────────────────────
  if ($ConfirmApply) {
    # 핵심 타겟의 구문 일치 재검
    $core = Join-Path $RepoRoot 'scripts\apply_ui_patch.ps1'
    if (Test-Path $core) {
      $c = Get-Content -LiteralPath $core -Raw -Encoding UTF8
      if ($c -notmatch 'ensure valid tmp path .* atomic friendly') {
        Write-Host "[WARN] VERIFY: guard snippet not found in apply_ui_patch.ps1"; try { LogRec "WARN" "verify" "SKIPPED" "guard-missing apply_ui_patch.ps1" } catch {}
      }
    }
  }
}
catch {
  LogRec 'ERROR' 'apply' 'FAILURE' $_.Exception.Message 'LOGIC'
  exit 0
}
finally {
  Remove-Item -Force $LockFile -ErrorAction SilentlyContinue
}
.Exception.Message)" }
}
try { Import-Module $ModPath -Force } catch { Write-Host "[WARN] Import-Module failed → $ModPath: $(# APPLY IN SHELL
#requires -Version 7.0
param([switch]$ConfirmApply,[string]$Root)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

# ── Gate-0: Repo / Lock ─────────────────────────────────────────────────────────
function Get-RepoRoot {
  try {
    $p = (git rev-parse --show-toplevel 2>$null)
    if ($p) { return (Resolve-Path $p).Path }
  } catch {}
  if ($Root) { return (Resolve-Path $Root).Path }
  return (Get-Location).Path
}
$RepoRoot = Get-RepoRoot
$LockFile = Join-Path $RepoRoot '.gpt5.lock'
if (Test-Path $LockFile) { Write-Error 'CONFLICT: .gpt5.lock exists.'; exit 11 }
"locked $(Get-Date -Format o)" | Out-File $LockFile -Encoding utf8 -NoNewline

$sw=[Diagnostics.Stopwatch]::StartNew()
$trace=[guid]::NewGuid().ToString()
$logPath = Join-Path $RepoRoot 'logs/apply-log.jsonl'
New-Item -ItemType Directory -Force -Path (Split-Path $logPath) | Out-Null

function LogRec([string]$level,[string]$action,[string]$outcome,[string]$msg,[string]$err='') {
  $rec = @{
    timestamp=(Get-Date).ToString('o'); level=$level; traceId=$trace; module='patcher';
    action=$action; inputHash=((Get-Variable -Name patchHash -Scope Global -ValueOnly -ErrorAction SilentlyContinue) ?? ""); outcome=$outcome;
    durationMs=$sw.ElapsedMilliseconds; errorCode=$err; message=$msg
  } | ConvertTo-Json -Compress
  Add-Content -Path $logPath -Value $rec
}

try {
  # ── Preflight: 모듈 로드 & 스모크 ─────────────────────────────────────────────
  $ModPath = Join-Path $RepoRoot 'scripts\lib\kobong-fileio.psm1'
  if (!(Test-Path $ModPath)) {
  Write-Host "[WARN] Missing module → $ModPath (continuing)"
  try { LogRec "WARN" "apply" "SKIPPED" ("missing-module: "+$ModPath) } catch {}
} else {
  try { Import-Module $ModPath -Force } catch { Write-Host "[WARN] Import-Module failed → $ModPath: $(# APPLY IN SHELL
#requires -Version 7.0
param([switch]$ConfirmApply,[string]$Root)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

# ── Gate-0: Repo / Lock ─────────────────────────────────────────────────────────
function Get-RepoRoot {
  try {
    $p = (git rev-parse --show-toplevel 2>$null)
    if ($p) { return (Resolve-Path $p).Path }
  } catch {}
  if ($Root) { return (Resolve-Path $Root).Path }
  return (Get-Location).Path
}
$RepoRoot = Get-RepoRoot
$LockFile = Join-Path $RepoRoot '.gpt5.lock'
if (Test-Path $LockFile) { Write-Error 'CONFLICT: .gpt5.lock exists.'; exit 11 }
"locked $(Get-Date -Format o)" | Out-File $LockFile -Encoding utf8 -NoNewline

$sw=[Diagnostics.Stopwatch]::StartNew()
$trace=[guid]::NewGuid().ToString()
$logPath = Join-Path $RepoRoot 'logs/apply-log.jsonl'
New-Item -ItemType Directory -Force -Path (Split-Path $logPath) | Out-Null

function LogRec([string]$level,[string]$action,[string]$outcome,[string]$msg,[string]$err='') {
  $rec = @{
    timestamp=(Get-Date).ToString('o'); level=$level; traceId=$trace; module='patcher';
    action=$action; inputHash=((Get-Variable -Name patchHash -Scope Global -ValueOnly -ErrorAction SilentlyContinue) ?? ""); outcome=$outcome;
    durationMs=$sw.ElapsedMilliseconds; errorCode=$err; message=$msg
  } | ConvertTo-Json -Compress
  Add-Content -Path $logPath -Value $rec
}

try {
  # ── Preflight: 모듈 로드 & 스모크 ─────────────────────────────────────────────
  $ModPath = Join-Path $RepoRoot 'scripts\lib\kobong-fileio.psm1'
  if (!(Test-Path $ModPath)) { throw "Missing module: $ModPath" }
try { Import-Module $ModPath -Force } catch { Write-Host "[WARN] Import-Module failed → $ModPath: $(# APPLY IN SHELL
#requires -Version 7.0
param([switch]$ConfirmApply,[string]$Root)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

# ── Gate-0: Repo / Lock ─────────────────────────────────────────────────────────
function Get-RepoRoot {
  try {
    $p = (git rev-parse --show-toplevel 2>$null)
    if ($p) { return (Resolve-Path $p).Path }
  } catch {}
  if ($Root) { return (Resolve-Path $Root).Path }
  return (Get-Location).Path
}
$RepoRoot = Get-RepoRoot
$LockFile = Join-Path $RepoRoot '.gpt5.lock'
if (Test-Path $LockFile) { Write-Error 'CONFLICT: .gpt5.lock exists.'; exit 11 }
"locked $(Get-Date -Format o)" | Out-File $LockFile -Encoding utf8 -NoNewline

$sw=[Diagnostics.Stopwatch]::StartNew()
$trace=[guid]::NewGuid().ToString()
$logPath = Join-Path $RepoRoot 'logs/apply-log.jsonl'
New-Item -ItemType Directory -Force -Path (Split-Path $logPath) | Out-Null

function LogRec([string]$level,[string]$action,[string]$outcome,[string]$msg,[string]$err='') {
  $rec = @{
    timestamp=(Get-Date).ToString('o'); level=$level; traceId=$trace; module='patcher';
    action=$action; inputHash=((Get-Variable -Name patchHash -Scope Global -ValueOnly -ErrorAction SilentlyContinue) ?? ""); outcome=$outcome;
    durationMs=$sw.ElapsedMilliseconds; errorCode=$err; message=$msg
  } | ConvertTo-Json -Compress
  Add-Content -Path $logPath -Value $rec
}

try {
  # ── Preflight: 모듈 로드 & 스모크 ─────────────────────────────────────────────
  $ModPath = Join-Path $RepoRoot 'scripts\lib\kobong-fileio.psm1'
  if (!(Test-Path $ModPath)) { throw "Missing module: $ModPath" }
  Import-Module $ModPath -Force

  # 스모크: 같은 볼륨에 원자 쓰기 → 즉시 삭제
  $smoke = Join-Path $RepoRoot 'webui\public\_klc-smoke.txt'
  $smokeContent = "[klc-smoke] $(Get-Date -Format o)"
  Write-AtomicUtf8 -Path $smoke -Content $smokeContent -Module 'patcher' -Action 'smoke'
  if (Test-Path $smoke) { Remove-Item -LiteralPath $smoke -Force -ErrorAction SilentlyContinue }

  # ── Patch 파일 파싱 ───────────────────────────────────────────────────────────
  $PatchFile = Join-Path $RepoRoot '.kobong\patches.pending.txt'
  if (!(Test-Path $PatchFile)) {
  Write-Host "[SKIP] patches file not found → $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("patches-file-missing: "+$PatchFile) } catch {}
  return
}
  $patchText = Get-Content -LiteralPath $PatchFile -Raw -Encoding UTF8
  $global:patchHash = (Get-FileHash -Algorithm SHA256 -InputStream ([IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes($patchText)))).Hash

  $matches = [regex]::Matches($patchText, '(?ms)#\s*PATCH\s*START\s*(?<body>.*?)#\s*PATCH\s*END')
  if ($matches.Count -eq 0) {
  Write-Host "[SKIP] No PATCH blocks found in $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("no-patch-blocks: "+$PatchFile) } catch {}
  return
}

  $applied = @()
  foreach ($m in $matches) {
    $body = $m.Groups['body'].Value

    $targetRel = [regex]::Match($body, 'TARGET:\s*(?<v>.+)').Groups['v'].Value.Trim()
    $mode      = [regex]::Match($body, 'MODE:\s*(?<v>.+)').Groups['v'].Value.Trim().ToLowerInvariant()
    $find      = [regex]::Match($body, "FIND\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value
    $replace   = [regex]::Match($body, "REPLACE\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value

    if (-not $targetRel) { throw "PATCH missing TARGET" }
    if (-not $mode)      { throw "PATCH missing MODE" }
    if (-not $find)      { throw "PATCH missing FIND" }

    $target = Join-Path $RepoRoot $targetRel
    if (!(Test-Path $target)) {
  Write-Host "[SKIP] TARGET not found → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("target-not-found: "+$targetRel) } catch {}
  continue
}

    $orig = Get-Content -LiteralPath $target -Raw -Encoding UTF8
    $rxOpts = [Text.RegularExpressions.RegexOptions]::Multiline -bor [Text.RegularExpressions.RegexOptions]::Singleline
    $rx = [regex]::new($find, $rxOpts)
    $mt = $rx.Match($orig)
    if (-not $mt.Success) {
  Write-Host "[SKIP] FIND not matched → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("find-not-matched: "+$targetRel) } catch {}
  continue
}

    switch ($mode) {
      'insert-before' {
        $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
      }
      'insert-before' {
  $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
}
'insert-after' {
  $new = $orig.Substring(0, $mt.Index + $mt.Length) + "`n" + $replace + $orig.Substring($mt.Index + $mt.Length)
}
'replace' {
        $new = $rx.Replace($orig, $replace, 1)
      }
      default {
  Write-Host "[SKIP] Unsupported MODE → $mode for $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("unsupported-mode: "+$mode+" for "+$targetRel) } catch {}
  continue
}
    }

    if ($ConfirmApply) {
      $bk = "$target.bak-" + (Get-Date -Format 'yyyyMMdd-HHmmss')
      Copy-Item -LiteralPath $target -Destination $bk -Force
      Write-AtomicUtf8 -Path $target -Content $new -Module 'patcher' -Action ('apply:'+ $mode)
      $applied += $targetRel
    } else {
      Write-Host "[PREVIEW] would patch → $targetRel ($mode)"
    }
  }

  if ($ConfirmApply) {
    LogRec 'INFO' 'apply' 'SUCCESS' ("patched: " + ($applied -join ', '))
  } else {
    LogRec 'INFO' 'preview' 'SUCCESS' ("preview-ok (no writes). blocks="+$matches.Count)
  }

  # ── Gate-3 Verify (경량) ───────────────────────────────────────────────────────
  if ($ConfirmApply) {
    # 핵심 타겟의 구문 일치 재검
    $core = Join-Path $RepoRoot 'scripts\apply_ui_patch.ps1'
    if (Test-Path $core) {
      $c = Get-Content -LiteralPath $core -Raw -Encoding UTF8
      if ($c -notmatch 'ensure valid tmp path .* atomic friendly') {
        Write-Host "[WARN] VERIFY: guard snippet not found in apply_ui_patch.ps1"; try { LogRec "WARN" "verify" "SKIPPED" "guard-missing apply_ui_patch.ps1" } catch {}
      }
    }
  }
}
catch {
  LogRec 'ERROR' 'apply' 'FAILURE' $_.Exception.Message 'LOGIC'
  exit 0
}
finally {
  Remove-Item -Force $LockFile -ErrorAction SilentlyContinue
}
.Exception.Message)" }
  # 스모크: 같은 볼륨에 원자 쓰기 → 즉시 삭제
  $smoke = Join-Path $RepoRoot 'webui\public\_klc-smoke.txt'
  $smokeContent = "[klc-smoke] $(Get-Date -Format o)"
  Write-AtomicUtf8 -Path $smoke -Content $smokeContent -Module 'patcher' -Action 'smoke'
  if (Test-Path $smoke) { Remove-Item -LiteralPath $smoke -Force -ErrorAction SilentlyContinue }

  # ── Patch 파일 파싱 ───────────────────────────────────────────────────────────
  $PatchFile = Join-Path $RepoRoot '.kobong\patches.pending.txt'
  if (!(Test-Path $PatchFile)) {
  Write-Host "[SKIP] patches file not found → $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("patches-file-missing: "+$PatchFile) } catch {}
  return
}
  $patchText = Get-Content -LiteralPath $PatchFile -Raw -Encoding UTF8
  $global:patchHash = (Get-FileHash -Algorithm SHA256 -InputStream ([IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes($patchText)))).Hash

  $matches = [regex]::Matches($patchText, '(?ms)#\s*PATCH\s*START\s*(?<body>.*?)#\s*PATCH\s*END')
  if ($matches.Count -eq 0) {
  Write-Host "[SKIP] No PATCH blocks found in $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("no-patch-blocks: "+$PatchFile) } catch {}
  return
}

  $applied = @()
  foreach ($m in $matches) {
    $body = $m.Groups['body'].Value

    $targetRel = [regex]::Match($body, 'TARGET:\s*(?<v>.+)').Groups['v'].Value.Trim()
    $mode      = [regex]::Match($body, 'MODE:\s*(?<v>.+)').Groups['v'].Value.Trim().ToLowerInvariant()
    $find      = [regex]::Match($body, "FIND\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value
    $replace   = [regex]::Match($body, "REPLACE\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value

    if (-not $targetRel) { throw "PATCH missing TARGET" }
    if (-not $mode)      { throw "PATCH missing MODE" }
    if (-not $find)      { throw "PATCH missing FIND" }

    $target = Join-Path $RepoRoot $targetRel
    if (!(Test-Path $target)) {
  Write-Host "[SKIP] TARGET not found → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("target-not-found: "+$targetRel) } catch {}
  continue
}

    $orig = Get-Content -LiteralPath $target -Raw -Encoding UTF8
    $rxOpts = [Text.RegularExpressions.RegexOptions]::Multiline -bor [Text.RegularExpressions.RegexOptions]::Singleline
    $rx = [regex]::new($find, $rxOpts)
    $mt = $rx.Match($orig)
    if (-not $mt.Success) {
  Write-Host "[SKIP] FIND not matched → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("find-not-matched: "+$targetRel) } catch {}
  continue
}

    switch ($mode) {
      'insert-before' {
        $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
      }
      'insert-before' {
  $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
}
'insert-after' {
  $new = $orig.Substring(0, $mt.Index + $mt.Length) + "`n" + $replace + $orig.Substring($mt.Index + $mt.Length)
}
'replace' {
        $new = $rx.Replace($orig, $replace, 1)
      }
      default {
  Write-Host "[SKIP] Unsupported MODE → $mode for $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("unsupported-mode: "+$mode+" for "+$targetRel) } catch {}
  continue
}
    }

    if ($ConfirmApply) {
      $bk = "$target.bak-" + (Get-Date -Format 'yyyyMMdd-HHmmss')
      Copy-Item -LiteralPath $target -Destination $bk -Force
      Write-AtomicUtf8 -Path $target -Content $new -Module 'patcher' -Action ('apply:'+ $mode)
      $applied += $targetRel
    } else {
      Write-Host "[PREVIEW] would patch → $targetRel ($mode)"
    }
  }

  if ($ConfirmApply) {
    LogRec 'INFO' 'apply' 'SUCCESS' ("patched: " + ($applied -join ', '))
  } else {
    LogRec 'INFO' 'preview' 'SUCCESS' ("preview-ok (no writes). blocks="+$matches.Count)
  }

  # ── Gate-3 Verify (경량) ───────────────────────────────────────────────────────
  if ($ConfirmApply) {
    # 핵심 타겟의 구문 일치 재검
    $core = Join-Path $RepoRoot 'scripts\apply_ui_patch.ps1'
    if (Test-Path $core) {
      $c = Get-Content -LiteralPath $core -Raw -Encoding UTF8
      if ($c -notmatch 'ensure valid tmp path .* atomic friendly') {
        Write-Host "[WARN] VERIFY: guard snippet not found in apply_ui_patch.ps1"; try { LogRec "WARN" "verify" "SKIPPED" "guard-missing apply_ui_patch.ps1" } catch {}
      }
    }
  }
}
catch {
  LogRec 'ERROR' 'apply' 'FAILURE' $_.Exception.Message 'LOGIC'
  exit 0
}
finally {
  Remove-Item -Force $LockFile -ErrorAction SilentlyContinue
}
.Exception.Message)" }
}
  Import-Module $ModPath -Force

  # 스모크: 같은 볼륨에 원자 쓰기 → 즉시 삭제
  $smoke = Join-Path $RepoRoot 'webui\public\_klc-smoke.txt'
  $smokeContent = "[klc-smoke] $(Get-Date -Format o)"
  Write-AtomicUtf8 -Path $smoke -Content $smokeContent -Module 'patcher' -Action 'smoke'
  if (Test-Path $smoke) { Remove-Item -LiteralPath $smoke -Force -ErrorAction SilentlyContinue }

  # ── Patch 파일 파싱 ───────────────────────────────────────────────────────────
  $PatchFile = Join-Path $RepoRoot '.kobong\patches.pending.txt'
  if (!(Test-Path $PatchFile)) {
  Write-Host "[SKIP] patches file not found → $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("patches-file-missing: "+$PatchFile) } catch {}
  return
}
  $patchText = Get-Content -LiteralPath $PatchFile -Raw -Encoding UTF8
  $global:patchHash = (Get-FileHash -Algorithm SHA256 -InputStream ([IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes($patchText)))).Hash

  $matches = [regex]::Matches($patchText, '(?ms)#\s*PATCH\s*START\s*(?<body>.*?)#\s*PATCH\s*END')
  if ($matches.Count -eq 0) {
  Write-Host "[SKIP] No PATCH blocks found in $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("no-patch-blocks: "+$PatchFile) } catch {}
  return
}

  $applied = @()
  foreach ($m in $matches) {
    $body = $m.Groups['body'].Value

    $targetRel = [regex]::Match($body, 'TARGET:\s*(?<v>.+)').Groups['v'].Value.Trim()
    $mode      = [regex]::Match($body, 'MODE:\s*(?<v>.+)').Groups['v'].Value.Trim().ToLowerInvariant()
    $find      = [regex]::Match($body, "FIND\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value
    $replace   = [regex]::Match($body, "REPLACE\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value

    if (-not $targetRel) { throw "PATCH missing TARGET" }
    if (-not $mode)      { throw "PATCH missing MODE" }
    if (-not $find)      { throw "PATCH missing FIND" }

    $target = Join-Path $RepoRoot $targetRel
    if (!(Test-Path $target)) {
  Write-Host "[SKIP] TARGET not found → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("target-not-found: "+$targetRel) } catch {}
  continue
}

    $orig = Get-Content -LiteralPath $target -Raw -Encoding UTF8
    $rxOpts = [Text.RegularExpressions.RegexOptions]::Multiline -bor [Text.RegularExpressions.RegexOptions]::Singleline
    $rx = [regex]::new($find, $rxOpts)
    $mt = $rx.Match($orig)
    if (-not $mt.Success) {
  Write-Host "[SKIP] FIND not matched → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("find-not-matched: "+$targetRel) } catch {}
  continue
}

    switch ($mode) {
      'insert-before' {
        $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
      }
      'insert-before' {
  $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
}
'insert-after' {
  $new = $orig.Substring(0, $mt.Index + $mt.Length) + "`n" + $replace + $orig.Substring($mt.Index + $mt.Length)
}
'replace' {
        $new = $rx.Replace($orig, $replace, 1)
      }
      default {
  Write-Host "[SKIP] Unsupported MODE → $mode for $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("unsupported-mode: "+$mode+" for "+$targetRel) } catch {}
  continue
}
    }

    if ($ConfirmApply) {
      $bk = "$target.bak-" + (Get-Date -Format 'yyyyMMdd-HHmmss')
      Copy-Item -LiteralPath $target -Destination $bk -Force
      Write-AtomicUtf8 -Path $target -Content $new -Module 'patcher' -Action ('apply:'+ $mode)
      $applied += $targetRel
    } else {
      Write-Host "[PREVIEW] would patch → $targetRel ($mode)"
    }
  }

  if ($ConfirmApply) {
    LogRec 'INFO' 'apply' 'SUCCESS' ("patched: " + ($applied -join ', '))
  } else {
    LogRec 'INFO' 'preview' 'SUCCESS' ("preview-ok (no writes). blocks="+$matches.Count)
  }

  # ── Gate-3 Verify (경량) ───────────────────────────────────────────────────────
  if ($ConfirmApply) {
    # 핵심 타겟의 구문 일치 재검
    $core = Join-Path $RepoRoot 'scripts\apply_ui_patch.ps1'
    if (Test-Path $core) {
      $c = Get-Content -LiteralPath $core -Raw -Encoding UTF8
      if ($c -notmatch 'ensure valid tmp path .* atomic friendly') {
        Write-Host "[WARN] VERIFY: guard snippet not found in apply_ui_patch.ps1"; try { LogRec "WARN" "verify" "SKIPPED" "guard-missing apply_ui_patch.ps1" } catch {}
      }
    }
  }
}
catch {
  LogRec 'ERROR' 'apply' 'FAILURE' $_.Exception.Message 'LOGIC'
  exit 0
}
finally {
  Remove-Item -Force $LockFile -ErrorAction SilentlyContinue
}
.Exception.Message)" }
  # 스모크: 같은 볼륨에 원자 쓰기 → 즉시 삭제
  $smoke = Join-Path $RepoRoot 'webui\public\_klc-smoke.txt'
  $smokeContent = "[klc-smoke] $(Get-Date -Format o)"
  Write-AtomicUtf8 -Path $smoke -Content $smokeContent -Module 'patcher' -Action 'smoke'
  if (Test-Path $smoke) { Remove-Item -LiteralPath $smoke -Force -ErrorAction SilentlyContinue }

  # ── Patch 파일 파싱 ───────────────────────────────────────────────────────────
  $PatchFile = Join-Path $RepoRoot '.kobong\patches.pending.txt'
  if (!(Test-Path $PatchFile)) {
  Write-Host "[SKIP] patches file not found → $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("patches-file-missing: "+$PatchFile) } catch {}
  return
}
  $patchText = Get-Content -LiteralPath $PatchFile -Raw -Encoding UTF8
  $global:patchHash = (Get-FileHash -Algorithm SHA256 -InputStream ([IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes($patchText)))).Hash

  $matches = [regex]::Matches($patchText, '(?ms)#\s*PATCH\s*START\s*(?<body>.*?)#\s*PATCH\s*END')
  if ($matches.Count -eq 0) {
  Write-Host "[SKIP] No PATCH blocks found in $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("no-patch-blocks: "+$PatchFile) } catch {}
  return
}

  $applied = @()
  foreach ($m in $matches) {
    $body = $m.Groups['body'].Value

    $targetRel = [regex]::Match($body, 'TARGET:\s*(?<v>.+)').Groups['v'].Value.Trim()
    $mode      = [regex]::Match($body, 'MODE:\s*(?<v>.+)').Groups['v'].Value.Trim().ToLowerInvariant()
    $find      = [regex]::Match($body, "FIND\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value
    $replace   = [regex]::Match($body, "REPLACE\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value

    if (-not $targetRel) { throw "PATCH missing TARGET" }
    if (-not $mode)      { throw "PATCH missing MODE" }
    if (-not $find)      { throw "PATCH missing FIND" }

    $target = Join-Path $RepoRoot $targetRel
    if (!(Test-Path $target)) {
  Write-Host "[SKIP] TARGET not found → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("target-not-found: "+$targetRel) } catch {}
  continue
}

    $orig = Get-Content -LiteralPath $target -Raw -Encoding UTF8
    $rxOpts = [Text.RegularExpressions.RegexOptions]::Multiline -bor [Text.RegularExpressions.RegexOptions]::Singleline
    $rx = [regex]::new($find, $rxOpts)
    $mt = $rx.Match($orig)
    if (-not $mt.Success) {
  Write-Host "[SKIP] FIND not matched → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("find-not-matched: "+$targetRel) } catch {}
  continue
}

    switch ($mode) {
      'insert-before' {
        $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
      }
      'insert-before' {
  $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
}
'insert-after' {
  $new = $orig.Substring(0, $mt.Index + $mt.Length) + "`n" + $replace + $orig.Substring($mt.Index + $mt.Length)
}
'replace' {
        $new = $rx.Replace($orig, $replace, 1)
      }
      default {
  Write-Host "[SKIP] Unsupported MODE → $mode for $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("unsupported-mode: "+$mode+" for "+$targetRel) } catch {}
  continue
}
    }

    if ($ConfirmApply) {
      $bk = "$target.bak-" + (Get-Date -Format 'yyyyMMdd-HHmmss')
      Copy-Item -LiteralPath $target -Destination $bk -Force
      Write-AtomicUtf8 -Path $target -Content $new -Module 'patcher' -Action ('apply:'+ $mode)
      $applied += $targetRel
    } else {
      Write-Host "[PREVIEW] would patch → $targetRel ($mode)"
    }
  }

  if ($ConfirmApply) {
    LogRec 'INFO' 'apply' 'SUCCESS' ("patched: " + ($applied -join ', '))
  } else {
    LogRec 'INFO' 'preview' 'SUCCESS' ("preview-ok (no writes). blocks="+$matches.Count)
  }

  # ── Gate-3 Verify (경량) ───────────────────────────────────────────────────────
  if ($ConfirmApply) {
    # 핵심 타겟의 구문 일치 재검
    $core = Join-Path $RepoRoot 'scripts\apply_ui_patch.ps1'
    if (Test-Path $core) {
      $c = Get-Content -LiteralPath $core -Raw -Encoding UTF8
      if ($c -notmatch 'ensure valid tmp path .* atomic friendly') {
        Write-Host "[WARN] VERIFY: guard snippet not found in apply_ui_patch.ps1"; try { LogRec "WARN" "verify" "SKIPPED" "guard-missing apply_ui_patch.ps1" } catch {}
      }
    }
  }
}
catch {
  LogRec 'ERROR' 'apply' 'FAILURE' $_.Exception.Message 'LOGIC'
  exit 0
}
finally {
  Remove-Item -Force $LockFile -ErrorAction SilentlyContinue
}
.Exception.Message) }
  # 스모크: 같은 볼륨에 원자 쓰기 → 즉시 삭제
  $smoke = Join-Path $RepoRoot 'webui\public\_klc-smoke.txt'
  $smokeContent = "[klc-smoke] $(Get-Date -Format o)"
  Write-AtomicUtf8 -Path $smoke -Content $smokeContent -Module 'patcher' -Action 'smoke'
  if (Test-Path $smoke) { Remove-Item -LiteralPath $smoke -Force -ErrorAction SilentlyContinue }

  # ── Patch 파일 파싱 ───────────────────────────────────────────────────────────
  $PatchFile = Join-Path $RepoRoot '.kobong\patches.pending.txt'
  if (!(Test-Path $PatchFile)) {
  Write-Host "[SKIP] patches file not found → $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("patches-file-missing: "+$PatchFile) } catch {}
  return
}
  $patchText = Get-Content -LiteralPath $PatchFile -Raw -Encoding UTF8
  $global:patchHash = (Get-FileHash -Algorithm SHA256 -InputStream ([IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes($patchText)))).Hash

  $matches = [regex]::Matches($patchText, '(?ms)#\s*PATCH\s*START\s*(?<body>.*?)#\s*PATCH\s*END')
  if ($matches.Count -eq 0) {
  Write-Host "[SKIP] No PATCH blocks found in $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("no-patch-blocks: "+$PatchFile) } catch {}
  return
}

  $applied = @()
  foreach ($m in $matches) {
    $body = $m.Groups['body'].Value

    $targetRel = [regex]::Match($body, 'TARGET:\s*(?<v>.+)').Groups['v'].Value.Trim()
    $mode      = [regex]::Match($body, 'MODE:\s*(?<v>.+)').Groups['v'].Value.Trim().ToLowerInvariant()
    $find      = [regex]::Match($body, "FIND\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value
    $replace   = [regex]::Match($body, "REPLACE\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value

    if (-not $targetRel) { throw "PATCH missing TARGET" }
    if (-not $mode)      { throw "PATCH missing MODE" }
    if (-not $find)      { throw "PATCH missing FIND" }

    $target = Join-Path $RepoRoot $targetRel
    if (!(Test-Path $target)) {
  Write-Host "[SKIP] TARGET not found → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("target-not-found: "+$targetRel) } catch {}
  continue
}

    $orig = Get-Content -LiteralPath $target -Raw -Encoding UTF8
    $rxOpts = [Text.RegularExpressions.RegexOptions]::Multiline -bor [Text.RegularExpressions.RegexOptions]::Singleline
    $rx = [regex]::new($find, $rxOpts)
    $mt = $rx.Match($orig)
    if (-not $mt.Success) {
  Write-Host "[SKIP] FIND not matched → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("find-not-matched: "+$targetRel) } catch {}
  continue
}

    switch ($mode) {
      'insert-before' {
        $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
      }
      'insert-before' {
  $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
}
'insert-after' {
  $new = $orig.Substring(0, $mt.Index + $mt.Length) + "`n" + $replace + $orig.Substring($mt.Index + $mt.Length)
}
'replace' {
        $new = $rx.Replace($orig, $replace, 1)
      }
      default {
  Write-Host "[SKIP] Unsupported MODE → $mode for $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("unsupported-mode: "+$mode+" for "+$targetRel) } catch {}
  continue
}
    }

    if ($ConfirmApply) {
      $bk = "$target.bak-" + (Get-Date -Format 'yyyyMMdd-HHmmss')
      Copy-Item -LiteralPath $target -Destination $bk -Force
      Write-AtomicUtf8 -Path $target -Content $new -Module 'patcher' -Action ('apply:'+ $mode)
      $applied += $targetRel
    } else {
      Write-Host "[PREVIEW] would patch → $targetRel ($mode)"
    }
  }

  if ($ConfirmApply) {
    LogRec 'INFO' 'apply' 'SUCCESS' ("patched: " + ($applied -join ', '))
  } else {
    LogRec 'INFO' 'preview' 'SUCCESS' ("preview-ok (no writes). blocks="+$matches.Count)
  }

  # ── Gate-3 Verify (경량) ───────────────────────────────────────────────────────
  if ($ConfirmApply) {
    # 핵심 타겟의 구문 일치 재검
    $core = Join-Path $RepoRoot 'scripts\apply_ui_patch.ps1'
    if (Test-Path $core) {
      $c = Get-Content -LiteralPath $core -Raw -Encoding UTF8
      if ($c -notmatch 'ensure valid tmp path .* atomic friendly') {
        Write-Host "[WARN] VERIFY: guard snippet not found in apply_ui_patch.ps1"; try { LogRec "WARN" "verify" "SKIPPED" "guard-missing apply_ui_patch.ps1" } catch {}
      }
    }
  }
}
catch {
  LogRec 'ERROR' 'apply' 'FAILURE' $_.Exception.Message 'LOGIC'
  exit 0
}
finally {
  Remove-Item -Force $LockFile -ErrorAction SilentlyContinue
}
.Exception.Message)" }
  # 스모크: 같은 볼륨에 원자 쓰기 → 즉시 삭제
  $smoke = Join-Path $RepoRoot 'webui\public\_klc-smoke.txt'
  $smokeContent = "[klc-smoke] $(Get-Date -Format o)"
  Write-AtomicUtf8 -Path $smoke -Content $smokeContent -Module 'patcher' -Action 'smoke'
  if (Test-Path $smoke) { Remove-Item -LiteralPath $smoke -Force -ErrorAction SilentlyContinue }

  # ── Patch 파일 파싱 ───────────────────────────────────────────────────────────
  $PatchFile = Join-Path $RepoRoot '.kobong\patches.pending.txt'
  if (!(Test-Path $PatchFile)) {
  Write-Host "[SKIP] patches file not found → $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("patches-file-missing: "+$PatchFile) } catch {}
  return
}
  $patchText = Get-Content -LiteralPath $PatchFile -Raw -Encoding UTF8
  $global:patchHash = (Get-FileHash -Algorithm SHA256 -InputStream ([IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes($patchText)))).Hash

  $matches = [regex]::Matches($patchText, '(?ms)#\s*PATCH\s*START\s*(?<body>.*?)#\s*PATCH\s*END')
  if ($matches.Count -eq 0) {
  Write-Host "[SKIP] No PATCH blocks found in $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("no-patch-blocks: "+$PatchFile) } catch {}
  return
}

  $applied = @()
  foreach ($m in $matches) {
    $body = $m.Groups['body'].Value

    $targetRel = [regex]::Match($body, 'TARGET:\s*(?<v>.+)').Groups['v'].Value.Trim()
    $mode      = [regex]::Match($body, 'MODE:\s*(?<v>.+)').Groups['v'].Value.Trim().ToLowerInvariant()
    $find      = [regex]::Match($body, "FIND\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value
    $replace   = [regex]::Match($body, "REPLACE\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value

    if (-not $targetRel) { throw "PATCH missing TARGET" }
    if (-not $mode)      { throw "PATCH missing MODE" }
    if (-not $find)      { throw "PATCH missing FIND" }

    $target = Join-Path $RepoRoot $targetRel
    if (!(Test-Path $target)) {
  Write-Host "[SKIP] TARGET not found → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("target-not-found: "+$targetRel) } catch {}
  continue
}

    $orig = Get-Content -LiteralPath $target -Raw -Encoding UTF8
    $rxOpts = [Text.RegularExpressions.RegexOptions]::Multiline -bor [Text.RegularExpressions.RegexOptions]::Singleline
    $rx = [regex]::new($find, $rxOpts)
    $mt = $rx.Match($orig)
    if (-not $mt.Success) {
  Write-Host "[SKIP] FIND not matched → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("find-not-matched: "+$targetRel) } catch {}
  continue
}

    switch ($mode) {
      'insert-before' {
        $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
      }
      'insert-before' {
  $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
}
'insert-after' {
  $new = $orig.Substring(0, $mt.Index + $mt.Length) + "`n" + $replace + $orig.Substring($mt.Index + $mt.Length)
}
'replace' {
        $new = $rx.Replace($orig, $replace, 1)
      }
      default {
  Write-Host "[SKIP] Unsupported MODE → $mode for $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("unsupported-mode: "+$mode+" for "+$targetRel) } catch {}
  continue
}
    }

    if ($ConfirmApply) {
      $bk = "$target.bak-" + (Get-Date -Format 'yyyyMMdd-HHmmss')
      Copy-Item -LiteralPath $target -Destination $bk -Force
      Write-AtomicUtf8 -Path $target -Content $new -Module 'patcher' -Action ('apply:'+ $mode)
      $applied += $targetRel
    } else {
      Write-Host "[PREVIEW] would patch → $targetRel ($mode)"
    }
  }

  if ($ConfirmApply) {
    LogRec 'INFO' 'apply' 'SUCCESS' ("patched: " + ($applied -join ', '))
  } else {
    LogRec 'INFO' 'preview' 'SUCCESS' ("preview-ok (no writes). blocks="+$matches.Count)
  }

  # ── Gate-3 Verify (경량) ───────────────────────────────────────────────────────
  if ($ConfirmApply) {
    # 핵심 타겟의 구문 일치 재검
    $core = Join-Path $RepoRoot 'scripts\apply_ui_patch.ps1'
    if (Test-Path $core) {
      $c = Get-Content -LiteralPath $core -Raw -Encoding UTF8
      if ($c -notmatch 'ensure valid tmp path .* atomic friendly') {
        Write-Host "[WARN] VERIFY: guard snippet not found in apply_ui_patch.ps1"; try { LogRec "WARN" "verify" "SKIPPED" "guard-missing apply_ui_patch.ps1" } catch {}
      }
    }
  }
}
catch {
  LogRec 'ERROR' 'apply' 'FAILURE' $_.Exception.Message 'LOGIC'
  exit 0
}
finally {
  Remove-Item -Force $LockFile -ErrorAction SilentlyContinue
}
.Exception.Message)" }
}
try { Import-Module $ModPath -Force } catch { Write-Host ("[WARN] Import-Module failed -> " + $ModPath + ": " + # APPLY IN SHELL
#requires -Version 7.0
param([switch]$ConfirmApply,[string]$Root)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

# ── Gate-0: Repo / Lock ─────────────────────────────────────────────────────────
function Get-RepoRoot {
  try {
    $p = (git rev-parse --show-toplevel 2>$null)
    if ($p) { return (Resolve-Path $p).Path }
  } catch {}
  if ($Root) { return (Resolve-Path $Root).Path }
  return (Get-Location).Path
}
$RepoRoot = Get-RepoRoot
$LockFile = Join-Path $RepoRoot '.gpt5.lock'
if (Test-Path $LockFile) { Write-Error 'CONFLICT: .gpt5.lock exists.'; exit 11 }
"locked $(Get-Date -Format o)" | Out-File $LockFile -Encoding utf8 -NoNewline

$sw=[Diagnostics.Stopwatch]::StartNew()
$trace=[guid]::NewGuid().ToString()
$logPath = Join-Path $RepoRoot 'logs/apply-log.jsonl'
New-Item -ItemType Directory -Force -Path (Split-Path $logPath) | Out-Null

function LogRec([string]$level,[string]$action,[string]$outcome,[string]$msg,[string]$err='') {
  $rec = @{
    timestamp=(Get-Date).ToString('o'); level=$level; traceId=$trace; module='patcher';
    action=$action; inputHash=((Get-Variable -Name patchHash -Scope Global -ValueOnly -ErrorAction SilentlyContinue) ?? ""); outcome=$outcome;
    durationMs=$sw.ElapsedMilliseconds; errorCode=$err; message=$msg
  } | ConvertTo-Json -Compress
  Add-Content -Path $logPath -Value $rec
}

try {
  # ── Preflight: 모듈 로드 & 스모크 ─────────────────────────────────────────────
  $ModPath = Join-Path $RepoRoot 'scripts\lib\kobong-fileio.psm1'
  if (!(Test-Path $ModPath)) {
  Write-Host "[WARN] Missing module → $ModPath (continuing)"
  try { LogRec "WARN" "apply" "SKIPPED" ("missing-module: "+$ModPath) } catch {}
} else {
  try { Import-Module $ModPath -Force } catch { Write-Host ("[WARN] Import-Module failed -> " + $ModPath + ": " + # APPLY IN SHELL
#requires -Version 7.0
param([switch]$ConfirmApply,[string]$Root)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

# ── Gate-0: Repo / Lock ─────────────────────────────────────────────────────────
function Get-RepoRoot {
  try {
    $p = (git rev-parse --show-toplevel 2>$null)
    if ($p) { return (Resolve-Path $p).Path }
  } catch {}
  if ($Root) { return (Resolve-Path $Root).Path }
  return (Get-Location).Path
}
$RepoRoot = Get-RepoRoot
$LockFile = Join-Path $RepoRoot '.gpt5.lock'
if (Test-Path $LockFile) { Write-Error 'CONFLICT: .gpt5.lock exists.'; exit 11 }
"locked $(Get-Date -Format o)" | Out-File $LockFile -Encoding utf8 -NoNewline

$sw=[Diagnostics.Stopwatch]::StartNew()
$trace=[guid]::NewGuid().ToString()
$logPath = Join-Path $RepoRoot 'logs/apply-log.jsonl'
New-Item -ItemType Directory -Force -Path (Split-Path $logPath) | Out-Null

function LogRec([string]$level,[string]$action,[string]$outcome,[string]$msg,[string]$err='') {
  $rec = @{
    timestamp=(Get-Date).ToString('o'); level=$level; traceId=$trace; module='patcher';
    action=$action; inputHash=((Get-Variable -Name patchHash -Scope Global -ValueOnly -ErrorAction SilentlyContinue) ?? ""); outcome=$outcome;
    durationMs=$sw.ElapsedMilliseconds; errorCode=$err; message=$msg
  } | ConvertTo-Json -Compress
  Add-Content -Path $logPath -Value $rec
}

try {
  # ── Preflight: 모듈 로드 & 스모크 ─────────────────────────────────────────────
  $ModPath = Join-Path $RepoRoot 'scripts\lib\kobong-fileio.psm1'
  if (!(Test-Path $ModPath)) {
  Write-Host "[WARN] Missing module → $ModPath (continuing)"
  try { LogRec "WARN" "apply" "SKIPPED" ("missing-module: "+$ModPath) } catch {}
} else {
  try { Import-Module $ModPath -Force } catch { Write-Host "[WARN] Import-Module failed → $ModPath: $(# APPLY IN SHELL
#requires -Version 7.0
param([switch]$ConfirmApply,[string]$Root)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

# ── Gate-0: Repo / Lock ─────────────────────────────────────────────────────────
function Get-RepoRoot {
  try {
    $p = (git rev-parse --show-toplevel 2>$null)
    if ($p) { return (Resolve-Path $p).Path }
  } catch {}
  if ($Root) { return (Resolve-Path $Root).Path }
  return (Get-Location).Path
}
$RepoRoot = Get-RepoRoot
$LockFile = Join-Path $RepoRoot '.gpt5.lock'
if (Test-Path $LockFile) { Write-Error 'CONFLICT: .gpt5.lock exists.'; exit 11 }
"locked $(Get-Date -Format o)" | Out-File $LockFile -Encoding utf8 -NoNewline

$sw=[Diagnostics.Stopwatch]::StartNew()
$trace=[guid]::NewGuid().ToString()
$logPath = Join-Path $RepoRoot 'logs/apply-log.jsonl'
New-Item -ItemType Directory -Force -Path (Split-Path $logPath) | Out-Null

function LogRec([string]$level,[string]$action,[string]$outcome,[string]$msg,[string]$err='') {
  $rec = @{
    timestamp=(Get-Date).ToString('o'); level=$level; traceId=$trace; module='patcher';
    action=$action; inputHash=((Get-Variable -Name patchHash -Scope Global -ValueOnly -ErrorAction SilentlyContinue) ?? ""); outcome=$outcome;
    durationMs=$sw.ElapsedMilliseconds; errorCode=$err; message=$msg
  } | ConvertTo-Json -Compress
  Add-Content -Path $logPath -Value $rec
}

try {
  # ── Preflight: 모듈 로드 & 스모크 ─────────────────────────────────────────────
  $ModPath = Join-Path $RepoRoot 'scripts\lib\kobong-fileio.psm1'
  if (!(Test-Path $ModPath)) { throw "Missing module: $ModPath" }
try { Import-Module $ModPath -Force } catch { Write-Host "[WARN] Import-Module failed → $ModPath: $(# APPLY IN SHELL
#requires -Version 7.0
param([switch]$ConfirmApply,[string]$Root)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

# ── Gate-0: Repo / Lock ─────────────────────────────────────────────────────────
function Get-RepoRoot {
  try {
    $p = (git rev-parse --show-toplevel 2>$null)
    if ($p) { return (Resolve-Path $p).Path }
  } catch {}
  if ($Root) { return (Resolve-Path $Root).Path }
  return (Get-Location).Path
}
$RepoRoot = Get-RepoRoot
$LockFile = Join-Path $RepoRoot '.gpt5.lock'
if (Test-Path $LockFile) { Write-Error 'CONFLICT: .gpt5.lock exists.'; exit 11 }
"locked $(Get-Date -Format o)" | Out-File $LockFile -Encoding utf8 -NoNewline

$sw=[Diagnostics.Stopwatch]::StartNew()
$trace=[guid]::NewGuid().ToString()
$logPath = Join-Path $RepoRoot 'logs/apply-log.jsonl'
New-Item -ItemType Directory -Force -Path (Split-Path $logPath) | Out-Null

function LogRec([string]$level,[string]$action,[string]$outcome,[string]$msg,[string]$err='') {
  $rec = @{
    timestamp=(Get-Date).ToString('o'); level=$level; traceId=$trace; module='patcher';
    action=$action; inputHash=((Get-Variable -Name patchHash -Scope Global -ValueOnly -ErrorAction SilentlyContinue) ?? ""); outcome=$outcome;
    durationMs=$sw.ElapsedMilliseconds; errorCode=$err; message=$msg
  } | ConvertTo-Json -Compress
  Add-Content -Path $logPath -Value $rec
}

try {
  # ── Preflight: 모듈 로드 & 스모크 ─────────────────────────────────────────────
  $ModPath = Join-Path $RepoRoot 'scripts\lib\kobong-fileio.psm1'
  if (!(Test-Path $ModPath)) { throw "Missing module: $ModPath" }
  Import-Module $ModPath -Force

  # 스모크: 같은 볼륨에 원자 쓰기 → 즉시 삭제
  $smoke = Join-Path $RepoRoot 'webui\public\_klc-smoke.txt'
  $smokeContent = "[klc-smoke] $(Get-Date -Format o)"
  Write-AtomicUtf8 -Path $smoke -Content $smokeContent -Module 'patcher' -Action 'smoke'
  if (Test-Path $smoke) { Remove-Item -LiteralPath $smoke -Force -ErrorAction SilentlyContinue }

  # ── Patch 파일 파싱 ───────────────────────────────────────────────────────────
  $PatchFile = Join-Path $RepoRoot '.kobong\patches.pending.txt'
  if (!(Test-Path $PatchFile)) {
  Write-Host "[SKIP] patches file not found → $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("patches-file-missing: "+$PatchFile) } catch {}
  return
}
  $patchText = Get-Content -LiteralPath $PatchFile -Raw -Encoding UTF8
  $global:patchHash = (Get-FileHash -Algorithm SHA256 -InputStream ([IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes($patchText)))).Hash

  $matches = [regex]::Matches($patchText, '(?ms)#\s*PATCH\s*START\s*(?<body>.*?)#\s*PATCH\s*END')
  if ($matches.Count -eq 0) {
  Write-Host "[SKIP] No PATCH blocks found in $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("no-patch-blocks: "+$PatchFile) } catch {}
  return
}

  $applied = @()
  foreach ($m in $matches) {
    $body = $m.Groups['body'].Value

    $targetRel = [regex]::Match($body, 'TARGET:\s*(?<v>.+)').Groups['v'].Value.Trim()
    $mode      = [regex]::Match($body, 'MODE:\s*(?<v>.+)').Groups['v'].Value.Trim().ToLowerInvariant()
    $find      = [regex]::Match($body, "FIND\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value
    $replace   = [regex]::Match($body, "REPLACE\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value

    if (-not $targetRel) { throw "PATCH missing TARGET" }
    if (-not $mode)      { throw "PATCH missing MODE" }
    if (-not $find)      { throw "PATCH missing FIND" }

    $target = Join-Path $RepoRoot $targetRel
    if (!(Test-Path $target)) {
  Write-Host "[SKIP] TARGET not found → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("target-not-found: "+$targetRel) } catch {}
  continue
}

    $orig = Get-Content -LiteralPath $target -Raw -Encoding UTF8
    $rxOpts = [Text.RegularExpressions.RegexOptions]::Multiline -bor [Text.RegularExpressions.RegexOptions]::Singleline
    $rx = [regex]::new($find, $rxOpts)
    $mt = $rx.Match($orig)
    if (-not $mt.Success) {
  Write-Host "[SKIP] FIND not matched → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("find-not-matched: "+$targetRel) } catch {}
  continue
}

    switch ($mode) {
      'insert-before' {
        $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
      }
      'insert-before' {
  $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
}
'insert-after' {
  $new = $orig.Substring(0, $mt.Index + $mt.Length) + "`n" + $replace + $orig.Substring($mt.Index + $mt.Length)
}
'replace' {
        $new = $rx.Replace($orig, $replace, 1)
      }
      default {
  Write-Host "[SKIP] Unsupported MODE → $mode for $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("unsupported-mode: "+$mode+" for "+$targetRel) } catch {}
  continue
}
    }

    if ($ConfirmApply) {
      $bk = "$target.bak-" + (Get-Date -Format 'yyyyMMdd-HHmmss')
      Copy-Item -LiteralPath $target -Destination $bk -Force
      Write-AtomicUtf8 -Path $target -Content $new -Module 'patcher' -Action ('apply:'+ $mode)
      $applied += $targetRel
    } else {
      Write-Host "[PREVIEW] would patch → $targetRel ($mode)"
    }
  }

  if ($ConfirmApply) {
    LogRec 'INFO' 'apply' 'SUCCESS' ("patched: " + ($applied -join ', '))
  } else {
    LogRec 'INFO' 'preview' 'SUCCESS' ("preview-ok (no writes). blocks="+$matches.Count)
  }

  # ── Gate-3 Verify (경량) ───────────────────────────────────────────────────────
  if ($ConfirmApply) {
    # 핵심 타겟의 구문 일치 재검
    $core = Join-Path $RepoRoot 'scripts\apply_ui_patch.ps1'
    if (Test-Path $core) {
      $c = Get-Content -LiteralPath $core -Raw -Encoding UTF8
      if ($c -notmatch 'ensure valid tmp path .* atomic friendly') {
        Write-Host "[WARN] VERIFY: guard snippet not found in apply_ui_patch.ps1"; try { LogRec "WARN" "verify" "SKIPPED" "guard-missing apply_ui_patch.ps1" } catch {}
      }
    }
  }
}
catch {
  LogRec 'ERROR' 'apply' 'FAILURE' $_.Exception.Message 'LOGIC'
  exit 0
}
finally {
  Remove-Item -Force $LockFile -ErrorAction SilentlyContinue
}
.Exception.Message)" }
  # 스모크: 같은 볼륨에 원자 쓰기 → 즉시 삭제
  $smoke = Join-Path $RepoRoot 'webui\public\_klc-smoke.txt'
  $smokeContent = "[klc-smoke] $(Get-Date -Format o)"
  Write-AtomicUtf8 -Path $smoke -Content $smokeContent -Module 'patcher' -Action 'smoke'
  if (Test-Path $smoke) { Remove-Item -LiteralPath $smoke -Force -ErrorAction SilentlyContinue }

  # ── Patch 파일 파싱 ───────────────────────────────────────────────────────────
  $PatchFile = Join-Path $RepoRoot '.kobong\patches.pending.txt'
  if (!(Test-Path $PatchFile)) {
  Write-Host "[SKIP] patches file not found → $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("patches-file-missing: "+$PatchFile) } catch {}
  return
}
  $patchText = Get-Content -LiteralPath $PatchFile -Raw -Encoding UTF8
  $global:patchHash = (Get-FileHash -Algorithm SHA256 -InputStream ([IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes($patchText)))).Hash

  $matches = [regex]::Matches($patchText, '(?ms)#\s*PATCH\s*START\s*(?<body>.*?)#\s*PATCH\s*END')
  if ($matches.Count -eq 0) {
  Write-Host "[SKIP] No PATCH blocks found in $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("no-patch-blocks: "+$PatchFile) } catch {}
  return
}

  $applied = @()
  foreach ($m in $matches) {
    $body = $m.Groups['body'].Value

    $targetRel = [regex]::Match($body, 'TARGET:\s*(?<v>.+)').Groups['v'].Value.Trim()
    $mode      = [regex]::Match($body, 'MODE:\s*(?<v>.+)').Groups['v'].Value.Trim().ToLowerInvariant()
    $find      = [regex]::Match($body, "FIND\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value
    $replace   = [regex]::Match($body, "REPLACE\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value

    if (-not $targetRel) { throw "PATCH missing TARGET" }
    if (-not $mode)      { throw "PATCH missing MODE" }
    if (-not $find)      { throw "PATCH missing FIND" }

    $target = Join-Path $RepoRoot $targetRel
    if (!(Test-Path $target)) {
  Write-Host "[SKIP] TARGET not found → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("target-not-found: "+$targetRel) } catch {}
  continue
}

    $orig = Get-Content -LiteralPath $target -Raw -Encoding UTF8
    $rxOpts = [Text.RegularExpressions.RegexOptions]::Multiline -bor [Text.RegularExpressions.RegexOptions]::Singleline
    $rx = [regex]::new($find, $rxOpts)
    $mt = $rx.Match($orig)
    if (-not $mt.Success) {
  Write-Host "[SKIP] FIND not matched → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("find-not-matched: "+$targetRel) } catch {}
  continue
}

    switch ($mode) {
      'insert-before' {
        $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
      }
      'insert-before' {
  $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
}
'insert-after' {
  $new = $orig.Substring(0, $mt.Index + $mt.Length) + "`n" + $replace + $orig.Substring($mt.Index + $mt.Length)
}
'replace' {
        $new = $rx.Replace($orig, $replace, 1)
      }
      default {
  Write-Host "[SKIP] Unsupported MODE → $mode for $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("unsupported-mode: "+$mode+" for "+$targetRel) } catch {}
  continue
}
    }

    if ($ConfirmApply) {
      $bk = "$target.bak-" + (Get-Date -Format 'yyyyMMdd-HHmmss')
      Copy-Item -LiteralPath $target -Destination $bk -Force
      Write-AtomicUtf8 -Path $target -Content $new -Module 'patcher' -Action ('apply:'+ $mode)
      $applied += $targetRel
    } else {
      Write-Host "[PREVIEW] would patch → $targetRel ($mode)"
    }
  }

  if ($ConfirmApply) {
    LogRec 'INFO' 'apply' 'SUCCESS' ("patched: " + ($applied -join ', '))
  } else {
    LogRec 'INFO' 'preview' 'SUCCESS' ("preview-ok (no writes). blocks="+$matches.Count)
  }

  # ── Gate-3 Verify (경량) ───────────────────────────────────────────────────────
  if ($ConfirmApply) {
    # 핵심 타겟의 구문 일치 재검
    $core = Join-Path $RepoRoot 'scripts\apply_ui_patch.ps1'
    if (Test-Path $core) {
      $c = Get-Content -LiteralPath $core -Raw -Encoding UTF8
      if ($c -notmatch 'ensure valid tmp path .* atomic friendly') {
        Write-Host "[WARN] VERIFY: guard snippet not found in apply_ui_patch.ps1"; try { LogRec "WARN" "verify" "SKIPPED" "guard-missing apply_ui_patch.ps1" } catch {}
      }
    }
  }
}
catch {
  LogRec 'ERROR' 'apply' 'FAILURE' $_.Exception.Message 'LOGIC'
  exit 0
}
finally {
  Remove-Item -Force $LockFile -ErrorAction SilentlyContinue
}
.Exception.Message)" }
}
try { Import-Module $ModPath -Force } catch { Write-Host "[WARN] Import-Module failed → $ModPath: $(# APPLY IN SHELL
#requires -Version 7.0
param([switch]$ConfirmApply,[string]$Root)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

# ── Gate-0: Repo / Lock ─────────────────────────────────────────────────────────
function Get-RepoRoot {
  try {
    $p = (git rev-parse --show-toplevel 2>$null)
    if ($p) { return (Resolve-Path $p).Path }
  } catch {}
  if ($Root) { return (Resolve-Path $Root).Path }
  return (Get-Location).Path
}
$RepoRoot = Get-RepoRoot
$LockFile = Join-Path $RepoRoot '.gpt5.lock'
if (Test-Path $LockFile) { Write-Error 'CONFLICT: .gpt5.lock exists.'; exit 11 }
"locked $(Get-Date -Format o)" | Out-File $LockFile -Encoding utf8 -NoNewline

$sw=[Diagnostics.Stopwatch]::StartNew()
$trace=[guid]::NewGuid().ToString()
$logPath = Join-Path $RepoRoot 'logs/apply-log.jsonl'
New-Item -ItemType Directory -Force -Path (Split-Path $logPath) | Out-Null

function LogRec([string]$level,[string]$action,[string]$outcome,[string]$msg,[string]$err='') {
  $rec = @{
    timestamp=(Get-Date).ToString('o'); level=$level; traceId=$trace; module='patcher';
    action=$action; inputHash=((Get-Variable -Name patchHash -Scope Global -ValueOnly -ErrorAction SilentlyContinue) ?? ""); outcome=$outcome;
    durationMs=$sw.ElapsedMilliseconds; errorCode=$err; message=$msg
  } | ConvertTo-Json -Compress
  Add-Content -Path $logPath -Value $rec
}

try {
  # ── Preflight: 모듈 로드 & 스모크 ─────────────────────────────────────────────
  $ModPath = Join-Path $RepoRoot 'scripts\lib\kobong-fileio.psm1'
  if (!(Test-Path $ModPath)) {
  Write-Host "[WARN] Missing module → $ModPath (continuing)"
  try { LogRec "WARN" "apply" "SKIPPED" ("missing-module: "+$ModPath) } catch {}
} else {
  try { Import-Module $ModPath -Force } catch { Write-Host "[WARN] Import-Module failed → $ModPath: $(# APPLY IN SHELL
#requires -Version 7.0
param([switch]$ConfirmApply,[string]$Root)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

# ── Gate-0: Repo / Lock ─────────────────────────────────────────────────────────
function Get-RepoRoot {
  try {
    $p = (git rev-parse --show-toplevel 2>$null)
    if ($p) { return (Resolve-Path $p).Path }
  } catch {}
  if ($Root) { return (Resolve-Path $Root).Path }
  return (Get-Location).Path
}
$RepoRoot = Get-RepoRoot
$LockFile = Join-Path $RepoRoot '.gpt5.lock'
if (Test-Path $LockFile) { Write-Error 'CONFLICT: .gpt5.lock exists.'; exit 11 }
"locked $(Get-Date -Format o)" | Out-File $LockFile -Encoding utf8 -NoNewline

$sw=[Diagnostics.Stopwatch]::StartNew()
$trace=[guid]::NewGuid().ToString()
$logPath = Join-Path $RepoRoot 'logs/apply-log.jsonl'
New-Item -ItemType Directory -Force -Path (Split-Path $logPath) | Out-Null

function LogRec([string]$level,[string]$action,[string]$outcome,[string]$msg,[string]$err='') {
  $rec = @{
    timestamp=(Get-Date).ToString('o'); level=$level; traceId=$trace; module='patcher';
    action=$action; inputHash=((Get-Variable -Name patchHash -Scope Global -ValueOnly -ErrorAction SilentlyContinue) ?? ""); outcome=$outcome;
    durationMs=$sw.ElapsedMilliseconds; errorCode=$err; message=$msg
  } | ConvertTo-Json -Compress
  Add-Content -Path $logPath -Value $rec
}

try {
  # ── Preflight: 모듈 로드 & 스모크 ─────────────────────────────────────────────
  $ModPath = Join-Path $RepoRoot 'scripts\lib\kobong-fileio.psm1'
  if (!(Test-Path $ModPath)) { throw "Missing module: $ModPath" }
try { Import-Module $ModPath -Force } catch { Write-Host "[WARN] Import-Module failed → $ModPath: $(# APPLY IN SHELL
#requires -Version 7.0
param([switch]$ConfirmApply,[string]$Root)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

# ── Gate-0: Repo / Lock ─────────────────────────────────────────────────────────
function Get-RepoRoot {
  try {
    $p = (git rev-parse --show-toplevel 2>$null)
    if ($p) { return (Resolve-Path $p).Path }
  } catch {}
  if ($Root) { return (Resolve-Path $Root).Path }
  return (Get-Location).Path
}
$RepoRoot = Get-RepoRoot
$LockFile = Join-Path $RepoRoot '.gpt5.lock'
if (Test-Path $LockFile) { Write-Error 'CONFLICT: .gpt5.lock exists.'; exit 11 }
"locked $(Get-Date -Format o)" | Out-File $LockFile -Encoding utf8 -NoNewline

$sw=[Diagnostics.Stopwatch]::StartNew()
$trace=[guid]::NewGuid().ToString()
$logPath = Join-Path $RepoRoot 'logs/apply-log.jsonl'
New-Item -ItemType Directory -Force -Path (Split-Path $logPath) | Out-Null

function LogRec([string]$level,[string]$action,[string]$outcome,[string]$msg,[string]$err='') {
  $rec = @{
    timestamp=(Get-Date).ToString('o'); level=$level; traceId=$trace; module='patcher';
    action=$action; inputHash=((Get-Variable -Name patchHash -Scope Global -ValueOnly -ErrorAction SilentlyContinue) ?? ""); outcome=$outcome;
    durationMs=$sw.ElapsedMilliseconds; errorCode=$err; message=$msg
  } | ConvertTo-Json -Compress
  Add-Content -Path $logPath -Value $rec
}

try {
  # ── Preflight: 모듈 로드 & 스모크 ─────────────────────────────────────────────
  $ModPath = Join-Path $RepoRoot 'scripts\lib\kobong-fileio.psm1'
  if (!(Test-Path $ModPath)) { throw "Missing module: $ModPath" }
  Import-Module $ModPath -Force

  # 스모크: 같은 볼륨에 원자 쓰기 → 즉시 삭제
  $smoke = Join-Path $RepoRoot 'webui\public\_klc-smoke.txt'
  $smokeContent = "[klc-smoke] $(Get-Date -Format o)"
  Write-AtomicUtf8 -Path $smoke -Content $smokeContent -Module 'patcher' -Action 'smoke'
  if (Test-Path $smoke) { Remove-Item -LiteralPath $smoke -Force -ErrorAction SilentlyContinue }

  # ── Patch 파일 파싱 ───────────────────────────────────────────────────────────
  $PatchFile = Join-Path $RepoRoot '.kobong\patches.pending.txt'
  if (!(Test-Path $PatchFile)) {
  Write-Host "[SKIP] patches file not found → $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("patches-file-missing: "+$PatchFile) } catch {}
  return
}
  $patchText = Get-Content -LiteralPath $PatchFile -Raw -Encoding UTF8
  $global:patchHash = (Get-FileHash -Algorithm SHA256 -InputStream ([IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes($patchText)))).Hash

  $matches = [regex]::Matches($patchText, '(?ms)#\s*PATCH\s*START\s*(?<body>.*?)#\s*PATCH\s*END')
  if ($matches.Count -eq 0) {
  Write-Host "[SKIP] No PATCH blocks found in $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("no-patch-blocks: "+$PatchFile) } catch {}
  return
}

  $applied = @()
  foreach ($m in $matches) {
    $body = $m.Groups['body'].Value

    $targetRel = [regex]::Match($body, 'TARGET:\s*(?<v>.+)').Groups['v'].Value.Trim()
    $mode      = [regex]::Match($body, 'MODE:\s*(?<v>.+)').Groups['v'].Value.Trim().ToLowerInvariant()
    $find      = [regex]::Match($body, "FIND\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value
    $replace   = [regex]::Match($body, "REPLACE\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value

    if (-not $targetRel) { throw "PATCH missing TARGET" }
    if (-not $mode)      { throw "PATCH missing MODE" }
    if (-not $find)      { throw "PATCH missing FIND" }

    $target = Join-Path $RepoRoot $targetRel
    if (!(Test-Path $target)) {
  Write-Host "[SKIP] TARGET not found → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("target-not-found: "+$targetRel) } catch {}
  continue
}

    $orig = Get-Content -LiteralPath $target -Raw -Encoding UTF8
    $rxOpts = [Text.RegularExpressions.RegexOptions]::Multiline -bor [Text.RegularExpressions.RegexOptions]::Singleline
    $rx = [regex]::new($find, $rxOpts)
    $mt = $rx.Match($orig)
    if (-not $mt.Success) {
  Write-Host "[SKIP] FIND not matched → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("find-not-matched: "+$targetRel) } catch {}
  continue
}

    switch ($mode) {
      'insert-before' {
        $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
      }
      'insert-before' {
  $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
}
'insert-after' {
  $new = $orig.Substring(0, $mt.Index + $mt.Length) + "`n" + $replace + $orig.Substring($mt.Index + $mt.Length)
}
'replace' {
        $new = $rx.Replace($orig, $replace, 1)
      }
      default {
  Write-Host "[SKIP] Unsupported MODE → $mode for $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("unsupported-mode: "+$mode+" for "+$targetRel) } catch {}
  continue
}
    }

    if ($ConfirmApply) {
      $bk = "$target.bak-" + (Get-Date -Format 'yyyyMMdd-HHmmss')
      Copy-Item -LiteralPath $target -Destination $bk -Force
      Write-AtomicUtf8 -Path $target -Content $new -Module 'patcher' -Action ('apply:'+ $mode)
      $applied += $targetRel
    } else {
      Write-Host "[PREVIEW] would patch → $targetRel ($mode)"
    }
  }

  if ($ConfirmApply) {
    LogRec 'INFO' 'apply' 'SUCCESS' ("patched: " + ($applied -join ', '))
  } else {
    LogRec 'INFO' 'preview' 'SUCCESS' ("preview-ok (no writes). blocks="+$matches.Count)
  }

  # ── Gate-3 Verify (경량) ───────────────────────────────────────────────────────
  if ($ConfirmApply) {
    # 핵심 타겟의 구문 일치 재검
    $core = Join-Path $RepoRoot 'scripts\apply_ui_patch.ps1'
    if (Test-Path $core) {
      $c = Get-Content -LiteralPath $core -Raw -Encoding UTF8
      if ($c -notmatch 'ensure valid tmp path .* atomic friendly') {
        Write-Host "[WARN] VERIFY: guard snippet not found in apply_ui_patch.ps1"; try { LogRec "WARN" "verify" "SKIPPED" "guard-missing apply_ui_patch.ps1" } catch {}
      }
    }
  }
}
catch {
  LogRec 'ERROR' 'apply' 'FAILURE' $_.Exception.Message 'LOGIC'
  exit 0
}
finally {
  Remove-Item -Force $LockFile -ErrorAction SilentlyContinue
}
.Exception.Message)" }
  # 스모크: 같은 볼륨에 원자 쓰기 → 즉시 삭제
  $smoke = Join-Path $RepoRoot 'webui\public\_klc-smoke.txt'
  $smokeContent = "[klc-smoke] $(Get-Date -Format o)"
  Write-AtomicUtf8 -Path $smoke -Content $smokeContent -Module 'patcher' -Action 'smoke'
  if (Test-Path $smoke) { Remove-Item -LiteralPath $smoke -Force -ErrorAction SilentlyContinue }

  # ── Patch 파일 파싱 ───────────────────────────────────────────────────────────
  $PatchFile = Join-Path $RepoRoot '.kobong\patches.pending.txt'
  if (!(Test-Path $PatchFile)) {
  Write-Host "[SKIP] patches file not found → $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("patches-file-missing: "+$PatchFile) } catch {}
  return
}
  $patchText = Get-Content -LiteralPath $PatchFile -Raw -Encoding UTF8
  $global:patchHash = (Get-FileHash -Algorithm SHA256 -InputStream ([IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes($patchText)))).Hash

  $matches = [regex]::Matches($patchText, '(?ms)#\s*PATCH\s*START\s*(?<body>.*?)#\s*PATCH\s*END')
  if ($matches.Count -eq 0) {
  Write-Host "[SKIP] No PATCH blocks found in $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("no-patch-blocks: "+$PatchFile) } catch {}
  return
}

  $applied = @()
  foreach ($m in $matches) {
    $body = $m.Groups['body'].Value

    $targetRel = [regex]::Match($body, 'TARGET:\s*(?<v>.+)').Groups['v'].Value.Trim()
    $mode      = [regex]::Match($body, 'MODE:\s*(?<v>.+)').Groups['v'].Value.Trim().ToLowerInvariant()
    $find      = [regex]::Match($body, "FIND\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value
    $replace   = [regex]::Match($body, "REPLACE\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value

    if (-not $targetRel) { throw "PATCH missing TARGET" }
    if (-not $mode)      { throw "PATCH missing MODE" }
    if (-not $find)      { throw "PATCH missing FIND" }

    $target = Join-Path $RepoRoot $targetRel
    if (!(Test-Path $target)) {
  Write-Host "[SKIP] TARGET not found → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("target-not-found: "+$targetRel) } catch {}
  continue
}

    $orig = Get-Content -LiteralPath $target -Raw -Encoding UTF8
    $rxOpts = [Text.RegularExpressions.RegexOptions]::Multiline -bor [Text.RegularExpressions.RegexOptions]::Singleline
    $rx = [regex]::new($find, $rxOpts)
    $mt = $rx.Match($orig)
    if (-not $mt.Success) {
  Write-Host "[SKIP] FIND not matched → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("find-not-matched: "+$targetRel) } catch {}
  continue
}

    switch ($mode) {
      'insert-before' {
        $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
      }
      'insert-before' {
  $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
}
'insert-after' {
  $new = $orig.Substring(0, $mt.Index + $mt.Length) + "`n" + $replace + $orig.Substring($mt.Index + $mt.Length)
}
'replace' {
        $new = $rx.Replace($orig, $replace, 1)
      }
      default {
  Write-Host "[SKIP] Unsupported MODE → $mode for $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("unsupported-mode: "+$mode+" for "+$targetRel) } catch {}
  continue
}
    }

    if ($ConfirmApply) {
      $bk = "$target.bak-" + (Get-Date -Format 'yyyyMMdd-HHmmss')
      Copy-Item -LiteralPath $target -Destination $bk -Force
      Write-AtomicUtf8 -Path $target -Content $new -Module 'patcher' -Action ('apply:'+ $mode)
      $applied += $targetRel
    } else {
      Write-Host "[PREVIEW] would patch → $targetRel ($mode)"
    }
  }

  if ($ConfirmApply) {
    LogRec 'INFO' 'apply' 'SUCCESS' ("patched: " + ($applied -join ', '))
  } else {
    LogRec 'INFO' 'preview' 'SUCCESS' ("preview-ok (no writes). blocks="+$matches.Count)
  }

  # ── Gate-3 Verify (경량) ───────────────────────────────────────────────────────
  if ($ConfirmApply) {
    # 핵심 타겟의 구문 일치 재검
    $core = Join-Path $RepoRoot 'scripts\apply_ui_patch.ps1'
    if (Test-Path $core) {
      $c = Get-Content -LiteralPath $core -Raw -Encoding UTF8
      if ($c -notmatch 'ensure valid tmp path .* atomic friendly') {
        Write-Host "[WARN] VERIFY: guard snippet not found in apply_ui_patch.ps1"; try { LogRec "WARN" "verify" "SKIPPED" "guard-missing apply_ui_patch.ps1" } catch {}
      }
    }
  }
}
catch {
  LogRec 'ERROR' 'apply' 'FAILURE' $_.Exception.Message 'LOGIC'
  exit 0
}
finally {
  Remove-Item -Force $LockFile -ErrorAction SilentlyContinue
}
.Exception.Message)" }
}
  Import-Module $ModPath -Force

  # 스모크: 같은 볼륨에 원자 쓰기 → 즉시 삭제
  $smoke = Join-Path $RepoRoot 'webui\public\_klc-smoke.txt'
  $smokeContent = "[klc-smoke] $(Get-Date -Format o)"
  Write-AtomicUtf8 -Path $smoke -Content $smokeContent -Module 'patcher' -Action 'smoke'
  if (Test-Path $smoke) { Remove-Item -LiteralPath $smoke -Force -ErrorAction SilentlyContinue }

  # ── Patch 파일 파싱 ───────────────────────────────────────────────────────────
  $PatchFile = Join-Path $RepoRoot '.kobong\patches.pending.txt'
  if (!(Test-Path $PatchFile)) {
  Write-Host "[SKIP] patches file not found → $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("patches-file-missing: "+$PatchFile) } catch {}
  return
}
  $patchText = Get-Content -LiteralPath $PatchFile -Raw -Encoding UTF8
  $global:patchHash = (Get-FileHash -Algorithm SHA256 -InputStream ([IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes($patchText)))).Hash

  $matches = [regex]::Matches($patchText, '(?ms)#\s*PATCH\s*START\s*(?<body>.*?)#\s*PATCH\s*END')
  if ($matches.Count -eq 0) {
  Write-Host "[SKIP] No PATCH blocks found in $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("no-patch-blocks: "+$PatchFile) } catch {}
  return
}

  $applied = @()
  foreach ($m in $matches) {
    $body = $m.Groups['body'].Value

    $targetRel = [regex]::Match($body, 'TARGET:\s*(?<v>.+)').Groups['v'].Value.Trim()
    $mode      = [regex]::Match($body, 'MODE:\s*(?<v>.+)').Groups['v'].Value.Trim().ToLowerInvariant()
    $find      = [regex]::Match($body, "FIND\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value
    $replace   = [regex]::Match($body, "REPLACE\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value

    if (-not $targetRel) { throw "PATCH missing TARGET" }
    if (-not $mode)      { throw "PATCH missing MODE" }
    if (-not $find)      { throw "PATCH missing FIND" }

    $target = Join-Path $RepoRoot $targetRel
    if (!(Test-Path $target)) {
  Write-Host "[SKIP] TARGET not found → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("target-not-found: "+$targetRel) } catch {}
  continue
}

    $orig = Get-Content -LiteralPath $target -Raw -Encoding UTF8
    $rxOpts = [Text.RegularExpressions.RegexOptions]::Multiline -bor [Text.RegularExpressions.RegexOptions]::Singleline
    $rx = [regex]::new($find, $rxOpts)
    $mt = $rx.Match($orig)
    if (-not $mt.Success) {
  Write-Host "[SKIP] FIND not matched → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("find-not-matched: "+$targetRel) } catch {}
  continue
}

    switch ($mode) {
      'insert-before' {
        $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
      }
      'insert-before' {
  $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
}
'insert-after' {
  $new = $orig.Substring(0, $mt.Index + $mt.Length) + "`n" + $replace + $orig.Substring($mt.Index + $mt.Length)
}
'replace' {
        $new = $rx.Replace($orig, $replace, 1)
      }
      default {
  Write-Host "[SKIP] Unsupported MODE → $mode for $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("unsupported-mode: "+$mode+" for "+$targetRel) } catch {}
  continue
}
    }

    if ($ConfirmApply) {
      $bk = "$target.bak-" + (Get-Date -Format 'yyyyMMdd-HHmmss')
      Copy-Item -LiteralPath $target -Destination $bk -Force
      Write-AtomicUtf8 -Path $target -Content $new -Module 'patcher' -Action ('apply:'+ $mode)
      $applied += $targetRel
    } else {
      Write-Host "[PREVIEW] would patch → $targetRel ($mode)"
    }
  }

  if ($ConfirmApply) {
    LogRec 'INFO' 'apply' 'SUCCESS' ("patched: " + ($applied -join ', '))
  } else {
    LogRec 'INFO' 'preview' 'SUCCESS' ("preview-ok (no writes). blocks="+$matches.Count)
  }

  # ── Gate-3 Verify (경량) ───────────────────────────────────────────────────────
  if ($ConfirmApply) {
    # 핵심 타겟의 구문 일치 재검
    $core = Join-Path $RepoRoot 'scripts\apply_ui_patch.ps1'
    if (Test-Path $core) {
      $c = Get-Content -LiteralPath $core -Raw -Encoding UTF8
      if ($c -notmatch 'ensure valid tmp path .* atomic friendly') {
        Write-Host "[WARN] VERIFY: guard snippet not found in apply_ui_patch.ps1"; try { LogRec "WARN" "verify" "SKIPPED" "guard-missing apply_ui_patch.ps1" } catch {}
      }
    }
  }
}
catch {
  LogRec 'ERROR' 'apply' 'FAILURE' $_.Exception.Message 'LOGIC'
  exit 0
}
finally {
  Remove-Item -Force $LockFile -ErrorAction SilentlyContinue
}
.Exception.Message)" }
  # 스모크: 같은 볼륨에 원자 쓰기 → 즉시 삭제
  $smoke = Join-Path $RepoRoot 'webui\public\_klc-smoke.txt'
  $smokeContent = "[klc-smoke] $(Get-Date -Format o)"
  Write-AtomicUtf8 -Path $smoke -Content $smokeContent -Module 'patcher' -Action 'smoke'
  if (Test-Path $smoke) { Remove-Item -LiteralPath $smoke -Force -ErrorAction SilentlyContinue }

  # ── Patch 파일 파싱 ───────────────────────────────────────────────────────────
  $PatchFile = Join-Path $RepoRoot '.kobong\patches.pending.txt'
  if (!(Test-Path $PatchFile)) {
  Write-Host "[SKIP] patches file not found → $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("patches-file-missing: "+$PatchFile) } catch {}
  return
}
  $patchText = Get-Content -LiteralPath $PatchFile -Raw -Encoding UTF8
  $global:patchHash = (Get-FileHash -Algorithm SHA256 -InputStream ([IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes($patchText)))).Hash

  $matches = [regex]::Matches($patchText, '(?ms)#\s*PATCH\s*START\s*(?<body>.*?)#\s*PATCH\s*END')
  if ($matches.Count -eq 0) {
  Write-Host "[SKIP] No PATCH blocks found in $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("no-patch-blocks: "+$PatchFile) } catch {}
  return
}

  $applied = @()
  foreach ($m in $matches) {
    $body = $m.Groups['body'].Value

    $targetRel = [regex]::Match($body, 'TARGET:\s*(?<v>.+)').Groups['v'].Value.Trim()
    $mode      = [regex]::Match($body, 'MODE:\s*(?<v>.+)').Groups['v'].Value.Trim().ToLowerInvariant()
    $find      = [regex]::Match($body, "FIND\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value
    $replace   = [regex]::Match($body, "REPLACE\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value

    if (-not $targetRel) { throw "PATCH missing TARGET" }
    if (-not $mode)      { throw "PATCH missing MODE" }
    if (-not $find)      { throw "PATCH missing FIND" }

    $target = Join-Path $RepoRoot $targetRel
    if (!(Test-Path $target)) {
  Write-Host "[SKIP] TARGET not found → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("target-not-found: "+$targetRel) } catch {}
  continue
}

    $orig = Get-Content -LiteralPath $target -Raw -Encoding UTF8
    $rxOpts = [Text.RegularExpressions.RegexOptions]::Multiline -bor [Text.RegularExpressions.RegexOptions]::Singleline
    $rx = [regex]::new($find, $rxOpts)
    $mt = $rx.Match($orig)
    if (-not $mt.Success) {
  Write-Host "[SKIP] FIND not matched → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("find-not-matched: "+$targetRel) } catch {}
  continue
}

    switch ($mode) {
      'insert-before' {
        $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
      }
      'insert-before' {
  $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
}
'insert-after' {
  $new = $orig.Substring(0, $mt.Index + $mt.Length) + "`n" + $replace + $orig.Substring($mt.Index + $mt.Length)
}
'replace' {
        $new = $rx.Replace($orig, $replace, 1)
      }
      default {
  Write-Host "[SKIP] Unsupported MODE → $mode for $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("unsupported-mode: "+$mode+" for "+$targetRel) } catch {}
  continue
}
    }

    if ($ConfirmApply) {
      $bk = "$target.bak-" + (Get-Date -Format 'yyyyMMdd-HHmmss')
      Copy-Item -LiteralPath $target -Destination $bk -Force
      Write-AtomicUtf8 -Path $target -Content $new -Module 'patcher' -Action ('apply:'+ $mode)
      $applied += $targetRel
    } else {
      Write-Host "[PREVIEW] would patch → $targetRel ($mode)"
    }
  }

  if ($ConfirmApply) {
    LogRec 'INFO' 'apply' 'SUCCESS' ("patched: " + ($applied -join ', '))
  } else {
    LogRec 'INFO' 'preview' 'SUCCESS' ("preview-ok (no writes). blocks="+$matches.Count)
  }

  # ── Gate-3 Verify (경량) ───────────────────────────────────────────────────────
  if ($ConfirmApply) {
    # 핵심 타겟의 구문 일치 재검
    $core = Join-Path $RepoRoot 'scripts\apply_ui_patch.ps1'
    if (Test-Path $core) {
      $c = Get-Content -LiteralPath $core -Raw -Encoding UTF8
      if ($c -notmatch 'ensure valid tmp path .* atomic friendly') {
        Write-Host "[WARN] VERIFY: guard snippet not found in apply_ui_patch.ps1"; try { LogRec "WARN" "verify" "SKIPPED" "guard-missing apply_ui_patch.ps1" } catch {}
      }
    }
  }
}
catch {
  LogRec 'ERROR' 'apply' 'FAILURE' $_.Exception.Message 'LOGIC'
  exit 0
}
finally {
  Remove-Item -Force $LockFile -ErrorAction SilentlyContinue
}
.Exception.Message) }

# ── Gate-0: Repo / Lock ─────────────────────────────────────────────────────────
function Get-RepoRoot {
  try {
    $p = (git rev-parse --show-toplevel 2>$null)
    if ($p) { return (Resolve-Path $p).Path }
  } catch {}
  if ($Root) { return (Resolve-Path $Root).Path }
  return (Get-Location).Path
}
$RepoRoot = Get-RepoRoot
$LockFile = Join-Path $RepoRoot '.gpt5.lock'
if (Test-Path $LockFile) { Write-Error 'CONFLICT: .gpt5.lock exists.'; exit 11 }
"locked $(Get-Date -Format o)" | Out-File $LockFile -Encoding utf8 -NoNewline

$sw=[Diagnostics.Stopwatch]::StartNew()
$trace=[guid]::NewGuid().ToString()
$logPath = Join-Path $RepoRoot 'logs/apply-log.jsonl'
New-Item -ItemType Directory -Force -Path (Split-Path $logPath) | Out-Null

function LogRec([string]$level,[string]$action,[string]$outcome,[string]$msg,[string]$err='') {
  $rec = @{
    timestamp=(Get-Date).ToString('o'); level=$level; traceId=$trace; module='patcher';
    action=$action; inputHash=((Get-Variable -Name patchHash -Scope Global -ValueOnly -ErrorAction SilentlyContinue) ?? ""); outcome=$outcome;
    durationMs=$sw.ElapsedMilliseconds; errorCode=$err; message=$msg
  } | ConvertTo-Json -Compress
  Add-Content -Path $logPath -Value $rec
}

try {
  # ── Preflight: 모듈 로드 & 스모크 ─────────────────────────────────────────────
  $ModPath = Join-Path $RepoRoot 'scripts\lib\kobong-fileio.psm1'
  if (!(Test-Path $ModPath)) { throw "Missing module: $ModPath" }
try { Import-Module $ModPath -Force } catch { Write-Host "[WARN] Import-Module failed → $ModPath: $(# APPLY IN SHELL
#requires -Version 7.0
param([switch]$ConfirmApply,[string]$Root)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

# ── Gate-0: Repo / Lock ─────────────────────────────────────────────────────────
function Get-RepoRoot {
  try {
    $p = (git rev-parse --show-toplevel 2>$null)
    if ($p) { return (Resolve-Path $p).Path }
  } catch {}
  if ($Root) { return (Resolve-Path $Root).Path }
  return (Get-Location).Path
}
$RepoRoot = Get-RepoRoot
$LockFile = Join-Path $RepoRoot '.gpt5.lock'
if (Test-Path $LockFile) { Write-Error 'CONFLICT: .gpt5.lock exists.'; exit 11 }
"locked $(Get-Date -Format o)" | Out-File $LockFile -Encoding utf8 -NoNewline

$sw=[Diagnostics.Stopwatch]::StartNew()
$trace=[guid]::NewGuid().ToString()
$logPath = Join-Path $RepoRoot 'logs/apply-log.jsonl'
New-Item -ItemType Directory -Force -Path (Split-Path $logPath) | Out-Null

function LogRec([string]$level,[string]$action,[string]$outcome,[string]$msg,[string]$err='') {
  $rec = @{
    timestamp=(Get-Date).ToString('o'); level=$level; traceId=$trace; module='patcher';
    action=$action; inputHash=((Get-Variable -Name patchHash -Scope Global -ValueOnly -ErrorAction SilentlyContinue) ?? ""); outcome=$outcome;
    durationMs=$sw.ElapsedMilliseconds; errorCode=$err; message=$msg
  } | ConvertTo-Json -Compress
  Add-Content -Path $logPath -Value $rec
}

try {
  # ── Preflight: 모듈 로드 & 스모크 ─────────────────────────────────────────────
  $ModPath = Join-Path $RepoRoot 'scripts\lib\kobong-fileio.psm1'
  if (!(Test-Path $ModPath)) { throw "Missing module: $ModPath" }
  Import-Module $ModPath -Force

  # 스모크: 같은 볼륨에 원자 쓰기 → 즉시 삭제
  $smoke = Join-Path $RepoRoot 'webui\public\_klc-smoke.txt'
  $smokeContent = "[klc-smoke] $(Get-Date -Format o)"
  Write-AtomicUtf8 -Path $smoke -Content $smokeContent -Module 'patcher' -Action 'smoke'
  if (Test-Path $smoke) { Remove-Item -LiteralPath $smoke -Force -ErrorAction SilentlyContinue }

  # ── Patch 파일 파싱 ───────────────────────────────────────────────────────────
  $PatchFile = Join-Path $RepoRoot '.kobong\patches.pending.txt'
  if (!(Test-Path $PatchFile)) {
  Write-Host "[SKIP] patches file not found → $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("patches-file-missing: "+$PatchFile) } catch {}
  return
}
  $patchText = Get-Content -LiteralPath $PatchFile -Raw -Encoding UTF8
  $global:patchHash = (Get-FileHash -Algorithm SHA256 -InputStream ([IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes($patchText)))).Hash

  $matches = [regex]::Matches($patchText, '(?ms)#\s*PATCH\s*START\s*(?<body>.*?)#\s*PATCH\s*END')
  if ($matches.Count -eq 0) {
  Write-Host "[SKIP] No PATCH blocks found in $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("no-patch-blocks: "+$PatchFile) } catch {}
  return
}

  $applied = @()
  foreach ($m in $matches) {
    $body = $m.Groups['body'].Value

    $targetRel = [regex]::Match($body, 'TARGET:\s*(?<v>.+)').Groups['v'].Value.Trim()
    $mode      = [regex]::Match($body, 'MODE:\s*(?<v>.+)').Groups['v'].Value.Trim().ToLowerInvariant()
    $find      = [regex]::Match($body, "FIND\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value
    $replace   = [regex]::Match($body, "REPLACE\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value

    if (-not $targetRel) { throw "PATCH missing TARGET" }
    if (-not $mode)      { throw "PATCH missing MODE" }
    if (-not $find)      { throw "PATCH missing FIND" }

    $target = Join-Path $RepoRoot $targetRel
    if (!(Test-Path $target)) {
  Write-Host "[SKIP] TARGET not found → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("target-not-found: "+$targetRel) } catch {}
  continue
}

    $orig = Get-Content -LiteralPath $target -Raw -Encoding UTF8
    $rxOpts = [Text.RegularExpressions.RegexOptions]::Multiline -bor [Text.RegularExpressions.RegexOptions]::Singleline
    $rx = [regex]::new($find, $rxOpts)
    $mt = $rx.Match($orig)
    if (-not $mt.Success) {
  Write-Host "[SKIP] FIND not matched → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("find-not-matched: "+$targetRel) } catch {}
  continue
}

    switch ($mode) {
      'insert-before' {
        $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
      }
      'insert-before' {
  $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
}
'insert-after' {
  $new = $orig.Substring(0, $mt.Index + $mt.Length) + "`n" + $replace + $orig.Substring($mt.Index + $mt.Length)
}
'replace' {
        $new = $rx.Replace($orig, $replace, 1)
      }
      default {
  Write-Host "[SKIP] Unsupported MODE → $mode for $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("unsupported-mode: "+$mode+" for "+$targetRel) } catch {}
  continue
}
    }

    if ($ConfirmApply) {
      $bk = "$target.bak-" + (Get-Date -Format 'yyyyMMdd-HHmmss')
      Copy-Item -LiteralPath $target -Destination $bk -Force
      Write-AtomicUtf8 -Path $target -Content $new -Module 'patcher' -Action ('apply:'+ $mode)
      $applied += $targetRel
    } else {
      Write-Host "[PREVIEW] would patch → $targetRel ($mode)"
    }
  }

  if ($ConfirmApply) {
    LogRec 'INFO' 'apply' 'SUCCESS' ("patched: " + ($applied -join ', '))
  } else {
    LogRec 'INFO' 'preview' 'SUCCESS' ("preview-ok (no writes). blocks="+$matches.Count)
  }

  # ── Gate-3 Verify (경량) ───────────────────────────────────────────────────────
  if ($ConfirmApply) {
    # 핵심 타겟의 구문 일치 재검
    $core = Join-Path $RepoRoot 'scripts\apply_ui_patch.ps1'
    if (Test-Path $core) {
      $c = Get-Content -LiteralPath $core -Raw -Encoding UTF8
      if ($c -notmatch 'ensure valid tmp path .* atomic friendly') {
        Write-Host "[WARN] VERIFY: guard snippet not found in apply_ui_patch.ps1"; try { LogRec "WARN" "verify" "SKIPPED" "guard-missing apply_ui_patch.ps1" } catch {}
      }
    }
  }
}
catch {
  LogRec 'ERROR' 'apply' 'FAILURE' $_.Exception.Message 'LOGIC'
  exit 0
}
finally {
  Remove-Item -Force $LockFile -ErrorAction SilentlyContinue
}
.Exception.Message)" }
  # 스모크: 같은 볼륨에 원자 쓰기 → 즉시 삭제
  $smoke = Join-Path $RepoRoot 'webui\public\_klc-smoke.txt'
  $smokeContent = "[klc-smoke] $(Get-Date -Format o)"
  Write-AtomicUtf8 -Path $smoke -Content $smokeContent -Module 'patcher' -Action 'smoke'
  if (Test-Path $smoke) { Remove-Item -LiteralPath $smoke -Force -ErrorAction SilentlyContinue }

  # ── Patch 파일 파싱 ───────────────────────────────────────────────────────────
  $PatchFile = Join-Path $RepoRoot '.kobong\patches.pending.txt'
  if (!(Test-Path $PatchFile)) {
  Write-Host "[SKIP] patches file not found → $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("patches-file-missing: "+$PatchFile) } catch {}
  return
}
  $patchText = Get-Content -LiteralPath $PatchFile -Raw -Encoding UTF8
  $global:patchHash = (Get-FileHash -Algorithm SHA256 -InputStream ([IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes($patchText)))).Hash

  $matches = [regex]::Matches($patchText, '(?ms)#\s*PATCH\s*START\s*(?<body>.*?)#\s*PATCH\s*END')
  if ($matches.Count -eq 0) {
  Write-Host "[SKIP] No PATCH blocks found in $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("no-patch-blocks: "+$PatchFile) } catch {}
  return
}

  $applied = @()
  foreach ($m in $matches) {
    $body = $m.Groups['body'].Value

    $targetRel = [regex]::Match($body, 'TARGET:\s*(?<v>.+)').Groups['v'].Value.Trim()
    $mode      = [regex]::Match($body, 'MODE:\s*(?<v>.+)').Groups['v'].Value.Trim().ToLowerInvariant()
    $find      = [regex]::Match($body, "FIND\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value
    $replace   = [regex]::Match($body, "REPLACE\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value

    if (-not $targetRel) { throw "PATCH missing TARGET" }
    if (-not $mode)      { throw "PATCH missing MODE" }
    if (-not $find)      { throw "PATCH missing FIND" }

    $target = Join-Path $RepoRoot $targetRel
    if (!(Test-Path $target)) {
  Write-Host "[SKIP] TARGET not found → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("target-not-found: "+$targetRel) } catch {}
  continue
}

    $orig = Get-Content -LiteralPath $target -Raw -Encoding UTF8
    $rxOpts = [Text.RegularExpressions.RegexOptions]::Multiline -bor [Text.RegularExpressions.RegexOptions]::Singleline
    $rx = [regex]::new($find, $rxOpts)
    $mt = $rx.Match($orig)
    if (-not $mt.Success) {
  Write-Host "[SKIP] FIND not matched → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("find-not-matched: "+$targetRel) } catch {}
  continue
}

    switch ($mode) {
      'insert-before' {
        $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
      }
      'insert-before' {
  $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
}
'insert-after' {
  $new = $orig.Substring(0, $mt.Index + $mt.Length) + "`n" + $replace + $orig.Substring($mt.Index + $mt.Length)
}
'replace' {
        $new = $rx.Replace($orig, $replace, 1)
      }
      default {
  Write-Host "[SKIP] Unsupported MODE → $mode for $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("unsupported-mode: "+$mode+" for "+$targetRel) } catch {}
  continue
}
    }

    if ($ConfirmApply) {
      $bk = "$target.bak-" + (Get-Date -Format 'yyyyMMdd-HHmmss')
      Copy-Item -LiteralPath $target -Destination $bk -Force
      Write-AtomicUtf8 -Path $target -Content $new -Module 'patcher' -Action ('apply:'+ $mode)
      $applied += $targetRel
    } else {
      Write-Host "[PREVIEW] would patch → $targetRel ($mode)"
    }
  }

  if ($ConfirmApply) {
    LogRec 'INFO' 'apply' 'SUCCESS' ("patched: " + ($applied -join ', '))
  } else {
    LogRec 'INFO' 'preview' 'SUCCESS' ("preview-ok (no writes). blocks="+$matches.Count)
  }

  # ── Gate-3 Verify (경량) ───────────────────────────────────────────────────────
  if ($ConfirmApply) {
    # 핵심 타겟의 구문 일치 재검
    $core = Join-Path $RepoRoot 'scripts\apply_ui_patch.ps1'
    if (Test-Path $core) {
      $c = Get-Content -LiteralPath $core -Raw -Encoding UTF8
      if ($c -notmatch 'ensure valid tmp path .* atomic friendly') {
        Write-Host "[WARN] VERIFY: guard snippet not found in apply_ui_patch.ps1"; try { LogRec "WARN" "verify" "SKIPPED" "guard-missing apply_ui_patch.ps1" } catch {}
      }
    }
  }
}
catch {
  LogRec 'ERROR' 'apply' 'FAILURE' $_.Exception.Message 'LOGIC'
  exit 0
}
finally {
  Remove-Item -Force $LockFile -ErrorAction SilentlyContinue
}
.Exception.Message)" }
}
try { Import-Module $ModPath -Force } catch { Write-Host "[WARN] Import-Module failed → $ModPath: $(# APPLY IN SHELL
#requires -Version 7.0
param([switch]$ConfirmApply,[string]$Root)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

# ── Gate-0: Repo / Lock ─────────────────────────────────────────────────────────
function Get-RepoRoot {
  try {
    $p = (git rev-parse --show-toplevel 2>$null)
    if ($p) { return (Resolve-Path $p).Path }
  } catch {}
  if ($Root) { return (Resolve-Path $Root).Path }
  return (Get-Location).Path
}
$RepoRoot = Get-RepoRoot
$LockFile = Join-Path $RepoRoot '.gpt5.lock'
if (Test-Path $LockFile) { Write-Error 'CONFLICT: .gpt5.lock exists.'; exit 11 }
"locked $(Get-Date -Format o)" | Out-File $LockFile -Encoding utf8 -NoNewline

$sw=[Diagnostics.Stopwatch]::StartNew()
$trace=[guid]::NewGuid().ToString()
$logPath = Join-Path $RepoRoot 'logs/apply-log.jsonl'
New-Item -ItemType Directory -Force -Path (Split-Path $logPath) | Out-Null

function LogRec([string]$level,[string]$action,[string]$outcome,[string]$msg,[string]$err='') {
  $rec = @{
    timestamp=(Get-Date).ToString('o'); level=$level; traceId=$trace; module='patcher';
    action=$action; inputHash=((Get-Variable -Name patchHash -Scope Global -ValueOnly -ErrorAction SilentlyContinue) ?? ""); outcome=$outcome;
    durationMs=$sw.ElapsedMilliseconds; errorCode=$err; message=$msg
  } | ConvertTo-Json -Compress
  Add-Content -Path $logPath -Value $rec
}

try {
  # ── Preflight: 모듈 로드 & 스모크 ─────────────────────────────────────────────
  $ModPath = Join-Path $RepoRoot 'scripts\lib\kobong-fileio.psm1'
  if (!(Test-Path $ModPath)) {
  Write-Host "[WARN] Missing module → $ModPath (continuing)"
  try { LogRec "WARN" "apply" "SKIPPED" ("missing-module: "+$ModPath) } catch {}
} else {
  try { Import-Module $ModPath -Force } catch { Write-Host "[WARN] Import-Module failed → $ModPath: $(# APPLY IN SHELL
#requires -Version 7.0
param([switch]$ConfirmApply,[string]$Root)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

# ── Gate-0: Repo / Lock ─────────────────────────────────────────────────────────
function Get-RepoRoot {
  try {
    $p = (git rev-parse --show-toplevel 2>$null)
    if ($p) { return (Resolve-Path $p).Path }
  } catch {}
  if ($Root) { return (Resolve-Path $Root).Path }
  return (Get-Location).Path
}
$RepoRoot = Get-RepoRoot
$LockFile = Join-Path $RepoRoot '.gpt5.lock'
if (Test-Path $LockFile) { Write-Error 'CONFLICT: .gpt5.lock exists.'; exit 11 }
"locked $(Get-Date -Format o)" | Out-File $LockFile -Encoding utf8 -NoNewline

$sw=[Diagnostics.Stopwatch]::StartNew()
$trace=[guid]::NewGuid().ToString()
$logPath = Join-Path $RepoRoot 'logs/apply-log.jsonl'
New-Item -ItemType Directory -Force -Path (Split-Path $logPath) | Out-Null

function LogRec([string]$level,[string]$action,[string]$outcome,[string]$msg,[string]$err='') {
  $rec = @{
    timestamp=(Get-Date).ToString('o'); level=$level; traceId=$trace; module='patcher';
    action=$action; inputHash=((Get-Variable -Name patchHash -Scope Global -ValueOnly -ErrorAction SilentlyContinue) ?? ""); outcome=$outcome;
    durationMs=$sw.ElapsedMilliseconds; errorCode=$err; message=$msg
  } | ConvertTo-Json -Compress
  Add-Content -Path $logPath -Value $rec
}

try {
  # ── Preflight: 모듈 로드 & 스모크 ─────────────────────────────────────────────
  $ModPath = Join-Path $RepoRoot 'scripts\lib\kobong-fileio.psm1'
  if (!(Test-Path $ModPath)) { throw "Missing module: $ModPath" }
try { Import-Module $ModPath -Force } catch { Write-Host "[WARN] Import-Module failed → $ModPath: $(# APPLY IN SHELL
#requires -Version 7.0
param([switch]$ConfirmApply,[string]$Root)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

# ── Gate-0: Repo / Lock ─────────────────────────────────────────────────────────
function Get-RepoRoot {
  try {
    $p = (git rev-parse --show-toplevel 2>$null)
    if ($p) { return (Resolve-Path $p).Path }
  } catch {}
  if ($Root) { return (Resolve-Path $Root).Path }
  return (Get-Location).Path
}
$RepoRoot = Get-RepoRoot
$LockFile = Join-Path $RepoRoot '.gpt5.lock'
if (Test-Path $LockFile) { Write-Error 'CONFLICT: .gpt5.lock exists.'; exit 11 }
"locked $(Get-Date -Format o)" | Out-File $LockFile -Encoding utf8 -NoNewline

$sw=[Diagnostics.Stopwatch]::StartNew()
$trace=[guid]::NewGuid().ToString()
$logPath = Join-Path $RepoRoot 'logs/apply-log.jsonl'
New-Item -ItemType Directory -Force -Path (Split-Path $logPath) | Out-Null

function LogRec([string]$level,[string]$action,[string]$outcome,[string]$msg,[string]$err='') {
  $rec = @{
    timestamp=(Get-Date).ToString('o'); level=$level; traceId=$trace; module='patcher';
    action=$action; inputHash=((Get-Variable -Name patchHash -Scope Global -ValueOnly -ErrorAction SilentlyContinue) ?? ""); outcome=$outcome;
    durationMs=$sw.ElapsedMilliseconds; errorCode=$err; message=$msg
  } | ConvertTo-Json -Compress
  Add-Content -Path $logPath -Value $rec
}

try {
  # ── Preflight: 모듈 로드 & 스모크 ─────────────────────────────────────────────
  $ModPath = Join-Path $RepoRoot 'scripts\lib\kobong-fileio.psm1'
  if (!(Test-Path $ModPath)) { throw "Missing module: $ModPath" }
  Import-Module $ModPath -Force

  # 스모크: 같은 볼륨에 원자 쓰기 → 즉시 삭제
  $smoke = Join-Path $RepoRoot 'webui\public\_klc-smoke.txt'
  $smokeContent = "[klc-smoke] $(Get-Date -Format o)"
  Write-AtomicUtf8 -Path $smoke -Content $smokeContent -Module 'patcher' -Action 'smoke'
  if (Test-Path $smoke) { Remove-Item -LiteralPath $smoke -Force -ErrorAction SilentlyContinue }

  # ── Patch 파일 파싱 ───────────────────────────────────────────────────────────
  $PatchFile = Join-Path $RepoRoot '.kobong\patches.pending.txt'
  if (!(Test-Path $PatchFile)) {
  Write-Host "[SKIP] patches file not found → $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("patches-file-missing: "+$PatchFile) } catch {}
  return
}
  $patchText = Get-Content -LiteralPath $PatchFile -Raw -Encoding UTF8
  $global:patchHash = (Get-FileHash -Algorithm SHA256 -InputStream ([IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes($patchText)))).Hash

  $matches = [regex]::Matches($patchText, '(?ms)#\s*PATCH\s*START\s*(?<body>.*?)#\s*PATCH\s*END')
  if ($matches.Count -eq 0) {
  Write-Host "[SKIP] No PATCH blocks found in $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("no-patch-blocks: "+$PatchFile) } catch {}
  return
}

  $applied = @()
  foreach ($m in $matches) {
    $body = $m.Groups['body'].Value

    $targetRel = [regex]::Match($body, 'TARGET:\s*(?<v>.+)').Groups['v'].Value.Trim()
    $mode      = [regex]::Match($body, 'MODE:\s*(?<v>.+)').Groups['v'].Value.Trim().ToLowerInvariant()
    $find      = [regex]::Match($body, "FIND\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value
    $replace   = [regex]::Match($body, "REPLACE\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value

    if (-not $targetRel) { throw "PATCH missing TARGET" }
    if (-not $mode)      { throw "PATCH missing MODE" }
    if (-not $find)      { throw "PATCH missing FIND" }

    $target = Join-Path $RepoRoot $targetRel
    if (!(Test-Path $target)) {
  Write-Host "[SKIP] TARGET not found → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("target-not-found: "+$targetRel) } catch {}
  continue
}

    $orig = Get-Content -LiteralPath $target -Raw -Encoding UTF8
    $rxOpts = [Text.RegularExpressions.RegexOptions]::Multiline -bor [Text.RegularExpressions.RegexOptions]::Singleline
    $rx = [regex]::new($find, $rxOpts)
    $mt = $rx.Match($orig)
    if (-not $mt.Success) {
  Write-Host "[SKIP] FIND not matched → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("find-not-matched: "+$targetRel) } catch {}
  continue
}

    switch ($mode) {
      'insert-before' {
        $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
      }
      'insert-before' {
  $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
}
'insert-after' {
  $new = $orig.Substring(0, $mt.Index + $mt.Length) + "`n" + $replace + $orig.Substring($mt.Index + $mt.Length)
}
'replace' {
        $new = $rx.Replace($orig, $replace, 1)
      }
      default {
  Write-Host "[SKIP] Unsupported MODE → $mode for $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("unsupported-mode: "+$mode+" for "+$targetRel) } catch {}
  continue
}
    }

    if ($ConfirmApply) {
      $bk = "$target.bak-" + (Get-Date -Format 'yyyyMMdd-HHmmss')
      Copy-Item -LiteralPath $target -Destination $bk -Force
      Write-AtomicUtf8 -Path $target -Content $new -Module 'patcher' -Action ('apply:'+ $mode)
      $applied += $targetRel
    } else {
      Write-Host "[PREVIEW] would patch → $targetRel ($mode)"
    }
  }

  if ($ConfirmApply) {
    LogRec 'INFO' 'apply' 'SUCCESS' ("patched: " + ($applied -join ', '))
  } else {
    LogRec 'INFO' 'preview' 'SUCCESS' ("preview-ok (no writes). blocks="+$matches.Count)
  }

  # ── Gate-3 Verify (경량) ───────────────────────────────────────────────────────
  if ($ConfirmApply) {
    # 핵심 타겟의 구문 일치 재검
    $core = Join-Path $RepoRoot 'scripts\apply_ui_patch.ps1'
    if (Test-Path $core) {
      $c = Get-Content -LiteralPath $core -Raw -Encoding UTF8
      if ($c -notmatch 'ensure valid tmp path .* atomic friendly') {
        Write-Host "[WARN] VERIFY: guard snippet not found in apply_ui_patch.ps1"; try { LogRec "WARN" "verify" "SKIPPED" "guard-missing apply_ui_patch.ps1" } catch {}
      }
    }
  }
}
catch {
  LogRec 'ERROR' 'apply' 'FAILURE' $_.Exception.Message 'LOGIC'
  exit 0
}
finally {
  Remove-Item -Force $LockFile -ErrorAction SilentlyContinue
}
.Exception.Message)" }
  # 스모크: 같은 볼륨에 원자 쓰기 → 즉시 삭제
  $smoke = Join-Path $RepoRoot 'webui\public\_klc-smoke.txt'
  $smokeContent = "[klc-smoke] $(Get-Date -Format o)"
  Write-AtomicUtf8 -Path $smoke -Content $smokeContent -Module 'patcher' -Action 'smoke'
  if (Test-Path $smoke) { Remove-Item -LiteralPath $smoke -Force -ErrorAction SilentlyContinue }

  # ── Patch 파일 파싱 ───────────────────────────────────────────────────────────
  $PatchFile = Join-Path $RepoRoot '.kobong\patches.pending.txt'
  if (!(Test-Path $PatchFile)) {
  Write-Host "[SKIP] patches file not found → $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("patches-file-missing: "+$PatchFile) } catch {}
  return
}
  $patchText = Get-Content -LiteralPath $PatchFile -Raw -Encoding UTF8
  $global:patchHash = (Get-FileHash -Algorithm SHA256 -InputStream ([IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes($patchText)))).Hash

  $matches = [regex]::Matches($patchText, '(?ms)#\s*PATCH\s*START\s*(?<body>.*?)#\s*PATCH\s*END')
  if ($matches.Count -eq 0) {
  Write-Host "[SKIP] No PATCH blocks found in $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("no-patch-blocks: "+$PatchFile) } catch {}
  return
}

  $applied = @()
  foreach ($m in $matches) {
    $body = $m.Groups['body'].Value

    $targetRel = [regex]::Match($body, 'TARGET:\s*(?<v>.+)').Groups['v'].Value.Trim()
    $mode      = [regex]::Match($body, 'MODE:\s*(?<v>.+)').Groups['v'].Value.Trim().ToLowerInvariant()
    $find      = [regex]::Match($body, "FIND\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value
    $replace   = [regex]::Match($body, "REPLACE\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value

    if (-not $targetRel) { throw "PATCH missing TARGET" }
    if (-not $mode)      { throw "PATCH missing MODE" }
    if (-not $find)      { throw "PATCH missing FIND" }

    $target = Join-Path $RepoRoot $targetRel
    if (!(Test-Path $target)) {
  Write-Host "[SKIP] TARGET not found → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("target-not-found: "+$targetRel) } catch {}
  continue
}

    $orig = Get-Content -LiteralPath $target -Raw -Encoding UTF8
    $rxOpts = [Text.RegularExpressions.RegexOptions]::Multiline -bor [Text.RegularExpressions.RegexOptions]::Singleline
    $rx = [regex]::new($find, $rxOpts)
    $mt = $rx.Match($orig)
    if (-not $mt.Success) {
  Write-Host "[SKIP] FIND not matched → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("find-not-matched: "+$targetRel) } catch {}
  continue
}

    switch ($mode) {
      'insert-before' {
        $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
      }
      'insert-before' {
  $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
}
'insert-after' {
  $new = $orig.Substring(0, $mt.Index + $mt.Length) + "`n" + $replace + $orig.Substring($mt.Index + $mt.Length)
}
'replace' {
        $new = $rx.Replace($orig, $replace, 1)
      }
      default {
  Write-Host "[SKIP] Unsupported MODE → $mode for $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("unsupported-mode: "+$mode+" for "+$targetRel) } catch {}
  continue
}
    }

    if ($ConfirmApply) {
      $bk = "$target.bak-" + (Get-Date -Format 'yyyyMMdd-HHmmss')
      Copy-Item -LiteralPath $target -Destination $bk -Force
      Write-AtomicUtf8 -Path $target -Content $new -Module 'patcher' -Action ('apply:'+ $mode)
      $applied += $targetRel
    } else {
      Write-Host "[PREVIEW] would patch → $targetRel ($mode)"
    }
  }

  if ($ConfirmApply) {
    LogRec 'INFO' 'apply' 'SUCCESS' ("patched: " + ($applied -join ', '))
  } else {
    LogRec 'INFO' 'preview' 'SUCCESS' ("preview-ok (no writes). blocks="+$matches.Count)
  }

  # ── Gate-3 Verify (경량) ───────────────────────────────────────────────────────
  if ($ConfirmApply) {
    # 핵심 타겟의 구문 일치 재검
    $core = Join-Path $RepoRoot 'scripts\apply_ui_patch.ps1'
    if (Test-Path $core) {
      $c = Get-Content -LiteralPath $core -Raw -Encoding UTF8
      if ($c -notmatch 'ensure valid tmp path .* atomic friendly') {
        Write-Host "[WARN] VERIFY: guard snippet not found in apply_ui_patch.ps1"; try { LogRec "WARN" "verify" "SKIPPED" "guard-missing apply_ui_patch.ps1" } catch {}
      }
    }
  }
}
catch {
  LogRec 'ERROR' 'apply' 'FAILURE' $_.Exception.Message 'LOGIC'
  exit 0
}
finally {
  Remove-Item -Force $LockFile -ErrorAction SilentlyContinue
}
.Exception.Message)" }
}
  Import-Module $ModPath -Force

  # 스모크: 같은 볼륨에 원자 쓰기 → 즉시 삭제
  $smoke = Join-Path $RepoRoot 'webui\public\_klc-smoke.txt'
  $smokeContent = "[klc-smoke] $(Get-Date -Format o)"
  Write-AtomicUtf8 -Path $smoke -Content $smokeContent -Module 'patcher' -Action 'smoke'
  if (Test-Path $smoke) { Remove-Item -LiteralPath $smoke -Force -ErrorAction SilentlyContinue }

  # ── Patch 파일 파싱 ───────────────────────────────────────────────────────────
  $PatchFile = Join-Path $RepoRoot '.kobong\patches.pending.txt'
  if (!(Test-Path $PatchFile)) {
  Write-Host "[SKIP] patches file not found → $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("patches-file-missing: "+$PatchFile) } catch {}
  return
}
  $patchText = Get-Content -LiteralPath $PatchFile -Raw -Encoding UTF8
  $global:patchHash = (Get-FileHash -Algorithm SHA256 -InputStream ([IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes($patchText)))).Hash

  $matches = [regex]::Matches($patchText, '(?ms)#\s*PATCH\s*START\s*(?<body>.*?)#\s*PATCH\s*END')
  if ($matches.Count -eq 0) {
  Write-Host "[SKIP] No PATCH blocks found in $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("no-patch-blocks: "+$PatchFile) } catch {}
  return
}

  $applied = @()
  foreach ($m in $matches) {
    $body = $m.Groups['body'].Value

    $targetRel = [regex]::Match($body, 'TARGET:\s*(?<v>.+)').Groups['v'].Value.Trim()
    $mode      = [regex]::Match($body, 'MODE:\s*(?<v>.+)').Groups['v'].Value.Trim().ToLowerInvariant()
    $find      = [regex]::Match($body, "FIND\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value
    $replace   = [regex]::Match($body, "REPLACE\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value

    if (-not $targetRel) { throw "PATCH missing TARGET" }
    if (-not $mode)      { throw "PATCH missing MODE" }
    if (-not $find)      { throw "PATCH missing FIND" }

    $target = Join-Path $RepoRoot $targetRel
    if (!(Test-Path $target)) {
  Write-Host "[SKIP] TARGET not found → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("target-not-found: "+$targetRel) } catch {}
  continue
}

    $orig = Get-Content -LiteralPath $target -Raw -Encoding UTF8
    $rxOpts = [Text.RegularExpressions.RegexOptions]::Multiline -bor [Text.RegularExpressions.RegexOptions]::Singleline
    $rx = [regex]::new($find, $rxOpts)
    $mt = $rx.Match($orig)
    if (-not $mt.Success) {
  Write-Host "[SKIP] FIND not matched → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("find-not-matched: "+$targetRel) } catch {}
  continue
}

    switch ($mode) {
      'insert-before' {
        $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
      }
      'insert-before' {
  $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
}
'insert-after' {
  $new = $orig.Substring(0, $mt.Index + $mt.Length) + "`n" + $replace + $orig.Substring($mt.Index + $mt.Length)
}
'replace' {
        $new = $rx.Replace($orig, $replace, 1)
      }
      default {
  Write-Host "[SKIP] Unsupported MODE → $mode for $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("unsupported-mode: "+$mode+" for "+$targetRel) } catch {}
  continue
}
    }

    if ($ConfirmApply) {
      $bk = "$target.bak-" + (Get-Date -Format 'yyyyMMdd-HHmmss')
      Copy-Item -LiteralPath $target -Destination $bk -Force
      Write-AtomicUtf8 -Path $target -Content $new -Module 'patcher' -Action ('apply:'+ $mode)
      $applied += $targetRel
    } else {
      Write-Host "[PREVIEW] would patch → $targetRel ($mode)"
    }
  }

  if ($ConfirmApply) {
    LogRec 'INFO' 'apply' 'SUCCESS' ("patched: " + ($applied -join ', '))
  } else {
    LogRec 'INFO' 'preview' 'SUCCESS' ("preview-ok (no writes). blocks="+$matches.Count)
  }

  # ── Gate-3 Verify (경량) ───────────────────────────────────────────────────────
  if ($ConfirmApply) {
    # 핵심 타겟의 구문 일치 재검
    $core = Join-Path $RepoRoot 'scripts\apply_ui_patch.ps1'
    if (Test-Path $core) {
      $c = Get-Content -LiteralPath $core -Raw -Encoding UTF8
      if ($c -notmatch 'ensure valid tmp path .* atomic friendly') {
        Write-Host "[WARN] VERIFY: guard snippet not found in apply_ui_patch.ps1"; try { LogRec "WARN" "verify" "SKIPPED" "guard-missing apply_ui_patch.ps1" } catch {}
      }
    }
  }
}
catch {
  LogRec 'ERROR' 'apply' 'FAILURE' $_.Exception.Message 'LOGIC'
  exit 0
}
finally {
  Remove-Item -Force $LockFile -ErrorAction SilentlyContinue
}
.Exception.Message)" }
  # 스모크: 같은 볼륨에 원자 쓰기 → 즉시 삭제
  $smoke = Join-Path $RepoRoot 'webui\public\_klc-smoke.txt'
  $smokeContent = "[klc-smoke] $(Get-Date -Format o)"
  Write-AtomicUtf8 -Path $smoke -Content $smokeContent -Module 'patcher' -Action 'smoke'
  if (Test-Path $smoke) { Remove-Item -LiteralPath $smoke -Force -ErrorAction SilentlyContinue }

  # ── Patch 파일 파싱 ───────────────────────────────────────────────────────────
  $PatchFile = Join-Path $RepoRoot '.kobong\patches.pending.txt'
  if (!(Test-Path $PatchFile)) {
  Write-Host "[SKIP] patches file not found → $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("patches-file-missing: "+$PatchFile) } catch {}
  return
}
  $patchText = Get-Content -LiteralPath $PatchFile -Raw -Encoding UTF8
  $global:patchHash = (Get-FileHash -Algorithm SHA256 -InputStream ([IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes($patchText)))).Hash

  $matches = [regex]::Matches($patchText, '(?ms)#\s*PATCH\s*START\s*(?<body>.*?)#\s*PATCH\s*END')
  if ($matches.Count -eq 0) {
  Write-Host "[SKIP] No PATCH blocks found in $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("no-patch-blocks: "+$PatchFile) } catch {}
  return
}

  $applied = @()
  foreach ($m in $matches) {
    $body = $m.Groups['body'].Value

    $targetRel = [regex]::Match($body, 'TARGET:\s*(?<v>.+)').Groups['v'].Value.Trim()
    $mode      = [regex]::Match($body, 'MODE:\s*(?<v>.+)').Groups['v'].Value.Trim().ToLowerInvariant()
    $find      = [regex]::Match($body, "FIND\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value
    $replace   = [regex]::Match($body, "REPLACE\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value

    if (-not $targetRel) { throw "PATCH missing TARGET" }
    if (-not $mode)      { throw "PATCH missing MODE" }
    if (-not $find)      { throw "PATCH missing FIND" }

    $target = Join-Path $RepoRoot $targetRel
    if (!(Test-Path $target)) {
  Write-Host "[SKIP] TARGET not found → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("target-not-found: "+$targetRel) } catch {}
  continue
}

    $orig = Get-Content -LiteralPath $target -Raw -Encoding UTF8
    $rxOpts = [Text.RegularExpressions.RegexOptions]::Multiline -bor [Text.RegularExpressions.RegexOptions]::Singleline
    $rx = [regex]::new($find, $rxOpts)
    $mt = $rx.Match($orig)
    if (-not $mt.Success) {
  Write-Host "[SKIP] FIND not matched → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("find-not-matched: "+$targetRel) } catch {}
  continue
}

    switch ($mode) {
      'insert-before' {
        $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
      }
      'insert-before' {
  $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
}
'insert-after' {
  $new = $orig.Substring(0, $mt.Index + $mt.Length) + "`n" + $replace + $orig.Substring($mt.Index + $mt.Length)
}
'replace' {
        $new = $rx.Replace($orig, $replace, 1)
      }
      default {
  Write-Host "[SKIP] Unsupported MODE → $mode for $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("unsupported-mode: "+$mode+" for "+$targetRel) } catch {}
  continue
}
    }

    if ($ConfirmApply) {
      $bk = "$target.bak-" + (Get-Date -Format 'yyyyMMdd-HHmmss')
      Copy-Item -LiteralPath $target -Destination $bk -Force
      Write-AtomicUtf8 -Path $target -Content $new -Module 'patcher' -Action ('apply:'+ $mode)
      $applied += $targetRel
    } else {
      Write-Host "[PREVIEW] would patch → $targetRel ($mode)"
    }
  }

  if ($ConfirmApply) {
    LogRec 'INFO' 'apply' 'SUCCESS' ("patched: " + ($applied -join ', '))
  } else {
    LogRec 'INFO' 'preview' 'SUCCESS' ("preview-ok (no writes). blocks="+$matches.Count)
  }

  # ── Gate-3 Verify (경량) ───────────────────────────────────────────────────────
  if ($ConfirmApply) {
    # 핵심 타겟의 구문 일치 재검
    $core = Join-Path $RepoRoot 'scripts\apply_ui_patch.ps1'
    if (Test-Path $core) {
      $c = Get-Content -LiteralPath $core -Raw -Encoding UTF8
      if ($c -notmatch 'ensure valid tmp path .* atomic friendly') {
        Write-Host "[WARN] VERIFY: guard snippet not found in apply_ui_patch.ps1"; try { LogRec "WARN" "verify" "SKIPPED" "guard-missing apply_ui_patch.ps1" } catch {}
      }
    }
  }
}
catch {
  LogRec 'ERROR' 'apply' 'FAILURE' $_.Exception.Message 'LOGIC'
  exit 0
}
finally {
  Remove-Item -Force $LockFile -ErrorAction SilentlyContinue
}
.Exception.Message) }
  # 스모크: 같은 볼륨에 원자 쓰기 → 즉시 삭제
  $smoke = Join-Path $RepoRoot 'webui\public\_klc-smoke.txt'
  $smokeContent = "[klc-smoke] $(Get-Date -Format o)"
  Write-AtomicUtf8 -Path $smoke -Content $smokeContent -Module 'patcher' -Action 'smoke'
  if (Test-Path $smoke) { Remove-Item -LiteralPath $smoke -Force -ErrorAction SilentlyContinue }

  # ── Patch 파일 파싱 ───────────────────────────────────────────────────────────
  $PatchFile = Join-Path $RepoRoot '.kobong\patches.pending.txt'
  if (!(Test-Path $PatchFile)) {
  Write-Host "[SKIP] patches file not found → $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("patches-file-missing: "+$PatchFile) } catch {}
  return
}
  $patchText = Get-Content -LiteralPath $PatchFile -Raw -Encoding UTF8
  $global:patchHash = (Get-FileHash -Algorithm SHA256 -InputStream ([IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes($patchText)))).Hash

  $matches = [regex]::Matches($patchText, '(?ms)#\s*PATCH\s*START\s*(?<body>.*?)#\s*PATCH\s*END')
  if ($matches.Count -eq 0) {
  Write-Host "[SKIP] No PATCH blocks found in $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("no-patch-blocks: "+$PatchFile) } catch {}
  return
}

  $applied = @()
  foreach ($m in $matches) {
    $body = $m.Groups['body'].Value

    $targetRel = [regex]::Match($body, 'TARGET:\s*(?<v>.+)').Groups['v'].Value.Trim()
    $mode      = [regex]::Match($body, 'MODE:\s*(?<v>.+)').Groups['v'].Value.Trim().ToLowerInvariant()
    $find      = [regex]::Match($body, "FIND\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value
    $replace   = [regex]::Match($body, "REPLACE\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value

    if (-not $targetRel) { throw "PATCH missing TARGET" }
    if (-not $mode)      { throw "PATCH missing MODE" }
    if (-not $find)      { throw "PATCH missing FIND" }

    $target = Join-Path $RepoRoot $targetRel
    if (!(Test-Path $target)) {
  Write-Host "[SKIP] TARGET not found → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("target-not-found: "+$targetRel) } catch {}
  continue
}

    $orig = Get-Content -LiteralPath $target -Raw -Encoding UTF8
    $rxOpts = [Text.RegularExpressions.RegexOptions]::Multiline -bor [Text.RegularExpressions.RegexOptions]::Singleline
    $rx = [regex]::new($find, $rxOpts)
    $mt = $rx.Match($orig)
    if (-not $mt.Success) {
  Write-Host "[SKIP] FIND not matched → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("find-not-matched: "+$targetRel) } catch {}
  continue
}

    switch ($mode) {
      'insert-before' {
        $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
      }
      'insert-before' {
  $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
}
'insert-after' {
  $new = $orig.Substring(0, $mt.Index + $mt.Length) + "`n" + $replace + $orig.Substring($mt.Index + $mt.Length)
}
'replace' {
        $new = $rx.Replace($orig, $replace, 1)
      }
      default {
  Write-Host "[SKIP] Unsupported MODE → $mode for $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("unsupported-mode: "+$mode+" for "+$targetRel) } catch {}
  continue
}
    }

    if ($ConfirmApply) {
      $bk = "$target.bak-" + (Get-Date -Format 'yyyyMMdd-HHmmss')
      Copy-Item -LiteralPath $target -Destination $bk -Force
      Write-AtomicUtf8 -Path $target -Content $new -Module 'patcher' -Action ('apply:'+ $mode)
      $applied += $targetRel
    } else {
      Write-Host "[PREVIEW] would patch → $targetRel ($mode)"
    }
  }

  if ($ConfirmApply) {
    LogRec 'INFO' 'apply' 'SUCCESS' ("patched: " + ($applied -join ', '))
  } else {
    LogRec 'INFO' 'preview' 'SUCCESS' ("preview-ok (no writes). blocks="+$matches.Count)
  }

  # ── Gate-3 Verify (경량) ───────────────────────────────────────────────────────
  if ($ConfirmApply) {
    # 핵심 타겟의 구문 일치 재검
    $core = Join-Path $RepoRoot 'scripts\apply_ui_patch.ps1'
    if (Test-Path $core) {
      $c = Get-Content -LiteralPath $core -Raw -Encoding UTF8
      if ($c -notmatch 'ensure valid tmp path .* atomic friendly') {
        Write-Host "[WARN] VERIFY: guard snippet not found in apply_ui_patch.ps1"; try { LogRec "WARN" "verify" "SKIPPED" "guard-missing apply_ui_patch.ps1" } catch {}
      }
    }
  }
}
catch {
  LogRec 'ERROR' 'apply' 'FAILURE' $_.Exception.Message 'LOGIC'
  exit 0
}
finally {
  Remove-Item -Force $LockFile -ErrorAction SilentlyContinue
}
.Exception.Message)" }
  # 스모크: 같은 볼륨에 원자 쓰기 → 즉시 삭제
  $smoke = Join-Path $RepoRoot 'webui\public\_klc-smoke.txt'
  $smokeContent = "[klc-smoke] $(Get-Date -Format o)"
  Write-AtomicUtf8 -Path $smoke -Content $smokeContent -Module 'patcher' -Action 'smoke'
  if (Test-Path $smoke) { Remove-Item -LiteralPath $smoke -Force -ErrorAction SilentlyContinue }

  # ── Patch 파일 파싱 ───────────────────────────────────────────────────────────
  $PatchFile = Join-Path $RepoRoot '.kobong\patches.pending.txt'
  if (!(Test-Path $PatchFile)) {
  Write-Host "[SKIP] patches file not found → $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("patches-file-missing: "+$PatchFile) } catch {}
  return
}
  $patchText = Get-Content -LiteralPath $PatchFile -Raw -Encoding UTF8
  $global:patchHash = (Get-FileHash -Algorithm SHA256 -InputStream ([IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes($patchText)))).Hash

  $matches = [regex]::Matches($patchText, '(?ms)#\s*PATCH\s*START\s*(?<body>.*?)#\s*PATCH\s*END')
  if ($matches.Count -eq 0) {
  Write-Host "[SKIP] No PATCH blocks found in $PatchFile"
  try { LogRec "INFO" "apply" "SUCCESS" ("no-patch-blocks: "+$PatchFile) } catch {}
  return
}

  $applied = @()
  foreach ($m in $matches) {
    $body = $m.Groups['body'].Value

    $targetRel = [regex]::Match($body, 'TARGET:\s*(?<v>.+)').Groups['v'].Value.Trim()
    $mode      = [regex]::Match($body, 'MODE:\s*(?<v>.+)').Groups['v'].Value.Trim()
$__tr = (Get-Variable -Name targetRel -ValueOnly -ErrorAction SilentlyContinue)
if ($__tr -is [string] -and ($__tr -match '^(?i)scripts\\lib\\kobong-fileio\.psm1$')) {
  Write-Host "[SKIP] blocked target → $__tr"
  try { LogRec "WARN" "patch" "SKIPPED" ("blocked-target: " + $__tr) } catch {}
  continue
}.ToLowerInvariant()
    $find      = [regex]::Match($body, "FIND\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value
    $replace   = [regex]::Match($body, "REPLACE\s*<<'EOF'\r?\n(?<v>.*?)(?:\r?\n)EOF", 'Singleline').Groups['v'].Value

    if (-not $targetRel) { throw "PATCH missing TARGET" }
    if (-not $mode)      { throw "PATCH missing MODE" }
    if (-not $find)      { throw "PATCH missing FIND" }

    $target = Join-Path $RepoRoot $targetRel
    if (!(Test-Path $target)) {
  Write-Host "[SKIP] TARGET not found → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("target-not-found: "+$targetRel) } catch {}
  continue
}

    $orig = Get-Content -LiteralPath $target -Raw -Encoding UTF8
    $rxOpts = [Text.RegularExpressions.RegexOptions]::Multiline -bor [Text.RegularExpressions.RegexOptions]::Singleline
    $rx = [regex]::new($find, $rxOpts)
    $mt = $rx.Match($orig)
    if (-not $mt.Success) {
  Write-Host "[SKIP] FIND not matched → $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("find-not-matched: "+$targetRel) } catch {}
  continue
}

    switch ($mode) {
      'insert-before' {
        $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
      }
      'insert-before' {
  $new = $orig.Substring(0, $mt.Index) + $replace + "`n" + $orig.Substring($mt.Index)
}
'insert-after' {
  $new = $orig.Substring(0, $mt.Index + $mt.Length) + "`n" + $replace + $orig.Substring($mt.Index + $mt.Length)
}
'replace' {
        $new = $rx.Replace($orig, $replace, 1)
      }
      default {
  Write-Host "[SKIP] Unsupported MODE → $mode for $targetRel"
  try { LogRec "WARN" "patch" "SKIPPED" ("unsupported-mode: "+$mode+" for "+$targetRel) } catch {}
  continue
}
    }

    if ($ConfirmApply) {
      $bk = "$target.bak-" + (Get-Date -Format 'yyyyMMdd-HHmmss')
      Copy-Item -LiteralPath $target -Destination $bk -Force
      Write-AtomicUtf8 -Path $target -Content $new -Module 'patcher' -Action ('apply:'+ $mode)
      $applied += $targetRel
    } else {
      Write-Host "[PREVIEW] would patch → $targetRel ($mode)"
    }
  }

  if ($ConfirmApply) {
    LogRec 'INFO' 'apply' 'SUCCESS' ("patched: " + ($applied -join ', '))
  } else {
    LogRec 'INFO' 'preview' 'SUCCESS' ("preview-ok (no writes). blocks="+$matches.Count)
  }

  # ── Gate-3 Verify (경량) ───────────────────────────────────────────────────────
  if ($ConfirmApply) {
    # 핵심 타겟의 구문 일치 재검
    $core = Join-Path $RepoRoot 'scripts\apply_ui_patch.ps1'
    if (Test-Path $core) {
      $c = Get-Content -LiteralPath $core -Raw -Encoding UTF8
      if ($c -notmatch 'ensure valid tmp path .* atomic friendly') {
        Write-Host "[WARN] VERIFY: guard snippet not found in apply_ui_patch.ps1"; try { LogRec "WARN" "verify" "SKIPPED" "guard-missing apply_ui_patch.ps1" } catch {}
      }
    }
  }
}
catch {
  LogRec 'ERROR' 'apply' 'FAILURE' $_.Exception.Message 'LOGIC'
  exit 0
}
finally {
  Remove-Item -Force $LockFile -ErrorAction SilentlyContinue
}
