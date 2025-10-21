#requires -Version 7.0
# update-docs-and-inventory.ps1 — 안정판 v1.1.1
param([string]$Label='KEEP')
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'

$Root=(git rev-parse --show-toplevel 2>$null) ?? (Get-Location).Path
$Root=(Resolve-Path $Root).Path
$invD=Join-Path $Root '_inventory'; New-Item -ItemType Directory -Force -Path $invD | Out-Null
$csv =Join-Path $invD 'inventory.csv'
$json=Join-Path $invD 'inventory.json'
$hash=Join-Path $invD 'inventory_hashes.csv'

$items=Get-ChildItem -Path $Root -Recurse -File -ErrorAction SilentlyContinue |
  ? { $_.FullName -notmatch '\\\.git\\|\\_inventory\\|\\node_modules\\|\\\.rollbacks\\' } |
  Select-Object @{n='path';e={$_.FullName.Substring($Root.Length+1)}},
                Length, LastWriteTimeUtc

$items | ConvertTo-Json -Depth 5 | Out-File $json
$items | Export-Csv -Path $csv -NoTypeInformation -Encoding UTF8

# 해시(선택)
$hashLines=@()
foreach($it in $items){ try{
  $p=Join-Path $Root $it.path
  $h=(Get-FileHash -Algorithm SHA256 -LiteralPath $p -ErrorAction SilentlyContinue).Hash
  if($h){ $hashLines += ('"{0}",{1},{2},sha256:{3}' -f $it.path,$it.Length,([int][double]::Parse((Get-Date $it.LastWriteTimeUtc -Format 'yyyyMMddHHmmss'))),$h) }
}catch{} }
if($hashLines){ $hashLines | Out-File $hash }

# KLC 1행
$klc=Join-Path $Root '.kobong/logs/api.log'; New-Item -ItemType Directory -Force -Path (Split-Path $klc) | Out-Null
$canon = (Get-Content $json -Raw); if([string]::IsNullOrEmpty($canon)){$canon='[]'}
$sha=[Convert]::ToHexString([Security.Cryptography.SHA256]::Create().ComputeHash([Text.Encoding]::UTF8.GetBytes($canon))).ToLower()
$emit=[ordered]@{
  version='1.3'; timestamp=(Get-Date).ToString('o'); traceId=[guid]::NewGuid().Guid
  message='update-docs-inventory'; outcome='SUCCESS'; exitCode=0; env='DEV'; mode='APPLY'; service='ak7'
  hash=$sha; prevHash=''; hashAlgo='sha256'; canonAlgo='json'; durationMs=0; anchorHash=$sha
}
$emit | ConvertTo-Json -Compress | Add-Content -Path $klc
Write-Host "Inventory refreshed → $invD"
