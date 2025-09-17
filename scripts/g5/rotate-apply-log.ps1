#requires -Version 7.0
param(
  [switch]$ConfirmApply,
  [string]$Root,
  [string]$LogPath = "logs/apply-log.jsonl",
  [int]$MaxLines = 5000,
  [int]$MaxSizeMB = 10
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

$RepoRoot = if ($Root) { (Resolve-Path -LiteralPath $Root).Path } else { (git rev-parse --show-toplevel 2>$null) ?? (Get-Location).Path }
function Normalize-Path([string]$p) {
  $n=[IO.Path]::GetFullPath($p) -replace '/','\'
  if ($n[-1] -ne '\') { return $n } else { return $n.TrimEnd('\') }
}

function Assert-InRepo([string]$Path) {
  $full = Normalize-Path (Resolve-Path -LiteralPath $Path).Path
  $root = (Normalize-Path $RepoRoot)
  $rootWithSep = $root + '\'
  if ($full.Length -lt $rootWithSep.Length -or -not $full.StartsWith($rootWithSep,[StringComparison]::OrdinalIgnoreCase)) {
    throw "Path not inside repo root: $full (RepoRoot=$root)"
  }
}
}

$trace=[guid]::NewGuid().ToString()
$sw=[Diagnostics.Stopwatch]::StartNew()
$LockFile = Join-Path $RepoRoot '.gpt5.lock'
try {
  if (Test-Path $LockFile) { throw 'CONFLICT: .gpt5.lock exists.' }
  "locked $(Get-Date -Format o)" | Out-File $LockFile -Encoding utf8 -NoNewline

  $LogFull = Join-Path $RepoRoot $LogPath
  Assert-InRepo $LogFull
  if (-not (Test-Path $LogFull)) {
    New-Item -ItemType Directory -Force -Path (Split-Path $LogFull) | Out-Null
    New-Item -ItemType File -Force -Path $LogFull | Out-Null
  }

  $fi = Get-Item $LogFull
  $sizeMB = [math]::Round($fi.Length/1MB,2)
  $lines = (Measure-Object -Line -Path $LogFull).Lines
  $needRotate = ($lines -gt $MaxLines) -or ($sizeMB -gt $MaxSizeMB)

  $preview = @{
    timestamp=(Get-Date).ToString('o'); level='INFO'; traceId=$trace
    module='rotate-apply-log'; action='plan'; inputHash=''
    outcome='PREVIEW'; durationMs=0; errorCode=''
    message="sizeMB=$sizeMB, lines=$lines, MaxSizeMB=$MaxSizeMB, MaxLines=$MaxLines, rotate=$needRotate"
  } | ConvertTo-Json -Compress
  Write-Host $preview

  if (-not $needRotate) {
    if ($ConfirmApply) {
      Add-Content -Path $LogFull -Value ($preview -replace '"PREVIEW"','"NOOP"')
    }
    return
  }

  $dir = Split-Path $LogFull
  $name = Split-Path $LogFull -Leaf
  $ts = (Get-Date).ToString('yyyyMMdd-HHmmss')
  $bak = Join-Path $dir "$name.bak-$ts"
  $tmp = Join-Path $dir ".$name.tmp"

  if (-not $ConfirmApply) {
    Write-Host (@{action='write'; path=$LogFull; backup=$bak; tmp=$tmp; keepLines=$MaxLines} | ConvertTo-Json -Compress)
    return
  }

  $tail = Get-Content -LiteralPath $LogFull -Tail $MaxLines
  Copy-Item -LiteralPath $LogFull -Destination $bak -Force
  $tail | Out-File -LiteralPath $tmp -Encoding utf8 -NoNewline
  Move-Item -LiteralPath $tmp -Destination $LogFull -Force

  $sw.Stop()
  $rec = @{
    timestamp=(Get-Date).ToString('o'); level='INFO'; traceId=$trace
    module='rotate-apply-log'; action='rotate'; inputHash=''
    outcome='APPLIED'; durationMs=$sw.ElapsedMilliseconds; errorCode=''
    message="rotated to last $MaxLines lines; prevSizeMB=$sizeMB; backup=$(Split-Path $bak -Leaf)"
  } | ConvertTo-Json -Compress
  Add-Content -Path $LogFull -Value $rec
}
catch {
  $err=$_.Exception.Message
  $sw.Stop()
  try {
    $LogFull ??= Join-Path $RepoRoot $LogPath
    if ($ConfirmApply -and $LogFull) {
      Add-Content -Path $LogFull -Value (@{timestamp=(Get-Date).ToString('o');level='ERROR';traceId=$trace;module='rotate-apply-log';action='rotate';inputHash='';outcome='FAILURE';durationMs=$sw.ElapsedMilliseconds;errorCode=$err;message=$_.ScriptStackTrace} | ConvertTo-Json -Compress)
    }
  } catch {}
  throw
}
finally {
  Remove-Item -Force $LockFile -ErrorAction SilentlyContinue
}