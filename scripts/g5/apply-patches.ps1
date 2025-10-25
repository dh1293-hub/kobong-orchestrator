#requires -Version 7.0
<#
  KoBong apply-patches.ps1 — v1.4.0 (2025-10-23, stable)
  Principles:
    - PS7-First, DRYRUN→APPLY
    - Repo sandbox, .gpt5.lock, atomic write, .bak snapshots
    - KLC jsonl logging (min 1 line), deterministic exit codes
    - No parameter-set conflicts: .NET Path only, LiteralPath only
    - Robust inputs: switches/strings/numbers/env → To-Bool
    - FIND/REPLACE TrimEnd CR/LF (anchor match stability)
    - Idempotence: SKIP when REPLACE already present
  Exit codes: 0=OK, 10=SKIP, 11=DRYRUN, 12=PRECONDITION, 13=CONFLICT, 1=ERROR
#>

[CmdletBinding()]
param(
  [string]$Root = (Get-Location).Path,
  [string]$PatchFile,
  [string]$PatchesDir,

  # Accept switch/string/number/env for long-term safety
  [object]$ConfirmApply,
  [object]$Quiet,
  [object]$Trace
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)

# ---------- Utils ----------
function New-TraceId { ([guid]::NewGuid()).ToString('N') }
function Get-Ts { Get-Date -Format 'yyyyMMdd-HHmmss' }

function To-Bool([object]$v) {
  if ($null -eq $v) { return $false }
  if ($v -is [System.Management.Automation.SwitchParameter]) { return $v.IsPresent }
  if ($v -is [bool]) { return $v }
  try { if ($v -is [int]) { return [bool]$v } } catch {}
  $s = $v.ToString().Trim().ToLowerInvariant()
  return $s -in @('1','true','t','yes','y','on')
}

function Path-Combine([string]$a,[string]$b) {
  if ([string]::IsNullOrWhiteSpace($a)) { throw "Path-Combine: base is empty" }
  if ([string]::IsNullOrWhiteSpace($b)) { throw "Path-Combine: child is empty" }
  [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($a,$b))
}
function Ensure-Dir([string]$p) {
  if (-not (Test-Path -LiteralPath $p)) { New-Item -ItemType Directory -Path $p | Out-Null }
}

# ---------- Repo paths ----------
function Resolve-RepoRoot([string]$root) {
  if ([string]::IsNullOrWhiteSpace($root)) { throw "Root is empty." }
  $rp = Resolve-Path -LiteralPath $root
  if (-not $rp) { throw "Root not found: $root" }
  [System.IO.Path]::GetFullPath($rp.Path)
}
function Join-RepoPath([string]$repo,[string]$rel) {
  if ([string]::IsNullOrWhiteSpace($repo)) { throw "Repo root empty." }
  if ([string]::IsNullOrWhiteSpace($rel))  { throw "TARGET path is empty." }
  if ($rel -match '^\s*[./\\]*\.\.[/\\]') { throw "Path escapes repo: $rel" }
  $full = Path-Combine $repo $rel
  $root = [System.IO.Path]::GetFullPath($repo)
  if (-not $full.StartsWith($root,[StringComparison]::OrdinalIgnoreCase)) { throw "Path escapes repo: $rel" }
  $full
}

# ---------- Logging ----------
function Get-PrevHash([string]$logPath) {
  if (-not (Test-Path -LiteralPath $logPath)) { return ('0' * 64) }
  $last = Get-Content -LiteralPath $logPath -Tail 200 | Where-Object { $_ -match '\S' } | Select-Object -Last 1
  try { return ((ConvertFrom-Json -InputObject $last).hash) } catch { return ('0' * 64) }
}
function Get-Hash([string]$s) {
  $sha=[System.Security.Cryptography.SHA256]::Create()
  ($sha.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($s))|ForEach-Object{ $_.ToString('x2') }) -join ''
}
function Write-KLCLog([string]$repo,[hashtable]$o) {
  $logDir = [System.IO.Path]::Combine($repo,'logs') ; Ensure-Dir $logDir
  $logPath= [System.IO.Path]::Combine($logDir,'apply-log.jsonl')
  $prev   = Get-PrevHash $logPath
  $canon  = ($o.GetEnumerator()|Sort-Object Name|ForEach-Object{ "$($_.Name)=$($_.Value)" }) -join '|'
  $hash   = Get-Hash "$prev|$canon"
  $o['prevHash']=$prev; $o['hash']=$hash; $o['hashAlgo']='SHA256'; $o['canonAlgo']='kvc-line-v1'
  Add-Content -LiteralPath $logPath -Value (($o|ConvertTo-Json -Depth 6 -Compress))
}

