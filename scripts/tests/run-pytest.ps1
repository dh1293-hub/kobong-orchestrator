#requires -Version 7.0
param([Parameter(Position=0, ValueFromRemainingArguments=$true)][string[]]$PytestArgs)
Set-StrictMode -Version Latest; $ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'; $PSDefaultParameterValues['*:Encoding']='utf8'

$RepoRoot = (git rev-parse --show-toplevel 2>$null) ?? "D:\ChatGPT5_AI_Link\dosc\kobong-orchestrator"
$Server   = Join-Path $RepoRoot 'server'
$Target   = Join-Path $RepoRoot 'server\tests'
$VenvDir  = Join-Path $Server '.venv'
$VenvPy   = Join-Path $VenvDir 'Scripts\python.exe'

if (-not (Test-Path $VenvPy)) {
  $py = (Get-Command py -ErrorAction SilentlyContinue)?.Path ?? (Get-Command python -ErrorAction SilentlyContinue)?.Path
  if (-not $py) { Write-Error "PRECONDITION: system Python not found"; exit 10 }
  & $py -m venv $VenvDir; if ($LASTEXITCODE -ne 0) { Write-Error "venv create failed"; exit 13 }
}
& $VenvPy -m pip install -U pip
$req = Join-Path $Server 'requirements.txt'
if (Test-Path $req) { & $VenvPy -m pip install -r $req } else { & $VenvPy -m pip install fastapi uvicorn[standard] httpx pytest jsonschema }

if (-not $PytestArgs -or $PytestArgs.Count -eq 0) { $PytestArgs=@('-q','--maxfail=1') }

$logsDir = Join-Path $RepoRoot 'logs\test'; New-Item -ItemType Directory -Force -Path $logsDir | Out-Null
$ts = Get-Date -Format 'yyyyMMdd-HHmmss'; $junit = Join-Path $logsDir ("junit-"+$ts+".xml")

# 핵심 수정: CWD를 루트로, 타깃은 절대경로
$env:PYTHONPATH = ($RepoRoot + ';' + ($env:PYTHONPATH ?? ''))
Push-Location $RepoRoot
try {
  & $VenvPy -m pytest $Target --junitxml $junit @PytestArgs
  exit $LASTEXITCODE
} finally {
  Pop-Location
}
