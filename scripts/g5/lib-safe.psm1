# NO-SHELL
# lib-safe.psm1 — common safe utilities (PS7)
#requires -Version 7.0
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'

function Confirm-PS7 {
  if ($PSVersionTable.PSVersion.Major -lt 7) {
    throw "PS7 required. Current: $($PSVersionTable.PSVersion)"
  }
}
function Get-RepoRoot([string]$Root){
  if ($Root -and (Test-Path $Root)) { return (Resolve-Path $Root).Path }
  try { $r = git rev-parse --show-toplevel 2>$null; if ($r) { return $r } } catch {}
  return (Get-Location).Path
}
function Write-Atomic([string]$Path,[string]$Content){
  $dir=Split-Path $Path; New-Item -ItemType Directory -Force -Path $dir | Out-Null
  $ts=Get-Date -Format 'yyyyMMdd-HHmmss'
  if(Test-Path $Path){ Copy-Item $Path "$Path.bak-$ts" -Force }
  $tmp=Join-Path $dir ('.'+[IO.Path]::GetFileName($Path)+'.tmp')
  [IO.File]::WriteAllText($tmp,$Content,[Text.UTF8Encoding]::new($false))
  Move-Item -Force $tmp $Path
}
function To-Array($x){
  if ($null -eq $x) { return @() }
  if ($x -is [System.Array]) { return $x }
  return @($x)
}
function Has-Prop($o,[string]$name){ try { return ($o -and $o.PSObject -and $o.PSObject.Properties[$name]) } catch { $false } }
function Get-Prop($o,[string]$name,$default=$null){
  if (Has-Prop $o $name) { return $o.PSObject.Properties[$name].Value }
  return $default
}
function Write-LogRecord([string]$Repo,[string]$Level,[string]$Outcome,[string]$Action,[string]$Msg,[string]$ErrCode=''){
  try{
    $log = Join-Path $Repo 'logs/apply-log.jsonl'
    New-Item -ItemType Directory -Force -Path (Split-Path $log) | Out-Null
    $rec = @{
      timestamp = (Get-Date).ToString('o')
      level     = $Level
      traceId   = [guid]::NewGuid().ToString()
      module    = 'g5'
      action    = $Action
      outcome   = $Outcome
      errorCode = $ErrCode
      message   = $Msg
    } | ConvertTo-Json -Compress
    Add-Content -Path $log -Value $rec
  } catch {}
}
Export-ModuleMember -Function Confirm-PS7,Get-RepoRoot,Write-Atomic,To-Array,Has-Prop,Get-Prop,Write-LogRecord