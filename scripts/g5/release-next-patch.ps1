#requires -Version 7.0
param([switch]$ConfirmApply,[string]$Root,[switch]$CreateReleasePage)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }
$RepoRoot = if ($Root) { $Root } else { (git rev-parse --show-toplevel 2>$null) ?? (Get-Location).Path }
Set-Location $RepoRoot
$LockFile = Join-Path $RepoRoot '.gpt5.lock'
if (Test-Path $LockFile) { Write-Error 'CONFLICT: .gpt5.lock exists.'; exit 11 }
"locked $(Get-Date -Format o)" | Out-File $LockFile -Encoding utf8 -NoNewline
$sw=[Diagnostics.Stopwatch]::StartNew(); $trace=[guid]::NewGuid().ToString()
function Log($lvl,$act,$msg,$code=''){ $rec=@{timestamp=(Get-Date).ToString('o');level=$lvl;traceId=$trace;module='release';action=$act;inputHash='';outcome=$lvl;durationMs=$sw.ElapsedMilliseconds;errorCode=$code;message=$msg}|ConvertTo-Json -Compress; $log=Join-Path $RepoRoot 'logs/apply-log.jsonl'; New-Item -ItemType Directory -Force -Path (Split-Path $log)|Out-Null; Add-Content -Path $log -Value $rec }
try {
  Log 'INFO' 'preflight' "RepoRoot=$RepoRoot"
  git fetch origin main --prune | Out-Null; git switch main | Out-Null; git pull --ff-only | Out-Null
  if ($ConfirmApply) { pwsh -File .\scripts\g5\release-vpatch.safe.ps1 -ConfirmApply } else { pwsh -File .\scripts\g5\release-vpatch.safe.ps1 }
  if ($ConfirmApply) { pwsh -File .\scripts\g5\finalize-release.ps1 -ConfirmApply } else { pwsh -File .\scripts\g5\finalize-release.ps1 }
  git fetch --tags --prune | Out-Null; $tag = (git describe --tags --abbrev=0); if (-not $tag){ throw "No tag detected after release." }
  $readme = Get-Content -Raw -Path ./README.md
  if ($readme -notmatch "/releases/tag/$([regex]::Escape($tag))") { throw "README not updated to $tag" }
  $cl = Get-Content -Raw -Path ./CHANGELOG.md; $escTag=[regex]::Escape($tag)
  if ($cl -notmatch "(?m)^##\s*$escTag\b") { throw "CHANGELOG missing $tag" }
  if ($CreateReleasePage) {
    if (-not (gh release view $tag 2>$null)) {
      $m=[regex]::Match($cl,"(?ms)^##\s*$escTag\b.*?(?=^##\s*v|\z)"); $tmp=Join-Path $PWD "notes-$tag.md"
      if ($m.Success){ $m.Value | Out-File $tmp -Encoding utf8 } else { "Release $tag" | Out-File $tmp -Encoding utf8 }
      gh release create $tag --title "Release $tag" --notes-file $tmp | Out-Null
      Log 'INFO' 'create-gh-release' "[OK] GitHub Release created → $tag"
    } else { Log 'INFO' 'create-gh-release' "[OK] GitHub Release already exists → $tag" }
  }
  Write-Host "[DONE] Release round finished → $tag"; exit 0
} catch { Log 'ERROR' 'step' $_.Exception.Message 'Code-013'; throw } finally { Remove-Item -Force $LockFile -ErrorAction SilentlyContinue }
