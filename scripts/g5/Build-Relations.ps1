<# =====================================================================
 파일: scripts/g5/Build-Relations.ps1
 목적:
   - 리포지토리 내 파일 연관관계를 스캔하여 _inventory 산출물 생성

 산출물:
   - _inventory/relations.csv
   - _inventory/graph.json
   - _inventory/graph.mermaid.md
   - _inventory/index.json

 핵심 개선(이번 수정):
   1) ✅ YAML의 inline run:  run: pwsh -NoProfile -File scripts/g5/xxx.ps1  → 인식
   2) ✅ Fallback: YAML 전체에서 .ps1/.js 경로 토큰을 추가로 수집(yml_path)
   3) 🔒 null-safe 파일읽기 & 정규식 누수 차단(문법/런타임 에러 방지)
   4) 0건이어도 CSV 헤더/미리보기 래퍼/인덱스는 항상 생성

 사용법:
   pwsh -NoProfile -File scripts/g5/Build-Relations.ps1              # 전체 스캔
   pwsh -NoProfile -File scripts/g5/Build-Relations.ps1 -ChangedOnly # 변경만 (git 불가 시 자동 전체)
===================================================================== #>

[CmdletBinding()]
param(
  [switch]$ChangedOnly,
  [string]$OutDir = "_inventory"
)

$ErrorActionPreference = 'Stop'

# == 기본 경로 ==
$REPO = (Get-Location).Path
$OUT  = Join-Path $REPO $OutDir
New-Item -ItemType Directory -Force -Path $OUT | Out-Null

# == 허용 확장자 ==
$ALLOW_EXT = @(
  '.ps1','.psm1','.psd1',
  '.js','.mjs','.cjs','.ts','.tsx','.jsx',
  '.md','.yml','.yaml'
)

# == 제외 규칙 ==
$IGNORE_RX = @('^\.git/','^_inventory/','^node_modules/','^dist/','^build/','^out/','^coverage/')
function Test-Ignored([string]$rel){ foreach($r in $IGNORE_RX){ if($rel -match $r){return $true} } return $false }

# == 항상 문자열을 반환하는 안전한 읽기 ==
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

# == 탐지 정규식 세트 ==
$RX = @{
  js_import     = [regex]"(?m)^\s*import\s+.*?\sfrom\s+['""](?<t>[^'""]+)['""]"
  js_req        = [regex]"(?m)require\(['""](?<t>[^'""]+)['""]\)"
  ps_dot        = [regex]"(?m)^\s*\.\s+(?<t>(?:\.{0,2}[\\/])?[^\s#'""]+\.ps1)\b"
  ps_call       = [regex]"(?m)^\s*&\s+(?<t>(?:\.{0,2}[\\/])?[^\s#'""]+\.ps1)\b"
  ps_module     = [regex]"(?im)^\s*Import-Module\s+['""]?(?<t>[^'""]+?)(['""]|\s|$)"
  md_link       = [regex]"\[(?<text>[^\]]+)\]\((?<t>[^)]+)\)"
  yml_uses      = [regex]"(?m)^\s*uses:\s*(?<t>\./[^\s#]+)"                      # 로컬 액션
  yml_run_block = [regex]"(?s)^\s*run:\s*\|\s*(?:#.*)?\r?\n(?<t>(?:\s{1,}.*\r?\n?)+)"  # 블록 스타일
  yml_run_line  = [regex]"(?m)^\s*run:\s*(?!\|)(?<t>.+)$"                             # ✅ 인라인 스타일
  yml_any_path  = [regex]"(?im)(?<t>(?:\.{0,2}[\\/])?(?:[\w\.\-]+[\\/])*[\w\.\-]+\.(?:ps1|js))" # ✅ Fallback
}

