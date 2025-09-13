# PS-SB6-Scaffold.ps1  (v1.3)
[CmdletBinding()] param()
$ErrorActionPreference = "Stop"

$orange = "DarkYellow"
Write-Host "[경고] Sprint-B 스캐폴딩을 현재 셸에서 연속 실행해도 안전합니다. 기존 파일은 건너뜁니다." -ForegroundColor $orange

$paths = @("domain/reporting","domain/dsl","app/reporting","infra/reporting","tests/unit/reporting")
foreach ($p in $paths) { New-Item -ItemType Directory -Path $p -Force | Out-Null }

function New-IfMissing { param([string]$Path,[string]$Content)
  if (Test-Path $Path) { Write-Host "존재: $Path (건너뜀)" }
  else { New-Item -ItemType File -Path $Path -Force | Out-Null; Set-Content -Path $Path -Value $Content -Encoding UTF8; Write-Host "생성: $Path" }
}

$domainTypes = @'
/** domain/reporting/types.ts */
export type FieldRef = { name: string; alias?: string };
export type FilterOp = "eq"|"ne"|"gt"|"lt"|"gte"|"lte"|"in"|"contains";
export type FilterExpr = { field: string; op: FilterOp; value: unknown };
export type SortSpec = { field: string; dir: "asc"|"desc" };
export type ReportSpec = {
  source: string; fields: FieldRef[]; filters?: FilterExpr[];
  groupBy?: string[]; sort?: SortSpec[]; limit?: number; format: "csv"|"json";
};
