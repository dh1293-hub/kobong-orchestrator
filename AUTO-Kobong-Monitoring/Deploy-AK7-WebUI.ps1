# AK7 WebUI Deploy Script (safe)
Param(
  [string]$TargetDir = "D:\ChatGPT5_AI_Link\dosc\Kobong-Orchestrator-VIP\AUTO-Kobong-Monitoring\webui",
  [switch]$DryRun
)
$ErrorActionPreference="Stop"
$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$bak = Join-Path (Split-Path $TargetDir -Parent) ("webui_backup_"+$stamp)
Write-Host "TargetDir =" $TargetDir
Write-Host "BackupDir =" $bak

if(-not (Test-Path $TargetDir)){ throw "TargetDir not found: $TargetDir" }
if($DryRun){ Write-Host "[DRYRUN] no changes will be made" -Foreground Yellow }

# 1) Backup
if(-not $DryRun){
  Copy-Item $TargetDir $bak -Recurse -Force
  Write-Host "Backup created at $bak"
}

# 2) Unzip refactor pack into a temp dir
$zip = Join-Path $PSScriptRoot "AK7-WebUI-Refactor-Pack.zip"
if(-not (Test-Path $zip)){ throw "Pack not found next to script: $zip" }
$tmp = Join-Path $env:TEMP ("ak7_ref_"+$stamp)
New-Item -ItemType Directory -Path $tmp | Out-Null
Expand-Archive -Path $zip -DestinationPath $tmp -Force

# 3) Copy webui only
$src = Join-Path $tmp "webui"
if(-not (Test-Path $src)){ throw "webui not found in pack: $src" }

# 4) Replace files
if(-not $DryRun){
  Copy-Item (Join-Path $src "*") $TargetDir -Recurse -Force
  Write-Host "Refactor files copied to $TargetDir"
}

# 5) Optional: set AK7 endpoints (DEV=5181 or MOCK=5191)
#    Open AK7-Monitoring.html and change the sentinel line if needed.

Write-Host "Done. Launch AK7-Monitoring.html in your browser."
