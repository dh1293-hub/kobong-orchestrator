# APPLY IN SHELL
#requires -Version 7.0
param([switch]$ConfirmApply,[string]$Root)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply=$true }

$RepoRoot = if($Root){$Root}else{ (git rev-parse --show-toplevel 2>$null) ?? (Get-Location).Path }
$Webui    = Join-Path $RepoRoot 'webui'
$Src      = Join-Path $Webui 'src'
$MainTsx  = Join-Path $Src 'main.tsx'
$LockFile = Join-Path $RepoRoot '.gpt5.lock'

if (Test-Path $LockFile) { $age=(New-TimeSpan -Start (Get-Item $LockFile).LastWriteTime -End (Get-Date)).TotalMinutes; if ($age -gt 5){ Remove-Item -Force $LockFile } else { Write-Error 'CONFLICT: .gpt5.lock exists (recent).'; exit 11 } }
"locked $(Get-Date -Format o)" | Out-File $LockFile -NoNewline

function Save-Atomic([string]$Path,[string]$Content){
  $dir=Split-Path $Path; New-Item -ItemType Directory -Force -Path $dir | Out-Null
  $bak = if(Test-Path $Path){"$Path.bak-$(Get-Date -Format yyyyMMdd-HHmmss)"}else{$null}
  if($bak){ Copy-Item $Path $bak -Force }
  $tmp = Join-Path $dir ".$([IO.Path]::GetFileName($Path)).tmp"
  $Content | Out-File -FilePath $tmp -Encoding utf8 -NoNewline
  Move-Item -Force $tmp $Path
  return $bak
}

try{
  if (!(Test-Path $MainTsx)) { throw "not found: $MainTsx" }
  $cleanMain = @(
    'import React from "react";'
    'import ReactDOM from "react-dom/client";'
    'import "./index.css";'
    'import WebGUIGithubUI from "./ui/Web-GUI-Github-v0.1";'
    ''
    'function App(){'
    '  return <WebGUIGithubUI />;'
    '}'
    ''
    'const root = document.getElementById("root");'
    'if (!root) { const d=document.createElement("div"); d.id="root"; document.body.appendChild(d); }'
    'ReactDOM.createRoot(document.getElementById("root")!).render('
    '  <React.StrictMode><App /></React.StrictMode>'
    ');'
  ) -join "`n"

  if (-not $ConfirmApply){
    Write-Host "[DRYRUN] Would replace main.tsx with production-safe entry (no DevOverlay/smoke)."
    exit 0
  }

  $bak = Save-Atomic $MainTsx $cleanMain

  $log = Join-Path $RepoRoot 'logs\apply-log.jsonl'
  New-Item -ItemType Directory -Force -Path (Split-Path $log) | Out-Null
  $rec=@{timestamp=(Get-Date).ToString('o');level='INFO';traceId=[guid]::NewGuid().ToString();module='webui-prod';action='strip-dev-guards';outcome='SUCCESS';message="main.tsx replaced; backup=$(Split-Path -Leaf $bak)"} | ConvertTo-Json -Compress
  Add-Content -Path $log -Value $rec

  Write-Host "[OK] main.tsx 정리 완료. backup: $(Split-Path -Leaf $bak)"
} catch {
  Write-Error $_.Exception.Message
  exit 13
} finally{
  Remove-Item -Force $LockFile -ErrorAction SilentlyContinue
}