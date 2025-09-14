#requires -Version 7.0
param([string]$Old,[string]$New,[int]$Top=5)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'

$Root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$Runs = Join-Path $Root 'out\run-logs'

function CountOrZero([string]$p){
  if (Test-Path $p) { (Get-Content $p -ReadCount 2000 | Measure-Object -Line).Lines } else { 0 }
}

function Get-CountsFromDir([string]$dir){
  $map = @{}
  foreach($k in 'stdout','stderr','warn','info','verbose','debug'){
    $map[$k] = CountOrZero (Join-Path $dir ("{0}.log" -f $k))
  }
  return $map
}

function Get-Run([string]$dir){
  if (-not (Test-Path $dir)) { throw "Not found: $dir" }
  $m = Join-Path $dir 'run.json'
  $obj = $null
  if (Test-Path $m) {
    try { $obj = Get-Content -Raw -Path $m | ConvertFrom-Json } catch { $obj = $null }
  }
  if ($null -eq $obj) { $obj = [pscustomobject]@{} }

  $name    = if ($obj.PSObject.Properties['name'])    { $obj.name }    else { Split-Path $dir -Leaf }
  $target  = if ($obj.PSObject.Properties['target'])  { $obj.target }  else { '(unknown)' }
  $args    = if ($obj.PSObject.Properties['args'])    { $obj.args }    else { '' }
  $outcome = if ($obj.PSObject.Properties['outcome']) { $obj.outcome } else { '(unknown)' }
  $exit    = if ($obj.PSObject.Properties['exitCode']){ [int]$obj.exitCode } else { 0 }

  # counts 확보(누락/잘못 타입이면 디렉터리에서 재계산)
  $counts = @{}
  if ($obj.PSObject.Properties['counts']) {
    foreach($k in 'stdout','stderr','warn','info','verbose','debug'){
      $v = $obj.counts.PSObject.Properties[$k]?.Value
      if ($null -eq $v -or $v -isnot [int]) { $v = CountOrZero (Join-Path $dir ("{0}.log" -f $k)) }
      $counts[$k] = [int]$v
    }
  } else {
    $counts = Get-CountsFromDir $dir
  }

  [pscustomobject]@{
    dir=$dir; name=$name; target=$target; args=$args;
    outcome=$outcome; exitCode=$exit; counts=$counts
  }
}

function Pick-Latest2 {
  $dirs = Get-ChildItem -Path $Runs -Directory | Sort-Object LastWriteTime
  if (-not $dirs -or $dirs.Count -eq 0) { throw "No run-logs found." }
  if ($dirs.Count -eq 1) { return @($dirs[0].FullName, $dirs[0].FullName) }
  return @($dirs[$dirs.Count-2].FullName, $dirs[$dirs.Count-1].FullName)
}

if (-not $Old -or -not (Test-Path $Old) -or -not $New -or -not (Test-Path $New)) {
  $pair = Pick-Latest2
  if (-not $Old -or -not (Test-Path $Old)) { $Old = $pair[0] }
  if (-not $New -or -not (Test-Path $New)) { $New = $pair[1] }
}

$A = Get-Run $Old
$B = Get-Run $New

Write-Host "== RUN DIFF ==" -ForegroundColor Magenta
Write-Host ("Old: {0}" -f $A.dir)
Write-Host ("New: {0}" -f $B.dir)
Write-Host ("Outcome: {0}  →  {1}" -f $A.outcome,$B.outcome)
Write-Host ("Exit:    {0}  →  {1}" -f $A.exitCode,$B.exitCode)

$keys = 'stdout','warn','stderr','info','verbose','debug'
foreach($k in $keys){
  $a = [int]($A.counts[$k]  ?? 0)
  $b = [int]($B.counts[$k]  ?? 0)
  $d = $b - $a
  Write-Host ("{0,-7}: {1,5} → {2,5}   (Δ {3})" -f $k,$a,$b,$d)
}

function Norm([string]$s){ ($s ?? '') -replace '\s+',' ' }
$eOld = if (Test-Path (Join-Path $A.dir 'stderr.log')) { Get-Content (Join-Path $A.dir 'stderr.log') } else { @() }
$eNew = if (Test-Path (Join-Path $B.dir 'stderr.log')) { Get-Content (Join-Path $B.dir 'stderr.log') } else { @() }
$setOld = [System.Collections.Generic.HashSet[string]]::new(); foreach($l in $eOld){ [void]$setOld.Add((Norm $l)) }
$setNew = [System.Collections.Generic.HashSet[string]]::new(); foreach($l in $eNew){ [void]$setNew.Add((Norm $l)) }

$added    = $eNew | Where-Object { -not $setOld.Contains((Norm $_)) } | Select-Object -First $Top
$resolved = $eOld | Where-Object { -not $setNew.Contains((Norm $_)) } | Select-Object -First $Top

Write-Host "`nNew error lines (up to $Top):" -ForegroundColor DarkYellow
if ($added)    { $added    | ForEach-Object { " + " + $_ } } else { Write-Host "(none)" }
Write-Host "Resolved error lines (up to $Top):" -ForegroundColor DarkYellow
if ($resolved) { $resolved | ForEach-Object { " - " + $_ } } else { Write-Host "(none)" }