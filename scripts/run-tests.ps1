param()
$ErrorActionPreference='Stop'
. "$PSScriptRoot/_preamble.ps1"

# 0) 선언 프리플라이트
& "$PSScriptRoot/validate-decl.ps1"

# 1) Python 가상환경 확인
$py = Join-Path $env:HAN_GPT5_ROOT '.venv\Scripts\python.exe'
if (-not (Test-Path $py)) { throw 'PRECONDITION: .venv missing. Run Code-008 first.' }

# 2) 계약 테스트 실행
$sw=[System.Diagnostics.Stopwatch]::StartNew()
& $py -m pytest -q "tests/contract"
$exit = $LASTEXITCODE
$sw.Stop()

# 3) 결과 로깅(JSONL)
$logDir = Join-Path $env:HAN_GPT5_ROOT 'logs'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$line = @{
  timestamp = (Get-Date).ToString('o')
  level     = if ($exit -eq 0) {'INFO'} else {'ERROR'}
  module    = 'tests'
  action    = 'contract'
  outcome   = if ($exit -eq 0) {'SUCCESS'} else {'FAILURE'}
  durationMs= $sw.ElapsedMilliseconds
} | ConvertTo-Json -Compress
Add-Content -Path (Join-Path $logDir 'apply-log.jsonl') -Value $line

if ($exit -ne 0) { exit $exit }
Write-Host '[OK] run-tests completed (contract).' 
