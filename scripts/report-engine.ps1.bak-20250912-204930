#requires -PSEdition Core
#requires -Version 7.0
param(
  [string] $ReqFile,
  [string] $OutFile
)
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-GitRoot { try { git rev-parse --show-toplevel 2>$null } catch { $null } }

# ===== env/paths =====
$ROOT  = $env:HAN_GPT5_ROOT
if (-not $ROOT) { $ROOT = Get-GitRoot }
if (-not $ROOT) { $ROOT = (Resolve-Path "$PSScriptRoot/..").Path }
if (-not (Test-Path $ROOT)) { throw "Invalid root: $ROOT" }
$env:HAN_GPT5_ROOT = $ROOT

$OUTDIR = $env:HAN_GPT5_OUT
if (-not $OUTDIR) { $OUTDIR = Join-Path $ROOT "out" }

if (-not $ReqFile) { $ReqFile = Join-Path $OUTDIR "dsl_request.demo.json" }
if (-not $OutFile) { $OutFile = Join-Path $OUTDIR "report_result.dsl.json" }

# ===== helpers =====
function Read-Json([string] $path) {
  if (-not (Test-Path $path)) { throw "PRECONDITION: input JSON not found: $path" }
  Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json
}

function Has-Prop($obj, [string]$name) { $obj.PSObject.Properties.Name -contains $name }

function To-ReportRequest($obj) {
  # Already ReportRequest?
  if (Has-Prop $obj 'title') {
    if (-not ($obj.title -is [string]))  { throw 'PRECONDITION: title must be string' }
    if (-not (Has-Prop $obj 'columns'))  { throw 'PRECONDITION: columns required' }
    return $obj
  }
  # DSL-shape → ReportRequest
  if (Has-Prop $obj 'from') {
    $from = [string]$obj.from
    $cols = @()
    if (Has-Prop $obj 'columns') { $cols = @($obj.columns) } else { $cols = @('id') }
    $fmt  = (Has-Prop $obj 'format') ? ([string]$obj.format) : 'CSV'
    $req  = [ordered]@{
      title   = "report:$from"
      columns = @($cols | ForEach-Object { "$_" })
      format  = $fmt.ToUpperInvariant()
      source  = @{ type = 'dsl'; from = $from }
    }
    return ($req | ConvertTo-Json -Depth 6 | ConvertFrom-Json)
  }
  throw "LOGIC: unsupported input shape (need 'title' or 'from')"
}

function Get-Dataset([string] $name) {
  switch ($name.ToLowerInvariant()) {
    'sample' {
      return @(
        @{ id = 1; name = 'Alice'; active = $true  },
        @{ id = 2; name = 'Bob';   active = $false }
      )
    }
    default { return @() }
  }
}

function Get-Value {
  param([Parameter(Mandatory)] $obj, [Parameter(Mandatory)][string] $key)
  if ($null -eq $obj) { return $null }
  if ($obj -is [hashtable]) { if ($obj.ContainsKey($key)) { return $obj[$key] } else { return $null } }
  $prop = $obj.PSObject.Properties[$key]
  if ($prop) { return $prop.Value } else { return $null }
}

function Project-Columns($rows, $columns) {
  foreach ($r in $rows) {
    $o = [ordered]@{}
    foreach ($c in $columns) {
      $o[$c] = (Get-Value -obj $r -key $c)
    }
    $o
  }
}

function Write-CsvFile($rows, $columns, $path) {
  $dir = Split-Path -Parent $path
  New-Item -ItemType Directory -Force -Path $dir | Out-Null
  $lines = New-Object System.Collections.Generic.List[string]
  $lines.Add(($columns -join ","))
  foreach ($row in $rows) {
    $vals = foreach ($c in $columns) {
      $v = Get-Value -obj $row -key $c
      if ($null -eq $v) { "" }
      else {
        $s = [string]$v
        if ($s -match '[,"\r\n]') { '"' + ($s -replace '"','""') + '"' } else { $s }
      }
    }
    $lines.Add(($vals -join ","))
  }
  $lines | Out-File -LiteralPath $path -Encoding utf8
}

# ===== main =====
Write-Host "[RUN] report-engine → $OutFile"
$inObj = Read-Json $ReqFile
$req   = To-ReportRequest $inObj

# dataset name 추출: source.from 우선, 없으면 title 패턴
$fromName = $null
if ((Has-Prop $req 'source') -and (Has-Prop $req.source 'from')) { $fromName = [string]$req.source.from }
if (-not $fromName) {
  if ([string]$req.title -match '^report:(.+)$') { $fromName = $Matches[1] } else { $fromName = 'sample' }
}

$rawData = Get-Dataset $fromName
$proj    = @(Project-Columns -rows $rawData -columns $req.columns)

$result = [ordered]@{
  title   = $req.title
  columns = @($req.columns)
  rows    = $proj.Count
  format  = (($req.format) ? $req.format : 'CSV').ToUpperInvariant()
}

if ($result.format -eq 'CSV') {
  $csvPath = Join-Path $OUTDIR 'report_result.dsl.csv'
  Write-CsvFile -rows $proj -columns $req.columns -path $csvPath
  $result.csv = $csvPath
} else {
  $jsonDataPath = Join-Path $OUTDIR 'report_result.dsl.data.json'
  New-Item -ItemType Directory -Force -Path (Split-Path -Parent $jsonDataPath) | Out-Null
  $proj | ConvertTo-Json -Depth 6 | Out-File -LiteralPath $jsonDataPath -Encoding utf8
  $result.json = $jsonDataPath
}

New-Item -ItemType Directory -Force -Path (Split-Path -Parent $OutFile) | Out-Null
$result | ConvertTo-Json -Depth 6 | Out-File -LiteralPath $OutFile -Encoding utf8

Write-Host "[ENGINE] saved: $OutFile"
Write-Host ("  title  : {0}" -f $result.title)
Write-Host ("  columns: {0}" -f ($result.columns -join ', '))
Write-Host ("  rows   : {0}" -f $result.rows)
Write-Host ("  format : {0}" -f $result.format)
if ($result.PSObject.Properties.Name -contains 'csv')  { Write-Host ("  csv    : {0}" -f $result.csv) }
if ($result.PSObject.Properties.Name -contains 'json') { Write-Host ("  json   : {0}" -f $result.json) }
