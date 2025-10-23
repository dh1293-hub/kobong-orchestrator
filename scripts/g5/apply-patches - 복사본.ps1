# APPLY IN SHELL
#requires -Version 7.0
<#
  KoBong apply-patches.ps1 — v1.1 (2025-10-22)
  원칙: PS7-First, DRYRUN→APPLY, 레포 샌드박스, .gpt5.lock, .bak 스냅샷, 원자 교체, KLC 최소 1로그
  종료코드: 0=OK, 11=DRYRUN, 12=PRECONDITION, 13=CONFLICT, 1=ERROR
#>

[CmdletBinding()]
param(
  [Parameter()][string]$Root = (Get-Location).Path,
  [Parameter()][string]$PatchFile,
  [Parameter()][string]$PatchesDir,
  [switch]$ConfirmApply,
  [switch]$Quiet
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)

function New-TraceId { ([guid]::NewGuid()).ToString('N') }
function Get-Ts     { Get-Date -Format 'yyyyMMdd-HHmmss' }

function Resolve-RepoRoot([string]$root) {
  $p = Resolve-Path -LiteralPath $root
  if (-not $p) { throw "Root not found: $root" }
  return $p.Path
}

function Join-RepoPath([string]$repo,[string]$rel) {
  if ([string]::IsNullOrWhiteSpace($rel)) { throw "TARGET path is empty." }
  if ($rel -match '^\s*[./\\]*\.\.[/\\]') { throw "Path escapes repo: $rel" }
  $full = Join-Path -LiteralPath $repo -ChildPath $rel
  $norm = [System.IO.Path]::GetFullPath($full)
  if (-not $norm.StartsWith([System.IO.Path]::GetFullPath($repo), [StringComparison]::OrdinalIgnoreCase)) {
    throw "Path escapes repo: $rel"
  }
  return $norm
}

