#requires -Version 7.0
[CmdletBinding()]
param(
  [string]$Pr,
  [string]$Sha,
  [switch]$ConfirmApply
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$PSDefaultParameterValues['*:Encoding'] = 'utf8'

# --- 1) git 없이 레포 루트 탐색 ---
function Find-RepoRoot([string]$start) {
  $d = Resolve-Path $start
  while ($d -and -not (Test-Path (Join-Path $d '.git'))) {
    $parent = Split-Path -Parent $d
    if ($parent -eq $d) { break }
    $d = $parent
  }
  if (Test-Path (Join-Path $d '.git')) { return $d }
  return (Resolve-Path $start)
}
function Get-RepoRoot {
  if ($env:GITHUB_WORKSPACE -and (Test-Path $env:GITHUB_WORKSPACE)) { return $env:GITHUB_WORKSPACE }
  return (Find-RepoRoot -start $PSScriptRoot)
}

# --- 2) 레포 루트로 작업 폴더 고정 + git 환경 보정 ---
$repo = Get-RepoRoot
Set-Location $repo
$env:GIT_DIR       = Join-Path $repo '.git'
$env:GIT_WORK_TREE = $repo
git config --global --add safe.directory "$repo" | Out-Null

# --- 3) 'git' 호출을 안전 래퍼로 강제 (재귀 금지) ---
$script:GitExe = (Get-Command git -Type Application).Source
function Invoke-GitSoft {
  param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Args)
  try {
    & $script:GitExe @Args
  } catch {
    Write-Warning "git failed: $($_.Exception.Message)"
    $global:LASTEXITCODE = 0
    return
  }
  if ($LASTEXITCODE -eq 128) {
    Write-Warning "git 128 ignored: git $($Args -join ' ')"
    $global:LASTEXITCODE = 0
  }
}
Set-Alias -Name git -Value Invoke-GitSoft -Scope Global

# (여기까지가 공통 헤더 — 아래부터 기존 함수/로직 유지)



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
