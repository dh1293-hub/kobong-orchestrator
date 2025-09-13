# scripts/report-engine.ps1 — Simple memory report engine (PS-only) v1.1 (CSV file output)
#requires -PSEdition Core
#requires -Version 7.0
param(
  [string]$InputPath = "$(Join-Path (Split-Path -Parent $PSScriptRoot) 'contracts/v1/samples/report_request.sample.json')",
  [string]$OutputPath = "$(Join-Path (Split-Path -Parent $PSScriptRoot) 'out/report_result.demo.json')",
  [string]$CsvPath    = $null  # format=CSV일 때 파일 저장 위치(미지정 시 OutputPath와 같은 이름의 .csv)
)

$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'

function Validate-ReportRequest($obj) {
  if (-not ($obj.title -is [string])) { return 'title must be string' }
  if (-not ($obj.columns -is [object[]]) -or $obj.columns.Count -lt 1) { return 'columns must be non-empty array' }
  foreach($h in $obj.columns){ if (-not ($h -is [string])) { return 'columns items must be string' } }
  if (-not ($obj.rows -is [object[]])) { return 'rows must be array' }
  foreach($r in $obj.rows){ if (-not ($r -is [object[]])) { return 'each row must be array' } }
  if ($obj.format -and ($obj.format -notin @('CSV','JSON'))) { return 'format must be CSV|JSON' }
  return $null
}

# load request
if (-not (Test-Path -LiteralPath $InputPath)) { throw "PRECONDITION: request not found: $InputPath" }
$req = (Get-Content -LiteralPath $InputPath -Raw) | ConvertFrom-Json -Depth 50
$err = Validate-ReportRequest $req
if ($err) { throw "LOGIC: invalid request :: $err" }

# generate
$result = [ordered]@{
  title   = $req.title
  columns = $req.columns
  rows    = $req.rows
  format  = ([string]::IsNullOrWhiteSpace($req.format) ? 'JSON' : $req.format)
  rendered = @{}
}

# ensure out dir
$dir = Split-Path -Parent $OutputPath
New-Item -ItemType Directory -Force -Path $dir | Out-Null

if ($result.format -eq 'CSV') {
  # build CSV text
  $sb = New-Object System.Text.StringBuilder
  [void]$sb.AppendLine(($result.columns -join ','))
  foreach($row in $result.rows){
    $cells = @()
    for($i=0;$i -lt $result.columns.Count;$i++){
      $v = if ($i -lt $row.Count) { $row[$i] } else { $null }
      if ($v -is [string]) { $cells += ('"'+$v.Replace('"','""')+'"') }
      elseif ($null -eq $v) { $cells += '' }
      else { $cells += ($v -as [string]) }
    }
    [void]$sb.AppendLine(($cells -join ','))
  }
  $csvText = $sb.ToString()
  $result.rendered = @{ csv = $csvText }

  # write CSV file if requested (or default alongside OutputPath)
  if (-not $CsvPath -or [string]::IsNullOrWhiteSpace($CsvPath)) {
    $CsvPath = [System.IO.Path]::ChangeExtension($OutputPath, '.csv')
  }
  $csvDir = Split-Path -Parent $CsvPath
  New-Item -ItemType Directory -Force -Path $csvDir | Out-Null
  $csvText | Out-File -LiteralPath $CsvPath
} else {
  $result.rendered = @{ json = @{ count = $result.rows.Count } }
}

# save JSON result
($result | ConvertTo-Json -Depth 50) | Out-File -LiteralPath $OutputPath

# echo summary
"[ENGINE] saved: $OutputPath" | Write-Host
"  title  : $($result.title)" | Write-Host
"  columns: $($result.columns -join ', ')" | Write-Host
"  rows   : $($result.rows.Count)" | Write-Host
"  format : $($result.format)" | Write-Host
if ($result.format -eq 'CSV') {
  "  csv    : $CsvPath" | Write-Host
}
