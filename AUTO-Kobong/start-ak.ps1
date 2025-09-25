# APPLY IN SHELL
#requires -Version 7.0
param([string]$RepoRoot="D:\ChatGPT5_AI_Link\dosc\kobong-orchestrator")
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'

# 경로 확인
$G5 = Join-Path $RepoRoot 'AUTO-Kobong\scripts\g5'
$Dispatch = Join-Path $G5 'ak-dispatch.ps1'
if (!(Test-Path $Dispatch)) { Write-Error "DISPATCH 스크립트 없음: $Dispatch"; exit 10 }

# LED 라벨
function Led([string]$t,[string]$c='Cyan'){ Write-Host ("`n==== $t ====`n") -ForegroundColor $c }
function PauseMsg { Write-Host "`n계속하려면 Enter..."; [void][Console]::ReadLine() }

# 락 닥터(스테일하면 해제)
function Unlock-StaleLock([int]$Minutes=10,[switch]$Force){
  $lock = Join-Path $RepoRoot '.gpt5.lock'
  if (!(Test-Path $lock)) { Led "락 없음" 'Green'; return }
  $age=((Get-Date)-(Get-Item $lock).LastWriteTime).TotalMinutes
  Write-Host "[LOCK] $lock  age=$([math]::Round($age,2))m"
  if ($age -ge $Minutes -or $Force){
    Remove-Item -Force $lock
    Led "락 해제 완료" 'Green'
  } else {
    Led "최근 락: 잠시 후 다시" 'Yellow'
  }
}

# 디스패처 호출 헬퍼
function Run-AK([string]$Cmd,[string]$Arg='',[switch]$Apply){
  Push-Location $RepoRoot
  try{
    $args = @('-File', $Dispatch, '-Command', $Cmd)
    if ($Arg) { $args += @('-Arg', $Arg) }
    if ($Apply) { $args += '-ConfirmApply' }
    $mode = ' (DRY)'
    if ($Apply) { $mode = ' (APPLY)' }   # if는 표현식이 아니므로 재지정
    Led ("실행: {0}{1}" -f $Cmd, $mode) 'Cyan'
    pwsh -NoLogo -NoProfile @args
  } finally { Pop-Location }
}

# GitHub 열기(원격 URL 유추)
function Open-Github{
  Push-Location $RepoRoot
  try{
    $url = (git config --get remote.origin.url 2>$null)
    if (-not $url) { Start-Process "https://github.com" ; return }
    if ($url -like 'git@github.com:*'){ $url=$url -replace '^git@github\.com:','https://github.com/' -replace '\.git$','' }
    if ($url -like 'https://github.com/*'){ Start-Process $url } else { Start-Process "https://github.com" }
  } finally { Pop-Location }
}

# 메인 메뉴 루프
while ($true){
  Clear-Host
  Write-Host "==== AUTO-KOBONG 초간편 메뉴 ====" -ForegroundColor Cyan
  Write-Host "1) 코드 스캔 (DRY-RUN)" -ForegroundColor Green
  Write-Host "2) 자동 재작성 (DRY-RUN)" -ForegroundColor Green
  Write-Host "3) FixLoop 미리보기 (DRY-RUN)" -ForegroundColor Green
  Write-Host "4) FixLoop 적용 (APPLY)" -ForegroundColor Yellow
  Write-Host "5) 테스트 실행 (로그)" -ForegroundColor Green
  Write-Host "6) AK-LIVE 주석 추출 (DRY-RUN)" -ForegroundColor Green
  Write-Host "7) GitHub 열기" -ForegroundColor Cyan
  Write-Host "9) 락 해제(.gpt5.lock) — 오래됐을 때" -ForegroundColor Magenta
  Write-Host "0) 종료" -ForegroundColor DarkGray
  $ch = Read-Host "선택 숫자"

  switch ($ch) {
    '1' { Run-AK 'scan'; PauseMsg }
    '2' { $msg = Read-Host "재작성 메모(엔터=기본)"; if ([string]::IsNullOrWhiteSpace($msg)) { $msg='rewrite-demo' }; Run-AK 'rewrite' -Arg $msg; PauseMsg }
    '3' { Run-AK 'fixloop'; PauseMsg }
    '4' { Write-Host "APPLY 실행은 되돌리기 전제(URS)입니다. 계속? (Y/N)"; $ok=Read-Host; if ($ok -match '^[Yy]'){ Run-AK 'fixloop' -Apply }; PauseMsg }
    '5' { Run-AK 'test'; PauseMsg }
    '6' { & (Join-Path $G5 'ak-live-extract.ps1'); PauseMsg }
    '7' { Open-Github; PauseMsg }
    '9' { Unlock-StaleLock -Minutes 10; PauseMsg }
    '0' { break }
    default { }
  }
}