# ---------- Text I/O ----------
function Read-TextUtf8([string]$path) {
  Get-Content -LiteralPath $path -Raw -Encoding UTF8
}
function Write-TextUtf8([string]$path,[string]$text) {
  $dir = Split-Path -LiteralPath $path -Parent
  Ensure-Dir $dir
  $tmp = "$path.tmp.$([guid]::NewGuid().ToString('N'))"
  [System.IO.File]::WriteAllText($tmp,$text,[System.Text.UTF8Encoding]::new($false))
  Move-Item -LiteralPath $tmp -Destination $path -Force
}

# ---------- Patch discovery ----------
function Get-DefaultPatchList([string]$repo) {
  $list = New-Object System.Collections.Generic.List[string]
  $pending = [System.IO.Path]::Combine($repo,'.kobong\patches.pending.txt')
  $dir1    = [System.IO.Path]::Combine($repo,'.kobong\patches')
  if (Test-Path -LiteralPath $pending) { [void]$list.Add($pending) }
  if (Test-Path -LiteralPath $dir1) {
    $files = Get-ChildItem -LiteralPath $dir1 -File |
             Where-Object { $_.Name -match '\.(txt|patch|patch\.txt)$' } |
             Sort-Object FullName
    foreach($f in $files){ [void]$list.Add($f.FullName) }
  }
  ,$list.ToArray()
}

# ---------- Safe props & normalization ----------
function Get-Prop([object]$o,[string]$name,$default){
  if ($null -eq $o) { return $default }
  if ($o -is [hashtable]) { return ($(if($o.ContainsKey($name)){$o[$name]}else{$default})) }
  $p=$o.PSObject.Properties[$name]; if($p){$p.Value}else{$default}
}
function Normalize-Result([object]$res) {
  if ($null -eq $res) {
    return @{
      exit    = 1
      msg     = 'INTERNAL: null result'
      target  = ''
      matches = 0
      backup  = ''
      changed = $false
    }
  }
  if ($res -is [hashtable]) {
    foreach ($k in 'exit','msg','target','matches','backup','changed') {
      if (-not $res.ContainsKey($k)) {
        $defaults = @{
          exit    = 1
          msg     = 'UNKNOWN'
          target  = ''
          matches = 0
          backup  = ''
          changed = $false
        }
        $res[$k] = $defaults[$k]
      }
    }
    return $res
  }
  return @{
    exit    = (Get-Prop $res 'exit'    1)
    msg     = (Get-Prop $res 'msg'     'UNKNOWN')
    target  = (Get-Prop $res 'target'  '')
    matches = (Get-Prop $res 'matches' 0)
    backup  = (Get-Prop $res 'backup'  '')
    changed = (Get-Prop $res 'changed' $false)
  }
}