function Get-DefaultPatchList([string]$repo) {
  $list = [System.Collections.Generic.List[string]]::new()
  $pending = Join-Path $repo '.kobong\patches.pending.txt'
  $dir1    = Join-Path $repo '.kobong\patches'
  if (Test-Path -LiteralPath $pending) { $list.Add($pending) | Out-Null }
  if (Test-Path -LiteralPath $dir1) {
  $files = Get-ChildItem -Path $dir1 -File |
           Where-Object { # APPLY IN SHELL
#requires -Version 7.0
<#
  KoBong apply-patches.ps1 — v1.1 (2025-10-22)
  원칙: PS7-First, DRYRUN→APPLY, 레포 샌드박스, .gpt5.lock, .bak 스냅샷, 원자 교체, KLC 최소 1로그
  종료코드: 0=OK, 11=DRYRUN, 12=PRECONDITION, 13=CONFLICT, 1=ERROR
#>

[CmdletBinding()]
param(
  [Parameter()][string]$Root = (Get-Location).Path,
  [Parameter()][string]$PatchFile,
  [Parameter()][string]$PatchesDir,
  [switch]$ConfirmApply,
  [switch]$Quiet
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)

function New-TraceId { ([guid]::NewGuid()).ToString('N') }
function Get-Ts     { Get-Date -Format 'yyyyMMdd-HHmmss' }

function Resolve-RepoRoot([string]$root) {
  $p = Resolve-Path -LiteralPath $root
  if (-not $p) { throw "Root not found: $root" }
  return $p.Path
}

function Join-RepoPath([string]$repo,[string]$rel) {
  if ([string]::IsNullOrWhiteSpace($rel)) { throw "TARGET path is empty." }
  if ($rel -match '^\s*[./\\]*\.\.[/\\]') { throw "Path escapes repo: $rel" }
  $full = Join-Path -LiteralPath $repo -ChildPath $rel
  $norm = [System.IO.Path]::GetFullPath($full)
  if (-not $norm.StartsWith([System.IO.Path]::GetFullPath($repo), [StringComparison]::OrdinalIgnoreCase)) {
    throw "Path escapes repo: $rel"
  }
  return $norm
}

function Get-DefaultPatchList([string]$repo) {
  $list = [System.Collections.Generic.List[string]]::new()
  $pending = Join-Path $repo '.kobong\patches.pending.txt'
  $dir1    = Join-Path $repo '.kobong\patches'
  if (Test-Path -LiteralPath $pending) { $list.Add($pending) | Out-Null }
  if (Test-Path -LiteralPath $dir1) {
    $list.AddRange( Get-ChildItem -LiteralPath $dir1 -File -Include *.txt,*.patch,*.patch.txt | Sort-Object FullName | % { $_.FullName } )
  }
  return $list
}

function Read-TextUtf8([string]$path) {
  return Get-Content -LiteralPath $path -Raw -Encoding UTF8
}

function Write-TextUtf8([string]$path,[string]$text) {
  $dir = Split-Path -LiteralPath $path -Parent
  if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
  $tmp = "$path.tmp.$([guid]::NewGuid().ToString('N'))"
  [System.IO.File]::WriteAllText($tmp, $text, [System.Text.UTF8Encoding]::new($false))
  Move-Item -LiteralPath $tmp -Destination $path -Force
}

function Get-PrevHash([string]$logPath) {
  if (-not (Test-Path -LiteralPath $logPath)) { return ('0' * 64) }
  $last = Get-Content -LiteralPath $logPath -Tail 200 | Where-Object { $_ -match '\S' } | Select-Object -Last 1
  try { return ((ConvertFrom-Json -InputObject $last).hash) } catch { return ('0' * 64) }
}

function Get-Hash([string]$s) {
  $sha = [System.Security.Cryptography.SHA256]::Create()
  $bytes = [System.Text.Encoding]::UTF8.GetBytes($s)
  ($sha.ComputeHash($bytes) | ForEach-Object { $_.ToString('x2') }) -join ''
}

function Write-KLCLog([string]$repo,[hashtable]$obj) {
  $logDir  = Join-Path $repo 'logs'
  if (-not (Test-Path -LiteralPath $logDir)) { New-Item -ItemType Directory -Path $logDir | Out-Null }
  $logPath = Join-Path $logDir 'apply-log.jsonl'
  $prev    = Get-PrevHash $logPath
  $canon   = ($obj.GetEnumerator() | Sort-Object Name | ForEach-Object { "$($_.Name)=$($_.Value)" }) -join '|'
  $hash    = Get-Hash "$prev|$canon"
  $obj['prevHash'] = $prev
  $obj['hash']     = $hash
  $obj['hashAlgo'] = 'SHA256'
  $obj['canonAlgo']= 'kvc-line-v1'
  $json = ($obj | ConvertTo-Json -Depth 6 -Compress)
  Add-Content -LiteralPath $logPath -Value $json
}

function With-Lock([string]$repo,[scriptblock]$body) {
  $lockPath = Join-Path $repo '.gpt5.lock'
  $mineId   = New-TraceId
  if (Test-Path -LiteralPath $lockPath) {
    $age = (Get-Item -LiteralPath $lockPath).LastWriteTimeUtc
    if ((Get-Date).ToUniversalTime().AddMinutes(-10) -gt $age) {
      Rename-Item -LiteralPath $lockPath -NewName (".gpt5.lock.bak-" + (Get-Ts)) -Force
    } else {
      throw "Lock exists: $lockPath (최근 10분 내 실행 흔적)"
    }
  }
  try {
    Set-Content -LiteralPath $lockPath -NoNewline -Encoding UTF8 -Value $mineId
    & $body
  } finally {
    try {
      $current = ''
      if (Test-Path -LiteralPath $lockPath) { $current = Get-Content -LiteralPath $lockPath -Raw -Encoding UTF8 }
      if ($current -eq $mineId) { Remove-Item -LiteralPath $lockPath -Force -ErrorAction SilentlyContinue }
    } catch { }
  }
}

function Parse-PatchBlocks([string]$text) {
  $lines = $text -split "`n"
  $blocks = @()
  $i = 0
  while ($i -lt $lines.Length) {
    if ($lines[$i].Trim() -eq '# PATCH START') {
      $i++
      $meta = @{}
      $find = ''
      $replace = ''
      while ($i -lt $lines.Length -and -not ($lines[$i].Trim() -eq '# PATCH END')) {
        $L = $lines[$i]
        if ($L -match '^\s*TARGET:\s*(.+)$') { $meta.TARGET = $matches[1].Trim() }
        elseif ($L -match '^\s*MODE:\s*(.+)$') { $meta.MODE = $matches[1].Trim().ToLower() }
        elseif ($L -match '^\s*MULTI:\s*(.+)$') { $meta.MULTI = [bool]::Parse($matches[1].Trim()) }
        elseif ($L -match "^\s*FIND\s+<<'EOF'\s*$") {
          $buf = New-Object System.Text.StringBuilder
          $i++
          while ($i -lt $lines.Length -and -not ($lines[$i].Trim() -eq 'EOF')) {
            [void]$buf.AppendLine($lines[$i])
            $i++
          }
          $find = $buf.ToString()
        }
        elseif ($L -match "^\s*REPLACE\s+<<'EOF'\s*$") {
          $buf = New-Object System.Text.StringBuilder
          $i++
          while ($i -lt $lines.Length -and -not ($lines[$i].Trim() -eq 'EOF')) {
            [void]$buf.AppendLine($lines[$i])
            $i++
          }
          $replace = $buf.ToString()
        }
        $i++
      }
      if (-not $meta.TARGET -or -not $meta.MODE) { throw "PATCH 메타 누락(TARGET/MODE)" }
      $blocks += [pscustomobject]@{
        TARGET  = $meta.TARGET
        MODE    = $meta.MODE
        MULTI   = [bool]($meta.MULTI)
        FIND    = $find
        REPLACE = $replace
      }
    } else { $i++ }
  }
  return ,$blocks
}

function Apply-OnePatch([string]$repo, $blk, [bool]$doApply, [string]$traceId) {
  $target = Join-RepoPath $repo $blk.TARGET
  if (-not (Test-Path -LiteralPath $target)) { return @{ exit=12; msg="PRECONDITION: target not found"; target=$blk.TARGET } }

  $orig = Read-TextUtf8 $target
  $new  = $orig
  $matches = 0
  $changed = $false

  # 멱등(SENTINEL): 이미 REPLACE가 있으면 SKIP
  if (-not [string]::IsNullOrEmpty($blk.REPLACE) -and $orig.Contains($blk.REPLACE)) {
    return @{ exit=10; msg="SKIP: already contains REPLACE"; target=$blk.TARGET; matches=0; changed=$false }
  }

  switch ($blk.MODE) {
    'regex-replace' {
      $rx = [System.Text.RegularExpressions.Regex]::new($blk.FIND, 'Singleline,Multiline')
      $matches = ($rx.Matches($orig)).Count
      if ($matches -eq 0) { return @{ exit=10; msg="SKIP: no match"; target=$blk.TARGET; matches=0; changed=$false } }
      if (-not $blk.MULTI -and $matches -gt 1) { return @{ exit=12; msg="PRECONDITION: multiple matches; set MULTI:true"; target=$blk.TARGET; matches=$matches } }
      if ($blk.MULTI) {
        $new = $rx.Replace($orig, $blk.REPLACE)
      } else {
        $m = $rx.Match($orig)
        $new = $orig.Substring(0, $m.Index) + $m.Result($blk.REPLACE) + $orig.Substring($m.Index + $m.Length)
      }
      $changed = ($new -ne $orig)
    }
    'plain-replace' {
      if (-not $orig.Contains($blk.FIND)) { return @{ exit=10; msg="SKIP: FIND not found"; target=$blk.TARGET; matches=0; changed=$false } }
      if ($blk.MULTI) {
        $new = $orig.Replace($blk.FIND, $blk.REPLACE); $matches = ([regex]::Matches($orig, [regex]::Escape($blk.FIND))).Count
      } else {
        $idx = $orig.IndexOf($blk.FIND)
        $new = $orig.Substring(0,$idx) + $blk.REPLACE + $orig.Substring($idx + $blk.FIND.Length); $matches = 1
      }
      $changed = ($new -ne $orig)
    }
    'insert-after' {
      $rx = [System.Text.RegularExpressions.Regex]::new($blk.FIND, 'Singleline,Multiline')
      $m  = $rx.Match($orig)
      if (-not $m.Success) { return @{ exit=10; msg="SKIP: anchor not found"; target=$blk.TARGET; matches=0; changed=$false } }
      if (-not $blk.MULTI -and $rx.Matches($orig).Count -gt 1) { return @{ exit=12; msg="PRECONDITION: multiple anchors; set MULTI:true"; target=$blk.TARGET } }
      if ($blk.MULTI) {
        $new = $rx.Replace($orig, { param($m) $m.Value + $blk.REPLACE })
        $matches = $rx.Matches($orig).Count
      } else {
        $new = $orig.Substring(0,$m.Index+$m.Length) + $blk.REPLACE + $orig.Substring($m.Index+$m.Length)
        $matches = 1
      }
      $changed = ($new -ne $orig)
    }
    'insert-before' {
      $rx = [System.Text.RegularExpressions.Regex]::new($blk.FIND, 'Singleline,Multiline')
      $m  = $rx.Match($orig)
      if (-not $m.Success) { return @{ exit=10; msg="SKIP: anchor not found"; target=$blk.TARGET; matches=0; changed=$false } }
      if (-not $blk.MULTI -and $rx.Matches($orig).Count -gt 1) { return @{ exit=12; msg="PRECONDITION: multiple anchors; set MULTI:true"; target=$blk.TARGET } }
      if ($blk.MULTI) {
        $new = $rx.Replace($orig, { param($m) $blk.REPLACE + $m.Value })
        $matches = $rx.Matches($orig).Count
      } else {
        $new = $orig.Substring(0,$m.Index) + $blk.REPLACE + $orig.Substring($m.Index)
        $matches = 1
      }
      $changed = ($new -ne $orig)
    }
    default { return @{ exit=12; msg="PRECONDITION: unknown MODE '$($blk.MODE)'" ; target=$blk.TARGET } }
  }

  if (-not $changed) { return @{ exit=10; msg="SKIP: no change"; target=$blk.TARGET; matches=$matches; changed=$false } }

  if ($doApply) {
    # ReadOnly 해제(있다면)
    try {
      $fi = Get-Item -LiteralPath $target -Force
      if ($fi.Attributes.HasFlag([IO.FileAttributes]::ReadOnly)) {
        $fi.Attributes = $fi.Attributes -band (-bnot [IO.FileAttributes]::ReadOnly)
      }
    } catch {}
    $bak = "$target.bak-$(Get-Ts)"
    Copy-Item -LiteralPath $target -Destination $bak -Force
    Write-TextUtf8 -path $target -text $new
    return @{ exit=0; msg="APPLY OK"; target=$blk.TARGET; matches=$matches; backup=$bak; changed=$true }
  } else {
    return @{ exit=11; msg="DRYRUN OK (would change)"; target=$blk.TARGET; matches=$matches; changed=$true }
  }
}

# ---------- Main ----------
$repo = Resolve-RepoRoot $Root
$trace = New-TraceId
$doApply = $ConfirmApply.IsPresent -or ($env:CONFIRM_APPLY -and $env:CONFIRM_APPLY.ToString().ToLower() -eq 'true')

$patchFiles = @()
if ($PatchFile)   { $patchFiles += (Resolve-Path -LiteralPath $PatchFile).Path }
if ($PatchesDir) {
  $files = Get-ChildItem -Path $PatchesDir -File |
           Where-Object { # APPLY IN SHELL
#requires -Version 7.0
<#
  KoBong apply-patches.ps1 — v1.1 (2025-10-22)
  원칙: PS7-First, DRYRUN→APPLY, 레포 샌드박스, .gpt5.lock, .bak 스냅샷, 원자 교체, KLC 최소 1로그
  종료코드: 0=OK, 11=DRYRUN, 12=PRECONDITION, 13=CONFLICT, 1=ERROR
#>

[CmdletBinding()]
param(
  [Parameter()][string]$Root = (Get-Location).Path,
  [Parameter()][string]$PatchFile,
  [Parameter()][string]$PatchesDir,
  [switch]$ConfirmApply,
  [switch]$Quiet
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)

function New-TraceId { ([guid]::NewGuid()).ToString('N') }
function Get-Ts     { Get-Date -Format 'yyyyMMdd-HHmmss' }

function Resolve-RepoRoot([string]$root) {
  $p = Resolve-Path -LiteralPath $root
  if (-not $p) { throw "Root not found: $root" }
  return $p.Path
}

function Join-RepoPath([string]$repo,[string]$rel) {
  if ([string]::IsNullOrWhiteSpace($rel)) { throw "TARGET path is empty." }
  if ($rel -match '^\s*[./\\]*\.\.[/\\]') { throw "Path escapes repo: $rel" }
  $full = Join-Path -LiteralPath $repo -ChildPath $rel
  $norm = [System.IO.Path]::GetFullPath($full)
  if (-not $norm.StartsWith([System.IO.Path]::GetFullPath($repo), [StringComparison]::OrdinalIgnoreCase)) {
    throw "Path escapes repo: $rel"
  }
  return $norm
}

function Get-DefaultPatchList([string]$repo) {
  $list = [System.Collections.Generic.List[string]]::new()
  $pending = Join-Path $repo '.kobong\patches.pending.txt'
  $dir1    = Join-Path $repo '.kobong\patches'
  if (Test-Path -LiteralPath $pending) { $list.Add($pending) | Out-Null }
  if (Test-Path -LiteralPath $dir1) {
  $files = Get-ChildItem -Path $dir1 -File |
           Where-Object { # APPLY IN SHELL
#requires -Version 7.0
<#
  KoBong apply-patches.ps1 — v1.1 (2025-10-22)
  원칙: PS7-First, DRYRUN→APPLY, 레포 샌드박스, .gpt5.lock, .bak 스냅샷, 원자 교체, KLC 최소 1로그
  종료코드: 0=OK, 11=DRYRUN, 12=PRECONDITION, 13=CONFLICT, 1=ERROR
#>

[CmdletBinding()]
param(
  [Parameter()][string]$Root = (Get-Location).Path,
  [Parameter()][string]$PatchFile,
  [Parameter()][string]$PatchesDir,
  [switch]$ConfirmApply,
  [switch]$Quiet
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)

function New-TraceId { ([guid]::NewGuid()).ToString('N') }
function Get-Ts     { Get-Date -Format 'yyyyMMdd-HHmmss' }

function Resolve-RepoRoot([string]$root) {
  $p = Resolve-Path -LiteralPath $root
  if (-not $p) { throw "Root not found: $root" }
  return $p.Path
}

function Join-RepoPath([string]$repo,[string]$rel) {
  if ([string]::IsNullOrWhiteSpace($rel)) { throw "TARGET path is empty." }
  if ($rel -match '^\s*[./\\]*\.\.[/\\]') { throw "Path escapes repo: $rel" }
  $full = Join-Path -LiteralPath $repo -ChildPath $rel
  $norm = [System.IO.Path]::GetFullPath($full)
  if (-not $norm.StartsWith([System.IO.Path]::GetFullPath($repo), [StringComparison]::OrdinalIgnoreCase)) {
    throw "Path escapes repo: $rel"
  }
  return $norm
}

function Get-DefaultPatchList([string]$repo) {
  $list = [System.Collections.Generic.List[string]]::new()
  $pending = Join-Path $repo '.kobong\patches.pending.txt'
  $dir1    = Join-Path $repo '.kobong\patches'
  if (Test-Path -LiteralPath $pending) { $list.Add($pending) | Out-Null }
  if (Test-Path -LiteralPath $dir1) {
    $list.AddRange( Get-ChildItem -LiteralPath $dir1 -File -Include *.txt,*.patch,*.patch.txt | Sort-Object FullName | % { $_.FullName } )
  }
  return $list
}

function Read-TextUtf8([string]$path) {
  return Get-Content -LiteralPath $path -Raw -Encoding UTF8
}

function Write-TextUtf8([string]$path,[string]$text) {
  $dir = Split-Path -LiteralPath $path -Parent
  if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
  $tmp = "$path.tmp.$([guid]::NewGuid().ToString('N'))"
  [System.IO.File]::WriteAllText($tmp, $text, [System.Text.UTF8Encoding]::new($false))
  Move-Item -LiteralPath $tmp -Destination $path -Force
}

function Get-PrevHash([string]$logPath) {
  if (-not (Test-Path -LiteralPath $logPath)) { return ('0' * 64) }
  $last = Get-Content -LiteralPath $logPath -Tail 200 | Where-Object { $_ -match '\S' } | Select-Object -Last 1
  try { return ((ConvertFrom-Json -InputObject $last).hash) } catch { return ('0' * 64) }
}

function Get-Hash([string]$s) {
  $sha = [System.Security.Cryptography.SHA256]::Create()
  $bytes = [System.Text.Encoding]::UTF8.GetBytes($s)
  ($sha.ComputeHash($bytes) | ForEach-Object { $_.ToString('x2') }) -join ''
}

function Write-KLCLog([string]$repo,[hashtable]$obj) {
  $logDir  = Join-Path $repo 'logs'
  if (-not (Test-Path -LiteralPath $logDir)) { New-Item -ItemType Directory -Path $logDir | Out-Null }
  $logPath = Join-Path $logDir 'apply-log.jsonl'
  $prev    = Get-PrevHash $logPath
  $canon   = ($obj.GetEnumerator() | Sort-Object Name | ForEach-Object { "$($_.Name)=$($_.Value)" }) -join '|'
  $hash    = Get-Hash "$prev|$canon"
  $obj['prevHash'] = $prev
  $obj['hash']     = $hash
  $obj['hashAlgo'] = 'SHA256'
  $obj['canonAlgo']= 'kvc-line-v1'
  $json = ($obj | ConvertTo-Json -Depth 6 -Compress)
  Add-Content -LiteralPath $logPath -Value $json
}

function With-Lock([string]$repo,[scriptblock]$body) {
  $lockPath = Join-Path $repo '.gpt5.lock'
  $mineId   = New-TraceId
  if (Test-Path -LiteralPath $lockPath) {
    $age = (Get-Item -LiteralPath $lockPath).LastWriteTimeUtc
    if ((Get-Date).ToUniversalTime().AddMinutes(-10) -gt $age) {
      Rename-Item -LiteralPath $lockPath -NewName (".gpt5.lock.bak-" + (Get-Ts)) -Force
    } else {
      throw "Lock exists: $lockPath (최근 10분 내 실행 흔적)"
    }
  }
  try {
    Set-Content -LiteralPath $lockPath -NoNewline -Encoding UTF8 -Value $mineId
    & $body
  } finally {
    try {
      $current = ''
      if (Test-Path -LiteralPath $lockPath) { $current = Get-Content -LiteralPath $lockPath -Raw -Encoding UTF8 }
      if ($current -eq $mineId) { Remove-Item -LiteralPath $lockPath -Force -ErrorAction SilentlyContinue }
    } catch { }
  }
}

function Parse-PatchBlocks([string]$text) {
  $lines = $text -split "`n"
  $blocks = @()
  $i = 0
  while ($i -lt $lines.Length) {
    if ($lines[$i].Trim() -eq '# PATCH START') {
      $i++
      $meta = @{}
      $find = ''
      $replace = ''
      while ($i -lt $lines.Length -and -not ($lines[$i].Trim() -eq '# PATCH END')) {
        $L = $lines[$i]
        if ($L -match '^\s*TARGET:\s*(.+)$') { $meta.TARGET = $matches[1].Trim() }
        elseif ($L -match '^\s*MODE:\s*(.+)$') { $meta.MODE = $matches[1].Trim().ToLower() }
        elseif ($L -match '^\s*MULTI:\s*(.+)$') { $meta.MULTI = [bool]::Parse($matches[1].Trim()) }
        elseif ($L -match "^\s*FIND\s+<<'EOF'\s*$") {
          $buf = New-Object System.Text.StringBuilder
          $i++
          while ($i -lt $lines.Length -and -not ($lines[$i].Trim() -eq 'EOF')) {
            [void]$buf.AppendLine($lines[$i])
            $i++
          }
          $find = $buf.ToString()
        }
        elseif ($L -match "^\s*REPLACE\s+<<'EOF'\s*$") {
          $buf = New-Object System.Text.StringBuilder
          $i++
          while ($i -lt $lines.Length -and -not ($lines[$i].Trim() -eq 'EOF')) {
            [void]$buf.AppendLine($lines[$i])
            $i++
          }
          $replace = $buf.ToString()
        }
        $i++
      }
      if (-not $meta.TARGET -or -not $meta.MODE) { throw "PATCH 메타 누락(TARGET/MODE)" }
      $blocks += [pscustomobject]@{
        TARGET  = $meta.TARGET
        MODE    = $meta.MODE
        MULTI   = [bool]($meta.MULTI)
        FIND    = $find
        REPLACE = $replace
      }
    } else { $i++ }
  }
  return ,$blocks
}

function Apply-OnePatch([string]$repo, $blk, [bool]$doApply, [string]$traceId) {
  $target = Join-RepoPath $repo $blk.TARGET
  if (-not (Test-Path -LiteralPath $target)) { return @{ exit=12; msg="PRECONDITION: target not found"; target=$blk.TARGET } }

  $orig = Read-TextUtf8 $target
  $new  = $orig
  $matches = 0
  $changed = $false

  # 멱등(SENTINEL): 이미 REPLACE가 있으면 SKIP
  if (-not [string]::IsNullOrEmpty($blk.REPLACE) -and $orig.Contains($blk.REPLACE)) {
    return @{ exit=10; msg="SKIP: already contains REPLACE"; target=$blk.TARGET; matches=0; changed=$false }
  }

  switch ($blk.MODE) {
    'regex-replace' {
      $rx = [System.Text.RegularExpressions.Regex]::new($blk.FIND, 'Singleline,Multiline')
      $matches = ($rx.Matches($orig)).Count
      if ($matches -eq 0) { return @{ exit=10; msg="SKIP: no match"; target=$blk.TARGET; matches=0; changed=$false } }
      if (-not $blk.MULTI -and $matches -gt 1) { return @{ exit=12; msg="PRECONDITION: multiple matches; set MULTI:true"; target=$blk.TARGET; matches=$matches } }
      if ($blk.MULTI) {
        $new = $rx.Replace($orig, $blk.REPLACE)
      } else {
        $m = $rx.Match($orig)
        $new = $orig.Substring(0, $m.Index) + $m.Result($blk.REPLACE) + $orig.Substring($m.Index + $m.Length)
      }
      $changed = ($new -ne $orig)
    }
    'plain-replace' {
      if (-not $orig.Contains($blk.FIND)) { return @{ exit=10; msg="SKIP: FIND not found"; target=$blk.TARGET; matches=0; changed=$false } }
      if ($blk.MULTI) {
        $new = $orig.Replace($blk.FIND, $blk.REPLACE); $matches = ([regex]::Matches($orig, [regex]::Escape($blk.FIND))).Count
      } else {
        $idx = $orig.IndexOf($blk.FIND)
        $new = $orig.Substring(0,$idx) + $blk.REPLACE + $orig.Substring($idx + $blk.FIND.Length); $matches = 1
      }
      $changed = ($new -ne $orig)
    }
    'insert-after' {
      $rx = [System.Text.RegularExpressions.Regex]::new($blk.FIND, 'Singleline,Multiline')
      $m  = $rx.Match($orig)
      if (-not $m.Success) { return @{ exit=10; msg="SKIP: anchor not found"; target=$blk.TARGET; matches=0; changed=$false } }
      if (-not $blk.MULTI -and $rx.Matches($orig).Count -gt 1) { return @{ exit=12; msg="PRECONDITION: multiple anchors; set MULTI:true"; target=$blk.TARGET } }
      if ($blk.MULTI) {
        $new = $rx.Replace($orig, { param($m) $m.Value + $blk.REPLACE })
        $matches = $rx.Matches($orig).Count
      } else {
        $new = $orig.Substring(0,$m.Index+$m.Length) + $blk.REPLACE + $orig.Substring($m.Index+$m.Length)
        $matches = 1
      }
      $changed = ($new -ne $orig)
    }
    'insert-before' {
      $rx = [System.Text.RegularExpressions.Regex]::new($blk.FIND, 'Singleline,Multiline')
      $m  = $rx.Match($orig)
      if (-not $m.Success) { return @{ exit=10; msg="SKIP: anchor not found"; target=$blk.TARGET; matches=0; changed=$false } }
      if (-not $blk.MULTI -and $rx.Matches($orig).Count -gt 1) { return @{ exit=12; msg="PRECONDITION: multiple anchors; set MULTI:true"; target=$blk.TARGET } }
      if ($blk.MULTI) {
        $new = $rx.Replace($orig, { param($m) $blk.REPLACE + $m.Value })
        $matches = $rx.Matches($orig).Count
      } else {
        $new = $orig.Substring(0,$m.Index) + $blk.REPLACE + $orig.Substring($m.Index)
        $matches = 1
      }
      $changed = ($new -ne $orig)
    }
    default { return @{ exit=12; msg="PRECONDITION: unknown MODE '$($blk.MODE)'" ; target=$blk.TARGET } }
  }

  if (-not $changed) { return @{ exit=10; msg="SKIP: no change"; target=$blk.TARGET; matches=$matches; changed=$false } }

  if ($doApply) {
    # ReadOnly 해제(있다면)
    try {
      $fi = Get-Item -LiteralPath $target -Force
      if ($fi.Attributes.HasFlag([IO.FileAttributes]::ReadOnly)) {
        $fi.Attributes = $fi.Attributes -band (-bnot [IO.FileAttributes]::ReadOnly)
      }
    } catch {}
    $bak = "$target.bak-$(Get-Ts)"
    Copy-Item -LiteralPath $target -Destination $bak -Force
    Write-TextUtf8 -path $target -text $new
    return @{ exit=0; msg="APPLY OK"; target=$blk.TARGET; matches=$matches; backup=$bak; changed=$true }
  } else {
    return @{ exit=11; msg="DRYRUN OK (would change)"; target=$blk.TARGET; matches=$matches; changed=$true }
  }
}

# ---------- Main ----------
$repo = Resolve-RepoRoot $Root
$trace = New-TraceId
$doApply = $ConfirmApply.IsPresent -or ($env:CONFIRM_APPLY -and $env:CONFIRM_APPLY.ToString().ToLower() -eq 'true')

$patchFiles = @()
if ($PatchFile)   { $patchFiles += (Resolve-Path -LiteralPath $PatchFile).Path }
if ($PatchesDir)  { $patchFiles += (Get-ChildItem -LiteralPath $PatchesDir -File -Include *.txt,*.patch,*.patch.txt | Sort-Object FullName | % FullName) }
if (-not $PatchFile -and -not $PatchesDir) { $patchFiles += Get-DefaultPatchList $repo }
if (-not $patchFiles) { throw "패치 파일이 없습니다(.kobong\patches.pending.txt 또는 .kobong\patches\*.txt)" }

$all = @()
foreach ($pf in $patchFiles) {
  $txt = Read-TextUtf8 $pf
  $blocks = Parse-PatchBlocks $txt
  if (-not $blocks -or $blocks.Count -eq 0) { throw "유효한 PATCH 블록이 없습니다: $pf" }
  $all += $blocks
}

$exitMax = 0
$print = { param($o)
  if (-not $Quiet) {
    "{0,-7} | {1} | {2} | matches={3} {4}" -f $o.exit, $o.msg, $o.target, ($o.matches ?? 0), ($(if($o.backup){"| bak=$($o.backup)"}else{""}))
  }
}

With-Lock $repo {
  $start = Get-Date
  foreach ($blk in $all) {
    $res = Apply-OnePatch -repo $repo -blk $blk -doApply:$doApply -traceId $trace
    & $print $res
    if ($res.exit -gt $exitMax) { $exitMax = $res.exit }
    Write-KLCLog $repo @{
      version   = '1.3'
      timestamp = (Get-Date).ToUniversalTime().ToString('o')
      traceId   = $trace
      env       = 'DEV'
      mode      = ($doApply ? 'APPLY' : 'DRYRUN')
      service   = 'apply-patches'
      module    = 'scripts/g5/apply-patches.ps1'
      action    = 'patch'
      outcome   = $res.msg
      exitCode  = $res.exit
      target    = $res.target
      matches   = ($res.matches ?? 0)
      backup    = ($res.backup ?? '')
      durationMs= [int]((Get-Date) - $start).TotalMilliseconds
      message   = $res.msg
    }
  }
}

if ($exitMax -eq 11 -and -not $doApply) { exit 11 }        # DRYRUN only
elseif ($exitMax -in 12,13)           { exit $exitMax }     # PRECONDITION/CONFLICT
elseif ($exitMax -eq 0)               { exit 0 }            # all good
elseif ($exitMax -eq 10)              { exit 0 }            # all skipped -> OK
else                                  { exit 1 }            # unknown -> ERROR
.Name -match '\.(txt|patch|patch\.txt)
  return $list
}

function Read-TextUtf8([string]$path) {
  return Get-Content -LiteralPath $path -Raw -Encoding UTF8
}

function Write-TextUtf8([string]$path,[string]$text) {
  $dir = Split-Path -LiteralPath $path -Parent
  if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
  $tmp = "$path.tmp.$([guid]::NewGuid().ToString('N'))"
  [System.IO.File]::WriteAllText($tmp, $text, [System.Text.UTF8Encoding]::new($false))
  Move-Item -LiteralPath $tmp -Destination $path -Force
}

function Get-PrevHash([string]$logPath) {
  if (-not (Test-Path -LiteralPath $logPath)) { return ('0' * 64) }
  $last = Get-Content -LiteralPath $logPath -Tail 200 | Where-Object { $_ -match '\S' } | Select-Object -Last 1
  try { return ((ConvertFrom-Json -InputObject $last).hash) } catch { return ('0' * 64) }
}

function Get-Hash([string]$s) {
  $sha = [System.Security.Cryptography.SHA256]::Create()
  $bytes = [System.Text.Encoding]::UTF8.GetBytes($s)
  ($sha.ComputeHash($bytes) | ForEach-Object { $_.ToString('x2') }) -join ''
}

function Write-KLCLog([string]$repo,[hashtable]$obj) {
  $logDir  = Join-Path $repo 'logs'
  if (-not (Test-Path -LiteralPath $logDir)) { New-Item -ItemType Directory -Path $logDir | Out-Null }
  $logPath = Join-Path $logDir 'apply-log.jsonl'
  $prev    = Get-PrevHash $logPath
  $canon   = ($obj.GetEnumerator() | Sort-Object Name | ForEach-Object { "$($_.Name)=$($_.Value)" }) -join '|'
  $hash    = Get-Hash "$prev|$canon"
  $obj['prevHash'] = $prev
  $obj['hash']     = $hash
  $obj['hashAlgo'] = 'SHA256'
  $obj['canonAlgo']= 'kvc-line-v1'
  $json = ($obj | ConvertTo-Json -Depth 6 -Compress)
  Add-Content -LiteralPath $logPath -Value $json
}

function With-Lock([string]$repo,[scriptblock]$body) {
  $lockPath = Join-Path $repo '.gpt5.lock'
  $mineId   = New-TraceId
  if (Test-Path -LiteralPath $lockPath) {
    $age = (Get-Item -LiteralPath $lockPath).LastWriteTimeUtc
    if ((Get-Date).ToUniversalTime().AddMinutes(-10) -gt $age) {
      Rename-Item -LiteralPath $lockPath -NewName (".gpt5.lock.bak-" + (Get-Ts)) -Force
    } else {
      throw "Lock exists: $lockPath (최근 10분 내 실행 흔적)"
    }
  }
  try {
    Set-Content -LiteralPath $lockPath -NoNewline -Encoding UTF8 -Value $mineId
    & $body
  } finally {
    try {
      $current = ''
      if (Test-Path -LiteralPath $lockPath) { $current = Get-Content -LiteralPath $lockPath -Raw -Encoding UTF8 }
      if ($current -eq $mineId) { Remove-Item -LiteralPath $lockPath -Force -ErrorAction SilentlyContinue }
    } catch { }
  }
}

function Parse-PatchBlocks([string]$text) {
  $lines = $text -split "`n"
  $blocks = @()
  $i = 0
  while ($i -lt $lines.Length) {
    if ($lines[$i].Trim() -eq '# PATCH START') {
      $i++
      $meta = @{}
      $find = ''
      $replace = ''
      while ($i -lt $lines.Length -and -not ($lines[$i].Trim() -eq '# PATCH END')) {
        $L = $lines[$i]
        if ($L -match '^\s*TARGET:\s*(.+)$') { $meta.TARGET = $matches[1].Trim() }
        elseif ($L -match '^\s*MODE:\s*(.+)$') { $meta.MODE = $matches[1].Trim().ToLower() }
        elseif ($L -match '^\s*MULTI:\s*(.+)$') { $meta.MULTI = [bool]::Parse($matches[1].Trim()) }
        elseif ($L -match "^\s*FIND\s+<<'EOF'\s*$") {
          $buf = New-Object System.Text.StringBuilder
          $i++
          while ($i -lt $lines.Length -and -not ($lines[$i].Trim() -eq 'EOF')) {
            [void]$buf.AppendLine($lines[$i])
            $i++
          }
          $find = $buf.ToString()
        }
        elseif ($L -match "^\s*REPLACE\s+<<'EOF'\s*$") {
          $buf = New-Object System.Text.StringBuilder
          $i++
          while ($i -lt $lines.Length -and -not ($lines[$i].Trim() -eq 'EOF')) {
            [void]$buf.AppendLine($lines[$i])
            $i++
          }
          $replace = $buf.ToString()
        }
        $i++
      }
      if (-not $meta.TARGET -or -not $meta.MODE) { throw "PATCH 메타 누락(TARGET/MODE)" }
      $blocks += [pscustomobject]@{
        TARGET  = $meta.TARGET
        MODE    = $meta.MODE
        MULTI   = [bool]($meta.MULTI)
        FIND    = $find
        REPLACE = $replace
      }
    } else { $i++ }
  }
  return ,$blocks
}

function Apply-OnePatch([string]$repo, $blk, [bool]$doApply, [string]$traceId) {
  $target = Join-RepoPath $repo $blk.TARGET
  if (-not (Test-Path -LiteralPath $target)) { return @{ exit=12; msg="PRECONDITION: target not found"; target=$blk.TARGET } }

  $orig = Read-TextUtf8 $target
  $new  = $orig
  $matches = 0
  $changed = $false

  # 멱등(SENTINEL): 이미 REPLACE가 있으면 SKIP
  if (-not [string]::IsNullOrEmpty($blk.REPLACE) -and $orig.Contains($blk.REPLACE)) {
    return @{ exit=10; msg="SKIP: already contains REPLACE"; target=$blk.TARGET; matches=0; changed=$false }
  }

  switch ($blk.MODE) {
    'regex-replace' {
      $rx = [System.Text.RegularExpressions.Regex]::new($blk.FIND, 'Singleline,Multiline')
      $matches = ($rx.Matches($orig)).Count
      if ($matches -eq 0) { return @{ exit=10; msg="SKIP: no match"; target=$blk.TARGET; matches=0; changed=$false } }
      if (-not $blk.MULTI -and $matches -gt 1) { return @{ exit=12; msg="PRECONDITION: multiple matches; set MULTI:true"; target=$blk.TARGET; matches=$matches } }
      if ($blk.MULTI) {
        $new = $rx.Replace($orig, $blk.REPLACE)
      } else {
        $m = $rx.Match($orig)
        $new = $orig.Substring(0, $m.Index) + $m.Result($blk.REPLACE) + $orig.Substring($m.Index + $m.Length)
      }
      $changed = ($new -ne $orig)
    }
    'plain-replace' {
      if (-not $orig.Contains($blk.FIND)) { return @{ exit=10; msg="SKIP: FIND not found"; target=$blk.TARGET; matches=0; changed=$false } }
      if ($blk.MULTI) {
        $new = $orig.Replace($blk.FIND, $blk.REPLACE); $matches = ([regex]::Matches($orig, [regex]::Escape($blk.FIND))).Count
      } else {
        $idx = $orig.IndexOf($blk.FIND)
        $new = $orig.Substring(0,$idx) + $blk.REPLACE + $orig.Substring($idx + $blk.FIND.Length); $matches = 1
      }
      $changed = ($new -ne $orig)
    }
    'insert-after' {
      $rx = [System.Text.RegularExpressions.Regex]::new($blk.FIND, 'Singleline,Multiline')
      $m  = $rx.Match($orig)
      if (-not $m.Success) { return @{ exit=10; msg="SKIP: anchor not found"; target=$blk.TARGET; matches=0; changed=$false } }
      if (-not $blk.MULTI -and $rx.Matches($orig).Count -gt 1) { return @{ exit=12; msg="PRECONDITION: multiple anchors; set MULTI:true"; target=$blk.TARGET } }
      if ($blk.MULTI) {
        $new = $rx.Replace($orig, { param($m) $m.Value + $blk.REPLACE })
        $matches = $rx.Matches($orig).Count
      } else {
        $new = $orig.Substring(0,$m.Index+$m.Length) + $blk.REPLACE + $orig.Substring($m.Index+$m.Length)
        $matches = 1
      }
      $changed = ($new -ne $orig)
    }
    'insert-before' {
      $rx = [System.Text.RegularExpressions.Regex]::new($blk.FIND, 'Singleline,Multiline')
      $m  = $rx.Match($orig)
      if (-not $m.Success) { return @{ exit=10; msg="SKIP: anchor not found"; target=$blk.TARGET; matches=0; changed=$false } }
      if (-not $blk.MULTI -and $rx.Matches($orig).Count -gt 1) { return @{ exit=12; msg="PRECONDITION: multiple anchors; set MULTI:true"; target=$blk.TARGET } }
      if ($blk.MULTI) {
        $new = $rx.Replace($orig, { param($m) $blk.REPLACE + $m.Value })
        $matches = $rx.Matches($orig).Count
      } else {
        $new = $orig.Substring(0,$m.Index) + $blk.REPLACE + $orig.Substring($m.Index)
        $matches = 1
      }
      $changed = ($new -ne $orig)
    }
    default { return @{ exit=12; msg="PRECONDITION: unknown MODE '$($blk.MODE)'" ; target=$blk.TARGET } }
  }

  if (-not $changed) { return @{ exit=10; msg="SKIP: no change"; target=$blk.TARGET; matches=$matches; changed=$false } }

  if ($doApply) {
    # ReadOnly 해제(있다면)
    try {
      $fi = Get-Item -LiteralPath $target -Force
      if ($fi.Attributes.HasFlag([IO.FileAttributes]::ReadOnly)) {
        $fi.Attributes = $fi.Attributes -band (-bnot [IO.FileAttributes]::ReadOnly)
      }
    } catch {}
    $bak = "$target.bak-$(Get-Ts)"
    Copy-Item -LiteralPath $target -Destination $bak -Force
    Write-TextUtf8 -path $target -text $new
    return @{ exit=0; msg="APPLY OK"; target=$blk.TARGET; matches=$matches; backup=$bak; changed=$true }
  } else {
    return @{ exit=11; msg="DRYRUN OK (would change)"; target=$blk.TARGET; matches=$matches; changed=$true }
  }
}

# ---------- Main ----------
$repo = Resolve-RepoRoot $Root
$trace = New-TraceId
$doApply = $ConfirmApply.IsPresent -or ($env:CONFIRM_APPLY -and $env:CONFIRM_APPLY.ToString().ToLower() -eq 'true')

$patchFiles = @()
if ($PatchFile)   { $patchFiles += (Resolve-Path -LiteralPath $PatchFile).Path }
if ($PatchesDir)  { $patchFiles += (Get-ChildItem -LiteralPath $PatchesDir -File -Include *.txt,*.patch,*.patch.txt | Sort-Object FullName | % FullName) }
if (-not $PatchFile -and -not $PatchesDir) { $patchFiles += Get-DefaultPatchList $repo }
if (-not $patchFiles) { throw "패치 파일이 없습니다(.kobong\patches.pending.txt 또는 .kobong\patches\*.txt)" }

$all = @()
foreach ($pf in $patchFiles) {
  $txt = Read-TextUtf8 $pf
  $blocks = Parse-PatchBlocks $txt
  if (-not $blocks -or $blocks.Count -eq 0) { throw "유효한 PATCH 블록이 없습니다: $pf" }
  $all += $blocks
}

$exitMax = 0
$print = { param($o)
  if (-not $Quiet) {
    "{0,-7} | {1} | {2} | matches={3} {4}" -f $o.exit, $o.msg, $o.target, ($o.matches ?? 0), ($(if($o.backup){"| bak=$($o.backup)"}else{""}))
  }
}

With-Lock $repo {
  $start = Get-Date
  foreach ($blk in $all) {
    $res = Apply-OnePatch -repo $repo -blk $blk -doApply:$doApply -traceId $trace
    & $print $res
    if ($res.exit -gt $exitMax) { $exitMax = $res.exit }
    Write-KLCLog $repo @{
      version   = '1.3'
      timestamp = (Get-Date).ToUniversalTime().ToString('o')
      traceId   = $trace
      env       = 'DEV'
      mode      = ($doApply ? 'APPLY' : 'DRYRUN')
      service   = 'apply-patches'
      module    = 'scripts/g5/apply-patches.ps1'
      action    = 'patch'
      outcome   = $res.msg
      exitCode  = $res.exit
      target    = $res.target
      matches   = ($res.matches ?? 0)
      backup    = ($res.backup ?? '')
      durationMs= [int]((Get-Date) - $start).TotalMilliseconds
      message   = $res.msg
    }
  }
}

if ($exitMax -eq 11 -and -not $doApply) { exit 11 }        # DRYRUN only
elseif ($exitMax -in 12,13)           { exit $exitMax }     # PRECONDITION/CONFLICT
elseif ($exitMax -eq 0)               { exit 0 }            # all good
elseif ($exitMax -eq 10)              { exit 0 }            # all skipped -> OK
else                                  { exit 1 }            # unknown -> ERROR
 } |
           Sort-Object FullName
  foreach ($f in $files) { [void]$list.Add($f.FullName) }
}
  return $list
}

function Read-TextUtf8([string]$path) {
  return Get-Content -LiteralPath $path -Raw -Encoding UTF8
}

function Write-TextUtf8([string]$path,[string]$text) {
  $dir = Split-Path -LiteralPath $path -Parent
  if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
  $tmp = "$path.tmp.$([guid]::NewGuid().ToString('N'))"
  [System.IO.File]::WriteAllText($tmp, $text, [System.Text.UTF8Encoding]::new($false))
  Move-Item -LiteralPath $tmp -Destination $path -Force
}

function Get-PrevHash([string]$logPath) {
  if (-not (Test-Path -LiteralPath $logPath)) { return ('0' * 64) }
  $last = Get-Content -LiteralPath $logPath -Tail 200 | Where-Object { $_ -match '\S' } | Select-Object -Last 1
  try { return ((ConvertFrom-Json -InputObject $last).hash) } catch { return ('0' * 64) }
}

function Get-Hash([string]$s) {
  $sha = [System.Security.Cryptography.SHA256]::Create()
  $bytes = [System.Text.Encoding]::UTF8.GetBytes($s)
  ($sha.ComputeHash($bytes) | ForEach-Object { $_.ToString('x2') }) -join ''
}

function Write-KLCLog([string]$repo,[hashtable]$obj) {
  $logDir  = Join-Path $repo 'logs'
  if (-not (Test-Path -LiteralPath $logDir)) { New-Item -ItemType Directory -Path $logDir | Out-Null }
  $logPath = Join-Path $logDir 'apply-log.jsonl'
  $prev    = Get-PrevHash $logPath
  $canon   = ($obj.GetEnumerator() | Sort-Object Name | ForEach-Object { "$($_.Name)=$($_.Value)" }) -join '|'
  $hash    = Get-Hash "$prev|$canon"
  $obj['prevHash'] = $prev
  $obj['hash']     = $hash
  $obj['hashAlgo'] = 'SHA256'
  $obj['canonAlgo']= 'kvc-line-v1'
  $json = ($obj | ConvertTo-Json -Depth 6 -Compress)
  Add-Content -LiteralPath $logPath -Value $json
}

function With-Lock([string]$repo,[scriptblock]$body) {
  $lockPath = Join-Path $repo '.gpt5.lock'
  $mineId   = New-TraceId
  if (Test-Path -LiteralPath $lockPath) {
    $age = (Get-Item -LiteralPath $lockPath).LastWriteTimeUtc
    if ((Get-Date).ToUniversalTime().AddMinutes(-10) -gt $age) {
      Rename-Item -LiteralPath $lockPath -NewName (".gpt5.lock.bak-" + (Get-Ts)) -Force
    } else {
      throw "Lock exists: $lockPath (최근 10분 내 실행 흔적)"
    }
  }
  try {
    Set-Content -LiteralPath $lockPath -NoNewline -Encoding UTF8 -Value $mineId
    & $body
  } finally {
    try {
      $current = ''
      if (Test-Path -LiteralPath $lockPath) { $current = Get-Content -LiteralPath $lockPath -Raw -Encoding UTF8 }
      if ($current -eq $mineId) { Remove-Item -LiteralPath $lockPath -Force -ErrorAction SilentlyContinue }
    } catch { }
  }
}

function Parse-PatchBlocks([string]$text) {
  $lines = $text -split "`n"
  $blocks = @()
  $i = 0
  while ($i -lt $lines.Length) {
    if ($lines[$i].Trim() -eq '# PATCH START') {
      $i++
      $meta = @{}
      $find = ''
      $replace = ''
      while ($i -lt $lines.Length -and -not ($lines[$i].Trim() -eq '# PATCH END')) {
        $L = $lines[$i]
        if ($L -match '^\s*TARGET:\s*(.+)$') { $meta.TARGET = $matches[1].Trim() }
        elseif ($L -match '^\s*MODE:\s*(.+)$') { $meta.MODE = $matches[1].Trim().ToLower() }
        elseif ($L -match '^\s*MULTI:\s*(.+)$') { $meta.MULTI = [bool]::Parse($matches[1].Trim()) }
        elseif ($L -match "^\s*FIND\s+<<'EOF'\s*$") {
          $buf = New-Object System.Text.StringBuilder
          $i++
          while ($i -lt $lines.Length -and -not ($lines[$i].Trim() -eq 'EOF')) {
            [void]$buf.AppendLine($lines[$i])
            $i++
          }
          $find = $buf.ToString()
        }
        elseif ($L -match "^\s*REPLACE\s+<<'EOF'\s*$") {
          $buf = New-Object System.Text.StringBuilder
          $i++
          while ($i -lt $lines.Length -and -not ($lines[$i].Trim() -eq 'EOF')) {
            [void]$buf.AppendLine($lines[$i])
            $i++
          }
          $replace = $buf.ToString()
        }
        $i++
      }
      if (-not $meta.TARGET -or -not $meta.MODE) { throw "PATCH 메타 누락(TARGET/MODE)" }
      $blocks += [pscustomobject]@{
        TARGET  = $meta.TARGET
        MODE    = $meta.MODE
        MULTI   = [bool]($meta.MULTI)
        FIND    = $find
        REPLACE = $replace
      }
    } else { $i++ }
  }
  return ,$blocks
}

function Apply-OnePatch([string]$repo, $blk, [bool]$doApply, [string]$traceId) {
  $target = Join-RepoPath $repo $blk.TARGET
  if (-not (Test-Path -LiteralPath $target)) { return @{ exit=12; msg="PRECONDITION: target not found"; target=$blk.TARGET } }

  $orig = Read-TextUtf8 $target
  $new  = $orig
  $matches = 0
  $changed = $false

  # 멱등(SENTINEL): 이미 REPLACE가 있으면 SKIP
  if (-not [string]::IsNullOrEmpty($blk.REPLACE) -and $orig.Contains($blk.REPLACE)) {
    return @{ exit=10; msg="SKIP: already contains REPLACE"; target=$blk.TARGET; matches=0; changed=$false }
  }

  switch ($blk.MODE) {
    'regex-replace' {
      $rx = [System.Text.RegularExpressions.Regex]::new($blk.FIND, 'Singleline,Multiline')
      $matches = ($rx.Matches($orig)).Count
      if ($matches -eq 0) { return @{ exit=10; msg="SKIP: no match"; target=$blk.TARGET; matches=0; changed=$false } }
      if (-not $blk.MULTI -and $matches -gt 1) { return @{ exit=12; msg="PRECONDITION: multiple matches; set MULTI:true"; target=$blk.TARGET; matches=$matches } }
      if ($blk.MULTI) {
        $new = $rx.Replace($orig, $blk.REPLACE)
      } else {
        $m = $rx.Match($orig)
        $new = $orig.Substring(0, $m.Index) + $m.Result($blk.REPLACE) + $orig.Substring($m.Index + $m.Length)
      }
      $changed = ($new -ne $orig)
    }
    'plain-replace' {
      if (-not $orig.Contains($blk.FIND)) { return @{ exit=10; msg="SKIP: FIND not found"; target=$blk.TARGET; matches=0; changed=$false } }
      if ($blk.MULTI) {
        $new = $orig.Replace($blk.FIND, $blk.REPLACE); $matches = ([regex]::Matches($orig, [regex]::Escape($blk.FIND))).Count
      } else {
        $idx = $orig.IndexOf($blk.FIND)
        $new = $orig.Substring(0,$idx) + $blk.REPLACE + $orig.Substring($idx + $blk.FIND.Length); $matches = 1
      }
      $changed = ($new -ne $orig)
    }
    'insert-after' {
      $rx = [System.Text.RegularExpressions.Regex]::new($blk.FIND, 'Singleline,Multiline')
      $m  = $rx.Match($orig)
      if (-not $m.Success) { return @{ exit=10; msg="SKIP: anchor not found"; target=$blk.TARGET; matches=0; changed=$false } }
      if (-not $blk.MULTI -and $rx.Matches($orig).Count -gt 1) { return @{ exit=12; msg="PRECONDITION: multiple anchors; set MULTI:true"; target=$blk.TARGET } }
      if ($blk.MULTI) {
        $new = $rx.Replace($orig, { param($m) $m.Value + $blk.REPLACE })
        $matches = $rx.Matches($orig).Count
      } else {
        $new = $orig.Substring(0,$m.Index+$m.Length) + $blk.REPLACE + $orig.Substring($m.Index+$m.Length)
        $matches = 1
      }
      $changed = ($new -ne $orig)
    }
    'insert-before' {
      $rx = [System.Text.RegularExpressions.Regex]::new($blk.FIND, 'Singleline,Multiline')
      $m  = $rx.Match($orig)
      if (-not $m.Success) { return @{ exit=10; msg="SKIP: anchor not found"; target=$blk.TARGET; matches=0; changed=$false } }
      if (-not $blk.MULTI -and $rx.Matches($orig).Count -gt 1) { return @{ exit=12; msg="PRECONDITION: multiple anchors; set MULTI:true"; target=$blk.TARGET } }
      if ($blk.MULTI) {
        $new = $rx.Replace($orig, { param($m) $blk.REPLACE + $m.Value })
        $matches = $rx.Matches($orig).Count
      } else {
        $new = $orig.Substring(0,$m.Index) + $blk.REPLACE + $orig.Substring($m.Index)
        $matches = 1
      }
      $changed = ($new -ne $orig)
    }
    default { return @{ exit=12; msg="PRECONDITION: unknown MODE '$($blk.MODE)'" ; target=$blk.TARGET } }
  }

  if (-not $changed) { return @{ exit=10; msg="SKIP: no change"; target=$blk.TARGET; matches=$matches; changed=$false } }

  if ($doApply) {
    # ReadOnly 해제(있다면)
    try {
      $fi = Get-Item -LiteralPath $target -Force
      if ($fi.Attributes.HasFlag([IO.FileAttributes]::ReadOnly)) {
        $fi.Attributes = $fi.Attributes -band (-bnot [IO.FileAttributes]::ReadOnly)
      }
    } catch {}
    $bak = "$target.bak-$(Get-Ts)"
    Copy-Item -LiteralPath $target -Destination $bak -Force
    Write-TextUtf8 -path $target -text $new
    return @{ exit=0; msg="APPLY OK"; target=$blk.TARGET; matches=$matches; backup=$bak; changed=$true }
  } else {
    return @{ exit=11; msg="DRYRUN OK (would change)"; target=$blk.TARGET; matches=$matches; changed=$true }
  }
}

# ---------- Main ----------
$repo = Resolve-RepoRoot $Root
$trace = New-TraceId
$doApply = $ConfirmApply.IsPresent -or ($env:CONFIRM_APPLY -and $env:CONFIRM_APPLY.ToString().ToLower() -eq 'true')

$patchFiles = @()
if ($PatchFile)   { $patchFiles += (Resolve-Path -LiteralPath $PatchFile).Path }
if ($PatchesDir)  { $patchFiles += (Get-ChildItem -LiteralPath $PatchesDir -File -Include *.txt,*.patch,*.patch.txt | Sort-Object FullName | % FullName) }
if (-not $PatchFile -and -not $PatchesDir) { $patchFiles += Get-DefaultPatchList $repo }
if (-not $patchFiles) { throw "패치 파일이 없습니다(.kobong\patches.pending.txt 또는 .kobong\patches\*.txt)" }

$all = @()
foreach ($pf in $patchFiles) {
  $txt = Read-TextUtf8 $pf
  $blocks = Parse-PatchBlocks $txt
  if (-not $blocks -or $blocks.Count -eq 0) { throw "유효한 PATCH 블록이 없습니다: $pf" }
  $all += $blocks
}

$exitMax = 0
$print = { param($o)
  if (-not $Quiet) {
    "{0,-7} | {1} | {2} | matches={3} {4}" -f $o.exit, $o.msg, $o.target, ($o.matches ?? 0), ($(if($o.backup){"| bak=$($o.backup)"}else{""}))
  }
}

With-Lock $repo {
  $start = Get-Date
  foreach ($blk in $all) {
    $res = Apply-OnePatch -repo $repo -blk $blk -doApply:$doApply -traceId $trace
    & $print $res
    if ($res.exit -gt $exitMax) { $exitMax = $res.exit }
    Write-KLCLog $repo @{
      version   = '1.3'
      timestamp = (Get-Date).ToUniversalTime().ToString('o')
      traceId   = $trace
      env       = 'DEV'
      mode      = ($doApply ? 'APPLY' : 'DRYRUN')
      service   = 'apply-patches'
      module    = 'scripts/g5/apply-patches.ps1'
      action    = 'patch'
      outcome   = $res.msg
      exitCode  = $res.exit
      target    = $res.target
      matches   = ($res.matches ?? 0)
      backup    = ($res.backup ?? '')
      durationMs= [int]((Get-Date) - $start).TotalMilliseconds
      message   = $res.msg
    }
  }
}

if ($exitMax -eq 11 -and -not $doApply) { exit 11 }        # DRYRUN only
elseif ($exitMax -in 12,13)           { exit $exitMax }     # PRECONDITION/CONFLICT
elseif ($exitMax -eq 0)               { exit 0 }            # all good
elseif ($exitMax -eq 10)              { exit 0 }            # all skipped -> OK
else                                  { exit 1 }            # unknown -> ERROR
.Name -match '\.(txt|patch|patch\.txt)
if (-not $PatchFile -and -not $PatchesDir) { $patchFiles += Get-DefaultPatchList $repo }
if (-not $patchFiles) { throw "패치 파일이 없습니다(.kobong\patches.pending.txt 또는 .kobong\patches\*.txt)" }

$all = @()
foreach ($pf in $patchFiles) {
  $txt = Read-TextUtf8 $pf
  $blocks = Parse-PatchBlocks $txt
  if (-not $blocks -or $blocks.Count -eq 0) { throw "유효한 PATCH 블록이 없습니다: $pf" }
  $all += $blocks
}

$exitMax = 0
$print = { param($o)
  if (-not $Quiet) {
    "{0,-7} | {1} | {2} | matches={3} {4}" -f $o.exit, $o.msg, $o.target, ($o.matches ?? 0), ($(if($o.backup){"| bak=$($o.backup)"}else{""}))
  }
}

With-Lock $repo {
  $start = Get-Date
  foreach ($blk in $all) {
    $res = Apply-OnePatch -repo $repo -blk $blk -doApply:$doApply -traceId $trace
    & $print $res
    if ($res.exit -gt $exitMax) { $exitMax = $res.exit }
    Write-KLCLog $repo @{
      version   = '1.3'
      timestamp = (Get-Date).ToUniversalTime().ToString('o')
      traceId   = $trace
      env       = 'DEV'
      mode      = ($doApply ? 'APPLY' : 'DRYRUN')
      service   = 'apply-patches'
      module    = 'scripts/g5/apply-patches.ps1'
      action    = 'patch'
      outcome   = $res.msg
      exitCode  = $res.exit
      target    = $res.target
      matches   = ($res.matches ?? 0)
      backup    = ($res.backup ?? '')
      durationMs= [int]((Get-Date) - $start).TotalMilliseconds
      message   = $res.msg
    }
  }
}

if ($exitMax -eq 11 -and -not $doApply) { exit 11 }        # DRYRUN only
elseif ($exitMax -in 12,13)           { exit $exitMax }     # PRECONDITION/CONFLICT
elseif ($exitMax -eq 0)               { exit 0 }            # all good
elseif ($exitMax -eq 10)              { exit 0 }            # all skipped -> OK
else                                  { exit 1 }            # unknown -> ERROR
.Name -match '\.(txt|patch|patch\.txt)
  return $list
}

function Read-TextUtf8([string]$path) {
  return Get-Content -LiteralPath $path -Raw -Encoding UTF8
}

function Write-TextUtf8([string]$path,[string]$text) {
  $dir = Split-Path -LiteralPath $path -Parent
  if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
  $tmp = "$path.tmp.$([guid]::NewGuid().ToString('N'))"
  [System.IO.File]::WriteAllText($tmp, $text, [System.Text.UTF8Encoding]::new($false))
  Move-Item -LiteralPath $tmp -Destination $path -Force
}

function Get-PrevHash([string]$logPath) {
  if (-not (Test-Path -LiteralPath $logPath)) { return ('0' * 64) }
  $last = Get-Content -LiteralPath $logPath -Tail 200 | Where-Object { $_ -match '\S' } | Select-Object -Last 1
  try { return ((ConvertFrom-Json -InputObject $last).hash) } catch { return ('0' * 64) }
}

function Get-Hash([string]$s) {
  $sha = [System.Security.Cryptography.SHA256]::Create()
  $bytes = [System.Text.Encoding]::UTF8.GetBytes($s)
  ($sha.ComputeHash($bytes) | ForEach-Object { $_.ToString('x2') }) -join ''
}

function Write-KLCLog([string]$repo,[hashtable]$obj) {
  $logDir  = Join-Path $repo 'logs'
  if (-not (Test-Path -LiteralPath $logDir)) { New-Item -ItemType Directory -Path $logDir | Out-Null }
  $logPath = Join-Path $logDir 'apply-log.jsonl'
  $prev    = Get-PrevHash $logPath
  $canon   = ($obj.GetEnumerator() | Sort-Object Name | ForEach-Object { "$($_.Name)=$($_.Value)" }) -join '|'
  $hash    = Get-Hash "$prev|$canon"
  $obj['prevHash'] = $prev
  $obj['hash']     = $hash
  $obj['hashAlgo'] = 'SHA256'
  $obj['canonAlgo']= 'kvc-line-v1'
  $json = ($obj | ConvertTo-Json -Depth 6 -Compress)
  Add-Content -LiteralPath $logPath -Value $json
}

function With-Lock([string]$repo,[scriptblock]$body) {
  $lockPath = Join-Path $repo '.gpt5.lock'
  $mineId   = New-TraceId
  if (Test-Path -LiteralPath $lockPath) {
    $age = (Get-Item -LiteralPath $lockPath).LastWriteTimeUtc
    if ((Get-Date).ToUniversalTime().AddMinutes(-10) -gt $age) {
      Rename-Item -LiteralPath $lockPath -NewName (".gpt5.lock.bak-" + (Get-Ts)) -Force
    } else {
      throw "Lock exists: $lockPath (최근 10분 내 실행 흔적)"
    }
  }
  try {
    Set-Content -LiteralPath $lockPath -NoNewline -Encoding UTF8 -Value $mineId
    & $body
  } finally {
    try {
      $current = ''
      if (Test-Path -LiteralPath $lockPath) { $current = Get-Content -LiteralPath $lockPath -Raw -Encoding UTF8 }
      if ($current -eq $mineId) { Remove-Item -LiteralPath $lockPath -Force -ErrorAction SilentlyContinue }
    } catch { }
  }
}

function Parse-PatchBlocks([string]$text) {
  $lines = $text -split "`n"
  $blocks = @()
  $i = 0
  while ($i -lt $lines.Length) {
    if ($lines[$i].Trim() -eq '# PATCH START') {
      $i++
      $meta = @{}
      $find = ''
      $replace = ''
      while ($i -lt $lines.Length -and -not ($lines[$i].Trim() -eq '# PATCH END')) {
        $L = $lines[$i]
        if ($L -match '^\s*TARGET:\s*(.+)$') { $meta.TARGET = $matches[1].Trim() }
        elseif ($L -match '^\s*MODE:\s*(.+)$') { $meta.MODE = $matches[1].Trim().ToLower() }
        elseif ($L -match '^\s*MULTI:\s*(.+)$') { $meta.MULTI = [bool]::Parse($matches[1].Trim()) }
        elseif ($L -match "^\s*FIND\s+<<'EOF'\s*$") {
          $buf = New-Object System.Text.StringBuilder
          $i++
          while ($i -lt $lines.Length -and -not ($lines[$i].Trim() -eq 'EOF')) {
            [void]$buf.AppendLine($lines[$i])
            $i++
          }
          $find = $buf.ToString()
        }
        elseif ($L -match "^\s*REPLACE\s+<<'EOF'\s*$") {
          $buf = New-Object System.Text.StringBuilder
          $i++
          while ($i -lt $lines.Length -and -not ($lines[$i].Trim() -eq 'EOF')) {
            [void]$buf.AppendLine($lines[$i])
            $i++
          }
          $replace = $buf.ToString()
        }
        $i++
      }
      if (-not $meta.TARGET -or -not $meta.MODE) { throw "PATCH 메타 누락(TARGET/MODE)" }
      $blocks += [pscustomobject]@{
        TARGET  = $meta.TARGET
        MODE    = $meta.MODE
        MULTI   = [bool]($meta.MULTI)
        FIND    = $find
        REPLACE = $replace
      }
    } else { $i++ }
  }
  return ,$blocks
}

function Apply-OnePatch([string]$repo, $blk, [bool]$doApply, [string]$traceId) {
  $target = Join-RepoPath $repo $blk.TARGET
  if (-not (Test-Path -LiteralPath $target)) { return @{ exit=12; msg="PRECONDITION: target not found"; target=$blk.TARGET } }

  $orig = Read-TextUtf8 $target
  $new  = $orig
  $matches = 0
  $changed = $false

  # 멱등(SENTINEL): 이미 REPLACE가 있으면 SKIP
  if (-not [string]::IsNullOrEmpty($blk.REPLACE) -and $orig.Contains($blk.REPLACE)) {
    return @{ exit=10; msg="SKIP: already contains REPLACE"; target=$blk.TARGET; matches=0; changed=$false }
  }

  switch ($blk.MODE) {
    'regex-replace' {
      $rx = [System.Text.RegularExpressions.Regex]::new($blk.FIND, 'Singleline,Multiline')
      $matches = ($rx.Matches($orig)).Count
      if ($matches -eq 0) { return @{ exit=10; msg="SKIP: no match"; target=$blk.TARGET; matches=0; changed=$false } }
      if (-not $blk.MULTI -and $matches -gt 1) { return @{ exit=12; msg="PRECONDITION: multiple matches; set MULTI:true"; target=$blk.TARGET; matches=$matches } }
      if ($blk.MULTI) {
        $new = $rx.Replace($orig, $blk.REPLACE)
      } else {
        $m = $rx.Match($orig)
        $new = $orig.Substring(0, $m.Index) + $m.Result($blk.REPLACE) + $orig.Substring($m.Index + $m.Length)
      }
      $changed = ($new -ne $orig)
    }
    'plain-replace' {
      if (-not $orig.Contains($blk.FIND)) { return @{ exit=10; msg="SKIP: FIND not found"; target=$blk.TARGET; matches=0; changed=$false } }
      if ($blk.MULTI) {
        $new = $orig.Replace($blk.FIND, $blk.REPLACE); $matches = ([regex]::Matches($orig, [regex]::Escape($blk.FIND))).Count
      } else {
        $idx = $orig.IndexOf($blk.FIND)
        $new = $orig.Substring(0,$idx) + $blk.REPLACE + $orig.Substring($idx + $blk.FIND.Length); $matches = 1
      }
      $changed = ($new -ne $orig)
    }
    'insert-after' {
      $rx = [System.Text.RegularExpressions.Regex]::new($blk.FIND, 'Singleline,Multiline')
      $m  = $rx.Match($orig)
      if (-not $m.Success) { return @{ exit=10; msg="SKIP: anchor not found"; target=$blk.TARGET; matches=0; changed=$false } }
      if (-not $blk.MULTI -and $rx.Matches($orig).Count -gt 1) { return @{ exit=12; msg="PRECONDITION: multiple anchors; set MULTI:true"; target=$blk.TARGET } }
      if ($blk.MULTI) {
        $new = $rx.Replace($orig, { param($m) $m.Value + $blk.REPLACE })
        $matches = $rx.Matches($orig).Count
      } else {
        $new = $orig.Substring(0,$m.Index+$m.Length) + $blk.REPLACE + $orig.Substring($m.Index+$m.Length)
        $matches = 1
      }
      $changed = ($new -ne $orig)
    }
    'insert-before' {
      $rx = [System.Text.RegularExpressions.Regex]::new($blk.FIND, 'Singleline,Multiline')
      $m  = $rx.Match($orig)
      if (-not $m.Success) { return @{ exit=10; msg="SKIP: anchor not found"; target=$blk.TARGET; matches=0; changed=$false } }
      if (-not $blk.MULTI -and $rx.Matches($orig).Count -gt 1) { return @{ exit=12; msg="PRECONDITION: multiple anchors; set MULTI:true"; target=$blk.TARGET } }
      if ($blk.MULTI) {
        $new = $rx.Replace($orig, { param($m) $blk.REPLACE + $m.Value })
        $matches = $rx.Matches($orig).Count
      } else {
        $new = $orig.Substring(0,$m.Index) + $blk.REPLACE + $orig.Substring($m.Index)
        $matches = 1
      }
      $changed = ($new -ne $orig)
    }
    default { return @{ exit=12; msg="PRECONDITION: unknown MODE '$($blk.MODE)'" ; target=$blk.TARGET } }
  }

  if (-not $changed) { return @{ exit=10; msg="SKIP: no change"; target=$blk.TARGET; matches=$matches; changed=$false } }

  if ($doApply) {
    # ReadOnly 해제(있다면)
    try {
      $fi = Get-Item -LiteralPath $target -Force
      if ($fi.Attributes.HasFlag([IO.FileAttributes]::ReadOnly)) {
        $fi.Attributes = $fi.Attributes -band (-bnot [IO.FileAttributes]::ReadOnly)
      }
    } catch {}
    $bak = "$target.bak-$(Get-Ts)"
    Copy-Item -LiteralPath $target -Destination $bak -Force
    Write-TextUtf8 -path $target -text $new
    return @{ exit=0; msg="APPLY OK"; target=$blk.TARGET; matches=$matches; backup=$bak; changed=$true }
  } else {
    return @{ exit=11; msg="DRYRUN OK (would change)"; target=$blk.TARGET; matches=$matches; changed=$true }
  }
}

# ---------- Main ----------
$repo = Resolve-RepoRoot $Root
$trace = New-TraceId
$doApply = $ConfirmApply.IsPresent -or ($env:CONFIRM_APPLY -and $env:CONFIRM_APPLY.ToString().ToLower() -eq 'true')

$patchFiles = @()
if ($PatchFile)   { $patchFiles += (Resolve-Path -LiteralPath $PatchFile).Path }
if ($PatchesDir)  { $patchFiles += (Get-ChildItem -LiteralPath $PatchesDir -File -Include *.txt,*.patch,*.patch.txt | Sort-Object FullName | % FullName) }
if (-not $PatchFile -and -not $PatchesDir) { $patchFiles += Get-DefaultPatchList $repo }
if (-not $patchFiles) { throw "패치 파일이 없습니다(.kobong\patches.pending.txt 또는 .kobong\patches\*.txt)" }

$all = @()
foreach ($pf in $patchFiles) {
  $txt = Read-TextUtf8 $pf
  $blocks = Parse-PatchBlocks $txt
  if (-not $blocks -or $blocks.Count -eq 0) { throw "유효한 PATCH 블록이 없습니다: $pf" }
  $all += $blocks
}

$exitMax = 0
$print = { param($o)
  if (-not $Quiet) {
    "{0,-7} | {1} | {2} | matches={3} {4}" -f $o.exit, $o.msg, $o.target, ($o.matches ?? 0), ($(if($o.backup){"| bak=$($o.backup)"}else{""}))
  }
}

With-Lock $repo {
  $start = Get-Date
  foreach ($blk in $all) {
    $res = Apply-OnePatch -repo $repo -blk $blk -doApply:$doApply -traceId $trace
    & $print $res
    if ($res.exit -gt $exitMax) { $exitMax = $res.exit }
    Write-KLCLog $repo @{
      version   = '1.3'
      timestamp = (Get-Date).ToUniversalTime().ToString('o')
      traceId   = $trace
      env       = 'DEV'
      mode      = ($doApply ? 'APPLY' : 'DRYRUN')
      service   = 'apply-patches'
      module    = 'scripts/g5/apply-patches.ps1'
      action    = 'patch'
      outcome   = $res.msg
      exitCode  = $res.exit
      target    = $res.target
      matches   = ($res.matches ?? 0)
      backup    = ($res.backup ?? '')
      durationMs= [int]((Get-Date) - $start).TotalMilliseconds
      message   = $res.msg
    }
  }
}

if ($exitMax -eq 11 -and -not $doApply) { exit 11 }        # DRYRUN only
elseif ($exitMax -in 12,13)           { exit $exitMax }     # PRECONDITION/CONFLICT
elseif ($exitMax -eq 0)               { exit 0 }            # all good
elseif ($exitMax -eq 10)              { exit 0 }            # all skipped -> OK
else                                  { exit 1 }            # unknown -> ERROR
 } |
           Sort-Object FullName
  foreach ($f in $files) { [void]$list.Add($f.FullName) }
}
  return $list
}

