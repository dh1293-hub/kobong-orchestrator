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
  $m = TryReadJson (Join-Path $dir 'run.json')
  $name    = if ($m -and $m.PSObject.Properties['name'])    { $m.name }    else { Split-Path $dir -Leaf }
  $target  = if ($m -and $m.PSObject.Properties['target'])  { $m.target }  else { '(unknown)' }
  $args    = if ($m -and $m.PSObject.Properties['args'])    { $m.args }    else { '' }
  $outcome = if ($m -and $m.PSObject.Properties['outcome']) { $m.outcome } else { '(unknown)' }
  $exit    = if ($m -and $m.PSObject.Properties['exitCode']){ [int]$m.exitCode } else { 0 }
  # counts: 기본은 디렉터리에서 생성, run.json에 정상 숫자 있으면 덮어씀
  $counts = CountsFromDir $dir
  if ($m -and $m.PSObject.Properties['counts']) {
    foreach($k in 'stdout','stderr','warn','info','verbose','debug'){
      $v = $m.counts.PSObject.Properties[$k]?.Value
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

$A = GetRunMeta $Old
$B = GetRunMeta $New

Write-Host "== RUN DIFF ==" -ForegroundColor Magenta
Write-Host ("Old: {0}" -f $A.dir)
Write-Host ("New: {0}" -f $B.dir)
Write-Host ("Outcome: {0}  →  {1}" -f $A.outcome,$B.outcome)
Write-Host ("Exit:    {0}  →  {1}" -f $A.exitCode,$B.exitCode)

$keys = 'stdout','warn','stderr','info','verbose','debug'
foreach($k in $keys){
  # ← 핵심: counts 속성이 없거나 null이어도, 항상 디렉터리에서 안전 폴백
  $a = if ($A.PSObject.Properties['counts'] -and $A.counts -is [hashtable] -and $A.counts.ContainsKey($k)) {
    [int]$A.counts[$k]
  } else {
    CountOrZero (Join-Path $A.dir ("{0}.log" -f $k))
  }
  $b = if ($B.PSObject.Properties['counts'] -and $B.counts -is [hashtable] -and $B.counts.ContainsKey($k)) {
    [int]$B.counts[$k]
  } else {
    CountOrZero (Join-Path $B.dir ("{0}.log" -f $k))
  }
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