# Kobong-Orchestrator-VIP — 전수 인벤토리 수집 (PS7) v1.5 Minimal Safe
# 목적: "파일명과 경로"만 수집 (콘텐츠 미접근, 파일 손상 위험 0)
#inventory.ps1
#requires -Version 7.0
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Continue'

# 경로 설정/자가복구
if (-not (Get-Variable -Name Root -ErrorAction SilentlyContinue) -or [string]::IsNullOrWhiteSpace($Root)) {
  $Root = 'D:\ChatGPT5_AI_Link\dosc\Kobong-Orchestrator-VIP'
}
if (-not (Test-Path -LiteralPath $Root -PathType Container)) { Write-Error "[fail] Root 경로가 없습니다: $Root"; return }
if (-not (Get-Variable -Name Out  -ErrorAction SilentlyContinue) -or [string]::IsNullOrWhiteSpace($Out))  {
  $Out  = Join-Path $Root '_inventory'
}
if (-not (Test-Path -LiteralPath $Out)) { New-Item -ItemType Directory -Force -Path $Out | Out-Null }

# 수집(디렉터리 엔트리 메타만 열람)
$gciErr = $null
$files = Get-ChildItem -LiteralPath $Root -File -Recurse -Force -ErrorAction SilentlyContinue -ErrorVariable +gciErr
$rows = foreach ($f in $files) {
  [pscustomobject]@{
    FullPath     = $f.FullName
    RelativePath = $f.FullName.Substring($Root.Length).TrimStart('\')
    Directory    = $f.DirectoryName
    Name         = $f.Name
  }
}

# 저장
$csv = Join-Path $Out 'inventory_paths.csv'
$txt = Join-Path $Out 'inventory_paths.txt'
$rows | Sort-Object RelativePath | Export-Csv -NoTypeInformation -Encoding UTF8 -Path $csv
$rows | Sort-Object RelativePath | ForEach-Object { $_.FullPath } | Set-Content -Path $txt -Encoding UTF8

# 오류(있을 때만)
if ($gciErr -and $gciErr.Count -gt 0) {
  $gciErr | Select-Object Exception, CategoryInfo, TargetObject |
    Export-Csv -NoTypeInformation -Encoding UTF8 -Path (Join-Path $Out 'inventory_errors.csv')
}

Write-Host "[OK] Files: $($rows.Count) → $csv, $txt" -ForegroundColor Green