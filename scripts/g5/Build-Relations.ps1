# scripts/g5/Build-Relations.ps1
# 목적: 리포 파일 간 관계 스캔 → _inventory 산출물 저장
# 사용법:
#   pwsh -NoProfile -File scripts/g5/Build-Relations.ps1            # 전체 스캔
#   pwsh -NoProfile -File scripts/g5/Build-Relations.ps1 -ChangedOnly  # 변경만(기본 비교: origin/main)
# 출력물:
#   _inventory/relations.csv, graph.json, graph.mermaid.md, index.json
# 테스트:
#   - 로컬 act: act -n -j build-relations
#   - actionlint: docker run --rm -v "${PWD}:/repo" -w /repo rhysd/actionlint:latest -color
# 안전:
#   - git 명령 실패 시 전체 스캔으로 폴백
#   - 마지막에 $LASTEXITCODE=0 으로 정리(워크플로 단계 실패 방지)

[CmdletBinding()]
param(
  [switch]$ChangedOnly,
  [string]$OutDir = "_inventory"
)

$ErrorActionPreference = 'Stop'
$repo = (Get-Location).Path
$rel = Join-Path $repo $OutDir
New-Item -ItemType Directory -Force -Path $rel | Out-Null

function Get-TargetFiles {
  param([switch]$ChangedOnly)
  $patterns = @("**/*.ps1","**/*.psm1","**/*.psd1","**/*.js","**/*.ts","**/*.tsx","**/*.jsx","**/*.md","**/*.yml","**/*.yaml")
  $ignore = @("^\.git/","^$OutDir/","^node_modules/","^dist/","^build/")

  if ($ChangedOnly) {
    $base = $env:GITHUB_BASE_REF
    if ([string]::IsNullOrWhiteSpace($base)) { $base = "origin/main" }
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
        # 네이티브 커맨드 종료코드 정리
        $global:LASTEXITCODE = 0
        return $files
      }
    }
  }

  $all = Get-ChildItem -Recurse -File -Force | ForEach-Object {
    $_.FullName.Substring($repo.Length + 1).Replace("\","/")
  }
  $all | Where-Object {
    $p = $_
    -not ($ignore | ForEach-Object { $p -match $_ }) -and
    ($patterns | ForEach-Object { $p -like $_ }) -contains $true
  }
}

# === 관계 추출기 (정규식 1차판)
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
  if ($t -match "^(node:|https?://|@|[A-Za-z0-9_-]+/[^/]+)") { return $null }
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

# === 산출물 저장
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
  generated_at = Get-Date -Format s
  generated_at = (Get-Date -AsUtc -Format s) + 'Z'
  node_count   = $nodes.Count
  edge_count   = $edges.Count
  changed_only = [bool]$ChangedOnly
  out_dir      = $OutDir
}
$summary | ConvertTo-Json -Depth 3 | Set-Content -Path $idx -Encoding UTF8

Write-Host "== relations.csv: $($edges.Count) edges"
Write-Host "== graph.json: $($nodes.Count) nodes"

# 단계 종료코드 안전 보장
$global:LASTEXITCODE = 0
exit 0
