
# APPLY IN SHELL
#requires -PSEdition Core
#requires -Version 7.0
param(
  [switch]$Init,
  [switch]$ConfirmApply,
  [string]$Root
)

Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

# --- KLC 로그 (v1.2 규격; kobong_logger_cli 우선, JSONL 폴백) ---------------
function Write-KLC {
  param(
    [ValidateSet('INFO','WARN','ERROR','DEBUG')]$Level='INFO',
    [ValidateSet('SUCCESS','FAILURE','DRYRUN')]$Outcome='DRYRUN',
    [string]$Action='fixloop-apply',
    [string]$ErrorCode='',
    [string]$Message='',
    [int]$DurationMs=0
  )
  try {
    if (Get-Command kobong_logger_cli -ErrorAction SilentlyContinue) {
      & kobong_logger_cli log --level $Level --module 'scripts' --action $Action `
        --outcome $Outcome --error $ErrorCode --message $Message --duration-ms $DurationMs 2>$null
      return
    }
  } catch {}
  $root = (git rev-parse --show-toplevel 2>$null); if (-not $root) { $root=(Get-Location).Path }
  $log = Join-Path $root 'logs/apply-log.jsonl'
  New-Item -ItemType Directory -Force -Path (Split-Path $log) | Out-Null
  $rec = @{
    timestamp=(Get-Date).ToString('o'); level=$Level; traceId=[guid]::NewGuid().ToString();
    module='scripts'; action=$Action; outcome=$Outcome; errorCode=$ErrorCode; message=$Message; durationMs=$DurationMs
  } | ConvertTo-Json -Compress
  Add-Content -Path $log -Value $rec
}
# ---------------------------------------------------------------------------

function Get-RepoRoot {
  param([string]$Hint)
  if ($Hint) { return (Resolve-Path -LiteralPath $Hint).Path }
  try { $r = (git rev-parse --show-toplevel 2>$null) } catch { $r = $null }
  if (-not $r) { $r = (Get-Location).Path }
  return $r
}

function Ensure-RollbackManifest {
  param([string]$RepoRoot)
  $rb = Join-Path $RepoRoot 'Rollbackfile.json'
  $obj = if (Test-Path $rb) { Get-Content -Raw -LiteralPath $rb | ConvertFrom-Json } else { [pscustomobject]@{ version=1; targets=@(); retention=@{bak=30;goodSlots=10;redo=3;undo=3}} }
  $need = @('.kobong/patches.pending.txt','scripts/g5/apply-patches.ps1')
  foreach($t in $need) { if (-not ($obj.targets -contains $t)) { $obj.targets += $t } }
  $obj | ConvertTo-Json -Depth 6 | Out-File -LiteralPath $rb -Encoding utf8
}

function New-PatchesFile {
  param([string]$Path)
  if (Test-Path $Path) { return }
  New-Item -ItemType Directory -Force -Path (Split-Path $Path) | Out-Null
  @"
# NO-SHELL
# FixLoop patches — put your PATCH blocks below. See FixLoop Runbook.
# Example:
# PATCH START/END delimit a block. MODE: regex-replace|plain-replace|insert-before|insert-after

# PATCH START
TARGET: README.md
MODE: insert-after
MULTI: false
FIND <<'EOF'
^#\s+.*
EOF
REPLACE <<'EOF'
  
> Updated by FixLoop at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
EOF
# PATCH END
"@ | Out-File -LiteralPath $Path -Encoding utf8
}

# --- PATCH 파서 -------------------------------------------------------------
function Parse-PatchBlocks {
  param([string]$Text)
  $blocks = @()
  $rxBlock = [regex]'(?ms)#\s*PATCH\s+START.*?TARGET:\s*(?<target>.+?)\s*?\r?\n.*?MODE:\s*(?<mode>.+?)\s*?\r?\n(?:(?:MULTI:\s*(?<multi>true|false)).*?\r?\n)?(?:.*?FIND\s*<<''EOF''\r?\n(?<find>.*?)[\r\n]+EOF\s*\r?\n)(?:.*?REPLACE\s*<<''EOF''\r?\n(?<replace>.*?)[\r\n]+EOF\s*\r?\n)?(?:.*?#\s*PATCH\s+END)'
  $m = $rxBlock.Matches($Text)
  foreach($x in $m){
    $blocks += [pscustomobject]@{
      Target = $x.Groups['target'].Value.Trim()
      Mode = $x.Groups['mode'].Value.Trim().ToLower()
      Multi = [bool]::Parse(($x.Groups['multi'].Value.Trim() ?? 'false'))
      Find  = $x.Groups['find'].Value
      Replace = $x.Groups['replace'].Value
    }
  }
  return $blocks
}

# --- 파일 백업(URS 규정: .bak + 원자 교체) -----------------------------------
function Backup-And-WriteFile {
  param([string]$Path, [string]$Content)
  $dir = Split-Path -Parent $Path
  New-Item -ItemType Directory -Force -Path $dir | Out-Null
  $ts = Get-Date -Format 'yyyyMMdd-HHmmss'
  $bak = "$Path.bak-$ts"
  if (Test-Path $Path) { Copy-Item -LiteralPath $Path -Destination $bak -Force }
  $tmp = "$Path.tmp"
  $Content | Out-File -LiteralPath $tmp -Encoding utf8
  Move-Item -LiteralPath $tmp -Destination $Path -Force
  # 보관 개수 30개 유지(오래된 것 정리)
  $baks = Get-ChildItem -LiteralPath $dir -Filter ("{0}.bak-*" -f (Split-Path -Leaf $Path)) -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
  if ($baks.Count -gt 30) { $baks[30..($baks.Count-1)] | Remove-Item -Force }
  return $bak
}

# --- 패치 적용 엔진 ----------------------------------------------------------
function Plan-And-ApplyPatches {
  param([object[]]$Patches, [switch]$Apply, [string]$RepoRoot)

  # 대상 파일별 버퍼를 모아 원 샷 적용
  $buffers = @{}
  $plans = @()

  foreach($p in $Patches){
    $target = Join-Path $RepoRoot $p.Target
    if (-not (Test-Path $target)) { throw "PRECONDITION: Target not found: $($p.Target)" }
    if (-not $buffers.ContainsKey($target)) {
      $buffers[$target] = Get-Content -LiteralPath $target -Raw -Encoding UTF8
    }
    $text = $buffers[$target]
    $mode = $p.Mode
    $multi = [bool]$p.Multi
    $find = $p.Find
    $replace = $p.Replace

    $matchCount = 0
    $newText = $text

    switch ($mode) {
      'regex-replace' {
        $rx = [regex]::new($find, [System.Text.RegularExpressions.RegexOptions]'Multiline, Singleline')
        $matchCount = ($rx.Matches($text)).Count
        if ($matchCount -gt 0) {
          if ($multi) { $newText = $rx.Replace($text, $replace) }
          else { $newText = $rx.Replace($text, $replace, 1) }
        }
      }
      'plain-replace' {
        if ($multi) {
          $matchCount = ([regex]::Matches($text,[regex]::Escape($find))).Count
          if ($matchCount -gt 0) { $newText = $text.Replace($find,$replace) }
        } else {
          $idx = $text.IndexOf($find,[StringComparison]::Ordinal)
          if ($idx -ge 0) {
            $matchCount = 1
            $newText = $text.Substring(0,$idx) + $replace + $text.Substring($idx + $find.Length)
          }
        }
      }
      'insert-before' {
        $rx = [regex]::new($find, [System.Text.RegularExpressions.RegexOptions]'Multiline, Singleline')
        $m = $rx.Match($text)
        if ($m.Success) {
          $matchCount = 1
          $newText = $text.Substring(0,$m.Index) + $replace + $text.Substring($m.Index)
        }
      }
      'insert-after' {
        $rx = [regex]::new($find, [System.Text.RegularExpressions.RegexOptions]'Multiline, Singleline')
        $m = $rx.Match($text)
        if ($m.Success) {
          $matchCount = 1
          $newText = $text.Substring(0,$m.Index+$m.Length) + $replace + $text.Substring($m.Index+$m.Length)
        }
      }
      default { throw "PRECONDITION: Unknown MODE: $mode" }
    }

    $plans += [pscustomobject]@{
      File=$p.Target; Mode=$mode; Multi=$multi; Matches=$matchCount; WillChange=($matchCount -gt 0)
    }

    if ($matchCount -gt 0) { $buffers[$target] = $newText }
  }

  if (-not $Apply) {
    return @{ Plans=$plans; Applied=$false; ChangedFiles=@() }
  }

  $changed=@()
  foreach($kv in $buffers.GetEnumerator()){
    $target = $kv.Key; $content = $kv.Value
    $original = Get-Content -LiteralPath $target -Raw -Encoding UTF8
    if ($original -ne $content) {
      $bak = Backup-And-WriteFile -Path $target -Content $content
      $changed += [pscustomobject]@{File=$target; Backup=$bak}
    }
  }
  return @{ Plans=$plans; Applied=$true; ChangedFiles=$changed }
}

# --- 메인 --------------------------------------------------------------------
$sw=[System.Diagnostics.Stopwatch]::StartNew()
$repo = Get-RepoRoot -Hint $Root
$patchFile = Join-Path $repo '.kobong/patches.pending.txt'

# 락
$LockFile = Join-Path $repo '.gpt5.lock'
if (Test-Path $LockFile) { Write-KLC -Level ERROR -Outcome FAILURE -Action 'fixloop-apply' -ErrorCode 'CONFLICT' -Message '.gpt5.lock exists'; exit 11 }
"locked $(Get-Date -Format o)" | Out-File $LockFile -Encoding utf8 -NoNewline

try {
  if ($Init) {
    New-PatchesFile -Path $patchFile
    Ensure-RollbackManifest -RepoRoot $repo
    Write-Host "[Init] Created/verified $patchFile and Rollbackfile.json"
    Write-KLC -Outcome 'DRYRUN' -Action 'fixloop-init' -Message 'init done'
    exit 0
  }

  if (-not (Test-Path $patchFile)) { throw "PRECONDITION: patches file missing: .kobong/patches.pending.txt" }
  $raw = Get-Content -LiteralPath $patchFile -Raw -Encoding UTF8
  $patches = Parse-PatchBlocks -Text $raw
  if (-not $patches -or $patches.Count -eq 0) { throw "PRECONDITION: no PATCH blocks found" }

  $plan = Plan-And-ApplyPatches -Patches $patches -RepoRoot $repo -Apply:$ConfirmApply
  $table = $plan.Plans | Format-Table -AutoSize | Out-String
  Write-Host $table

  if (-not $ConfirmApply) {
    # 항상 배열로 만들어 Count 보장
    $files = @()
    if ($plan -and $plan.Plans) {
        $files = @($plan.Plans | ForEach-Object { 
# APPLY IN SHELL
#requires -Version 7.0
param(
  [switch]$Init,
  [switch]$ConfirmApply,
  [string]$Root
)

Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

# --- KLC 로그 (v1.2 규격; kobong_logger_cli 우선, JSONL 폴백) ---------------
function Write-KLC {
  param(
    [ValidateSet('INFO','WARN','ERROR','DEBUG')]$Level='INFO',
    [ValidateSet('SUCCESS','FAILURE','DRYRUN')]$Outcome='DRYRUN',
    [string]$Action='fixloop-apply',
    [string]$ErrorCode='',
    [string]$Message='',
    [int]$DurationMs=0
  )
  try {
    if (Get-Command kobong_logger_cli -ErrorAction SilentlyContinue) {
      & kobong_logger_cli log --level $Level --module 'scripts' --action $Action `
        --outcome $Outcome --error $ErrorCode --message $Message --duration-ms $DurationMs 2>$null
      return
    }
  } catch {}
  $root = (git rev-parse --show-toplevel 2>$null); if (-not $root) { $root=(Get-Location).Path }
  $log = Join-Path $root 'logs/apply-log.jsonl'
  New-Item -ItemType Directory -Force -Path (Split-Path $log) | Out-Null
  $rec = @{
    timestamp=(Get-Date).ToString('o'); level=$Level; traceId=[guid]::NewGuid().ToString();
    module='scripts'; action=$Action; outcome=$Outcome; errorCode=$ErrorCode; message=$Message; durationMs=$DurationMs
  } | ConvertTo-Json -Compress
  Add-Content -Path $log -Value $rec
}
# ---------------------------------------------------------------------------