function Read-TextUtf8([string]$path) {
  return Get-Content -LiteralPath $path -Raw -Encoding UTF8
}

function Write-TextUtf8([string]$path,[string]$text) {
  $dir = Split-Path -LiteralPath $path -Parent
  if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
  $tmp = "$path.tmp.$([guid]::NewGuid().ToString('N'))"
  [System.IO.File]::WriteAllText($tmp, $text, [System.Text.UTF8Encoding]::new($false))
  Move-Item -LiteralPath $tmp -Destination $path -Force
}

function Get-PrevHash([string]$logPath) {
  if (-not (Test-Path -LiteralPath $logPath)) { return ('0' * 64) }
  $last = Get-Content -LiteralPath $logPath -Tail 200 | Where-Object { $_ -match '\S' } | Select-Object -Last 1
  try { return ((ConvertFrom-Json -InputObject $last).hash) } catch { return ('0' * 64) }
}

function Get-Hash([string]$s) {
  $sha = [System.Security.Cryptography.SHA256]::Create()
  $bytes = [System.Text.Encoding]::UTF8.GetBytes($s)
  ($sha.ComputeHash($bytes) | ForEach-Object { $_.ToString('x2') }) -join ''
}

function Write-KLCLog([string]$repo,[hashtable]$obj) {
  $logDir  = Join-Path $repo 'logs'
  if (-not (Test-Path -LiteralPath $logDir)) { New-Item -ItemType Directory -Path $logDir | Out-Null }
  $logPath = Join-Path $logDir 'apply-log.jsonl'
  $prev    = Get-PrevHash $logPath
  $canon   = ($obj.GetEnumerator() | Sort-Object Name | ForEach-Object { "$($_.Name)=$($_.Value)" }) -join '|'
  $hash    = Get-Hash "$prev|$canon"
  $obj['prevHash'] = $prev
  $obj['hash']     = $hash
  $obj['hashAlgo'] = 'SHA256'
  $obj['canonAlgo']= 'kvc-line-v1'
  $json = ($obj | ConvertTo-Json -Depth 6 -Compress)
  Add-Content -LiteralPath $logPath -Value $json
}

function With-Lock([string]$repo,[scriptblock]$body) {
  $lockPath = Join-Path $repo '.gpt5.lock'
  $mineId   = New-TraceId
  if (Test-Path -LiteralPath $lockPath) {
    $age = (Get-Item -LiteralPath $lockPath).LastWriteTimeUtc
    if ((Get-Date).ToUniversalTime().AddMinutes(-10) -gt $age) {
      Rename-Item -LiteralPath $lockPath -NewName (".gpt5.lock.bak-" + (Get-Ts)) -Force
    } else {
      throw "Lock exists: $lockPath (최근 10분 내 실행 흔적)"
    }
  }
  try {
    Set-Content -LiteralPath $lockPath -NoNewline -Encoding UTF8 -Value $mineId
    & $body
  } finally {
    try {
      $current = ''
      if (Test-Path -LiteralPath $lockPath) { $current = Get-Content -LiteralPath $lockPath -Raw -Encoding UTF8 }
      if ($current -eq $mineId) { Remove-Item -LiteralPath $lockPath -Force -ErrorAction SilentlyContinue }
    } catch { }
  }
}

function Parse-PatchBlocks([string]$text) {
  $lines = $text -split "`n"
  $blocks = @()
  $i = 0
  while ($i -lt $lines.Length) {
    if ($lines[$i].Trim() -eq '# PATCH START') {
      $i++
      $meta = @{}
      $find = ''
      $replace = ''
      while ($i -lt $lines.Length -and -not ($lines[$i].Trim() -eq '# PATCH END')) {
        $L = $lines[$i]
        if ($L -match '^\s*TARGET:\s*(.+)$') { $meta.TARGET = $matches[1].Trim() }
        elseif ($L -match '^\s*MODE:\s*(.+)$') { $meta.MODE = $matches[1].Trim().ToLower() }
        elseif ($L -match '^\s*MULTI:\s*(.+)$') { $meta.MULTI = [bool]::Parse($matches[1].Trim()) }
        elseif ($L -match "^\s*FIND\s+<<'EOF'\s*$") {
          $buf = New-Object System.Text.StringBuilder
          $i++
          while ($i -lt $lines.Length -and -not ($lines[$i].Trim() -eq 'EOF')) {
            [void]$buf.AppendLine($lines[$i])
            $i++
          }
          $find = $buf.ToString()
        }
        elseif ($L -match "^\s*REPLACE\s+<<'EOF'\s*$") {
          $buf = New-Object System.Text.StringBuilder
          $i++
          while ($i -lt $lines.Length -and -not ($lines[$i].Trim() -eq 'EOF')) {
            [void]$buf.AppendLine($lines[$i])
            $i++
          }
          $replace = $buf.ToString()
        }
        $i++
      }
      if (-not $meta.TARGET -or -not $meta.MODE) { throw "PATCH 메타 누락(TARGET/MODE)" }
      $blocks += [pscustomobject]@{
        TARGET  = $meta.TARGET
        MODE    = $meta.MODE
        MULTI   = [bool]($meta.MULTI)
        FIND    = $find
        REPLACE = $replace
      }
    } else { $i++ }
  }
  return ,$blocks
}

function Apply-OnePatch([string]$repo, $blk, [bool]$doApply, [string]$traceId) {
  $target = Join-RepoPath $repo $blk.TARGET
  if (-not (Test-Path -LiteralPath $target)) { return @{ exit=12; msg="PRECONDITION: target not found"; target=$blk.TARGET } }

  $orig = Read-TextUtf8 $target
  $new  = $orig
  $matches = 0
  $changed = $false

  # 멱등(SENTINEL): 이미 REPLACE가 있으면 SKIP
  if (-not [string]::IsNullOrEmpty($blk.REPLACE) -and $orig.Contains($blk.REPLACE)) {
    return @{ exit=10; msg="SKIP: already contains REPLACE"; target=$blk.TARGET; matches=0; changed=$false }
  }

  switch ($blk.MODE) {
    'regex-replace' {
      $rx = [System.Text.RegularExpressions.Regex]::new($blk.FIND, 'Singleline,Multiline')
      $matches = ($rx.Matches($orig)).Count
      if ($matches -eq 0) { return @{ exit=10; msg="SKIP: no match"; target=$blk.TARGET; matches=0; changed=$false } }
      if (-not $blk.MULTI -and $matches -gt 1) { return @{ exit=12; msg="PRECONDITION: multiple matches; set MULTI:true"; target=$blk.TARGET; matches=$matches } }
      if ($blk.MULTI) {
        $new = $rx.Replace($orig, $blk.REPLACE)
      } else {
        $m = $rx.Match($orig)
        $new = $orig.Substring(0, $m.Index) + $m.Result($blk.REPLACE) + $orig.Substring($m.Index + $m.Length)
      }
      $changed = ($new -ne $orig)
    }
    'plain-replace' {
      if (-not $orig.Contains($blk.FIND)) { return @{ exit=10; msg="SKIP: FIND not found"; target=$blk.TARGET; matches=0; changed=$false } }
      if ($blk.MULTI) {
        $new = $orig.Replace($blk.FIND, $blk.REPLACE); $matches = ([regex]::Matches($orig, [regex]::Escape($blk.FIND))).Count
      } else {
        $idx = $orig.IndexOf($blk.FIND)
        $new = $orig.Substring(0,$idx) + $blk.REPLACE + $orig.Substring($idx + $blk.FIND.Length); $matches = 1
      }
      $changed = ($new -ne $orig)
    }
    'insert-after' {
      $rx = [System.Text.RegularExpressions.Regex]::new($blk.FIND, 'Singleline,Multiline')
      $m  = $rx.Match($orig)
      if (-not $m.Success) { return @{ exit=10; msg="SKIP: anchor not found"; target=$blk.TARGET; matches=0; changed=$false } }
      if (-not $blk.MULTI -and $rx.Matches($orig).Count -gt 1) { return @{ exit=12; msg="PRECONDITION: multiple anchors; set MULTI:true"; target=$blk.TARGET } }
      if ($blk.MULTI) {
        $new = $rx.Replace($orig, { param($m) $m.Value + $blk.REPLACE })
        $matches = $rx.Matches($orig).Count
      } else {
        $new = $orig.Substring(0,$m.Index+$m.Length) + $blk.REPLACE + $orig.Substring($m.Index+$m.Length)
        $matches = 1
      }
      $changed = ($new -ne $orig)
    }
    'insert-before' {
      $rx = [System.Text.RegularExpressions.Regex]::new($blk.FIND, 'Singleline,Multiline')
      $m  = $rx.Match($orig)
      if (-not $m.Success) { return @{ exit=10; msg="SKIP: anchor not found"; target=$blk.TARGET; matches=0; changed=$false } }
      if (-not $blk.MULTI -and $rx.Matches($orig).Count -gt 1) { return @{ exit=12; msg="PRECONDITION: multiple anchors; set MULTI:true"; target=$blk.TARGET } }
      if ($blk.MULTI) {
        $new = $rx.Replace($orig, { param($m) $blk.REPLACE + $m.Value })
        $matches = $rx.Matches($orig).Count
      } else {
        $new = $orig.Substring(0,$m.Index) + $blk.REPLACE + $orig.Substring($m.Index)
        $matches = 1
      }
      $changed = ($new -ne $orig)
    }
    default { return @{ exit=12; msg="PRECONDITION: unknown MODE '$($blk.MODE)'" ; target=$blk.TARGET } }
  }

  if (-not $changed) { return @{ exit=10; msg="SKIP: no change"; target=$blk.TARGET; matches=$matches; changed=$false } }

  if ($doApply) {
    # ReadOnly 해제(있다면)
    try {
      $fi = Get-Item -LiteralPath $target -Force
      if ($fi.Attributes.HasFlag([IO.FileAttributes]::ReadOnly)) {
        $fi.Attributes = $fi.Attributes -band (-bnot [IO.FileAttributes]::ReadOnly)
      }
    } catch {}
    $bak = "$target.bak-$(Get-Ts)"
    Copy-Item -LiteralPath $target -Destination $bak -Force
    Write-TextUtf8 -path $target -text $new
    return @{ exit=0; msg="APPLY OK"; target=$blk.TARGET; matches=$matches; backup=$bak; changed=$true }
  } else {
    return @{ exit=11; msg="DRYRUN OK (would change)"; target=$blk.TARGET; matches=$matches; changed=$true }
  }
}

