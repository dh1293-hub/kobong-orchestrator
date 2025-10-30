#requires -Version 7.0
<#
  파일: scripts/g5/apply-patches.ps1
  목적(WHAT)
    - 리포지토리 워크스페이스에 "패치 매니페스트(JSON)"를 적용합니다.
    - DRYRUN(계획)과 APPLY(적용)를 지원하고, KLC/JSONL 로그를 남깁니다.

  산출물(OUTPUTS)
    - 텍스트 로그:   .ak-out.txt    (요약)
    - JSONL 로그:    logs/ak7.jsonl (한 줄 한 개 JSON 이벤트)

  연관 파일(RELATED)
    - .github/workflows/ak-apply.yml        # 이 스크립트를 DryRun→Apply로 호출
    - patches/manifest.json                 # 패치 정의(아래 스키마)
    - ROLLBACK_POLICY*.md, PowerShell7_Guidelines_Kobong_v1.1.md

  매니페스트 스키마(SCHEMA v1)
    {
      "version": 1,
      "operations": [
        { "op": "replace", "path": "README.md", "find": "old", "with": "new", "all": false },
        { "op": "ensureLine", "path": "README.md", "line": "# Title" },
        { "op": "insertAfter", "path": "a.txt", "anchor": "LINE", "with": "NEW LINE" },
        { "op": "copy", "from": "templates/x.yml", "to": ".github/workflows/x.yml", "mode":"overwrite" },
        { "op": "delete", "path": "obsolete.txt" }
      ]
    }

  사용법(USAGE)
    - DryRun: pwsh -NoProfile -File scripts/g5/apply-patches.ps1 -DryRun `
                -Manifest patches/manifest.json -OutText .ak-out.txt -OutJson logs/ak7.jsonl
    - Apply : pwsh -NoProfile -File scripts/g5/apply-patches.ps1 `
                -Manifest patches/manifest.json -OutText .ak-out.txt -OutJson logs/ak7.jsonl

  테스트(TEST)
    - GitHub Actions: ak-apply.yml에서 Plan→Apply 순서로 확인
    - 로컬: 변경 전 워크스페이스 백업 후 같은 명령 실행(권장: actionlint로 정적검사 병행)

  안전 가드(SAFETY)
    - .gpt5.lock 파일로 동시 실행 차단(Apply에서만 잠금)
    - 모든 파일 쓰기는 temp→Move(원자적 교체), 기존은 .bak 보관
    - git 미사용 경로도 동작(로컬/CI 공통) — zip-fetch 기반 전개 정책과 양립
    - 실패 시에도 로그 파일이 반드시 생성되도록 보장

  종료코드(EXIT CODES)
    - 0: 적용 성공(변경 1개 이상)
    - 10: 적용할 변경 없음(SKIP)
    - 11: DryRun 완료
    - 12: 사전조건 위반(매니페스트 없음 등)
    - 1 : 기타 오류
#>

[CmdletBinding()]
param(
  [switch]$DryRun,
  [string]$Manifest = "patches/manifest.json",
  [string]$Root = (Get-Location).Path,
  [string]$OutText = ".ak-out.txt",
  [string]$OutJson = "logs/ak7.jsonl",
  [switch]$Quiet,
  [switch]$Trace
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)

