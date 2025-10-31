# ======================================================================
# 파일: scripts/g5/Build-Relations.ps1
# 목적: 레포 내 참조 관계를 스캔하여 _inventory 산출물 생성
# 산출물:
#   - _inventory/relations.csv
#   - _inventory/graph.json
#   - _inventory/graph.mermaid.md
#   - _inventory/index.json
# 사용법:
#   pwsh -NoProfile -File scripts/g5/Build-Relations.ps1
#   pwsh -NoProfile -File scripts/g5/Build-Relations.ps1 -ChangedOnly
#   pwsh -NoProfile -File scripts/g5/Build-Relations.ps1 -OutDirPath "D:\work\repo\_inventory"
# 가드:
#   - ENV: INVENTORY_DIR, 인자 -OutDirPath 로 출력 위치 강제 가능
#   - zipball( .git 없음 ) 환경에서도 동작
#   - 0건이어도 CSV/mermaid/index 는 항상 생성
#   - 정규식 누수/경로 이상치 차단
# ======================================================================

[CmdletBinding()]
param(
  [switch]$ChangedOnly,
  [string]$OutDir = "_inventory",
  [string]$OutDirPath
)

$ErrorActionPreference = 'Stop'

# --- 출력 루트 결정 (OutDirPath > ENV > 스크립트 기준 + OutDir) -----------------
$rootByScript = try { (Resolve-Path (Join-Path $PSScriptRoot '..' '..')).Path } catch { (Get-Location).Path }

if (-not [string]::IsNullOrWhiteSpace($OutDirPath)) {
  $OUT = [System.IO.Path]::GetFullPath($OutDirPath)
}
elseif (-not [string]::IsNullOrWhiteSpace($env:INVENTORY_DIR)) {
  $OUT = [System.IO.Path]::GetFullPath($env:INVENTORY_DIR)
}
else {
  $OUT = Join-Path $rootByScript $OutDir
}
if ([string]::IsNullOrWhiteSpace($OUT)) { $OUT = Join-Path $rootByScript "_inventory" }
New-Item -ItemType Directory -Force -Path $OUT | Out-Null
Write-Host "OUT_DIR=$OUT"

# --- 유틸 --------------------------------------------------------------
$ALLOW_EXT = @(
  '.ps1','.psm1','.psd1',
  '.js','.mjs','.cjs','.ts','.tsx','.jsx',
  '.md','.yml','.yaml'
)
$IGNORE_RX = @('^\.git/','^_inventory/','^node_modules/','^dist/','^build/','^out/','^coverage/')
function Test-Ignored([string]$rel){ foreach($r in $IGNORE_RX){ if($rel -match $r){return $true} } return $false }

function Read-TextSafe {
  param([string]$Path)
  try { return [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8) }
  catch {
    try {
      $s = Get-Content -LiteralPath $Path -Raw -ErrorAction SilentlyContinue
      if ($null -eq $s) { '' } else { [string]$s }
    } catch { '' }
  }
}

