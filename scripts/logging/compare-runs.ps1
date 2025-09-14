#requires -Version 7.0
param([string]$Old,[string]$New,[int]$Top=5)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'

$Root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$Runs = Join-Path $Root 'out\run-logs'

function CountOrZero([string]$p){
  if (Test-Path $p) { (Get-Content $p -ReadCount 2000 | Measure-Object -Line).Lines } else { 0 }
}
function CountsFromDir([string]$dir){
  $m = @{}
  foreach($k in 'stdout','stderr','warn','info','verbose','debug'){ $m[$k] = CountOrZero (Join-Path $dir ("{0}.log" -f $k)) }
  return $m
}
function TryReadJson([string]$path){
  if (Test-Path $path) { try { return (Get-Content -Raw -Path $path | ConvertFrom-Json) } catch { return $null } }
  return $null
}
function GetRunMeta([string]$dir){
  $j = TryReadJson (Join-Path $dir 'run.json')
  $name    = if ($j -and $j.PSObject.Properties['name'])    { $j.name }    else { Split-Path $dir -Leaf }
  $target  = if ($j -and $j.PSObject.Properties['target'])  { $j.target }  else { '(unknown)' }
  $args    = if ($j -and $j.PSObject.Properties['args'])    { $j.args }    else { '' }
  $outcome = if ($j -and $j.PSObject.Properties['outcome']) { $j.outcome } else { '(unknown)' }
  $exit    = if ($j -and $j.PSObject.Properties['exitCode']){ [int]$j.exitCode } else { 0 }
  # 기본은 디렉터리에서 집계, run.json에 정상 숫자 있으면 덮어씀
  $counts = CountsFromDir $dir
  if ($j -and $j.PSObject.Properties['counts']) {
    foreach($k in 'stdout','stderr','warn','info','verbose','debug'){
      $v = $j.counts.PSObject.Properties[$k]?.Value
      if ($null -ne $v -and $v -is [int]) { $counts[$k] = [int]$v }
    }
  }
  [pscustomobject]@{ dir=$dir; name=$name; target=$target; args=$args; outcome=$outcome; exitCode=$exit; counts=$counts }
}
function Pick-Latest2 {
  $dirs = Get-ChildItem -Path $Runs -Directory | Sort-Object LastWriteTime
  if (-not $dirs -or $dirs.Count -eq 0) { throw "No run-logs found." }
  if ($dirs.Count -eq 1) { return @($dirs[0].FullName,$dirs[0].FullName) }
  return @($dirs[$dirs.Count-2].FullName,$dirs[$dirs.Count-1].FullName)
}

if (-not $Old -or -not (Test-Path $Old) -or -not $New -or -not (Test-Path $New)) {
  $pair = Pick-Latest2
  if (-not $Old -or -not (Test-Path $Old)) { $Old = $pair[0] }
  if (-not $New -or -not (Test-Path $New)) { $New = $pair[1] }
}

$runA = GetRunMeta $Old
$runB = GetRunMeta $New

Write-Host "== RUN DIFF ==" -ForegroundColor Magenta
Write-Host ("Old: {0}" -f $runA.dir)
Write-Host ("New: {0}" -f $runB.dir)
Write-Host ("Outcome: {0}  →  {1}" -f $runA.outcome,$runB.outcome)
Write-Host ("Exit:    {0}  →  {1}" -f $runA.exitCode,$runB.exitCode)

$keys = 'stdout','warn','stderr','info','verbose','debug'
foreach($k in $keys){
  $countA = [int]($runA.counts[$k])
  $countB = [int]($runB.counts[$k])
  $delta  = $countB - $countA
  Write-Host ("{0,-7}: {1,5} → {2,5}   (Δ {3})" -f $k,$countA,$countB,$delta)
}

function Norm([string]$s){ ($s ?? '') -replace '\s+',' ' }
$eOld = if (Test-Path (Join-Path $runA.dir 'stderr.log')) { Get-Content (Join-Path $runA.dir 'stderr.log') } else { @() }
$eNew = if (Test-Path (Join-Path $runB.dir 'stderr.log')) { Get-Content (Join-Path $runB.dir 'stderr.log') } else { @() }
$setOld = [System.Collections.Generic.HashSet[string]]::new(); foreach($line in $eOld){ [void]$setOld.Add((Norm $line)) }
$setNew = [System.Collections.Generic.HashSet[string]]::new(); foreach($line in $eNew){ [void]$setNew.Add((Norm $line)) }

$added    = $eNew | Where-Object { -not $setOld.Contains((Norm $_)) } | Select-Object -First $Top
$resolved = $eOld | Where-Object { -not $setNew.Contains((Norm $_)) } | Select-Object -First $Top

Write-Host "`nNew error lines (up to $Top):" -ForegroundColor DarkYellow
if ($added)    { $added    | ForEach-Object { " + " + $_ } } else { Write-Host "(none)" }
Write-Host "Resolved error lines (up to $Top):" -ForegroundColor DarkYellow
if ($resolved) { $resolved | ForEach-Object { " - " + $_ } } else { Write-Host "(none)" }