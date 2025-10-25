# Kobong-Orchestrator-VIP — 전수 인벤토리 수집 (PS7) v1.5 Minimal Safe
# 목적: "파일명과 경로"만 수집 (콘텐츠 미접근, 파일 손상 위험 0)
#inventory.ps1
#requires -Version 7.0
[CmdletBinding()]
param(
  [switch]$Strict  # permanent 누락 시 실패
)

Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['*:Encoding']='utf8'

# ---- repo root 탐색 (.git 없어도 동작) ----
function Get-RepoRoot {
  $d = Resolve-Path $PSScriptRoot
  for($i=0;$i -lt 6;$i++){
    if (Test-Path (Join-Path $d '.github') -or Test-Path (Join-Path $d '.kobong')) { return $d }
    $p = Split-Path -Parent $d
    if ($p -eq $d) { break }
    $d = $p
  }
  return (Resolve-Path (Join-Path $PSScriptRoot '..' '..'))  # scripts/g5 기준 2단계 상위
}

$ROOT = Get-RepoRoot
Set-Location $ROOT
$INV_DIR = Join-Path $ROOT '_inventory'
New-Item -ItemType Directory -Force -Path $INV_DIR | Out-Null

# ---- DocsManifest 로드 & 기본 검증 ----
$MANIFEST_FILE = Join-Path $ROOT '.kobong/DocsManifest.json'
if (-not (Test-Path $MANIFEST_FILE)) { throw "DocsManifest not found: $MANIFEST_FILE" }
$Manifest = Get-Content $MANIFEST_FILE -Raw | ConvertFrom-Json
if (-not ($Manifest -is [System.Collections.IEnumerable])) { throw "DocsManifest must be an array" }

# ---- 해시 스냅샷 생성 ----
$Ignore = @(
  '\.git\\', '^_inventory\\', 'node_modules\\', '\.cache\\', '\.vs\\', '\.vscode\\',
  'logs\\', '\.DS_Store$', '\.idea\\', '\.pytest_cache\\', '\.venv\\', '__pycache__\\'
)
function Should-Skip([string]$rel){
  foreach($pat in $Ignore){ if ($rel -ireplace '/','\' -match $pat){ return $true } }
  return $false
}

$files = Get-ChildItem -File -Recurse -Force | ForEach-Object {
  $rel = [IO.Path]::GetRelativePath($ROOT, $_.FullName)
  if (-not (Should-Skip $rel)) { $_ }
}

$rows = foreach($f in $files){
  $h = Get-FileHash -Algorithm SHA256 -LiteralPath $f.FullName
  [pscustomobject]@{
    path          = [IO.Path]::GetRelativePath($ROOT, $f.FullName).Replace('\','/')
    sha256        = $h.Hash.ToLowerInvariant()
    size          = $f.Length
    lastWriteTime = $f.LastWriteTimeUtc.ToString('o')
  }
}

$CSV = Join-Path $INV_DIR 'hashes.csv'
$rows | Sort-Object path | Export-Csv -NoTypeInformation -Encoding UTF8 -Path $CSV

# ---- 이전 스냅샷과 비교(있으면) ----
$CHG = Join-Path $INV_DIR 'changes.txt'
if (Test-Path $CSV){
  $prev = @{}
  $old = if (Test-Path $CSV) { Import-Csv $CSV } else { @() }  # 첫 실행이면 빈값
}
# 이전 파일이 이번에 덮였으므로, 비교를 위해 메모리 보관
$prevRows = $rows | Group-Object path -AsHashTable

$oldRows = @{}
if (Test-Path $CSV){
  try { $oldRows = (Import-Csv $CSV) | Group-Object path -AsHashTable } catch { $oldRows=@{} }
}

$added   = @()
$removed = @()
$changed = @()

# oldRows vs prevRows (이전→현재)
foreach($k in $oldRows.Keys){
  if (-not $prevRows.ContainsKey($k)){ $removed += $k; continue }
  if ($oldRows[$k].sha256 -ne $prevRows[$k].sha256){ $changed += $k }
}
foreach($k in $prevRows.Keys){
  if (-not $oldRows.ContainsKey($k)){ $added += $k }
}

"ADDED   `t{0}"   -f ($added  -join "`n")   | Out-File $CHG -Encoding utf8
"CHANGED `t{0}"   -f ($changed-join "`n")   | Out-File $CHG -Append -Encoding utf8
"REMOVED `t{0}"   -f ($removed-join "`n")   | Out-File $CHG -Append -Encoding utf8

# ---- Manifest 정책 검증 ----
$viol = @()
foreach($m in $Manifest){
  $p = "$($m.path)".Replace('/','\')
  $full = Join-Path $ROOT $p
  $exists = Test-Path $full
  if ($m.retention -eq 'permanent' -and -not $exists){
    $viol += "permanent missing: $($m.path)"
  }
}
# 정책 파일 존재 보장 (Manifest가 가리키는 보안 정책)
$policy = ($Manifest | Where-Object { $_.path -match '\.kobong/policy/.+\.ya?ml$' })
foreach($pp in $policy){
  $full = Join-Path $ROOT ($pp.path)
  if (-not (Test-Path $full)){ $viol += "policy missing: $($pp.path)" }
}

if ($Strict -and $viol.Count){
  $viol -join "`n" | Out-Host
  throw "Manifest violations: $($viol.Count)"
}

Write-Host "INVENTORY OK"
