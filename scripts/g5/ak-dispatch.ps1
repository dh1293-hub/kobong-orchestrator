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
/ak help               - 이 도움말
/ak ping               - 연결 확인
/ak scan [--all]       - 리포 상태 간단 점검
/ak test [--fast]      - 가능한 테스트 실행(Pester/PyTest/npm)
/ak lint               - 코드 린트(PowerShell/Ruff/Flake8/ESLint)
/ak audit              - 의존성 보안 점검(npm audit/pip-audit)
/ak fmt                - 포맷 체크(Prettier/black/isort)
/ak status             - 최근 워크플로/체크 상태 요약
"@ | Write-Host
}

if (-not $RawComment) { Print-Help; exit 0 }
if ($RawComment -notmatch '/ak\s+([a-z0-9\-]+)(.*)') { Print-Help; exit 0 }

$cmd  = $matches[1]
$rest = ($matches[2] ?? '').Trim()
$argv = @()
if ($rest) { $argv = $rest -split '\s+' }

switch ($cmd) {
  'help' { Print-Help; exit 0 }
  'ping' { Write-Host "[AK] command=ping args='$rest' sha=$Sha pr=$Pr (stub ok)"; exit 0 }
  'scan' { & (Join-Path $PSScriptRoot 'ak-scan.ps1')  -Raw $rest -Sha $Sha -Pr $Pr @argv; exit 0 }
  'test' { & (Join-Path $PSScriptRoot 'ak-test.ps1')  -Raw $rest -Sha $Sha -Pr $Pr @argv; exit 0 }
  'lint' { & (Join-Path $PSScriptRoot 'ak-lint.ps1')  -Raw $rest -Sha $Sha -Pr $Pr @argv; exit 0 }
  'audit'{ & (Join-Path $PSScriptRoot 'ak-audit.ps1') -Raw $rest -Sha $Sha -Pr $Pr @argv; exit 0 }
  'fmt'  { & (Join-Path $PSScriptRoot 'ak-fmt.ps1')   -Raw $rest -Sha $Sha -Pr $Pr @argv; exit 0 }
  'status' { & (Join-Path $PSScriptRoot 'ak-status.ps1') -Raw $rest -Sha $Sha -Pr $Pr @argv; exit 0 }
  default {
    Write-Host "[AK] unknown command='$cmd' args='$rest'"; Print-Help; exit 0
  }
}