# ---------- Main ----------
$repo = Resolve-RepoRoot $Root
$trace = New-TraceId
$doApply = $ConfirmApply.IsPresent -or ($env:CONFIRM_APPLY -and $env:CONFIRM_APPLY.ToString().ToLower() -eq 'true')

$patchFiles = @()
if ($PatchFile)   { $patchFiles += (Resolve-Path -LiteralPath $PatchFile).Path }
if ($PatchesDir)  { $patchFiles += (Get-ChildItem -LiteralPath $PatchesDir -File -Include *.txt,*.patch,*.patch.txt | Sort-Object FullName | % FullName) }
if (-not $PatchFile -and -not $PatchesDir) { $patchFiles += Get-DefaultPatchList $repo }
if (-not $patchFiles) { throw "패치 파일이 없습니다(.kobong\patches.pending.txt 또는 .kobong\patches\*.txt)" }

$all = @()
foreach ($pf in $patchFiles) {
  $txt = Read-TextUtf8 $pf
  $blocks = Parse-PatchBlocks $txt
  if (-not $blocks -or $blocks.Count -eq 0) { throw "유효한 PATCH 블록이 없습니다: $pf" }
  $all += $blocks
}

$exitMax = 0
$print = { param($o)
  if (-not $Quiet) {
    "{0,-7} | {1} | {2} | matches={3} {4}" -f $o.exit, $o.msg, $o.target, ($o.matches ?? 0), ($(if($o.backup){"| bak=$($o.backup)"}else{""}))
  }
}

With-Lock $repo {
  $start = Get-Date
  foreach ($blk in $all) {
    $res = Apply-OnePatch -repo $repo -blk $blk -doApply:$doApply -traceId $trace
    & $print $res
    if ($res.exit -gt $exitMax) { $exitMax = $res.exit }
    Write-KLCLog $repo @{
      version   = '1.3'
      timestamp = (Get-Date).ToUniversalTime().ToString('o')
      traceId   = $trace
      env       = 'DEV'
      mode      = ($doApply ? 'APPLY' : 'DRYRUN')
      service   = 'apply-patches'
      module    = 'scripts/g5/apply-patches.ps1'
      action    = 'patch'
      outcome   = $res.msg
      exitCode  = $res.exit
      target    = $res.target
      matches   = ($res.matches ?? 0)
      backup    = ($res.backup ?? '')
      durationMs= [int]((Get-Date) - $start).TotalMilliseconds
      message   = $res.msg
    }
  }
}

if ($exitMax -eq 11 -and -not $doApply) { exit 11 }        # DRYRUN only
elseif ($exitMax -in 12,13)           { exit $exitMax }     # PRECONDITION/CONFLICT
elseif ($exitMax -eq 0)               { exit 0 }            # all good
elseif ($exitMax -eq 10)              { exit 0 }            # all skipped -> OK
else                                  { exit 1 }            # unknown -> ERROR
 } |
           Sort-Object FullName
  $patchFiles += $files.FullName
}
if (-not $PatchFile -and -not $PatchesDir) { $patchFiles += Get-DefaultPatchList $repo }
if (-not $patchFiles) { throw "패치 파일이 없습니다(.kobong\patches.pending.txt 또는 .kobong\patches\*.txt)" }

$all = @()
foreach ($pf in $patchFiles) {
  $txt = Read-TextUtf8 $pf
  $blocks = Parse-PatchBlocks $txt
  if (-not $blocks -or $blocks.Count -eq 0) { throw "유효한 PATCH 블록이 없습니다: $pf" }
  $all += $blocks
}

$exitMax = 0
$print = { param($o)
  if (-not $Quiet) {
    "{0,-7} | {1} | {2} | matches={3} {4}" -f $o.exit, $o.msg, $o.target, ($o.matches ?? 0), ($(if($o.backup){"| bak=$($o.backup)"}else{""}))
  }
}

With-Lock $repo {
  $start = Get-Date
  foreach ($blk in $all) {
    $res = Apply-OnePatch -repo $repo -blk $blk -doApply:$doApply -traceId $trace
    & $print $res
    if ($res.exit -gt $exitMax) { $exitMax = $res.exit }
    Write-KLCLog $repo @{
      version   = '1.3'
      timestamp = (Get-Date).ToUniversalTime().ToString('o')
      traceId   = $trace
      env       = 'DEV'
      mode      = ($doApply ? 'APPLY' : 'DRYRUN')
      service   = 'apply-patches'
      module    = 'scripts/g5/apply-patches.ps1'
      action    = 'patch'
      outcome   = $res.msg
      exitCode  = $res.exit
      target    = $res.target
      matches   = ($res.matches ?? 0)
      backup    = ($res.backup ?? '')
      durationMs= [int]((Get-Date) - $start).TotalMilliseconds
      message   = $res.msg
    }
  }
}

if ($exitMax -eq 11 -and -not $doApply) { exit 11 }        # DRYRUN only
elseif ($exitMax -in 12,13)           { exit $exitMax }     # PRECONDITION/CONFLICT
elseif ($exitMax -eq 0)               { exit 0 }            # all good
elseif ($exitMax -eq 10)              { exit 0 }            # all skipped -> OK
else                                  { exit 1 }            # unknown -> ERROR
.Name -match '\.(txt|patch|patch\.txt)
  return $list
}

function Read-TextUtf8([string]$path) {
  return Get-Content -LiteralPath $path -Raw -Encoding UTF8
}

function Write-TextUtf8([string]$path,[string]$text) {
  $dir = Split-Path -LiteralPath $path -Parent
  if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
  $tmp = "$path.tmp.$([guid]::NewGuid().ToString('N'))"
  [System.IO.File]::WriteAllText($tmp, $text, [System.Text.UTF8Encoding]::new($false))
  Move-Item -LiteralPath $tmp -Destination $path -Force
}

function Get-PrevHash([string]$logPath) {
  if (-not (Test-Path -LiteralPath $logPath)) { return ('0' * 64) }
  $last = Get-Content -LiteralPath $logPath -Tail 200 | Where-Object { $_ -match '\S' } | Select-Object -Last 1
  try { return ((ConvertFrom-Json -InputObject $last).hash) } catch { return ('0' * 64) }
}

function Get-Hash([string]$s) {
  $sha = [System.Security.Cryptography.SHA256]::Create()
  $bytes = [System.Text.Encoding]::UTF8.GetBytes($s)
  ($sha.ComputeHash($bytes) | ForEach-Object { $_.ToString('x2') }) -join ''
}

function Write-KLCLog([string]$repo,[hashtable]$obj) {
  $logDir  = Join-Path $repo 'logs'
  if (-not (Test-Path -LiteralPath $logDir)) { New-Item -ItemType Directory -Path $logDir | Out-Null }
  $logPath = Join-Path $logDir 'apply-log.jsonl'
  $prev    = Get-PrevHash $logPath
  $canon   = ($obj.GetEnumerator() | Sort-Object Name | ForEach-Object { "$($_.Name)=$($_.Value)" }) -join '|'
  $hash    = Get-Hash "$prev|$canon"
  $obj['prevHash'] = $prev
  $obj['hash']     = $hash
  $obj['hashAlgo'] = 'SHA256'
  $obj['canonAlgo']= 'kvc-line-v1'
  $json = ($obj | ConvertTo-Json -Depth 6 -Compress)
  Add-Content -LiteralPath $logPath -Value $json
}

function With-Lock([string]$repo,[scriptblock]$body) {
  $lockPath = Join-Path $repo '.gpt5.lock'
  $mineId   = New-TraceId
  if (Test-Path -LiteralPath $lockPath) {
    $age = (Get-Item -LiteralPath $lockPath).LastWriteTimeUtc
    if ((Get-Date).ToUniversalTime().AddMinutes(-10) -gt $age) {
      Rename-Item -LiteralPath $lockPath -NewName (".gpt5.lock.bak-" + (Get-Ts)) -Force
    } else {
      throw "Lock exists: $lockPath (최근 10분 내 실행 흔적)"
    }
  }
  try {
    Set-Content -LiteralPath $lockPath -NoNewline -Encoding UTF8 -Value $mineId
    & $body
  } finally {
    try {
      $current = ''
      if (Test-Path -LiteralPath $lockPath) { $current = Get-Content -LiteralPath $lockPath -Raw -Encoding UTF8 }
      if ($current -eq $mineId) { Remove-Item -LiteralPath $lockPath -Force -ErrorAction SilentlyContinue }
    } catch { }
  }
}

function Parse-PatchBlocks([string]$text) {
  $lines = $text -split "`n"
  $blocks = @()
  $i = 0
  while ($i -lt $lines.Length) {
    if ($lines[$i].Trim() -eq '# PATCH START') {
      $i++
      $meta = @{}
      $find = ''
      $replace = ''
      while ($i -lt $lines.Length -and -not ($lines[$i].Trim() -eq '# PATCH END')) {
        $L = $lines[$i]
        if ($L -match '^\s*TARGET:\s*(.+)$') { $meta.TARGET = $matches[1].Trim() }
        elseif ($L -match '^\s*MODE:\s*(.+)$') { $meta.MODE = $matches[1].Trim().ToLower() }
        elseif ($L -match '^\s*MULTI:\s*(.+)$') { $meta.MULTI = [bool]::Parse($matches[1].Trim()) }
        elseif ($L -match "^\s*FIND\s+<<'EOF'\s*$") {
          $buf = New-Object System.Text.StringBuilder
          $i++
          while ($i -lt $lines.Length -and -not ($lines[$i].Trim() -eq 'EOF')) {
            [void]$buf.AppendLine($lines[$i])
            $i++
          }
          $find = $buf.ToString()
        }
        elseif ($L -match "^\s*REPLACE\s+<<'EOF'\s*$") {
          $buf = New-Object System.Text.StringBuilder
          $i++
          while ($i -lt $lines.Length -and -not ($lines[$i].Trim() -eq 'EOF')) {
            [void]$buf.AppendLine($lines[$i])
            $i++
          }
          $replace = $buf.ToString()
        }
        $i++
      }
      if (-not $meta.TARGET -or -not $meta.MODE) { throw "PATCH 메타 누락(TARGET/MODE)" }
      $blocks += [pscustomobject]@{
        TARGET  = $meta.TARGET
        MODE    = $meta.MODE
        MULTI   = [bool]($meta.MULTI)
        FIND    = $find
        REPLACE = $replace
      }
    } else { $i++ }
  }
  return ,$blocks
}

function Apply-OnePatch([string]$repo, $blk, [bool]$doApply, [string]$traceId) {
  $target = Join-RepoPath $repo $blk.TARGET
  if (-not (Test-Path -LiteralPath $target)) { return @{ exit=12; msg="PRECONDITION: target not found"; target=$blk.TARGET } }

  $orig = Read-TextUtf8 $target
  $new  = $orig
  $matches = 0
  $changed = $false

  # 멱등(SENTINEL): 이미 REPLACE가 있으면 SKIP
  if (-not [string]::IsNullOrEmpty($blk.REPLACE) -and $orig.Contains($blk.REPLACE)) {
    return @{ exit=10; msg="SKIP: already contains REPLACE"; target=$blk.TARGET; matches=0; changed=$false }
  }

  switch ($blk.MODE) {
    'regex-replace' {
      $rx = [System.Text.RegularExpressions.Regex]::new($blk.FIND, 'Singleline,Multiline')
      $matches = ($rx.Matches($orig)).Count
      if ($matches -eq 0) { return @{ exit=10; msg="SKIP: no match"; target=$blk.TARGET; matches=0; changed=$false } }
      if (-not $blk.MULTI -and $matches -gt 1) { return @{ exit=12; msg="PRECONDITION: multiple matches; set MULTI:true"; target=$blk.TARGET; matches=$matches } }
      if ($blk.MULTI) {
        $new = $rx.Replace($orig, $blk.REPLACE)
      } else {
        $m = $rx.Match($orig)
        $new = $orig.Substring(0, $m.Index) + $m.Result($blk.REPLACE) + $orig.Substring($m.Index + $m.Length)
      }
      $changed = ($new -ne $orig)
    }
    'plain-replace' {
      if (-not $orig.Contains($blk.FIND)) { return @{ exit=10; msg="SKIP: FIND not found"; target=$blk.TARGET; matches=0; changed=$false } }
      if ($blk.MULTI) {
        $new = $orig.Replace($blk.FIND, $blk.REPLACE); $matches = ([regex]::Matches($orig, [regex]::Escape($blk.FIND))).Count
      } else {
        $idx = $orig.IndexOf($blk.FIND)
        $new = $orig.Substring(0,$idx) + $blk.REPLACE + $orig.Substring($idx + $blk.FIND.Length); $matches = 1
      }
      $changed = ($new -ne $orig)
    }
    'insert-after' {
      $rx = [System.Text.RegularExpressions.Regex]::new($blk.FIND, 'Singleline,Multiline')
      $m  = $rx.Match($orig)
      if (-not $m.Success) { return @{ exit=10; msg="SKIP: anchor not found"; target=$blk.TARGET; matches=0; changed=$false } }
      if (-not $blk.MULTI -and $rx.Matches($orig).Count -gt 1) { return @{ exit=12; msg="PRECONDITION: multiple anchors; set MULTI:true"; target=$blk.TARGET } }
      if ($blk.MULTI) {
        $new = $rx.Replace($orig, { param($m) $m.Value + $blk.REPLACE })
        $matches = $rx.Matches($orig).Count
      } else {
        $new = $orig.Substring(0,$m.Index+$m.Length) + $blk.REPLACE + $orig.Substring($m.Index+$m.Length)
        $matches = 1
      }
      $changed = ($new -ne $orig)
    }
    'insert-before' {
      $rx = [System.Text.RegularExpressions.Regex]::new($blk.FIND, 'Singleline,Multiline')
      $m  = $rx.Match($orig)
      if (-not $m.Success) { return @{ exit=10; msg="SKIP: anchor not found"; target=$blk.TARGET; matches=0; changed=$false } }
      if (-not $blk.MULTI -and $rx.Matches($orig).Count -gt 1) { return @{ exit=12; msg="PRECONDITION: multiple anchors; set MULTI:true"; target=$blk.TARGET } }
      if ($blk.MULTI) {
        $new = $rx.Replace($orig, { param($m) $blk.REPLACE + $m.Value })
        $matches = $rx.Matches($orig).Count
      } else {
        $new = $orig.Substring(0,$m.Index) + $blk.REPLACE + $orig.Substring($m.Index)
        $matches = 1
      }
      $changed = ($new -ne $orig)
    }
    default { return @{ exit=12; msg="PRECONDITION: unknown MODE '$($blk.MODE)'" ; target=$blk.TARGET } }
  }

  if (-not $changed) { return @{ exit=10; msg="SKIP: no change"; target=$blk.TARGET; matches=$matches; changed=$false } }

  if ($doApply) {
    # ReadOnly 해제(있다면)
    try {
      $fi = Get-Item -LiteralPath $target -Force
      if ($fi.Attributes.HasFlag([IO.FileAttributes]::ReadOnly)) {
        $fi.Attributes = $fi.Attributes -band (-bnot [IO.FileAttributes]::ReadOnly)
      }
    } catch {}
    $bak = "$target.bak-$(Get-Ts)"
    Copy-Item -LiteralPath $target -Destination $bak -Force
    Write-TextUtf8 -path $target -text $new
    return @{ exit=0; msg="APPLY OK"; target=$blk.TARGET; matches=$matches; backup=$bak; changed=$true }
  } else {
    return @{ exit=11; msg="DRYRUN OK (would change)"; target=$blk.TARGET; matches=$matches; changed=$true }
  }
}

# ---------- Main ----------
$repo = Resolve-RepoRoot $Root
$trace = New-TraceId
$doApply = $ConfirmApply.IsPresent -or ($env:CONFIRM_APPLY -and $env:CONFIRM_APPLY.ToString().ToLower() -eq 'true')

