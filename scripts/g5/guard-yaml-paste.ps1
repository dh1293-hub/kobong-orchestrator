#requires -Version 7.0
param([switch]$ConfirmApply,[string]$Root)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

# APPLY IN SHELL
#requires -Version 7.0
param(
  [switch]$ConfirmApply,
  [string]$Root,
  [int]$MonitorSeconds,
  [string]$OutDir,
  [switch]$Once
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

# ==== Defaults ====
if (-not $PSBoundParameters.ContainsKey('MonitorSeconds') -or $MonitorSeconds -le 0) { $MonitorSeconds = 120 }
if (-not $PSBoundParameters.ContainsKey('OutDir') -or [string]::IsNullOrWhiteSpace($OutDir)) { $OutDir = 'drafts' }

# === Preflight ===
$RepoRoot = if ($Root) { (Resolve-Path -LiteralPath $Root).Path } else { (git rev-parse --show-toplevel 2>$null) ?? (Get-Location).Path }
if (-not (Test-Path $RepoRoot)) { Write-Error "PRECONDITION: RepoRoot not found → $RepoRoot"; exit 10 }
Set-Location $RepoRoot
$Branch = (git rev-parse --abbrev-ref HEAD 2>$null) ?? '<unknown>'
$now = [TimeZoneInfo]::ConvertTimeBySystemTimeZoneId((Get-Date),'Asia/Seoul').ToString('yyyy-MM-dd HH:mm:ss')
Write-Host ("`n[verify] YAML paste guard on {0} @ {1} (KST)" -f $Branch,$now)

# === Lock (stale >= 15s auto-unlock) ===
$LockFile = Join-Path $RepoRoot '.gpt5.lock.yaml-guard'
if (Test-Path $LockFile) {
  try { $age = [int]((Get-Date) - (Get-Item $LockFile).LastWriteTime).TotalSeconds } catch { $age = 999999 }
  if ($age -ge 15) {
    $ts  = Get-Date -Format 'yyyyMMdd-HHmmss'
    $rot = "{0}.stale-{1}" -f $LockFile, $ts
    Move-Item -Force $LockFile $rot
    Write-Host ("[auto-unlock] rotated stale lock → {0}" -f $rot)
  } else { Write-Error 'CONFLICT: .gpt5.lock.yaml-guard exists (recent)'; exit 11 }
}
"locked $(Get-Date -Format o)" | Out-File $LockFile -Encoding utf8 -NoNewline

$sw=[Diagnostics.Stopwatch]::StartNew()
$trace=[guid]::NewGuid().ToString()
function Write-Log($level,$action,$message,$outcome='',$errorCode='',$inputHash=''){
  $rec=[ordered]@{
    timestamp=(Get-Date).ToString('o');level=$level;traceId=$trace;module='yaml-guard';action=$action
    inputHash=$inputHash;outcome=$outcome;durationMs=$sw.ElapsedMilliseconds;errorCode=$errorCode;message=$message
  } | ConvertTo-Json -Compress
  $log=Join-Path $RepoRoot 'logs/apply-log.jsonl'; New-Item -ItemType Directory -Force -Path (Split-Path $log)|Out-Null; Add-Content -Path $log -Value $rec
}

function Get-TextClipboard {
  try { return [string](Get-Clipboard -Format Text) } catch { return "" }
}

function Normalize-Text([string]$s) {
  if (-not $s) { return "" }
  $s = $s -replace "`r?`n","`n"                  # normalize EOL to LF
  $s = $s.Replace([char]0xFEFF,'')               # strip BOM
  $s = $s.Replace([char]0x200B,'')               # strip zero-width space
  return $s
}

function Test-YamlSignature([string]$text) {
  if (-not $text) { return $false }
  $text  = Normalize-Text $text
  $lines = $text -split "`n"
  $head  = $lines | Where-Object { $_ -match '\S' } | Select-Object -First 1
  if ($head -match '^(?i)\s*(name|on|jobs)\s*:\s*') { return $true }
  $topN = $lines | Select-Object -First ([Math]::Min(30,$lines.Count))
  if (($topN -match '^(?i)\s*on\s*:').Count -gt 0) { return $true }
  if (($topN -match '^(?i)\s*jobs\s*:').Count -gt 0) { return $true }
  if (($topN -match '^(?i)\s*name\s*:').Count -gt 0) { return $true }
  # generic key: value count
  $kvCount = ($topN -match '^\s*["'']?[A-Za-z0-9_.-]+["'']?\s*:\s*').Count
  return ($kvCount -ge 3)
}

function Save-YamlFromClipboard() {
  $raw = Get-TextClipboard
  $txt = Normalize-Text $raw
  if (-not (Test-YamlSignature $txt)) {
    # debug print first few lines to help user
    $first5 = ($txt -split "`n") | Select-Object -First 5
    if ($first5) {
      Write-Host "[debug] first lines:"
      $first5 | ForEach-Object { Write-Host ("  > " + $_) }
    }
    return $false
  }
  $draftDir = Join-Path $RepoRoot $OutDir
  New-Item -ItemType Directory -Force -Path $draftDir | Out-Null
  $ts = Get-Date -Format 'yyyyMMdd-HHmmss'
  $out = Join-Path $draftDir ("paste-{0}.yml" -f $ts)
  Set-Content -Path $out -Value $txt -Encoding utf8 -NoNewline
  Write-Log 'INFO' 'capture' ("saved YAML from clipboard → {0}" -f $out) 'APPLIED' ''
  Write-Host ("[saved] YAML detected — {0}" -f $out)
  return $true
}

try {
  if (-not $ConfirmApply) {
    Write-Host "DRY-RUN ✅  실제 감시는 하지 않았습니다."
    Write-Host "사용법:"
    Write-Host "  `$env:CONFIRM_APPLY='true'; pwsh -File scripts/g5/guard-yaml-paste.ps1 -ConfirmApply -MonitorSeconds 120"
    Write-Host "  또는 1회 캡처: -Once"
    return
  }

  if ($Once) {
    if (-not (Save-YamlFromClipboard)) { Write-Host "ℹ️ YAML 시그니처를 발견하지 못했습니다."; Write-Log 'INFO' 'once' 'no yaml'; return }
    else { return }
  }

  Write-Host ("[monitor] clipboard for {0}s — YAML will be saved to '{1}\*.yml'" -f $MonitorSeconds,$OutDir)
  $deadline = (Get-Date).AddSeconds($MonitorSeconds)
  $prev=''
  while ((Get-Date) -lt $deadline) {
    $cur = Get-TextClipboard
    if ($cur -and $cur -ne $prev) {
      if (Save-YamlFromClipboard) { $prev = $cur } else { $prev = $cur }
    }
    Start-Sleep -Milliseconds 250
  }
  Write-Host "[done] monitor finished."
}
catch {
  Write-Log 'ERROR' 'exception' $_.Exception.Message 'FAILURE' ($_.FullyQualifiedErrorId ?? 'Unknown')
  throw
}
finally {
  Remove-Item -Force $LockFile -ErrorAction SilentlyContinue
}