# scripts/run-report-demo.ps1 — run report-engine then self-validate
#requires -PSEdition Core
#requires -Version 7.0
param([string]$Root = $(Get-Location).Path)

$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'

$RepoRoot = (Resolve-Path $Root).Path
$Engine   = Join-Path $RepoRoot 'scripts/report-engine.ps1'
$ReqPath  = Join-Path $RepoRoot 'contracts/v1/samples/report_request.sample.json'
$OutPath  = Join-Path $RepoRoot 'out/report_result.demo.json'
$LogPath  = Join-Path $RepoRoot 'logs/apply-log.jsonl'
New-Item -ItemType Directory -Force -Path (Split-Path $LogPath) | Out-Null

function Write-JsonLog($o){ Add-Content -Path $LogPath -Value ($o | ConvertTo-Json -Depth 6 -Compress) }
function Validate-ReportResult($obj) {
  if (-not ($obj.title -is [string])) { return 'title must be string' }
  if (-not ($obj.columns -is [object[]]) -or $obj.columns.Count -lt 1) { return 'columns must be array' }
  if (-not ($obj.rows -is [object[]])) { return 'rows must be array' }
  if (-not ($obj.format -is [string])) { return 'format required' }
  return $null
}

Write-Host "[RUN] report-engine → $OutPath"
& $Engine -InputPath $ReqPath -OutputPath $OutPath

if (-not (Test-Path -LiteralPath $OutPath)) {
  Write-Host "[FAIL] result not found."
  Write-JsonLog @{ timestamp=(Get-Date).ToString('o'); level='ERROR'; module='report-demo'; action='run'; outcome='FAIL'; message='result missing' }
  exit 1
}

$res = (Get-Content -LiteralPath $OutPath -Raw) | ConvertFrom-Json -Depth 50
$err = Validate-ReportResult $res
if ($err) {
  "[FAIL] result validation :: $err" | Write-Host
  Write-JsonLog @{ timestamp=(Get-Date).ToString('o'); level='ERROR'; module='report-demo'; action='validate'; outcome='FAIL'; message=$err }
  exit 1
}

"[PASS] report-engine demo OK" | Write-Host
Write-JsonLog @{ timestamp=(Get-Date).ToString('o'); level='INFO'; module='report-demo'; action='validate'; outcome='PASS'; path=$OutPath }
exit 0
