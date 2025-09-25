# APPLY IN SHELL
#requires -Version 7.0
param(
  [string]$RepoRoot = "D:\ChatGPT5_AI_Link\dosc\kobong-orchestrator",
  [int]$StaleMinutes = 5,
  [switch]$ForceUnlock,
  [switch]$ConfirmApply
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

function LogKLC([string]$Action,[string]$Outcome,[string]$Message,[string]$Level='INFO'){
  try {
    if (Get-Command kobong_logger_cli -ErrorAction SilentlyContinue) {
      & kobong_logger_cli log --level $Level --module 'cleanup' --action $Action --outcome $Outcome --message $Message 2>$null
      return
    }
  } catch {}
  $rec=@{timestamp=(Get-Date).ToString('o');level=$Level;traceId=[guid]::NewGuid().ToString();
    module='cleanup';action=$Action;outcome=$Outcome;errorCode='';message=$Message} | ConvertTo-Json -Compress
  $log = Join-Path $RepoRoot 'logs\apply-log.jsonl'
  New-Item -ItemType Directory -Force -Path (Split-Path $log) | Out-Null
  Add-Content -Path $log -Value $rec
}

$RepoRoot = (Resolve-Path $RepoRoot).Path
function AssertInRepo([string]$path){
  $full = [IO.Path]::GetFullPath($path)
  if (-not $full.StartsWith($RepoRoot, [StringComparison]::OrdinalIgnoreCase)) {
    throw "PRECONDITION: out-of-repo path: $full"
  }
}

# ── 락 처리: 오래된 락은 자동 해제, 최근 락은 옵션 필요
$Lock = Join-Path $RepoRoot '.gpt5.lock'
if (Test-Path $Lock) {
  $ageMin = ((Get-Date) - (Get-Item $Lock).LastWriteTime).TotalMinutes
  if ($ageMin -ge $StaleMinutes -or $ForceUnlock) {
    Remove-Item -Force $Lock
  } else {
    Write-Error "CONFLICT: .gpt5.lock exists (age=$([math]::Round($ageMin,2))m). Use -ForceUnlock or wait."
    exit 11
  }
}
"locked $(Get-Date -Format o)" | Out-File $Lock -Encoding utf8 -NoNewline

# ── 대상 파일(각각 별도 Join-Path 호출)
$targets = @(
  (Join-Path $RepoRoot 'scripts\g5\open-ps7-strong-강력.cmd')
  (Join-Path $RepoRoot 'scripts\g5\open-ps7-strong-경량.cmd')
)

$sw=[Diagnostics.Stopwatch]::StartNew()
try {
  if (-not $ConfirmApply) {
    $plan = foreach($p in $targets){
      AssertInRepo $p
      $exists  = Test-Path -LiteralPath $p
      $tracked = $false
      if ($exists) {
        $rel = [IO.Path]::GetRelativePath($RepoRoot, $p).Replace('\','/')
        $null = git -C $RepoRoot ls-files --error-unmatch -- "$rel" 2>$null
        $tracked = ($LASTEXITCODE -eq 0)
      }
      [pscustomobject]@{ file=$p; exists=$exists; tracked=$tracked }
    }
    $plan | ConvertTo-Json -Compress | Write-Output
    LogKLC 'remove-plan' 'DRYRUN' ("targets="+$targets.Count)
    exit 0
  }

  # ── APPLY: 백업 → 잠금해제 → 삭제 → git index 반영
  $backupDir = Join-Path $RepoRoot ("backups\deleted\" + (Get-Date -Format 'yyyyMMdd-HHmmss'))
  foreach($p in $targets){
    AssertInRepo $p
    if (-not (Test-Path -LiteralPath $p)) {
      LogKLC 'remove' 'SUCCESS' ("skip-missing "+$p); continue
    }
    $rel = [IO.Path]::GetRelativePath($RepoRoot, $p)
    $relGit = $rel.Replace('\','/')

    # 백업
    $dest = Join-Path $backupDir $rel
    New-Item -ItemType Directory -Force -Path (Split-Path $dest) | Out-Null
    Copy-Item -LiteralPath $p -Destination $dest -Force

    # 잠금/차단 해제
    attrib -R $p 2>$null
    Unblock-File -LiteralPath $p 2>$null

    # 삭제
    Remove-Item -LiteralPath $p -Force

    # 인덱스에서 제거(추적 시)
    $null = git -C $RepoRoot rm -f --ignore-unmatch -- "$relGit" 2>$null

    LogKLC 'remove' 'SUCCESS' ("deleted "+$rel)
  }

  Write-Host "[APPLIED] deleted files (backup → $backupDir)"
  LogKLC 'remove-apply' 'SUCCESS' ("backupDir="+$backupDir+"; count="+$targets.Count)
  exit 0
}
catch {
  LogKLC 'remove-apply' 'FAILURE' $_.Exception.Message 'ERROR'
  throw
}
finally {
  Remove-Item -Force $Lock -ErrorAction SilentlyContinue
}