$patchFiles = @()
if ($PatchFile)   { $patchFiles += (Resolve-Path -LiteralPath $PatchFile).Path }
if ($PatchesDir) {
  $files = Get-ChildItem -Path $PatchesDir -File |
           Where-Object { # APPLY IN SHELL
#requires -Version 7.0
<#
  KoBong apply-patches.ps1 — v1.1 (2025-10-22)
  원칙: PS7-First, DRYRUN→APPLY, 레포 샌드박스, .gpt5.lock, .bak 스냅샷, 원자 교체, KLC 최소 1로그
  종료코드: 0=OK, 11=DRYRUN, 12=PRECONDITION, 13=CONFLICT, 1=ERROR
#>

[CmdletBinding()]
param(
  [Parameter()][string]$Root = (Get-Location).Path,
  [Parameter()][string]$PatchFile,
  [Parameter()][string]$PatchesDir,
  [switch]$ConfirmApply,
  [switch]$Quiet
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)

function New-TraceId { ([guid]::NewGuid()).ToString('N') }
function Get-Ts     { Get-Date -Format 'yyyyMMdd-HHmmss' }

function Resolve-RepoRoot([string]$root) {
  $p = Resolve-Path -LiteralPath $root
  if (-not $p) { throw "Root not found: $root" }
  return $p.Path
}

function Join-RepoPath([string]$repo,[string]$rel) {
  if ([string]::IsNullOrWhiteSpace($rel)) { throw "TARGET path is empty." }
  if ($rel -match '^\s*[./\\]*\.\.[/\\]') { throw "Path escapes repo: $rel" }
  $full = Join-Path -LiteralPath $repo -ChildPath $rel
  $norm = [System.IO.Path]::GetFullPath($full)
  if (-not $norm.StartsWith([System.IO.Path]::GetFullPath($repo), [StringComparison]::OrdinalIgnoreCase)) {
    throw "Path escapes repo: $rel"
  }
  return $norm
}

function Get-DefaultPatchList([string]$repo) {
  $list = [System.Collections.Generic.List[string]]::new()
  $pending = Join-Path $repo '.kobong\patches.pending.txt'
  $dir1    = Join-Path $repo '.kobong\patches'
  if (Test-Path -LiteralPath $pending) { $list.Add($pending) | Out-Null }
  if (Test-Path -LiteralPath $dir1) {
  $files = Get-ChildItem -Path $dir1 -File |
           Where-Object { # APPLY IN SHELL
#requires -Version 7.0
<#
  KoBong apply-patches.ps1 — v1.1 (2025-10-22)
  원칙: PS7-First, DRYRUN→APPLY, 레포 샌드박스, .gpt5.lock, .bak 스냅샷, 원자 교체, KLC 최소 1로그
  종료코드: 0=OK, 11=DRYRUN, 12=PRECONDITION, 13=CONFLICT, 1=ERROR
#>

[CmdletBinding()]
param(
  [Parameter()][string]$Root = (Get-Location).Path,
  [Parameter()][string]$PatchFile,
  [Parameter()][string]$PatchesDir,
  [switch]$ConfirmApply,
  [switch]$Quiet
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)

function New-TraceId { ([guid]::NewGuid()).ToString('N') }
function Get-Ts     { Get-Date -Format 'yyyyMMdd-HHmmss' }

function Resolve-RepoRoot([string]$root) {
  $p = Resolve-Path -LiteralPath $root
  if (-not $p) { throw "Root not found: $root" }
  return $p.Path
}

function Join-RepoPath([string]$repo,[string]$rel) {
  if ([string]::IsNullOrWhiteSpace($rel)) { throw "TARGET path is empty." }
  if ($rel -match '^\s*[./\\]*\.\.[/\\]') { throw "Path escapes repo: $rel" }
  $full = Join-Path -LiteralPath $repo -ChildPath $rel
  $norm = [System.IO.Path]::GetFullPath($full)
  if (-not $norm.StartsWith([System.IO.Path]::GetFullPath($repo), [StringComparison]::OrdinalIgnoreCase)) {
    throw "Path escapes repo: $rel"
  }
  return $norm
}

function Get-DefaultPatchList([string]$repo) {
  $list = [System.Collections.Generic.List[string]]::new()
  $pending = Join-Path $repo '.kobong\patches.pending.txt'
  $dir1    = Join-Path $repo '.kobong\patches'
  if (Test-Path -LiteralPath $pending) { $list.Add($pending) | Out-Null }
  if (Test-Path -LiteralPath $dir1) {
    $list.AddRange( Get-ChildItem -LiteralPath $dir1 -File -Include *.txt,*.patch,*.patch.txt | Sort-Object FullName | % { $_.FullName } )
  }
  return $list
}

function Read-TextUtf8([string]$path) {
  return Get-Content -LiteralPath $path -Raw -Encoding UTF8
}

function Write-TextUtf8([string]$path,[string]$text) {
  $dir = Split-Path -LiteralPath $path -Parent
  if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
  $tmp = "$path.tmp.$([guid]::NewGuid().ToString('N'))"
  [System.IO.File]::WriteAllText($tmp, $text, [System.Text.UTF8Encoding]::new($false))
  Move-Item -LiteralPath $tmp -Destination $path -Force
}

function Get-PrevHash([string]$logPath) {
  if (-not (Test-Path -LiteralPath $logPath)) { return ('0' * 64) }
  $last = Get-Content -LiteralPath $logPath -Tail 200 | Where-Object { $_ -match '\S' } | Select-Object -Last 1
  try { return ((ConvertFrom-Json -InputObject $last).hash) } catch { return ('0' * 64) }
}

function Get-Hash([string]$s) {
  $sha = [System.Security.Cryptography.SHA256]::Create()
  $bytes = [System.Text.Encoding]::UTF8.GetBytes($s)
  ($sha.ComputeHash($bytes) | ForEach-Object { $_.ToString('x2') }) -join ''
}

function Write-KLCLog([string]$repo,[hashtable]$obj) {
  $logDir  = Join-Path $repo 'logs'
  if (-not (Test-Path -LiteralPath $logDir)) { New-Item -ItemType Directory -Path $logDir | Out-Null }
  $logPath = Join-Path $logDir 'apply-log.jsonl'
  $prev    = Get-PrevHash $logPath
  $canon   = ($obj.GetEnumerator() | Sort-Object Name | ForEach-Object { "$($_.Name)=$($_.Value)" }) -join '|'
  $hash    = Get-Hash "$prev|$canon"
  $obj['prevHash'] = $prev
  $obj['hash']     = $hash
  $obj['hashAlgo'] = 'SHA256'
  $obj['canonAlgo']= 'kvc-line-v1'
  $json = ($obj | ConvertTo-Json -Depth 6 -Compress)
  Add-Content -LiteralPath $logPath -Value $json
}

function With-Lock([string]$repo,[scriptblock]$body) {
  $lockPath = Join-Path $repo '.gpt5.lock'
  $mineId   = New-TraceId
  if (Test-Path -LiteralPath $lockPath) {
    $age = (Get-Item -LiteralPath $lockPath).LastWriteTimeUtc
    if ((Get-Date).ToUniversalTime().AddMinutes(-10) -gt $age) {
      Rename-Item -LiteralPath $lockPath -NewName (".gpt5.lock.bak-" + (Get-Ts)) -Force
    } else {
      throw "Lock exists: $lockPath (최근 10분 내 실행 흔적)"
    }
  }
  try {
    Set-Content -LiteralPath $lockPath -NoNewline -Encoding UTF8 -Value $mineId
    & $body
  } finally {
    try {
      $current = ''
      if (Test-Path -LiteralPath $lockPath) { $current = Get-Content -LiteralPath $lockPath -Raw -Encoding UTF8 }
      if ($current -eq $mineId) { Remove-Item -LiteralPath $lockPath -Force -ErrorAction SilentlyContinue }
    } catch { }
  }
}

function Parse-PatchBlocks([string]$text) {
  $lines = $text -split "`n"
  $blocks = @()
  $i = 0
  while ($i -lt $lines.Length) {
    if ($lines[$i].Trim() -eq '# PATCH START') {
      $i++
      $meta = @{}
      $find = ''
      $replace = ''
      while ($i -lt $lines.Length -and -not ($lines[$i].Trim() -eq '# PATCH END')) {
        $L = $lines[$i]
        if ($L -match '^\s*TARGET:\s*(.+)$') { $meta.TARGET = $matches[1].Trim() }
        elseif ($L -match '^\s*MODE:\s*(.+)$') { $meta.MODE = $matches[1].Trim().ToLower() }
        elseif ($L -match '^\s*MULTI:\s*(.+)$') { $meta.MULTI = [bool]::Parse($matches[1].Trim()) }
        elseif ($L -match "^\s*FIND\s+<<'EOF'\s*$") {
          $buf = New-Object System.Text.StringBuilder
          $i++
          while ($i -lt $lines.Length -and -not ($lines[$i].Trim() -eq 'EOF')) {
            [void]$buf.AppendLine($lines[$i])
            $i++
          }
          $find = $buf.ToString()
        }
        elseif ($L -match "^\s*REPLACE\s+<<'EOF'\s*$") {
          $buf = New-Object System.Text.StringBuilder
          $i++
          while ($i -lt $lines.Length -and -not ($lines[$i].Trim() -eq 'EOF')) {
            [void]$buf.AppendLine($lines[$i])
            $i++
          }
          $replace = $buf.ToString()
        }
        $i++
      }
      if (-not $meta.TARGET -or -not $meta.MODE) { throw "PATCH 메타 누락(TARGET/MODE)" }
      $blocks += [pscustomobject]@{
        TARGET  = $meta.TARGET
        MODE    = $meta.MODE
        MULTI   = [bool]($meta.MULTI)
        FIND    = $find
        REPLACE = $replace
      }
    } else { $i++ }
  }
  return ,$blocks
}

function Apply-OnePatch([string]$repo, $blk, [bool]$doApply, [string]$traceId) {
  $target = Join-RepoPath $repo $blk.TARGET
  if (-not (Test-Path -LiteralPath $target)) { return @{ exit=12; msg="PRECONDITION: target not found"; target=$blk.TARGET } }

  $orig = Read-TextUtf8 $target
  $new  = $orig
  $matches = 0
  $changed = $false

  # 멱등(SENTINEL): 이미 REPLACE가 있으면 SKIP
  if (-not [string]::IsNullOrEmpty($blk.REPLACE) -and $orig.Contains($blk.REPLACE)) {
    return @{ exit=10; msg="SKIP: already contains REPLACE"; target=$blk.TARGET; matches=0; changed=$false }
  }

  switch ($blk.MODE) {
    'regex-replace' {
      $rx = [System.Text.RegularExpressions.Regex]::new($blk.FIND, 'Singleline,Multiline')
      $matches = ($rx.Matches($orig)).Count
      if ($matches -eq 0) { return @{ exit=10; msg="SKIP: no match"; target=$blk.TARGET; matches=0; changed=$false } }
      if (-not $blk.MULTI -and $matches -gt 1) { return @{ exit=12; msg="PRECONDITION: multiple matches; set MULTI:true"; target=$blk.TARGET; matches=$matches } }
      if ($blk.MULTI) {
        $new = $rx.Replace($orig, $blk.REPLACE)
      } else {
        $m = $rx.Match($orig)
        $new = $orig.Substring(0, $m.Index) + $m.Result($blk.REPLACE) + $orig.Substring($m.Index + $m.Length)
      }
      $changed = ($new -ne $orig)
    }
    'plain-replace' {
      if (-not $orig.Contains($blk.FIND)) { return @{ exit=10; msg="SKIP: FIND not found"; target=$blk.TARGET; matches=0; changed=$false } }
      if ($blk.MULTI) {
        $new = $orig.Replace($blk.FIND, $blk.REPLACE); $matches = ([regex]::Matches($orig, [regex]::Escape($blk.FIND))).Count
      } else {
        $idx = $orig.IndexOf($blk.FIND)
        $new = $orig.Substring(0,$idx) + $blk.REPLACE + $orig.Substring($idx + $blk.FIND.Length); $matches = 1
      }
      $changed = ($new -ne $orig)
    }
    'insert-after' {
      $rx = [System.Text.RegularExpressions.Regex]::new($blk.FIND, 'Singleline,Multiline')
      $m  = $rx.Match($orig)
      if (-not $m.Success) { return @{ exit=10; msg="SKIP: anchor not found"; target=$blk.TARGET; matches=0; changed=$false } }
      if (-not $blk.MULTI -and $rx.Matches($orig).Count -gt 1) { return @{ exit=12; msg="PRECONDITION: multiple anchors; set MULTI:true"; target=$blk.TARGET } }
      if ($blk.MULTI) {
        $new = $rx.Replace($orig, { param($m) $m.Value + $blk.REPLACE })
        $matches = $rx.Matches($orig).Count
      } else {
        $new = $orig.Substring(0,$m.Index+$m.Length) + $blk.REPLACE + $orig.Substring($m.Index+$m.Length)
        $matches = 1
      }
      $changed = ($new -ne $orig)
    }
    'insert-before' {
      $rx = [System.Text.RegularExpressions.Regex]::new($blk.FIND, 'Singleline,Multiline')
      $m  = $rx.Match($orig)
      if (-not $m.Success) { return @{ exit=10; msg="SKIP: anchor not found"; target=$blk.TARGET; matches=0; changed=$false } }
      if (-not $blk.MULTI -and $rx.Matches($orig).Count -gt 1) { return @{ exit=12; msg="PRECONDITION: multiple anchors; set MULTI:true"; target=$blk.TARGET } }
      if ($blk.MULTI) {
        $new = $rx.Replace($orig, { param($m) $blk.REPLACE + $m.Value })
        $matches = $rx.Matches($orig).Count
      } else {
        $new = $orig.Substring(0,$m.Index) + $blk.REPLACE + $orig.Substring($m.Index)
        $matches = 1
      }
      $changed = ($new -ne $orig)
    }
    default { return @{ exit=12; msg="PRECONDITION: unknown MODE '$($blk.MODE)'" ; target=$blk.TARGET } }
  }

  if (-not $changed) { return @{ exit=10; msg="SKIP: no change"; target=$blk.TARGET; matches=$matches; changed=$false } }

  if ($doApply) {
    # ReadOnly 해제(있다면)
    try {
      $fi = Get-Item -LiteralPath $target -Force
      if ($fi.Attributes.HasFlag([IO.FileAttributes]::ReadOnly)) {
        $fi.Attributes = $fi.Attributes -band (-bnot [IO.FileAttributes]::ReadOnly)
      }
    } catch {}
    $bak = "$target.bak-$(Get-Ts)"
    Copy-Item -LiteralPath $target -Destination $bak -Force
    Write-TextUtf8 -path $target -text $new
    return @{ exit=0; msg="APPLY OK"; target=$blk.TARGET; matches=$matches; backup=$bak; changed=$true }
  } else {
    return @{ exit=11; msg="DRYRUN OK (would change)"; target=$blk.TARGET; matches=$matches; changed=$true }
  }
}

# ---------- Main ----------
$repo = Resolve-RepoRoot $Root
$trace = New-TraceId
$doApply = $ConfirmApply.IsPresent -or ($env:CONFIRM_APPLY -and $env:CONFIRM_APPLY.ToString().ToLower() -eq 'true')

$patchFiles = @()
if ($PatchFile)   { $patchFiles += (Resolve-Path -LiteralPath $PatchFile).Path }
if ($PatchesDir)  { $patchFiles += (Get-ChildItem -LiteralPath $PatchesDir -File -Include *.txt,*.patch,*.patch.txt | Sort-Object FullName | % FullName) }
if (-not $PatchFile -and -not $PatchesDir) { $patchFiles += Get-DefaultPatchList $repo }
if (-not $patchFiles) { throw "패치 파일이 없습니다(.kobong\patches.pending.txt 또는 .kobong\patches\*.txt)" }

$all = @()
foreach ($pf in $patchFiles) {
  $txt = Read-TextUtf8 $pf
  $blocks = Parse-PatchBlocks $txt
  if (-not $blocks -or $blocks.Count -eq 0) { throw "유효한 PATCH 블록이 없습니다: $pf" }
  $all += $blocks
}

$exitMax = 0
$print = { param($o)
  if (-not $Quiet) {
    "{0,-7} | {1} | {2} | matches={3} {4}" -f $o.exit, $o.msg, $o.target, ($o.matches ?? 0), ($(if($o.backup){"| bak=$($o.backup)"}else{""}))
  }
}

With-Lock $repo {
  $start = Get-Date
  foreach ($blk in $all) {
    $res = Apply-OnePatch -repo $repo -blk $blk -doApply:$doApply -traceId $trace
    & $print $res
    if ($res.exit -gt $exitMax) { $exitMax = $res.exit }
    Write-KLCLog $repo @{
      version   = '1.3'
      timestamp = (Get-Date).ToUniversalTime().ToString('o')
      traceId   = $trace
      env       = 'DEV'
      mode      = ($doApply ? 'APPLY' : 'DRYRUN')
      service   = 'apply-patches'
      module    = 'scripts/g5/apply-patches.ps1'
      action    = 'patch'
      outcome   = $res.msg
      exitCode  = $res.exit
      target    = $res.target
      matches   = ($res.matches ?? 0)
      backup    = ($res.backup ?? '')
      durationMs= [int]((Get-Date) - $start).TotalMilliseconds
      message   = $res.msg
    }
  }
}

if ($exitMax -eq 11 -and -not $doApply) { exit 11 }        # DRYRUN only
elseif ($exitMax -in 12,13)           { exit $exitMax }     # PRECONDITION/CONFLICT
elseif ($exitMax -eq 0)               { exit 0 }            # all good
elseif ($exitMax -eq 10)              { exit 0 }            # all skipped -> OK
else                                  { exit 1 }            # unknown -> ERROR
.Name -match '\.(txt|patch|patch\.txt)
  return $list
}

function Read-TextUtf8([string]$path) {
  return Get-Content -LiteralPath $path -Raw -Encoding UTF8
}

function Write-TextUtf8([string]$path,[string]$text) {
  $dir = Split-Path -LiteralPath $path -Parent
  if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
  $tmp = "$path.tmp.$([guid]::NewGuid().ToString('N'))"
  [System.IO.File]::WriteAllText($tmp, $text, [System.Text.UTF8Encoding]::new($false))
  Move-Item -LiteralPath $tmp -Destination $path -Force
}

function Get-PrevHash([string]$logPath) {
  if (-not (Test-Path -LiteralPath $logPath)) { return ('0' * 64) }
  $last = Get-Content -LiteralPath $logPath -Tail 200 | Where-Object { $_ -match '\S' } | Select-Object -Last 1
  try { return ((ConvertFrom-Json -InputObject $last).hash) } catch { return ('0' * 64) }
}

function Get-Hash([string]$s) {
  $sha = [System.Security.Cryptography.SHA256]::Create()
  $bytes = [System.Text.Encoding]::UTF8.GetBytes($s)
  ($sha.ComputeHash($bytes) | ForEach-Object { $_.ToString('x2') }) -join ''
}

function Write-KLCLog([string]$repo,[hashtable]$obj) {
  $logDir  = Join-Path $repo 'logs'
  if (-not (Test-Path -LiteralPath $logDir)) { New-Item -ItemType Directory -Path $logDir | Out-Null }
  $logPath = Join-Path $logDir 'apply-log.jsonl'
  $prev    = Get-PrevHash $logPath
  $canon   = ($obj.GetEnumerator() | Sort-Object Name | ForEach-Object { "$($_.Name)=$($_.Value)" }) -join '|'
  $hash    = Get-Hash "$prev|$canon"
  $obj['prevHash'] = $prev
  $obj['hash']     = $hash
  $obj['hashAlgo'] = 'SHA256'
  $obj['canonAlgo']= 'kvc-line-v1'
  $json = ($obj | ConvertTo-Json -Depth 6 -Compress)
  Add-Content -LiteralPath $logPath -Value $json
}

function With-Lock([string]$repo,[scriptblock]$body) {
  $lockPath = Join-Path $repo '.gpt5.lock'
  $mineId   = New-TraceId
  if (Test-Path -LiteralPath $lockPath) {
    $age = (Get-Item -LiteralPath $lockPath).LastWriteTimeUtc
    if ((Get-Date).ToUniversalTime().AddMinutes(-10) -gt $age) {
      Rename-Item -LiteralPath $lockPath -NewName (".gpt5.lock.bak-" + (Get-Ts)) -Force
    } else {
      throw "Lock exists: $lockPath (최근 10분 내 실행 흔적)"
    }
  }
  try {
    Set-Content -LiteralPath $lockPath -NoNewline -Encoding UTF8 -Value $mineId
    & $body
  } finally {
    try {
      $current = ''
      if (Test-Path -LiteralPath $lockPath) { $current = Get-Content -LiteralPath $lockPath -Raw -Encoding UTF8 }
      if ($current -eq $mineId) { Remove-Item -LiteralPath $lockPath -Force -ErrorAction SilentlyContinue }
    } catch { }
  }
}

function Parse-PatchBlocks([string]$text) {
  $lines = $text -split "`n"
  $blocks = @()
  $i = 0
  while ($i -lt $lines.Length) {
    if ($lines[$i].Trim() -eq '# PATCH START') {
      $i++
      $meta = @{}
      $find = ''
      $replace = ''
      while ($i -lt $lines.Length -and -not ($lines[$i].Trim() -eq '# PATCH END')) {
        $L = $lines[$i]
        if ($L -match '^\s*TARGET:\s*(.+)$') { $meta.TARGET = $matches[1].Trim() }
        elseif ($L -match '^\s*MODE:\s*(.+)$') { $meta.MODE = $matches[1].Trim().ToLower() }
        elseif ($L -match '^\s*MULTI:\s*(.+)$') { $meta.MULTI = [bool]::Parse($matches[1].Trim()) }
        elseif ($L -match "^\s*FIND\s+<<'EOF'\s*$") {
          $buf = New-Object System.Text.StringBuilder
          $i++
          while ($i -lt $lines.Length -and -not ($lines[$i].Trim() -eq 'EOF')) {
            [void]$buf.AppendLine($lines[$i])
            $i++
          }
          $find = $buf.ToString()
        }
        elseif ($L -match "^\s*REPLACE\s+<<'EOF'\s*$") {
          $buf = New-Object System.Text.StringBuilder
          $i++
          while ($i -lt $lines.Length -and -not ($lines[$i].Trim() -eq 'EOF')) {
            [void]$buf.AppendLine($lines[$i])
            $i++
          }
          $replace = $buf.ToString()
        }
        $i++
      }
      if (-not $meta.TARGET -or -not $meta.MODE) { throw "PATCH 메타 누락(TARGET/MODE)" }
      $blocks += [pscustomobject]@{
        TARGET  = $meta.TARGET
        MODE    = $meta.MODE
        MULTI   = [bool]($meta.MULTI)
        FIND    = $find
        REPLACE = $replace
      }
    } else { $i++ }
  }
  return ,$blocks
}

function Apply-OnePatch([string]$repo, $blk, [bool]$doApply, [string]$traceId) {
  $target = Join-RepoPath $repo $blk.TARGET
  if (-not (Test-Path -LiteralPath $target)) { return @{ exit=12; msg="PRECONDITION: target not found"; target=$blk.TARGET } }

  $orig = Read-TextUtf8 $target
  $new  = $orig
  $matches = 0
  $changed = $false

  # 멱등(SENTINEL): 이미 REPLACE가 있으면 SKIP
  if (-not [string]::IsNullOrEmpty($blk.REPLACE) -and $orig.Contains($blk.REPLACE)) {
    return @{ exit=10; msg="SKIP: already contains REPLACE"; target=$blk.TARGET; matches=0; changed=$false }
  }

  switch ($blk.MODE) {
    'regex-replace' {
      $rx = [System.Text.RegularExpressions.Regex]::new($blk.FIND, 'Singleline,Multiline')
      $matches = ($rx.Matches($orig)).Count
      if ($matches -eq 0) { return @{ exit=10; msg="SKIP: no match"; target=$blk.TARGET; matches=0; changed=$false } }
      if (-not $blk.MULTI -and $matches -gt 1) { return @{ exit=12; msg="PRECONDITION: multiple matches; set MULTI:true"; target=$blk.TARGET; matches=$matches } }
      if ($blk.MULTI) {
        $new = $rx.Replace($orig, $blk.REPLACE)
      } else {
        $m = $rx.Match($orig)
        $new = $orig.Substring(0, $m.Index) + $m.Result($blk.REPLACE) + $orig.Substring($m.Index + $m.Length)
      }
      $changed = ($new -ne $orig)
    }
    'plain-replace' {
      if (-not $orig.Contains($blk.FIND)) { return @{ exit=10; msg="SKIP: FIND not found"; target=$blk.TARGET; matches=0; changed=$false } }
      if ($blk.MULTI) {
        $new = $orig.Replace($blk.FIND, $blk.REPLACE); $matches = ([regex]::Matches($orig, [regex]::Escape($blk.FIND))).Count
      } else {
        $idx = $orig.IndexOf($blk.FIND)
        $new = $orig.Substring(0,$idx) + $blk.REPLACE + $orig.Substring($idx + $blk.FIND.Length); $matches = 1
      }
      $changed = ($new -ne $orig)
    }
    'insert-after' {
      $rx = [System.Text.RegularExpressions.Regex]::new($blk.FIND, 'Singleline,Multiline')
      $m  = $rx.Match($orig)
      if (-not $m.Success) { return @{ exit=10; msg="SKIP: anchor not found"; target=$blk.TARGET; matches=0; changed=$false } }
      if (-not $blk.MULTI -and $rx.Matches($orig).Count -gt 1) { return @{ exit=12; msg="PRECONDITION: multiple anchors; set MULTI:true"; target=$blk.TARGET } }
      if ($blk.MULTI) {
        $new = $rx.Replace($orig, { param($m) $m.Value + $blk.REPLACE })
        $matches = $rx.Matches($orig).Count
      } else {
        $new = $orig.Substring(0,$m.Index+$m.Length) + $blk.REPLACE + $orig.Substring($m.Index+$m.Length)
        $matches = 1
      }
      $changed = ($new -ne $orig)
    }
    'insert-before' {
      $rx = [System.Text.RegularExpressions.Regex]::new($blk.FIND, 'Singleline,Multiline')
      $m  = $rx.Match($orig)
      if (-not $m.Success) { return @{ exit=10; msg="SKIP: anchor not found"; target=$blk.TARGET; matches=0; changed=$false } }
      if (-not $blk.MULTI -and $rx.Matches($orig).Count -gt 1) { return @{ exit=12; msg="PRECONDITION: multiple anchors; set MULTI:true"; target=$blk.TARGET } }
      if ($blk.MULTI) {
        $new = $rx.Replace($orig, { param($m) $blk.REPLACE + $m.Value })
        $matches = $rx.Matches($orig).Count
      } else {
        $new = $orig.Substring(0,$m.Index) + $blk.REPLACE + $orig.Substring($m.Index)
        $matches = 1
      }
      $changed = ($new -ne $orig)
    }
    default { return @{ exit=12; msg="PRECONDITION: unknown MODE '$($blk.MODE)'" ; target=$blk.TARGET } }
  }

  if (-not $changed) { return @{ exit=10; msg="SKIP: no change"; target=$blk.TARGET; matches=$matches; changed=$false } }

  if ($doApply) {
    # ReadOnly 해제(있다면)
    try {
      $fi = Get-Item -LiteralPath $target -Force
      if ($fi.Attributes.HasFlag([IO.FileAttributes]::ReadOnly)) {
        $fi.Attributes = $fi.Attributes -band (-bnot [IO.FileAttributes]::ReadOnly)
      }
    } catch {}
    $bak = "$target.bak-$(Get-Ts)"
    Copy-Item -LiteralPath $target -Destination $bak -Force
    Write-TextUtf8 -path $target -text $new
    return @{ exit=0; msg="APPLY OK"; target=$blk.TARGET; matches=$matches; backup=$bak; changed=$true }
  } else {
    return @{ exit=11; msg="DRYRUN OK (would change)"; target=$blk.TARGET; matches=$matches; changed=$true }
  }
}

# ---------- Main ----------
$repo = Resolve-RepoRoot $Root
$trace = New-TraceId
$doApply = $ConfirmApply.IsPresent -or ($env:CONFIRM_APPLY -and $env:CONFIRM_APPLY.ToString().ToLower() -eq 'true')

$patchFiles = @()
if ($PatchFile)   { $patchFiles += (Resolve-Path -LiteralPath $PatchFile).Path }
if ($PatchesDir)  { $patchFiles += (Get-ChildItem -LiteralPath $PatchesDir -File -Include *.txt,*.patch,*.patch.txt | Sort-Object FullName | % FullName) }
if (-not $PatchFile -and -not $PatchesDir) { $patchFiles += Get-DefaultPatchList $repo }
if (-not $patchFiles) { throw "패치 파일이 없습니다(.kobong\patches.pending.txt 또는 .kobong\patches\*.txt)" }

$all = @()
foreach ($pf in $patchFiles) {
  $txt = Read-TextUtf8 $pf
  $blocks = Parse-PatchBlocks $txt
  if (-not $blocks -or $blocks.Count -eq 0) { throw "유효한 PATCH 블록이 없습니다: $pf" }
  $all += $blocks
}

$exitMax = 0
$print = { param($o)
  if (-not $Quiet) {
    "{0,-7} | {1} | {2} | matches={3} {4}" -f $o.exit, $o.msg, $o.target, ($o.matches ?? 0), ($(if($o.backup){"| bak=$($o.backup)"}else{""}))
  }
}

With-Lock $repo {
  $start = Get-Date
  foreach ($blk in $all) {
    $res = Apply-OnePatch -repo $repo -blk $blk -doApply:$doApply -traceId $trace
    & $print $res
    if ($res.exit -gt $exitMax) { $exitMax = $res.exit }
    Write-KLCLog $repo @{
      version   = '1.3'
      timestamp = (Get-Date).ToUniversalTime().ToString('o')
      traceId   = $trace
      env       = 'DEV'
      mode      = ($doApply ? 'APPLY' : 'DRYRUN')
      service   = 'apply-patches'
      module    = 'scripts/g5/apply-patches.ps1'
      action    = 'patch'
      outcome   = $res.msg
      exitCode  = $res.exit
      target    = $res.target
      matches   = ($res.matches ?? 0)
      backup    = ($res.backup ?? '')
      durationMs= [int]((Get-Date) - $start).TotalMilliseconds
      message   = $res.msg
    }
  }
}

if ($exitMax -eq 11 -and -not $doApply) { exit 11 }        # DRYRUN only
elseif ($exitMax -in 12,13)           { exit $exitMax }     # PRECONDITION/CONFLICT
elseif ($exitMax -eq 0)               { exit 0 }            # all good
elseif ($exitMax -eq 10)              { exit 0 }            # all skipped -> OK
else                                  { exit 1 }            # unknown -> ERROR
 } |
           Sort-Object FullName
  foreach ($f in $files) { [void]$list.Add($f.FullName) }
}
  return $list
}

function Read-TextUtf8([string]$path) {
  return Get-Content -LiteralPath $path -Raw -Encoding UTF8
}

function Write-TextUtf8([string]$path,[string]$text) {
  $dir = Split-Path -LiteralPath $path -Parent
  if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
  $tmp = "$path.tmp.$([guid]::NewGuid().ToString('N'))"
  [System.IO.File]::WriteAllText($tmp, $text, [System.Text.UTF8Encoding]::new($false))
  Move-Item -LiteralPath $tmp -Destination $path -Force
}

function Get-PrevHash([string]$logPath) {
  if (-not (Test-Path -LiteralPath $logPath)) { return ('0' * 64) }
  $last = Get-Content -LiteralPath $logPath -Tail 200 | Where-Object { $_ -match '\S' } | Select-Object -Last 1
  try { return ((ConvertFrom-Json -InputObject $last).hash) } catch { return ('0' * 64) }
}

function Get-Hash([string]$s) {
  $sha = [System.Security.Cryptography.SHA256]::Create()
  $bytes = [System.Text.Encoding]::UTF8.GetBytes($s)
  ($sha.ComputeHash($bytes) | ForEach-Object { $_.ToString('x2') }) -join ''
}

function Write-KLCLog([string]$repo,[hashtable]$obj) {
  $logDir  = Join-Path $repo 'logs'
  if (-not (Test-Path -LiteralPath $logDir)) { New-Item -ItemType Directory -Path $logDir | Out-Null }
  $logPath = Join-Path $logDir 'apply-log.jsonl'
  $prev    = Get-PrevHash $logPath
  $canon   = ($obj.GetEnumerator() | Sort-Object Name | ForEach-Object { "$($_.Name)=$($_.Value)" }) -join '|'
  $hash    = Get-Hash "$prev|$canon"
  $obj['prevHash'] = $prev
  $obj['hash']     = $hash
  $obj['hashAlgo'] = 'SHA256'
  $obj['canonAlgo']= 'kvc-line-v1'
  $json = ($obj | ConvertTo-Json -Depth 6 -Compress)
  Add-Content -LiteralPath $logPath -Value $json
}

function With-Lock([string]$repo,[scriptblock]$body) {
  $lockPath = Join-Path $repo '.gpt5.lock'
  $mineId   = New-TraceId
  if (Test-Path -LiteralPath $lockPath) {
    $age = (Get-Item -LiteralPath $lockPath).LastWriteTimeUtc
    if ((Get-Date).ToUniversalTime().AddMinutes(-10) -gt $age) {
      Rename-Item -LiteralPath $lockPath -NewName (".gpt5.lock.bak-" + (Get-Ts)) -Force
    } else {
      throw "Lock exists: $lockPath (최근 10분 내 실행 흔적)"
    }
  }
  try {
    Set-Content -LiteralPath $lockPath -NoNewline -Encoding UTF8 -Value $mineId
    & $body
  } finally {
    try {
      $current = ''
      if (Test-Path -LiteralPath $lockPath) { $current = Get-Content -LiteralPath $lockPath -Raw -Encoding UTF8 }
      if ($current -eq $mineId) { Remove-Item -LiteralPath $lockPath -Force -ErrorAction SilentlyContinue }
    } catch { }
  }
}

function Parse-PatchBlocks([string]$text) {
  $lines = $text -split "`n"
  $blocks = @()
  $i = 0
  while ($i -lt $lines.Length) {
    if ($lines[$i].Trim() -eq '# PATCH START') {
      $i++
      $meta = @{}
      $find = ''
      $replace = ''
      while ($i -lt $lines.Length -and -not ($lines[$i].Trim() -eq '# PATCH END')) {
        $L = $lines[$i]
        if ($L -match '^\s*TARGET:\s*(.+)$') { $meta.TARGET = $matches[1].Trim() }
        elseif ($L -match '^\s*MODE:\s*(.+)$') { $meta.MODE = $matches[1].Trim().ToLower() }
        elseif ($L -match '^\s*MULTI:\s*(.+)$') { $meta.MULTI = [bool]::Parse($matches[1].Trim()) }
        elseif ($L -match "^\s*FIND\s+<<'EOF'\s*$") {
          $buf = New-Object System.Text.StringBuilder
          $i++
          while ($i -lt $lines.Length -and -not ($lines[$i].Trim() -eq 'EOF')) {
            [void]$buf.AppendLine($lines[$i])
            $i++
          }
          $find = $buf.ToString()
        }
        elseif ($L -match "^\s*REPLACE\s+<<'EOF'\s*$") {
          $buf = New-Object System.Text.StringBuilder
          $i++
          while ($i -lt $lines.Length -and -not ($lines[$i].Trim() -eq 'EOF')) {
            [void]$buf.AppendLine($lines[$i])
            $i++
          }
          $replace = $buf.ToString()
        }
        $i++
      }
      if (-not $meta.TARGET -or -not $meta.MODE) { throw "PATCH 메타 누락(TARGET/MODE)" }
      $blocks += [pscustomobject]@{
        TARGET  = $meta.TARGET
        MODE    = $meta.MODE
        MULTI   = [bool]($meta.MULTI)
        FIND    = $find
        REPLACE = $replace
      }
    } else { $i++ }
  }
  return ,$blocks
}

function Apply-OnePatch([string]$repo, $blk, [bool]$doApply, [string]$traceId) {
  $target = Join-RepoPath $repo $blk.TARGET
  if (-not (Test-Path -LiteralPath $target)) { return @{ exit=12; msg="PRECONDITION: target not found"; target=$blk.TARGET } }

  $orig = Read-TextUtf8 $target
  $new  = $orig
  $matches = 0
  $changed = $false

  # 멱등(SENTINEL): 이미 REPLACE가 있으면 SKIP
  if (-not [string]::IsNullOrEmpty($blk.REPLACE) -and $orig.Contains($blk.REPLACE)) {
    return @{ exit=10; msg="SKIP: already contains REPLACE"; target=$blk.TARGET; matches=0; changed=$false }
  }

  switch ($blk.MODE) {
    'regex-replace' {
      $rx = [System.Text.RegularExpressions.Regex]::new($blk.FIND, 'Singleline,Multiline')
      $matches = ($rx.Matches($orig)).Count
      if ($matches -eq 0) { return @{ exit=10; msg="SKIP: no match"; target=$blk.TARGET; matches=0; changed=$false } }
      if (-not $blk.MULTI -and $matches -gt 1) { return @{ exit=12; msg="PRECONDITION: multiple matches; set MULTI:true"; target=$blk.TARGET; matches=$matches } }
      if ($blk.MULTI) {
        $new = $rx.Replace($orig, $blk.REPLACE)
      } else {
        $m = $rx.Match($orig)
        $new = $orig.Substring(0, $m.Index) + $m.Result($blk.REPLACE) + $orig.Substring($m.Index + $m.Length)
      }
      $changed = ($new -ne $orig)
    }
    'plain-replace' {
      if (-not $orig.Contains($blk.FIND)) { return @{ exit=10; msg="SKIP: FIND not found"; target=$blk.TARGET; matches=0; changed=$false } }
      if ($blk.MULTI) {
        $new = $orig.Replace($blk.FIND, $blk.REPLACE); $matches = ([regex]::Matches($orig, [regex]::Escape($blk.FIND))).Count
      } else {
        $idx = $orig.IndexOf($blk.FIND)
        $new = $orig.Substring(0,$idx) + $blk.REPLACE + $orig.Substring($idx + $blk.FIND.Length); $matches = 1
      }
      $changed = ($new -ne $orig)
    }
    'insert-after' {
      $rx = [System.Text.RegularExpressions.Regex]::new($blk.FIND, 'Singleline,Multiline')
      $m  = $rx.Match($orig)
      if (-not $m.Success) { return @{ exit=10; msg="SKIP: anchor not found"; target=$blk.TARGET; matches=0; changed=$false } }
      if (-not $blk.MULTI -and $rx.Matches($orig).Count -gt 1) { return @{ exit=12; msg="PRECONDITION: multiple anchors; set MULTI:true"; target=$blk.TARGET } }
      if ($blk.MULTI) {
        $new = $rx.Replace($orig, { param($m) $m.Value + $blk.REPLACE })
        $matches = $rx.Matches($orig).Count
      } else {
        $new = $orig.Substring(0,$m.Index+$m.Length) + $blk.REPLACE + $orig.Substring($m.Index+$m.Length)
        $matches = 1
      }
      $changed = ($new -ne $orig)
    }
    'insert-before' {
      $rx = [System.Text.RegularExpressions.Regex]::new($blk.FIND, 'Singleline,Multiline')
      $m  = $rx.Match($orig)
      if (-not $m.Success) { return @{ exit=10; msg="SKIP: anchor not found"; target=$blk.TARGET; matches=0; changed=$false } }
      if (-not $blk.MULTI -and $rx.Matches($orig).Count -gt 1) { return @{ exit=12; msg="PRECONDITION: multiple anchors; set MULTI:true"; target=$blk.TARGET } }
      if ($blk.MULTI) {
        $new = $rx.Replace($orig, { param($m) $blk.REPLACE + $m.Value })
        $matches = $rx.Matches($orig).Count
      } else {
        $new = $orig.Substring(0,$m.Index) + $blk.REPLACE + $orig.Substring($m.Index)
        $matches = 1
      }
      $changed = ($new -ne $orig)
    }
    default { return @{ exit=12; msg="PRECONDITION: unknown MODE '$($blk.MODE)'" ; target=$blk.TARGET } }
  }

  if (-not $changed) { return @{ exit=10; msg="SKIP: no change"; target=$blk.TARGET; matches=$matches; changed=$false } }

  if ($doApply) {
    # ReadOnly 해제(있다면)
    try {
      $fi = Get-Item -LiteralPath $target -Force
      if ($fi.Attributes.HasFlag([IO.FileAttributes]::ReadOnly)) {
        $fi.Attributes = $fi.Attributes -band (-bnot [IO.FileAttributes]::ReadOnly)
      }
    } catch {}
    $bak = "$target.bak-$(Get-Ts)"
    Copy-Item -LiteralPath $target -Destination $bak -Force
    Write-TextUtf8 -path $target -text $new
    return @{ exit=0; msg="APPLY OK"; target=$blk.TARGET; matches=$matches; backup=$bak; changed=$true }
  } else {
    return @{ exit=11; msg="DRYRUN OK (would change)"; target=$blk.TARGET; matches=$matches; changed=$true }
  }
}

# ---------- Main ----------
$repo = Resolve-RepoRoot $Root
$trace = New-TraceId
$doApply = $ConfirmApply.IsPresent -or ($env:CONFIRM_APPLY -and $env:CONFIRM_APPLY.ToString().ToLower() -eq 'true')

$patchFiles = @()
if ($PatchFile)   { $patchFiles += (Resolve-Path -LiteralPath $PatchFile).Path }
if ($PatchesDir)  { $patchFiles += (Get-ChildItem -LiteralPath $PatchesDir -File -Include *.txt,*.patch,*.patch.txt | Sort-Object FullName | % FullName) }
if (-not $PatchFile -and -not $PatchesDir) { $patchFiles += Get-DefaultPatchList $repo }
if (-not $patchFiles) { throw "패치 파일이 없습니다(.kobong\patches.pending.txt 또는 .kobong\patches\*.txt)" }

$all = @()
foreach ($pf in $patchFiles) {
  $txt = Read-TextUtf8 $pf
  $blocks = Parse-PatchBlocks $txt
  if (-not $blocks -or $blocks.Count -eq 0) { throw "유효한 PATCH 블록이 없습니다: $pf" }
  $all += $blocks
}

$exitMax = 0
$print = { param($o)
  if (-not $Quiet) {
    "{0,-7} | {1} | {2} | matches={3} {4}" -f $o.exit, $o.msg, $o.target, ($o.matches ?? 0), ($(if($o.backup){"| bak=$($o.backup)"}else{""}))
  }
}

With-Lock $repo {
  $start = Get-Date
  foreach ($blk in $all) {
    $res = Apply-OnePatch -repo $repo -blk $blk -doApply:$doApply -traceId $trace
    & $print $res
    if ($res.exit -gt $exitMax) { $exitMax = $res.exit }
    Write-KLCLog $repo @{
      version   = '1.3'
      timestamp = (Get-Date).ToUniversalTime().ToString('o')
      traceId   = $trace
      env       = 'DEV'
      mode      = ($doApply ? 'APPLY' : 'DRYRUN')
      service   = 'apply-patches'
      module    = 'scripts/g5/apply-patches.ps1'
      action    = 'patch'
      outcome   = $res.msg
      exitCode  = $res.exit
      target    = $res.target
      matches   = ($res.matches ?? 0)
      backup    = ($res.backup ?? '')
      durationMs= [int]((Get-Date) - $start).TotalMilliseconds
      message   = $res.msg
    }
  }
}

if ($exitMax -eq 11 -and -not $doApply) { exit 11 }        # DRYRUN only
elseif ($exitMax -in 12,13)           { exit $exitMax }     # PRECONDITION/CONFLICT
elseif ($exitMax -eq 0)               { exit 0 }            # all good
elseif ($exitMax -eq 10)              { exit 0 }            # all skipped -> OK
else                                  { exit 1 }            # unknown -> ERROR
.Name -match '\.(txt|patch|patch\.txt)
if (-not $PatchFile -and -not $PatchesDir) { $patchFiles += Get-DefaultPatchList $repo }
if (-not $patchFiles) { throw "패치 파일이 없습니다(.kobong\patches.pending.txt 또는 .kobong\patches\*.txt)" }

$all = @()
foreach ($pf in $patchFiles) {
  $txt = Read-TextUtf8 $pf
  $blocks = Parse-PatchBlocks $txt
  if (-not $blocks -or $blocks.Count -eq 0) { throw "유효한 PATCH 블록이 없습니다: $pf" }
  $all += $blocks
}

$exitMax = 0
$print = { param($o)
  if (-not $Quiet) {
    "{0,-7} | {1} | {2} | matches={3} {4}" -f $o.exit, $o.msg, $o.target, ($o.matches ?? 0), ($(if($o.backup){"| bak=$($o.backup)"}else{""}))
  }
}

With-Lock $repo {
  $start = Get-Date
  foreach ($blk in $all) {
    $res = Apply-OnePatch -repo $repo -blk $blk -doApply:$doApply -traceId $trace
    & $print $res
    if ($res.exit -gt $exitMax) { $exitMax = $res.exit }
    Write-KLCLog $repo @{
      version   = '1.3'
      timestamp = (Get-Date).ToUniversalTime().ToString('o')
      traceId   = $trace
      env       = 'DEV'
      mode      = ($doApply ? 'APPLY' : 'DRYRUN')
      service   = 'apply-patches'
      module    = 'scripts/g5/apply-patches.ps1'
      action    = 'patch'
      outcome   = $res.msg
      exitCode  = $res.exit
      target    = $res.target
      matches   = ($res.matches ?? 0)
      backup    = ($res.backup ?? '')
      durationMs= [int]((Get-Date) - $start).TotalMilliseconds
      message   = $res.msg
    }
  }
}

if ($exitMax -eq 11 -and -not $doApply) { exit 11 }        # DRYRUN only
elseif ($exitMax -in 12,13)           { exit $exitMax }     # PRECONDITION/CONFLICT
elseif ($exitMax -eq 0)               { exit 0 }            # all good
elseif ($exitMax -eq 10)              { exit 0 }            # all skipped -> OK
else                                  { exit 1 }            # unknown -> ERROR
 } |
           Sort-Object FullName
  foreach ($f in $files) { [void]$list.Add($f.FullName) }
}
  return $list
}

