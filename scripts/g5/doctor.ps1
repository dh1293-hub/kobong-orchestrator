#requires -Version 7.0
param([switch]$ConfirmApply,[string]$Root)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

# APPLY IN SHELL
# doctor.ps1 — no pager hang (generated: 2025-09-15 03:28:55 +09:00)
#requires -Version 7.0
param([string]$Root)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'

function Get-RepoRoot {
  if ($Root -and (Test-Path $Root)) { return (Resolve-Path $Root).Path }
  try { $r = git rev-parse --show-toplevel 2>$null; if ($r) { return $r } } catch {}
  return (Get-Location).Path
}
function To-Array($x){ if($null -eq $x){@()} elseif($x -is [Array]){$x}else{@($x)} }

# use $arg (NOT $args) and disable pagers
function Try-Ver($name,$cmd,$arg){
  try{
    $env:GH_PAGER=''; $env:PAGER=''; $env:GIT_PAGER=''; $env:GH_PROMPT_DISABLED='1'; $env:GH_NO_UPDATE_NOTIFIER='1'
    $v = if([string]::IsNullOrWhiteSpace($arg)){ & $cmd 2>$null } else { & $cmd $arg 2>$null }
    "{0,-6}: {1}" -f $name, (($v -split "`n")|Select-Object -First 1)
  }catch{
    "{0,-6}: <not found>" -f $name
  }
}

$Repo = Get-RepoRoot
Set-Location $Repo
Write-Host ("KOBONG DOCTOR @ {0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')) -ForegroundColor Cyan
Write-Host ("Repo: {0}" -f $Repo) -ForegroundColor DarkGray
Write-Host ("PS7 : {0}" -f $PSVersionTable.PSVersion)
Write-Host (Try-Ver 'git'  'git'  '--version')
Write-Host (Try-Ver 'gh'   'gh'   '--version')
Write-Host (Try-Ver 'node' 'node' '--version')
Write-Host (Try-Ver 'pnpm' 'pnpm' '--version')

$lockNames = @('.gpt5.lock','.gpt5.guard.lock')
$lockPaths = $lockNames | ForEach-Object { Join-Path $Repo $_ }
$locks     = @($lockPaths | Where-Object { Test-Path $_ })
if (@($locks).Count -gt 0) {
  Write-Host "[WARN] Locks exist:" -ForegroundColor Yellow
  $locks | ForEach-Object { Write-Host ("  - {0}" -f $_) }
} else {
  Write-Host "[OK] No locks" -ForegroundColor Green
}

$need = @('scripts/g5/monitor-status.ps1','scripts/g5/monitor-logs.ps1','scripts/g5/error-trend.ps1','scripts/g5/generate-badges.ps1','scripts/view-ci-summary.ps1','scripts/g5/guard-run.ps1')
$miss = @(); foreach($f in $need){ if(-not (Test-Path (Join-Path $Repo $f))){ $miss += $f } }
if (@($miss).Count -gt 0){
  Write-Host "[WARN] Missing:" -ForegroundColor Yellow
  $miss | ForEach-Object { Write-Host ("  - {0}" -f $_) }
} else {
  Write-Host "[OK] Required scripts present" -ForegroundColor Green
}
# keep shell open
return