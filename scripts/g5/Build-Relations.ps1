# scripts/g5/Build-Relations.ps1
# 목적: 리포지토리 내 파일 간 관계를 스캔해 _inventory 산출물로 저장
# 사용법:
#   pwsh -NoProfile -File scripts/g5/Build-Relations.ps1 [-ChangedOnly] [-OutDir _inventory]
# 출력:
#   _inventory/relations.csv, graph.json, graph.mermaid.md, index.json
# 주의:
#   - 정규식 기반 1차 판: 과탐/미탐이 있을 수 있으나, 운영 안전성을 위해 "보수적"으로 추출
#   - YAML 파싱 미사용(무의존). 추후 확장 여지 있음.

[CmdletBinding()]
param(
  [switch]$ChangedOnly,
  [string]$OutDir = "_inventory"
)

$ErrorActionPreference = 'Stop'
$repo = (Get-Location).Path
$rel = Join-Path $repo $OutDir
New-Item -ItemType Directory -Force -Path $rel | Out-Null

# == 1) 스캔 대상 계산 (ChangedOnly면 git diff 기반)
function Get-TargetFiles {
  param([switch]$ChangedOnly)
  $patterns = @("**/*.ps1","**/*.psm1","**/*.psd1","**/*.js","**/*.ts","**/*.tsx","**/*.jsx","**/*.md","**/*.yml","**/*.yaml")
  $ignore = @("^\.git/","^$OutDir/","^node_modules/","^dist/","^build/")

  if ($ChangedOnly) {
    # 기본: main과 비교. 필요 시 환경에 맞게 브랜치명 변경.
    $base = $env:GITHUB_BASE_REF
    if ([string]::IsNullOrWhiteSpace($base)) { $base = "origin/main" }
    # git 없으면 전체 스캔
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
      Write-Warning "git 미존재 → 전체 스캔으로 대체"
      $ChangedOnly = $false
    } else {
      $diff = git diff --name-only $base...HEAD 2>$null
      if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($diff)) {
        Write-Warning "git diff 실패/변경없음 → 전체 스캔"
        $ChangedOnly = $false
      } else {
        $files = $diff | Where-Object {
          $p = $_.ToString().Replace("\","/")
          -not ($ignore | ForEach-Object { $p -match $_ }) -and
          ($patterns | ForEach-Object { $p -like $_ }) -contains $true
        }
        return $files
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

# == 2) 파일별 관계 추출기 (정규식 기반)
$rx = @{
  js_import   = [regex]"(?m)^\s*import\s+.*?from\s+['""](?<t>[^'""]+)['""]"
  js_require  = [regex]"(?m)require\(['""](?<t>[^'""]+)['""]\)"
  ps_dot      = [regex]"(?m)^\s*\.\s+\.?/(?<t>[^\s#]+\.ps1)\b"
  ps_call     = [regex]"(?m)^\s*&\s+\.?/(?<t>[^\s#]+\.ps1)\b"
  ps_module   = [regex]"(?im)^\s*Import-Module\s+['""]?(?<t>[^'""]+?)(['""]|\s|$)"
  md_link     = [regex]"\[(?<text>[^\]]+)\]\((?<t>[^)]+)\)"
  yml_uses    = [regex]"(?m)^\s*uses:\s*(?<t>\./[^#\s]+)"
  yml_run_ps  = [regex]"(?m)^\s*run:\s*\|?\s*$[\s\S]*?(?<t>\.?/[^ \r\n]+\.(ps1|js))"
}

function Resolve-TargetPath {
  param($src,$t)
  # 외부 패키지(ex: npm 패키지)는 파일관계에서 제외
  if ($t -match "^(node:|https?://|@|[A-Za-z0-9_-]+/[^/]+)") { return $null }
  # 확장자 없는 경우 보정은 1차판에선 생략
  $p = [System.IO.Path]::GetFullPath((Join-Path (Split-Path $src -Parent) $t))
  if ($p.StartsWith($repo)) {
    return $p.Substring($repo.Length + 1).Replace("\","/")
  }
  return $null
}

$edges = New-Object System.Collections.Generic.List[object]
$files = Get-TargetFiles -ChangedOnly:$ChangedOnly
foreach ($f in $files) {
  $full = Join-Path $repo $f
  $text = Get-Content -Raw -Encoding UTF8 $full
  foreach ($k in $rx.Keys) {
    foreach ($m in $rx[$k].Matches($text)) {
      $t = $m.Groups["t"].Value.Trim()
      $tp = Resolve-TargetPath -src $f -t $t
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

# == 3) 산출물 저장
$csv = Join-Path $rel "relations.csv"
$json = Join-Path $rel "graph.json"
$mm   = Join-Path $rel "graph.mermaid.md"
$idx  = Join-Path $rel "index.json"

$edges | Sort-Object source_path, target_path, relation | Export-Csv -Path $csv -NoTypeInformation -Encoding UTF8

$nodes = @{}
$edges | ForEach-Object { $nodes[$_.source_path]=$true; $nodes[$_.target_path]=$true }
$g = [pscustomobject]@{
  nodes = @($nodes.Keys | Sort-Object | ForEach-Object { @{ id = $_ } })
  edges = @($edges | ForEach-Object { @{ from=$_.source_path; to=$_.target_path; type=$_.relation } })
}
$g | ConvertTo-Json -Depth 5 | Set-Content -Path $json -Encoding UTF8

# 간단 Mermaid (상위 100엣지만)
$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("```mermaid")
$lines.Add("graph LR")
$edges | Select-Object -First 100 | ForEach-Object {
  $a = $_.source_path.Replace(" ","_").Replace("/","__")
  $b = $_.target_path.Replace(" ","_").Replace("/","__")
  $lines.Add("  $a --> $b")
}
$lines.Add("```")
$lines -join [Environment]::NewLine | Set-Content -Path $mm -Encoding UTF8

$summary = @{
  generated_at = (Get-Date).ToString("s")
  node_count   = $nodes.Count
  edge_count   = $edges.Count
  changed_only = [bool]$ChangedOnly
  out_dir      = $OutDir
}
$summary | ConvertTo-Json -Depth 3 | Set-Content -Path $idx -Encoding UTF8

Write-Host "== relations.csv: $($edges.Count) edges"
Write-Host "== graph.json: $($nodes.Count) nodes"