function Get-RepoRoot {
  param([string]$Hint)
  if ($Hint) { return (Resolve-Path -LiteralPath $Hint).Path }
  try { $r = (git rev-parse --show-toplevel 2>$null) } catch { $r = $null }
  if (-not $r) { $r = (Get-Location).Path }
  return $r
}

function Ensure-RollbackManifest {
  param([string]$RepoRoot)
  $rb = Join-Path $RepoRoot 'Rollbackfile.json'
  $obj = if (Test-Path $rb) { Get-Content -Raw -LiteralPath $rb | ConvertFrom-Json } else { [pscustomobject]@{ version=1; targets=@(); retention=@{bak=30;goodSlots=10;redo=3;undo=3}} }
  $need = @('.kobong/patches.pending.txt','scripts/g5/apply-patches.ps1')
  foreach($t in $need) { if (-not ($obj.targets -contains $t)) { $obj.targets += $t } }
  $obj | ConvertTo-Json -Depth 6 | Out-File -LiteralPath $rb -Encoding utf8
}

function New-PatchesFile {
  param([string]$Path)
  if (Test-Path $Path) { return }
  New-Item -ItemType Directory -Force -Path (Split-Path $Path) | Out-Null
  @"
# NO-SHELL
# FixLoop patches — put your PATCH blocks below. See FixLoop Runbook.
# Example:
# PATCH START/END delimit a block. MODE: regex-replace|plain-replace|insert-before|insert-after

# PATCH START
TARGET: README.md
MODE: insert-after
MULTI: false
FIND <<'EOF'
^#\s+.*
EOF
REPLACE <<'EOF'
  
> Updated by FixLoop at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
EOF
# PATCH END
"@ | Out-File -LiteralPath $Path -Encoding utf8
}

