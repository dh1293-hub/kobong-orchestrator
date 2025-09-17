# APPLY IN SHELL
#requires -Version 7.0
param([switch]$ConfirmApply,[string]$Root='.',[string]$WorkflowPath='.github/workflows/auto-github-release.yml',[int]$MaxWaitSec=240)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8';$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

$RepoRoot=(Resolve-Path $Root).Path
Set-Location $RepoRoot
git fetch -p origin --tags | Out-Null
git switch main | Out-Null
git pull --ff-only | Out-Null

# lock + std log
$Lock=Join-Path $RepoRoot '.gpt5.lock'
if (Test-Path $Lock) { Remove-Item -Force $Lock }
"locked $(Get-Date -Format o)" | Out-File $Lock -NoNewline
$sw=[Diagnostics.Stopwatch]::StartNew(); $trace=[guid]::NewGuid().ToString()
function StdLog($level,$module,$action,$message,$outcome=''){
  $rec=@{timestamp=(Get-Date).ToString('o');level=$level;traceId=$trace;module=$module;action=$action;inputHash='';outcome=$outcome;durationMs=$sw.ElapsedMilliseconds;errorCode='';message=$message}|ConvertTo-Json -Compress
  $log=Join-Path $RepoRoot 'logs/apply-log.jsonl'; New-Item -ItemType Directory -Force -Path (Split-Path $log)|Out-Null; Add-Content $log $rec
}

try {
  if (-not (Test-Path $WorkflowPath)) { throw "Workflow missing on main: $WorkflowPath" }

  # 빈 v0.0.X 스모크 태그 선택
  $base='v0.0.'; $i=0; $Tag=$null
  do {
    $cand="$base$i"
    $exists=(git tag -l --format="%(refname:short)"|Select-String "^$([regex]::Escape($cand))$") -or (git ls-remote --tags origin $cand)
    if (-not $exists) { $Tag=$cand; break }
    $i++
  } while ($i -lt 1000)
  if (-not $Tag) { throw "No free smoke tag under v0.0.*" }

  $sha=(git rev-parse origin/main).Trim()
  if ($ConfirmApply) {
    git tag -a $Tag $sha -m "smoke(auto-release): $Tag"
    git push origin $Tag
    Write-Host "[push] $Tag @ $sha"
  } else { Write-Host "[DRY-RUN] would push $Tag @ $sha" }

  # 릴리즈 생성 대기
  $deadline=(Get-Date).AddSeconds($MaxWaitSec); $created=$false
  while ((Get-Date) -lt $deadline) {
    $ok=$false; try { gh release view $Tag 2>$null|Out-Null; $ok=$true } catch {}
    if ($ok) { $created=$true; break }
    Start-Sleep 5
  }
  if ($created) {
    Write-Host "[OK] release created for $Tag 🎉"
  } else { throw "Auto-release not observed within ${MaxWaitSec}s for $Tag" }

  # 정리
  if ($ConfirmApply) {
    gh release delete $Tag -y 2>$null|Out-Null
    git push origin :refs/tags/$Tag | Out-Null
    git tag -d $Tag | Out-Null
    Write-Host "[clean] removed release+tag $Tag"
  } else { Write-Host "[DRY-RUN] would delete release+tag $Tag" }

  StdLog 'INFO' 'smoke-auto-release' 'run' "tag=$Tag" 'OK'
} catch {
  StdLog 'ERROR' 'smoke-auto-release' 'run' $_.Exception.Message 'FAILURE'
  throw
} finally {
  Remove-Item -Force $Lock -ErrorAction SilentlyContinue
}