function Read-TextUtf8([string]$path) {
  return Get-Content -LiteralPath $path -Raw -Encoding UTF8
}

function Write-TextUtf8([string]$path,[string]$text) {
  $dir = Split-Path -LiteralPath $path -Parent
  if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
  $tmp = "$path.tmp.$([guid]::NewGuid().ToString('N'))"
  [System.IO.File]::WriteAllText($tmp, $text, [System.Text.UTF8Encoding]::new($false))
  Move-Item -LiteralPath $tmp -Destination $path -Force
}

function Get-PrevHash([string]$logPath) {
  if (-not (Test-Path -LiteralPath $logPath)) { return ('0' * 64) }
  $last = Get-Content -LiteralPath $logPath -Tail 200 | Where-Object { $_ -match '\S' } | Select-Object -Last 1
  try { return ((ConvertFrom-Json -InputObject $last).hash) } catch { return ('0' * 64) }
}

function Get-Hash([string]$s) {
  $sha = [System.Security.Cryptography.SHA256]::Create()
  $bytes = [System.Text.Encoding]::UTF8.GetBytes($s)
  ($sha.ComputeHash($bytes) | ForEach-Object { $_.ToString('x2') }) -join ''
}

function Write-KLCLog([string]$repo,[hashtable]$obj) {
  $logDir  = Join-Path $repo 'logs'
  if (-not (Test-Path -LiteralPath $logDir)) { New-Item -ItemType Directory -Path $logDir | Out-Null }
  $logPath = Join-Path $logDir 'apply-log.jsonl'
  $prev    = Get-PrevHash $logPath
  $canon   = ($obj.GetEnumerator() | Sort-Object Name | ForEach-Object { "$($_.Name)=$($_.Value)" }) -join '|'
  $hash    = Get-Hash "$prev|$canon"
  $obj['prevHash'] = $prev
  $obj['hash']     = $hash
  $obj['hashAlgo'] = 'SHA256'
  $obj['canonAlgo']= 'kvc-line-v1'
  $json = ($obj | ConvertTo-Json -Depth 6 -Compress)
  Add-Content -LiteralPath $logPath -Value $json
}

function With-Lock([string]$repo,[scriptblock]$body) {
  $lockPath = Join-Path $repo '.gpt5.lock'
  $mineId   = New-TraceId
  if (Test-Path -LiteralPath $lockPath) {
    $age = (Get-Item -LiteralPath $lockPath).LastWriteTimeUtc
    if ((Get-Date).ToUniversalTime().AddMinutes(-10) -gt $age) {
      Rename-Item -LiteralPath $lockPath -NewName (".gpt5.lock.bak-" + (Get-Ts)) -Force
    } else {
      throw "Lock exists: $lockPath (최근 10분 내 실행 흔적)"
    }
  }
  try {
    Set-Content -LiteralPath $lockPath -NoNewline -Encoding UTF8 -Value $mineId
    & $body
  } finally {
    try {
      $current = ''
      if (Test-Path -LiteralPath $lockPath) { $current = Get-Content -LiteralPath $lockPath -Raw -Encoding UTF8 }
      if ($current -eq $mineId) { Remove-Item -LiteralPath $lockPath -Force -ErrorAction SilentlyContinue }
    } catch { }
  }
}

function Parse-PatchBlocks([string]$text) {
  $lines = $text -split "`n"
  $blocks = @()
  $i = 0
  while ($i -lt $lines.Length) {
    if ($lines[$i].Trim() -eq '# PATCH START') {
      $i++
      $meta = @{}
      $find = ''
      $replace = ''
      while ($i -lt $lines.Length -and -not ($lines[$i].Trim() -eq '# PATCH END')) {
        $L = $lines[$i]
        if ($L -match '^\s*TARGET:\s*(.+)$') { $meta.TARGET = $matches[1].Trim() }
        elseif ($L -match '^\s*MODE:\s*(.+)$') { $meta.MODE = $matches[1].Trim().ToLower() }
        elseif ($L -match '^\s*MULTI:\s*(.+)$') { $meta.MULTI = [bool]::Parse($matches[1].Trim()) }
        elseif ($L -match "^\s*FIND\s+<<'EOF'\s*$") {
          $buf = New-Object System.Text.StringBuilder
          $i++
          while ($i -lt $lines.Length -and -not ($lines[$i].Trim() -eq 'EOF')) {
            [void]$buf.AppendLine($lines[$i])
            $i++
          }
          $find = $buf.ToString()
        }
        elseif ($L -match "^\s*REPLACE\s+<<'EOF'\s*$") {
          $buf = New-Object System.Text.StringBuilder
          $i++
          while ($i -lt $lines.Length -and -not ($lines[$i].Trim() -eq 'EOF')) {
            [void]$buf.AppendLine($lines[$i])
            $i++
          }
          $replace = $buf.ToString()
        }
        $i++
      }
      if (-not $meta.TARGET -or -not $meta.MODE) { throw "PATCH 메타 누락(TARGET/MODE)" }
      $blocks += [pscustomobject]@{
        TARGET  = $meta.TARGET
        MODE    = $meta.MODE
        MULTI   = [bool]($meta.MULTI)
        FIND    = $find
        REPLACE = $replace
      }
    } else { $i++ }
  }
  return ,$blocks
}

function Apply-OnePatch([string]$repo, $blk, [bool]$doApply, [string]$traceId) {
  $target = Join-RepoPath $repo $blk.TARGET
  if (-not (Test-Path -LiteralPath $target)) { return @{ exit=12; msg="PRECONDITION: target not found"; target=$blk.TARGET } }

  $orig = Read-TextUtf8 $target
  $new  = $orig
  $matches = 0
  $changed = $false

  # 멱등(SENTINEL): 이미 REPLACE가 있으면 SKIP
  if (-not [string]::IsNullOrEmpty($blk.REPLACE) -and $orig.Contains($blk.REPLACE)) {
    return @{ exit=10; msg="SKIP: already contains REPLACE"; target=$blk.TARGET; matches=0; changed=$false }
  }

  switch ($blk.MODE) {
    'regex-replace' {
      $rx = [System.Text.RegularExpressions.Regex]::new($blk.FIND, 'Singleline,Multiline')
      $matches = ($rx.Matches($orig)).Count
      if ($matches -eq 0) { return @{ exit=10; msg="SKIP: no match"; target=$blk.TARGET; matches=0; changed=$false } }
      if (-not $blk.MULTI -and $matches -gt 1) { return @{ exit=12; msg="PRECONDITION: multiple matches; set MULTI:true"; target=$blk.TARGET; matches=$matches } }
      if ($blk.MULTI) {
        $new = $rx.Replace($orig, $blk.REPLACE)
      } else {
        $m = $rx.Match($orig)
        $new = $orig.Substring(0, $m.Index) + $m.Result($blk.REPLACE) + $orig.Substring($m.Index + $m.Length)
      }
      $changed = ($new -ne $orig)
    }
    'plain-replace' {
      if (-not $orig.Contains($blk.FIND)) { return @{ exit=10; msg="SKIP: FIND not found"; target=$blk.TARGET; matches=0; changed=$false } }
      if ($blk.MULTI) {
        $new = $orig.Replace($blk.FIND, $blk.REPLACE); $matches = ([regex]::Matches($orig, [regex]::Escape($blk.FIND))).Count
      } else {
        $idx = $orig.IndexOf($blk.FIND)
        $new = $orig.Substring(0,$idx) + $blk.REPLACE + $orig.Substring($idx + $blk.FIND.Length); $matches = 1
      }
      $changed = ($new -ne $orig)
    }
    'insert-after' {
      $rx = [System.Text.RegularExpressions.Regex]::new($blk.FIND, 'Singleline,Multiline')
      $m  = $rx.Match($orig)
      if (-not $m.Success) { return @{ exit=10; msg="SKIP: anchor not found"; target=$blk.TARGET; matches=0; changed=$false } }
      if (-not $blk.MULTI -and $rx.Matches($orig).Count -gt 1) { return @{ exit=12; msg="PRECONDITION: multiple anchors; set MULTI:true"; target=$blk.TARGET } }
      if ($blk.MULTI) {
        $new = $rx.Replace($orig, { param($m) $m.Value + $blk.REPLACE })
        $matches = $rx.Matches($orig).Count
      } else {
        $new = $orig.Substring(0,$m.Index+$m.Length) + $blk.REPLACE + $orig.Substring($m.Index+$m.Length)
        $matches = 1
      }
      $changed = ($new -ne $orig)
    }
    'insert-before' {
      $rx = [System.Text.RegularExpressions.Regex]::new($blk.FIND, 'Singleline,Multiline')
      $m  = $rx.Match($orig)
      if (-not $m.Success) { return @{ exit=10; msg="SKIP: anchor not found"; target=$blk.TARGET; matches=0; changed=$false } }
      if (-not $blk.MULTI -and $rx.Matches($orig).Count -gt 1) { return @{ exit=12; msg="PRECONDITION: multiple anchors; set MULTI:true"; target=$blk.TARGET } }
      if ($blk.MULTI) {
        $new = $rx.Replace($orig, { param($m) $blk.REPLACE + $m.Value })
        $matches = $rx.Matches($orig).Count
      } else {
        $new = $orig.Substring(0,$m.Index) + $blk.REPLACE + $orig.Substring($m.Index)
        $matches = 1
      }
      $changed = ($new -ne $orig)
    }
    default { return @{ exit=12; msg="PRECONDITION: unknown MODE '$($blk.MODE)'" ; target=$blk.TARGET } }
  }

  if (-not $changed) { return @{ exit=10; msg="SKIP: no change"; target=$blk.TARGET; matches=$matches; changed=$false } }

  if ($doApply) {
    # ReadOnly 해제(있다면)
    try {
      $fi = Get-Item -LiteralPath $target -Force
      if ($fi.Attributes.HasFlag([IO.FileAttributes]::ReadOnly)) {
        $fi.Attributes = $fi.Attributes -band (-bnot [IO.FileAttributes]::ReadOnly)
      }
    } catch {}
    $bak = "$target.bak-$(Get-Ts)"
    Copy-Item -LiteralPath $target -Destination $bak -Force
    Write-TextUtf8 -path $target -text $new
    return @{ exit=0; msg="APPLY OK"; target=$blk.TARGET; matches=$matches; backup=$bak; changed=$true }
  } else {
    return @{ exit=11; msg="DRYRUN OK (would change)"; target=$blk.TARGET; matches=$matches; changed=$true }
  }
}

# ---------- Main ----------
$repo = Resolve-RepoRoot $Root
$trace = New-TraceId
$doApply = $ConfirmApply.IsPresent -or ($env:CONFIRM_APPLY -and $env:CONFIRM_APPLY.ToString().ToLower() -eq 'true')

$patchFiles = @()
if ($PatchFile)   { $patchFiles += (Resolve-Path -LiteralPath $PatchFile).Path }
if ($PatchesDir)  { $patchFiles += (Get-ChildItem -LiteralPath $PatchesDir -File -Include *.txt,*.patch,*.patch.txt | Sort-Object FullName | % FullName) }
if (-not $PatchFile -and -not $PatchesDir) { $patchFiles += Get-DefaultPatchList $repo }
if (-not $patchFiles) { throw "패치 파일이 없습니다(.kobong\patches.pending.txt 또는 .kobong\patches\*.txt)" }

$all = @()
foreach ($pf in $patchFiles) {
  $txt = Read-TextUtf8 $pf
  $blocks = Parse-PatchBlocks $txt
  if (-not $blocks -or $blocks.Count -eq 0) { throw "유효한 PATCH 블록이 없습니다: $pf" }
  $all += $blocks
}

$exitMax = 0
$print = { param($o)
  if (-not $Quiet) {
    "{0,-7} | {1} | {2} | matches={3} {4}" -f $o.exit, $o.msg, $o.target, ($o.matches ?? 0), ($(if($o.backup){"| bak=$($o.backup)"}else{""}))
  }
}

With-Lock $repo {
  $start = Get-Date
  foreach ($blk in $all) {
    $res = Apply-OnePatch -repo $repo -blk $blk -doApply:$doApply -traceId $trace
    & $print $res
    if ($res.exit -gt $exitMax) { $exitMax = $res.exit }
    Write-KLCLog $repo @{
      version   = '1.3'
      timestamp = (Get-Date).ToUniversalTime().ToString('o')
      traceId   = $trace
      env       = 'DEV'
      mode      = ($doApply ? 'APPLY' : 'DRYRUN')
      service   = 'apply-patches'
      module    = 'scripts/g5/apply-patches.ps1'
      action    = 'patch'
      outcome   = $res.msg
      exitCode  = $res.exit
      target    = $res.target
      matches   = ($res.matches ?? 0)
      backup    = ($res.backup ?? '')
      durationMs= [int]((Get-Date) - $start).TotalMilliseconds
      message   = $res.msg
    }
  }
}

if ($exitMax -eq 11 -and -not $doApply) { exit 11 }        # DRYRUN only
elseif ($exitMax -in 12,13)           { exit $exitMax }     # PRECONDITION/CONFLICT
elseif ($exitMax -eq 0)               { exit 0 }            # all good
elseif ($exitMax -eq 10)              { exit 0 }            # all skipped -> OK
else                                  { exit 1 }            # unknown -> ERROR
 } |
           Sort-Object FullName
  $patchFiles += $files.FullName
}
if (-not $PatchFile -and -not $PatchesDir) { $patchFiles += Get-DefaultPatchList $repo }
if (-not $patchFiles) { throw "패치 파일이 없습니다(.kobong\patches.pending.txt 또는 .kobong\patches\*.txt)" }

$all = @()
foreach ($pf in $patchFiles) {
  $txt = Read-TextUtf8 $pf
  $blocks = Parse-PatchBlocks $txt
  if (-not $blocks -or $blocks.Count -eq 0) { throw "유효한 PATCH 블록이 없습니다: $pf" }
  $all += $blocks
}

$exitMax = 0
$print = { param($o)
  if (-not $Quiet) {
    "{0,-7} | {1} | {2} | matches={3} {4}" -f $o.exit, $o.msg, $o.target, ($o.matches ?? 0), ($(if($o.backup){"| bak=$($o.backup)"}else{""}))
  }
}

With-Lock $repo {
  $start = Get-Date
  foreach ($blk in $all) {
    $res = Apply-OnePatch -repo $repo -blk $blk -doApply:$doApply -traceId $trace
    & $print $res
    if ($res.exit -gt $exitMax) { $exitMax = $res.exit }
    Write-KLCLog $repo @{
      version   = '1.3'
      timestamp = (Get-Date).ToUniversalTime().ToString('o')
      traceId   = $trace
      env       = 'DEV'
      mode      = ($doApply ? 'APPLY' : 'DRYRUN')
      service   = 'apply-patches'
      module    = 'scripts/g5/apply-patches.ps1'
      action    = 'patch'
      outcome   = $res.msg
      exitCode  = $res.exit
      target    = $res.target
      matches   = ($res.matches ?? 0)
      backup    = ($res.backup ?? '')
      durationMs= [int]((Get-Date) - $start).TotalMilliseconds
      message   = $res.msg
    }
  }
}

if ($exitMax -eq 11 -and -not $doApply) { exit 11 }        # DRYRUN only
elseif ($exitMax -in 12,13)           { exit $exitMax }     # PRECONDITION/CONFLICT
elseif ($exitMax -eq 0)               { exit 0 }            # all good
elseif ($exitMax -eq 10)              { exit 0 }            # all skipped -> OK
else                                  { exit 1 }            # unknown -> ERROR
 } |
           Sort-Object FullName
  foreach ($f in $files) { [void]$list.Add($f.FullName) }
}
  return $list
}

function Read-TextUtf8([string]$path) {
  return Get-Content -LiteralPath $path -Raw -Encoding UTF8
}

function Write-TextUtf8([string]$path,[string]$text) {
  $dir = Split-Path -LiteralPath $path -Parent
  if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
  $tmp = "$path.tmp.$([guid]::NewGuid().ToString('N'))"
  [System.IO.File]::WriteAllText($tmp, $text, [System.Text.UTF8Encoding]::new($false))
  Move-Item -LiteralPath $tmp -Destination $path -Force
}

function Get-PrevHash([string]$logPath) {
  if (-not (Test-Path -LiteralPath $logPath)) { return ('0' * 64) }
  $last = Get-Content -LiteralPath $logPath -Tail 200 | Where-Object { $_ -match '\S' } | Select-Object -Last 1
  try { return ((ConvertFrom-Json -InputObject $last).hash) } catch { return ('0' * 64) }
}

function Get-Hash([string]$s) {
  $sha = [System.Security.Cryptography.SHA256]::Create()
  $bytes = [System.Text.Encoding]::UTF8.GetBytes($s)
  ($sha.ComputeHash($bytes) | ForEach-Object { $_.ToString('x2') }) -join ''
}

function Write-KLCLog([string]$repo,[hashtable]$obj) {
  $logDir  = Join-Path $repo 'logs'
  if (-not (Test-Path -LiteralPath $logDir)) { New-Item -ItemType Directory -Path $logDir | Out-Null }
  $logPath = Join-Path $logDir 'apply-log.jsonl'
  $prev    = Get-PrevHash $logPath
  $canon   = ($obj.GetEnumerator() | Sort-Object Name | ForEach-Object { "$($_.Name)=$($_.Value)" }) -join '|'
  $hash    = Get-Hash "$prev|$canon"
  $obj['prevHash'] = $prev
  $obj['hash']     = $hash
  $obj['hashAlgo'] = 'SHA256'
  $obj['canonAlgo']= 'kvc-line-v1'
  $json = ($obj | ConvertTo-Json -Depth 6 -Compress)
  Add-Content -LiteralPath $logPath -Value $json
}

function With-Lock([string]$repo,[scriptblock]$body) {
  $lockPath = Join-Path $repo '.gpt5.lock'
  $mineId   = New-TraceId
  if (Test-Path -LiteralPath $lockPath) {
    $age = (Get-Item -LiteralPath $lockPath).LastWriteTimeUtc
    if ((Get-Date).ToUniversalTime().AddMinutes(-10) -gt $age) {
      Rename-Item -LiteralPath $lockPath -NewName (".gpt5.lock.bak-" + (Get-Ts)) -Force
    } else {
      throw "Lock exists: $lockPath (최근 10분 내 실행 흔적)"
    }
  }
  try {
    Set-Content -LiteralPath $lockPath -NoNewline -Encoding UTF8 -Value $mineId
    & $body
  } finally {
    try {
      $current = ''
      if (Test-Path -LiteralPath $lockPath) { $current = Get-Content -LiteralPath $lockPath -Raw -Encoding UTF8 }
      if ($current -eq $mineId) { Remove-Item -LiteralPath $lockPath -Force -ErrorAction SilentlyContinue }
    } catch { }
  }
}

