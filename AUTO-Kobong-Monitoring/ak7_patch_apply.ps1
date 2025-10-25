# AK7 migration apply script
Param(
  [string]$Root = "D:\ChatGPT5_AI_Link\dosc\Kobong-Orchestrator-VIP\AUTO-Kobong-Monitoring"
)

$ErrorActionPreference = "Stop"
$webui = Join-Path $Root "webui"
$bk = Join-Path $Root ("webui_backup_{0:yyyyMMdd_HHmmss}" -f (Get-Date))
Write-Host "Backup to $bk"
New-Item -ItemType Directory -Force -Path $bk | Out-Null
Copy-Item -Recurse -Force $webui\* $bk

# Ensure reset-local redirect patched and AK7 defaults
# Apply patched files from zip (this script assumes ak7_migrated_webui.zip is next to this script)
$zipPath = Join-Path $PSScriptRoot "ak7_migrated_webui.zip"
if(!(Test-Path $zipPath)){ throw "ak7_migrated_webui.zip not found at $zipPath" }

Add-Type -AssemblyName System.IO.Compression.FileSystem
$archive = [System.IO.Compression.ZipFile]::OpenRead($zipPath)
foreach($entry in $archive.Entries){
  $outPath = Join-Path $Root $entry.FullName
  $outDir  = Split-Path $outPath -Parent
  New-Item -ItemType Directory -Force -Path $outDir | Out-Null
  if($entry.FullName -match '/$'){ continue }
  [System.IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $outPath, $true)
  Write-Host "Patched: $($entry.FullName)"
}
$archive.Dispose()

# Rename main HTML
$old = Join-Path $webui "AUTO-Kobong-Monitoring-Han.html"
$new = Join-Path $webui "ak7-monitoring.html"
if(Test-Path $old){ Rename-Item -Force $old $new }

# Optional: keep an .old copy for quick revert
# Copy-Item $new ($new + ".bak")

Write-Host "Done. Open: $new"
