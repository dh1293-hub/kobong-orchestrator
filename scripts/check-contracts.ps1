param()
$files = @(
  "domain\reporting\ports.ts",
  "domain\dsl\v0_4\types.ts",
  "domain\dsl\v0_4\parser.ts",
  "app\reporting\report_service.ts",
  "infra\reporting\memory_report_engine.ts",
  "ui\reporting\cli.ts"
)
$missing = $files | Where-Object { !(Test-Path $_) }
if($missing){
  Write-Host "[CHECK] Missing:`n - " + ($missing -join "`n - ") -ForegroundColor Red
  exit 2
}
Write-Host "[CHECK] Contracts & critical files OK" -ForegroundColor DarkYellow