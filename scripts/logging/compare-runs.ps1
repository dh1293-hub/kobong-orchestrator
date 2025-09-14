#requires -Version 7.0
param([string]$Old,[string]$New,[int]$Top=5)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'

$Root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$Runs = Join-Path $Root 'out\run-logs'

function CountOrZero([string]$p){
  if (Test-Path $p) { (Get-Content $p -ReadCount 2000 | Measure-Object -Line).Lines } else { 0 }
}

function Get-RunManifest([string]$dir){
  if (-not (Test-Path $dir)) { throw "Not found: $dir" }
  $m = Join-Path $dir 'run.json'
  $obj = $null
  if (Test-Path $m) {
    try { $obj = Get-Content -Raw -Path $m | ConvertFrom-Json } catch { $obj = $null }
  }
  if ($null -eq $obj) {
    $obj = [pscustomobject]@{}
  }
  if (-not ($obj.PSObject.Properties['name']))    { Add-Member -InputObject $obj -Name name    -Value (Split-Path $dir -Leaf) -MemberType NoteProperty }
  if (-not ($obj.PSObject.Properties['target']))  { Add-Member -InputObject $obj -Name target  -Value '(unknown)' -MemberType NoteProperty }
  if (-not ($obj.PSObject.Properties['args']))    { Add-Member -InputObject $obj -Name args    -Value '' -MemberType NoteProperty }
  if (-not ($obj.PSObject.Properties['outcome'])) { Add-Member -InputObject $obj -Name outcome -Value '(unknown)' -MemberType NoteProperty }
  if (-not ($obj.PSObject.Properties['exitCode'])){ Add-Member -InputObject $obj -Name exitCode-Value 0 -MemberType NoteProperty }

  # counts 보장
  if (-not ($obj.PSObject.Properties['counts'])) {
    $counts = [pscustomobject]@{}
    Add-Member -InputObject $obj -Name counts -Value $counts -MemberType NoteProperty
  }
  $c = $obj.counts
  foreach($k in 'stdout','stderr','warn','info','verbose','debug'){
    if (-not ($c.PSObject.Properties[$k])) {
      $val = CountOrZero (Join-Path $dir ("{0}.log" -f $k))
      Add-Member -InputObject $c -Name $k -Value $val -MemberType NoteProperty
    }
  }
  return $obj
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

$A = Get-RunManifest $Old
$B = Get-RunManifest $New

Write-Host "== RUN DIFF ==" -ForegroundColor Magenta
Write-Host ("Old: {0}" -f $Old)
Write-Host ("New: {0}" -f $New)
Write-Host ("Outcome: {0}  →  {1}" -f $A.outcome,$B.outcome)
Write-Host ("Exit:    {0}  →  {1}" -f $A.exitCode,$B.exitCode)

$keys = 'stdout','warn','stderr','info','verbose','debug'
foreach($k in $keys){
  $a = [int]($A.counts.$k ?? 0)
  $b = [int]($B.counts.$k ?? 0)
  $d = $b - $a
  Write-Host ("{0,-7}: {1,5} → {2,5}   (Δ {3})" -f $k,$a,$b,$d)
}

function Norm([string]$s){ ($s ?? '') -replace '\s+',' ' }
$eOld = if (Test-Path (Join-Path $Old 'stderr.log')) { Get-Content (Join-Path $Old 'stderr.log') } else { @() }
$eNew = if (Test-Path (Join-Path $New 'stderr.log')) { Get-Content (Join-Path $New 'stderr.log') } else { @() }
$setOld = [System.Collections.Generic.HashSet[string]]::new(); foreach($l in $eOld){ [void]$setOld.Add((Norm $l)) }
$setNew = [System.Collections.Generic.HashSet[string]]::new(); foreach($l in $eNew){ [void]$setNew.Add((Norm $l)) }

$added    = $eNew | Where-Object { -not $setOld.Contains((Norm $_)) } | Select-Object -First $Top
$resolved = $eOld | Where-Object { -not $setNew.Contains((Norm $_)) } | Select-Object -First $Top

Write-Host "`nNew error lines (up to $Top):" -ForegroundColor DarkYellow
if ($added)    { $added    | ForEach-Object { " + " + $_ } } else { Write-Host "(none)" }
Write-Host "Resolved error lines (up to $Top):" -ForegroundColor DarkYellow
if ($resolved) { $resolved | ForEach-Object { " - " + $_ } } else { Write-Host "(none)" }