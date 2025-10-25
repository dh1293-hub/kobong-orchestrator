# APPLY IN SHELL
#requires -Version 7.0
param(
  [string]$G5Dir = "D:\ChatGPT5_AI_Link\dosc\kobong-orchestrator\AUTO-Kobong\scripts\g5",
  [switch]$ConfirmApply
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

function Get-RepoRoot([string]$p){
  try { if ($p) { return (Resolve-Path $p).Path } } catch {}
  try { return (git rev-parse --show-toplevel 2>$null) } catch {}
  return (Get-Location).Path
}
function AtomicWrite([string]$Path,[string]$Content){
  New-Item -ItemType Directory -Force -Path (Split-Path $Path) | Out-Null
  $ts=(Get-Date -Format 'yyyyMMdd-HHmmss'); $tmp="$Path.tmp"; $bak="$Path.bak-$ts"
  if (Test-Path $Path) { Copy-Item $Path $bak -Force }
  [IO.File]::WriteAllText($tmp,$Content,[Text.UTF8Encoding]::new($false))
  Move-Item -Force $tmp $Path
}
$Repo = Get-RepoRoot (Split-Path $G5Dir -Parent -ErrorAction SilentlyContinue)
$Lock = Join-Path $Repo '.gpt5.lock'
if (Test-Path $Lock) { Write-Error 'CONFLICT: .gpt5.lock exists.'; exit 11 }
"locked $(Get-Date -Format o)" | Out-File $Lock -Encoding utf8 -NoNewline
try {
  $dispatch = @'
# APPLY IN SHELL
#requires -Version 7.0
param(
  [ValidateSet('scan','rewrite','fixloop','test','shell')]
  [string]$Command = 'scan',
  [string]$Sha = '',
  [string]$Pr  = '',
  [string]$Arg = '',
  [switch]$ConfirmApply
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }
if (-not $PSBoundParameters.ContainsKey('Command') -or [string]::IsNullOrWhiteSpace($Command)) { $Command = 'scan' }

function Write-KLC {
  param(
    [ValidateSet('INFO','ERROR')] $Level='INFO',
    [string]$Module='auto-kobong',
    [string]$Action='step',
    [ValidateSet('SUCCESS','FAILURE','DRYRUN')] $Outcome='SUCCESS',
    [string]$ErrorCode='',
    [string]$Message='',
    [int]$DurationMs=0
  )
  try {
    if (Get-Command kobong_logger_cli -ErrorAction SilentlyContinue) {
      & kobong_logger_cli log --level $Level --module $Module --action $Action --outcome $Outcome --error $ErrorCode --message $Message --meta durationMs=$DurationMs 2>$null
      return
    }
  } catch {}
  $repo = (git rev-parse --show-toplevel 2>$null); if (-not $repo) { $repo=(Get-Location).Path }
  $log = Join-Path $repo 'logs\apply-log.jsonl'
  New-Item -ItemType Directory -Force -Path (Split-Path $log) | Out-Null
  $rec=@{timestamp=(Get-Date).ToString('o');level=$Level;traceId=[guid]::NewGuid().ToString();
    module=$Module;action=$Action;outcome=$Outcome;errorCode=$ErrorCode;message=$Message;durationMs=$DurationMs} | ConvertTo-Json -Compress
  Add-Content -Path $log -Value $rec
}

switch ($Command.ToLowerInvariant()) {
  'scan'    { & "$PSScriptRoot\ak-scan.ps1"    -ExternalId "ak-scan@$Sha"    -Pr $Pr }
  'rewrite' { & "$PSScriptRoot\ak-rewrite.ps1" -ExternalId "ak-rewrite@$Sha" -Pr $Pr -Arg $Arg -ConfirmApply:$ConfirmApply }
  'fixloop' { & "$PSScriptRoot\ak-fixloop.ps1" -Pr $Pr -ConfirmApply:$ConfirmApply }
  'test'    { & "$PSScriptRoot\ak-test.ps1"    -Pr $Pr }
  'shell'   { Write-Host '[INFO] shell passthrough (sandboxed log only)'; Write-KLC -Action 'shell' -Outcome 'DRYRUN' -Message $Arg }
  default   { Write-Host "[WARN] Unknown: $Command"; exit 10 }
}
'@

  $scan = @'
# APPLY IN SHELL
#requires -Version 7.0
param([string]$ExternalId='', [string]$Pr='')
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
Write-Host '[AK] similarity scan (demo)'
if (Get-Command kobong_logger_cli -ErrorAction SilentlyContinue) {
  kobong_logger_cli log --level INFO --module auto-kobong --action ak-scan --outcome SUCCESS --message ("externalId="+$ExternalId) 2>$null
} else {
  $repo=(git rev-parse --show-toplevel 2>$null) ?? (Get-Location).Path
  $rec=@{timestamp=(Get-Date).ToString('o');level='INFO';traceId=[guid]::NewGuid().ToString();
    module='auto-kobong';action='ak-scan';outcome='SUCCESS';errorCode='';message=("externalId="+$ExternalId)} | ConvertTo-Json -Compress
  $log=Join-Path $repo 'logs\apply-log.jsonl'; New-Item -ItemType Directory -Force -Path (Split-Path $log) | Out-Null; Add-Content -Path $log -Value $rec
}
'@

  $rewrite = @'
# APPLY IN SHELL
#requires -Version 7.0
param([string]$ExternalId='', [string]$Pr='', [string]$Arg='', [switch]$ConfirmApply)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }
if (-not $ConfirmApply) {
  Write-Host '[DRYRUN] rewrite suggestion prepared'
  if (Get-Command kobong_logger_cli -ErrorAction SilentlyContinue) {
    kobong_logger_cli log --level INFO --module auto-kobong --action ak-rewrite --outcome DRYRUN --message $Arg 2>$null
  }
  exit 0
}
Write-Host '[APPLY] rewrite suggestion applied (demo)'
if (Get-Command kobong_logger_cli -ErrorAction SilentlyContinue) {
  kobong_logger_cli log --level INFO --module auto-kobong --action ak-rewrite --outcome SUCCESS --message $Arg 2>$null
}
'@

  $fixloop = @'
# APPLY IN SHELL
#requires -Version 7.0
param([string]$Pr='', [switch]$ConfirmApply)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }
if (-not $ConfirmApply) {
  Write-Host '[DRYRUN] FixLoop preview ready'
  if (Get-Command kobong_logger_cli -ErrorAction SilentlyContinue) {
    kobong_logger_cli log --level INFO --module auto-kobong --action ak-fixloop --outcome DRYRUN --message 'preview' 2>$null
  }
  exit 0
}
Write-Host '[APPLY] FixLoop patches applied (demo)'
if (Get-Command kobong_logger_cli -ErrorAction SilentlyContinue) {
  kobong_logger_cli log --level INFO --module auto-kobong --action ak-fixloop --outcome SUCCESS --message 'applied' 2>$null
}
'@

  $test = @'
