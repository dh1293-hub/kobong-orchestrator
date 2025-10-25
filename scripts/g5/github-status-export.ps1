# APPLY IN SHELL
# scripts/g5/github-status-export.ps1  (v0.3.0 — adds `recent`)
#requires -Version 7.0
param([string]$OutFile)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'

function Get-RepoRoot { try { (git rev-parse --show-toplevel 2>$null) } catch { (Get-Location).Path } }
function Parse-OwnerRepo {
  $url = (git remote get-url origin 2>$null)
  if (-not $url) { throw "git origin remote not found" }
  if ($url -match 'github\.com[:/](?<owner>[^/]+)/(?<name>[^/.]+)') { return @{Owner=$Matches.owner; Repo=$Matches.name} }
  throw "cannot parse owner/repo from: $url"
}
function Get-DefaultBranch {
  $ref = (& git symbolic-ref refs/remotes/origin/HEAD 2>$null)
  if ($LASTEXITCODE -eq 0 -and $ref -match 'refs/remotes/origin/(.+)$') { return $Matches[1] }
  return 'main'
}
function Has-GhAuth {
  $gh=(Get-Command gh -ErrorAction SilentlyContinue)
  if (-not $gh){ return $false }
  try { & $gh.Source auth status 2>$null | Out-Null; return ($LASTEXITCODE -eq 0) } catch { return $false }
}
function Invoke-GHApi([string]$Method,[string]$Path){
  $gh=(Get-Command gh -ErrorAction SilentlyContinue)
  if (-not $gh){ throw 'gh not found' }
  $args=@('api','-X',$Method,'-H','Accept: application/vnd.github+json', $Path)
  $out=& $gh.Source @args
  if ($LASTEXITCODE -ne 0){ throw "gh api failed: $Path" }
  if ($out){ return $out | ConvertFrom-Json } else { return $null }
}
function Invoke-REST([string]$Method,[string]$Path){
  $tok=$null; if ($env:GITHUB_TOKEN){$tok=$env:GITHUB_TOKEN} elseif($env:GH_TOKEN){$tok=$env:GH_TOKEN} elseif($env:GITHUB_PAT){$tok=$env:GITHUB_PAT}
  if (-not $tok){ throw 'Missing GitHub token' }
  $uri='https://api.github.com'+$Path
  $hdr=@{ Authorization='Bearer '+$tok; 'User-Agent'='kobong-monitor-export'; Accept='application/vnd.github+json' }
  return Invoke-RestMethod -Method $Method -Uri $uri -Headers $hdr -ErrorAction Stop
}
function GitHub-Get([string]$Path){
  try {
    if ($env:GITHUB_TOKEN -or $env:GH_TOKEN -or $env:GITHUB_PAT){ return Invoke-REST -Method 'GET' -Path $Path }
  } catch { $restErr=$_.Exception.Message }
  if (Has-GhAuth){ return Invoke-GHApi -Method 'GET' -Path $Path }
  if ($restErr){ throw "REST failed: $restErr; and gh not available" }
  throw "No auth available (token or gh)"
}
function To-Date($s){ if (-not $s){ return $null } try { [datetime]::Parse($s) } catch { $null } }

$RepoRoot = Get-RepoRoot
if (-not $OutFile) { $OutFile = Join-Path (Join-Path $RepoRoot 'public') 'data\gh-monitor.json' }

$or   = Parse-OwnerRepo
$base = Get-DefaultBranch
$owner=$or.Owner; $repo=$or.Repo

$prsOpen=@(); $prsClosed=@()
try { $tmp = GitHub-Get "/repos/$owner/$repo/pulls?state=open&per_page=20";   if ($tmp){ $prsOpen   = @($tmp) } } catch { }
try { $tmp = GitHub-Get "/repos/$owner/$repo/pulls?state=closed&per_page=20"; if ($tmp){ $prsClosed = @($tmp) } } catch { }
$prs=@(); $prs += $prsOpen; $prs += $prsClosed

$items=@()
foreach($p in $prs){
  if (-not $p){ continue }
  $labels=@(); if ($p.labels){ $labels = $p.labels | ForEach-Object { $_.name } }
  $state = if ($p.merged_at){ 'merged' } elseif($p.state){ $p.state } else { 'unknown' }
  $items += [pscustomobject]@{
    number     = $p.number
    state      = $state
    merged_at  = $p.merged_at
    created_at = $p.created_at
    head       = $p.head.ref
    base       = $p.base.ref
    title      = $p.title
    labels     = $labels
    url        = $p.html_url
    isSynthetic= ($labels -contains 'heartbeat' -or ($p.head.ref -like 'synthetic/*') -or ($p.title -like '*heartbeat*'))
  }
}
$map = $items | Sort-Object -Property created_at -Descending
$latestSynth = $null; if ($map){ $latestSynth = $map | Where-Object { $_.isSynthetic } | Select-Object -First 1 }
$openCount = 0; if ($map){ $openCount = ($map | Where-Object { $_.state -eq 'open' }).Count }
$merged24 = 0; if ($map){
  $merged24 = ($map | Where-Object { $_.state -eq 'merged' -and (To-Date $_.merged_at) -gt (Get-Date).AddHours(-24) }).Count
}
$recent = $map | Select-Object -First 8  # ← 새로 추가(필요시 더 늘릴 수 있음)

$result = [pscustomobject]@{
  repo      = "$owner/$repo"
  base      = $base
  timestamp = (Get-Date).ToString('o')
  totals    = @{ open = $openCount; merged_24h = $merged24 }
  latest    = $latestSynth
  recent    = $recent
}

$dir = Split-Path -Parent $OutFile
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
$tmp = "$OutFile.tmp"
$result | ConvertTo-Json -Depth 6 | Out-File -LiteralPath $tmp -Encoding utf8 -NoNewline
Move-Item -LiteralPath $tmp -Destination $OutFile -Force
Write-Host "[OK] exported → $OutFile"