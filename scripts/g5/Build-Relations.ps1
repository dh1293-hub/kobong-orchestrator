# scripts/g5/Build-Relations.ps1
<# 
 목적: 리포지토리의 파일 연관관계를 스캔하여 _inventory 산출물 생성
 산출물:
   - _inventory/relations.csv        # source_path, relation, target_path, detected_by, confidence
   - _inventory/graph.json           # {nodes:[{id}], edges:[{from,to,type}]}
   - _inventory/graph.mermaid.md     # Mermaid 미리보기(최대 100 엣지)
   - _inventory/index.json           # {generated_at,node_count,edge_count,changed_only_effective,out_dir}
 사용법:
   pwsh -NoProfile -File scripts/g5/Build-Relations.ps1               # 전체 스캔
   pwsh -NoProfile -File scripts/g5/Build-Relations.ps1 -ChangedOnly  # 변경 파일만 (git 없으면 자동 전체)
 친절 주석:
   - 이 스크립트는 zipball 체크아웃( .git 없음 ) 환경에서도 안전하게 동작하도록 설계됨
   - 허용 확장자 기반 필터링으로 와일드카드/글롭 의존 제거
#>

[CmdletBinding()]
param(
  [switch]$ChangedOnly,
  [string]$OutDir = "_inventory"
)

$ErrorActionPreference = 'Stop'

# == 기본 경로 준비 ==
$repo = (Get-Location).Path
$out  = Join-Path $repo $OutDir
New-Item -ItemType Directory -Force -Path $out | Out-Null

# == 허용 확장자(소문자) ==
$AllowExt = @(
  '.ps1','.psm1','.psd1',
  '.js','.mjs','.cjs','.ts','.tsx','.jsx',
  '.md','.yml','.yaml'
)

# == 무시(정규식) ==
$IgnoreRx = @(
  '^\.git/','^_inventory/','^node_modules/','^dist/','^build/','^out/','^coverage/'
)

function Test-Ignored([string]$relPath) {
  foreach ($r in $IgnoreRx) { if ($relPath -match $r) { return $true } }
  return $false
}

