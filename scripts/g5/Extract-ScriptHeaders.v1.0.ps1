#requires -Version 7.0
# [목적] scripts/g5/**/*.ps1 의 "머리 주석(파일 시작부)"만 수집해 Markdown으로 정리
# [규칙]
#   - 머리 주석이 없는 스크립트는 제외
#   - 머리 주석 패턴:
#       (A) 시작부 연속 '# ...' 라인
#       (B) 시작부 펜스 블록: 첫 비공백 라인이 ``` 로 시작해 다음 ``` 전까지
#       (C) PowerShell 블록 주석: 시작부에 오는 <# ... #> (실제 스크립트에서 사용된 유형)
#       (D) 첫 줄이 shebang('#!')이면 한 줄 스킵 후 (A/B/C) 적용
# [산출] ./_inventory/script-headers.md (UTF-8, 덮어쓰기) — 본문은 ```text 코드블록로 통일
# [사용]
#   pwsh -NoProfile -File .\scripts\g5\Extract-ScriptHeaders.v1.0.1.ps1 `
#     -ScriptsDir "scripts/g5" -Out "./_inventory/script-headers.md"

param(
  [string]$Root,
  [string]$ScriptsDir = "scripts/g5",
  [string]$Out = "./_inventory/script-headers.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$PSDefaultParameterValues['*:Encoding'] = 'utf8'

function Resolve-RepoRoot([string]$R){
  if ($env:GITHUB_WORKSPACE -and (Test-Path $env:GITHUB_WORKSPACE)) {
    return (Resolve-Path $env:GITHUB_WORKSPACE).Path
  }
  $git=''; try{ $git=(git rev-parse --show-toplevel 2>$null) }catch{}
  if($git){ return (Resolve-Path $git).Path }
  if($R){ return (Resolve-Path $R).Path }
  return (Get-Location).Path
}
function To-Rel([string]$root,[string]$abs){
  $p = (Resolve-Path $abs -ErrorAction SilentlyContinue); if(-not $p){ return $abs }
  $r = [IO.Path]::GetFullPath($root); $a = [IO.Path]::GetFullPath($p)
  if($a.StartsWith($r,[StringComparison]::OrdinalIgnoreCase)){
    return ($a.Substring($r.Length).TrimStart('\','/') -replace '\\','/')
  }
  return ($a -replace '\\','/')
}

function Get-PS1Header([string]$file){
  $raw = Get-Content -LiteralPath $file -Raw
  if(-not $raw){ return $null }
  $lines = $raw -split "`r?`n"
  if($lines.Length -gt 0){ $lines[0] = $lines[0].TrimStart([char]0xFEFF) }  # UTF-8 BOM 제거

  # 시작부 공백 스킵
  $i = 0
  while($i -lt $lines.Length -and [string]::IsNullOrWhiteSpace($lines[$i])){ $i++ }
  if($i -ge $lines.Length){ return $null }

  # (D) shebang
  if($lines[$i] -match '^\s*#!'){
    $i++
    while($i -lt $lines.Length -and [string]::IsNullOrWhiteSpace($lines[$i])){ $i++ }
    if($i -ge $lines.Length){ return $null }
  }

  # (B) 시작부 펜스 블록: ```
  if($lines[$i] -match '^\s*```'){
    $buf = New-Object System.Collections.Generic.List[string]
    $i++
    for(; $i -lt $lines.Length; $i++){
      if($lines[$i] -match '^\s*```'){ break }
      $buf.Add($lines[$i])
    }
    $txt = ($buf -join "`n").Trim()
    return ([string]::IsNullOrWhiteSpace($txt)) ? $null : $txt
  }

  # (C) 시작부 PowerShell 블록 주석: <# ... #>
  if($lines[$i] -match '^\s*<\#'){
    $bufC = New-Object System.Collections.Generic.List[string]
    # 현재 줄(<# 뒤)을 포함
    $ln0 = $lines[$i]
    $lin = ($ln0 -replace '^\s*<\#','')
    if($lin -match '\#>'){
      $bufC.Add( ($lin -replace '\#>.*$','').TrimEnd() )
    } else {
      $bufC.Add($lin)
      $i++
      for(; $i -lt $lines.Length; $i++){
        if($lines[$i] -match '^\s*\#>'){
          $bufC.Add( ($lines[$i] -replace '^\s*\#>','') )
          break
        }
        $bufC.Add($lines[$i])
      }
    }
    $txtC = ($bufC -join "`n").Trim()
    return ([string]::IsNullOrWhiteSpace($txtC)) ? $null : $txtC
  }

  # (A) 연속 # 라인
  if($lines[$i] -notmatch '^\s*#'){ return $null }
  $bufA = New-Object System.Collections.Generic.List[string]
  for(; $i -lt $lines.Length; $i++){
    $ln = $lines[$i]
    if($ln -match '^\s*#(.*)$'){
      $bufA.Add( ($Matches[1]).TrimStart() )
    } else { break }
  }
  $txtA = ($bufA -join "`n").Trim()
  return ([string]::IsNullOrWhiteSpace($txtA)) ? $null : $txtA
}

# === MAIN ===
$root = Resolve-RepoRoot $Root
$srcDir = Join-Path $root $ScriptsDir
if(-not (Test-Path $srcDir -PathType Container)){ throw "not found: $srcDir" }

$files = Get-ChildItem -Path $srcDir -Recurse -Filter '*.ps1' -File -ErrorAction SilentlyContinue |
         Sort-Object FullName -Unique

$lines = New-Object System.Collections.Generic.List[string]
$stamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ssK'
$lines.Add('# Script Header Comments (scripts/g5)')
$lines.Add('')
$lines.Add(('> Generated @ {0} (`{1}/**/*.ps1`, head comments only)' -f $stamp, $ScriptsDir))
$lines.Add('')

foreach($f in $files){
  $head = Get-PS1Header $f.FullName
  if(-not $head){ continue }   # 머리 주석 없는 파일 제외

  $rel = To-Rel $root $f.FullName
  $lines.Add(('## `{0}`' -f $rel))
  $lines.Add('')
  $lines.Add('```text')    # 삼중 백틱은 홑따옴표로!
  $lines.Add($head)
  $lines.Add('```')
  $lines.Add('')
}

# 저장(PS7/PS5 안전)
$md = ($lines -join "`r`n")
$inv = Join-Path $root "_inventory"; New-Item -ItemType Directory -Force -Path $inv | Out-Null
try { Set-Content -LiteralPath $Out -Value $md -Encoding utf8 -ErrorAction Stop }
catch { $enc = New-Object System.Text.UTF8Encoding($false); [IO.File]::WriteAllText($Out,$md,$enc) }

Write-Host "[OK] script header doc → $Out"
