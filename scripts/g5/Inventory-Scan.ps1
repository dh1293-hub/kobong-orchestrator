# 목적: 현재 리포 트리를 읽어 _inventory/* 로 스냅샷
# 사용: pwsh -NoProfile -File .\scripts\g5\Inventory-Scan.ps1
# 결과: _inventory/tree.csv, workflows.csv, scripts.csv

param()

$ErrorActionPreference='Stop'
$root = (Resolve-Path .).Path
$inv  = Join-Path $root "_inventory"
New-Item -ItemType Directory -Path $inv -Force | Out-Null

function Write-Csv($path, $rows) {
  $rows | Export-Csv -NoTypeInformation -Encoding UTF8 -Path $path
  Write-Host "Wrote: $path"
}

# 전체 트리
$all = Get-ChildItem -Recurse -Force -File | ForEach-Object {
  [pscustomobject]@{
    Path = $_.FullName.Substring($root.Length).TrimStart('\','/')
    Size = $_.Length
  }
}
Write-Csv (Join-Path $inv 'tree.csv') $all

# 워크플로
$wf = Get-ChildItem -Recurse -Force -File -Include *.yml,*.yaml |
  Where-Object { $_.FullName -match '\\.github\\workflows\\' -or $_.FullName -match '/\.github/workflows/' } |
  ForEach-Object {
    [pscustomobject]@{ Path=$_.FullName.Substring($root.Length).TrimStart('\','/'); Size=$_.Length }
  }
Write-Csv (Join-Path $inv 'workflows.csv') $wf

# 스크립트(g5)
$g5 = Get-ChildItem -Recurse -Force -File -Include *.ps1 |
  Where-Object { $_.FullName -match '\\scripts\\g5\\' -or $_.FullName -match '/scripts/g5/' } |
  ForEach-Object {
    [pscustomobject]@{ Path=$_.FullName.Substring($root.Length).TrimStart('\','/'); Size=$_.Length }
  }
Write-Csv (Join-Path $inv 'scripts.csv') $g5

Write-Host "== Inventory complete. Check _inventory/*.csv"