# == run 블록에서 .ps1/.js 경로 추출 ==
function Find-YamlRunPaths {
  param([string]$block)
  if ([string]::IsNullOrWhiteSpace($block)) { return @() }
  $pat = [regex]@'
(?im)(?:"|')?(?<path>(?:\.{0,2}[\\/])?(?:[\w\.\-]+[\\/])*[\w\.\-]+\.(?:ps1|js))(?:"|')?
'@
  $list = New-Object System.Collections.Generic.List[string]
  foreach ($m in $pat.Matches($block)) {
    $p = $m.Groups['path'].Value
    if (-not [string]::IsNullOrWhiteSpace($p)) { $list.Add($p) }
  }
  $list | Select-Object -Unique
}

# == 스캔 ==
$edgeSet = New-Object System.Collections.Generic.HashSet[string]
$edges   = New-Object System.Collections.Generic.List[object]

foreach ($f in (Get-RepoFiles -Changed:$ChangedOnly)) {
  $full = Join-Path $REPO $f
  $text = Read-TextSafe -Path $full

  foreach($k in $RX.Keys){
    # 1) run 블록(블록 스타일)
    if ($k -eq 'yml_run_block') {
      foreach($m in $RX[$k].Matches($text)) {
        foreach($raw in (Find-YamlRunPaths $m.Groups['t'].Value)) {
          $tp = Resolve-PathSafe -src $f -t $raw -kind 'yml_run'
          if ($tp) {
            $key = "$f|yml_run|$tp"
            if ($edgeSet.Add($key)) {
              $edges.Add([pscustomobject]@{ source_path=$f; relation='yml_run'; target_path=$tp; detected_by='run-block'; confidence=0.9 })
            }
          }
        }
      }
      continue
    }

    # 2) run (인라인 스타일)  ← ✅ 이번 추가
    if ($k -eq 'yml_run_line') {
      foreach($m in $RX[$k].Matches($text)) {
        foreach($raw in (Find-YamlRunPaths $m.Groups['t'].Value)) {
          $tp = Resolve-PathSafe -src $f -t $raw -kind 'yml_run'
          if ($tp) {
            $key = "$f|yml_run|$tp"
            if ($edgeSet.Add($key)) {
              $edges.Add([pscustomobject]@{ source_path=$f; relation='yml_run'; target_path=$tp; detected_by='run-inline'; confidence=0.9 })
            }
          }
        }
      }
      continue
    }

    # 3) Fallback: YAML 내 임의 위치의 .ps1/.js 토큰  ← ✅ 이번 추가
    if ($k -eq 'yml_any_path' -and ($f -like '*.yml' -or $f -like '*.yaml')) {
      foreach($m in $RX[$k].Matches($text)) {
        $tp = Resolve-PathSafe -src $f -t $m.Groups['t'].Value -kind 'yml_path'
        if ($tp) {
          $key = "$f|yml_path|$tp"
          if ($edgeSet.Add($key)) {
            $edges.Add([pscustomobject]@{ source_path=$f; relation='yml_path'; target_path=$tp; detected_by='fallback'; confidence=0.6 })
          }
        }
      }
      continue
    }

    # 4) 나머지 일반 규칙
    foreach($m in $RX[$k].Matches($text)) {
      $raw = $m.Groups['t'].Value
      $tp = Resolve-PathSafe -src $f -t $raw -kind $k
      if ($tp) {
        $key = "$f|$k|$tp"
        if ($edgeSet.Add($key)) {
          $edges.Add([pscustomobject]@{
            source_path=$f; relation=$k; target_path=$tp; detected_by=("regex/{0}" -f $k); confidence=0.7
          })
        }
      }
    }
  }
}

# == 산출물 ==
$CSV = Join-Path $OUT "relations.csv"
$JSON= Join-Path $OUT "graph.json"
$MM  = Join-Path $OUT "graph.mermaid.md"
$IDX = Join-Path $OUT "index.json"

if ($edges.Count -eq 0) {
  Set-Content -Path $CSV -Encoding UTF8 -Value "source_path,relation,target_path,detected_by,confidence`n"
} else {
  $edges | Sort-Object source_path, target_path, relation | Export-Csv -NoTypeInformation -Encoding UTF8 -Path $CSV
}

$nodes = @{}
$edges | ForEach-Object { $nodes[$_.source_path]=$true; $nodes[$_.target_path]=$true }

$g = [pscustomobject]@{
  nodes = @($nodes.Keys | Sort-Object | ForEach-Object { @{ id = $_ } })
  edges = @($edges | ForEach-Object { @{ from = $_.source_path; to = $_.target_path; type = $_.relation } })
}
$g | ConvertTo-Json -Depth 5 | Set-Content -Path $JSON -Encoding UTF8

$mm = New-Object System.Collections.Generic.List[string]
$mm.Add('```mermaid'); $mm.Add('graph LR')
$edges | Select-Object -First 100 | ForEach-Object {
  $a=$_.source_path.Replace(' ','_').Replace('/','__')
  $b=$_.target_path.Replace(' ','_').Replace('/','__')
  $mm.Add("  $a --> $b")
}
$mm.Add('```')
$mm -join [Environment]::NewLine | Set-Content -Path $MM -Encoding UTF8

[pscustomobject]@{
  generated_at           = (Get-Date -AsUtc -Format s) + 'Z'
  node_count             = $nodes.Count
  edge_count             = $edges.Count
  changed_only_effective = [bool]$ChangedOnly  # (zipball이면 내부적으로 전체 스캔일 수 있음)
  out_dir                = $OutDir
} | ConvertTo-Json -Depth 3 | Set-Content -Path $IDX -Encoding UTF8

Write-Host ("== relations.csv edges: {0}" -f $edges.Count)
Write-Host ("== graph.json nodes : {0}" -f $nodes.Count)
exit 0
