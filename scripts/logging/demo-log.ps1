#requires -Version 7.0
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# 래퍼 로드
. (Join-Path $PSScriptRoot 'klc-wrapper.ps1')

# 데모 로그
Write-KlcLog -Level INFO -Module 'bootstrap' -Action 'demo' -Outcome 'SUCCESS' -Message 'Hello from demo-log.ps1'
Write-Host '[OK] Demo log written (CLI or JSONL fallback).' -ForegroundColor Green

# JSONL 폴백 존재 시 Tail, 없으면 안내
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$jsonl = Join-Path $repoRoot 'logs\apply-log.jsonl'
if (Test-Path $jsonl) {
  Write-Host "`n== apply-log.jsonl (tail 3) ==" -ForegroundColor DarkCyan
  Get-Content $jsonl -Tail 3
} else {
  Write-Host '[INFO] JSONL 파일이 없습니다. (kobong_logger_cli가 PATH에서 실행된 것으로 보입니다.)' -ForegroundColor Cyan
}
