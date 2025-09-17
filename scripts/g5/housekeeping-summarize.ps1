#requires -Version 7.0
param(
  [string]$RepoRoot,
  [int]$Tail = 2000,
  [int]$Days = 3
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [Text.Encoding]::UTF8

if (-not $RepoRoot) {
  $RepoRoot = (git rev-parse --show-toplevel 2>$null) ?? (Get-Location).Path
}
$log = Join-Path $RepoRoot 'logs/apply-log.jsonl'

# No logs → short summary and exit 0
if (-not (Test-Path $log)) {
  $md = "# Housekeeping Summary`n`n_No logs found._"
  if ($env:GITHUB_STEP_SUMMARY) { $md | Out-File $env:GITHUB_STEP_SUMMARY -Encoding utf8 -NoNewline } else { Write-Output $md }
  exit 0
}

try {
  $cutoff = (Get-Date).AddDays(-1 * [Math]::Abs($Days))
  $lines  = Get-Content -Encoding utf8 -Tail $Tail $log
  $items  = foreach ($ln in $lines) {
    try { $o = $ln | ConvertFrom-Json -ErrorAction Stop } catch { continue }
    if ($o.timestamp) {
      $ts = [datetime]$o.timestamp
      if ($ts -lt $cutoff) { continue }
    }
    $o
  }

  $total = 0
  $byOutcome = @{}
  $latest = $null
  foreach ($it in $items) {
    $total++
    $key = if ($it.outcome) { $it.outcome.ToString().ToUpperInvariant() } else { 'UNKNOWN' }
    $byOutcome[$key] = 1 + ($byOutcome[$key] ?? 0)
    $t = if ($it.timestamp) { [datetime]$it.timestamp } else { Get-Date }
    if (-not $latest -or $t -gt $latest.time) { $latest = @{ time = $t; traceId = ($it.traceId ?? '') } }
  }

  $rows = ($byOutcome.GetEnumerator() | Sort-Object Name | ForEach-Object { "| $($_.Name) | $($_.Value) |" }) -join "`n"
  if (-not $rows) { $rows = "| (none) | 0 |" }

  $latestInfo = if ($latest) { "`n_Last entry_: **$($latest.time.ToString('yyyy-MM-dd HH:mm:ss K'))** (trace **$($latest.traceId)**)" } else { "" }

  $md = @(
    "# Housekeeping Summary",
    "",
    "*Window:* last $Days day(s) - *Scanned:* last $Tail line(s) - *File:* logs/apply-log.jsonl",
    "",
    "| Outcome | Count |",
    "|---|---|",
    $rows
  )
  if ($latestInfo) { $md += $latestInfo }

  $text = ($md -join "`n")
  if ($env:GITHUB_STEP_SUMMARY) { $text | Out-File $env:GITHUB_STEP_SUMMARY -Encoding utf8 -NoNewline } else { Write-Output $text }
}
catch {
  Write-Error $_.Exception.Message
  exit 13
}