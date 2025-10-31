#requires -Version 7.0
<#
[목적]
- 루트 ".github/workflows"의 YML만 스캔 → "주석 제외 + 단일 파일 경로만" 수집.
- 상대경로 해석: "YAML 폴더 → 레포 루트 → scripts/ → scripts/g5/ → .github/scripts/".
- 파일명 토큰(예: ak-rewrite.ps1)도 해석(대소문자 무시, scripts/** 재귀).
- '.github/workflows/inventory-ci.yml' 지정 제외.
- -ScanDepth 단계만큼 반복 루프(전체 검색) 확장. 출력은 평탄화된 파일 목록.

[사용]
pwsh -NoProfile -File .\scripts\g5\Trace-WorkflowRefs.v3.3.ps1
pwsh -NoProfile -File .\scripts\g5\Trace-WorkflowRefs.v3.3.ps1 -ScanDepth 2
#>

param(
  [string]$Root,
  [ValidateRange(1,10)]
  [int]$ScanDepth = 1
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$PSDefaultParameterValues['*:Encoding'] = 'utf8'

function Resolve-RepoRoot([string]$R){
  if ($env:GITHUB_WORKSPACE -and (Test-Path $env:GITHUB_WORKSPACE)) {
    return (Resolve-Path $env:GITHUB_WORKSPACE).Path
  }
  $git=''; try{ $git=(git rev-parse --show-toplevel 2>$null) }catch{}
  if(-not [string]::IsNullOrWhiteSpace($git)){ return (Resolve-Path $git).Path }
  if($R){ return (Resolve-Path $R).Path }
  return (Get-Location).Path
}
function To-RelPath([string]$repo,[string]$abs){
  $p = (Resolve-Path $abs -ErrorAction SilentlyContinue); if(-not $p){ return $null }
  $r = [System.IO.Path]::GetFullPath($repo)
  $a = [System.IO.Path]::GetFullPath($p.Path)
  if($a.StartsWith($r,[System.StringComparison]::OrdinalIgnoreCase)){
    return ($a.Substring($r.Length).TrimStart('\','/') -replace '\\','/')
  }
  return ($a -replace '\\','/')
}

# == 주석 제거 강화를 위한 인라인 처리 ==
function Remove-InlineComment([string]$line){
  if([string]::IsNullOrEmpty($line)){ return $line }
  $inS=$false; $inD=$false
  for($i=0; $i -lt $line.Length; $i++){
    $ch = $line[$i]
    if($ch -eq "'"){ $inS = -not $inS; continue }
    if($ch -eq '"'){ $inD = -not $inD; continue }
    if($ch -eq '#'){
      if(-not $inS -and -not $inD){
        # URL 보호: 직전 7글자 안에 http:// 또는 https:/ 가 있으면 유지
        $k = [Math]::Max(0, $i-7)
        $pre = $line.Substring($k, $i-$k).ToLower()
        if($pre.EndsWith('http://') -or $pre.EndsWith('https:/')){ continue }
        return $line.Substring(0,$i)
      }
    }
  }
  return $line
}
function Strip-LineComments([string]$text){
  $sb = New-Object System.Text.StringBuilder
  foreach($raw in ($text -split "`r?`n")){
    $t = $raw.TrimStart()
    if($t.StartsWith('#')){ continue }           # 라인 전체 주석
    $noInline = Remove-InlineComment $raw        # 인라인 주석
    [void]$sb.AppendLine($noInline)
  }
  return $sb.ToString()
}

# 정규식(작따옴표는 '' 두 번)
$PatUsesLocal = '(?mi)^\s*uses\s*:\s*(["'']?)(\./[^''"\r\n]+)\1\s*$'
$PatFileToken = '(?<![\w./-])([./\\]?(?:[\w.-]+[\\/])*[\w.-]+\.[A-Za-z0-9]{1,10})'

function Resolve-Candidate([string]$token,[string]$baseFile,[string]$repoRoot){
  if([string]::IsNullOrWhiteSpace($token)){ return $null }
  $tok = $token.Trim('"','''',' ')
  if($tok -match '://'){ return $null }                     # URL 제외
  if($tok -match '^\$|\$\{|^\(\(|\)\)|\${{'){ return $null }# 변수/토큰류 제외
  if($tok -match '[\*\?]'){ return $null }                  # 와일드카드 제외

  $yamlDir = Split-Path -Parent $baseFile
  $prefDirs = @(
    $yamlDir,
    $repoRoot,
    (Join-Path $repoRoot 'scripts'),
    (Join-Path $repoRoot 'scripts/g5'),
    (Join-Path $repoRoot '.github/scripts')
  ) | Select-Object -Unique

  $hasSep = ($tok -match '[\\/]')
  if([IO.Path]::IsPathRooted($tok)){
    $cand = (Resolve-Path $tok -ErrorAction SilentlyContinue)?.Path
    if($cand){ try{ $it=Get-Item $cand -ErrorAction Stop; if(-not $it.PSIsContainer){ return $it.FullName } }catch{} }
    return $null
  }

  if($hasSep){
    $tok2 = $tok -replace '\\','/'
    foreach($p in @((Join-Path $yamlDir $tok2),(Join-Path $repoRoot $tok2)) | Select-Object -Unique){
      $abs = (Resolve-Path $p -ErrorAction SilentlyContinue)?.Path
      if($abs){ try{ $it=Get-Item $abs -ErrorAction Stop; if(-not $it.PSIsContainer){ return $it.FullName } }catch{} }
    }
    return $null
  }

  # 파일명만 — 우선 디렉터리 탐색(대소문자 무시), 실패 시 scripts/** 재귀 검색(대소문자 무시)
  foreach($d in $prefDirs){
    $p = Join-Path $d $tok
    if(Test-Path $p -PathType Leaf){ return (Resolve-Path $p).Path }
    # 케이스 무시 비교
    if(Test-Path $d -PathType Container){
      $hit = Get-ChildItem -Path $d -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -ieq $tok } | Select-Object -First 1
      if($hit){ return $hit.FullName }
    }
  }
  $scriptsRoot = (Join-Path $repoRoot 'scripts')
  if(Test-Path $scriptsRoot -PathType Container){
    $hit = Get-ChildItem -Path $scriptsRoot -Recurse -File -ErrorAction SilentlyContinue |
      Where-Object { $_.Name -ieq $tok } | Select-Object -First 1
    if($hit){ return $hit.FullName }
  }
  return $null
}

function Expand-LocalAction([string]$baseFile,[string]$raw){
  if([string]::IsNullOrWhiteSpace($raw)){ return @() }
  $s = $raw.Trim('"','''',' ')
  if(-not ($s -like './*' -or $s -like '.\*')){ return @() }
  $baseDir = Split-Path -Parent $baseFile
  $candAbs = (Resolve-Path (Join-Path $baseDir $s) -ErrorAction SilentlyContinue)?.Path
  if(-not $candAbs){ return @() }
  $fi = Get-Item $candAbs -ErrorAction SilentlyContinue
  if(-not $fi){ return @() }
  if($fi.PSIsContainer){
    foreach($a in @('action.yml','action.yaml')){
      $p = Join-Path $fi.FullName $a
      if(Test-Path $p -PathType Leaf){ return ,$p }
    }
    return @()
  } else { return ,$fi.FullName }
}

function Find-FileCandidates([string]$repo,[string]$baseFile,[string]$rawText){
  $clean = Strip-LineComments $rawText

  # 1) uses: ./local/action → 파일로
  $uses = @()
  foreach($m in [regex]::Matches($clean, $PatUsesLocal)){
    $uses += (Expand-LocalAction $baseFile $m.Groups[2].Value)
  }

  # 2) 파일 토큰(확장자 포함) → 파일만 남김 (파일명 토큰 허용)
  $rawHits = @()
  foreach($m in [regex]::Matches($clean, $PatFileToken)){
    $hit = Resolve-Candidate $m.Groups[1].Value $baseFile $repo
    if($hit){ $rawHits += $hit }
  }

  # 3) 병합 → 상대경로 정규화
  $all = @($uses + $rawHits) | Select-Object -Unique
  $rel = foreach($x in $all){ $rp = To-RelPath $repo $x; if($rp){ $rp } }
  return ($rel | Select-Object -Unique)
}

# === MAIN ===
$RepoRoot = Resolve-RepoRoot $Root
$WfDir    = Join-Path $RepoRoot '.github/workflows'
if(-not (Test-Path $WfDir -PathType Container)){ throw "'.github/workflows' 폴더가 없습니다: $WfDir" }

$InvDir     = Join-Path $RepoRoot '_inventory'
New-Item -ItemType Directory -Force -Path $InvDir | Out-Null
$OutTxtPath = Join-Path $InvDir 'workflows.txt'

$WfFiles = @(
  Get-ChildItem -Path (Join-Path $WfDir '*.yml')  -Recurse -File -ErrorAction SilentlyContinue
  Get-ChildItem -Path (Join-Path $WfDir '*.yaml') -Recurse -File -ErrorAction SilentlyContinue
) | Where-Object {
  $_.BaseName -ne 'inventory-ci'   # ⛔ 지정 제외
} | Sort-Object FullName -Unique

$Lines = New-Object System.Collections.Generic.List[string]
$stamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ssK'
$Lines.Add("# GENERATED @ $stamp  (repo=$RepoRoot)")
$Lines.Add("# RULES: comments-excluded(inline+#start), files-only, .github/workflows only, flat, exclude=inventory-ci.yml")
$Lines.Add("")

foreach($wf in $WfFiles){
  $wfRel = To-RelPath $RepoRoot $wf.FullName
  $Lines.Add($wfRel)

  # 1차
  $wfRaw = Get-Content -LiteralPath $wf.FullName -Raw
  $level1 = Find-FileCandidates $RepoRoot $wf.FullName $wfRaw

  # 반복 루프
  $seen = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
  foreach($p in $level1){ [void]$seen.Add($p) }

  $curDepth  = 1
  $scanQueue = [System.Collections.Generic.Queue[string]]::new()
  foreach($p in $level1){ $scanQueue.Enqueue($p) }

  while($curDepth -lt $ScanDepth -and $scanQueue.Count -gt 0){
    $nextQ = [System.Collections.Generic.Queue[string]]::new()
    while($scanQueue.Count -gt 0){
      $relPath = $scanQueue.Dequeue()
      $absPath = Join-Path $RepoRoot $relPath
      if(-not (Test-Path $absPath -PathType Leaf)){ continue }
      try{ $fileRaw = Get-Content -LiteralPath $absPath -Raw -ErrorAction Stop }catch{ continue }
      $more = Find-FileCandidates $RepoRoot $absPath $fileRaw
      foreach($m in $more){ if($seen.Add($m)){ $nextQ.Enqueue($m) } }
    }
    $scanQueue = $nextQ
    $curDepth++
  }

  foreach($p in ($seen | Sort-Object)){ $Lines.Add("  - $p") }
  $Lines.Add("")
}

# 저장(PS7/PS5 모두 안전)
$__content = ($Lines -join "`r`n")
try {
  Set-Content -LiteralPath $OutTxtPath -Value $__content -Encoding utf8 -ErrorAction Stop
}
catch {
  $enc = New-Object System.Text.UTF8Encoding($false)   # UTF-8 (no BOM)
  [System.IO.File]::WriteAllText($OutTxtPath, $__content, $enc)
}

Write-Host "[OK] $($WfFiles.Count)개 워크플로 → $OutTxtPath"
