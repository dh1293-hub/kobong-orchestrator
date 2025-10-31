# scripts/g5/Build-Relations.ps1
<# 목적
 - 리포지토리 내 파일 간 "연관 관계"를 스캔하여 _inventory 산출물 생성

 산출물
 - _inventory/relations.csv
 - _inventory/graph.json
 - _inventory/graph.mermaid.md
 - _inventory/index.json

 사용법
 - pwsh -NoProfile -File scripts/g5/Build-Relations.ps1
 - pwsh -NoProfile -File scripts/g5/Build-Relations.ps1 -ChangedOnly
 - pwsh -NoProfile -File scripts/g5/Build-Relations.ps1 -OutDir _inventory   # 기본값 동일

 친절한 주석
 - zipball(.git 없음) 환경에서도 안전
 - YAML run: 블록/인라인 + Fallback(.ps1/.js 토큰)까지 수집
 - null-safe 파일 읽기, 정규식 누수 차단, 경로 안전 화이트리스트
 - 0건이어도 CSV 헤더/메르메이드/인덱스 반드시 생성
#>

[CmdletBinding()]
param(
  [switch]$ChangedOnly,
  [string]$OutDir = "_inventory",
  [string]$OutDirPath   # ✅ 강제 출력 경로(절대/상대 모두 허용)
)

$ErrorActionPreference = 'Stop'

# 1) 스크립트 기준 repo 루트(폴백)
$rootByScript = try { (Resolve-Path (Join-Path $PSScriptRoot '..' '..')).Path } catch { (Get-Location).Path }

# 2) 출력 경로 결론: OutDirPath > ENV:INVENTORY_DIR > 스크립트 기준 + OutDir
if (-not [string]::IsNullOrWhiteSpace($OutDirPath)) {
  $OUT = [System.IO.Path]::GetFullPath($OutDirPath)
}
elseif (-not [string]::IsNullOrWhiteSpace($env:INVENTORY_DIR)) {
  $OUT = [System.IO.Path]::GetFullPath($env:INVENTORY_DIR)
}
else {
  $OUT = Join-Path $rootByScript $OutDir
}

# 3) 최종 안전장치 + 폴더 생성
if ([string]::IsNullOrWhiteSpace($OUT)) { $OUT = Join-Path $rootByScript "_inventory" }
New-Item -ItemType Directory -Force -Path $OUT | Out-Null
Write-Host "OUT_DIR=$OUT"

# (아래쪽 산출물 경로 생성부는 이렇게 보장된 $OUT을 그대로 사용)
# $CsvPath   = Join-Path $OUT "relations.csv"
# $GraphJson = Join-Path $OUT "graph.json"
# $MermaidPath = Join-Path $OUT "graph.mermaid.md"
# $IndexPath = Join-Path $OUT "index.json"





# == 허용 확장자 ==
$ALLOW_EXT = @(
  '.ps1','.psm1','.psd1',
  '.js','.mjs','.cjs','.ts','.tsx','.jsx',
  '.md','.yml','.yaml'
)

# == 제외 규칙 ==
$IGNORE_RX = @('^\.git/','^_inventory/','^node_modules/','^dist/','^build/','^out/','^coverage/')
function Test-Ignored([string]$rel){ foreach($r in $IGNORE_RX){ if($rel -match $r){return $true} } return $false }

# == 항상 문자열 반환: null-safe ==
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

