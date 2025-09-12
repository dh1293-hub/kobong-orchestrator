# scripts/dsl-compile.ps1 — Mini DSL → ReportRequest(JSON) compiler (PS-only)
#requires -PSEdition Core
#requires -Version 7.0
param(
  [Parameter(Mandatory=$true)][string]$Dsl,
  [string]$Root = $(Get-Location).Path,
  [string]$OutputPath = "$(Join-Path (Split-Path -Parent $PSScriptRoot) 'out/dsl_request.demo.json')"
)

$ErrorActionPreference='Stop'; Set-StrictMode -Version Latest
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'

$RepoRoot = (Resolve-Path $Root).Path
$SampleReq = Join-Path $RepoRoot 'contracts/v1/samples/report_request.sample.json'
if (-not (Test-Path -LiteralPath $SampleReq)) { throw "PRECONDITION: sample request not found: $SampleReq" }

# --- parse DSL:  from <source> | select a,b,c | format CSV|JSON
$source = $null; $sel=@(); $format='JSON'
$parts = $Dsl -split '\|' | ForEach-Object { $_.Trim() } | Where-Object { $_.Length -gt 0 }
foreach($p in $parts){
  if ($p -match '^(?i)from\s+([A-Za-z0-9_]+)$') { $source = $Matches[1].ToLowerInvariant(); continue }
  if ($p -match '^(?i)select\s+(.+)$') {
    $sel = @()
    foreach($c in ($Matches[1] -split ',')) {
      $name = $c.Trim()
      if ($name.Length -gt 0) { $sel += $name }
    }
    continue
  }
  if ($p -match '^(?i)format\s+(CSV|JSON)$') { $format = $Matches[1].ToUpperInvariant(); continue }
  throw "LOGIC: unknown DSL clause -> '$p'"
}
if ([string]::IsNullOrWhiteSpace($source)) { throw "LOGIC: DSL must start with: from <source> (e.g., 'from sample')" }

# --- load base dataset (demo: only 'sample' supported)
$base = (Get-Content -LiteralPath $SampleReq -Raw) | ConvertFrom-Json -Depth 50
if ($source -ne 'sample') {
  Write-Host "[WARN] unknown source '$source' — falling back to 'sample'"
  $source = 'sample'
}
$baseCols = @($base.columns)
$baseRows = @($base.rows)

# --- determine columns
$columns = @()
if ($sel.Count -gt 0) {
  foreach($c in $sel){
    if ($baseCols -notcontains $c) { throw "LOGIC: select contains unknown column: $c (available: $($baseCols -join ', '))" }
  }
  $columns = $sel
} else {
  $columns = $baseCols
}

# --- project rows
$indexMap = @{}
for ($i=0; $i -lt $baseCols.Count; $i++) { $indexMap[$baseCols[$i]] = $i }
$rows = @()
foreach($r in $baseRows){
  $new = @()
  foreach($c in $columns){
    $idx = $indexMap[$c]
    $val = $null
    if ($idx -lt $r.Count) { $val = $r[$idx] }
    $new += $val
  }
  $rows += ,$new
}

# --- build request
$title = "report:{0}" -f $source
$req = [ordered]@{
  title   = $title
  columns = $columns
  rows    = $rows
  format  = $format
}

# --- save
$dir = Split-Path -Parent $OutputPath
New-Item -ItemType Directory -Force -Path $dir | Out-Null
($req | ConvertTo-Json -Depth 50) | Out-File -LiteralPath $OutputPath
"[DSL] compiled → $OutputPath" | Write-Host
