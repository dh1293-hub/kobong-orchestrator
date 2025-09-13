# scripts/run-report-demo.ps1 — run report-engine then self-validate (CSV file check) v1.1
#requires -PSEdition Core
#requires -Version 7.0
param([string]$Root = $(Get-Location).Path, [string]$Dsl = 'from sample | select id,name,active | format CSV')

$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'

$RepoRoot = (Resolve-Path $Root).Path
$Compiler = Join-Path $RepoRoot 'scripts/dsl-compile.ps1'
$Engine   = Join-Path $RepoRoot 'scripts/report-engine.ps1'
$ReqPath  = Join-Path $RepoRoot 'out/dsl_request.demo.json'
$OutPath  = Join-Path $RepoRoot 'out/report_result.dsl.json'
$CsvPath  = [System.IO.Path]::ChangeExtension($OutPath, '.csv')

if (-not (Test-Path $Compiler)) { throw "PRECONDITION: dsl-compile.ps1 not found: $Compiler" }
if (-not (Test-Path $Engine))   { throw "PRECONDITION: report-engine.ps1 not found: $Engine" }

"[RUN] compile DSL → $ReqPath" | Write-Host
& $Compiler -Dsl $Dsl -Root $RepoRoot -OutputPath $ReqPath

"[RUN] report-engine → $OutPath" | Write-Host
& $Engine -InputPath $ReqPath -OutputPath $OutPath -CsvPath $CsvPath

if (-not (Test-Path -LiteralPath $OutPath)) { throw "LOGIC: result not produced: $OutPath" }
$res = (Get-Content -LiteralPath $OutPath -Raw) | ConvertFrom-Json -Depth 50

# shape check
if (-not ($res.title -is [string])) { throw "LOGIC: result.title missing" }
if (-not ($res.columns -is [object[]]) -or $res.columns.Count -lt 1) { throw "LOGIC: result.columns invalid" }
if (-not ($res.rows -is [object[]])) { throw "LOGIC: result.rows invalid" }
if (-not ($res.format -is [string])) { throw "LOGIC: result.format missing" }

# rendered checks
if ($res.format -eq 'CSV') {
  if (-not $res.rendered -or -not $res.rendered.csv) { throw "LOGIC: CSV result missing rendered.csv" }
  if (-not (Test-Path -LiteralPath $CsvPath)) { throw "LOGIC: CSV file not written: $CsvPath" }
  if ((Get-Item -LiteralPath $CsvPath).Length -le 0) { throw "LOGIC: CSV file is empty: $CsvPath" }
} else {
  if (-not $res.rendered -or -not $res.rendered.json) { throw "LOGIC: JSON result missing rendered.json" }
}

"[PASS] report-engine demo OK (format=$($res.format))" | Write-Host