# --- PATCH 파서 -------------------------------------------------------------
function Parse-PatchBlocks {
  param([string]$Text)
  $blocks = @()
  $rxBlock = [regex]'(?ms)#\s*PATCH\s+START.*?TARGET:\s*(?<target>.+?)\s*?\r?\n.*?MODE:\s*(?<mode>.+?)\s*?\r?\n(?:(?:MULTI:\s*(?<multi>true|false)).*?\r?\n)?(?:.*?FIND\s*<<''EOF''\r?\n(?<find>.*?)[\r\n]+EOF\s*\r?\n)(?:.*?REPLACE\s*<<''EOF''\r?\n(?<replace>.*?)[\r\n]+EOF\s*\r?\n)?(?:.*?#\s*PATCH\s+END)'
  $m = $rxBlock.Matches($Text)
  foreach($x in $m){
    $blocks += [pscustomobject]@{
      Target = $x.Groups['target'].Value.Trim()
      Mode = $x.Groups['mode'].Value.Trim().ToLower()
      Multi = [bool]::Parse(($x.Groups['multi'].Value.Trim() ?? 'false'))
      Find  = $x.Groups['find'].Value
      Replace = $x.Groups['replace'].Value
    }
  }
  return $blocks
}

# --- 파일 백업(URS 규정: .bak + 원자 교체) -----------------------------------
function Backup-And-WriteFile {
  param([string]$Path, [string]$Content)
  $dir = Split-Path -Parent $Path
  New-Item -ItemType Directory -Force -Path $dir | Out-Null
  $ts = Get-Date -Format 'yyyyMMdd-HHmmss'
  $bak = "$Path.bak-$ts"
  if (Test-Path $Path) { Copy-Item -LiteralPath $Path -Destination $bak -Force }
  $tmp = "$Path.tmp"
  $Content | Out-File -LiteralPath $tmp -Encoding utf8
  Move-Item -LiteralPath $tmp -Destination $Path -Force
  # 보관 개수 30개 유지(오래된 것 정리)
  $baks = Get-ChildItem -LiteralPath $dir -Filter ("{0}.bak-*" -f (Split-Path -Leaf $Path)) -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
  if ($baks.Count -gt 30) { $baks[30..($baks.Count-1)] | Remove-Item -Force }
  return $bak
}

