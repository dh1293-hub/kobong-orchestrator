#requires -Version 7.0
<#
[목적] .github/workflows/*.yml(yaml)의 "머리 주석(파일 시작부 연속 # 라인)"만 수집해 MD로 출력
[출력] -Out 로 지정한 경로(기본: ./_inventory/workflow-headers.md) UTF-8
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
  # UTF-8 BOM 제거
  if($lines.Length -gt 0){ $lines[0] = $lines[0].TrimStart([char]0xFEFF) }
  # 시작부 빈 줄 스킵
  $i = 0; while($i -lt $lines.Length -and [string]::IsNullOrWhiteSpace($lines[$i])){ $i++ }
  if($i -ge $lines.Length){ return $null }
  if($lines[$i] -notmatch '^\s*#'){ return $null }

  $buf = New-Object System.Collections.Generic.List[string]
  for(; $i -lt $lines.Length; $i++){
    $ln = $lines[$i]
    if($ln -match '^\s*#(.*)$'){
      # 앞의 '# ' 제거하여 본문만
      $buf.Add( ($Matches[1]).TrimStart() )
    } else {
      break
    }
  }
  $txt = ($buf -join "`n").TrimEnd()
  if([string]::IsNullOrWhiteSpace($txt)){ return $null }
  return $txt
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
$lines.Add("> Generated @ $stamp (`$Workflows only, exclude=inventory-ci.yml`)")
$lines.Add("")

foreach($f in $files){
  $rel = To-Rel $root $f.FullName
  $head = Get-HeadComment $f.FullName
  $lines.Add(('## `{0}`' -f $rel))

  if($head){
    $lines.Add("")
    $lines.Add($head)          # 주석 본문을 그대로 MD 본문으로
    $lines.Add("")
  } else {
    $lines.Add("")
    $lines.Add("_(no header comment)_")
    $lines.Add("")
  }
}

# 저장(PS7/PS5 모두 안전)
$md = ($lines -join "`r`n")
$inv = Join-Path $root "_inventory"; New-Item -ItemType Directory -Force -Path $inv | Out-Null
try { Set-Content -LiteralPath $Out -Value $md -Encoding utf8 -ErrorAction Stop }
catch { $enc = New-Object System.Text.UTF8Encoding($false); [IO.File]::WriteAllText($Out,$md,$enc) }

Write-Host "[OK] header doc → $Out"