# ---------- Parser ----------
function Parse-PatchBlocks([string]$text) {
  $lines = [regex]::Split($text, "\r?\n")
  $blocks=@(); $i=0
  while($i -lt $lines.Length){
    if($lines[$i].Trim() -eq '# PATCH START'){
      $i++; $meta=@{}; $find=''; $replace=''
      while ($i -lt $lines.Length -and -not ($lines[$i].Trim() -eq '# PATCH END')) {
        $L=$lines[$i]
        if     ($L -match '^\s*TARGET:\s*(.+)$') { $meta.TARGET=$matches[1].Trim() }
        elseif ($L -match '^\s*MODE:\s*(.+)$')   { $meta.MODE=$matches[1].Trim().ToLower() }
        elseif ($L -match '^\s*MULTI:\s*(.+)$')  { $meta.MULTI=[bool]::Parse($matches[1].Trim()) }
        elseif ($L -match "^\s*FIND\s+<<'EOF'\s*$") {
          $buf=[System.Text.StringBuilder]::new(); $i++
          while($i -lt $lines.Length -and -not ($lines[$i].Trim() -eq 'EOF')){ [void]$buf.AppendLine($lines[$i]); $i++ }
          $find = ($buf.ToString()).TrimEnd("`r","`n")
        }
        elseif ($L -match "^\s*REPLACE\s+<<'EOF'\s*$") {
          $buf=[System.Text.StringBuilder]::new(); $i++
          while($i -lt $lines.Length -and -not ($lines[$i].Trim() -eq 'EOF')){ [void]$buf.AppendLine($lines[$i]); $i++ }
          $replace = ($buf.ToString()).TrimEnd("`r","`n")
        }
        $i++
      }
      if (-not $meta.TARGET -or -not $meta.MODE) { throw "PATCH 메타 누락(TARGET/MODE)" }
      $blocks += [pscustomobject]@{ TARGET=$meta.TARGET; MODE=$meta.MODE; MULTI=[bool]($meta.MULTI); FIND=$find; REPLACE=$replace }
    } else { $i++ }
  }
  ,$blocks
}