# --- 패치 적용 엔진 ----------------------------------------------------------
function Plan-And-ApplyPatches {
  param([object[]]$Patches, [switch]$Apply, [string]$RepoRoot)

  # 대상 파일별 버퍼를 모아 원 샷 적용
  $buffers = @{}
  $plans = @()

  foreach($p in $Patches){
    $target = Join-Path $RepoRoot $p.Target
    if (-not (Test-Path $target)) { throw "PRECONDITION: Target not found: $($p.Target)" }
    if (-not $buffers.ContainsKey($target)) {
      $buffers[$target] = Get-Content -LiteralPath $target -Raw -Encoding UTF8
    }
    $text = $buffers[$target]
    $mode = $p.Mode
    $multi = [bool]$p.Multi
    $find = $p.Find
    $replace = $p.Replace

    $matchCount = 0
    $newText = $text

    switch ($mode) {
      'regex-replace' {
        $rx = [regex]::new($find, [System.Text.RegularExpressions.RegexOptions]'Multiline, Singleline')
        $matchCount = ($rx.Matches($text)).Count
        if ($matchCount -gt 0) {
          if ($multi) { $newText = $rx.Replace($text, $replace) }
          else { $newText = $rx.Replace($text, $replace, 1) }
        }
      }
      'plain-replace' {
        if ($multi) {
          $matchCount = ([regex]::Matches($text,[regex]::Escape($find))).Count
          if ($matchCount -gt 0) { $newText = $text.Replace($find,$replace) }
        } else {
          $idx = $text.IndexOf($find,[StringComparison]::Ordinal)
          if ($idx -ge 0) {
            $matchCount = 1
            $newText = $text.Substring(0,$idx) + $replace + $text.Substring($idx + $find.Length)
          }
        }
      }
      'insert-before' {
        $rx = [regex]::new($find, [System.Text.RegularExpressions.RegexOptions]'Multiline, Singleline')
        $m = $rx.Match($text)
        if ($m.Success) {
          $matchCount = 1
          $newText = $text.Substring(0,$m.Index) + $replace + $text.Substring($m.Index)
        }
      }
      'insert-after' {
        $rx = [regex]::new($find, [System.Text.RegularExpressions.RegexOptions]'Multiline, Singleline')
        $m = $rx.Match($text)
        if ($m.Success) {
          $matchCount = 1
          $newText = $text.Substring(0,$m.Index+$m.Length) + $replace + $text.Substring($m.Index+$m.Length)
        }
      }
      default { throw "PRECONDITION: Unknown MODE: $mode" }
    }

    $plans += [pscustomobject]@{
      File=$p.Target; Mode=$mode; Multi=$multi; Matches=$matchCount; WillChange=($matchCount -gt 0)
    }

    if ($matchCount -gt 0) { $buffers[$target] = $newText }
  }

  if (-not $Apply) {
    return @{ Plans=$plans; Applied=$false; ChangedFiles=@() }
  }

  $changed=@()
  foreach($kv in $buffers.GetEnumerator()){
    $target = $kv.Key; $content = $kv.Value
    $original = Get-Content -LiteralPath $target -Raw -Encoding UTF8
    if ($original -ne $content) {
      $bak = Backup-And-WriteFile -Path $target -Content $content
      $changed += [pscustomobject]@{File=$target; Backup=$bak}
    }
  }
  return @{ Plans=$plans; Applied=$true; ChangedFiles=$changed }
}

