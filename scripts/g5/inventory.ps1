# Kobong-Orchestrator-VIP — 전수 인벤토리 수집 (PS7) v1.5 Minimal Safe
# 목적: "파일명과 경로"만 수집 (콘텐츠 미접근, 파일 손상 위험 0)
#inventory.ps1
#requires -Version 7.0
[CmdletBinding()]
param(
  [switch]$Strict  # permanent 누락 시 실패
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$PSDefaultParameterValues['*:Encoding'] = 'utf8'

# --- 레포 루트 탐색 (.git 없이도 동작) : OR 연산자 미사용 ---
function Get-RepoRoot {
  $d = Resolve-Path $PSScriptRoot
  for ($i = 0; $i -lt 8; $i++) {
    $p1 = Join-Path $d '.github'
    if (Test-Path $p1) { return $d }
    $p2 = Join-Path $d '.kobong'
    if (Test-Path $p2) { return $d }
    $parent = Split-Path -Parent $d
    if ($parent -eq $d) { break }
    $d = $parent
  }
  # scripts/g5 기준 두 단계 위로 fallback
  return (Resolve-Path (Join-Path $PSScriptRoot '..' '..'))
}

$ROOT    = Get-RepoRoot
Set-Location $ROOT
$INV_DIR = Join-Path $ROOT '_inventory'
New-Item -ItemType Directory -Force -Path $INV_DIR | Out-Null

$MANIFEST_FILE = Join-Path $ROOT '.kobong/DocsManifest.json'
if (-not (Test-Path $MANIFEST_FILE)) { throw "DocsManifest not found: $MANIFEST_FILE" }

# --- Manifest 로드/검증(배열 보장) ---
$ManifestRaw = Get-Content $MANIFEST_FILE -Raw
$Manifest = $null
try {
  $Manifest = $ManifestRaw | ConvertFrom-Json
} catch {
  throw "DocsManifest JSON parse error: $($_.Exception.Message)"
}
if (-not ($Manifest -is [System.Collections.IEnumerable])) { throw "DocsManifest must be an array" }

# --- 이전 스냅샷 로드 (있으면) ---
$CSV   = Join-Path $INV_DIR 'hashes.csv'
$CHG   = Join-Path $INV_DIR 'changes.txt'
$oldRows = @{}
if (Test-Path $CSV) {
  try {
    $oldRows = (Import-Csv $CSV) | Group-Object path -AsHashTable
  } catch {
    $oldRows = @{}
  }
}

# --- 스캔 대상(무시 목록) ---
$Ignore = @(
  '\.git\\', '^_inventory\\', 'node_modules\\', '\.cache\\', '\.vs\\', '\.vscode\\',
  'logs\\', '\.DS_Store$', '\.idea\\', '\.pytest_cache\\', '\.venv\\', '__pycache__\\'
)
function Should-Skip([string]$rel) {
  $r = $rel -replace '/', '\'
  foreach ($pat in $Ignore) {
    if ($r -match $pat) { return $true }
  }
  return $false
}

# --- 현재 스냅샷 생성 ---
$files = Get-ChildItem -File -Recurse -Force | ForEach-Object {
  $rel = [IO.Path]::GetRelativePath($ROOT, $_.FullName)
  if (-not (Should-Skip $rel)) { $_ }
}

$currList = foreach ($f in $files) {
  $h = Get-FileHash -Algorithm SHA256 -LiteralPath $f.FullName
  [pscustomobject]@{
    path          = [IO.Path]::GetRelativePath($ROOT, $f.FullName).Replace('\','/')
    sha256        = $h.Hash.ToLowerInvariant()
    size          = $f.Length
    lastWriteTime = $f.LastWriteTimeUtc.ToString('o')
  }
}

# --- 새 스냅샷 저장(임시→원본 교체) ---
$tmpCSV = Join-Path $INV_DIR 'hashes.tmp.csv'
$currList | Sort-Object path | Export-Csv -NoTypeInformation -Encoding UTF8 -Path $tmpCSV
Move-Item -Force $tmpCSV $CSV

# --- 변경점 비교(oldRows vs currRows) ---
$currRows = $currList | Group-Object path -AsHashTable

$added   = New-Object System.Collections.Generic.List[string]
$removed = New-Object System.Collections.Generic.List[string]
$changed = New-Object System.Collections.Generic.List[string]

foreach ($k in $oldRows.Keys) {
  if (-not $currRows.ContainsKey($k)) { [void]$removed.Add($k) }
  else {
    if ($oldRows[$k].sha256 -ne $currRows[$k].sha256) { [void]$changed.Add($k) }
  }
}
foreach ($k in $currRows.Keys) {
  if (-not $oldRows.ContainsKey($k)) { [void]$added.Add($k) }
}

"ADDED"   | Out-File $CHG -Encoding utf8
($added   | Sort-Object) | Out-File $CHG -Append -Encoding utf8
"CHANGED" | Out-File $CHG -Append -Encoding utf8
($changed | Sort-Object) | Out-File $CHG -Append -Encoding utf8
"REMOVED" | Out-File $CHG -Append -Encoding utf8
($removed | Sort-Object) | Out-File $CHG -Append -Encoding utf8

# --- Manifest 정책 검증 ---
$viol = New-Object System.Collections.Generic.List[string]
foreach ($m in $Manifest) {
  $pp = "$($m.path)".Replace('/','\')
  $full = Join-Path $ROOT $pp
  $needPermanent = ($null -ne $m.retention) -and ($m.retention.ToString().ToLower() -eq 'permanent')
  if ($needPermanent) {
    if (-not (Test-Path $full)) {
      [void]$viol.Add("permanent missing: $($m.path)")
    }
  }
}

# Manifest 내부에 정책(YAML) 지정이 있다면 존재 확인
foreach ($m in $Manifest) {
  $p = "$($m.path)"
  if ($p.ToLower().EndsWith('.yaml') -or $p.ToLower().EndsWith('.yml')) {
    $full = Join-Path $ROOT ($p.Replace('/','\'))
    if (-not (Test-Path $full)) {
      [void]$viol.Add("policy missing: $p")
    }
  }
}

if ($Strict -and $viol.Count -gt 0) {
  $viol | ForEach-Object { Write-Host $_ }
  throw "Manifest violations: $($viol.Count)"
}

Write-Host "INVENTORY OK"
exit 0