function Get-RepoFiles {
  param([switch]$ChangedOnly)
  $effectiveChanged = $false
  $results = @()

  if ($ChangedOnly) {
    $baseRef = $env:GITHUB_BASE_REF
    if ([string]::IsNullOrWhiteSpace($baseRef)) { $baseRef = 'origin/main' }

    $gitOk = $false
    if (Get-Command git -ErrorAction SilentlyContinue) {
      try {
        $diff = git diff --name-only $baseRef...HEAD 2>$null
        if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($diff)) {
          $gitOk = $true
          $effectiveChanged = $true
          $cand = $diff -split "`n"
          foreach ($p in $cand) {
            if ([string]::IsNullOrWhiteSpace($p)) { continue }
            $rel = $p.Trim().Replace('\','/')
            if (Test-Ignored $rel) { continue }
            $ext = [System.IO.Path]::GetExtension($rel).ToLowerInvariant()
            if ($AllowExt -contains $ext) { $results += $rel }
          }
        }
      } catch { }
    }
    if (-not $gitOk) {
      Write-Host "changed_only 요청 → git 비교 불가 → 전체 스캔으로 폴백"
    }
  }

  if (-not $effectiveChanged) {
    $all = Get-ChildItem -File -Recurse -Force | ForEach-Object {
      $_.FullName.Substring($repo.Length + 1).Replace('\','/')
    }
    foreach ($rel in $all) {
      if (Test-Ignored $rel) { continue }
      $ext = [System.IO.Path]::GetExtension($rel).ToLowerInvariant()
      if ($AllowExt -contains $ext) { $results += $rel }
    }
  }

  # 중복 제거
  $results = $results | Select-Object -Unique
  return @{ files = $results; changed = $effectiveChanged }
}

# == 탐지 정규식 ==
$rx = @{
  js_import  = [regex]"(?m)^\s*import\s+.*?\sfrom\s+['""](?<t>[^'""]+)['""]"
  js_req     = [regex]"(?m)require\(['""](?<t>[^'""]+)['""]\)"
  ps_dot     = [regex]"(?m)^\s*\.\s+(?<t>(?:\.{0,2}[\\/])?[^\s#'""]+\.ps1)\b"
  ps_call    = [regex]"(?m)^\s*&\s+(?<t>(?:\.{0,2}[\\/])?[^\s#'""]+\.ps1)\b"
  ps_module  = [regex]"(?im)^\s*Import-Module\s+['""]?(?<t>[^'""]+?)(['""]|\s|$)"
  md_link    = [regex]"\[(?<text>[^\]]+)\]\((?<t>[^)]+)\)"
  yml_uses   = [regex]"(?m)^\s*uses:\s*(?<t>\./[^\s#]+)"    # 로컬 액션만
  yml_runblk = [regex]"(?s)^\s*run:\s*\|?\s*[\r\n]+(?<t>(?:\s{2,}.+[\r\n]+)+)"
}

function Resolve-PathFor([string]$src, [string]$t, [string]$kind) {
  # 외부/절대/URL/패키지는 제외
  if ($t -match "^(node:|https?://|@|[A-Za-z0-9._-]+/[A-Za-z0-9._-]+)") { return $null }
  if ($t -match "^[A-Za-z]:[\\/]" -or $t -match "^/") { return $null }
  if ($kind -eq 'ps_module' -and ($t -notmatch "[\\/]|^\.")) { return $null }  # 모듈명은 스킵(상대경로만)

  $t = $t.Trim("'`"").Trim()

  # YAML은 레포 루트 기준, 그 외는 파일 기준
  $baseDir = if ($kind -like 'yml_*') { $repo } else { Split-Path -Parent (Join-Path $repo $src) }
  $abs = [System.IO.Path]::GetFullPath((Join-Path $baseDir $t))
  if (-not $abs.StartsWith($repo)) { return $null }
  return $abs.Substring($repo.Length + 1).Replace('\','/')
}

# == 스캔 ==
$edges = New-Object System.Collections.Generic.List[object]
$scan = Get-RepoFiles -ChangedOnly:$ChangedOnly
$files = $scan.files
$changedEff = $scan.changed

foreach ($f in $files) {
  $full = Join-Path $repo $f
  $text = Get-Content -Raw -Encoding UTF8 $full

  foreach ($k in $rx.Keys) {
    if ($k -eq 'yml_runblk') {
      foreach ($m in $rx[$k].Matches($text)) {
        $blk = $m.Groups['t'].Value

        # 1) -File <path>
        foreach ($mm in [regex]::Matches($blk, "(?im)(?:^|\s)-File\s+['""]?(?<path>(?:\.{0,2}[\\/])?(?:[A-Za-z0-9._-]+[\\/])*[A-Za-z0-9._-]+\.ps1)['""]?")) {
          $tp = Resolve-PathFor $f $mm.Groups['path'].Value $k
          if ($tp) { $edges.Add([pscustomobject]@{source_path=$f;relation=$k;target_path=$tp;detected_by='regex/run/-File';confidence=0.9}) }
        }
        # 2) '-File','<path>' (배열 인자)
        foreach ($mm in [regex]::Matches($blk, "(?is)['""]-?File['""]\s*,\s*['""](?<path>(?:\.{0,2}[\\/])?(?:[A-Za-z0-9._-]+[\\/])*[A-Za-z0-9._-]+\.ps1)['""]")) {
          $tp = Resolve-PathFor $f $mm.Groups['path'].Value $k
          if ($tp) { $edges.Add([pscustomobject]@{source_path=$f;relation=$k;target_path=$tp;detected_by='regex/run/array';confidence=0.9}) }
        }
        # 3) 그냥 <path>.ps1 등장
        foreach ($mm in [regex]::Matches($blk, "(?im)(?<path>(?:\.{0,2}[\\/])?(?:[A-Za-z0-9._-]+[\\/])*[A-Za-z0-9._-]+\.ps1)")) {
          $tp = Resolve-PathFor $f $mm.Groups['path'].Value $k
          if ($tp) { $edges.Add([pscustomobject]@{source_path=$f;relation=$k;target_path=$tp;detected_by='regex/run/loose';confidence=0.7}) }
        }
      }
      continue
    }

    foreach ($m in $rx[$k].Matches($text)) {
      $t = $m.Groups['t'].Value
      $tp = Resolve-PathFor $f $t $k
      if ($tp) { $edges.Add([pscustomobject]@{source_path=$f;relation=$k;target_path=$tp;detected_by="regex/$k";confidence=0.7}) }
    }
  }
}

# == 산출물 ==
$csv = Join-Path $out "relations.csv"
$json = Join-Path $out "graph.json"
$mm   = Join-Path $out "graph.mermaid.md"
$idx  = Join-Path $out "index.json"

if ($edges.Count -eq 0) {
  Set-Content -Path $csv -Encoding UTF8 -Value "source_path,relation,target_path,detected_by,confidence`n"
} else {
  $edges | Sort-Object source_path, target_path, relation | Export-Csv -NoTypeInformation -Encoding UTF8 -Path $csv
}

$nodes = @{}
$edges | ForEach-Object { $nodes[$_.source_path]=$true; $nodes[$_.target_path]=$true }

$g = [pscustomobject]@{
  nodes = @($nodes.Keys | Sort-Object | ForEach-Object { @{ id = $_ } })
  edges = @($edges | ForEach-Object { @{ from = $_.source_path; to = $_.target_path; type = $_.relation } })
}
$g | ConvertTo-Json -Depth 5 | Set-Content -Path $json -Encoding UTF8

$mmLines = New-Object System.Collections.Generic.List[string]
$mmLines.Add('```mermaid'); $mmLines.Add('graph LR')
$edges | Select-Object -First 100 | ForEach-Object {
  $a=$_.source_path.Replace(' ','_').Replace('/','__')
  $b=$_.target_path.Replace(' ','_').Replace('/','__')
  $mmLines.Add("  $a --> $b")
}
$mmLines.Add('```')
$mmLines -join [Environment]::NewLine | Set-Content -Path $mm -Encoding UTF8

$summary = [pscustomobject]@{
  generated_at          = (Get-Date -AsUtc -Format s) + 'Z'
  node_count            = $nodes.Count
  edge_count            = $edges.Count
  changed_only_effective= [bool]$changedEff
  out_dir               = $OutDir
}
$summary | ConvertTo-Json -Depth 3 | Set-Content -Path $idx -Encoding UTF8

Write-Host ("== relations.csv edges: {0}" -f $edges.Count)
Write-Host ("== graph.json nodes : {0}" -f $nodes.Count)
exit 0
