#requires -PSEdition Core
#requires -Version 7.0
param(
  [string]$RawComment,
  [string]$Sha,
  [string]$Pr
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Print-Help {
@"
[AK] usage:
/ak help              - 이 도움말
/ak ping              - 연결 확인
/ak scan [--all]      - 리포 상태 간단 점검(오픈 PR/실패 런 등)
/ak test [--fast]     - 가벼운 테스트 러너 (가능한 것만 실행)
"@ | Write-Host
}

if (-not $RawComment) { Print-Help; exit 0 }
if ($RawComment -notmatch '/ak\s+([a-z0-9\-]+)(.*)') { Print-Help; exit 0 }

$cmd  = $matches[1]
$rest = ($matches[2] ?? '').Trim()
# 간단 토큰화
$argv = @()
if ($rest) { $argv = $rest -split '\s+' }

switch ($cmd) {
  'help' { Print-Help; exit 0 }
  'ping' { Write-Host "[AK] command=ping args='$rest' sha=$Sha pr=$Pr (stub ok)"; exit 0 }
  'scan' {
    $scan = Join-Path $PSScriptRoot 'ak-scan.ps1'
    & $scan -Raw $rest -Sha $Sha -Pr $Pr @argv
    exit 0
  }
  'test' {
    $test = Join-Path $PSScriptRoot 'ak-test.ps1'
    & $test -Raw $rest -Sha $Sha -Pr $Pr @argv
    exit 0
  }
  default {
    Write-Host "[AK] unknown command='$cmd' args='$rest'"
    Print-Help
    exit 0
  }
}