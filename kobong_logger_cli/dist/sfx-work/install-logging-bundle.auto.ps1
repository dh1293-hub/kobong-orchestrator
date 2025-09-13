# install-logging-bundle.auto.ps1 (embedded)
param([string]$Bundle="", [string]$Target=".", [switch]$WithActions, [switch]$Renormalize)
$ErrorActionPreference='Stop'; Set-StrictMode -Version Latest
function Write-NoBom([string]$Path,[string]$Content){$d=Split-Path -Parent $Path; if([string]::IsNullOrWhiteSpace($d)){$d='.'}; if(-not(Test-Path $d)){New-Item -ItemType Directory -Force -Path $d|Out-Null}; [IO.File]::WriteAllText($Path,$Content,(New-Object System.Text.UTF8Encoding($false)))}
$here = Split-Path -Parent $PSCommandPath
if ([string]::IsNullOrWhiteSpace($Bundle)) {
  $cands = @(
    (Join-Path $here 'kobong-logging-bundle.zip'),
    (Join-Path $here 'dist\kobong-logging-bundle.zip'),
    (Join-Path (Get-Location) 'kobong-logging-bundle.zip'),
    (Join-Path (Get-Location) 'dist\kobong-logging-bundle.zip')
  ) | Where-Object { Test-Path $_ }
  if ($cands.Count -eq 0) { throw "Bundle not found. Place 'kobong-logging-bundle.zip' next to the EXE or pass -Bundle." }
  $Bundle = $cands[0]
}
$Target = if ([string]::IsNullOrWhiteSpace($Target)) { (Get-Location).Path } else { $Target }
$Tmp = Join-Path $env:TEMP ("kobong-" + [guid]::NewGuid()); New-Item -ItemType Directory -Force -Path $Tmp | Out-Null
Expand-Archive -Path $Bundle -DestinationPath $Tmp -Force
$keep = @('infra','domain','tests','scripts','requirements.contract-tests.txt','.gitattributes')
foreach ($k in $keep) { $src = Join-Path $Tmp $k; if (Test-Path $src) { Copy-Item $src -Destination (Join-Path $Target $k) -Recurse -Force } }
Get-ChildItem -Path $Target -Recurse -File -Include *.py,*.ps1,*.json,*.txt,*.md,*.yml,*.yaml |
  ForEach-Object { $t = Get-Content -LiteralPath $_.FullName -Raw; [IO.File]::WriteAllText($_.FullName,$t,(New-Object System.Text.UTF8Encoding($false))) }
if ($WithActions) {
  $wfDir = Join-Path $Target '.github\workflows'; New-Item -ItemType Directory -Force -Path $wfDir | Out-Null
  $yml = @"
name: contract-tests
on:
  push: { branches: [ main ] }
  pull_request: { branches: [ main ] }
jobs:
  tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with: { python-version: '3.11' }
      - name: Install deps
        run: python -m pip install -q -r requirements.contract-tests.txt --disable-pip-version-check
      - name: Run contract tests
        env:
          APP_TZ: Asia/Seoul
        run: python -m pytest -q tests/contract
"@
  Write-NoBom (Join-Path $wfDir 'contract-tests.yml') $yml
}
if ($Renormalize) {
  Push-Location $Target
  try { git config core.autocrlf false | Out-Null; git add --renormalize . | Out-Null; git commit -m "chore(repo): normalize EOL via .gitattributes" | Out-Null } catch {}
  Pop-Location
}
$runner = Join-Path $Target 'scripts\run-contract-tests.ps1'
if (Test-Path $runner) {
  $pwsh = (Get-Command pwsh -ErrorAction SilentlyContinue)
  if ($pwsh) { & pwsh -File $runner } else { & powershell.exe -ExecutionPolicy Bypass -File $runner }
  $code = $LASTEXITCODE
  if ($code -eq 0) { Write-Host "pytest exit code = 0 (OK)" -ForegroundColor Green } else { Write-Host "pytest exit code = $code" -ForegroundColor Red; exit $code }
} else {
  Write-Host "[WARN] runner not found; skipped tests" -ForegroundColor DarkYellow
}