# scripts/g5/klc-aggregate.ps1 — KLC one-liner 집계
param([string]$Root = (Split-Path -Parent $PSScriptRoot))
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$targets = @(
  Join-Path $Root "automation_logs",
  Join-Path $Root "logs"
)
$rx = 'KLC\s*\|\s*traceId=.*?\|\s*durationMs=.*?\|\s*exitCode=.*?\|\s*anchorHash=\d+'
$rows = New-Object System.Collections.Generic.List[object]
foreach($t in $targets){
  if(-not (Test-Path $t)) { continue }
  Get-ChildItem -Recurse -File -Path $t -ErrorAction SilentlyContinue |
    ForEach-Object {
      $txt = Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue
      if([string]::IsNullOrWhiteSpace($txt)) { return }
      $m = [regex]::Matches($txt,$rx,[System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
      foreach($mm in $m){
        $rows.Add([pscustomobject]@{
          File = $_.FullName
          Line = $mm.Value.Trim()
          Ts   = (Get-Item $_.FullName).LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss')
        })
      }
    }
}
$outDir = Join-Path $Root "_klc"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
$csv = Join-Path $outDir ("klc_agg_" + (Get-Date -Format 'yyyyMMdd_HHmmss') + ".csv")
$rows | Export-Csv -NoTypeInformation -Encoding UTF8 -Path $csv
Write-Host "[OK] KLC rows: $($rows.Count) → $csv"
