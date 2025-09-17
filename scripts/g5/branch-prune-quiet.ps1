#requires -Version 7.0
param([switch]$ConfirmApply,[string]$Root)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

function Resolve-RepoRoot {
  param([string]$Root)
  if (-not [string]::IsNullOrWhiteSpace($Root)) { return (Resolve-Path $Root).Path }
  $top = (& git rev-parse --show-toplevel 2>$null)
  if (-not [string]::IsNullOrWhiteSpace($top)) { return $top }
  return (Get-Location).Path
}

$RepoRoot = Resolve-RepoRoot -Root $Root
if ([string]::IsNullOrWhiteSpace($RepoRoot)) { throw "PRECONDITION: RepoRoot resolved empty." }
if (-not (Test-Path $RepoRoot)) { throw "PRECONDITION: RepoRoot not found: $RepoRoot" }
Set-Location $RepoRoot

$LockFile = Join-Path $RepoRoot '.gpt5.lock'
if (Test-Path $LockFile) { Write-Error 'CONFLICT: .gpt5.lock exists.'; exit 11 }
"locked $(Get-Date -Format o)" | Out-File $LockFile -NoNewline

$sw=[Diagnostics.Stopwatch]::StartNew()
$trace=[guid]::NewGuid().ToString()
$log = Join-Path $RepoRoot 'logs\apply-log.jsonl'

function Write-Rec([string]$Outcome,[string]$Msg,[string]$Level='INFO'){
  $rec=@{timestamp=(Get-Date).ToString('o');level=$Level;traceId=$trace;module='git';action='branch-prune-quiet';inputHash='';outcome=$Outcome;durationMs=$sw.ElapsedMilliseconds;errorCode='';message=$Msg} | ConvertTo-Json -Compress
  New-Item -ItemType Directory -Force -Path (Split-Path $log) | Out-Null
  Add-Content -Path $log -Value $rec
}

try {
  $env:GIT_PAGER='' ; $env:LESS='-FRX'

  # gone 브랜치 수집
  $gone = git --no-pager branch -vv | ForEach-Object {
    $line = $_.ToString()
    if ($line -match '^\*?\s*(\S+).*?\[origin\/[^\]:]+:\s+gone\]') { $Matches[1] }
  } | Sort-Object -Unique

  if (-not $gone) {
    Write-Host "[CLEAN] no local branches with gone upstream"
    Write-Rec 'OK' 'nothing to delete'
    return
  }

  Write-Host "[PREVIEW] would delete:"; $gone | ForEach-Object { "  - $_" }

  if (-not $ConfirmApply) {
    Write-Host "`n[HINT] 적용하려면: `$env:CONFIRM_APPLY='true'; pwsh -File .\scripts\g5\branch-prune-quiet.ps1 -ConfirmApply"
    Write-Rec 'PREVIEW' ("would delete: " + ($gone -join ', '))
    return
  }

  $current   = (git rev-parse --abbrev-ref HEAD).Trim()
  $mergedSet = @( git --no-pager branch --merged origin/main --format='%(refname:short)' | ForEach-Object { $_.Trim() } )

  $count=0
  foreach ($b in $gone) {
    if ($b -eq $current) { Write-Warning "Skip current branch: $b"; continue }
    if ($mergedSet -contains $b) { git branch -d $b | Out-Null } else { git branch -D $b | Out-Null }
    $count++
  }
  Write-Host "[DONE] deleted $count branches"
  Write-Rec 'APPLIED' "deleted=$count"
}
catch {
  $err=$_.Exception.Message; $stk=$_.ScriptStackTrace
  $rec=@{timestamp=(Get-Date).ToString('o');level='ERROR';traceId=$trace;module='git';action='branch-prune-quiet';inputHash='';outcome='FAILURE';durationMs=$sw.ElapsedMilliseconds;errorCode=$err;message=$stk} | ConvertTo-Json -Compress
  New-Item -ItemType Directory -Force -Path (Split-Path $log) | Out-Null
  Add-Content -Path $log -Value $rec
  exit 13
}
finally {
  Remove-Item -Force $LockFile -ErrorAction SilentlyContinue
}
