param(
  [switch] $DryRun,
  [switch] $ConfirmApply,
  [int]    $TimeoutSec = 90,
  [int]    $MaxFiles   = 5000,
  [int]    $MaxDepth   = 12,
  [switch] $NoForceExit,
  [switch] $ForceKill
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

function Write-JsonLog {
  param([string]$Action,[string]$Outcome,[string]$Message = '',[string]$ErrorCode = '',[int]$DurationMs = 0)
  $logDir = Join-Path $RepoRoot 'logs'
  New-Item -ItemType Directory -Force -Path $logDir | Out-Null
  $jsonl = Join-Path $logDir 'apply-log.jsonl'
  $obj = [ordered]@{
    timestamp=(Get-Date).ToString('o'); level=$(if($Outcome -eq 'FAILURE'){'ERROR'}else{'INFO'})
    traceId=[guid]::NewGuid().ToString(); module='scripts'; action=$Action; inputHash=''
    outcome=$Outcome; durationMs=$DurationMs; errorCode=$ErrorCode; message=$Message
  }
  $line = ($obj | ConvertTo-Json -Depth 6 -Compress)
  if (-not (Test-Path $jsonl)) { $line | Out-File -FilePath $jsonl -Encoding utf8 } else { $line | Out-File -FilePath $jsonl -Encoding utf8 -Append }
}

function Get-GitRoot { try { git rev-parse --show-toplevel 2>$null } catch { $null } }

$RepoRoot = Get-GitRoot
if (-not $RepoRoot) { $RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path }
if (-not (Test-Path $RepoRoot)) { throw "PRECONDITION: RepoRoot not found" }

# Lock
$LockFile = Join-Path $RepoRoot '.gpt5.lock'
if (Test-Path $LockFile) { throw 'CONFLICT: Another operation in progress (.gpt5.lock exists).' }
'locked ' + (Get-Date).ToString('o') | Out-File $LockFile -Encoding utf8 -NoNewline

# Ignore rules
$IgnoreDirs = @('\.git\','\node_modules\','\out\','\.venv\','\.cache\','\dist\','\coverage\','\target\','\bin\','\obj\')
function Should-SkipPath([string]$p){
  $pp = $p -ireplace '/', '\'
  foreach($i in $IgnoreDirs){ if($pp -match $i){ return $true } }
  return $false
}

# Deterministic, bounded enumerator (no regex/backticks in core logic)
function Get-Ps1Files([string]$root,[int]$maxDepth,[int]$maxFiles,[int]$timeoutSec,[ref]$truncated){
  $truncated.Value = $false
  $results = New-Object System.Collections.Generic.List[System.IO.FileInfo]
  $visited = New-Object 'System.Collections.Generic.HashSet[string]'
  $queue   = New-Object 'System.Collections.Generic.Queue[psobject]'
  $sw      = [System.Diagnostics.Stopwatch]::StartNew()

  $rootItem = Get-Item -LiteralPath $root -ErrorAction SilentlyContinue
  if (-not $rootItem) { return $results }
  $queue.Enqueue([pscustomobject]@{ Dir=$rootItem; Depth=0 })

  while($queue.Count -gt 0){
    if ($sw.Elapsed.TotalSeconds -ge $timeoutSec) { $truncated.Value = $true; break }
    if ($results.Count -ge $maxFiles) { $truncated.Value = $true; break }

    $node = $queue.Dequeue()
    $dir  = $node.Dir
    $depth= [int]$node.Depth

    $norm = ($dir.FullName -ireplace '/', '\').ToLowerInvariant()
    if ($visited.Contains($norm)) { continue }
    [void]$visited.Add($norm)

    if ($dir.Attributes -band [IO.FileAttributes]::ReparsePoint) { continue }
    if (Should-SkipPath $dir.FullName) { continue }

    try {
      $files = Get-ChildItem -LiteralPath $dir.FullName -Filter *.ps1 -File -ErrorAction SilentlyContinue
      foreach($f in $files){
        $results.Add($f) | Out-Null
        if ($results.Count -ge $maxFiles) { $truncated.Value = $true; break }
      }
      if ($truncated.Value) { break }
    } catch {}

    if ($depth -ge $maxDepth) { continue }
    try {
      $dirs = Get-ChildItem -LiteralPath $dir.FullName -Directory -Force -ErrorAction SilentlyContinue
      foreach($d in $dirs){
        if ($d.Attributes -band [IO.FileAttributes]::ReparsePoint) { continue }
        if (Should-SkipPath $d.FullName) { continue }
        $queue.Enqueue([pscustomobject]@{ Dir=$d; Depth=($depth+1) })
      }
    } catch {}
  }
  return $results
}

# Header template
$HeaderLines = @(
  "Set-StrictMode -Version Latest",
  "$" + "ErrorActionPreference = 'Stop'",
  ". ""$PSScriptRoot\_preamble.ps1"""
)

function Normalize-Newline {
  param([string]$s)
  if ($null -eq $s) { return $null }
  $crlf = [string]([char]13) + [string]([char]10)
  $lf   = [string]([char]10)
  return $s.Replace($crlf, $lf)
}

function Ensure-Header {
  param([string]$content)

  # 어떤 헤더 라인이 비어있는지 확인(IndexOf로 단순 확인)
  $needs = @()
  foreach($h in $HeaderLines){
    if ($content.IndexOf($h, [System.StringComparison]::Ordinal) -lt 0) { $needs += $h }
  }
  if ($needs.Count -eq 0) { return $content }

  # 줄바꿈을 LF로 통일 → 배열 분해
  $lf = [string]([char]10)
  $crlf = [string]([char]13) + $lf
  $normalized = $content.Replace($crlf, $lf)
  $lines = $normalized.Split(@($lf), [System.StringSplitOptions]::None)

  # 삽입 위치 계산: shebang 다음 또는 최상단 param(...) 블록 이후
  $insertAt = 0
  if ($lines.Count -gt 0 -and $lines[0] -match '^\s*#\!') { $insertAt = 1 }

  if ($lines.Count -gt 0 -and $lines[0] -match '^\s*param\s*\(') {
    $depth = 0
    for($i=0; $i -lt $lines.Count; $i++){
      if ($lines[$i] -match '\(') { $depth++ }
      if ($lines[$i] -match '\)') {
        $depth--
        if ($depth -le 0) { $insertAt = $i + 1; break }
      }
    }
  }

  $prefix = @()
  if ($insertAt -gt 0) { $prefix = $lines[0..($insertAt-1)] }
  $suffix = $lines[$insertAt..($lines.Count-1)]

  $injected = @()
  foreach($h in $needs){ $injected += $h }

  $newLines = @()
  $newLines += $prefix
  if ($injected.Count -gt 0) {
    if ($prefix.Count -gt 0) { $newLines += "" }
    $newLines += $injected
  }
  if ($suffix.Count -gt 0) {
    if ($injected.Count -gt 0) { $newLines += "" }
    $newLines += $suffix
  }

  # CRLF로 재조립
  $nl = [string]([char]13) + [string]([char]10)
  return ($newLines -join $nl)
}

function Invoke-StrongExit {
  param([switch]$ForceKill)
  try { $global:LASTEXITCODE = 0 } catch {}
  try { if ($host -and $host.UI) { $host.SetShouldExit(0) } } catch {}
  try { exit 0 } catch {}
  try { [Environment]::Exit(0) } catch {}
  if ($ForceKill) { try { Stop-Process -Id $PID -Force } catch {} }
}

# Main
$swAll=[System.Diagnostics.Stopwatch]::StartNew()
$report = @(); $patched=0; $skipped=0; $err=0; $trunc=$false

try {
  $ScriptsDir = Join-Path $RepoRoot 'scripts'
  $ScanRoot = $(if (Test-Path $ScriptsDir) { $ScriptsDir } else { $RepoRoot })

  $files = Get-Ps1Files $ScanRoot $MaxDepth $MaxFiles $TimeoutSec ([ref]$trunc)

  foreach($f in $files){
    try {
      $orig = [System.IO.File]::ReadAllText($f.FullName)
      $norm = Normalize-Newline $orig
      $new  = Ensure-Header $norm

      # detect '??' usage (PS5-incompatible) — report only
      $hasNullCoalesce = ($norm -match '(^|[^\?])\?\?([^\?]|$)')

      if ($new -ne $norm) {
        if ($ConfirmApply) {
          $bak = "$($f.FullName).bak"
          if (-not (Test-Path $bak)) { [System.IO.File]::Copy($f.FullName, $bak, $true) }
          [System.IO.File]::WriteAllText($f.FullName, $new, (New-Object System.Text.UTF8Encoding($false)))
          $patched++
          Write-JsonLog -Action ("Patch:{0}" -f $f.Name) -Outcome 'SUCCESS' -Message 'Header injected'
        } else {
          $skipped++
          Write-JsonLog -Action ("Preview:{0}" -f $f.Name) -Outcome 'DRYRUN' -Message 'Would inject header'
        }
      } else {
        Write-JsonLog -Action ("Check:{0}" -f $f.Name) -Outcome 'SUCCESS' -Message 'Header OK'
      }

      if ($hasNullCoalesce) {
        $report += [pscustomobject]@{ File=$f.FullName; Issue='?? operator detected (PS5-incompatible)'; Hint='Replace with: if (-not $var) { $var = <fallback> }' }
      }
    } catch {
      $err++
      Write-JsonLog -Action ("Check:{0}" -f $f.Name) -Outcome 'FAILURE' -ErrorCode=$_.Exception.Message -Message=$_.ScriptStackTrace
    }
  }

  $swAll.Stop()
  $summary = ("files={0} patched={1} preview={2} issues={3} truncated={4} timeout={5}s maxFiles={6} maxDepth={7}" -f $files.Count,$patched,$skipped,$report.Count,$trunc,$TimeoutSec,$MaxFiles,$MaxDepth)
  Write-JsonLog -Action 'RepoHardening' -Outcome $(if($err -gt 0){'FAILURE'}elseif($ConfirmApply){'SUCCESS'}else{'DRYRUN'}) -Message $summary -DurationMs $swAll.ElapsedMilliseconds

  Write-Host "==== PS Hardening Summary ===="
  Write-Host ("Scanned     : {0}" -f $files.Count)
  Write-Host ("Patched     : {0}" -f $patched)
  Write-Host ("PreviewOnly : {0}" -f $skipped)
  Write-Host ("Errors      : {0}" -f $err)
  Write-Host ("Truncated   : {0} (timeout={1}s, maxFiles={2}, maxDepth={3})" -f $trunc,$TimeoutSec,$MaxFiles,$MaxDepth)
  if ($report.Count -gt 0) {
    Write-Host ""
    Write-Host "Files needing manual fix ('??' found):"
    $report | ForEach-Object { Write-Host (" - {0}" -f $_.File) }
  }
}
finally {
  Remove-Item -Force $LockFile -ErrorAction SilentlyContinue
  if (-not $NoForceExit) { Invoke-StrongExit -ForceKill:$ForceKill }
  Invoke-StrongExit -ForceKill:$ForceKill
}