# ---------- One patch ----------
function Apply-OnePatch([string]$repo, $blk, [bool]$doApply, [string]$traceId) {
  $target = Join-RepoPath $repo $blk.TARGET
  if (-not (Test-Path -LiteralPath $target)) { return @{ exit=12; msg="PRECONDITION: target not found"; target=$blk.TARGET; matches=0; changed=$false; backup='' } }
  $orig = Read-TextUtf8 $target ; $new=$orig ; $matches=0 ; $changed=$false ; $backup=''

  # Idempotence: if REPLACE already present → SKIP
  if (-not [string]::IsNullOrEmpty($blk.REPLACE) -and $orig.Contains($blk.REPLACE)) {
    return @{ exit=10; msg="SKIP: already contains REPLACE"; target=$blk.TARGET; matches=0; changed=$false; backup='' }
  }

  switch ($blk.MODE) {
    'regex-replace' {
      $rx = [System.Text.RegularExpressions.Regex]::new(
        $blk.FIND,
        [System.Text.RegularExpressions.RegexOptions]::Singleline -bor
        [System.Text.RegularExpressions.RegexOptions]::Multiline
      )
      $matches = ($rx.Matches($orig)).Count
      if ($matches -eq 0) { return @{ exit=10; msg="SKIP: no match"; target=$blk.TARGET; matches=0; changed=$false; backup='' } }
      if (-not $blk.MULTI -and $matches -gt 1) { return @{ exit=12; msg="PRECONDITION: multiple matches; set MULTI:true"; target=$blk.TARGET; matches=$matches; changed=$false; backup='' } }
      if ($blk.MULTI) { $new = $rx.Replace($orig, $blk.REPLACE) }
      else { $m=$rx.Match($orig); $new = $orig.Substring(0,$m.Index) + $m.Result($blk.REPLACE) + $orig.Substring($m.Index+$m.Length) }
      $changed = ($new -ne $orig)
    }
    'plain-replace' {
      if (-not $orig.Contains($blk.FIND)) { return @{ exit=10; msg="SKIP: FIND not found"; target=$blk.TARGET; matches=0; changed=$false; backup='' } }
      if ($blk.MULTI) { $matches = ([regex]::Matches($orig, [regex]::Escape($blk.FIND))).Count; $new=$orig.Replace($blk.FIND,$blk.REPLACE) }
      else { $idx=$orig.IndexOf($blk.FIND); $new=$orig.Substring(0,$idx)+$blk.REPLACE+$orig.Substring($idx+$blk.FIND.Length); $matches=1 }
      $changed = ($new -ne $orig)
    }
    'insert-after' {
      $rx = [System.Text.RegularExpressions.Regex]::new(
        $blk.FIND,
        [System.Text.RegularExpressions.RegexOptions]::Singleline -bor
        [System.Text.RegularExpressions.RegexOptions]::Multiline
      )
      $all = $rx.Matches($orig)
      if ($all.Count -eq 0) { return @{ exit=10; msg="SKIP: anchor not found"; target=$blk.TARGET; matches=0; changed=$false; backup='' } }
      if (-not $blk.MULTI -and $all.Count -gt 1) { return @{ exit=12; msg="PRECONDITION: multiple anchors; set MULTI:true"; target=$blk.TARGET; matches=$all.Count; changed=$false; backup='' } }
      if ($blk.MULTI) { $new=$rx.Replace($orig,{ param($m) $m.Value+$blk.REPLACE }); $matches=$all.Count }
      else { $m=$all[0]; $new=$orig.Substring(0,$m.Index+$m.Length)+$blk.REPLACE+$orig.Substring($m.Index+$m.Length); $matches=1 }
      $changed=($new -ne $orig)
    }
    'insert-before' {
      $rx = [System.Text.RegularExpressions.Regex]::new(
        $blk.FIND,
        [System.Text.RegularExpressions.RegexOptions]::Singleline -bor
        [System.Text.RegularExpressions.RegexOptions]::Multiline
      )
      $all = $rx.Matches($orig)
      if ($all.Count -eq 0) { return @{ exit=10; msg="SKIP: anchor not found"; target=$blk.TARGET; matches=0; changed=$false; backup='' } }
      if (-not $blk.MULTI -and $all.Count -gt 1) { return @{ exit=12; msg="PRECONDITION: multiple anchors; set MULTI:true"; target=$blk.TARGET; matches=$all.Count; changed=$false; backup='' } }
      if ($blk.MULTI) { $new=$rx.Replace($orig,{ param($m) $blk.REPLACE+$m.Value }); $matches=$all.Count }
      else { $m=$all[0]; $new=$orig.Substring(0,$m.Index)+$blk.REPLACE+$orig.Substring($m.Index); $matches=1 }
      $changed=($new -ne $orig)
    }
    default {
      return @{ exit=12; msg="PRECONDITION: unknown MODE '$($blk.MODE)'" ; target=$blk.TARGET; matches=0; changed=$false; backup='' }
    }
  }

  if (-not $changed) { return @{ exit=10; msg="SKIP: no change"; target=$blk.TARGET; matches=$matches; changed=$false; backup='' } }

  if ($doApply) {
    try {
      $fi = Get-Item -LiteralPath $target -Force
      if ($fi.Attributes.HasFlag([IO.FileAttributes]::ReadOnly)) { $fi.Attributes = $fi.Attributes -band (-bnot [IO.FileAttributes]::ReadOnly) }
    } catch {}
    $backup = "$target.bak-$(Get-Ts)"
    Copy-Item -LiteralPath $target -Destination $backup -Force
    Write-TextUtf8 -path $target -text $new
    return @{ exit=0; msg="APPLY OK"; target=$blk.TARGET; matches=$matches; changed=$true; backup=$backup }
  } else {
    return @{ exit=11; msg="DRYRUN OK (would change)"; target=$blk.TARGET; matches=$matches; changed=$true; backup='' }
  }
}

# ---------- Main ----------
$repo   = Resolve-RepoRoot $Root
$trace  = New-TraceId
$doApply= (To-Bool $ConfirmApply) -or (To-Bool $env:CONFIRM_APPLY)
$quiet  = (To-Bool $Quiet)        -or (To-Bool $env:PATCH_QUIET)
$traceOn= (To-Bool $Trace)        -or (To-Bool $env:PATCH_TRACE)

