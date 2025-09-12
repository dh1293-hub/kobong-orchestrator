# scripts/run-contract-tests.ps1 — contract tests + DSL cases v1.1
#requires -PSEdition Core
#requires -Version 7.0
param([string]$Root = $(Get-Location).Path)

$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'

$RepoRoot = (Resolve-Path $Root).Path
$Contracts = Join-Path $RepoRoot 'contracts/v1'
$Schemas   = Join-Path $Contracts 'schemas'
$Samples   = Join-Path $Contracts 'samples'
$Scripts   = Join-Path $RepoRoot 'scripts'
$LogPath   = Join-Path $RepoRoot 'logs/apply-log.jsonl'
New-Item -ItemType Directory -Force -Path (Split-Path $LogPath) | Out-Null

function Write-JsonLog($obj) {
  $line = ($obj | ConvertTo-Json -Depth 6 -Compress)
  Add-Content -Path $LogPath -Value $line
}

function Validate-ReleaseNotes($obj) {
  if (-not ($obj.version -is [string])) { return 'version must be string' }
  if (-not ($obj.date -is [string])) { return 'date must be string' }
  if (-not ($obj.changes -is [object[]]) -or $obj.changes.Count -lt 1) { return 'changes must be non-empty array' }
  foreach($c in $obj.changes) {
    if (-not ($c.type -is [string])) { return 'change.type must be string' }
    if (-not ($c.description -is [string])) { return 'change.description must be string' }
  }
  return $null
}
function Validate-ReportRequest($obj) {
  if (-not ($obj.title -is [string])) { return 'title must be string' }
  if (-not ($obj.columns -is [object[]]) -or $obj.columns.Count -lt 1) { return 'columns must be non-empty array' }
  foreach($h in $obj.columns){ if (-not ($h -is [string])) { return 'columns items must be string' } }
  if (-not ($obj.rows -is [object[]])) { return 'rows must be array' }
  foreach($r in $obj.rows){
    if (-not ($r -is [object[]])) { return 'each row must be array' }
  }
  if ($obj.format -and ($obj.format -notin @('CSV','JSON'))) { return 'format must be CSV|JSON' }
  return $null
}
function Validate-ReportResult($obj) {
  $err = Validate-ReportRequest $obj
  if ($err) { return $err }
  if (-not $obj.format) { return 'result.format required' }
  return $null
}

$cases = @()

# 샘플 JSON 3종 (기존)
$cases += @{ name='release_notes.sample.json'; path=(Join-Path $Samples 'release_notes.sample.json'); type='json'; fn='Validate-ReleaseNotes' }
$cases += @{ name='report_request.sample.json'; path=(Join-Path $Samples 'report_request.sample.json'); type='json'; fn='Validate-ReportRequest' }
$cases += @{ name='report_result.sample.json' ; path=(Join-Path $Samples 'report_result.sample.json') ; type='json'; fn='Validate-ReportResult' }

# DSL 2종 — 러너 호출 방식
$DslRunner = Join-Path $Scripts 'run-dsl-demo.ps1'
$cases += @{ name='dsl:json'; type='dsl'; dsl='from sample | select id,active | format JSON' }
$cases += @{ name='dsl:csv' ; type='dsl'; dsl='from sample | select id,name,active | format CSV' }

$passed=0; $failed=0

foreach($tc in $cases) {
  try {
    if ($tc.type -eq 'json') {
      $raw = Get-Content -LiteralPath $tc.path -Raw
      $obj = $raw | ConvertFrom-Json -Depth 50
      $msg = & $tc.fn $obj
      if ($null -eq $msg) {
        $passed++; Write-Host ("[PASS] {0}" -f $tc.name)
        Write-JsonLog @{ timestamp=(Get-Date).ToString('o'); level='INFO'; module='contracts-test'; case=$tc.name; outcome='PASS' }
      } else {
        $failed++; Write-Host ("[FAIL] {0} :: {1}" -f $tc.name, $msg)
        Write-JsonLog @{ timestamp=(Get-Date).ToString('o'); level='ERROR'; module='contracts-test'; case=$tc.name; outcome='FAIL'; message=$msg }
      }
    } elseif ($tc.type -eq 'dsl') {
      $args = @('-File', $DslRunner, '-Root', $RepoRoot, '-Dsl', $tc.dsl)
      $psi = (Start-Process -FilePath 'pwsh' -ArgumentList $args -NoNewWindow -PassThru -Wait)
      if ($psi.ExitCode -eq 0) {
        $passed++; Write-Host ("[PASS] {0}" -f $tc.name)
        Write-JsonLog @{ timestamp=(Get-Date).ToString('o'); level='INFO'; module='contracts-test'; case=$tc.name; outcome='PASS' }
      } else {
        $failed++; Write-Host ("[FAIL] {0} :: exit {1}" -f $tc.name, $psi.ExitCode)
        Write-JsonLog @{ timestamp=(Get-Date).ToString('o'); level='ERROR'; module='contracts-test'; case=$tc.name; outcome='FAIL'; message=("exit " + $psi.ExitCode) }
      }
    }
  } catch {
    $failed++; Write-Host ("[FAIL] {0} :: {1}" -f $tc.name, $_.Exception.Message)
    Write-JsonLog @{ timestamp=(Get-Date).ToString('o'); level='ERROR'; module='contracts-test'; case=$tc.name; outcome='FAIL'; message=$_.Exception.Message }
  }
}

$summary = "[SUMMARY] Contracts v1 — passed={0} failed={1}" -f $passed, $failed
$summary | Write-Host
if ($failed -gt 0) { exit 1 } else { exit 0 }
