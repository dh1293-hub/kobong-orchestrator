######## APPLY IN SHELL
#requires -Version 7.0
param(
  [string]$RepoRoot = 'D:\ChatGPT5_AI_Link\dosc\kobong-orchestrator-VIP',
  [Parameter(Mandatory=$true)][string]$Doc,  # 등록할 파일 경로(절대/상대 OK)
  [switch]$AsFile                           # DocsManifest를 file 스키마로 저장하고 싶을 때 사용
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'

# resolve
$RepoRoot = (Resolve-Path $RepoRoot).Path
$Full = (Resolve-Path $Doc).Path
if ($Full -notlike "$RepoRoot*") { throw "Repo 루트 밖 경로 금지: $Full" }
$Rel = $Full.Substring($RepoRoot.Length).TrimStart('\','/').Replace('\','/')
$Leaf = Split-Path -Leaf $Rel

# paths
$DocsMf = Join-Path $RepoRoot ".kobong\DocsManifest.json"
$RbFile = Join-Path $RepoRoot "Rollbackfile.json"

# io helpers
function ReadJson($p){ if(Test-Path $p){ try {Get-Content -Raw $p|ConvertFrom-Json}catch{$null}}}
function SaveJson($p,$o){
  New-Item -ItemType Directory -Force -Path (Split-Path $p) | Out-Null
  $bak = (Test-Path $p) ? ($p + ".bak-" + (Get-Date -Format 'yyyyMMdd-HHmmss')) : $null
  if ($bak){ Copy-Item $p $bak -Force }
  $tmp="$p.tmp"; ($o|ConvertTo-Json -Depth 10)|Out-File $tmp -Encoding utf8; Move-Item $tmp $p -Force
}

# Rollbackfile: targets + forbidden (중복 제거 후 추가)
$rb = ReadJson $RbFile; if(-not $rb){ $rb=[pscustomobject]@{version=1;targets=@();forbidden=@()} }
foreach($k in 'targets','forbidden'){
  if ($rb.PSObject.Properties[$k] -eq $null){ $rb | Add-Member -Name $k -Value @() -MemberType NoteProperty }
  $rb.$k = @($rb.$k | Where-Object { $_ -ne $Rel })
  $rb.$k += $Rel
}

# DocsManifest: 혼합 스키마(path/file/string) 지원
$mf = ReadJson $DocsMf; if(-not $mf){ $mf=[pscustomobject]@{version=1;docs=@()} }
if ($mf.PSObject.Properties['docs'] -eq $null){ $mf | Add-Member -Name docs -Value @() -MemberType NoteProperty }
function GetKey($d){
  if ($d -is [string]) { return $d.Replace('\','/') }
  $n=$d.PSObject.Properties.Name
  if ($n -contains 'path') { return $d.path.Replace('\','/') }
  elseif ($n -contains 'file') { return (".kobong/$($d.file)").Replace('\','/') }
  else { '' }
}
$mf.docs = @($mf.docs | Where-Object { (GetKey $_) -ne $Rel })

# shape 선택: 명시(--AsFile) > 기존 다수결(file 우선) > 기본(path)
$hasFile = ($mf.docs | Where-Object { $_ -isnot [string] -and $_.PSObject.Properties.Name -contains 'file' } | Measure-Object).Count
$shape   = if ($AsFile){'file'} elseif($hasFile -gt 0){'file'} else {'path'}

if ($shape -eq 'file') {
  $mf.docs += [pscustomobject]@{ file=$Leaf; status='register-only'; title=$Leaf; tags=@('policy') }
} else {
  $mf.docs += [pscustomobject]@{ path=$Rel; status='register-only'; title=$Leaf; tags=@('policy') }
}

# save
SaveJson $RbFile $rb
SaveJson $DocsMf $mf
Write-Host "[OK] 등록됨 → targets+forbidden+DocsManifest : $Rel (shape=$shape)"