$patchFiles = @()
if ($PatchFile)  { $patchFiles += (Resolve-Path -LiteralPath $PatchFile).Path }
if ($PatchesDir) {
  $files = Get-ChildItem -LiteralPath $PatchesDir -File | Where-Object { $_.Name -match '\.(txt|patch|patch\.txt)$' } | Sort-Object FullName
  $patchFiles += $files.FullName
}
if (-not $PatchFile -and -not $PatchesDir) { $patchFiles += Get-DefaultPatchList $repo }
if (-not $patchFiles -or $patchFiles.Count -eq 0) { throw "패치 파일이 없습니다(.kobong\patches.pending.txt 또는 .kobong\patches\*.txt)" }

if($traceOn){ Write-Host "[TRACE] repo=$repo"; Write-Host "[TRACE] files=" ($patchFiles -join ', ') }

$lockPath = [System.IO.Path]::Combine($repo,'.gpt5.lock')
$mineId   = New-TraceId
if (Test-Path -LiteralPath $lockPath) {
  $age = (Get-Item -LiteralPath $lockPath).LastWriteTimeUtc
  if ((Get-Date).ToUniversalTime().AddMinutes(-10) -gt $age) { Rename-Item -LiteralPath $lockPath -NewName (".gpt5.lock.bak-" + (Get-Ts)) -Force }
  else { throw "Lock exists: $lockPath (최근 10분 내 실행 흔적)" }
}
try {
  Set-Content -LiteralPath $lockPath -NoNewline -Encoding UTF8 -Value $mineId
  $start = Get-Date
  $exitMax=0

  foreach($pf in $patchFiles){
    if($traceOn){ Write-Host "[TRACE] read $pf" }
    $txt    = Read-TextUtf8 $pf
    $blocks = Parse-PatchBlocks $txt
    if (-not $blocks -or $blocks.Count -eq 0) { throw "유효한 PATCH 블록이 없습니다: $pf" }

    foreach($blk in $blocks){
      $raw = Apply-OnePatch -repo $repo -blk $blk -doApply:$doApply -traceId $trace
      $res = Normalize-Result $raw

      if (-not $quiet) {
        $m = Get-Prop $res 'matches' 0
        $bak = Get-Prop $res 'backup' ''
        "{0,-7} | {1} | {2} | matches={3} {4}" -f (Get-Prop $res 'exit' 1), (Get-Prop $res 'msg' 'UNKNOWN'), (Get-Prop $res 'target' ''), $m, ($(if($bak -ne ''){"| bak=$bak"}else{""}))
      }

      $ex = [int](Get-Prop $res 'exit' 1); if($ex -gt $exitMax){ $exitMax=$ex }

      Write-KLCLog $repo @{
        version='1.3'; timestamp=(Get-Date).ToUniversalTime().ToString('o'); traceId=$trace
        env='DEV'; mode=($doApply ? 'APPLY' : 'DRYRUN'); service='apply-patches'; module='scripts/g5/apply-patches.ps1'
        action='patch'; outcome=(Get-Prop $res 'msg' 'UNKNOWN'); exitCode=$ex; target=(Get-Prop $res 'target' '')
        matches=(Get-Prop $res 'matches' 0); backup=(Get-Prop $res 'backup' ''); durationMs=[int]((Get-Date)-$start).TotalMilliseconds
        message=(Get-Prop $res 'msg' 'UNKNOWN')
      }
    }
  }

  if ($exitMax -eq 11 -and -not $doApply) { exit 11 }        # DRYRUN only
  elseif ($exitMax -in 12,13)            { exit $exitMax }   # PRECONDITION/CONFLICT
  elseif ($exitMax -eq 0)                { exit 0 }          # all good
  elseif ($exitMax -eq 10)               { exit 0 }          # all skipped -> OK
  else                                   { exit 1 }          # unknown -> ERROR
}
finally {
  try {
    $current = if (Test-Path -LiteralPath $lockPath){ Get-Content -LiteralPath $lockPath -Raw -Encoding UTF8 } else { '' }
    if ($current -eq $mineId) { Remove-Item -LiteralPath $lockPath -Force -ErrorAction SilentlyContinue }
  } catch {}
}