# --- 메인 --------------------------------------------------------------------
$sw=[System.Diagnostics.Stopwatch]::StartNew()
$repo = Get-RepoRoot -Hint $Root
$patchFile = Join-Path $repo '.kobong/patches.pending.txt'

# 락
$LockFile = Join-Path $repo '.gpt5.lock'
if (Test-Path $LockFile) { Write-KLC -Level ERROR -Outcome FAILURE -Action 'fixloop-apply' -ErrorCode 'CONFLICT' -Message '.gpt5.lock exists'; exit 11 }
"locked $(Get-Date -Format o)" | Out-File $LockFile -Encoding utf8 -NoNewline

try {
  if ($Init) {
    New-PatchesFile -Path $patchFile
    Ensure-RollbackManifest -RepoRoot $repo
    Write-Host "[Init] Created/verified $patchFile and Rollbackfile.json"
    Write-KLC -Outcome 'DRYRUN' -Action 'fixloop-init' -Message 'init done'
    exit 0
  }

  if (-not (Test-Path $patchFile)) { throw "PRECONDITION: patches file missing: .kobong/patches.pending.txt" }
  $raw = Get-Content -LiteralPath $patchFile -Raw -Encoding UTF8
  $patches = Parse-PatchBlocks -Text $raw
  if (-not $patches -or $patches.Count -eq 0) { throw "PRECONDITION: no PATCH blocks found" }

  $plan = Plan-And-ApplyPatches -Patches $patches -RepoRoot $repo -Apply:$ConfirmApply
  $table = $plan.Plans | Format-Table -AutoSize | Out-String
  Write-Host $table

  if (-not $ConfirmApply) {
    # 항상 배열화해서 Count 보장
    \ = @()
    if (\ -and \.Plans) {
        \ = @(\.Plans | ForEach-Object { \.File } | Where-Object { \ } | Select-Object -Unique)
    }
    \ = \.Count  # @() 이므로 언제나 Count 존재
    Write-KLC -Outcome 'DRYRUN' -Action 'fixloop-preview' -Message ("Files={0}" -f $filesCount)
    exit 0
}

  $changedFiles = ($plan.ChangedFiles | ForEach-Object { $_.File }) -join ', '
  Write-Host "[Apply] Changed: $changedFiles"
  Ensure-RollbackManifest -RepoRoot $repo
  Write-KLC -Outcome 'SUCCESS' -Action 'fixloop-apply' -Message "changed=$changedFiles" -DurationMs ([int]$sw.ElapsedMilliseconds)
  exit 0
}
catch {
  $msg = $_.Exception.Message
  $code = if ($msg -match '^PRECONDITION') {'PRECONDITION'} elseif ($msg -match '^CONFLICT') {'CONFLICT'} else {'LOGIC'}
  Write-Error $msg
  Write-KLC -Level 'ERROR' -Outcome 'FAILURE' -Action 'fixloop-apply' -ErrorCode $code -Message $msg -DurationMs ([int]$sw.ElapsedMilliseconds)
  switch ($code) { 'PRECONDITION'{ exit 10 } 'CONFLICT'{ exit 11 } default{ exit 13 } }
}
finally {
  Remove-Item -LiteralPath $LockFile -Force -ErrorAction SilentlyContinue
}



