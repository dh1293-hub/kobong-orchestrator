# PS-GUARD-BOOTSTRAP v1 — must be dot-sourced by all scripts
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# Repo root = parent of scripts
$global:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
if (-not (Test-Path $global:RepoRoot)) { throw "PRECONDITION: RepoRoot not found: $global:RepoRoot" }
Set-Location $global:RepoRoot

function Assert-InRepo([string]$Path) {
  $full = (Resolve-Path $Path).Path
  $root = (Resolve-Path $global:RepoRoot).Path
  if (-not $full.StartsWith($root, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "LOGIC: Path out of repo: $full"
  }
}

# Lock
$global:LockFile = Join-Path $global:RepoRoot '.gpt5.lock'
function Enter-Gpt5Lock {
  if (Test-Path $global:LockFile) { throw 'CONFLICT: Another operation in progress (.gpt5.lock exists).' }
  'locked ' + (Get-Date).ToString('o') | Out-File $global:LockFile -Encoding utf8 -NoNewline
}
function Exit-Gpt5Lock { Remove-Item -Force $global:LockFile -ErrorAction SilentlyContinue }

# Logs dir
New-Item -ItemType Directory -Force -Path (Join-Path $global:RepoRoot 'logs') | Out-Null

function Write-JsonLog($obj) {
  $line = ($obj | ConvertTo-Json -Depth 6 -Compress)
  $log  = Join-Path $global:RepoRoot 'logs/apply-log.jsonl'
  New-Item -ItemType Directory -Force -Path (Split-Path $log) | Out-Null
  Add-Content -Path $log -Value $line
}

function New-ErrorReport {
  param(
    [Parameter(Mandatory)] [string] $Category,
    [Parameter(Mandatory)] [string] $Code,
    [Parameter(Mandatory)] $Error
  )
  $dir = Join-Path $global:RepoRoot 'logs/error-reports'
  New-Item -ItemType Directory -Force -Path $dir | Out-Null
  $stamp = (Get-Date).ToString('yyyyMMdd-HHmmss')
  # 일련번호 부여
  $seq = (Get-ChildItem $dir -Filter "$stamp-*.txt" | Measure-Object).Count + 1
  $file = Join-Path $dir "$stamp-{0:d2}.txt" -f $seq
  $content = @"
[When] $((Get-Date).ToString('O'))
[Category] $Category
[Code] $Code
[Message] $($Error.Exception.Message)
[Type] $($Error.Exception.GetType().FullName)

[Stack]
$($Error.ScriptStackTrace)

"@
  $content | Out-File -FilePath $file -Encoding UTF8 -Force
  return $file
}

function Invoke-Gpt5Step {
  param(
    [Parameter(Mandatory)] [string] $Name,
    [Parameter(Mandatory)] [scriptblock] $Action,
    [switch] $DryRun,
    [switch] $ConfirmApply
  )
  $sw=[System.Diagnostics.Stopwatch]::StartNew(); $trace=[guid]::NewGuid().ToString()
  try {
    Enter-Gpt5Lock
    if ($DryRun) { & $Action ; $outcome='DRYRUN' }
    else {
      if (-not $ConfirmApply){ throw 'PRECONDITION: ConfirmApply required.' }
      & $Action ; $outcome='SUCCESS'
    }
    Write-JsonLog @{
      timestamp=(Get-Date).ToString('o'); level='INFO'; traceId=$trace;
      module='scripts'; action=$Name; outcome=$outcome; durationMs=$sw.ElapsedMilliseconds; message=''
    }
  } catch {
    Write-JsonLog @{
      timestamp=(Get-Date).ToString('o'); level='ERROR'; traceId=$trace;
      module='scripts'; action=$Name; outcome='FAILURE';
      durationMs=$sw.ElapsedMilliseconds; errorCode=$_.Exception.Message; message=$_.ScriptStackTrace
    }
    throw
  } finally { Exit-Gpt5Lock }
}