# ===== 공통 유틸 =====
function New-Dir([string]$p){ $d = Split-Path -Parent $p; if ($d) { New-Item -ItemType Directory -Force -Path $d | Out-Null } }
function Write-Text([string]$s){ if(-not $Quiet){ Write-Host $s } $s | Out-File -FilePath $OutText -Append -Encoding utf8 }
function To-Rel([string]$abs){
  $root = [System.IO.Path]::GetFullPath($Root)
  $absf = [System.IO.Path]::GetFullPath($abs)
  if (-not $absf.StartsWith($root, [StringComparison]::OrdinalIgnoreCase)) { return $abs }
  return $absf.Substring($root.Length).TrimStart('\','/').Replace('\','/')
}
function SafeJoin([string]$base, [string]$rel){
  if ($rel -match '^\s*[./\\]*\.\.[/\\]') { throw "Path escapes root: $rel" }
  $full = [System.IO.Path]::GetFullPath((Join-Path $base $rel))
  $root = [System.IO.Path]::GetFullPath($base)
  if (-not $full.StartsWith($root, [StringComparison]::OrdinalIgnoreCase)) { throw "Path escapes root: $rel" }
  return $full
}

# JSONL 로그(중괄호 서식 충돌 방지: 객체→ConvertTo-Json)
function Write-JsonLog {
  param(
    [string]$Event,
    [string]$Message,
    [int]$ExitCode = 0,
    [hashtable]$Data
  )
  $obj = [pscustomobject]@{
    ts       = (Get-Date -AsUtc -Format o)
    event    = $Event
    message  = $Message
    exitCode = $ExitCode
    data     = $Data
  }
  $line = $obj | ConvertTo-Json -Compress
  New-Dir $OutJson
  $line | Out-File -FilePath $OutJson -Append -Encoding utf8
  if(-not $Quiet){ Write-Host $line }
}

# 파일 쓰기(원자적 교체 + .bak 백업)
function Set-FileAtomic {
  param([string]$Path, [string]$Content)
  New-Dir $Path
  $tmp = "$Path.tmp.$$"
  $bak = "$Path.bak"
  Set-Content -Path $tmp -Value $Content -Encoding utf8
  if (Test-Path -LiteralPath $Path) {
    Move-Item -Force -Path $Path -Destination $bak
  }
  Move-Item -Force -Path $tmp -Destination $Path
}

# ===== 패치 엔진(간단·고성능) =====
function Apply-Replace {
  param([string]$file, [string]$find, [string]$with, [bool]$all = $false, [switch]$dry)
  $src = Get-Content -Raw -Encoding UTF8 -LiteralPath $file
  if ([string]::IsNullOrEmpty($src)) { $src = "" }
  if ($src.Contains($with)) { return @{ changed = $false; reason = 'already-present' } }
  if (-not $src.Contains($find)) { return @{ changed = $false; reason = 'anchor-missing' } }

  $new = if ($all) { $src.Replace($find, $with) } else { $src -replace [regex]::Escape($find), [System.Text.RegularExpressions.MatchEvaluator]{ param($m) if ($script:__done){ $m.Value } else { $script:__done=$true; $with } } }
  if ($dry) { return @{ changed = ($new -ne $src); preview=$true } }
  Set-FileAtomic -Path $file -Content $new
  return @{ changed = $true }
}

function Apply-EnsureLine {
  param([string]$file, [string]$line, [switch]$dry)
  $text = Test-Path $file ? (Get-Content -Raw -Encoding UTF8 -LiteralPath $file) : ""
  $norm = ($text -split "`r?`n")
  if ($norm -contains $line) { return @{ changed = $false; reason='exists' } }
  $new = ($norm + $line) -join "`n"
  if ($dry) { return @{ changed = $true; preview=$true } }
  Set-FileAtomic -Path $file -Content $new
  return @{ changed = $true }
}

function Apply-InsertAfter {
  param([string]$file, [string]$anchor, [string]$with, [switch]$dry)
  if (-not (Test-Path $file)) { return @{ changed=$false; reason='file-missing' } }
  $text = Get-Content -Raw -Encoding UTF8 -LiteralPath $file
  $lines = $text -split "`r?`n"
  $idx = [array]::IndexOf($lines, $anchor)
  if ($idx -lt 0) { return @{ changed=$false; reason='anchor-missing' } }
  if ($idx -lt $lines.Length-1 -and $lines[$idx+1] -eq $with) { return @{ changed=$false; reason='next-exists' } }
  $new = @()
  $new += $lines[0..$idx]
  $new += $with
  if ($idx -lt $lines.Length-1) { $new += $lines[($idx+1)..($lines.Length-1)] }
  $content = $new -join "`n"
  if ($dry) { return @{ changed=$true; preview=$true } }
  Set-FileAtomic -Path $file -Content $content
  return @{ changed=$true }
}

function Apply-Copy {
  param([string]$from, [string]$to, [ValidateSet('overwrite','ifMissing','create')][string]$mode='ifMissing', [switch]$dry)
  if (-not (Test-Path -LiteralPath $from)) { return @{ changed=$false; reason='source-missing' } }
  $need = $true
  if (Test-Path -LiteralPath $to) {
    if ($mode -eq 'ifMissing' -or $mode -eq 'create') { $need = $false }
  }
  if (-not $need) { return @{ changed=$false; reason='skip-exists' } }
  if ($dry) { return @{ changed=$true; preview=$true } }
  New-Dir $to
  Copy-Item -Force -LiteralPath $from -Destination $to
  return @{ changed=$true }
}

function Apply-Delete {
  param([string]$path, [switch]$dry)
  if (-not (Test-Path -LiteralPath $path)) { return @{ changed=$false; reason='missing' } }
  if ($dry) { return @{ changed=$true; preview=$true } }
  Remove-Item -Force -LiteralPath $path
  return @{ changed=$true }
}

# ===== 실행 준비 =====
New-Dir $OutText; New-Dir $OutJson | Out-Null
Write-Text "== apply-patches.ps1 start (DryRun=$($DryRun.IsPresent)) =="
Write-JsonLog -Event 'ak-start' -Message 'begin' -ExitCode 0 -Data @{ dry = $DryRun.IsPresent }

if (-not (Test-Path -LiteralPath (SafeJoin $Root $Manifest))) {
  $msg = "Manifest not found: $Manifest"
  Write-Text $msg
  Write-JsonLog -Event 'ak-error' -Message $msg -ExitCode 12
  if ($DryRun) { exit 11 } else { exit 12 }
}

$mfPath = SafeJoin $Root $Manifest
$mf = Get-Content -Raw -Encoding UTF8 -LiteralPath $mfPath | ConvertFrom-Json
if ($mf.version -ne 1) {
  $msg = "Unsupported manifest version: $($mf.version)"
  Write-Text $msg
  Write-JsonLog -Event 'ak-error' -Message $msg -ExitCode 12
  if ($DryRun) { exit 11 } else { exit 12 }
}
$ops = @($mf.operations)
if ($ops.Count -eq 0) {
  Write-Text "No operations in manifest."
  Write-JsonLog -Event 'ak-done' -Message 'no-op' -ExitCode 10 -Data @{ changed = 0 }
  if ($DryRun) { exit 11 } else { exit 10 }
}

# Apply 모드: 락 파일로 동시 실행 차단
$lockFile = Join-Path $Root ".gpt5.lock"
$lock = $null
if (-not $DryRun) {
  try {
    $lock = [System.IO.File]::Open($lockFile, [System.IO.FileMode]::OpenOrCreate, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
  } catch {
    $msg = "Another apply is running (lock busy): $lockFile"
    Write-Text $msg
    Write-JsonLog -Event 'ak-error' -Message $msg -ExitCode 13
    exit 13
  }
}

# ===== 실행 =====
$changed = 0
$preview = @()

foreach ($op in $ops) {
  $kind = $op.op
  switch ($kind) {
    'replace' {
      $dst = SafeJoin $Root $op.path
      $r = Apply-Replace -file $dst -find $op.find -with $op.with -all:([bool]$op.all) -dry:$DryRun
    }
    'ensureLine' {
      $dst = SafeJoin $Root $op.path
      $r = Apply-EnsureLine -file $dst -line $op.line -dry:$DryRun
    }
    'insertAfter' {
      $dst = SafeJoin $Root $op.path
      $r = Apply-InsertAfter -file $dst -anchor $op.anchor -with $op.with -dry:$DryRun
    }
    'copy' {
      $src = SafeJoin $Root $op.from
      $dst = SafeJoin $Root $op.to
      $mode = if ($op.mode) { $op.mode } else { 'ifMissing' }
      $r = Apply-Copy -from $src -to $dst -mode $mode -dry:$DryRun
    }
    'delete' {
      $dst = SafeJoin $Root $op.path
      $r = Apply-Delete -path $dst -dry:$DryRun
    }
    default {
      $r = @{ changed = $false; reason = "unknown-op:$kind" }
    }
  }

  if ($DryRun -and $r.preview) {
    $preview += [pscustomobject]@{ op=$kind; path=($op.path ?? $op.to ?? $op.from); result='would-change' }
  }
  if ($r.changed) { $changed++ }

  if ($Trace) {
    Write-JsonLog -Event 'ak-op' -Message $kind -ExitCode 0 -Data @{ op = $op; result = $r }
  }
}

if ($null -ne $lock) { $lock.Dispose() }

$mode = $DryRun ? 'DryRun' : 'Apply'
Write-Text ("== {0} completed: {1} change(s)" -f $mode, $changed)
Write-JsonLog -Event 'ak-done' -Message 'ok' -ExitCode 0 -Data @{ mode=$mode; changed=$changed; preview=$preview }

if ($DryRun) { exit 11 }
elseif ($changed -gt 0) { exit 0 }
else { exit 10 }
