#requires -Version 7.0
param([string]$Old,[string]$New,[int]$Top=5)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$Root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$Runs = Join-Path $Root 'out\run-logs'
function CountOrZero($p){ if (Test-Path $p) { (Get-Content $p -ReadCount 1000 | Measure-Object -Line).Lines } else { 0 } }
function Pick-Latest2 {
  $dirs = Get-ChildItem -Path $Runs -Directory | Sort-Object LastWriteTime
  if (-not $dirs -or $dirs.Count -eq 0) { throw "No run-logs found." }
  if ($dirs.Count -eq 1) { return @($dirs[0].FullName, $dirs[0].FullName) }
  return @($dirs[$dirs.Count-2].FullName, $dirs[$dirs.Count-1].FullName)
}
if (-not $Old -or -not (Test-Path $Old)) {
  $pair = Pick-Latest2; $Old = $pair[0]; if (-not $New) { $New = $pair[1] }
}
if (-not $New -or -not (Test-Path $New)) {
  $pair = Pick-Latest2; $New = $pair[1]
}

$mOld = Join-Path $Old 'run.json'
$mNew = Join-Path $New 'run.json'
function Read-Man($m,$dir){
  if (Test-Path $m) { return Get-Content -Raw -Path $m | ConvertFrom-Json }
  else {
    $obj = [ordered]@{
      name=(Split-Path $dir -Leaf); target="(unknown)"; args=""; outcome="(unknown)"; exitCode=0;
      counts=@{
        stdout=CountOrZero (Join-Path $dir "stdout.log"); stderr=CountOrZero (Join-Path $dir "stderr.log");
        warn=CountOrZero (Join-Path $dir "warn.log"); info=CountOrZero (Join-Path $dir "info.log");
        verbose=CountOrZero (Join-Path $dir "verbose.log"); debug=CountOrZero (Join-Path $dir "debug.log")
      }
    }
    return ($obj | ConvertTo-Json | ConvertFrom-Json)
  }
}

$A = Read-Man $mOld $Old
$B = Read-Man $mNew $New
Write-Host "== RUN DIFF ==" -ForegroundColor Magenta
Write-Host ("Old: {0}" -f $Old)
Write-Host ("New: {0}" -f $New)
Write-Host ("Outcome: {0}  →  {1}" -f $A.outcome,$B.outcome)
Write-Host ("Exit:    {0}  →  {1}" -f $A.exitCode,$B.exitCode)
$keys = "stdout","warn","stderr","info","verbose","debug"
foreach($k in $keys){
  $a = [int]$A.counts.$k; $b=[int]$B.counts.$k; $d=$b-$a
  Write-Host ("{0,-7}: {1,5} → {2,5}   (Δ {3})" -f $k,$a,$b,$d)
}
function Norm([string]$s){ ($s ?? "") -replace "\s+"," " }
$eOld = if (Test-Path (Join-Path $Old "stderr.log")) { Get-Content (Join-Path $Old "stderr.log") } else { @() }
$eNew = if (Test-Path (Join-Path $New "stderr.log")) { Get-Content (Join-Path $New "stderr.log") } else { @() }
$setOld = [System.Collections.Generic.HashSet[string]]::new(); foreach($l in $eOld){ [void]$setOld.Add((Norm $l)) }
$setNew = [System.Collections.Generic.HashSet[string]]::new(); foreach($l in $eNew){ [void]$setNew.Add((Norm $l)) }
$added    = $eNew | Where-Object { -not $setOld.Contains((Norm $_)) } | Select-Object -First $Top
$resolved = $eOld | Where-Object { -not $setNew.Contains((Norm $_)) } | Select-Object -First $Top
Write-Host "`nNew error lines (up to $Top):" -ForegroundColor DarkYellow
if ($added) { $added | ForEach-Object { " + " + $_ } } else { Write-Host "(none)" }
Write-Host "Resolved error lines (up to $Top):" -ForegroundColor DarkYellow
if ($resolved) { $resolved | ForEach-Object { " - " + $_ } } else { Write-Host "(none)" }