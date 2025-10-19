# APPLY IN SHELL
#requires -Version 7.0
param(
  [string]$RepoRoot,
  [string]$DocsPath = 'D:\ChatGPT5_AI_Link\dosc\kobong-orchestrator-VIP\.kobong',
  [string]$Source,              # 새 문서가 모여있는 폴더(선택). 없으면 "등록만" 수행.
  [switch]$ConfirmApply
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

function Resolve-Root([string]$UserRoot){
  if ($UserRoot) { return (Resolve-Path $UserRoot).Path }
  try { $c=(git rev-parse --show-toplevel 2>$null) } catch {}
  if (-not $c) { $c=(Get-Location).Path }
  return (Resolve-Path $c).Path
}
function Write-KLC([string]$Level='INFO',[string]$Action='docs-register',[string]$Outcome='DRYRUN',[string]$ErrorCode='',[string]$Message=''){
  try {
    if (Get-Command kobong_logger_cli -ErrorAction SilentlyContinue) {
      & kobong_logger_cli log --level $Level --module 'scripts' --action $Action --outcome $Outcome --error $ErrorCode --message $Message 2>$null
      return
    }
  } catch {}
  $log = Join-Path (Get-Location) 'logs\apply-log.jsonl'
  New-Item -ItemType Directory -Force -Path (Split-Path $log) | Out-Null
  $rec = @{timestamp=(Get-Date).ToString('o');level=$Level;traceId=[guid]::NewGuid().ToString();module='scripts';action=$Action;outcome=$Outcome;errorCode=$ErrorCode;message=$Message} | ConvertTo-Json -Compress
  Add-Content -Path $log -Value $rec
}
function Get-Sha256([string]$Path){
  $sha = [System.Security.Cryptography.SHA256]::Create()
  $bytes = [IO.File]::ReadAllBytes($Path)
  ($sha.ComputeHash($bytes) | ForEach-Object { $_.ToString('x2') }) -join ''
}
function Safe-InstallFile([string]$Src,[string]$Dst){
  if (-not (Test-Path $Src)) { throw "PRECONDITION(10): 소스 없음: $Src" }
  $dstDir = Split-Path $Dst
  New-Item -ItemType Directory -Force -Path $dstDir | Out-Null
  if (Test-Path $Dst){
    $bak = "$Dst.bak-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    Copy-Item -LiteralPath $Dst -Destination $bak -Force
  }
  $tmp = "$Dst.tmp"
  Copy-Item -LiteralPath $Src -Destination $tmp -Force
  Move-Item -LiteralPath $tmp -Destination $Dst -Force
}
function Read-JsonIf([string]$Path){
  if (-not (Test-Path $Path)) { return $null }
  try { return Get-Content -Raw -LiteralPath $Path | ConvertFrom-Json -ErrorAction Stop } catch { return $null }
}
function Upsert-Doc($mf,[string]$Id,[string]$File,[string]$Title,[string]$Sha,[string]$Version){
  if (-not $mf) { $mf=[pscustomobject]@{ version=1; docs=@() } }
  if (-not $mf.docs) { $mf | Add-Member -NotePropertyName docs -NotePropertyValue @() -Force }
  $exist = $mf.docs | Where-Object { $_.id -eq $Id }
  $now = (Get-Date).ToString('o')
  $entry = [pscustomobject]@{
    id=$Id; file=$File; title=$Title; sha256=$Sha; version=$Version
    status='adopted'; replace=$true; adoptedAt=$now
  }
  if ($exist) {
    $i = [Array]::IndexOf($mf.docs, $exist[0]); $mf.docs[$i]=$entry
  } else {
    $mf.docs += $entry
  }
  return $mf
}

$root = Resolve-Root $RepoRoot
$lock = Join-Path $root '.gpt5.lock'
"locked $(Get-Date -Format o)" | Out-File $lock -Encoding utf8 -NoNewline
try{
  $targetDir = $DocsPath
  New-Item -ItemType Directory -Force -Path $targetDir | Out-Null

  # 대상 파일명
  $files = @(
    @{ id='rollback_policy'; file='ROLLBACK_POLICY.md';               title='KoBong 통합 롤백 시스템(URS)';            wantVer='';    },
    @{ id='ps7_guidelines';  file='PowerShell7_Guidelines_Kobong_v1.1.md'; title='PowerShell 7 지침 — Kobong-First';    wantVer='v1.1' },
    @{ id='klc_v1_2';        file='kobong_logger_cli_minimal_standard_v1.2.md'; title='kobong_logger_cli Minimal Standard'; wantVer='v1.2' }
  )

  $plan=@()
  foreach($f in $files){
    $dst = Join-Path $targetDir $f.file
    $src = $null
    if ($Source) {
      $src = Join-Path (Resolve-Path $Source) $f.file
      if (-not (Test-Path $src)) { throw "PRECONDITION(10): Source 폴더에 파일이 없습니다: $($f.file)" }
    }
    $plan += [pscustomobject]@{ id=$f.id; title=$f.title; src=$src; dst=$dst; wantVer=$f.wantVer }
  }

  # Dry-Run 요약
  $summary = ($plan | ForEach-Object {
    $state = if ($_.src) { if (Test-Path $_.dst) { 'replace' } else { 'add' } } else { 'register-only' }
    "{0} → {1} ({2})" -f ($_.src ?? '[등록만]'), $_.dst, $state
  }) -join "`n"
  Write-Host "[PLAN]`n$summary"
  Write-KLC 'INFO' 'docs-register' 'DRYRUN' '' "plan: $($plan.Count) files"

  if ($ConfirmApply){
    foreach($p in $plan){
      if ($p.src) { Safe-InstallFile $p.src $p.dst }
    }
    # 매니페스트 병합/업서트
    $mfPath = Join-Path $targetDir 'DocsManifest.json'
    $mf = Read-JsonIf $mfPath
    foreach($p in $plan){
      if (-not (Test-Path $p.dst)) { throw "LOGIC(13): 대상 파일이 없습니다: $($p.dst)" }
      $sha = Get-Sha256 $p.dst
      # 간단 버전 추출(파일명에 vX.Y 있으면 우선)
      $ver = if ($p.wantVer) { $p.wantVer } else { if ($p.dst -match 'v(\d+(?:\.\d+)*)') { "v$($matches[1])" } else { "" } }
      $title = $files | Where-Object { $_.id -eq $p.id } | Select-Object -ExpandProperty title
      $file  = Split-Path $p.dst -Leaf
      $mf = Upsert-Doc $mf $p.id $file $title $sha $ver
    }
    $tmp = "$mfPath.tmp"
    ($mf | ConvertTo-Json -Depth 6) | Out-File $tmp -Encoding utf8
    Move-Item -LiteralPath $tmp -Destination $mfPath -Force

    Write-Host "[APPLIED] 문서 교체/등록 및 DocsManifest.json 반영 완료"
    Write-KLC 'INFO' 'docs-register' 'SUCCESS' '' "applied: $($plan.Count) files"
  } else {
    Write-Host "[PREVIEW] 적용하려면: `$env:CONFIRM_APPLY='true' 후 동일 명령 재실행"
  }
}
catch{
  Write-Error $_.Exception.Message
  Write-KLC 'ERROR' 'docs-register' 'FAILURE' 'LOGIC' $_.Exception.Message
  exit 13
}
finally{
  Remove-Item -Force $lock -ErrorAction SilentlyContinue
}
