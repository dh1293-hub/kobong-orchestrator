#requires -Version 7.0
# make-g5-context.ps1 — 안정판 v1.1.1 (no-HMAC)
param([ValidateSet('DEV','MOCK')][string]$Mode='DEV')
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'

$ports=@{ DEV=@{ak7=5181;gh=5182;orch=5183}; MOCK=@{ak7=5191;gh=5199;orch=5193} }[$Mode]
function Get-Health($name,$port,$prefix){
  try{ $u="http://localhost:$port/api/$prefix/health"
       $r=Invoke-RestMethod -Uri $u -TimeoutSec 3 -ErrorAction Stop
       [pscustomobject]@{name=$name;port=$port;ok=($r.ok -eq $true);code=($r.code ?? 0);url=$u} }
  catch{ [pscustomobject]@{name=$name;port=$port;ok=$false;code=1;url=$u;error=$_.Exception.Message} }
}
$repo=(git rev-parse --show-toplevel 2>$null) ?? (Get-Location).Path
$repo=(Resolve-Path $repo).Path
$ctxDir=Join-Path $repo '.kobong/context'; New-Item -ItemType Directory -Force -Path $ctxDir | Out-Null

$health=@( Get-Health 'AK7' $ports.ak7 'ak7'
           Get-Health 'GHMON' $ports.gh 'ghmon'
           Get-Health 'ORCHMON' $ports.orch 'orchmon' )

$SSOT = Join-Path $repo '계획서.md'
$Docs = Join-Path $repo '.kobong/DocsManifest.json'
$Inv  = Join-Path $repo '_inventory/inventory.json'
$Last = (git log --oneline -n 1 2>$null)

$summary=[ordered]@{
  version='g5-context.v1'; when=(Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
  mode=$Mode; health=$health
  ssot_exists=(Test-Path $SSOT); docsmanifest_exists=(Test-Path $Docs); inventory_exists=(Test-Path $Inv)
  last_commit=$Last
}

$ctxJson=Join-Path $ctxDir 'context-latest.json'
$ctxTxt =Join-Path $ctxDir 'context-latest.txt'
$lines=@()
$lines+="GPT-5 CONTEXT · Mode=$($summary.mode) · $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$lines+="Health: " + ($summary.health | % { "$($_.name):$($_.port)→" + ($(if ($_.ok){'OK'}else{'FAIL'})) } ) -join " | "
if(Test-Path $SSOT){$lines+="SSOT present: 계획서.md"}
if(Test-Path $Docs){$lines+="DocsManifest present: .kobong/DocsManifest.json"}
if(Test-Path $Inv){$lines+="_inventory present: inventory.json"}
if($Last){$lines+="Last Commit: $Last"}

$summary | ConvertTo-Json -Depth 6 | Out-File $ctxJson
$lines   | Out-File $ctxTxt

# KLC 1행(최소)
$klc=Join-Path $repo '.kobong/logs/api.log'; New-Item -ItemType Directory -Force -Path (Split-Path $klc) | Out-Null
$canon = (Get-Content $ctxTxt -Raw); if([string]::IsNullOrEmpty($canon)){$canon='context-empty'}
$sha = [Convert]::ToHexString([Security.Cryptography.SHA256]::Create().ComputeHash([Text.Encoding]::UTF8.GetBytes($canon))).ToLower()
$emit=[ordered]@{
  version='1.3'; timestamp=(Get-Date).ToString('o'); traceId=[guid]::NewGuid().Guid
  message='make-g5-context'; outcome='SUCCESS'; exitCode=0; env=$Mode; mode='READONLY'; service='ak7-orchmon-ghmon'
  hash=$sha; prevHash=''; hashAlgo='sha256'; canonAlgo='text'; durationMs=0; anchorHash=$sha
}
$emit | ConvertTo-Json -Compress | Add-Content -Path $klc
Write-Host "Context written → $ctxTxt"

