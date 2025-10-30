# scripts/g5/Build-Relations.ps1
# 목적(WHAT)
#   - 리포지토리 내 파일 간 "연관 관계"를 스캔하여 _inventory 산출물 생성
# 산출물(OUTPUTS)
#   - _inventory/relations.csv       # source_path, relation, target_path, detected_by, confidence
#   - _inventory/graph.json          # { nodes:[{id}], edges:[{from,to,type}] }
#   - _inventory/graph.mermaid.md    # Mermaid 미리보기(최대 100엣지)
#   - _inventory/index.json          # { generated_at, node_count, edge_count, changed_only, out_dir }
# 연관(RELATED)
#   - .github/workflows/inventory-relations.yml
# 사용법(USAGE)
#   - 전체 스캔: pwsh -NoProfile -File scripts/g5/Build-Relations.ps1
#   - 변경만:   pwsh -NoProfile -File scripts/g5/Build-Relations.ps1 -ChangedOnly

[CmdletBinding()]
param(
  [switch]$ChangedOnly,
  [string]$OutDir = "_inventory"
)

$ErrorActionPreference = 'Stop'

# === 경로/출력 준비 ===
$repo = (Get-Location).Path
$rel  = Join-Path $repo $OutDir
New-Item -ItemType Directory -Force -Path $rel | Out-Null

# === 스캔 대상 계산 ===
function Get-TargetFiles {
  param([switch]$ChangedOnly)
  $patterns = @(
    "**/*.ps1","**/*.psm1","**/*.psd1",
    "**/*.js","**/*.mjs","**/*.cjs","**/*.ts","**/*.tsx","**/*.jsx",
    "**/*.md","**/*.yml","**/*.yaml"
  )
  $ignore = @("^\.git/","^$OutDir/","^node_modules/","^dist/","^build/","^out/","^coverage/")

  if ($ChangedOnly) {
    $base = $env:GITHUB_BASE_REF
    if ([string]::IsNullOrWhiteSpace($base)) { $base = "origin/main" }
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
      Write-Warning "git 미존재 → 전체 스캔으로 폴백"
      $ChangedOnly = $false
    } else {
      $diff = git diff --name-only $base...HEAD 2>$null
      if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($diff)) {
        Write-Warning "git diff 실패/변경없음 → 전체 스캔으로 폴백"
        $ChangedOnly = $false
      } else {
        return $diff | ForEach-Object { $_.ToString() } | Where-Object {
          $p = $_.Replace("\","/")
          -not ($ignore | ForEach-Object { $p -match $_ }) -and
          ($patterns | ForEach-Object { $p -like $_ }) -contains $true
        }
      }
    }
  }

  # 전체 스캔
  $all = Get-ChildItem -Recurse -File -Force | ForEach-Object {
    $_.FullName.Substring($repo.Length + 1).Replace("\","/")
  }
  $all | Where-Object {
    $p = $_
    -not ($ignore | ForEach-Object { $p -match $_ }) -and
    ($patterns | ForEach-Object { $p -like $_ }) -contains $true
  }
}

# === 정규식(1차 탐지기) ===
$rx = @{
  js_import  = [regex]"(?m)^\s*import\s+.*?\sfrom\s+['""](?<t>[^'""]+)['""]"
  js_require = [regex]"(?m)require\(['""](?<t>[^'""]+)['""]\)"
  ps_dot     = [regex]"(?m)^\s*\.\s+(?<t>(?:\.{0,2}[\\/])?[^\s#'""]+\.ps1)\b"
  ps_call    = [regex]"(?m)^\s*&\s+(?<t>(?:\.{0,2}[\\/])?[^\s#'""]+\.ps1)\b"
  ps_module  = [regex]"(?im)^\s*Import-Module\s+['""]?(?<t>[^'""]+?)(['""]|\s|$)"
  md_link    = [regex]"\[(?<text>[^\]]+)\]\((?<t>[^)]+)\)"
  yml_uses   = [regex]"(?m)^\s*uses:\s*(?<t>\./[^\s#]+)"    # 로컬 액션만
  # run 블록 전체(들여쓰기 포함) 캡처
  yml_run    = [regex]"(?s)^\s*run:\s*\|?\s*[\r\n]+(?<t>(?:\s{2,}.+[\r\n]+)+)"
}

