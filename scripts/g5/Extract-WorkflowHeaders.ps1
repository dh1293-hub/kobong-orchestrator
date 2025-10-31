#requires -Version 7.0
<#
[목적]  #주석(친절한)
- .github/workflows/*.yml(yaml) 파일들의 "머리 주석(파일 시작부)"만 수집해서 Markdown으로 정리.
- 머리 주석이 없는 파일은 "완전히 제외".
- 머리 주석 패턴 2종:
  1) 시작부 연속 `# ...` 라인
  2) 시작부 펜스 블록: 첫 비공백 라인이 ``` 로 시작하고, 다음 ``` 를 만날 때까지

[출력]
- -Out 경로(기본 ./_inventory/workflow-headers.md)로 UTF-8 저장
- 본문은 모두 ```text 코드블록으로 감싸 "문자 크기/진하기"를 통일

[사용법]
pwsh -NoProfile -File .\scripts\g5\Extract-WorkflowHeaders.v1.2.ps1 -Out .\_inventory\workflow-headers.md
#>

param(
  [string]$Root,
  [string]$Workflows = ".github/workflows",
  [string]$Out = "./_inventory/workflow-headers.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$PSDefaultParameterValues['*:Encoding'] = 'utf8'

function Resolve-RepoRoot([string]$R){
  if ($env:GITHUB_WORKSPACE -and (Test-Path $env:GITHUB_WORKSPACE)) { return (Resolve-Path $env:GITHUB_WORKSPACE).Path }
  $git=''; try{ $git=(git rev-parse --show-toplevel 2>$null) }catch{}
  if($git){ return (Resolve-Path $git).Path }
  if($R){ return (Resolve-Path $R).Path }
  return (Get-Location).Path
}
function To-Rel([string]$root,[string]$abs){
  $p = (Resolve-Path $abs -ErrorAction SilentlyContinue); if(-not $p){ return $abs }
  $r = [IO.Path]::GetFullPath($root); $a = [IO.Path]::GetFullPath($p)
  if($a.StartsWith($r,[StringComparison]::OrdinalIgnoreCase)){ return ($a.Substring($r.Length).TrimStart('\','/') -replace '\\','/') }
  return ($a -replace '\\','/')
}

function Get-HeadComment([string]$file){
  $raw = Get-Content -LiteralPath $file -Raw
  if(-not $raw){ return $null }
  $lines = $raw -split "`r?`n"
  if($lines.Length -gt 0){ $lines[0] = $lines[0].TrimStart([char]0xFEFF) }  # UTF-8 BOM 제거

  # 1) 시작부 공백 라인 스킵
  $i = 0
  while($i -lt $lines.Length -and [string]::IsNullOrWhiteSpace($lines[$i])){ $i++ }
  if($i -ge $lines.Length){ return $null }

  # 2) 펜스 블록( ``` ) 우선 인식
  if($lines[$i] -match '^\s*```'){
    $buf = New-Object System.Collections.Generic.List[string]
    $i++
    for(; $i -lt $lines.Length; $i++){
      if($lines[$i] -match '^\s*```'){ break }  # 닫힘 펜스
      $buf.Add($lines[$i])
    }
    $txt = ($buf -join "`n").Trim()
    return ([string]::IsNullOrWhiteSpace($txt)) ? $null : $txt
  }

  # 3) 연속 # 주석 블록
  if($lines[$i] -notmatch '^\s*#'){ return $null }
  $buf2 = New-Object System.Collections.Generic.List[string]
  for(; $i -lt $lines.Length; $i++){
    $ln = $lines[$i]
    if($ln -match '^\s*#(.*)$'){
      $buf2.Add( ($Matches[1]).TrimStart() )   # 앞의 '# ' 제거
    } else { break }
  }
  $txt2 = ($buf2 -join "`n").Trim()
  return ([string]::IsNullOrWhiteSpace($txt2)) ? $null : $txt2
}

# === MAIN ===
$root = Resolve-RepoRoot $Root
$wfDir = Join-Path $root $Workflows
if(-not (Test-Path $wfDir -PathType Container)){ throw "not found: $wfDir" }

$files = @(
  Get-ChildItem -Path (Join-Path $wfDir '*.yml')  -Recurse -File -ErrorAction SilentlyContinue
  Get-ChildItem -Path (Join-Path $wfDir '*.yaml') -Recurse -File -ErrorAction SilentlyContinue
) | Where-Object { $_.BaseName -ne 'inventory-ci' } | Sort-Object FullName -Unique

$lines = New-Object System.Collections.Generic.List[string]
$stamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ssK'
$lines.Add("# Workflow Header Comments")
$lines.Add("")
$lines.Add("> Generated @ $stamp (`.github/workflows only, exclude=inventory-ci.yml`)")
$lines.Add("")

foreach($f in $files){
  $head = Get-HeadComment $f.FullName
  if(-not $head){ continue }  # 머리 주석 없는 파일은 제외!

  $rel = To-Rel $root $f.FullName
  $lines.Add(('## `{0}`' -f $rel))   # ← 백틱 출력은 -f 사용
  $lines.Add("")
  $lines.Add("```text")              # 크기/진하기 통일(코드블록)
  $lines.Add($head)
  $lines.Add("```")
  $lines.Add("")
}

# 저장(PS7/PS5 안전)
$md = ($lines -join "`r`n")
$inv = Join-Path $root "_inventory"; New-Item -ItemType Directory -Force -Path $inv | Out-Null
try { Set-Content -LiteralPath $Out -Value $md -Encoding utf8 -ErrorAction Stop }
catch { $enc = New-Object System.Text.UTF8Encoding($false); [IO.File]::WriteAllText($Out,$md,$enc) }

Write-Host "[OK] header doc → $Out"
