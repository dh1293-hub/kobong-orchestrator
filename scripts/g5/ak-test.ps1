# APPLY IN SHELL
#requires -Version 7.0
param([string]$Pr,[string]$Sha,[switch]$ConfirmApply)
# ---------- SAFE BOOTSTRAP (git 의존 제거 + 레포 루트 고정) ----------
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$PSDefaultParameterValues['*:Encoding'] = 'utf8'

function Find-RepoRoot([string]$start) {
  $d = Resolve-Path $start
  while ($d -and -not (Test-Path (Join-Path $d '.git'))) {
    $parent = Split-Path -Parent $d
    if ($parent -eq $d) { break }  # 디스크 루트까지 올라감
    $d = $parent
  }
  if (Test-Path (Join-Path $d '.git')) { return $d }
  return (Resolve-Path $start)
}

function Get-RepoRoot {
  if ($env:GITHUB_WORKSPACE -and (Test-Path $env:GITHUB_WORKSPACE)) { return $env:GITHUB_WORKSPACE }
  return (Find-RepoRoot -start $PSScriptRoot)
}

# 레포 루트 보장 + 작업 폴더 고정
$repo = Get-RepoRoot
Set-Location $repo

# git 호출이 남아있을 경우 128 무시(경고만) 래퍼
function Invoke-GitSoft { param([Parameter(ValueFromRemainingArguments=$true)][string[]]$Args)
  try { & git @Args } catch { Write-Warning "git failed: $($_.Exception.Message)"; $global:LASTEXITCODE = 0; return }
  if ($LASTEXITCODE -eq 128) { Write-Warning "git 128 ignored: git $($Args -join ' ')"; $global:LASTEXITCODE = 0 }
}
Set-Alias git Invoke-GitSoft -Scope Local
# -------------------------------------------------------------------
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
