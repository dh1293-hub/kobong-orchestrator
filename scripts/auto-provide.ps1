#requires -PSEdition Core
#requires -Version 7.0
param(
  [string] $DslFile,                 # default: domain/dsl.demo.dsl
  [string] $OutDir,                  # default: out
  [string] $DistDir,                 # default: dist
  [switch] $OpenExplorer,            # dist/<ts> 폴더 탐색기 열기
  [switch] $NoZip,                   # ZIP 생성하지 않음
  [switch] $GhUpload,                # GitHub Release 업로드
  [string] $Tag                      # 업로드 태그 (예: v0.1.0)
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
function Get-GitRoot { try { git rev-parse --show-toplevel 2>$null } catch { $null } }
$RepoRoot = $env:HAN_GPT5_ROOT; if (-not $RepoRoot) { $RepoRoot = Get-GitRoot }
if (-not $RepoRoot) { $RepoRoot = (Resolve-Path "$PSScriptRoot/..").Path }
if (-not (Test-Path $RepoRoot)) { throw "PRECONDITION: RepoRoot not found: $RepoRoot" }
$env:HAN_GPT5_ROOT = $RepoRoot
if (-not $OutDir)  { $OutDir  = Join-Path $RepoRoot 'out' }
if (-not $DistDir) { $DistDir = Join-Path $RepoRoot 'dist' }
if (-not $DslFile) { $DslFile = Join-Path $RepoRoot 'domain/dsl.demo.dsl' }

Write-Host "[RUN] pipeline via run-report-demo.ps1"
& pwsh -NoLogo -NoProfile -File (Join-Path $RepoRoot 'scripts/run-report-demo.ps1') -DslFile $DslFile
if ($LASTEXITCODE -ne 0) { throw "PIPELINE_FAIL: run-report-demo exit=$LASTEXITCODE" }

$reqJson = Join-Path $OutDir 'dsl_request.demo.json'
$resJson = Join-Path $OutDir 'report_result.dsl.json'
$resCsv  = Join-Path $OutDir 'report_result.dsl.csv'
$arts = @(); foreach ($p in @($reqJson,$resJson,$resCsv)) { if (Test-Path $p) { $arts += (Resolve-Path $p).Path } }
if ($arts.Count -eq 0) { throw "NO_ARTIFACTS: nothing found in $OutDir" }

$ts = (Get-Date -Format 'yyyyMMdd-HHmmss')
$distTs = Join-Path $DistDir $ts
New-Item -ItemType Directory -Force -Path $distTs | Out-Null
foreach ($a in $arts) { Copy-Item -LiteralPath $a -Destination $distTs -Force }
Write-Host "[OK] Collected → $distTs"
$zipPath = Join-Path $DistDir ("report_result-{0}.zip" -f $ts)

if (-not $NoZip) {
  if (Test-Path $zipPath) { Remove-Item -LiteralPath $zipPath -Force }
  Compress-Archive -Path (Join-Path $distTs '*') -DestinationPath $zipPath
  Write-Host "[OK] Packaged → $zipPath"
}
if ($OpenExplorer) { Start-Process explorer.exe $distTs | Out-Null; Write-Host "[OPEN] Explorer → $distTs" }

if ($GhUpload) {
  $gh = Get-Command gh -ErrorAction SilentlyContinue
  if (-not $gh) { Write-Warning "gh CLI not found — skip upload." }
  else {
    $asset = if (-not $NoZip) { $zipPath } else { $arts[0] }
    if (-not (Test-Path $asset)) { throw "UPLOAD_FAIL: asset not found: $asset" }
    if (-not $Tag) { $Tag = "auto-" + (Get-Date -Format 'yyyyMMdd') }
    $exists = (gh release view $Tag *> $null); $ok = ($LASTEXITCODE -eq 0)
    if ($ok) { Write-Host "[INFO] Updating release $Tag"; gh release upload $Tag $asset --clobber }
    else     { Write-Host "[INFO] Creating release $Tag"; gh release create $Tag $asset --title "$Tag" --generate-notes }
    if ($LASTEXITCODE -ne 0) { throw "UPLOAD_FAIL: gh exit=$LASTEXITCODE" }
    Write-Host "[OK] Uploaded asset → $Tag"
  }
}

Write-Host "==== Summary ===="
Write-Host ("Artifacts:`n - {0}" -f ($arts -join "`n - "))
Write-Host ("DistDir : {0}" -f $distTs)
if (-not $NoZip -and (Test-Path $zipPath)) { Write-Host ("ZIP    : {0}" -f $zipPath) }
Write-Host "[DONE] auto-provide complete."
