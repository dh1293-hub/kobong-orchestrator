# APPLY IN SHELL
#requires -Version 7.0
param([string]$Root='')
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'

# 1) 레포 루트
$repo = if ($Root) { (Resolve-Path $Root).Path } else { (git rev-parse --show-toplevel 2>$null) }
if (-not $repo) { $repo = (Get-Location).Path }

# 2) 대상 파일 수집 (제외 디렉토리/확장자 필터)
$exclude = @('node_modules','dist','build','coverage','.git','.venv','venv','out','target','bin','obj')
$extRe   = '\.(ts|tsx|js|jsx|py|java|md|ya?ml|json|ps1)$'

$files = @()
try {
  $files = (git -C $repo ls-files 2>$null) -split "`n"
} catch {}
if (-not $files -or $files.Count -eq 0) {
  $files = Get-ChildItem -Path $repo -Recurse -File -ErrorAction SilentlyContinue |
           Where-Object { $_.FullName -notmatch '\\(' + ($exclude -join '|') + ')\\' } |
           Where-Object { $_.Name -match $extRe } |
           Select-Object -ExpandProperty FullName
} else {
  $ex = '^(' + ($exclude -join '|').Replace('.','\.') + ')/'
  $files = $files | Where-Object { $_ -match $extRe -and $_ -notmatch $ex } | ForEach-Object { Join-Path $repo $_ }
}

# 3) LIVE 블록 추출 (안전 가드 강화)
$rx = [regex]'AK-LIVE-BEGIN(?s)(.*?)AK-LIVE-END'
$blocks = New-Object System.Collections.Generic.List[object]
$stat = [ordered]@{ scanned=0; missing=0; empty=0; large=0; skippedNoMarker=0 }

foreach ($path in $files) {
  if (-not (Test-Path $path)) { $stat.missing++; continue }
  $stat.scanned++

  # 대용량 파일은 건너뛰기(> 2 MB)
  try { if ((Get-Item $path).Length -gt 2MB) { $stat.large++; continue } } catch { continue }

  # 안전 읽기
  $text = $null
  try { $text = Get-Content -Raw -Path $path -Encoding UTF8 -ErrorAction Stop } catch { continue }
  if ($null -eq $text -or $text.Length -eq 0) { $stat.empty++; continue }

  # 마커 없으면 스킵(빠른 체크)
  if ($text.IndexOf('AK-LIVE-BEGIN', [System.StringComparison]::Ordinal) -lt 0) { $stat.skippedNoMarker++; continue }

  # 정규식 매칭 (널 불가 보장)
  $ms = $rx.Matches($text)
  if ($ms.Count -eq 0) { continue }

  $rel = [System.IO.Path]::GetRelativePath($repo, $path)
  foreach ($m in $ms) {
    $body = $m.Groups[1].Value
    if ([string]::IsNullOrWhiteSpace($body)) { continue }
    $blocks.Add([pscustomobject]@{ file = $rel; body = $body.Trim() })
  }
}

# 4) 결과 저장
$outDir = Join-Path $repo '.kobong'; New-Item -ItemType Directory -Force -Path $outDir | Out-Null
$out = Join-Path $outDir 'live.md'

if ($blocks.Count -gt 0) {
  $md = ($blocks | ForEach-Object { "### $($_.file)`n```````n$($_.body)`n```````n" }) -join "`n"
  $md | Out-File $out -Encoding utf8
  Write-Host "[AK-LIVE] extracted $($blocks.Count) block(s) → $out"
} else {
  @"
*(empty)*

scanned   : $($stat.scanned)
missing   : $($stat.missing)
empty     : $($stat.empty)
large     : $($stat.large)
no-marker : $($stat.skippedNoMarker)
"@ | Out-File $out -Encoding utf8
  Write-Host "[AK-LIVE] no blocks → wrote placeholder → $out"
}