# APPLY IN SHELL
#requires -Version 7.0
param([string]$Pr='')
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
Write-Host '[AK] run tests (demo)'
if (Get-Command kobong_logger_cli -ErrorAction SilentlyContinue) {
  kobong_logger_cli log --level INFO --module auto-kobong --action ak-test --outcome SUCCESS --message ("PR="+$Pr) 2>$null
}
'@

  $live = @'
# APPLY IN SHELL
#requires -Version 7.0
param([string]$Root='')
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
$repo = (git rev-parse --show-toplevel 2>$null); if (-not $repo) { $repo=(Get-Location).Path }
$files = git ls-files | Where-Object { $_ -match '\.(ts|tsx|js|py|java|md|yml)$' }
$blocks=@()
foreach($f in $files){
  $t = Get-Content -Raw -Path (Join-Path $repo $f) -Encoding UTF8
  if ($t -match 'AK-LIVE-BEGIN'){
    $m = [regex]::Matches($t,'AK-LIVE-BEGIN(?s)(.*?)AK-LIVE-END')
    foreach($x in $m){ $blocks += [pscustomobject]@{ file=$f; body=$x.Groups[1].Value.Trim() } }
  }
}
if($blocks.Count -gt 0){
  $out = Join-Path $repo '.kobong\live.md'
  $md = ($blocks | ForEach-Object { "### $($_.file)`n```````n$($_.body)`n```````n" }) -join "`n"
  $md | Out-File $out -Encoding utf8
  Write-Host ('[AK-LIVE] extracted → ' + $out)
  if (Get-Command kobong_logger_cli -ErrorAction SilentlyContinue) {
    kobong_logger_cli log --level INFO --module auto-kobong --action ak-live-extract --outcome SUCCESS --message ("count="+$blocks.Count) 2>$null
  }
} else {
  Write-Host '[AK-LIVE] no blocks'
  if (Get-Command kobong_logger_cli -ErrorAction SilentlyContinue) {
    kobong_logger_cli log --level INFO --module auto-kobong --action ak-live-extract --outcome SUCCESS --message 'none' 2>$null
  }
}
'@

  $targets = @(
    @{ path = Join-Path $G5Dir 'ak-dispatch.ps1';     body = $dispatch },
    @{ path = Join-Path $G5Dir 'ak-scan.ps1';         body = $scan     },
    @{ path = Join-Path $G5Dir 'ak-rewrite.ps1';      body = $rewrite  },
    @{ path = Join-Path $G5Dir 'ak-fixloop.ps1';      body = $fixloop  },
    @{ path = Join-Path $G5Dir 'ak-test.ps1';         body = $test     },
    @{ path = Join-Path $G5Dir 'ak-live-extract.ps1'; body = $live     }
  )

  if (-not $ConfirmApply) {
    $plan = $targets | ForEach-Object { @{ file=$_.path; bytes=$_.body.Length } }
    $plan | ConvertTo-Json -Compress | Write-Output
    exit 0
  }

  foreach($t in $targets){ AtomicWrite -Path $t.path -Content $t.body }
  Write-Host "[APPLIED] ak-* scripts normalized: param() at top, CmdletBinding removed."
} finally {
  Remove-Item -Force $Lock -ErrorAction SilentlyContinue
}
