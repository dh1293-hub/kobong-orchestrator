#requires -Version 7.0
param([string]$Root="D:\ChatGPT5_AI_Link\dosc\kobong-orchestrator",[string]$Slot)
Set-StrictMode -Version Latest; $ErrorActionPreference='Stop'
$RepoRoot=(Resolve-Path $Root).Path; Set-Location $RepoRoot
$Manifest = Join-Path $RepoRoot 'Rollbackfile.json'
$RollDir  = Join-Path $RepoRoot '.rollbacks\good'
$UndoDir  = Join-Path $RepoRoot '.rollbacks\undo'
New-Item -ItemType Directory -Force -Path $UndoDir | Out-Null

# choose slot
if (-not $Slot){
  $cand = Get-ChildItem $RollDir -Filter 'good-*.zip' | Sort-Object LastWriteTimeUtc -Descending | Select-Object -First 1
  if (-not $cand) { throw "No good slot found" }
  $Slot=$cand.FullName
}
if (-not (Test-Path $Slot)) { throw "Slot not found: $Slot" }

# backup UNDO of current targets
$m = Get-Content $Manifest -Raw -Encoding utf8 | ConvertFrom-Json
$targets = @()
foreach($t in $m.targets){
  $p = Join-Path $RepoRoot $t
  if (Test-Path $p -PathType Container) {
    $targets += Get-ChildItem -LiteralPath $p -Recurse -File | ForEach-Object { $_.FullName }
  } elseif (Test-Path $p) { $targets += (Resolve-Path $p).Path }
}
$rel = $targets | ForEach-Object { $_.Substring($RepoRoot.Length).TrimStart('\') }
$ts = Get-Date -Format 'yyyyMMdd-HHmmss'
$undo = Join-Path $UndoDir ("undo-$ts.zip")
Push-Location $RepoRoot
try { if ($rel) { Compress-Archive -Path $rel -DestinationPath $undo -CompressionLevel Optimal -Force } } finally { Pop-Location }

# restore
Expand-Archive -Path $Slot -DestinationPath $RepoRoot -Force
Write-Host "[ROLLBACK] restored from: $Slot"
Write-Host "[UNDO] saved snapshot: $undo"