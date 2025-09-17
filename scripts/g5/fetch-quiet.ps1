#requires -Version 7.0
param(
  [string]$Root,
  [string]$Remote = 'origin',
  [int]$TimeoutSec = 30,
  [switch]$Prune,
  [switch]$Tags
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'

function Resolve-RepoRoot {
  param([string]$Root)
  if (-not [string]::IsNullOrWhiteSpace($Root)) { return (Resolve-Path $Root).Path }
  $top = (& git rev-parse --show-toplevel 2>$null)
  if ($top) { return $top }
  return (Get-Location).Path
}

$RepoRoot = Resolve-RepoRoot -Root $Root
if (-not (Test-Path $RepoRoot)) { throw "PRECONDITION: RepoRoot not found: $RepoRoot" }
Set-Location $RepoRoot

# repo lock
$LockFile = Join-Path $RepoRoot '.gpt5.lock'
if (Test-Path $LockFile) { Write-Error 'CONFLICT: .gpt5.lock exists.'; exit 11 }
"locked $(Get-Date -Format o)" | Out-File $LockFile -NoNewline

$sw=[Diagnostics.Stopwatch]::StartNew()
$trace=[guid]::NewGuid().ToString()
$log = Join-Path $RepoRoot 'logs\apply-log.jsonl'
New-Item -ItemType Directory -Force -Path (Split-Path $log) | Out-Null

try {
  # quiet env (no pager / no prompts)
  $env:GIT_PAGER='' ; $env:LESS='-FRX'
  $env:GIT_TERMINAL_PROMPT='0'
  $env:GIT_ASKPASS='echo'

  # build args (low-speed timeout, no submodules, blob-less)
  $args = @(
    '-c','credential.interactive=never',
    '-c','http.version=HTTP/1.1',
    '-c','http.lowSpeedLimit=1',
    '-c','http.lowSpeedTime=30',
    '--no-pager','fetch',$Remote,'--no-recurse-submodules','--filter=blob:none'
  )
  if ($Prune) { $args += '--prune' }
  if ($Tags)  { $args += '--tags' }

  $outFile = Join-Path $RepoRoot ("logs\fetch-quiet-{0}.log" -f (Get-Date -Format yyyyMMdd-HHmmss))
  $p = Start-Process -FilePath 'git' -ArgumentList $args -WorkingDirectory $RepoRoot `
        -NoNewWindow -PassThru -RedirectStandardOutput $outFile -RedirectStandardError $outFile

  $completed = $true
  try {
    if (-not (Wait-Process -Id $p.Id -Timeout $TimeoutSec -ErrorAction SilentlyContinue)) {
      $completed = $false
      Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue
    }
  } catch { $completed = $false }

  $rc = if ($completed) { $p.ExitCode } else { 999 }
  if (-not $completed -or $rc -ne 0) {
    Write-Warning "git fetch did not complete cleanly (rc=$rc). Falling back to: git remote prune $Remote"
    git --no-pager remote prune $Remote | Out-Null
  }

  $msg = if ($completed) { "fetch exit=$rc" } else { "fetch timeout after ${TimeoutSec}s → pruned" }
  $outcome = if ($completed -and $rc -eq 0) { 'OK' } else { 'PARTIAL' }

  $rec=@{timestamp=(Get-Date).ToString('o');level='INFO';traceId=$trace;module='git';action='fetch-quiet';inputHash="$Remote/$TimeoutSec";outcome=$outcome;durationMs=$sw.ElapsedMilliseconds;errorCode='';message=$msg} | ConvertTo-Json -Compress
  Add-Content -Path $log -Value $rec

  if ($outcome -eq 'OK') { exit 0 } else { exit 12 }
}
catch {
  $err=$_.Exception.Message; $stk=$_.ScriptStackTrace
  $rec=@{timestamp=(Get-Date).ToString('o');level='ERROR';traceId=$trace;module='git';action='fetch-quiet';inputHash='';outcome='FAILURE';durationMs=$sw.ElapsedMilliseconds;errorCode=$err;message=$stk} | ConvertTo-Json -Compress
  Add-Content -Path $log -Value $rec
  exit 13
}
finally {
  Remove-Item -Force $LockFile -ErrorAction SilentlyContinue
}
