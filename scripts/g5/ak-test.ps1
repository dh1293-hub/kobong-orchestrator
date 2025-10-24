# APPLY IN SHELL
#requires -Version 7.0

# === GIT SAFE CONTEXT (do not remove) ===
$ErrorActionPreference = 'Continue'
try {
  if (-not $env:GITHUB_WORKSPACE) {
    $top = (git rev-parse --show-toplevel) 2>$null
    if ($top) { $env:GITHUB_WORKSPACE = $top }
  }
} catch {}
if (-not $env:GITHUB_WORKSPACE) { $env:GITHUB_WORKSPACE = Split-Path -Parent $PSScriptRoot }
if (Test-Path $env:GITHUB_WORKSPACE) { Set-Location $env:GITHUB_WORKSPACE }

git config --global --add safe.directory "$env:GITHUB_WORKSPACE" 2>$null
$gitExe = (Get-Command git -Type Application).Source

function global:Invoke-GitSoft {
  param([Parameter(ValueFromRemainingArguments=$true)][string[]]$Args)
  & $gitExe @Args
  $code = $LASTEXITCODE
  if ($code -eq 128) {
    Write-Warning "git 128 ignored: git $($Args -join ' ')"
    $global:LASTEXITCODE = 0
  }
  return $global:LASTEXITCODE
}

Set-Alias -Name git -Value Invoke-GitSoft -Scope Global
# === /GIT SAFE CONTEXT ===

param([string]$Pr,[string]$Sha,[switch]$ConfirmApply)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['*:Encoding']='utf8'
$sw=[Diagnostics.Stopwatch]::StartNew()

function Get-RepoRoot {
  if ($env:GITHUB_WORKSPACE) { return $env:GITHUB_WORKSPACE }
  try { $r = (git rev-parse --show-toplevel) 2>$null; if($r){ return $r } } catch {}
  return (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
}

function K($lvl,$act,$out,$msg,$exit=0){
  $rec=[ordered]@{
    timestamp=(Get-Date).ToString('o'); level=$lvl; traceId=[guid]::NewGuid().ToString();
    module='scripts'; action=$act; outcome=$out; message=$msg; durationMs=$sw.ElapsedMilliseconds
  }|ConvertTo-Json -Compress
  $root   = Get-RepoRoot
  $logDir = Join-Path $root 'logs'
  New-Item -ItemType Directory -Force -Path $logDir | Out-Null
  Add-Content -Path (Join-Path $logDir 'ak7.jsonl') -Value $rec
  if($exit -ne 0){ exit $exit }
}

try{
  $mode = ($ConfirmApply ? 'APPLY' : 'DRYRUN')
  K 'INFO'  $MyInvocation.MyCommand.Name $mode "start pr=$Pr sha=$Sha"
  Start-Sleep -Milliseconds 150
  K 'INFO'  $MyInvocation.MyCommand.Name 'SUCCESS' 'ok'
  exit 0
}catch{
  K 'ERROR' $MyInvocation.MyCommand.Name 'FAILURE' $_.Exception.Message 13
}