# == 경로 안전성 검사 + 정규화 ==
function Resolve-PathSafe {
  param([string]$src, [string]$t, [string]$kind)

  if ([string]::IsNullOrWhiteSpace($t)) { return $null }
  $t = $t.Trim(" `t`r`n'`"")

  # 정규식/이상문자 누수 차단
  if ($t -match '\(\?\<|<path>|\?\:|\[\^|\\d|\(\?i|\(\?m|\(\?s' -or $t -match '[\r\n]') { return $null }

  # 외부/절대/URL/패키지 제외
  if ($t -match '^(node:|https?://|@|[A-Za-z0-9._-]+/[A-Za-z0-9._-]+)') { return $null }
  if ($t -match '^[A-Za-z]:[\\/]' -or $t -match '^/') { return $null }

  # 허용 문자/확장자
  if ($t -notmatch '^[\.A-Za-z0-9_\-/\\]+?\.[A-Za-z0-9]+$') { return $null }
  $ext = ([System.IO.Path]::GetExtension($t) ?? '').ToLowerInvariant()
  if (-not ($ALLOW_EXT -contains $ext)) { return $null }

  # YAML(run/uses)은 레포 루트 기준, 그 외는 파일 기준
  $baseDir = if ($kind -like 'yml_*') { $REPO } else { Split-Path -Parent (Join-Path $REPO $src) }
  $abs = [System.IO.Path]::GetFullPath((Join-Path $baseDir $t))
  if (-not $abs.StartsWith($REPO)) { return $null }
  $abs.Substring($REPO.Length + 1).Replace('\','/')
}

# == 파일 목록 ==
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
    foreach($it in Get-ChildItem -File -Recurse -Force){
      $rel = $it.FullName.Substring($REPO.Length + 1).Replace('\','/')
      if (Test-Ignored $rel) { continue }
      $ext = [System.IO.Path]::GetExtension($rel).ToLowerInvariant()
      if ($ALLOW_EXT -contains $ext) { $files += $rel }
    }
  }

  $files | Select-Object -Unique | ForEach-Object { $_ }
}

# == 탐지 정규식 ==
$RX = @{
  js_import     = [regex]"(?m)^\s*import\s+.*?\sfrom\s+['""](?<t>[^'""]+)['""]"
  js_req        = [regex]"(?m)require\(['""](?<t>[^'""]+)['""]\)"
  ps_dot        = [regex]"(?m)^\s*\.\s+(?<t>(?:\.{0,2}[\\/])?[^\s#'""]+\.ps1)\b"
  ps_call       = [regex]"(?m)^\s*&\s+(?<t>(?:\.{0,2}[\\/])?[^\s#'""]+\.ps1)\b"
  ps_module     = [regex]"(?im)^\s*Import-Module\s+['""]?(?<t>[^'""]+?)(['""]|\s|$)"
  md_link       = [regex]"\[(?<text>[^\]]+)\]\((?<t>[^)]+)\)"
  yml_uses      = [regex]"(?m)^\s*uses:\s*(?<t>\./[^\s#]+)"                           # 로컬 액션
  yml_run_block = [regex]"(?s)^\s*run:\s*\|\s*(?:#.*)?\r?\n(?<t>(?:\s{1,}.*\r?\n?)+)" # 블록 스타일
  yml_run_line  = [regex]"(?m)^\s*run:\s*(?!\|)(?<t>.+)$"                             # 인라인 스타일
  yml_any_path  = [regex]"(?im)(?<t>(?:\.{0,2}[\\/])?(?:[\w\.\-]+[\\/])*[\w\.\-]+\.(?:ps1|js))" # Fallback
}

# == run 블록에서 .ps1/.js 경로 뽑기 ==
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

# == 스캔 ==
$edgeSet = New-Object System.Collections.Generic.HashSet[string]
$edges   = New-Object System.Collections.Generic.List[object]

foreach ($f in (Get-RepoFiles -Changed:$ChangedOnly)) {
  $full = Join-Path $REPO $f
  $text = Read-TextSafe -Path $full

  foreach($k in $RX.Keys){
    if ($k -eq 'yml_run_block') {
      foreach($m in $RX[$k].Matches($text)) {
        foreach($raw in (Find-YamlRunPaths $m.Groups['t'].Value)) {
          $tp = Resolve-PathSafe -src $f -t $raw -kind 'yml_run'
          if ($tp) { $key = "$f|yml_run|$tp"; if ($edgeSet.Add($key)) { $edges.Add([pscustomobject]@{source_path=$f;relation='yml_run';target_path=$tp;detected_by='run-block';confidence=0.9}) } }
        }
      }
      continue
    }
    if ($k -eq 'yml_run_line') {
      foreach($m in $RX[$k].Matches($text)) {
        foreach($raw in (Find-YamlRunPaths $m.Groups['t'].Value)) {
          $tp = Resolve-PathSafe -src $f -t $raw -kind 'yml_run'
          if ($tp) { $key = "$f|yml_run|$tp"; if ($edgeSet.Add($key)) { $edges.Add([pscustomobject]@{source_path=$f;relation='yml_run';target_path=$tp;detected_by='run-inline';confidence=0.9}) } }
        }
      }
      continue
    }
    if ($k -eq 'yml_any_path' -and ($f -like '*.yml' -or $f -like '*.yaml')) {
      foreach($m in $RX[$k].Matches($text)) {
        $tp = Resolve-PathSafe -src $f -t $m.Groups['t'].Value -kind 'yml_path'
        if ($tp) { $key = "$f|yml_path|$tp"; if ($edgeSet.Add($key)) { $edges.Add([pscustomobject]@{source_path=$f;relation='yml_path';target_path=$tp;detected_by='fallback';confidence=0.6}) } }
      }
      continue
    }
    foreach($m in $RX[$k].Matches($text)) {
      $tp = Resolve-PathSafe -src $f -t $m.Groups['t'].Value -kind $k
      if ($tp) { $key = "$f|$k|$tp"; if ($edgeSet.Add($key)) { $edges.Add([pscustomobject]@{source_path=$f;relation=$k;target_path=$tp;detected_by=("regex/{0}" -f $k);confidence=0.7}) } }
    }
  }
}

# == 산출물 파일 경로 ==
$CsvPath      = Join-Path $OUT "relations.csv"
$GraphJson    = Join-Path $OUT "graph.json"
$MermaidPath  = Join-Path $OUT "graph.mermaid.md"
$IndexPath    = Join-Path $OUT "index.json"

# == relations.csv ==
if ($edges.Count -eq 0) {
  Set-Content -Path $CsvPath -Encoding UTF8 -Value "source_path,relation,target_path,detected_by,confidence`n"
} else {
  $edges | Sort-Object source_path, target_path, relation | Export-Csv -NoTypeInformation -Encoding UTF8 -Path $CsvPath
}

# == graph.json ==
$nodes = @{}
$edges | ForEach-Object { $nodes[$_.source_path]=$true; $nodes[$_.target_path]=$true }
$g = [pscustomobject]@{
  nodes = @($nodes.Keys | Sort-Object | ForEach-Object { @{ id = $_ } })
  edges = @($edges | ForEach-Object { @{ from = $_.source_path; to = $_.target_path; type = $_.relation } })
}
$g | ConvertTo-Json -Depth 5 | Set-Content -Path $GraphJson -Encoding UTF8

# === Mermaid(100 edges) ===
function To-MermaidId([string]$p) {
  if ([string]::IsNullOrWhiteSpace($p)) { return '_' }
  # 영숫자/언더스코어만 남기고 나머지는 모두 '_' 로 정규화
  return ($p -replace '[^A-Za-z0-9_]', '_')
}

$MermaidPath  = Join-Path $OUT "graph.mermaid.md"
$MermaidLines = New-Object System.Collections.Generic.List[string]

$MermaidLines.Add('```mermaid')
$MermaidLines.Add('graph LR')

$edges | Select-Object -First 100 | ForEach-Object {
  $aid = To-MermaidId $_.source_path
  $bid = To-MermaidId $_.target_path
  # 라벨은 생략(안전). 라벨을 넣고 싶으면  ->  $aid["$($_.source_path)"]  형식으로 확장 가능
  $MermaidLines.Add("  $aid --> $bid")
}

$MermaidLines.Add('```')

$MermaidContent = ($MermaidLines -join [Environment]::NewLine)
Set-Content -Path $MermaidPath -Value $MermaidContent -Encoding UTF8 -ErrorAction Stop


# == index.json ==
[pscustomobject]@{
  generated_at           = (Get-Date -AsUtc -Format s) + 'Z'
  node_count             = $nodes.Count
  edge_count             = $edges.Count
  changed_only_effective = [bool]$ChangedOnly
  out_dir                = $OutDir
} | ConvertTo-Json -Depth 3 | Set-Content -Path $IndexPath -Encoding UTF8

Write-Host ("== relations.csv edges: {0}" -f $edges.Count)
Write-Host ("== graph.json nodes : {0}" -f $nodes.Count)
exit 0
