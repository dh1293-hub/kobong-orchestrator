#requires -Version 7.0
<#
  scripts/g5/apply-patches.ps1 — v1.0 (URS·센티넬 멱등)
  목적: “패치 블록(# PATCH START/END)”을 기반으로 **부분 패치**를 DRYRUN→APPLY 2단계로 적용.

  표준 규칙:
    - PS7 전용, StrictMode, UTF-8(LF), `$ErrorActionPreference='Stop'`
    - URS: Apply 전 `.bak-<ts>` 스냅샷 → 임시파일에 기록 후 원자 교체
    - 멱등: **센티넬(KOBO-SENTINEL:xyz)**이 이미 존재하면 멱등 SKIP
    - KLC 로그(JSONL): `logs/apply-log.jsonl`에 traceId/durationMs/exitCode/anchorHash
    - 표준 종료코드(SSOT): 0=OK, 10=SKIP, 11=DRYRUN, 12=PRECONDITION, 13=CONFLICT, 1=ERROR

  사용 예시:
    DRYRUN: pwsh -File scripts/g5/apply-patches.ps1 -Root "D:\\ChatGPT5_AI_Link\\dosc\\Kobong-Orchestrator-VIP" -Patch ".\\patches\\ghmon.patch"
    APPLY : pwsh -File scripts/g5/apply-patches.ps1 -Root "..." -Patch ".\\patches\\ghmon.patch" -ConfirmApply

  패치 블록 예시:
    # PATCH START
    TARGET: GitHub-Monitoring/webui/GitHub-Monitoring-Min.html
    MODE: insert-before
    MULTI: false
    FIND <<'EOF'
    </body>
    EOF
    REPLACE <<'EOF'
    <!-- KOBO-SENTINEL:ghmon-boot-v1 -->
    <script>window.GHMON={API_BASE:'http://localhost:5182/api/ghmon',MODE:'DEV'};</script>
    <script src="/GitHub-Monitoring/webui/GitHub-Mon-bridge.js" defer></script>
    EOF
    # PATCH END
#>

param(
  [Parameter(Mandatory=$false)]
  [string]$Root = (Get-Location).Path,

  [Parameter(Mandatory=$false)]
  [string[]]$Patch,

  [switch]$FromStdin,
  [switch]$ConfirmApply
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function New-TraceId { (New-Guid).ToString('N').Substring(0,12) }
function Get-NowIso  { (Get-Date).ToUniversalTime().ToString('o') }
function Get-Sha256([string]$s){
  $sha = [System.Security.Cryptography.SHA256]::Create()
  $bytes = [System.Text.Encoding]::UTF8.GetBytes($s)
  ($sha.ComputeHash($bytes) | ForEach-Object { $_.ToString('x2') }) -join ''
}

$Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
$traceId = New-TraceId
$logDir  = Join-Path $Root 'logs'
$logPath = Join-Path $logDir 'apply-log.jsonl'
if(!(Test-Path $logDir)){ New-Item -ItemType Directory -Force -Path $logDir | Out-Null }

function Write-KlcLog([int]$exit,[hashtable]$meta){
  $rec = [ordered]@{
    ts         = Get-NowIso
    traceId    = $traceId
    durationMs = [int]$Stopwatch.Elapsed.TotalMilliseconds
    exitCode   = $exit
    anchorHash = Get-Sha256(($meta.targetPath ?? '') + '|' + ($meta.mode ?? '') + '|' + ($meta.sentinel ?? ''))
    meta       = $meta
  } | ConvertTo-Json -Compress -Depth 5
  Add-Content -Path $logPath -Value $rec
}

function Read-Text([string]$path){ Get-Content -Raw -LiteralPath $path -Encoding UTF8 }
function Write-TextAtomic([string]$path,[string]$content){
  $tmp = "$path.tmp"
  $content | Set-Content -LiteralPath $tmp -Encoding UTF8 -NoNewline
  Move-Item -LiteralPath $tmp -Destination $path -Force
}

function Backup-File([string]$path){
  $ts = (Get-Date).ToString('yyyyMMdd-HHmmss')
  $bak = "$path.bak-$ts"
  Copy-Item -LiteralPath $path -Destination $bak -Force
  return $bak
}

function Parse-PatchText([string]$text){
  $lines = $text -split "`r?`n"
  $out = @()
  $i = 0
  while($i -lt $lines.Length){
    if($lines[$i] -match '^\s*#\s*PATCH\s+START'){
      $obj = @{}
      $i++
      while($i -lt $lines.Length -and ($lines[$i] -notmatch '^\s*#\s*PATCH\s+END')){
        $line = $lines[$i]
        if($line -match '^\s*([A-Z_]+):\s*(.+)$'){
          $k=$Matches[1]; $v=$Matches[2]
          if($v -match "<<'EOF'"){
            # heredoc capture
            $buf = @()
            $i++
            while($i -lt $lines.Length -and ($lines[$i] -ne 'EOF')){ $buf += $lines[$i]; $i++ }
            $obj[$k] = ($buf -join "`n")
          } else { $obj[$k] = $v }
        }
        $i++
      }
      $out += $obj
    } else { $i++ }
  }
  return $out
}

# 1) 패치 소스 수집
$patchTexts = @()
if($FromStdin){ $patchTexts += [Console]::In.ReadToEnd() }
if($Patch){ foreach($p in $Patch){ $patchTexts += (Read-Text (Resolve-Path $p)) } }
if(-not $FromStdin -and -not $Patch){
  $defaultDir1 = Join-Path $Root 'patches'
  if(Test-Path $defaultDir1){
    Get-ChildItem $defaultDir1 -File -Recurse -Include *.patch,*.g5.patch,*.patch.txt | ForEach-Object {
      $patchTexts += (Read-Text $_.FullName)
    }
  }
}
if($patchTexts.Count -eq 0){
  Write-Error '패치 소스를 찾을 수 없습니다. -Patch 파일을 지정하거나 -FromStdin 를 사용하세요.'
}

$patches = @()
foreach($txt in $patchTexts){ $patches += Parse-PatchText $txt }
if($patches.Count -eq 0){ Write-Error '유효한 # PATCH START/END 블록이 없습니다.' }

# 2) 실행
$applied = 0; $skipped = 0; $preconds = 0; $conflicts = 0

foreach($p in $patches){
  $targetRel = $p.TARGET; if(-not $targetRel){ $preconds++; Write-KlcLog 12 @{ reason='NO_TARGET'; patch=$p }; continue }
  $mode = ($p.MODE ?? 'replace').ToLower()
  $multi = [System.Convert]::ToBoolean(($p.MULTI ?? 'false'))
  $find = $p.FIND; $repl = $p.REPLACE
  $targetPath = Join-Path $Root $targetRel
  if(-not (Test-Path $targetPath)){ $preconds++; Write-KlcLog 12 @{ reason='TARGET_NOT_FOUND'; targetPath=$targetPath; patch=$p }; continue }

  $src = Read-Text $targetPath
  $sentinel = $null
  if($repl -and $repl -match 'KOBO-SENTINEL:[^\s>]+' ){ $sentinel = $Matches[0] }

  if($sentinel -and ($src -match [Regex]::Escape($sentinel)) -and -not $multi){
    $skipped++; Write-KlcLog 10 @{ result='SKIP_SENTINEL'; targetPath=$targetPath; mode=$mode; sentinel=$sentinel }; continue
  }

  $new = $null
  switch($mode){
    'insert-after' {
      if(-not $find){ $preconds++; Write-KlcLog 12 @{ reason='MISSING_FIND'; targetPath=$targetPath; mode=$mode }; break }
      $m = [Regex]::Match($src, $find, [System.Text.RegularExpressions.RegexOptions]::Singleline)
      if(-not $m.Success){ $preconds++; Write-KlcLog 12 @{ reason='FIND_NOT_MATCH'; targetPath=$targetPath; mode=$mode }; break }
      $new = $src.Substring(0,$m.Index+$m.Length) + "`n" + ($repl ?? '') + $src.Substring($m.Index+$m.Length)
    }
    'insert-before' {
      if(-not $find){ $preconds++; Write-KlcLog 12 @{ reason='MISSING_FIND'; targetPath=$targetPath; mode=$mode }; break }
      $m = [Regex]::Match($src, $find, [System.Text.RegularExpressions.RegexOptions]::Singleline)
      if(-not $m.Success){ $preconds++; Write-KlcLog 12 @{ reason='FIND_NOT_MATCH'; targetPath=$targetPath; mode=$mode }; break }
      $new = $src.Substring(0,$m.Index) + ($repl ?? '') + "`n" + $src.Substring($m.Index)
    }
    'replace' {
      if(-not $find){ $preconds++; Write-KlcLog 12 @{ reason='MISSING_FIND'; targetPath=$targetPath; mode=$mode }; break }
      if($multi){ $new = [Regex]::Replace($src, $find, ($repl ?? ''), [System.Text.RegularExpressions.RegexOptions]::Singleline) }
      else {
        $m = [Regex]::Match($src, $find, [System.Text.RegularExpressions.RegexOptions]::Singleline)
        if(-not $m.Success){ $preconds++; Write-KlcLog 12 @{ reason='FIND_NOT_MATCH'; targetPath=$targetPath; mode=$mode }; break }
        $new = $src.Substring(0,$m.Index) + ($repl ?? '') + $src.Substring($m.Index+$m.Length)
      }
    }
    'append' { $new = $src + "`n" + ($repl ?? '') }
    Default { $preconds++; Write-KlcLog 12 @{ reason='BAD_MODE'; targetPath=$targetPath; mode=$mode }; }
  }

  if($null -eq $new){ continue }
  if($new -eq $src){ $skipped++; Write-KlcLog 10 @{ result='SKIP_NOCHANGE'; targetPath=$targetPath; mode=$mode; sentinel=$sentinel }; continue }

  if($ConfirmApply){
    $bak = Backup-File $targetPath
    try { Write-TextAtomic $targetPath $new } catch { $conflicts++; Write-KlcLog 13 @{ result='CONFLICT_WRITE'; targetPath=$targetPath; bak=$bak; error=$_.Exception.Message }; continue }
    $applied++
    Write-KlcLog 0 @{ result='APPLIED'; targetPath=$targetPath; mode=$mode; bak=$bak; sentinel=$sentinel }
  }
  else {
    # DRYRUN: 변경 미리보기(앞부분 240자)
    $deltaHead = ($new.Substring(0,[Math]::Min($new.Length,240)))
    Write-KlcLog 11 @{ result='DRYRUN'; targetPath=$targetPath; mode=$mode; preview=$deltaHead; sentinel=$sentinel }
  }
}

$Stopwatch.Stop()

if($ConfirmApply){
  if($applied -gt 0 -and $conflicts -eq 0 -and $preconds -eq 0){ exit 0 }
  elseif($applied -eq 0 -and $skipped -gt 0 -and $conflicts -eq 0 -and $preconds -eq 0){ exit 10 }
  elseif($preconds -gt 0){ exit 12 }
  elseif($conflicts -gt 0){ exit 13 }
  else { exit 1 }
}
else {
  # DRYRUN
  if($preconds -gt 0){ exit 12 }
  elseif($conflicts -gt 0){ exit 13 }
  else { exit 11 }
}
