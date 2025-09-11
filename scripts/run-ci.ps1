# Local CI Gate: lint -> tests (scoped, strict exit codes)
param()
$ErrorActionPreference = "Stop"

Write-Host "== Lint (ruff) =="
python -m ruff check infra/logging tests/contract/test_logging_contract.py
if ($LASTEXITCODE -ne 0) {
  Write-Host "Ruff failed (exit $LASTEXITCODE)" -ForegroundColor Red
  exit 2
}

Write-Host "== Tests (pytest) =="
python -m pytest -q tests/contract/test_logging_contract.py
if ($LASTEXITCODE -ne 0) {
  Write-Host "Pytest failed (exit $LASTEXITCODE)" -ForegroundColor Red
  exit 3
}

Write-Host "All checks passed."
exit 0