# === 경로 해석 ===
function Resolve-TargetPath {
  param([string]$src, [string]$t, [string]$kind)

  # 외부/패키지/URL/절대경로 제외
  if ($t -match "^(node:|https?://|@|[A-Za-z0-9._-]+/[A-Za-z0-9._-]+)") { return $null }
  if ($t -match "^[A-Za-z]:[\\/]" -or $t -match "^/") { return $null }

  # Import-Module 은 상대경로만 파일관계로 수집(모듈명은 제외)
  if ($kind -eq 'ps_module' -and ($t -notmatch "[\\/]|^\.")) { return $null }

  # 공백/인용부호 제거
  $t = $t.Trim("'`"").Trim()

  # YAML(run/uses)은 레포 루트 기준, 그 외는 파일 기준
  $baseDir = if ($kind -like 'yml_*') { $repo } else { Split-Path -Parent (Join-Path $repo $src) }

  # 상대경로 정규화
  $p = [System.IO.Path]::GetFullPath((Join-Path $baseDir $t))
  if ($p.StartsWith($repo)) {
    return $p.Substring($repo.Length + 1).Replace("\","/")
  }
  return $null
}

# === 스캔 실행 ===
$edges = New-Object System.Collections.Generic.List[object]
$files = Get-TargetFiles -ChangedOnly:$ChangedOnly
foreach ($f in $files) {
  $full = Join-Path $repo $f
  $text = Get-Content -Raw -Encoding UTF8 $full

  foreach ($k in $rx.Keys) {
    $matches = $rx[$k].Matches($text)

    if ($k -eq 'yml_run') {
      foreach ($m in $matches) {
        $block = $m.Groups['t'].Value

        # 1) -File <path>     2) '-File','<path>' (배열)     3) 그냥 <path>.ps1 등장
        $paths = New-Object System.Collections.Generic.List[string]
        $r1 = [regex]"(?im)(?:^|\s)-File\s+['""]?(?<path>(?:\.{0,2}[\\/])?(?:[A-Za-z0-9._-]+[\\/])*[A-Za-z0-9._-]+\.ps1)['""]?"
        $r2 = [regex]"(?is)(?:^|\s)['""]-?File['""]\s*,\s*['""](?<path>(?:\.{0,2}[\\/])?(?:[A-Za-z0-9._-]+[\\/])*[A-Za-z0-9._-]+\.ps1)['""]"
        $r3 = [regex]"(?im)(?<path>(?:\.{0,2}[\\/])?(?:[A-Za-z0-9._-]+[\\/])*[A-Za-z0-9._-]+\.ps1)"

        foreach ($mm in $r1.Matches($block)) { $paths.Add($mm.Groups['path'].Value) }
        foreach ($mm in $r2.Matches($block)) { $paths.Add($mm.Groups['path'].Value) }
        foreach ($mm in $r3.Matches($block)) { $paths.Add($mm.Groups['path'].Value) }

        foreach ($t in ($paths | Select-Object -Unique)) {
          $tp = Resolve-TargetPath -src $f -t $t -kind $k
          if ($null -ne $tp) {
            $edges.Add([pscustomobject]@{
              source_path = $f
              relation    = $k
              target_path = $tp
              detected_by = "regex/$k"
              confidence  = 0.8
            })
          }
        }
      }
      continue
    }

    foreach ($m in $matches) {
      $t = $m.Groups['t'].Value
      $tp = Resolve-TargetPath -src $f -t $t -kind $k
      if ($null -ne $tp) {
        $edges.Add([pscustomobject]@{
          source_path = $f
          relation    = $k
          target_path = $tp
          detected_by = "regex/$k"
          confidence  = 0.7
        })
      }
    }
  }
}

# === 산출물 생성 ===
$csv = Join-Path $rel "relations.csv"
$json = Join-Path $rel "graph.json"
$mm   = Join-Path $rel "graph.mermaid.md"
$idx  = Join-Path $rel "index.json"

if ($edges.Count -eq 0) {
  Set-Content -Path $csv -Value "source_path,relation,target_path,detected_by,confidence`n" -Encoding UTF8
} else {
  $edges | Sort-Object source_path, target_path, relation | Export-Csv -Path $csv -NoTypeInformation -Encoding UTF8
}

$nodes = @{}
$edges | ForEach-Object {
  $nodes[$_.source_path] = $true
  $nodes[$_.target_path] = $true
}

$g = [pscustomobject]@{
  nodes = @($nodes.Keys | Sort-Object | ForEach-Object { @{ id = $_ } })
  edges = @($edges | ForEach-Object { @{ from = $_.source_path; to = $_.target_path; type = $_.relation } })
}
$g | ConvertTo-Json -Depth 5 | Set-Content -Path $json -Encoding UTF8

# Mermaid(100 엣지 제한)
$lines = New-Object System.Collections.Generic.List[string]
$lines.Add('```mermaid')
$lines.Add('graph LR')
$edges | Select-Object -First 100 | ForEach-Object {
  $a = $_.source_path.Replace(' ','_').Replace('/','__')
  $b = $_.target_path.Replace(' ','_').Replace('/','__')
  $lines.Add(("  {0} --> {1}" -f $a, $b))
}
$lines.Add('```')
$lines -join [Environment]::NewLine | Set-Content -Path $mm -Encoding UTF8

$summary = @{
  generated_at = (Get-Date -AsUtc -Format s) + 'Z'
  node_count   = $nodes.Count
  edge_count   = $edges.Count
  changed_only = [bool]$ChangedOnly
  out_dir      = $OutDir
}
$summary | ConvertTo-Json -Depth 3 | Set-Content -Path $idx -Encoding UTF8

Write-Host ("== relations.csv: {0} edges" -f $edges.Count)
Write-Host ("== graph.json: {0} nodes" -f $nodes.Count)

$global:LASTEXITCODE = 0
exit 0
