# APPLY IN SHELL
# Kobong-Orchestrator — Monitor Status v1.3.2  (generated: KST: 2025-09-15 01:44:06 +09:00)
#requires -Version 7.0
param(
  [switch]$ConfirmApply,
  [string]$Root,
  [switch]$Once,
  [int]$IntervalSec = 0,
  [int]$Port = 0,
  [string]$HealthUrl
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
$PSDefaultParameterValues['*:Encoding'] = 'utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

function Get-RepoRoot {
  if ($Root -and (Test-Path $Root)) { return (Resolve-Path $Root).Path }
  try { $r = git rev-parse --show-toplevel 2>$null; if ($r) { return $r } } catch {}
  return (Get-Location).Path
}
$RepoRoot = Get-RepoRoot
Set-Location $RepoRoot
if (-not $HealthUrl -and $Port -gt 0) { $HealthUrl = "http://localhost:$Port/health" }

function Get-RepoInfo {
  $o = [ordered]@{ path=$RepoRoot; branch=$null; head=$null; dirty=$false }
  try { $o.branch = git rev-parse --abbrev-ref HEAD 2>$null } catch {}
  try { $o.head   = git log -1 --pretty='%h %ci %s' 2>$null } catch {}
  try { $o.dirty  = [bool](git status --porcelain 2>$null) } catch {}
  return $o
}

function Get-ProcessInfo {
  try {
    $q = Get-CimInstance Win32_Process | Where-Object {
      ($_.Name -match 'node|npm|pnpm|kobong') -and ($_.CommandLine -match 'kobong-orchestrator')
    } | Select-Object ProcessId, Name, @{n='Start'; e={$_.CreationDate}}
    # 항상 "배열"로, null 제거
    return @($q) | Where-Object { $_ }
  } catch { return @() }
}

function Get-HealthInfo {
  if (-not $HealthUrl) { return @{ enabled=$false } }
  $r = @{ enabled=$true; url=$HealthUrl; ok=$false; code=$null; ms=$null; note=$null }
  try {
    $sw = [Diagnostics.Stopwatch]::StartNew()
    $handler = [System.Net.Http.HttpClientHandler]::new()
    $handler.ServerCertificateCustomValidationCallback = { param($s,$c,$ch,$e) $true }
    $cl = [System.Net.Http.HttpClient]::new($handler)
    $cl.Timeout = [TimeSpan]::FromSeconds(5)
    $resp = $cl.GetAsync($HealthUrl).GetAwaiter().GetResult()
    $sw.Stop()
    $r.ms = $sw.ElapsedMilliseconds
    try { $r.code = [int]$resp.StatusCode } catch {}
    $r.ok = $resp.IsSuccessStatusCode
    $cl.Dispose()
  } catch {
    $r.note = $_.Exception.Message
  }
  return $r
}

function Show-Dashboard($st) {
  Clear-Host
  $repo = $st.repo
  # 핵심: 프로세스를 반드시 배열화
  $p    = @($st.procs) | Where-Object { $_ }
  $h    = $st.health

  $dirty = if ($repo.dirty) { 'DIRTY' } else { 'clean' }
  Write-Host ("KOBONG — STATUS @ {0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')) -ForegroundColor Cyan
  Write-Host ("Repo : {0} | branch={1} | {2}" -f $repo.path, $repo.branch, $dirty)
  Write-Host ("HEAD : {0}" -f $repo.head)

  $pcnt   = @($p).Count
  $pidLst = if ($pcnt -gt 0) { (@($p) | Select-Object -First 5 | ForEach-Object { $_.ProcessId }) -join ', ' } else { '<none>' }
  Write-Host ("PROC : count={0}  PIDs: {1}" -f $pcnt, $pidLst)

  if ($h.enabled) {
    $ok   = if ($h.ok) { 'OK' } else { 'BAD' }
    $code = if ($h.code) { $h.code } else { 'n/a' }
    $ms   = if ($h.ms) { $h.ms } else { 'n/a' }
    Write-Host ("HTTP : {0} ({1} ms, code={2}) {3}" -f $ok, $ms, $code, $h.url)
  } else {
    Write-Host "HTTP : disabled (use -Port 8080 or -HealthUrl …)"
  }
}

do {
  $st = @{ repo = Get-RepoInfo; procs = Get-ProcessInfo; health = Get-HealthInfo }
  Show-Dashboard $st
  if ($Once -or $IntervalSec -le 0) { break }
  Write-Host ("Refreshing in {0} s … (Ctrl+C to stop)" -f $IntervalSec) -ForegroundColor DarkGray
  Start-Sleep -Seconds $IntervalSec
} while ($true)