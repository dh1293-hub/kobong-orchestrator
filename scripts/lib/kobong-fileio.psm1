#requires -Version 7.0
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-AtomicTempPath {
  param([Parameter(Mandatory)][string]$DestPath)
  $dir = Split-Path -Parent $DestPath
  if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
  return (Join-Path $dir ('.' + (Split-Path -Leaf $DestPath) + '.tmp'))
}

function Write-AtomicUtf8 {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$Path,
    [Parameter(Mandatory)][string]$Content,
    [string]$Module='scripts',
    [string]$Action='write-atomic'
  )
  $sw=[Diagnostics.Stopwatch]::StartNew()
  $tmp = Get-AtomicTempPath -DestPath $Path
  $utf8 = New-Object System.Text.UTF8Encoding($false)
  try {
    [System.IO.File]::WriteAllText($tmp, $Content, $utf8)
    if (Test-Path $Path) { Copy-Item -LiteralPath $Path -Destination ($Path + '.bak-' + (Get-Date -Format 'yyyyMMdd-HHmmss')) -Force }
    Move-Item -LiteralPath $tmp -Destination $Path -Force
    try {
      $rec=@{timestamp=(Get-Date).ToString('o');level='INFO';module=$Module;action=$Action;outcome='SUCCESS';message=("wrote:"+$Path)} | ConvertTo-Json -Compress
      $repo=(git rev-parse --show-toplevel 2>$null); if($repo){ $log=Join-Path $repo 'logs\apply-log.jsonl'; New-Item -ItemType Directory -Force -Path (Split-Path $log) | Out-Null; Add-Content -Path $log -Value $rec }
    } catch {}
  } catch {
    try {
      $rec=@{timestamp=(Get-Date).ToString('o');level='ERROR';module=$Module;action=$Action;outcome='FAILURE';errorCode='LOGIC';message=("write-failed:"+$Path+" "+$_.Exception.Message)} | ConvertTo-Json -Compress
      $repo=(git rev-parse --show-toplevel 2>$null); if($repo){ $log=Join-Path $repo 'logs\apply-log.jsonl'; New-Item -ItemType Directory -Force -Path (Split-Path $log) | Out-Null; Add-Content -Path $log -Value $rec }
    } catch {}
    throw
  } finally { $sw.Stop() }
}