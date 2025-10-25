#requires -Version 7.0
param([string]$Root="D:\ChatGPT5_AI_Link\dosc\kobong-orchestrator")
Set-StrictMode -Version Latest; $ErrorActionPreference='Stop'
$RepoRoot=(Resolve-Path $Root).Path; Set-Location $RepoRoot
$Manifest = Join-Path $RepoRoot 'Rollbackfile.json'
$RollDir  = Join-Path $RepoRoot '.rollbacks\good'
New-Item -ItemType Directory -Force -Path $RollDir | Out-Null

# Load manifest
$m = Get-Content $Manifest -Raw -Encoding utf8 | ConvertFrom-Json
$targets = @()
foreach($t in $m.targets){
  $p = Join-Path $RepoRoot $t
  if (Test-Path $p -PathType Container) {
    $targets += Get-ChildItem -LiteralPath $p -Recurse -File | ForEach-Object { $_.FullName }
  } elseif (Test-Path $p) {
    $targets += (Resolve-Path $p).Path
  }
}
# Apply excludes
$rel = $targets | ForEach-Object { $_.Substring($RepoRoot.Length).TrimStart('\') }
$ex  = @($m.exclude) | Where-Object { $_ } | ForEach-Object { $_ -replace '/', '\' }
$kept = @()
foreach($r in $rel){
  $skip=$false
  foreach($pat in $ex){ if ($r -like $pat) { $skip=$true; break } }
  if(-not $skip){ $kept += $r }
}

$ts = Get-Date -Format 'yyyyMMdd-HHmmss'
$slot = Join-Path $RollDir ("good-$ts.zip")
Push-Location $RepoRoot
try {
  if ($kept.Count -eq 0) { throw "No files to snapshot (targets empty after exclude)" }
  Compress-Archive -Path $kept -DestinationPath $slot -CompressionLevel Optimal -Force
} finally { Pop-Location }

# retention
$keep = ($m.retention.goodSlots) ?? 10
$old = Get-ChildItem $RollDir -Filter 'good-*.zip' | Sort-Object LastWriteTimeUtc -Descending | Select-Object -Skip $keep
$old | ForEach-Object { Remove-Item -LiteralPath $_.FullName -Force -ErrorAction SilentlyContinue }

Write-Host "[GOOD] created: $slot"