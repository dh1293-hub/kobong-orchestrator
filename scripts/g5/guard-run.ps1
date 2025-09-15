#requires -Version 7.0
param([switch]$ConfirmApply,[string]$Root)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

# APPLY IN SHELL
# guard-run.ps1 — safe runner (generated: 2025-09-15 03:20:10 +09:00)
#requires -Version 7.0
param(
  [Parameter(Mandatory)][string]$Script,
  [string[]]$Args,
  [string]$Root,
  [string]$WorkingDirectory,
  [switch]$NewWindow
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
function Get-RepoRoot{ if($Root -and (Test-Path $Root)){return (Resolve-Path $Root).Path}; try{$r=git rev-parse --show-toplevel 2>$null;if($r){return $r}}catch{}; return (Get-Location).Path }
function To-Array($x){ if($null -eq $x){@()} elseif($x -is [Array]){$x}else{@($x)} }

$Repo = Get-RepoRoot
if(-not $WorkingDirectory){ $WorkingDirectory = $Repo }
Set-Location $WorkingDirectory

$target = $Script
if(-not (Test-Path $target)){
  $t1 = Join-Path $WorkingDirectory $Script
  $t2 = Join-Path $Repo $Script
  if(Test-Path $t1){ $target=$t1 } elseif(Test-Path $t2){ $target=$t2 }
}
if(-not (Test-Path $target)){ Write-Host "[FAIL] Script not found: $Script" -ForegroundColor Red; return }

if($NewWindow){
  $pwsh = if (Test-Path "$env:ProgramFiles\PowerShell\7\pwsh.exe") {"$env:ProgramFiles\PowerShell\7\pwsh.exe"} else {'pwsh'}
  Start-Process -FilePath $pwsh -ArgumentList @('-NoExit','-NoProfile','-ExecutionPolicy','Bypass','-WorkingDirectory',$WorkingDirectory,'-File',$target) + (To-Array $Args) | Out-Null
  Write-Host "[OK] Launched new PS7 window → $target" -ForegroundColor Green
  return
}

try{
  Write-Host ("[RUN] {0} {1}" -f $target, ((To-Array $Args) -join ' '))
  & $target @Args
  Write-Host "[OK] Done." -ForegroundColor Green
} catch {
  Write-Host "[FAIL] $($_.Exception.Message)" -ForegroundColor Red
}
return