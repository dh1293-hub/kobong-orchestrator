# build-oneclick-installer.ps1 — One-click SFX EXE builder (7-Zip → fallback to IExpress)
# 사용: pwsh -NoProfile -ExecutionPolicy Bypass -File .\build-oneclick-installer.ps1
$ErrorActionPreference='Stop'; Set-StrictMode -Version Latest
$ROOT = (Get-Location).Path
[Environment]::CurrentDirectory = $ROOT

function Write-NoBom([string]$Path,[string]$Content) {
  $dir = Split-Path -Parent $Path; if ([string]::IsNullOrWhiteSpace($dir)){$dir='.'}
  if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
  [IO.File]::WriteAllText($Path,$Content,(New-Object System.Text.UTF8Encoding($false)))
}

# ── 0) 도구 탐색 ─────────────────────────────────────────────────────────────
$SevenZip = @(
  "${env:ProgramFiles}\7-Zip\7z.exe",
  "${env:ProgramW6432}\7-Zip\7z.exe",
  "${env:ProgramFiles(x86)}\7-Zip\7z.exe"
) | Where-Object { Test-Path $_ } | Select-Object -First 1

$IExpress = Join-Path $env:WINDIR "System32\iexpress.exe"
$HasIExpress = Test-Path $IExpress

# ── 1) kobong-logging 번들 ZIP 준비(없으면 생성) ───────────────────────────────
$Dist = Join-Path $ROOT 'dist'; New-Item -ItemType Directory -Force -Path $Dist | Out-Null
$BundleZip = Join-Path $Dist 'kobong-logging-bundle.zip'

function Make-Bundle {
  $exp = Join-Path $ROOT 'scripts\export-logging-bundle.ps1'
  if (Test-Path $exp) { pwsh -NoProfile -ExecutionPolicy Bypass -File $exp; return }

  # 간이 번들(레포에 있는 파일들 복사)
  $tmp = Join-Path $Dist 'bundle.stage'; if (Test-Path $tmp){Remove-Item $tmp -Recurse -Force}
  New-Item -ItemType Directory -Force -Path $tmp | Out-Null
  $files = @(
    'infra\logging\json_logger.py',
    'infra\__init__.py',
    'infra\logging\__init__.py',
    'domain\contracts\logging\v1.schema.json',
    'tests\contract\test_logging_contract.py',
    'scripts\setup-env.ps1',
    'scripts\run-contract-tests.ps1',
    'requirements.contract-tests.txt',
    '.gitattributes'
  ) | Where-Object { Test-Path $_ }
  foreach ($f in $files) {
    $dst = Join-Path $tmp $f
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $dst) | Out-Null
    Copy-Item $f $dst -Force
  }
  # 무BOM 강제
  Get-ChildItem -Path $tmp -Recurse -File -Include *.py,*.ps1,*.json,*.txt,*.md,*.yml,*.yaml |
    ForEach-Object { $t=Get-Content -LiteralPath $_.FullName -Raw; [IO.File]::WriteAllText($_.FullName,$t,(New-Object System.Text.UTF8Encoding($false))) }
  if (Test-Path $BundleZip) { Remove-Item $BundleZip -Force }
  Compress-Archive -Path (Join-Path $tmp '*') -DestinationPath $BundleZip
}
if (-not (Test-Path $BundleZip)) { Make-Bundle }

# ── 2) 공통 페이로드 준비(설치 스크립트, 런처, 번들) ───────────────────────────
$Work = Join-Path $Dist 'sfx-work'; if (Test-Path $Work){Remove-Item $Work -Recurse -Force}
New-Item -ItemType Directory -Force -Path $Work | Out-Null

$InstallerPs1 = @'
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
'@
Write-NoBom (Join-Path $Work 'install-logging-bundle.auto.ps1') $InstallerPs1

$RunCmd = @'
@echo off
setlocal
set SCRIPT=%~dp0install-logging-bundle.auto.ps1
if exist "%ProgramFiles%\PowerShell\7\pwsh.exe" (
  "%ProgramFiles%\PowerShell\7\pwsh.exe" -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%" -WithActions -Renormalize
) else (
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%" -WithActions -Renormalize
)
endlocal
'@
Write-NoBom (Join-Path $Work 'run.cmd') $RunCmd

Copy-Item $BundleZip (Join-Path $Work 'kobong-logging-bundle.zip') -Force

# ── 3) EXE 생성: 7-Zip 있으면 7z SFX, 없으면 IExpress ─────────────────────────
$OutExe = Join-Path $Dist 'KobongLoggerSetup.exe'
if (Test-Path $OutExe) { Remove-Item $OutExe -Force }

if ($SevenZip) {
  # 7-Zip SFX 경로
  $SfxModule = @(
    (Join-Path (Split-Path $SevenZip -Parent) '7zsd.sfx'),
    (Join-Path (Split-Path $SevenZip -Parent) '7z.sfx')
  ) | Where-Object { Test-Path $_ } | Select-Object -First 1
  if (-not $SfxModule) { Write-Host "[WARN] SFX module not found, fallback to IExpress." -ForegroundColor DarkYellow; $SevenZip=$null }
}

if (-not $SevenZip -and -not $HasIExpress) {
  throw "Neither 7-Zip SFX nor IExpress available. Please install 7-Zip or enable IExpress."
}

if ($SevenZip) {
  # 7-Zip 방식
  $Payload7z = Join-Path $Dist 'payload.7z'; if (Test-Path $Payload7z){Remove-Item $Payload7z -Force}
  Push-Location $Work
  & $SevenZip a -t7z $Payload7z "*" | Out-Null
  Pop-Location

  $ConfigTxt = @'
;!@Install@!UTF-8!
Title="Kobong Logger Installer"
BeginPrompt="Install Kobong Logging Bundle?"
RunProgram="cmd /c run.cmd"
;!@InstallEnd@!
'@
  $Cfg = Join-Path $Dist 'config.txt'; Write-NoBom $Cfg $ConfigTxt
  $Sfx = @"
cmd /c copy /b `"$SfxModule`"+`"$Cfg`"+`"$Payload7z`" `"$OutExe`" >nul
"@
  cmd /c $Sfx | Out-Null
}
else {
  # IExpress 방식
  $Sed = @"
[Version]
Class=IEXPRESS
SEDVersion=3
[Options]
PackagePurpose=InstallApp
ShowInstallProgramWindow=0
HideExtractAnimation=1
UseLongFileName=1
InsideCompressed=1
CompressionType=MSZIP
TargetName=$OutExe
FriendlyName=Kobong Logger Installer
AppLaunched=cmd /c run.cmd
PostInstallCmd=<None>
RebootMode=I
Files=3
[Strings]
FILE0=run.cmd
FILE1=install-logging-bundle.auto.ps1
FILE2=kobong-logging-bundle.zip
[SourceFiles]
SourceFiles0=$Work
[SourceFiles0]
%FILE0%=
%FILE1%=
%FILE2%=
"@
  $SedPath = Join-Path $Dist 'kbl.sed'; Write-NoBom $SedPath $Sed
  & $IExpress /N $SedPath | Out-Null
}

Write-Host "[DONE] One-click installer: $OutExe" -ForegroundColor Cyan
