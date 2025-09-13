# scripts/report-engine.ps1 — Simple memory report engine (PS-only)
#requires -PSEdition Core
#requires -Version 7.0
param(
  [string]$InputPath = "$(Join-Path (Split-Path -Parent $PSScriptRoot) 'contracts/v1/samples/report_request.sample.json')",
  [string]$OutputPath = "$(Join-Path (Split-Path -Parent $PSScriptRoot) 'out/report_result.demo.json')"
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
  format  = ($req.format ? $req.format : 'JSON')
  rendered = @{}
}

if ($result.format -eq 'CSV') {
  $sb = New-Object System.Text.StringBuilder
  [void]$sb.AppendLine(($result.columns -join ','))
  foreach($row in $result.rows){
    $cells = @()
    for($i=0;$i -lt $result.columns.Count;$i++){
      $v = if ($i -lt $row.Count) { $row[$i] } else { $null }
      if ($v -is [string]) { $cells += ('"'+$v.Replace('"','""')+'"') }
      else { $cells += ($v -as [string]) }
    }
    [void]$sb.AppendLine(($cells -join ','))
  }
  $result.rendered = @{ csv = $sb.ToString() }
} else {
  $result.rendered = @{ json = @{ count = $result.rows.Count } }
}

# save
$dir = Split-Path -Parent $OutputPath
New-Item -ItemType Directory -Force -Path $dir | Out-Null
($result | ConvertTo-Json -Depth 50) | Out-File -LiteralPath $OutputPath

# echo summary
"[ENGINE] saved: $OutputPath" | Write-Host
"  title  : $($result.title)" | Write-Host
"  columns: $($result.columns -join ', ')" | Write-Host
"  rows   : $($result.rows.Count)" | Write-Host
"  format : $($result.format)" | Write-Host