function Parse-PatchBlocks([string]$text) {
  $lines = $text -split "`n"
  $blocks = @()
  $i = 0
  while ($i -lt $lines.Length) {
    if ($lines[$i].Trim() -eq '# PATCH START') {
      $i++
      $meta = @{}
      $find = ''
      $replace = ''
      while ($i -lt $lines.Length -and -not ($lines[$i].Trim() -eq '# PATCH END')) {
        $L = $lines[$i]
        if ($L -match '^\s*TARGET:\s*(.+)$') { $meta.TARGET = $matches[1].Trim() }
        elseif ($L -match '^\s*MODE:\s*(.+)$') { $meta.MODE = $matches[1].Trim().ToLower() }
        elseif ($L -match '^\s*MULTI:\s*(.+)$') { $meta.MULTI = [bool]::Parse($matches[1].Trim()) }
        elseif ($L -match "^\s*FIND\s+<<'EOF'\s*$") {
          $buf = New-Object System.Text.StringBuilder
          $i++
          while ($i -lt $lines.Length -and -not ($lines[$i].Trim() -eq 'EOF')) {
            [void]$buf.AppendLine($lines[$i])
            $i++
          }
          $find = $buf.ToString()
        }
        elseif ($L -match "^\s*REPLACE\s+<<'EOF'\s*$") {
          $buf = New-Object System.Text.StringBuilder
          $i++
          while ($i -lt $lines.Length -and -not ($lines[$i].Trim() -eq 'EOF')) {
            [void]$buf.AppendLine($lines[$i])
            $i++
          }
          $replace = $buf.ToString()
        }
        $i++
      }
      if (-not $meta.TARGET -or -not $meta.MODE) { throw "PATCH 메타 누락(TARGET/MODE)" }
      $blocks += [pscustomobject]@{
        TARGET  = $meta.TARGET
        MODE    = $meta.MODE
        MULTI   = [bool]($meta.MULTI)
        FIND    = $find
        REPLACE = $replace
      }
    } else { $i++ }
  }
  return ,$blocks
}

function Apply-OnePatch([string]$repo, $blk, [bool]$doApply, [string]$traceId) {
  $target = Join-RepoPath $repo $blk.TARGET
  if (-not (Test-Path -LiteralPath $target)) { return @{ exit=12; msg="PRECONDITION: target not found"; target=$blk.TARGET } }

  $orig = Read-TextUtf8 $target
  $new  = $orig
  $matches = 0
  $changed = $false

  # 멱등(SENTINEL): 이미 REPLACE가 있으면 SKIP
  if (-not [string]::IsNullOrEmpty($blk.REPLACE) -and $orig.Contains($blk.REPLACE)) {
    return @{ exit=10; msg="SKIP: already contains REPLACE"; target=$blk.TARGET; matches=0; changed=$false }
  }

  switch ($blk.MODE) {
    'regex-replace' {
      $rx = [System.Text.RegularExpressions.Regex]::new($blk.FIND, 'Singleline,Multiline')
      $matches = ($rx.Matches($orig)).Count
      if ($matches -eq 0) { return @{ exit=10; msg="SKIP: no match"; target=$blk.TARGET; matches=0; changed=$false } }
      if (-not $blk.MULTI -and $matches -gt 1) { return @{ exit=12; msg="PRECONDITION: multiple matches; set MULTI:true"; target=$blk.TARGET; matches=$matches } }
      if ($blk.MULTI) {
        $new = $rx.Replace($orig, $blk.REPLACE)
      } else {
        $m = $rx.Match($orig)
        $new = $orig.Substring(0, $m.Index) + $m.Result($blk.REPLACE) + $orig.Substring($m.Index + $m.Length)
      }
      $changed = ($new -ne $orig)
    }
    'plain-replace' {
      if (-not $orig.Contains($blk.FIND)) { return @{ exit=10; msg="SKIP: FIND not found"; target=$blk.TARGET; matches=0; changed=$false } }
      if ($blk.MULTI) {
        $new = $orig.Replace($blk.FIND, $blk.REPLACE); $matches = ([regex]::Matches($orig, [regex]::Escape($blk.FIND))).Count
      } else {
        $idx = $orig.IndexOf($blk.FIND)
        $new = $orig.Substring(0,$idx) + $blk.REPLACE + $orig.Substring($idx + $blk.FIND.Length); $matches = 1
      }
      $changed = ($new -ne $orig)
    }
    'insert-after' {
      $rx = [System.Text.RegularExpressions.Regex]::new($blk.FIND, 'Singleline,Multiline')
      $m  = $rx.Match($orig)
      if (-not $m.Success) { return @{ exit=10; msg="SKIP: anchor not found"; target=$blk.TARGET; matches=0; changed=$false } }
      if (-not $blk.MULTI -and $rx.Matches($orig).Count -gt 1) { return @{ exit=12; msg="PRECONDITION: multiple anchors; set MULTI:true"; target=$blk.TARGET } }
      if ($blk.MULTI) {
        $new = $rx.Replace($orig, { param($m) $m.Value + $blk.REPLACE })
        $matches = $rx.Matches($orig).Count
      } else {
        $new = $orig.Substring(0,$m.Index+$m.Length) + $blk.REPLACE + $orig.Substring($m.Index+$m.Length)
        $matches = 1
      }
      $changed = ($new -ne $orig)
    }
    'insert-before' {
      $rx = [System.Text.RegularExpressions.Regex]::new($blk.FIND, 'Singleline,Multiline')
      $m  = $rx.Match($orig)
      if (-not $m.Success) { return @{ exit=10; msg="SKIP: anchor not found"; target=$blk.TARGET; matches=0; changed=$false } }
      if (-not $blk.MULTI -and $rx.Matches($orig).Count -gt 1) { return @{ exit=12; msg="PRECONDITION: multiple anchors; set MULTI:true"; target=$blk.TARGET } }
      if ($blk.MULTI) {
        $new = $rx.Replace($orig, { param($m) $blk.REPLACE + $m.Value })
        $matches = $rx.Matches($orig).Count
      } else {
        $new = $orig.Substring(0,$m.Index) + $blk.REPLACE + $orig.Substring($m.Index)
        $matches = 1
      }
      $changed = ($new -ne $orig)
    }
    default { return @{ exit=12; msg="PRECONDITION: unknown MODE '$($blk.MODE)'" ; target=$blk.TARGET } }
  }

  if (-not $changed) { return @{ exit=10; msg="SKIP: no change"; target=$blk.TARGET; matches=$matches; changed=$false } }

  if ($doApply) {
    # ReadOnly 해제(있다면)
    try {
      $fi = Get-Item -LiteralPath $target -Force
      if ($fi.Attributes.HasFlag([IO.FileAttributes]::ReadOnly)) {
        $fi.Attributes = $fi.Attributes -band (-bnot [IO.FileAttributes]::ReadOnly)
      }
    } catch {}
    $bak = "$target.bak-$(Get-Ts)"
    Copy-Item -LiteralPath $target -Destination $bak -Force
    Write-TextUtf8 -path $target -text $new
    return @{ exit=0; msg="APPLY OK"; target=$blk.TARGET; matches=$matches; backup=$bak; changed=$true }
  } else {
    return @{ exit=11; msg="DRYRUN OK (would change)"; target=$blk.TARGET; matches=$matches; changed=$true }
  }
}

# ---------- Main ----------
$repo = Resolve-RepoRoot $Root
$trace = New-TraceId
$doApply = $ConfirmApply.IsPresent -or ($env:CONFIRM_APPLY -and $env:CONFIRM_APPLY.ToString().ToLower() -eq 'true')