function Resolve-PathSafe {
  param([string]$src, [string]$t, [string]$kind)
  if ([string]::IsNullOrWhiteSpace($t)) { return $null }
  $t = $t.Trim(" `t`r`n'`"")

  if ($t -match '\(\?\<|<path>|\?\:|\[\^|\\d|\(\?i|\(\?m|\(\?s' -or $t -match '[\r\n]') { return $null }
  if ($t -match '^(node:|https?://|@|[A-Za-z0-9._-]+/[A-Za-z0-9._-]+)') { return $null }
  if ($t -match '^[A-Za-z]:[\\/]' -or $t -match '^/') { return $null }
  if ($t -notmatch '^[\.A-Za-z0-9_\-/\\]+?\.[A-Za-z0-9]+$') { return $null }

  $ext = ([System.IO.Path]::GetExtension($t) ?? '').ToLowerInvariant()
  if (-not ($ALLOW_EXT -contains $ext)) { return $null }

  $repoRoot = $rootByScript
  $baseDir = if ($kind -like 'yml_*') { $repoRoot } else { Split-Path -Parent (Join-Path $repoRoot $src) }
  $abs = [System.IO.Path]::GetFullPath((Join-Path $baseDir $t))
  if (-not $abs.StartsWith($repoRoot)) { return $null }
  return $abs.Substring($repoRoot.Length + 1).Replace('\','/')
}

function Get-RepoFiles {
  param([switch]$Changed)
  $effectiveChanged = $false
  $files = @()

  if ($Changed) {
    $baseRef = $env:GITHUB_BASE_REF; if ([string]::IsNullOrWhiteSpace($baseRef)) { $baseRef = 'origin/main' }
    if (Get-Command git -ErrorAction SilentlyContinue) {
      try {
        $diff = git diff --name-only $baseRef...HEAD 2>$null
        if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($diff)) {
          $effectiveChanged = $true
          foreach($p in ($diff -split "`n")){
            if ([string]::IsNullOrWhiteSpace($p)) { continue }
            $rel = $p.Trim().Replace('\','/')
            if (Test-Ignored $rel) { continue }
            $ext = [System.IO.Path]::GetExtension($rel).ToLowerInvariant()
            if ($ALLOW_EXT -contains $ext) { $files += $rel }
          }
        }
      } catch { }
    }
    if (-not $effectiveChanged) { Write-Host 'changed_only 요청 → git 비교 불가 → 전체 스캔으로 폴백' }
  }

  if (-not $effectiveChanged) {
    foreach($it in Get-ChildItem -File -Recurse -Force -LiteralPath $rootByScript){
      $rel = $it.FullName.Substring($rootByScript.Length + 1).Replace('\','/')
      if (Test-Ignored $rel) { continue }
      $ext = [System.IO.Path]::GetExtension($rel).ToLowerInvariant()
      if ($ALLOW_EXT -contains $ext) { $files += $rel }
    }
  }

  return @{ files = ($files | Select-Object -Unique); changed = $effectiveChanged }
}

# --- 탐지 정규식 -------------------------------------------------------
$RX = @{
  js_import     = [regex]"(?m)^\s*import\s+.*?\sfrom\s+['""](?<t>[^'""]+)['""]"
  js_req        = [regex]"(?m)require\(['""](?<t>[^'""]+)['""]\)"
  ps_dot        = [regex]"(?m)^\s*\.\s+(?<t>(?:\.{0,2}[\\/])?[^\s#'""]+\.ps1)\b"
  ps_call       = [regex]"(?m)^\s*&\s+(?<t>(?:\.{0,2}[\\/])?[^\s#'""]+\.ps1)\b"
  ps_module     = [regex]"(?im)^\s*Import-Module\s+['""]?(?<t>[^'""]+?)(['""]|\s|$)"
  md_link       = [regex]"\[(?<text>[^\]]+)\]\((?<t>[^)]+)\)"
  yml_uses      = [regex]"(?m)^\s*uses:\s*(?<t>\./[^\s#]+)"
  yml_run_block = [regex]"(?s)^\s*run:\s*\|\s*(?:#.*)?\r?\n(?<t>(?:\s{1,}.*\r?\n?)+)"
  yml_run_line  = [regex]"(?m)^\s*run:\s*(?!\|)(?<t>.+)$"
  yml_any_path  = [regex]"(?im)(?<t>(?:\.{0,2}[\\/])?(?:[\w\.\-]+[\\/])*[\w\.\-]+\.(?:ps1|js))"
}

function Find-YamlRunPaths {
  param([string]$block)
  if ([string]::IsNullOrWhiteSpace($block)) { return @() }
  $pat = [regex]@'
(?im)(?:"|')?(?<path>(?:\.{0,2}[\\/])?(?:[\w\.\-]+[\\/])*[\w\.\-]+\.(?:ps1|js))(?:"|')?
'@
  $acc = New-Object System.Collections.Generic.List[string]
  foreach ($m in $pat.Matches($block)) {
    $p = $m.Groups['path'].Value
    if (-not [string]::IsNullOrWhiteSpace($p)) { $acc.Add($p) }
  }
  $acc | Select-Object -Unique
}

# --- 스캔 --------------------------------------------------------------
$edgeSet = New-Object System.Collections.Generic.HashSet[string]
$edges   = New-Object System.Collections.Generic.List[object]

$scan = Get-RepoFiles -Changed:$ChangedOnly
$FILES = $scan.files

foreach ($f in $FILES) {
  $full = Join-Path $rootByScript $f
  $text = Read-TextSafe -Path $full

  foreach($k in $RX.Keys){

    if ($k -eq 'yml_run_block') {
      foreach($m in $RX[$k].Matches($text)) {
        foreach($raw in (Find-YamlRunPaths $m.Groups['t'].Value)) {
          $tp = Resolve-PathSafe -src $f -t $raw -kind 'yml_run'
          if ($tp) { $key="$f|yml_run|$tp"; if ($edgeSet.Add($key)) { $edges.Add([pscustomobject]@{source_path=$f;relation='yml_run';target_path=$tp;detected_by='run-block';confidence=0.9}) } }
        }
      }
      continue
    }

    if ($k -eq 'yml_run_line') {
      foreach($m in $RX[$k].Matches($text)) {
        foreach($raw in (Find-YamlRunPaths $m.Groups['t'].Value)) {
          $tp = Resolve-PathSafe -src $f -t $raw -kind 'yml_run'
          if ($tp) { $key="$f|yml_run|$tp"; if ($edgeSet.Add($key)) { $edges.Add([pscustomobject]@{source_path=$f;relation='yml_run';target_path=$tp;detected_by='run-inline';confidence=0.9}) } }
        }
      }
      continue
    }

    if ($k -eq 'yml_any_path' -and ($f -like '*.yml' -or $f -like '*.yaml')) {
      foreach($m in $RX[$k].Matches($text)) {
        $tp = Resolve-PathSafe -src $f -t $m.Groups['t'].Value -kind 'yml_path'
        if ($tp) { $key="$f|yml_path|$tp"; if ($edgeSet.Add($key)) { $edges.Add([pscustomobject]@{source_path=$f;relation='yml_path';target_path=$tp;detected_by='fallback';confidence=0.6}) } }
      }
      continue
    }

    foreach($m in $RX[$k].Matches($text)) {
      $tp = Resolve-PathSafe -src $f -t $m.Groups['t'].Value -kind $k
      if ($tp) { $key="$f|$k|$tp"; if ($edgeSet.Add($key)) { $edges.Add([pscustomobject]@{source_path=$f;relation=$k;target_path=$tp;detected_by=("regex/{0}" -f $k);confidence=0.7}) } }
    }
  }
}

# --- 산출물 경로(!! 변수명 확정: 혼선 방지) ---------------------------------------
$CsvPath     = Join-Path $OUT "relations.csv"
$GraphPath   = Join-Path $OUT "graph.json"
$MermaidPath = Join-Path $OUT "graph.mermaid.md"
$IndexPath   = Join-Path $OUT "index.json"

# --- relations.csv ------------------------------------------------------
if ($edges.Count -eq 0) {
  Set-Content -Path $CsvPath -Encoding UTF8 -Value "source_path,relation,target_path,detected_by,confidence`n"
} else {
  $edges | Sort-Object source_path, target_path, relation | Export-Csv -NoTypeInformation -Encoding UTF8 -Path $CsvPath
}

# --- graph.json ---------------------------------------------------------
$nodes = @{}
$edges | ForEach-Object { $nodes[$_.source_path]=$true; $nodes[$_.target_path]=$true }
$g = [pscustomobject]@{
  nodes = @($nodes.Keys | Sort-Object | ForEach-Object { @{ id = $_ } })
  edges = @($edges | ForEach-Object { @{ from = $_.source_path; to = $_.target_path; type = $_.relation } })
}
$g | ConvertTo-Json -Depth 5 | Set-Content -Path $GraphPath -Encoding UTF8

# --- Mermaid(100 edges) -------------------------------------------------
function To-MermaidId([string]$p) { if ([string]::IsNullOrWhiteSpace($p)) { return '_' } else { return ($p -replace '[^A-Za-z0-9_]', '_') } }
$mer = New-Object System.Collections.Generic.List[string]
$mer.Add('```mermaid'); $mer.Add('graph LR')
$edges | Select-Object -First 100 | ForEach-Object {
  $a = To-MermaidId $_.source_path
  $b = To-MermaidId $_.target_path
  $mer.Add("  $a --> $b")
}
$mer.Add('```')
($mer -join [Environment]::NewLine) | Set-Content -Path $MermaidPath -Encoding UTF8 -ErrorAction Stop

# --- index.json ---------------------------------------------------------
[pscustomobject]@{
  generated_at           = (Get-Date -AsUtc -Format s) + 'Z'
  node_count             = $nodes.Count
  edge_count             = $edges.Count
  changed_only_effective = [bool]$ChangedOnly
  out_dir                = (Resolve-Path $OUT).Path
} | ConvertTo-Json -Depth 3 | Set-Content -Path $IndexPath -Encoding UTF8

Write-Host ("== relations.csv edges: {0}" -f $edges.Count)
Write-Host ("== graph.json nodes : {0}" -f $nodes.Count)
exit 0
