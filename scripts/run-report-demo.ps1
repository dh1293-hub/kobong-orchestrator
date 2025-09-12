# SIGNATURE: RUN-REPORT-DEMO v1.1 (delegates to run-dsl-demo.ps1)
#requires -PSEdition Core
#requires -Version 7.0
param(
  [string] $DslFile,          # default: domain/dsl.demo.dsl
  [string] $DslReqOut,        # default: out/dsl_request.demo.json
  [string] $ResultOut         # default: out/report_result.dsl.json
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-GitRoot { try { git rev-parse --show-toplevel 2>$null } catch { $null } }

$ROOT = $env:HAN_GPT5_ROOT
if (-not $ROOT) { $ROOT = Get-GitRoot }
if (-not $ROOT) { $ROOT = (Resolve-Path "$PSScriptRoot/..").Path }
if (-not (Test-Path $ROOT)) { throw "PRECONDITION: RepoRoot not found: $ROOT" }
$env:HAN_GPT5_ROOT = $ROOT

$OUTDIR = $env:HAN_GPT5_OUT
if (-not $OUTDIR) { $OUTDIR = Join-Path $ROOT 'out' }

if (-not $DslFile)   { $DslFile   = Join-Path $ROOT 'domain/dsl.demo.dsl' }
if (-not $DslReqOut) { $DslReqOut = Join-Path $OUTDIR 'dsl_request.demo.json' }
if (-not $ResultOut) { $ResultOut = Join-Path $OUTDIR 'report_result.dsl.json' }

# 1) compile (명시 파일)
Write-Host "[RUN] compile DSL → $DslReqOut"
& pwsh -NoLogo -NoProfile -File (Join-Path $ROOT 'scripts/dsl-compile.ps1') -DslFile $DslFile -OutFile $DslReqOut
if ($LASTEXITCODE -ne 0) { throw "compile failed (exit=$LASTEXITCODE)" }
if (-not (Test-Path $DslReqOut)) { throw "compile output missing: $DslReqOut" }
Write-Host "[DSL] compiled → $DslReqOut"

# 2) engine
Write-Host "[RUN] report-engine → $ResultOut"
& pwsh -NoLogo -NoProfile -File (Join-Path $ROOT 'scripts/report-engine.ps1') -ReqFile $DslReqOut -OutFile $ResultOut
if ($LASTEXITCODE -ne 0) { throw "engine failed (exit=$LASTEXITCODE)" }
if (-not (Test-Path $ResultOut)) { throw "engine output missing: $ResultOut" }

# 3) validation 위임(관대 검사 사용)
& pwsh -NoLogo -NoProfile -File (Join-Path $ROOT 'scripts/run-dsl-demo.ps1') -ResultFile $ResultOut
if ($LASTEXITCODE -ne 0) { throw "demo validation failed (exit=$LASTEXITCODE)" }

Write-Host "[DEMO] Pipeline OK."