$patchFiles = @()
if ($PatchFile)   { $patchFiles += (Resolve-Path -LiteralPath $PatchFile).Path }
if ($PatchesDir) {
  $files = Get-ChildItem -Path $PatchesDir -File |
           Where-Object { # APPLY IN SHELL
#requires -Version 7.0
<#
  KoBong apply-patches.ps1 — v1.1 (2025-10-22)
  원칙: PS7-First, DRYRUN→APPLY, 레포 샌드박스, .gpt5.lock, .bak 스냅샷, 원자 교체, KLC 최소 1로그
  종료코드: 0=OK, 11=DRYRUN, 12=PRECONDITION, 13=CONFLICT, 1=ERROR
#>

[CmdletBinding()]
param(
  [Parameter()][string]$Root = (Get-Location).Path,
  [Parameter()][string]$PatchFile,
  [Parameter()][string]$PatchesDir,
  [switch]$ConfirmApply,
  [switch]$Quiet
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)

function New-TraceId { ([guid]::NewGuid()).ToString('N') }
function Get-Ts     { Get-Date -Format 'yyyyMMdd-HHmmss' }

function Resolve-RepoRoot([string]$root) {
  $p = Resolve-Path -LiteralPath $root
  if (-not $p) { throw "Root not found: $root" }
  return $p.Path
}

function Join-RepoPath([string]$repo,[string]$rel) {
  if ([string]::IsNullOrWhiteSpace($rel)) { throw "TARGET path is empty." }
  if ($rel -match '^\s*[./\\]*\.\.[/\\]') { throw "Path escapes repo: $rel" }
  $full = Join-Path -LiteralPath $repo -ChildPath $rel
  $norm = [System.IO.Path]::GetFullPath($full)
  if (-not $norm.StartsWith([System.IO.Path]::GetFullPath($repo), [StringComparison]::OrdinalIgnoreCase)) {
    throw "Path escapes repo: $rel"
  }
  return $norm
}

function Get-DefaultPatchList([string]$repo) {
  $list = [System.Collections.Generic.List[string]]::new()
  $pending = Join-Path $repo '.kobong\patches.pending.txt'
  $dir1    = Join-Path $repo '.kobong\patches'
  if (Test-Path -LiteralPath $pending) { $list.Add($pending) | Out-Null }
  if (Test-Path -LiteralPath $dir1) {
  $files = Get-ChildItem -Path $dir1 -File |
           Where-Object { # APPLY IN SHELL
#requires -Version 7.0
<#
  KoBong apply-patches.ps1 — v1.1 (2025-10-22)
  원칙: PS7-First, DRYRUN→APPLY, 레포 샌드박스, .gpt5.lock, .bak 스냅샷, 원자 교체, KLC 최소 1로그
  종료코드: 0=OK, 11=DRYRUN, 12=PRECONDITION, 13=CONFLICT, 1=ERROR
#>

[CmdletBinding()]
param(
  [Parameter()][string]$Root = (Get-Location).Path,
  [Parameter()][string]$PatchFile,
  [Parameter()][string]$PatchesDir,
  [switch]$ConfirmApply,
  [switch]$Quiet
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)

function New-TraceId { ([guid]::NewGuid()).ToString('N') }
function Get-Ts     { Get-Date -Format 'yyyyMMdd-HHmmss' }

function Resolve-RepoRoot([string]$root) {
  $p = Resolve-Path -LiteralPath $root
  if (-not $p) { throw "Root not found: $root" }
  return $p.Path
}

function Join-RepoPath([string]$repo,[string]$rel) {
  if ([string]::IsNullOrWhiteSpace($rel)) { throw "TARGET path is empty." }
  if ($rel -match '^\s*[./\\]*\.\.[/\\]') { throw "Path escapes repo: $rel" }
  $full = Join-Path -LiteralPath $repo -ChildPath $rel
  $norm = [System.IO.Path]::GetFullPath($full)
  if (-not $norm.StartsWith([System.IO.Path]::GetFullPath($repo), [StringComparison]::OrdinalIgnoreCase)) {
    throw "Path escapes repo: $rel"
  }
  return $norm
}

function Get-DefaultPatchList([string]$repo) {
  $list = [System.Collections.Generic.List[string]]::new()
  $pending = Join-Path $repo '.kobong\patches.pending.txt'
  $dir1    = Join-Path $repo '.kobong\patches'
  if (Test-Path -LiteralPath $pending) { $list.Add($pending) | Out-Null }
  if (Test-Path -LiteralPath $dir1) {
    $list.AddRange( Get-ChildItem -LiteralPath $dir1 -File -Include *.txt,*.patch,*.patch.txt | Sort-Object FullName | % { $_.FullName } )
  }
  return $list
}

function Read-TextUtf8([string]$path) {
  return Get-Content -LiteralPath $path -Raw -Encoding UTF8
}

function Write-TextUtf8([string]$path,[string]$text) {
  $dir = Split-Path -LiteralPath $path -Parent
  if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
  $tmp = "$path.tmp.$([guid]::NewGuid().ToString('N'))"
  [System.IO.File]::WriteAllText($tmp, $text, [System.Text.UTF8Encoding]::new($false))
  Move-Item -LiteralPath $tmp -Destination $path -Force
}

function Get-PrevHash([string]$logPath) {
  if (-not (Test-Path -LiteralPath $logPath)) { return ('0' * 64) }
  $last = Get-Content -LiteralPath $logPath -Tail 200 | Where-Object { $_ -match '\S' } | Select-Object -Last 1
  try { return ((ConvertFrom-Json -InputObject $last).hash) } catch { return ('0' * 64) }
}

function Get-Hash([string]$s) {
  $sha = [System.Security.Cryptography.SHA256]::Create()
  $bytes = [System.Text.Encoding]::UTF8.GetBytes($s)
  ($sha.ComputeHash($bytes) | ForEach-Object { $_.ToString('x2') }) -join ''
}

function Write-KLCLog([string]$repo,[hashtable]$obj) {
  $logDir  = Join-Path $repo 'logs'
  if (-not (Test-Path -LiteralPath $logDir)) { New-Item -ItemType Directory -Path $logDir | Out-Null }
  $logPath = Join-Path $logDir 'apply-log.jsonl'
  $prev    = Get-PrevHash $logPath
  $canon   = ($obj.GetEnumerator() | Sort-Object Name | ForEach-Object { "$($_.Name)=$($_.Value)" }) -join '|'
  $hash    = Get-Hash "$prev|$canon"
  $obj['prevHash'] = $prev
  $obj['hash']     = $hash
  $obj['hashAlgo'] = 'SHA256'
  $obj['canonAlgo']= 'kvc-line-v1'
  $json = ($obj | ConvertTo-Json -Depth 6 -Compress)
  Add-Content -LiteralPath $logPath -Value $json
}

function With-Lock([string]$repo,[scriptblock]$body) {
  $lockPath = Join-Path $repo '.gpt5.lock'
  $mineId   = New-TraceId
  if (Test-Path -LiteralPath $lockPath) {
    $age = (Get-Item -LiteralPath $lockPath).LastWriteTimeUtc
    if ((Get-Date).ToUniversalTime().AddMinutes(-10) -gt $age) {
      Rename-Item -LiteralPath $lockPath -NewName (".gpt5.lock.bak-" + (Get-Ts)) -Force
    } else {
      throw "Lock exists: $lockPath (최근 10분 내 실행 흔적)"
    }
  }
  try {
    Set-Content -LiteralPath $lockPath -NoNewline -Encoding UTF8 -Value $mineId
    & $body
  } finally {
    try {
      $current = ''
      if (Test-Path -LiteralPath $lockPath) { $current = Get-Content -LiteralPath $lockPath -Raw -Encoding UTF8 }
      if ($current -eq $mineId) { Remove-Item -LiteralPath $lockPath -Force -ErrorAction SilentlyContinue }
    } catch { }
  }
}

function Parse-PatchBlocks([string]$text) {
  $lines = $text -split "`n"
  $blocks = @()
  $i = 0
  while ($i -lt $lines.Length) {
    if ($lines[$i].Trim() -eq '# PATCH START') {
      $i++
      $meta = @{}
      $find = ''
      $replace = ''
      while ($i -lt $lines.Length -and -not ($lines[$i].Trim() -eq '# PATCH END')) {
        $L = $lines[$i]
        if ($L -match '^\s*TARGET:\s*(.+)$') { $meta.TARGET = $matches[1].Trim() }
        elseif ($L -match '^\s*MODE:\s*(.+)$') { $meta.MODE = $matches[1].Trim().ToLower() }
        elseif ($L -match '^\s*MULTI:\s*(.+)$') { $meta.MULTI = [bool]::Parse($matches[1].Trim()) }
        elseif ($L -match "^\s*FIND\s+<<'EOF'\s*$") {
          $buf = New-Object System.Text.StringBuilder
          $i++
          while ($i -lt $lines.Length -and -not ($lines[$i].Trim() -eq 'EOF')) {
            [void]$buf.AppendLine($lines[$i])
            $i++
          }
          $find = $buf.ToString()
        }
        elseif ($L -match "^\s*REPLACE\s+<<'EOF'\s*$") {
          $buf = New-Object System.Text.StringBuilder
          $i++
          while ($i -lt $lines.Length -and -not ($lines[$i].Trim() -eq 'EOF')) {
            [void]$buf.AppendLine($lines[$i])
            $i++
          }
          $replace = $buf.ToString()
        }
        $i++
      }
      if (-not $meta.TARGET -or -not $meta.MODE) { throw "PATCH 메타 누락(TARGET/MODE)" }
      $blocks += [pscustomobject]@{
        TARGET  = $meta.TARGET
        MODE    = $meta.MODE
        MULTI   = [bool]($meta.MULTI)
        FIND    = $find
        REPLACE = $replace
      }
    } else { $i++ }
  }
  return ,$blocks
}

function Apply-OnePatch([string]$repo, $blk, [bool]$doApply, [string]$traceId) {
  $target = Join-RepoPath $repo $blk.TARGET
  if (-not (Test-Path -LiteralPath $target)) { return @{ exit=12; msg="PRECONDITION: target not found"; target=$blk.TARGET } }

  $orig = Read-TextUtf8 $target
  $new  = $orig
  $matches = 0
  $changed = $false

  # 멱등(SENTINEL): 이미 REPLACE가 있으면 SKIP
  if (-not [string]::IsNullOrEmpty($blk.REPLACE) -and $orig.Contains($blk.REPLACE)) {
    return @{ exit=10; msg="SKIP: already contains REPLACE"; target=$blk.TARGET; matches=0; changed=$false }
  }

  switch ($blk.MODE) {
    'regex-replace' {
      $rx = [System.Text.RegularExpressions.Regex]::new($blk.FIND, 'Singleline,Multiline')
      $matches = ($rx.Matches($orig)).Count
      if ($matches -eq 0) { return @{ exit=10; msg="SKIP: no match"; target=$blk.TARGET; matches=0; changed=$false } }
      if (-not $blk.MULTI -and $matches -gt 1) { return @{ exit=12; msg="PRECONDITION: multiple matches; set MULTI:true"; target=$blk.TARGET; matches=$matches } }
      if ($blk.MULTI) {
        $new = $rx.Replace($orig, $blk.REPLACE)
      } else {
        $m = $rx.Match($orig)
        $new = $orig.Substring(0, $m.Index) + $m.Result($blk.REPLACE) + $orig.Substring($m.Index + $m.Length)
      }
      $changed = ($new -ne $orig)
    }
    'plain-replace' {
      if (-not $orig.Contains($blk.FIND)) { return @{ exit=10; msg="SKIP: FIND not found"; target=$blk.TARGET; matches=0; changed=$false } }
      if ($blk.MULTI) {
        $new = $orig.Replace($blk.FIND, $blk.REPLACE); $matches = ([regex]::Matches($orig, [regex]::Escape($blk.FIND))).Count
      } else {
        $idx = $orig.IndexOf($blk.FIND)
        $new = $orig.Substring(0,$idx) + $blk.REPLACE + $orig.Substring($idx + $blk.FIND.Length); $matches = 1
      }
      $changed = ($new -ne $orig)
    }
    'insert-after' {
      $rx = [System.Text.RegularExpressions.Regex]::new($blk.FIND, 'Singleline,Multiline')
      $m  = $rx.Match($orig)
      if (-not $m.Success) { return @{ exit=10; msg="SKIP: anchor not found"; target=$blk.TARGET; matches=0; changed=$false } }
      if (-not $blk.MULTI -and $rx.Matches($orig).Count -gt 1) { return @{ exit=12; msg="PRECONDITION: multiple anchors; set MULTI:true"; target=$blk.TARGET } }
      if ($blk.MULTI) {
        $new = $rx.Replace($orig, { param($m) $m.Value + $blk.REPLACE })
        $matches = $rx.Matches($orig).Count
      } else {
        $new = $orig.Substring(0,$m.Index+$m.Length) + $blk.REPLACE + $orig.Substring($m.Index+$m.Length)
        $matches = 1
      }
      $changed = ($new -ne $orig)
    }
    'insert-before' {
      $rx = [System.Text.RegularExpressions.Regex]::new($blk.FIND, 'Singleline,Multiline')
      $m  = $rx.Match($orig)
      if (-not $m.Success) { return @{ exit=10; msg="SKIP: anchor not found"; target=$blk.TARGET; matches=0; changed=$false } }
      if (-not $blk.MULTI -and $rx.Matches($orig).Count -gt 1) { return @{ exit=12; msg="PRECONDITION: multiple anchors; set MULTI:true"; target=$blk.TARGET } }
      if ($blk.MULTI) {
        $new = $rx.Replace($orig, { param($m) $blk.REPLACE + $m.Value })
        $matches = $rx.Matches($orig).Count
      } else {
        $new = $orig.Substring(0,$m.Index) + $blk.REPLACE + $orig.Substring($m.Index)
        $matches = 1
      }
      $changed = ($new -ne $orig)
    }
    default { return @{ exit=12; msg="PRECONDITION: unknown MODE '$($blk.MODE)'" ; target=$blk.TARGET } }
  }

  if (-not $changed) { return @{ exit=10; msg="SKIP: no change"; target=$blk.TARGET; matches=$matches; changed=$false } }

  if ($doApply) {
    # ReadOnly 해제(있다면)
    try {
      $fi = Get-Item -LiteralPath $target -Force
      if ($fi.Attributes.HasFlag([IO.FileAttributes]::ReadOnly)) {
        $fi.Attributes = $fi.Attributes -band (-bnot [IO.FileAttributes]::ReadOnly)
      }
    } catch {}
    $bak = "$target.bak-$(Get-Ts)"
    Copy-Item -LiteralPath $target -Destination $bak -Force
    Write-TextUtf8 -path $target -text $new
    return @{ exit=0; msg="APPLY OK"; target=$blk.TARGET; matches=$matches; backup=$bak; changed=$true }
  } else {
    return @{ exit=11; msg="DRYRUN OK (would change)"; target=$blk.TARGET; matches=$matches; changed=$true }
  }
}

# ---------- Main ----------
$repo = Resolve-RepoRoot $Root
$trace = New-TraceId
$doApply = $ConfirmApply.IsPresent -or ($env:CONFIRM_APPLY -and $env:CONFIRM_APPLY.ToString().ToLower() -eq 'true')

$patchFiles = @()
if ($PatchFile)   { $patchFiles += (Resolve-Path -LiteralPath $PatchFile).Path }
if ($PatchesDir)  { $patchFiles += (Get-ChildItem -LiteralPath $PatchesDir -File -Include *.txt,*.patch,*.patch.txt | Sort-Object FullName | % FullName) }
if (-not $PatchFile -and -not $PatchesDir) { $patchFiles += Get-DefaultPatchList $repo }
if (-not $patchFiles) { throw "패치 파일이 없습니다(.kobong\patches.pending.txt 또는 .kobong\patches\*.txt)" }

$all = @()
foreach ($pf in $patchFiles) {
  $txt = Read-TextUtf8 $pf
  $blocks = Parse-PatchBlocks $txt
  if (-not $blocks -or $blocks.Count -eq 0) { throw "유효한 PATCH 블록이 없습니다: $pf" }
  $all += $blocks
}

$exitMax = 0
$print = { param($o)
  if (-not $Quiet) {
    "{0,-7} | {1} | {2} | matches={3} {4}" -f $o.exit, $o.msg, $o.target, ($o.matches ?? 0), ($(if($o.backup){"| bak=$($o.backup)"}else{""}))
  }
}

With-Lock $repo {
  $start = Get-Date
  foreach ($blk in $all) {
    $res = Apply-OnePatch -repo $repo -blk $blk -doApply:$doApply -traceId $trace
    & $print $res
    if ($res.exit -gt $exitMax) { $exitMax = $res.exit }
    Write-KLCLog $repo @{
      version   = '1.3'
      timestamp = (Get-Date).ToUniversalTime().ToString('o')
      traceId   = $trace
      env       = 'DEV'
      mode      = ($doApply ? 'APPLY' : 'DRYRUN')
      service   = 'apply-patches'
      module    = 'scripts/g5/apply-patches.ps1'
      action    = 'patch'
      outcome   = $res.msg
      exitCode  = $res.exit
      target    = $res.target
      matches   = ($res.matches ?? 0)
      backup    = ($res.backup ?? '')
      durationMs= [int]((Get-Date) - $start).TotalMilliseconds
      message   = $res.msg
    }
  }
}

if ($exitMax -eq 11 -and -not $doApply) { exit 11 }        # DRYRUN only
elseif ($exitMax -in 12,13)           { exit $exitMax }     # PRECONDITION/CONFLICT
elseif ($exitMax -eq 0)               { exit 0 }            # all good
elseif ($exitMax -eq 10)              { exit 0 }            # all skipped -> OK
else                                  { exit 1 }            # unknown -> ERROR
.Name -match '\.(txt|patch|patch\.txt)
  return $list
}

function Read-TextUtf8([string]$path) {
  return Get-Content -LiteralPath $path -Raw -Encoding UTF8
}

function Write-TextUtf8([string]$path,[string]$text) {
  $dir = Split-Path -LiteralPath $path -Parent
  if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
  $tmp = "$path.tmp.$([guid]::NewGuid().ToString('N'))"
  [System.IO.File]::WriteAllText($tmp, $text, [System.Text.UTF8Encoding]::new($false))
  Move-Item -LiteralPath $tmp -Destination $path -Force
}

function Get-PrevHash([string]$logPath) {
  if (-not (Test-Path -LiteralPath $logPath)) { return ('0' * 64) }
  $last = Get-Content -LiteralPath $logPath -Tail 200 | Where-Object { $_ -match '\S' } | Select-Object -Last 1
  try { return ((ConvertFrom-Json -InputObject $last).hash) } catch { return ('0' * 64) }
}

function Get-Hash([string]$s) {
  $sha = [System.Security.Cryptography.SHA256]::Create()
  $bytes = [System.Text.Encoding]::UTF8.GetBytes($s)
  ($sha.ComputeHash($bytes) | ForEach-Object { $_.ToString('x2') }) -join ''
}

function Write-KLCLog([string]$repo,[hashtable]$obj) {
  $logDir  = Join-Path $repo 'logs'
  if (-not (Test-Path -LiteralPath $logDir)) { New-Item -ItemType Directory -Path $logDir | Out-Null }
  $logPath = Join-Path $logDir 'apply-log.jsonl'
  $prev    = Get-PrevHash $logPath
  $canon   = ($obj.GetEnumerator() | Sort-Object Name | ForEach-Object { "$($_.Name)=$($_.Value)" }) -join '|'
  $hash    = Get-Hash "$prev|$canon"
  $obj['prevHash'] = $prev
  $obj['hash']     = $hash
  $obj['hashAlgo'] = 'SHA256'
  $obj['canonAlgo']= 'kvc-line-v1'
  $json = ($obj | ConvertTo-Json -Depth 6 -Compress)
  Add-Content -LiteralPath $logPath -Value $json
}

function With-Lock([string]$repo,[scriptblock]$body) {
  $lockPath = Join-Path $repo '.gpt5.lock'
  $mineId   = New-TraceId
  if (Test-Path -LiteralPath $lockPath) {
    $age = (Get-Item -LiteralPath $lockPath).LastWriteTimeUtc
    if ((Get-Date).ToUniversalTime().AddMinutes(-10) -gt $age) {
      Rename-Item -LiteralPath $lockPath -NewName (".gpt5.lock.bak-" + (Get-Ts)) -Force
    } else {
      throw "Lock exists: $lockPath (최근 10분 내 실행 흔적)"
    }
  }
  try {
    Set-Content -LiteralPath $lockPath -NoNewline -Encoding UTF8 -Value $mineId
    & $body
  } finally {
    try {
      $current = ''
      if (Test-Path -LiteralPath $lockPath) { $current = Get-Content -LiteralPath $lockPath -Raw -Encoding UTF8 }
      if ($current -eq $mineId) { Remove-Item -LiteralPath $lockPath -Force -ErrorAction SilentlyContinue }
    } catch { }
  }
}

function Parse-PatchBlocks([string]$text) {
  $lines = $text -split "`n"
  $blocks = @()
  $i = 0
  while ($i -lt $lines.Length) {
    if ($lines[$i].Trim() -eq '# PATCH START') {
      $i++
      $meta = @{}
      $find = ''
      $replace = ''
      while ($i -lt $lines.Length -and -not ($lines[$i].Trim() -eq '# PATCH END')) {
        $L = $lines[$i]
        if ($L -match '^\s*TARGET:\s*(.+)$') { $meta.TARGET = $matches[1].Trim() }
        elseif ($L -match '^\s*MODE:\s*(.+)$') { $meta.MODE = $matches[1].Trim().ToLower() }
        elseif ($L -match '^\s*MULTI:\s*(.+)$') { $meta.MULTI = [bool]::Parse($matches[1].Trim()) }
        elseif ($L -match "^\s*FIND\s+<<'EOF'\s*$") {
          $buf = New-Object System.Text.StringBuilder
          $i++
          while ($i -lt $lines.Length -and -not ($lines[$i].Trim() -eq 'EOF')) {
            [void]$buf.AppendLine($lines[$i])
            $i++
          }
          $find = $buf.ToString()
        }
        elseif ($L -match "^\s*REPLACE\s+<<'EOF'\s*$") {
          $buf = New-Object System.Text.StringBuilder
          $i++
          while ($i -lt $lines.Length -and -not ($lines[$i].Trim() -eq 'EOF')) {
            [void]$buf.AppendLine($lines[$i])
            $i++
          }
          $replace = $buf.ToString()
        }
        $i++
      }
      if (-not $meta.TARGET -or -not $meta.MODE) { throw "PATCH 메타 누락(TARGET/MODE)" }
      $blocks += [pscustomobject]@{
        TARGET  = $meta.TARGET
        MODE    = $meta.MODE
        MULTI   = [bool]($meta.MULTI)
        FIND    = $find
        REPLACE = $replace
      }
    } else { $i++ }
  }
  return ,$blocks
}

function Apply-OnePatch([string]$repo, $blk, [bool]$doApply, [string]$traceId) {
  $target = Join-RepoPath $repo $blk.TARGET
  if (-not (Test-Path -LiteralPath $target)) { return @{ exit=12; msg="PRECONDITION: target not found"; target=$blk.TARGET } }

  $orig = Read-TextUtf8 $target
  $new  = $orig
  $matches = 0
  $changed = $false

  # 멱등(SENTINEL): 이미 REPLACE가 있으면 SKIP
  if (-not [string]::IsNullOrEmpty($blk.REPLACE) -and $orig.Contains($blk.REPLACE)) {
    return @{ exit=10; msg="SKIP: already contains REPLACE"; target=$blk.TARGET; matches=0; changed=$false }
  }

  switch ($blk.MODE) {
    'regex-replace' {
      $rx = [System.Text.RegularExpressions.Regex]::new($blk.FIND, 'Singleline,Multiline')
      $matches = ($rx.Matches($orig)).Count
      if ($matches -eq 0) { return @{ exit=10; msg="SKIP: no match"; target=$blk.TARGET; matches=0; changed=$false } }
      if (-not $blk.MULTI -and $matches -gt 1) { return @{ exit=12; msg="PRECONDITION: multiple matches; set MULTI:true"; target=$blk.TARGET; matches=$matches } }
      if ($blk.MULTI) {
        $new = $rx.Replace($orig, $blk.REPLACE)
      } else {
        $m = $rx.Match($orig)
        $new = $orig.Substring(0, $m.Index) + $m.Result($blk.REPLACE) + $orig.Substring($m.Index + $m.Length)
      }
      $changed = ($new -ne $orig)
    }
    'plain-replace' {
      if (-not $orig.Contains($blk.FIND)) { return @{ exit=10; msg="SKIP: FIND not found"; target=$blk.TARGET; matches=0; changed=$false } }
      if ($blk.MULTI) {
        $new = $orig.Replace($blk.FIND, $blk.REPLACE); $matches = ([regex]::Matches($orig, [regex]::Escape($blk.FIND))).Count
      } else {
        $idx = $orig.IndexOf($blk.FIND)
        $new = $orig.Substring(0,$idx) + $blk.REPLACE + $orig.Substring($idx + $blk.FIND.Length); $matches = 1
      }
      $changed = ($new -ne $orig)
    }
    'insert-after' {
      $rx = [System.Text.RegularExpressions.Regex]::new($blk.FIND, 'Singleline,Multiline')
      $m  = $rx.Match($orig)
      if (-not $m.Success) { return @{ exit=10; msg="SKIP: anchor not found"; target=$blk.TARGET; matches=0; changed=$false } }
      if (-not $blk.MULTI -and $rx.Matches($orig).Count -gt 1) { return @{ exit=12; msg="PRECONDITION: multiple anchors; set MULTI:true"; target=$blk.TARGET } }
      if ($blk.MULTI) {
        $new = $rx.Replace($orig, { param($m) $m.Value + $blk.REPLACE })
        $matches = $rx.Matches($orig).Count
      } else {
        $new = $orig.Substring(0,$m.Index+$m.Length) + $blk.REPLACE + $orig.Substring($m.Index+$m.Length)
        $matches = 1
      }
      $changed = ($new -ne $orig)
    }
    'insert-before' {
      $rx = [System.Text.RegularExpressions.Regex]::new($blk.FIND, 'Singleline,Multiline')
      $m  = $rx.Match($orig)
      if (-not $m.Success) { return @{ exit=10; msg="SKIP: anchor not found"; target=$blk.TARGET; matches=0; changed=$false } }
      if (-not $blk.MULTI -and $rx.Matches($orig).Count -gt 1) { return @{ exit=12; msg="PRECONDITION: multiple anchors; set MULTI:true"; target=$blk.TARGET } }
      if ($blk.MULTI) {
        $new = $rx.Replace($orig, { param($m) $blk.REPLACE + $m.Value })
        $matches = $rx.Matches($orig).Count
      } else {
        $new = $orig.Substring(0,$m.Index) + $blk.REPLACE + $orig.Substring($m.Index)
        $matches = 1
      }
      $changed = ($new -ne $orig)
    }
    default { return @{ exit=12; msg="PRECONDITION: unknown MODE '$($blk.MODE)'" ; target=$blk.TARGET } }
  }

  if (-not $changed) { return @{ exit=10; msg="SKIP: no change"; target=$blk.TARGET; matches=$matches; changed=$false } }

  if ($doApply) {
    # ReadOnly 해제(있다면)
    try {
      $fi = Get-Item -LiteralPath $target -Force
      if ($fi.Attributes.HasFlag([IO.FileAttributes]::ReadOnly)) {
        $fi.Attributes = $fi.Attributes -band (-bnot [IO.FileAttributes]::ReadOnly)
      }
    } catch {}
    $bak = "$target.bak-$(Get-Ts)"
    Copy-Item -LiteralPath $target -Destination $bak -Force
    Write-TextUtf8 -path $target -text $new
    return @{ exit=0; msg="APPLY OK"; target=$blk.TARGET; matches=$matches; backup=$bak; changed=$true }
  } else {
    return @{ exit=11; msg="DRYRUN OK (would change)"; target=$blk.TARGET; matches=$matches; changed=$true }
  }
}

# ---------- Main ----------
$repo = Resolve-RepoRoot $Root
$trace = New-TraceId
$doApply = $ConfirmApply.IsPresent -or ($env:CONFIRM_APPLY -and $env:CONFIRM_APPLY.ToString().ToLower() -eq 'true')

$patchFiles = @()
if ($PatchFile)   { $patchFiles += (Resolve-Path -LiteralPath $PatchFile).Path }
if ($PatchesDir)  { $patchFiles += (Get-ChildItem -LiteralPath $PatchesDir -File -Include *.txt,*.patch,*.patch.txt | Sort-Object FullName | % FullName) }
if (-not $PatchFile -and -not $PatchesDir) { $patchFiles += Get-DefaultPatchList $repo }
if (-not $patchFiles) { throw "패치 파일이 없습니다(.kobong\patches.pending.txt 또는 .kobong\patches\*.txt)" }

$all = @()
foreach ($pf in $patchFiles) {
  $txt = Read-TextUtf8 $pf
  $blocks = Parse-PatchBlocks $txt
  if (-not $blocks -or $blocks.Count -eq 0) { throw "유효한 PATCH 블록이 없습니다: $pf" }
  $all += $blocks
}

$exitMax = 0
$print = { param($o)
  if (-not $Quiet) {
    "{0,-7} | {1} | {2} | matches={3} {4}" -f $o.exit, $o.msg, $o.target, ($o.matches ?? 0), ($(if($o.backup){"| bak=$($o.backup)"}else{""}))
  }
}

With-Lock $repo {
  $start = Get-Date
  foreach ($blk in $all) {
    $res = Apply-OnePatch -repo $repo -blk $blk -doApply:$doApply -traceId $trace
    & $print $res
    if ($res.exit -gt $exitMax) { $exitMax = $res.exit }
    Write-KLCLog $repo @{
      version   = '1.3'
      timestamp = (Get-Date).ToUniversalTime().ToString('o')
      traceId   = $trace
      env       = 'DEV'
      mode      = ($doApply ? 'APPLY' : 'DRYRUN')
      service   = 'apply-patches'
      module    = 'scripts/g5/apply-patches.ps1'
      action    = 'patch'
      outcome   = $res.msg
      exitCode  = $res.exit
      target    = $res.target
      matches   = ($res.matches ?? 0)
      backup    = ($res.backup ?? '')
      durationMs= [int]((Get-Date) - $start).TotalMilliseconds
      message   = $res.msg
    }
  }
}

if ($exitMax -eq 11 -and -not $doApply) { exit 11 }        # DRYRUN only
elseif ($exitMax -in 12,13)           { exit $exitMax }     # PRECONDITION/CONFLICT
elseif ($exitMax -eq 0)               { exit 0 }            # all good
elseif ($exitMax -eq 10)              { exit 0 }            # all skipped -> OK
else                                  { exit 1 }            # unknown -> ERROR
 } |
           Sort-Object FullName
  foreach ($f in $files) { [void]$list.Add($f.FullName) }
}
  return $list
}

function Read-TextUtf8([string]$path) {
  return Get-Content -LiteralPath $path -Raw -Encoding UTF8
}

function Write-TextUtf8([string]$path,[string]$text) {
  $dir = Split-Path -LiteralPath $path -Parent
  if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
  $tmp = "$path.tmp.$([guid]::NewGuid().ToString('N'))"
  [System.IO.File]::WriteAllText($tmp, $text, [System.Text.UTF8Encoding]::new($false))
  Move-Item -LiteralPath $tmp -Destination $path -Force
}

function Get-PrevHash([string]$logPath) {
  if (-not (Test-Path -LiteralPath $logPath)) { return ('0' * 64) }
  $last = Get-Content -LiteralPath $logPath -Tail 200 | Where-Object { $_ -match '\S' } | Select-Object -Last 1
  try { return ((ConvertFrom-Json -InputObject $last).hash) } catch { return ('0' * 64) }
}

function Get-Hash([string]$s) {
  $sha = [System.Security.Cryptography.SHA256]::Create()
  $bytes = [System.Text.Encoding]::UTF8.GetBytes($s)
  ($sha.ComputeHash($bytes) | ForEach-Object { $_.ToString('x2') }) -join ''
}

function Write-KLCLog([string]$repo,[hashtable]$obj) {
  $logDir  = Join-Path $repo 'logs'
  if (-not (Test-Path -LiteralPath $logDir)) { New-Item -ItemType Directory -Path $logDir | Out-Null }
  $logPath = Join-Path $logDir 'apply-log.jsonl'
  $prev    = Get-PrevHash $logPath
  $canon   = ($obj.GetEnumerator() | Sort-Object Name | ForEach-Object { "$($_.Name)=$($_.Value)" }) -join '|'
  $hash    = Get-Hash "$prev|$canon"
  $obj['prevHash'] = $prev
  $obj['hash']     = $hash
  $obj['hashAlgo'] = 'SHA256'
  $obj['canonAlgo']= 'kvc-line-v1'
  $json = ($obj | ConvertTo-Json -Depth 6 -Compress)
  Add-Content -LiteralPath $logPath -Value $json
}

function With-Lock([string]$repo,[scriptblock]$body) {
  $lockPath = Join-Path $repo '.gpt5.lock'
  $mineId   = New-TraceId
  if (Test-Path -LiteralPath $lockPath) {
    $age = (Get-Item -LiteralPath $lockPath).LastWriteTimeUtc
    if ((Get-Date).ToUniversalTime().AddMinutes(-10) -gt $age) {
      Rename-Item -LiteralPath $lockPath -NewName (".gpt5.lock.bak-" + (Get-Ts)) -Force
    } else {
      throw "Lock exists: $lockPath (최근 10분 내 실행 흔적)"
    }
  }
  try {
    Set-Content -LiteralPath $lockPath -NoNewline -Encoding UTF8 -Value $mineId
    & $body
  } finally {
    try {
      $current = ''
      if (Test-Path -LiteralPath $lockPath) { $current = Get-Content -LiteralPath $lockPath -Raw -Encoding UTF8 }
      if ($current -eq $mineId) { Remove-Item -LiteralPath $lockPath -Force -ErrorAction SilentlyContinue }
    } catch { }
  }
}

function Parse-PatchBlocks([string]$text) {
  $lines = $text -split "`n"
  $blocks = @()
  $i = 0
  while ($i -lt $lines.Length) {
    if ($lines[$i].Trim() -eq '# PATCH START') {
      $i++
      $meta = @{}
      $find = ''
      $replace = ''
      while ($i -lt $lines.Length -and -not ($lines[$i].Trim() -eq '# PATCH END')) {
        $L = $lines[$i]
        if ($L -match '^\s*TARGET:\s*(.+)$') { $meta.TARGET = $matches[1].Trim() }
        elseif ($L -match '^\s*MODE:\s*(.+)$') { $meta.MODE = $matches[1].Trim().ToLower() }
        elseif ($L -match '^\s*MULTI:\s*(.+)$') { $meta.MULTI = [bool]::Parse($matches[1].Trim()) }
        elseif ($L -match "^\s*FIND\s+<<'EOF'\s*$") {
          $buf = New-Object System.Text.StringBuilder
          $i++
          while ($i -lt $lines.Length -and -not ($lines[$i].Trim() -eq 'EOF')) {
            [void]$buf.AppendLine($lines[$i])
            $i++
          }
          $find = $buf.ToString()
        }
        elseif ($L -match "^\s*REPLACE\s+<<'EOF'\s*$") {
          $buf = New-Object System.Text.StringBuilder
          $i++
          while ($i -lt $lines.Length -and -not ($lines[$i].Trim() -eq 'EOF')) {
            [void]$buf.AppendLine($lines[$i])
            $i++
          }
          $replace = $buf.ToString()
        }
        $i++
      }
      if (-not $meta.TARGET -or -not $meta.MODE) { throw "PATCH 메타 누락(TARGET/MODE)" }
      $blocks += [pscustomobject]@{
        TARGET  = $meta.TARGET
        MODE    = $meta.MODE
        MULTI   = [bool]($meta.MULTI)
        FIND    = $find
        REPLACE = $replace
      }
    } else { $i++ }
  }
  return ,$blocks
}

function Apply-OnePatch([string]$repo, $blk, [bool]$doApply, [string]$traceId) {
  $target = Join-RepoPath $repo $blk.TARGET
  if (-not (Test-Path -LiteralPath $target)) { return @{ exit=12; msg="PRECONDITION: target not found"; target=$blk.TARGET } }

  $orig = Read-TextUtf8 $target
  $new  = $orig
  $matches = 0
  $changed = $false

  # 멱등(SENTINEL): 이미 REPLACE가 있으면 SKIP
  if (-not [string]::IsNullOrEmpty($blk.REPLACE) -and $orig.Contains($blk.REPLACE)) {
    return @{ exit=10; msg="SKIP: already contains REPLACE"; target=$blk.TARGET; matches=0; changed=$false }
  }

  switch ($blk.MODE) {
    'regex-replace' {
      $rx = [System.Text.RegularExpressions.Regex]::new($blk.FIND, 'Singleline,Multiline')
      $matches = ($rx.Matches($orig)).Count
      if ($matches -eq 0) { return @{ exit=10; msg="SKIP: no match"; target=$blk.TARGET; matches=0; changed=$false } }
      if (-not $blk.MULTI -and $matches -gt 1) { return @{ exit=12; msg="PRECONDITION: multiple matches; set MULTI:true"; target=$blk.TARGET; matches=$matches } }
      if ($blk.MULTI) {
        $new = $rx.Replace($orig, $blk.REPLACE)
      } else {
        $m = $rx.Match($orig)
        $new = $orig.Substring(0, $m.Index) + $m.Result($blk.REPLACE) + $orig.Substring($m.Index + $m.Length)
      }
      $changed = ($new -ne $orig)
    }
    'plain-replace' {
      if (-not $orig.Contains($blk.FIND)) { return @{ exit=10; msg="SKIP: FIND not found"; target=$blk.TARGET; matches=0; changed=$false } }
      if ($blk.MULTI) {
        $new = $orig.Replace($blk.FIND, $blk.REPLACE); $matches = ([regex]::Matches($orig, [regex]::Escape($blk.FIND))).Count
      } else {
        $idx = $orig.IndexOf($blk.FIND)
        $new = $orig.Substring(0,$idx) + $blk.REPLACE + $orig.Substring($idx + $blk.FIND.Length); $matches = 1
      }
      $changed = ($new -ne $orig)
    }
    'insert-after' {
      $rx = [System.Text.RegularExpressions.Regex]::new($blk.FIND, 'Singleline,Multiline')
      $m  = $rx.Match($orig)
      if (-not $m.Success) { return @{ exit=10; msg="SKIP: anchor not found"; target=$blk.TARGET; matches=0; changed=$false } }
      if (-not $blk.MULTI -and $rx.Matches($orig).Count -gt 1) { return @{ exit=12; msg="PRECONDITION: multiple anchors; set MULTI:true"; target=$blk.TARGET } }
      if ($blk.MULTI) {
        $new = $rx.Replace($orig, { param($m) $m.Value + $blk.REPLACE })
        $matches = $rx.Matches($orig).Count
      } else {
        $new = $orig.Substring(0,$m.Index+$m.Length) + $blk.REPLACE + $orig.Substring($m.Index+$m.Length)
        $matches = 1
      }
      $changed = ($new -ne $orig)
    }
    'insert-before' {
      $rx = [System.Text.RegularExpressions.Regex]::new($blk.FIND, 'Singleline,Multiline')
      $m  = $rx.Match($orig)
      if (-not $m.Success) { return @{ exit=10; msg="SKIP: anchor not found"; target=$blk.TARGET; matches=0; changed=$false } }
      if (-not $blk.MULTI -and $rx.Matches($orig).Count -gt 1) { return @{ exit=12; msg="PRECONDITION: multiple anchors; set MULTI:true"; target=$blk.TARGET } }
      if ($blk.MULTI) {
        $new = $rx.Replace($orig, { param($m) $blk.REPLACE + $m.Value })
        $matches = $rx.Matches($orig).Count
      } else {
        $new = $orig.Substring(0,$m.Index) + $blk.REPLACE + $orig.Substring($m.Index)
        $matches = 1
      }
      $changed = ($new -ne $orig)
    }
    default { return @{ exit=12; msg="PRECONDITION: unknown MODE '$($blk.MODE)'" ; target=$blk.TARGET } }
  }

  if (-not $changed) { return @{ exit=10; msg="SKIP: no change"; target=$blk.TARGET; matches=$matches; changed=$false } }

  if ($doApply) {
    # ReadOnly 해제(있다면)
    try {
      $fi = Get-Item -LiteralPath $target -Force
      if ($fi.Attributes.HasFlag([IO.FileAttributes]::ReadOnly)) {
        $fi.Attributes = $fi.Attributes -band (-bnot [IO.FileAttributes]::ReadOnly)
      }
    } catch {}
    $bak = "$target.bak-$(Get-Ts)"
    Copy-Item -LiteralPath $target -Destination $bak -Force
    Write-TextUtf8 -path $target -text $new
    return @{ exit=0; msg="APPLY OK"; target=$blk.TARGET; matches=$matches; backup=$bak; changed=$true }
  } else {
    return @{ exit=11; msg="DRYRUN OK (would change)"; target=$blk.TARGET; matches=$matches; changed=$true }
  }
}

# ---------- Main ----------
$repo = Resolve-RepoRoot $Root
$trace = New-TraceId
$doApply = $ConfirmApply.IsPresent -or ($env:CONFIRM_APPLY -and $env:CONFIRM_APPLY.ToString().ToLower() -eq 'true')

$patchFiles = @()
if ($PatchFile)   { $patchFiles += (Resolve-Path -LiteralPath $PatchFile).Path }
if ($PatchesDir)  { $patchFiles += (Get-ChildItem -LiteralPath $PatchesDir -File -Include *.txt,*.patch,*.patch.txt | Sort-Object FullName | % FullName) }
if (-not $PatchFile -and -not $PatchesDir) { $patchFiles += Get-DefaultPatchList $repo }
if (-not $patchFiles) { throw "패치 파일이 없습니다(.kobong\patches.pending.txt 또는 .kobong\patches\*.txt)" }

$all = @()
foreach ($pf in $patchFiles) {
  $txt = Read-TextUtf8 $pf
  $blocks = Parse-PatchBlocks $txt
  if (-not $blocks -or $blocks.Count -eq 0) { throw "유효한 PATCH 블록이 없습니다: $pf" }
  $all += $blocks
}

$exitMax = 0
$print = { param($o)
  if (-not $Quiet) {
    "{0,-7} | {1} | {2} | matches={3} {4}" -f $o.exit, $o.msg, $o.target, ($o.matches ?? 0), ($(if($o.backup){"| bak=$($o.backup)"}else{""}))
  }
}

With-Lock $repo {
  $start = Get-Date
  foreach ($blk in $all) {
    $res = Apply-OnePatch -repo $repo -blk $blk -doApply:$doApply -traceId $trace
    & $print $res
    if ($res.exit -gt $exitMax) { $exitMax = $res.exit }
    Write-KLCLog $repo @{
      version   = '1.3'
      timestamp = (Get-Date).ToUniversalTime().ToString('o')
      traceId   = $trace
      env       = 'DEV'
      mode      = ($doApply ? 'APPLY' : 'DRYRUN')
      service   = 'apply-patches'
      module    = 'scripts/g5/apply-patches.ps1'
      action    = 'patch'
      outcome   = $res.msg
      exitCode  = $res.exit
      target    = $res.target
      matches   = ($res.matches ?? 0)
      backup    = ($res.backup ?? '')
      durationMs= [int]((Get-Date) - $start).TotalMilliseconds
      message   = $res.msg
    }
  }
}

if ($exitMax -eq 11 -and -not $doApply) { exit 11 }        # DRYRUN only
elseif ($exitMax -in 12,13)           { exit $exitMax }     # PRECONDITION/CONFLICT
elseif ($exitMax -eq 0)               { exit 0 }            # all good
elseif ($exitMax -eq 10)              { exit 0 }            # all skipped -> OK
else                                  { exit 1 }            # unknown -> ERROR
.Name -match '\.(txt|patch|patch\.txt)
if (-not $PatchFile -and -not $PatchesDir) { $patchFiles += Get-DefaultPatchList $repo }
if (-not $patchFiles) { throw "패치 파일이 없습니다(.kobong\patches.pending.txt 또는 .kobong\patches\*.txt)" }

$all = @()
foreach ($pf in $patchFiles) {
  $txt = Read-TextUtf8 $pf
  $blocks = Parse-PatchBlocks $txt
  if (-not $blocks -or $blocks.Count -eq 0) { throw "유효한 PATCH 블록이 없습니다: $pf" }
  $all += $blocks
}

$exitMax = 0
$print = { param($o)
  if (-not $Quiet) {
    "{0,-7} | {1} | {2} | matches={3} {4}" -f $o.exit, $o.msg, $o.target, ($o.matches ?? 0), ($(if($o.backup){"| bak=$($o.backup)"}else{""}))
  }
}

With-Lock $repo {
  $start = Get-Date
  foreach ($blk in $all) {
    $res = Apply-OnePatch -repo $repo -blk $blk -doApply:$doApply -traceId $trace
    & $print $res
    if ($res.exit -gt $exitMax) { $exitMax = $res.exit }
    Write-KLCLog $repo @{
      version   = '1.3'
      timestamp = (Get-Date).ToUniversalTime().ToString('o')
      traceId   = $trace
      env       = 'DEV'
      mode      = ($doApply ? 'APPLY' : 'DRYRUN')
      service   = 'apply-patches'
      module    = 'scripts/g5/apply-patches.ps1'
      action    = 'patch'
      outcome   = $res.msg
      exitCode  = $res.exit
      target    = $res.target
      matches   = ($res.matches ?? 0)
      backup    = ($res.backup ?? '')
      durationMs= [int]((Get-Date) - $start).TotalMilliseconds
      message   = $res.msg
    }
  }
}

if ($exitMax -eq 11 -and -not $doApply) { exit 11 }        # DRYRUN only
elseif ($exitMax -in 12,13)           { exit $exitMax }     # PRECONDITION/CONFLICT
elseif ($exitMax -eq 0)               { exit 0 }            # all good
elseif ($exitMax -eq 10)              { exit 0 }            # all skipped -> OK
else                                  { exit 1 }            # unknown -> ERROR
 } |
           Sort-Object FullName
  $patchFiles += $files.FullName
}
if (-not $PatchFile -and -not $PatchesDir) { $patchFiles += Get-DefaultPatchList $repo }
if (-not $patchFiles) { throw "패치 파일이 없습니다(.kobong\patches.pending.txt 또는 .kobong\patches\*.txt)" }

$all = @()
foreach ($pf in $patchFiles) {
  $txt = Read-TextUtf8 $pf
  $blocks = Parse-PatchBlocks $txt
  if (-not $blocks -or $blocks.Count -eq 0) { throw "유효한 PATCH 블록이 없습니다: $pf" }
  $all += $blocks
}

$exitMax = 0
$print = { param($o)
  if (-not $Quiet) {
    "{0,-7} | {1} | {2} | matches={3} {4}" -f $o.exit, $o.msg, $o.target, ($o.matches ?? 0), ($(if($o.backup){"| bak=$($o.backup)"}else{""}))
  }
}

With-Lock $repo {
  $start = Get-Date
  foreach ($blk in $all) {
    $res = Apply-OnePatch -repo $repo -blk $blk -doApply:$doApply -traceId $trace
    & $print $res
    if ($res.exit -gt $exitMax) { $exitMax = $res.exit }
    Write-KLCLog $repo @{
      version   = '1.3'
      timestamp = (Get-Date).ToUniversalTime().ToString('o')
      traceId   = $trace
      env       = 'DEV'
      mode      = ($doApply ? 'APPLY' : 'DRYRUN')
      service   = 'apply-patches'
      module    = 'scripts/g5/apply-patches.ps1'
      action    = 'patch'
      outcome   = $res.msg
      exitCode  = $res.exit
      target    = $res.target
      matches   = ($res.matches ?? 0)
      backup    = ($res.backup ?? '')
      durationMs= [int]((Get-Date) - $start).TotalMilliseconds
      message   = $res.msg
    }
  }
}

if ($exitMax -eq 11 -and -not $doApply) { exit 11 }        # DRYRUN only
elseif ($exitMax -in 12,13)           { exit $exitMax }     # PRECONDITION/CONFLICT
elseif ($exitMax -eq 0)               { exit 0 }            # all good
elseif ($exitMax -eq 10)              { exit 0 }            # all skipped -> OK
else                                  { exit 1 }            # unknown -> ERROR