.File } | Where-Object { 
# APPLY IN SHELL
#requires -Version 7.0
param(
  [switch]$Init,
  [switch]$ConfirmApply,
  [string]$Root
)

Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

# --- KLC 로그 (v1.2 규격; kobong_logger_cli 우선, JSONL 폴백) ---------------
function Write-KLC {
  param(
    [ValidateSet('INFO','WARN','ERROR','DEBUG')]$Level='INFO',
    [ValidateSet('SUCCESS','FAILURE','DRYRUN')]$Outcome='DRYRUN',
    [string]$Action='fixloop-apply',
    [string]$ErrorCode='',
    [string]$Message='',
    [int]$DurationMs=0
  )
  try {
    if (Get-Command kobong_logger_cli -ErrorAction SilentlyContinue) {
      & kobong_logger_cli log --level $Level --module 'scripts' --action $Action `
        --outcome $Outcome --error $ErrorCode --message $Message --duration-ms $DurationMs 2>$null
      return
    }
  } catch {}
  $root = (git rev-parse --show-toplevel 2>$null); if (-not $root) { $root=(Get-Location).Path }
  $log = Join-Path $root 'logs/apply-log.jsonl'
  New-Item -ItemType Directory -Force -Path (Split-Path $log) | Out-Null
  $rec = @{
    timestamp=(Get-Date).ToString('o'); level=$Level; traceId=[guid]::NewGuid().ToString();
    module='scripts'; action=$Action; outcome=$Outcome; errorCode=$ErrorCode; message=$Message; durationMs=$DurationMs
  } | ConvertTo-Json -Compress
  Add-Content -Path $log -Value $rec
}
# ---------------------------------------------------------------------------

function Get-RepoRoot {
  param([string]$Hint)
  if ($Hint) { return (Resolve-Path -LiteralPath $Hint).Path }
  try { $r = (git rev-parse --show-toplevel 2>$null) } catch { $r = $null }
  if (-not $r) { $r = (Get-Location).Path }
  return $r
}

function Ensure-RollbackManifest {
  param([string]$RepoRoot)
  $rb = Join-Path $RepoRoot 'Rollbackfile.json'
  $obj = if (Test-Path $rb) { Get-Content -Raw -LiteralPath $rb | ConvertFrom-Json } else { [pscustomobject]@{ version=1; targets=@(); retention=@{bak=30;goodSlots=10;redo=3;undo=3}} }
  $need = @('.kobong/patches.pending.txt','scripts/g5/apply-patches.ps1')
  foreach($t in $need) { if (-not ($obj.targets -contains $t)) { $obj.targets += $t } }
  $obj | ConvertTo-Json -Depth 6 | Out-File -LiteralPath $rb -Encoding utf8
}

function New-PatchesFile {
  param([string]$Path)
  if (Test-Path $Path) { return }
  New-Item -ItemType Directory -Force -Path (Split-Path $Path) | Out-Null
  @"
# NO-SHELL
# FixLoop patches — put your PATCH blocks below. See FixLoop Runbook.
# Example:
# PATCH START/END delimit a block. MODE: regex-replace|plain-replace|insert-before|insert-after

# PATCH START
TARGET: README.md
MODE: insert-after
MULTI: false
FIND <<'EOF'
^#\s+.*
EOF
REPLACE <<'EOF'
  
> Updated by FixLoop at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
EOF
# PATCH END
"@ | Out-File -LiteralPath $Path -Encoding utf8
}

# --- PATCH 파서 -------------------------------------------------------------
function Parse-PatchBlocks {
  param([string]$Text)
  $blocks = @()
  $rxBlock = [regex]'(?ms)#\s*PATCH\s+START.*?TARGET:\s*(?<target>.+?)\s*?\r?\n.*?MODE:\s*(?<mode>.+?)\s*?\r?\n(?:(?:MULTI:\s*(?<multi>true|false)).*?\r?\n)?(?:.*?FIND\s*<<''EOF''\r?\n(?<find>.*?)[\r\n]+EOF\s*\r?\n)(?:.*?REPLACE\s*<<''EOF''\r?\n(?<replace>.*?)[\r\n]+EOF\s*\r?\n)?(?:.*?#\s*PATCH\s+END)'
  $m = $rxBlock.Matches($Text)
  foreach($x in $m){
    $blocks += [pscustomobject]@{
      Target = $x.Groups['target'].Value.Trim()
      Mode = $x.Groups['mode'].Value.Trim().ToLower()
      Multi = [bool]::Parse(($x.Groups['multi'].Value.Trim() ?? 'false'))
      Find  = $x.Groups['find'].Value
      Replace = $x.Groups['replace'].Value
    }
  }
  return $blocks
}

# --- 파일 백업(URS 규정: .bak + 원자 교체) -----------------------------------
function Backup-And-WriteFile {
  param([string]$Path, [string]$Content)
  $dir = Split-Path -Parent $Path
  New-Item -ItemType Directory -Force -Path $dir | Out-Null
  $ts = Get-Date -Format 'yyyyMMdd-HHmmss'
  $bak = "$Path.bak-$ts"
  if (Test-Path $Path) { Copy-Item -LiteralPath $Path -Destination $bak -Force }
  $tmp = "$Path.tmp"
  $Content | Out-File -LiteralPath $tmp -Encoding utf8
  Move-Item -LiteralPath $tmp -Destination $Path -Force
  # 보관 개수 30개 유지(오래된 것 정리)
  $baks = Get-ChildItem -LiteralPath $dir -Filter ("{0}.bak-*" -f (Split-Path -Leaf $Path)) -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
  if ($baks.Count -gt 30) { $baks[30..($baks.Count-1)] | Remove-Item -Force }
  return $bak
}

# --- 패치 적용 엔진 ----------------------------------------------------------
function Plan-And-ApplyPatches {
  param([object[]]$Patches, [switch]$Apply, [string]$RepoRoot)

  # 대상 파일별 버퍼를 모아 원 샷 적용
  $buffers = @{}
  $plans = @()

  foreach($p in $Patches){
    $target = Join-Path $RepoRoot $p.Target
    if (-not (Test-Path $target)) { throw "PRECONDITION: Target not found: $($p.Target)" }
    if (-not $buffers.ContainsKey($target)) {
      $buffers[$target] = Get-Content -LiteralPath $target -Raw -Encoding UTF8
    }
    $text = $buffers[$target]
    $mode = $p.Mode
    $multi = [bool]$p.Multi
    $find = $p.Find
    $replace = $p.Replace

    $matchCount = 0
    $newText = $text

    switch ($mode) {
      'regex-replace' {
        $rx = [regex]::new($find, [System.Text.RegularExpressions.RegexOptions]'Multiline, Singleline')
        $matchCount = ($rx.Matches($text)).Count
        if ($matchCount -gt 0) {
          if ($multi) { $newText = $rx.Replace($text, $replace) }
          else { $newText = $rx.Replace($text, $replace, 1) }
        }
      }
      'plain-replace' {
        if ($multi) {
          $matchCount = ([regex]::Matches($text,[regex]::Escape($find))).Count
          if ($matchCount -gt 0) { $newText = $text.Replace($find,$replace) }
        } else {
          $idx = $text.IndexOf($find,[StringComparison]::Ordinal)
          if ($idx -ge 0) {
            $matchCount = 1
            $newText = $text.Substring(0,$idx) + $replace + $text.Substring($idx + $find.Length)
          }
        }
      }
      'insert-before' {
        $rx = [regex]::new($find, [System.Text.RegularExpressions.RegexOptions]'Multiline, Singleline')
        $m = $rx.Match($text)
        if ($m.Success) {
          $matchCount = 1
          $newText = $text.Substring(0,$m.Index) + $replace + $text.Substring($m.Index)
        }
      }
      'insert-after' {
        $rx = [regex]::new($find, [System.Text.RegularExpressions.RegexOptions]'Multiline, Singleline')
        $m = $rx.Match($text)
        if ($m.Success) {
          $matchCount = 1
          $newText = $text.Substring(0,$m.Index+$m.Length) + $replace + $text.Substring($m.Index+$m.Length)
        }
      }
      default { throw "PRECONDITION: Unknown MODE: $mode" }
    }

    $plans += [pscustomobject]@{
      File=$p.Target; Mode=$mode; Multi=$multi; Matches=$matchCount; WillChange=($matchCount -gt 0)
    }

    if ($matchCount -gt 0) { $buffers[$target] = $newText }
  }

  if (-not $Apply) {
    return @{ Plans=$plans; Applied=$false; ChangedFiles=@() }
  }

  $changed=@()
  foreach($kv in $buffers.GetEnumerator()){
    $target = $kv.Key; $content = $kv.Value
    $original = Get-Content -LiteralPath $target -Raw -Encoding UTF8
    if ($original -ne $content) {
      $bak = Backup-And-WriteFile -Path $target -Content $content
      $changed += [pscustomobject]@{File=$target; Backup=$bak}
    }
  }
  return @{ Plans=$plans; Applied=$true; ChangedFiles=$changed }
}

# --- 메인 --------------------------------------------------------------------
$sw=[System.Diagnostics.Stopwatch]::StartNew()
$repo = Get-RepoRoot -Hint $Root
$patchFile = Join-Path $repo '.kobong/patches.pending.txt'

# 락
$LockFile = Join-Path $repo '.gpt5.lock'
if (Test-Path $LockFile) { Write-KLC -Level ERROR -Outcome FAILURE -Action 'fixloop-apply' -ErrorCode 'CONFLICT' -Message '.gpt5.lock exists'; exit 11 }
"locked $(Get-Date -Format o)" | Out-File $LockFile -Encoding utf8 -NoNewline

try {
  if ($Init) {
    New-PatchesFile -Path $patchFile
    Ensure-RollbackManifest -RepoRoot $repo
    Write-Host "[Init] Created/verified $patchFile and Rollbackfile.json"
    Write-KLC -Outcome 'DRYRUN' -Action 'fixloop-init' -Message 'init done'
    exit 0
  }

  if (-not (Test-Path $patchFile)) { throw "PRECONDITION: patches file missing: .kobong/patches.pending.txt" }
  $raw = Get-Content -LiteralPath $patchFile -Raw -Encoding UTF8
  $patches = Parse-PatchBlocks -Text $raw
  if (-not $patches -or $patches.Count -eq 0) { throw "PRECONDITION: no PATCH blocks found" }

  $plan = Plan-And-ApplyPatches -Patches $patches -RepoRoot $repo -Apply:$ConfirmApply
  $table = $plan.Plans | Format-Table -AutoSize | Out-String
  Write-Host $table

  if (-not $ConfirmApply) {
    # 항상 배열화해서 Count 보장
    \ = @()
    if (\ -and \.Plans) {
        \ = @(\.Plans | ForEach-Object { \.File } | Where-Object { \ } | Select-Object -Unique)
    }
    \ = \.Count  # @() 이므로 언제나 Count 존재
    Write-KLC -Outcome 'DRYRUN' -Action 'fixloop-preview' -Message ("Files={0}" -f $filesCount)
    exit 0
}

  $changedFiles = ($plan.ChangedFiles | ForEach-Object { $_.File }) -join ', '
  Write-Host "[Apply] Changed: $changedFiles"
  Ensure-RollbackManifest -RepoRoot $repo
  Write-KLC -Outcome 'SUCCESS' -Action 'fixloop-apply' -Message "changed=$changedFiles" -DurationMs ([int]$sw.ElapsedMilliseconds)
  exit 0
}
catch {
  $msg = $_.Exception.Message
  $code = if ($msg -match '^PRECONDITION') {'PRECONDITION'} elseif ($msg -match '^CONFLICT') {'CONFLICT'} else {'LOGIC'}
  Write-Error $msg
  Write-KLC -Level 'ERROR' -Outcome 'FAILURE' -Action 'fixloop-apply' -ErrorCode $code -Message $msg -DurationMs ([int]$sw.ElapsedMilliseconds)
  switch ($code) { 'PRECONDITION'{ exit 10 } 'CONFLICT'{ exit 11 } default{ exit 13 } }
}
finally {
  Remove-Item -LiteralPath $LockFile -Force -ErrorAction SilentlyContinue
}



 } | Select-Object -Unique)
    }
    $filesCount = $files.Count
    Write-KLC -Outcome 'DRYRUN' -Action 'fixloop-preview' -Message ("Files={0}" -f $filesCount)
    exit 0
}

  $changedFiles = ($plan.ChangedFiles | ForEach-Object { $_.File }) -join ', '
  Write-Host "[Apply] Changed: $changedFiles"
  Ensure-RollbackManifest -RepoRoot $repo
  Write-KLC -Outcome 'SUCCESS' -Action 'fixloop-apply' -Message "changed=$changedFiles" -DurationMs ([int]$sw.ElapsedMilliseconds)
  exit 0
}
catch {
  $msg = $_.Exception.Message
  $code = if ($msg -match '^PRECONDITION') {'PRECONDITION'} elseif ($msg -match '^CONFLICT') {'CONFLICT'} else {'LOGIC'}
  Write-Error $msg
  Write-KLC -Level 'ERROR' -Outcome 'FAILURE' -Action 'fixloop-apply' -ErrorCode $code -Message $msg -DurationMs ([int]$sw.ElapsedMilliseconds)
  switch ($code) { 'PRECONDITION'{ exit 10 } 'CONFLICT'{ exit 11 } default{ exit 13 } }
}
finally {
  Remove-Item -LiteralPath $LockFile -Force -ErrorAction SilentlyContinue
}





